import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/archive/archive_filter.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/stats/module_kpi_counts_data_source.dart';
import '../../../../core/utils/initial_load_timeout.dart';
import '../../../audit_logs/domain/entities/audit_log.dart';
import '../../../audit_logs/domain/usecases/create_audit_log_usecase.dart';
import '../../domain/entities/client.dart';
import '../../domain/errors/client_exception.dart';
import '../../domain/usecases/archive_client_usecase.dart';
import '../../domain/usecases/assign_client_usecase.dart';
import '../../domain/usecases/create_client_usecase.dart';
import '../../domain/usecases/restore_client_usecase.dart';
import '../../domain/usecases/update_client_usecase.dart';
import '../../domain/usecases/watch_client_usecase.dart';
import '../../domain/usecases/watch_clients_usecase.dart';
import 'clients_state.dart';

class ClientsCubit extends Cubit<ClientsState> {
  ClientsCubit({
    required WatchClientsUseCase watchClientsUseCase,
    required WatchClientUseCase watchClientUseCase,
    required CreateClientUseCase createClientUseCase,
    required UpdateClientUseCase updateClientUseCase,
    required AssignClientUseCase assignClientUseCase,
    required ArchiveClientUseCase archiveClientUseCase,
    required RestoreClientUseCase restoreClientUseCase,
    required CreateAuditLogUseCase createAuditLogUseCase,
  }) : _watchClientsUseCase = watchClientsUseCase,
       _watchClientUseCase = watchClientUseCase,
       _createClientUseCase = createClientUseCase,
       _updateClientUseCase = updateClientUseCase,
       _assignClientUseCase = assignClientUseCase,
       _archiveClientUseCase = archiveClientUseCase,
       _restoreClientUseCase = restoreClientUseCase,
       _createAuditLogUseCase = createAuditLogUseCase,
      super(const ClientsState.initial());

  final WatchClientsUseCase _watchClientsUseCase;
  final WatchClientUseCase _watchClientUseCase;
  final CreateClientUseCase _createClientUseCase;
  final UpdateClientUseCase _updateClientUseCase;
  final AssignClientUseCase _assignClientUseCase;
  final ArchiveClientUseCase _archiveClientUseCase;
  final RestoreClientUseCase _restoreClientUseCase;
  final CreateAuditLogUseCase _createAuditLogUseCase;
  final FirestoreModuleKpiCountsDataSource _countsDataSource =
      FirestoreModuleKpiCountsDataSource();

  StreamSubscription<List<Client>>? _clientsSubscription;
  StreamSubscription<Client?>? _clientSubscription;
  String? _watchedCompanyId;
  String? _watchedAssignedTo;
  String? _watchedManagerId;
  String? _watchedTeamId;
  ArchiveFilter _watchedArchiveFilter = ArchiveFilter.active;
  Future<void>? _inFlightKpiRefresh;
  String? _inFlightKpiRefreshKey;
  String? _lastSuccessfulKpiRefreshKey;
  DateTime? _lastSuccessfulKpiRefreshAt;
  ModuleKpiCounts? _lastSuccessfulKpiCounts;
  int _kpiRefreshSerial = 0;
  bool _isClosing = false;
  static const Duration _streamKpiRefreshDebounce =
      Duration(milliseconds: 1500);
  static const int _defaultPageLimit = 15;
  static const int _pageIncrement = 15;
  static const List<String> _kpiCountKeys = <String>[
    'total',
    'assigned',
    'unassigned',
  ];
  static const int _dashboardWatchLimit = 500;
  static const int _filterModeWatchLimit = 500;
  final InitialLoadTimeout _clientsInitialLoadTimeout = InitialLoadTimeout();
  final InitialLoadTimeout _clientInitialLoadTimeout = InitialLoadTimeout();

  void watchClients({
    required String companyId,
    String? assignedTo,
    String? managerId,
    String? teamId,
    ArchiveFilter archiveFilter = ArchiveFilter.active,
    int? limit,
    bool resetPage = true,
    bool usePagination = true,
  }) {
    _watchedCompanyId = companyId;
    _watchedAssignedTo = assignedTo;
    _watchedManagerId = managerId;
    _watchedTeamId = teamId;
    _watchedArchiveFilter = archiveFilter;
    final pageLimit = usePagination
        ? (resetPage ? _defaultPageLimit : limit ?? state.pageLimit)
        : state.pageLimit;
    final watchLimit = usePagination
        ? _effectiveWatchLimit(pageLimit)
        : _dashboardWatchLimit;
    final kpiScopeKey = _kpiScopeKey(
      companyId: companyId,
      assignedTo: assignedTo,
      managerId: managerId,
      teamId: teamId,
      archiveFilter: archiveFilter,
    );
    final cachedKpiCounts = resetPage
        ? _cachedKpiCountsFor(scopeKey: kpiScopeKey)
        : null;
    emit(
      state.copyWith(
        status: resetPage || state.clients.isEmpty
            ? ClientsStatus.loading
            : ClientsStatus.loadingMore,
        pageLimit: pageLimit,
        kpiCounts: resetPage
            ? cachedKpiCounts ?? const ModuleKpiCounts.empty()
            : state.kpiCounts,
        clearMessage: true,
        clearLastAction: true,
      ),
    );
    if (resetPage || !state.kpiCounts.hasAll(_kpiCountKeys)) {
      unawaited(_refreshKpiCounts(reason: 'watch-start'));
    }
    _clientsSubscription?.cancel();
    _clientsInitialLoadTimeout.start(() {
      if (isClosed ||
          (state.status != ClientsStatus.loading &&
              state.status != ClientsStatus.loadingMore) ||
          state.clients.isNotEmpty) {
        return;
      }
      emit(
        state.copyWith(
          status: ClientsStatus.failure,
          message: AppErrorMessages.connectionTimeout,
        ),
      );
    });
    _clientsSubscription = _watchClientsUseCase(
      companyId: companyId,
      assignedTo: assignedTo,
      managerId: managerId,
      teamId: teamId,
      archiveFilter: archiveFilter,
      limit: watchLimit,
    ).listen(
      (clients) {
        if (isClosed) {
          return;
        }
        _clientsInitialLoadTimeout.complete();
        emit(
          state.copyWith(
            status: clients.isEmpty ? ClientsStatus.empty : ClientsStatus.loaded,
            clients: clients,
            filteredClients: _applyFilters(
              clients,
              searchQuery: state.searchQuery,
              assignedToFilter: state.assignedToFilter,
            ),
            archiveFilter: archiveFilter,
            pageLimit: pageLimit,
            clearMessage: true,
          ),
        );
        unawaited(_refreshKpiCounts(reason: 'stream-data'));
        _debugCheckKpiInvariant();
      },
      onError: (error) {
        if (isClosed) {
          return;
        }
        _clientsInitialLoadTimeout.complete();
        emit(
          state.copyWith(
            status: ClientsStatus.failure,
            message: _clientErrorMessage(
              error,
              AppErrorMessages.unknown,
            ),
          ),
        );
      },
    );
  }

  void setArchiveFilter(
    ArchiveFilter archiveFilter, {
    required String companyId,
    String? assignedTo,
    String? managerId,
    String? teamId,
  }) {
    emit(state.copyWith(archiveFilter: archiveFilter));
    watchClients(
      companyId: companyId,
      assignedTo: assignedTo,
      managerId: managerId,
      teamId: teamId,
      archiveFilter: archiveFilter,
    );
  }


  Future<void> _refreshKpiCounts({
    required String reason,
    bool force = false,
  }) {
    if (_isClosing || isClosed) {
      return Future<void>.value();
    }
    final companyId = _watchedCompanyId;
    if (companyId == null || companyId.trim().isEmpty) {
      return Future<void>.value();
    }
    final scopeKey = _kpiScopeKey(
      companyId: companyId,
      assignedTo: _watchedAssignedTo,
      managerId: _watchedManagerId,
      teamId: _watchedTeamId,
      archiveFilter: _watchedArchiveFilter,
    );

    final inFlight = _inFlightKpiRefresh;
    if (!force && inFlight != null && _inFlightKpiRefreshKey == scopeKey) {
      _masarClientsCubitDebug(
        'kpi skipped duplicate inFlight reason=$reason key=$scopeKey',
      );
      return inFlight;
    }

    final cachedCounts = _cachedKpiCountsFor(scopeKey: scopeKey);
    final stateHasKpiCounts = state.kpiCounts.hasAll(_kpiCountKeys);
    final hasSameSuccessfulScope = _lastSuccessfulKpiRefreshKey == scopeKey;
    if (!force &&
        reason == 'watch-start' &&
        hasSameSuccessfulScope &&
        (stateHasKpiCounts || cachedCounts != null)) {
      final rehydrated = !stateHasKpiCounts && cachedCounts != null;
      _masarClientsCubitDebug(
        'kpi skipped cached watch-start key=$scopeKey '
        'stateHadCounts=$stateHasKpiCounts rehydrated=$rehydrated '
        'ageMs=${_cachedKpiAgeMs()}',
      );
      if (rehydrated && !isClosed && !_isClosing) {
        emit(state.copyWith(kpiCounts: cachedCounts));
        _debugCheckKpiInvariant();
      }
      return Future<void>.value();
    }

    final lastAt = _lastSuccessfulKpiRefreshAt;
    if (!force &&
        reason == 'stream-data' &&
        cachedCounts != null &&
        lastAt != null &&
        DateTime.now().difference(lastAt) < _streamKpiRefreshDebounce) {
      final rehydrated = !stateHasKpiCounts;
      _masarClientsCubitDebug(
        'kpi skipped recent stream-data key=$scopeKey '
        'stateHadCounts=$stateHasKpiCounts rehydrated=$rehydrated '
        'ageMs=${_cachedKpiAgeMs()}',
      );
      if (rehydrated && !isClosed && !_isClosing) {
        emit(state.copyWith(kpiCounts: cachedCounts));
        _debugCheckKpiInvariant();
      }
      return Future<void>.value();
    }

    final refreshSerial = ++_kpiRefreshSerial;
    final refresh = _runKpiRefresh(
      companyId: companyId,
      assignedTo: _watchedAssignedTo,
      managerId: _watchedManagerId,
      teamId: _watchedTeamId,
      archiveFilter: _watchedArchiveFilter,
      scopeKey: scopeKey,
      reason: reason,
      refreshSerial: refreshSerial,
      bypassCache: force,
    );
    _inFlightKpiRefresh = refresh;
    _inFlightKpiRefreshKey = scopeKey;
    refresh.whenComplete(() {
      if (identical(_inFlightKpiRefresh, refresh)) {
        _inFlightKpiRefresh = null;
        _inFlightKpiRefreshKey = null;
      }
    });
    return refresh;
  }

  Future<void> _runKpiRefresh({
    required String companyId,
    required String? assignedTo,
    required String? managerId,
    required String? teamId,
    required ArchiveFilter archiveFilter,
    required String scopeKey,
    required String reason,
    required int refreshSerial,
    required bool bypassCache,
  }) async {
    try {
      _masarClientsCubitDebug(
        'kpi start reason=$reason company=$companyId assignedTo=$assignedTo '
        'managerId=$managerId teamId=$teamId archive=${archiveFilter.name} '
        'key=$scopeKey',
      );
      final counts = await _countsDataSource.clientCounts(
        companyId: companyId,
        assignedTo: assignedTo,
        managerId: managerId,
        teamId: teamId,
        archiveFilter: archiveFilter,
        bypassCache: bypassCache,
      );
      final currentKey = _currentKpiScopeKey();
      final shouldApply = !_isClosing &&
          !isClosed &&
          _kpiRefreshSerial == refreshSerial &&
          currentKey == scopeKey;
      if (shouldApply) {
        _lastSuccessfulKpiRefreshKey = scopeKey;
        _lastSuccessfulKpiRefreshAt = DateTime.now();
        _lastSuccessfulKpiCounts = counts;
        _masarClientsCubitDebug(
          'kpi success reason=$reason company=$companyId assignedTo=$assignedTo '
          'managerId=$managerId teamId=$teamId archive=${archiveFilter.name} '
          'kpi=${_debugKpiCounts(counts)}',
        );
        emit(state.copyWith(kpiCounts: counts));
        _debugCheckKpiInvariant();
      } else {
        final discardReason = _isClosing || isClosed
            ? 'cubitClosed'
            : _kpiRefreshSerial != refreshSerial
                ? 'serialChanged'
                : currentKey != scopeKey
                    ? 'scopeChanged'
                    : 'unknown';
        _masarClientsCubitDebug(
          'kpi discarded stale reason=$reason discardReason=$discardReason '
          'company=$companyId key=$scopeKey serial=$refreshSerial '
          'latestSerial=$_kpiRefreshSerial currentKey=$currentKey '
          'isClosing=$_isClosing isClosed=$isClosed',
        );
      }
    } catch (error) {
      _masarClientsCubitDebug(
        'kpi error reason=$reason company=$companyId assignedTo=$assignedTo '
        'managerId=$managerId teamId=$teamId archive=${archiveFilter.name} '
        'errorType=${error.runtimeType} error=$error',
      );
      final currentKey = _currentKpiScopeKey();
      if (!_isClosing &&
          !isClosed &&
          _kpiRefreshSerial == refreshSerial &&
          currentKey == scopeKey) {
        emit(
          state.copyWith(
            kpiCounts: ModuleKpiCounts(
              const <String, int>{},
              failedKeys: _kpiCountKeys.toSet(),
            ),
          ),
        );
      }
    }
  }

  String? _currentKpiScopeKey() {
    final companyId = _watchedCompanyId;
    if (companyId == null || companyId.trim().isEmpty) {
      return null;
    }
    return _kpiScopeKey(
      companyId: companyId,
      assignedTo: _watchedAssignedTo,
      managerId: _watchedManagerId,
      teamId: _watchedTeamId,
      archiveFilter: _watchedArchiveFilter,
    );
  }

  ModuleKpiCounts? _cachedKpiCountsFor({required String scopeKey}) {
    final cachedCounts = _lastSuccessfulKpiCounts;
    final lastAt = _lastSuccessfulKpiRefreshAt;
    if (_lastSuccessfulKpiRefreshKey != scopeKey ||
        cachedCounts == null ||
        !cachedCounts.hasAll(_kpiCountKeys) ||
        lastAt == null) {
      return null;
    }
    return cachedCounts;
  }

  int? _cachedKpiAgeMs() {
    final lastAt = _lastSuccessfulKpiRefreshAt;
    if (lastAt == null) {
      return null;
    }
    return DateTime.now().difference(lastAt).inMilliseconds;
  }

  String _kpiScopeKey({
    required String companyId,
    required String? assignedTo,
    required String? managerId,
    required String? teamId,
    required ArchiveFilter archiveFilter,
  }) {
    return <String>[
      companyId.trim(),
      assignedTo?.trim() ?? '',
      managerId?.trim() ?? '',
      teamId?.trim() ?? '',
      archiveFilter.name,
    ].join('|');
  }

  void _debugCheckKpiInvariant() {
    debugCheckModuleKpiInvariant(
      module: 'clients',
      loadedRows: state.clients.length,
      totalCount: state.kpiCounts.valueOrNull('total'),
      hasLocalFilters: state.hasLocalTableFilters,
      scopeLabel: state.archiveFilter.name,
    );
  }

  int _effectiveWatchLimit(int pageLimit) {
    return state.hasLocalTableFilters ? _filterModeWatchLimit : pageLimit;
  }

  void loadMoreClients() {
    final companyId = _watchedCompanyId;
    if (companyId == null ||
        companyId.isEmpty ||
        state.status == ClientsStatus.loading ||
        state.status == ClientsStatus.loadingMore) {
      return;
    }

    final nextLimit = state.pageLimit + _pageIncrement;
    if (state.filteredClients.length > state.pageLimit) {
      emit(state.copyWith(pageLimit: nextLimit));
      _debugCheckKpiInvariant();
      return;
    }
    if (!state.canLoadMore) {
      return;
    }

    watchClients(
      companyId: companyId,
      assignedTo: _watchedAssignedTo,
      managerId: _watchedManagerId,
      teamId: _watchedTeamId,
      archiveFilter: _watchedArchiveFilter,
      limit: nextLimit,
      resetPage: false,
    );
  }

  void _reloadCurrentClientScopeAfterFilterChange() {
    final companyId = _watchedCompanyId;
    if (companyId == null || companyId.trim().isEmpty) {
      return;
    }
    watchClients(
      companyId: companyId,
      assignedTo: _watchedAssignedTo,
      managerId: _watchedManagerId,
      teamId: _watchedTeamId,
      archiveFilter: _watchedArchiveFilter,
      resetPage: true,
      usePagination: !state.hasLocalTableFilters,
    );
  }

  void watchClient({required String companyId, required String clientId}) {
    emit(
      state.copyWith(
        status: ClientsStatus.loading,
        clearMessage: true,
        clearLastAction: true,
        clearSelectedClient: true,
      ),
    );
    _clientSubscription?.cancel();
    _clientInitialLoadTimeout.start(() {
      if (isClosed ||
          state.status != ClientsStatus.loading ||
          state.selectedClient != null) {
        return;
      }
      emit(
        state.copyWith(
          status: ClientsStatus.failure,
          message: AppErrorMessages.connectionTimeout,
        ),
      );
    });
    _clientSubscription = _watchClientUseCase(
      companyId: companyId,
      clientId: clientId,
    ).listen(
      (client) {
        if (isClosed) {
          return;
        }
        _clientInitialLoadTimeout.complete();
        emit(
          state.copyWith(
            status: client == null ? ClientsStatus.empty : ClientsStatus.loaded,
            selectedClient: client,
            clearMessage: true,
          ),
        );
      },
      onError: (error) {
        if (isClosed) {
          return;
        }
        _clientInitialLoadTimeout.complete();
        emit(
          state.copyWith(
            status: ClientsStatus.failure,
            message: _clientErrorMessage(error, AppErrorMessages.unknown),
          ),
        );
      },
    );
  }

  void setSearchQuery(String query) {
    emit(
      state.copyWith(
        searchQuery: query,
        pageLimit: _defaultPageLimit,
        filteredClients: _applyFilters(state.clients, searchQuery: query),
      ),
    );
    _reloadCurrentClientScopeAfterFilterChange();
  }

  void setAssignedToFilter(String? assignedTo) {
    emit(
      state.copyWith(
        assignedToFilter: assignedTo,
        pageLimit: _defaultPageLimit,
        clearAssignedToFilter: assignedTo == null,
        filteredClients: _applyFilters(
          state.clients,
          assignedToFilter: assignedTo,
          overrideAssignedToFilter: true,
        ),
      ),
    );
    _reloadCurrentClientScopeAfterFilterChange();
  }


  void applyKpiFilter(String? assignedToFilter) {
    emit(
      state.copyWith(
        searchQuery: '',
        assignedToFilter: assignedToFilter,
        pageLimit: _defaultPageLimit,
        clearAssignedToFilter: assignedToFilter == null,
        filteredClients: _applyFilters(
          state.clients,
          searchQuery: '',
          assignedToFilter: assignedToFilter,
          overrideAssignedToFilter: true,
        ),
      ),
    );
    _reloadCurrentClientScopeAfterFilterChange();
  }

  Future<void> createClient({
    required String companyId,
    required Client client,
  }) async {
    emit(
      state.copyWith(
        status: ClientsStatus.saving,
        clearMessage: true,
        clearLastAction: true,
      ),
    );
    try {
      final createdClient = await _createClientUseCase(
        companyId: companyId,
        client: client,
      );
      unawaited(
        _writeAuditLog(
          companyId: companyId,
          actorId: createdClient.createdBy,
          action: AuditLogAction.create,
          recordId: createdClient.id,
          recordTitle: _clientTitle(createdClient),
          recordSubtitle: _clientSubtitle(createdClient),
          metadata: {
            'assignedTo': createdClient.assignedTo,
            'assignedToName': createdClient.assignedToName,
            'teamId': createdClient.teamId,
            'teamName': createdClient.teamName,
            'managerId': createdClient.managerId,
            'managerName': createdClient.managerName,
          },
        ),
      );
      if (isClosed) {
        return;
      }
      emit(
        state.copyWith(
          status: ClientsStatus.saved,
          clearMessage: true,
          lastAction: ClientsAction.createClient,
        ),
      );
      unawaited(_refreshKpiCounts(reason: 'mutation', force: true));
    } on ClientException catch (error) {
      if (isClosed) {
        return;
      }
      emit(
        state.copyWith(
          status: ClientsStatus.failure,
          message: error.message,
          lastAction: ClientsAction.createClient,
        ),
      );
    } catch (_) {
      if (isClosed) {
        return;
      }
      emit(
        state.copyWith(
          status: ClientsStatus.failure,
          message: AppErrorMessages.unknown,
          lastAction: ClientsAction.createClient,
        ),
      );
    }
  }

  Future<void> updateClient({
    required String companyId,
    required Client client,
  }) async {
    emit(
      state.copyWith(
        status: ClientsStatus.saving,
        clearMessage: true,
        clearLastAction: true,
      ),
    );
    try {
      final updatedClient = await _updateClientUseCase(
        companyId: companyId,
        client: client,
      );
      unawaited(
        _writeAuditLog(
          companyId: companyId,
          actorId: updatedClient.updatedBy,
          action: AuditLogAction.update,
          recordId: updatedClient.id,
          recordTitle: _clientTitle(updatedClient),
          recordSubtitle: _clientSubtitle(updatedClient),
          metadata: {
            'assignedTo': updatedClient.assignedTo,
            'assignedToName': updatedClient.assignedToName,
            'teamId': updatedClient.teamId,
            'teamName': updatedClient.teamName,
            'managerId': updatedClient.managerId,
            'managerName': updatedClient.managerName,
          },
        ),
      );
      if (isClosed) {
        return;
      }
      final updatedClients = _replaceClientInCurrentList(updatedClient);
      emit(
        state.copyWith(
          status: ClientsStatus.saved,
          clients: updatedClients,
          filteredClients: _applyFilters(
            updatedClients,
            searchQuery: state.searchQuery,
            assignedToFilter: state.assignedToFilter,
            overrideAssignedToFilter: true,
          ),
          selectedClient: state.selectedClient?.id == updatedClient.id
              ? updatedClient
              : state.selectedClient,
          clearMessage: true,
          lastAction: ClientsAction.updateClient,
        ),
      );
      unawaited(_refreshKpiCounts(reason: 'mutation', force: true));
    } on ClientException catch (error) {
      if (isClosed) {
        return;
      }
      emit(
        state.copyWith(
          status: ClientsStatus.failure,
          message: error.message,
          lastAction: ClientsAction.updateClient,
        ),
      );
    } catch (_) {
      if (isClosed) {
        return;
      }
      emit(
        state.copyWith(
          status: ClientsStatus.failure,
          message: AppErrorMessages.unknown,
          lastAction: ClientsAction.updateClient,
        ),
      );
    }
  }

  Future<bool> assignClient({
    required String companyId,
    required String clientId,
    required String assignedTo,
    required String assignedToName,
    required String assignedToEmail,
    required String teamId,
    required String teamName,
    required String managerId,
    required String managerName,
    required String updatedBy,
  }) async {
    emit(
      state.copyWith(
        status: ClientsStatus.saving,
        clearMessage: true,
        clearLastAction: true,
      ),
    );
    try {
      await _assignClientUseCase(
        companyId: companyId,
        clientId: clientId,
        assignedTo: assignedTo,
        assignedToName: assignedToName,
        assignedToEmail: assignedToEmail,
        teamId: teamId,
        teamName: teamName,
        managerId: managerId,
        managerName: managerName,
        updatedBy: updatedBy,
      );
      final client = _clientById(clientId);
      unawaited(
        _writeAuditLog(
          companyId: companyId,
          actorId: updatedBy,
          action: AuditLogAction.assign,
          recordId: clientId,
          recordTitle: client == null ? 'Client' : _clientTitle(client),
          recordSubtitle: client == null ? '' : _clientSubtitle(client),
          metadata: {
            'assignedTo': assignedTo,
            'assignedToName': assignedToName,
            'teamId': teamId,
            'teamName': teamName,
            'managerId': managerId,
            'managerName': managerName,
          },
        ),
      );
      if (isClosed) {
        return true;
      }
      final currentClient = _clientById(clientId);
      final updatedClient = currentClient == null
          ? null
          : _clientWithAssignment(
              currentClient,
              assignedTo: assignedTo,
              assignedToName: assignedToName,
              assignedToEmail: assignedToEmail,
              teamId: teamId,
              teamName: teamName,
              managerId: managerId,
              managerName: managerName,
              updatedBy: updatedBy,
            );
      final updatedClients = updatedClient == null
          ? state.clients
          : _replaceClientInCurrentList(updatedClient);
      emit(
        state.copyWith(
          status: ClientsStatus.saved,
          clients: updatedClients,
          filteredClients: _applyFilters(
            updatedClients,
            searchQuery: state.searchQuery,
            assignedToFilter: state.assignedToFilter,
            overrideAssignedToFilter: true,
          ),
          selectedClient: state.selectedClient?.id == clientId
              ? updatedClient
              : state.selectedClient,
          clearMessage: true,
          lastAction: ClientsAction.assignClient,
        ),
      );
      unawaited(_refreshKpiCounts(reason: 'mutation', force: true));
      return true;
    } on ClientException catch (error) {
      if (isClosed) {
        return false;
      }
      emit(
        state.copyWith(
          status: ClientsStatus.failure,
          message: error.message,
          lastAction: ClientsAction.assignClient,
        ),
      );
    } catch (_) {
      if (isClosed) {
        return false;
      }
      emit(
        state.copyWith(
          status: ClientsStatus.failure,
          message: AppErrorMessages.unknown,
          lastAction: ClientsAction.assignClient,
        ),
      );
    }
    return false;
  }

  Future<bool> archiveClient({
    required String companyId,
    required String clientId,
    required String updatedBy,
    String reason = '',
  }) async {
    emit(
      state.copyWith(
        status: ClientsStatus.saving,
        clearMessage: true,
        clearLastAction: true,
      ),
    );
    try {
      await _archiveClientUseCase(
        companyId: companyId,
        clientId: clientId,
        updatedBy: updatedBy,
        reason: reason,
      );
      final client = _clientById(clientId);
      unawaited(
        _writeAuditLog(
          companyId: companyId,
          actorId: updatedBy,
          action: AuditLogAction.archive,
          recordId: clientId,
          recordTitle: client == null ? 'Client' : _clientTitle(client),
          recordSubtitle: client == null ? '' : _clientSubtitle(client),
          metadata: {
            if (client != null) ...{
              'assignedTo': client.assignedTo,
              'assignedToName': client.assignedToName,
              'teamId': client.teamId,
              'teamName': client.teamName,
              'managerId': client.managerId,
              'managerName': client.managerName,
            },
          },
        ),
      );
      if (isClosed) {
        return true;
      }
      emit(
        state.copyWith(
          status: ClientsStatus.saved,
          clearMessage: true,
          lastAction: ClientsAction.archiveClient,
        ),
      );
      unawaited(_refreshKpiCounts(reason: 'mutation', force: true));
      return true;
    } on ClientException catch (error) {
      if (isClosed) {
        return false;
      }
      emit(
        state.copyWith(
          status: ClientsStatus.failure,
          message: error.message,
          lastAction: ClientsAction.archiveClient,
        ),
      );
    } catch (_) {
      if (isClosed) {
        return false;
      }
      emit(
        state.copyWith(
          status: ClientsStatus.failure,
          message: AppErrorMessages.unknown,
          lastAction: ClientsAction.archiveClient,
        ),
      );
    }
    return false;
  }

  Future<bool> restoreClient({
    required String companyId,
    required String clientId,
    required String updatedBy,
  }) async {
    emit(
      state.copyWith(
        status: ClientsStatus.saving,
        clearMessage: true,
        clearLastAction: true,
      ),
    );
    try {
      await _restoreClientUseCase(
        companyId: companyId,
        clientId: clientId,
        updatedBy: updatedBy,
      );
      final client = _clientById(clientId);
      unawaited(
        _writeAuditLog(
          companyId: companyId,
          actorId: updatedBy,
          action: AuditLogAction.update,
          recordId: clientId,
          recordTitle: client == null ? 'Client' : _clientTitle(client),
          recordSubtitle: client == null ? '' : _clientSubtitle(client),
          metadata: {
            'restoreAction': 'restore',
            if (client != null) ...{
              'assignedTo': client.assignedTo,
              'assignedToName': client.assignedToName,
              'teamId': client.teamId,
              'teamName': client.teamName,
              'managerId': client.managerId,
              'managerName': client.managerName,
            },
          },
        ),
      );
      if (isClosed) {
        return true;
      }
      emit(
        state.copyWith(
          status: ClientsStatus.saved,
          clearMessage: true,
          lastAction: ClientsAction.restoreClient,
        ),
      );
      unawaited(_refreshKpiCounts(reason: 'mutation', force: true));
      return true;
    } on ClientException catch (error) {
      if (isClosed) {
        return false;
      }
      emit(
        state.copyWith(
          status: ClientsStatus.failure,
          message: error.message,
          lastAction: ClientsAction.restoreClient,
        ),
      );
    } catch (_) {
      if (isClosed) {
        return false;
      }
      emit(
        state.copyWith(
          status: ClientsStatus.failure,
          message: AppErrorMessages.unknown,
          lastAction: ClientsAction.restoreClient,
        ),
      );
    }
    return false;
  }

  void clearAction() {
    emit(state.copyWith(clearLastAction: true));
  }

  String _clientErrorMessage(Object error, String fallback) {
    if (error is ClientException) {
      return error.message;
    }

    return fallback;
  }

  Future<void> _writeAuditLog({
    required String companyId,
    required String actorId,
    required AuditLogAction action,
    required String recordId,
    required String recordTitle,
    required String recordSubtitle,
    required Map<String, Object?> metadata,
  }) async {
    try {
      await _createAuditLogUseCase(
        companyId: companyId,
        auditLog: AuditLog(
          id: '',
          companyId: companyId,
          actorId: actorId,
          actorName: '',
          actorEmail: '',
          actorRole: '',
          action: action,
          module: AuditLogModule.clients,
          recordId: recordId,
          recordTitle: recordTitle,
          recordSubtitle: recordSubtitle,
          createdAt: DateTime.now(),
          metadata: metadata,
        ),
      );
    } catch (_) {
      // Audit logging is best-effort and must not block client workflows.
    }
  }

  Client? _clientById(String clientId) {
    if (state.selectedClient?.id == clientId) {
      return state.selectedClient;
    }
    for (final client in state.clients) {
      if (client.id == clientId) {
        return client;
      }
    }
    return null;
  }


  List<Client> _replaceClientInCurrentList(Client updated) {
    final index = state.clients.indexWhere((client) => client.id == updated.id);
    if (index < 0) {
      return state.clients;
    }
    final next = List<Client>.of(state.clients);
    next[index] = updated;
    return next;
  }

  Client _clientWithAssignment(
    Client client, {
    required String assignedTo,
    required String assignedToName,
    required String assignedToEmail,
    required String teamId,
    required String teamName,
    required String managerId,
    required String managerName,
    required String updatedBy,
  }) {
    return Client(
      id: client.id,
      companyId: client.companyId,
      fullName: client.fullName,
      phone: client.phone,
      email: client.email,
      budgetMin: client.budgetMin,
      budgetMax: client.budgetMax,
      preferredLocation: client.preferredLocation,
      preferredPropertyType: client.preferredPropertyType,
      notes: client.notes,
      assignedTo: assignedTo.trim(),
      assignedToName: assignedToName.trim(),
      assignedToEmail: assignedToEmail.trim(),
      teamId: teamId.trim(),
      teamName: teamName.trim(),
      managerId: managerId.trim(),
      managerName: managerName.trim(),
      isActive: client.isActive,
      createdAt: client.createdAt,
      updatedAt: DateTime.now(),
      createdBy: client.createdBy,
      updatedBy: updatedBy,
      isArchived: client.isArchived,
      archivedAt: client.archivedAt,
      archivedBy: client.archivedBy,
      archivedByName: client.archivedByName,
      archiveReason: client.archiveReason,
      restoredAt: client.restoredAt,
      restoredBy: client.restoredBy,
      restoredByName: client.restoredByName,
    );
  }

  List<Client> _applyFilters(
    List<Client> clients, {
    String? searchQuery,
    String? assignedToFilter,
    bool overrideAssignedToFilter = false,
  }) {
    final query = (searchQuery ?? '').trim().toLowerCase();
    final selectedAssignedTo = overrideAssignedToFilter
        ? assignedToFilter?.trim()
        : (assignedToFilter ?? state.assignedToFilter)?.trim();
    final filtered = clients.where((client) {
      final matchesSearch = query.isEmpty ||
          client.fullName.toLowerCase().contains(query) ||
          client.phone.toLowerCase().contains(query) ||
          client.email.toLowerCase().contains(query) ||
          client.preferredLocation.toLowerCase().contains(query) ||
          client.preferredPropertyType.toLowerCase().contains(query) ||
          client.assignedToName.toLowerCase().contains(query) ||
          client.assignedToEmail.toLowerCase().contains(query);
      final matchesAssignee = selectedAssignedTo == null ||
          selectedAssignedTo.isEmpty ||
          (selectedAssignedTo == '__assigned__' &&
              client.assignedTo.trim().isNotEmpty) ||
          (selectedAssignedTo == '__unassigned__' &&
              client.assignedTo.trim().isEmpty) ||
          client.assignedTo == selectedAssignedTo;
      return matchesSearch && matchesAssignee;
    }).toList();

    filtered.sort((a, b) {
      final aDate = a.updatedAt ?? a.createdAt ?? DateTime(0);
      final bDate = b.updatedAt ?? b.createdAt ?? DateTime(0);
      return bDate.compareTo(aDate);
    });
    return filtered;
  }

  @override
  Future<void> close() {
    _isClosing = true;
    _clientsInitialLoadTimeout.cancel();
    _clientInitialLoadTimeout.cancel();
    _clientsSubscription?.cancel();
    _clientSubscription?.cancel();
    return super.close();
  }
}


void _masarClientsCubitDebug(String message) {
  assert(() {
    // ignore: avoid_print
    print('MasarClientsCubitDebug $message');
    return true;
  }());
}

String _debugKpiCounts(ModuleKpiCounts counts) {
  final values = _debugCompactValues(counts.values);
  final failed = counts.failedKeys.toList()..sort();
  return 'values={$values} failed=$failed';
}

String _debugCompactValues(Map<String, int> values) {
  if (values.isEmpty) {
    return '';
  }
  final keys = values.keys.toList()..sort();
  return keys.map((key) => '$key=${values[key]}').join(',');
}

String _clientTitle(Client client) {
  final name = client.fullName.trim();
  return name.isEmpty ? 'Client' : name;
}

String _clientSubtitle(Client client) {
  final phone = client.phone.trim();
  if (phone.isNotEmpty) {
    return phone;
  }
  return client.email.trim();
}
