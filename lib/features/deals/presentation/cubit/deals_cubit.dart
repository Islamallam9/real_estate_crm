import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/archive/archive_filter.dart';
import '../../../../core/constants/role_constants.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/stats/module_kpi_counts_data_source.dart';
import '../../../../core/utils/initial_load_timeout.dart';
import '../../../audit_logs/domain/entities/audit_log.dart';
import '../../../audit_logs/domain/usecases/create_audit_log_usecase.dart';
import '../../../dashboard/domain/services/dashboard_truth_rules.dart';
import '../../data/datasources/deals_remote_data_source.dart';
import '../../data/models/deal_model.dart';
import '../../domain/entities/deal.dart';
import '../../domain/usecases/archive_deal_usecase.dart';
import '../../domain/usecases/create_deal_usecase.dart';
import '../../domain/usecases/restore_deal_usecase.dart';
import '../../domain/usecases/update_deal_stage_usecase.dart';
import '../../domain/usecases/update_deal_usecase.dart';
import '../../domain/usecases/watch_deal_usecase.dart';
import '../../domain/usecases/watch_deals_usecase.dart';
import 'deals_state.dart';

void _masarDealsCubitDebug(String message) {
  if (!kDebugMode) {
    return;
  }
  debugPrint('MasarDealsCubitDebug $message');
}

class DealsCubit extends Cubit<DealsState> {
  DealsCubit({
    required WatchDealUseCase watchDealUseCase,
    required WatchDealsUseCase watchDealsUseCase,
    required CreateDealUseCase createDealUseCase,
    required UpdateDealUseCase updateDealUseCase,
    required UpdateDealStageUseCase updateDealStageUseCase,
    required ArchiveDealUseCase archiveDealUseCase,
    required RestoreDealUseCase restoreDealUseCase,
    required CreateAuditLogUseCase createAuditLogUseCase,
  }) : _watchDealUseCase = watchDealUseCase,
       _watchDealsUseCase = watchDealsUseCase,
       _createDealUseCase = createDealUseCase,
       _updateDealUseCase = updateDealUseCase,
       _updateDealStageUseCase = updateDealStageUseCase,
       _archiveDealUseCase = archiveDealUseCase,
       _restoreDealUseCase = restoreDealUseCase,
       _createAuditLogUseCase = createAuditLogUseCase,
       super(const DealsState.initial());

  final WatchDealUseCase _watchDealUseCase;
  final WatchDealsUseCase _watchDealsUseCase;
  final CreateDealUseCase _createDealUseCase;
  final UpdateDealUseCase _updateDealUseCase;
  final UpdateDealStageUseCase _updateDealStageUseCase;
  final ArchiveDealUseCase _archiveDealUseCase;
  final RestoreDealUseCase _restoreDealUseCase;
  final CreateAuditLogUseCase _createAuditLogUseCase;
  final FirestoreModuleKpiCountsDataSource _countsDataSource =
      FirestoreModuleKpiCountsDataSource();

  StreamSubscription<dynamic>? _dealsSubscription;
  String? _watchedCompanyId;
  UserRole? _watchedRole;
  String? _watchedCurrentUserId;
  String? _watchedTeamId;
  ArchiveFilter _watchedArchiveFilter = ArchiveFilter.active;
  String? _activeDealsWatchKey;
  String? _activeDealsWatchFamilyKey;
  DateTime? _activeDealsWatchStartedAt;
  int? _activeDealsWatchLimit;
  int _dealsWatchGeneration = 0;
  Future<void>? _inFlightKpiRefresh;
  String? _inFlightKpiRefreshKey;
  String? _lastSuccessfulKpiRefreshKey;
  DateTime? _lastSuccessfulKpiRefreshAt;
  int _kpiRefreshSerial = 0;
  bool _isClosing = false;
  static const Duration _streamKpiRefreshDebounce =
      Duration(milliseconds: 1500);
  static const Duration _duplicateWatchStartDebounce =
      Duration(milliseconds: 1500);
  static const int _defaultPageLimit = 15;
  static const int _pageIncrement = 15;
  static const List<String> _kpiCountKeys = <String>[
    'total',
    'open',
    'atRisk',
    'wonThisMonth',
    'lost',
  ];
  static const int _dashboardWatchLimit = 500;
  final InitialLoadTimeout _dealsInitialLoadTimeout = InitialLoadTimeout();

  void watchDeal({
    required String companyId,
    required String dealId,
  }) {
    _activeDealsWatchKey = null;
    _activeDealsWatchFamilyKey = null;
    _activeDealsWatchStartedAt = null;
    _activeDealsWatchLimit = null;
    _dealsWatchGeneration++;
    emit(
      state.copyWith(
        status: DealsStatus.loading,
        clearMessage: true,
        clearLastAction: true,
      ),
    );
    if (!state.kpiCounts.hasAll(_kpiCountKeys)) {
      unawaited(_refreshKpiCounts(reason: 'single-watch-start'));
    }
    _dealsSubscription?.cancel();
    _dealsInitialLoadTimeout.start(() {
      if (isClosed ||
          (state.status != DealsStatus.loading &&
              state.status != DealsStatus.loadingMore) ||
          state.deals.isNotEmpty) {
        return;
      }
      emit(
        state.copyWith(
          status: DealsStatus.failure,
          message: AppErrorMessages.connectionTimeout,
        ),
      );
    });
    _dealsSubscription = _watchDealUseCase(
      companyId: companyId,
      dealId: dealId,
    ).listen(
      (deal) {
        if (isClosed) {
          return;
        }
        _dealsInitialLoadTimeout.complete();
        final deals = deal == null ? const <Deal>[] : <Deal>[deal];
        emit(
          state.copyWith(
            status: deal == null ? DealsStatus.empty : DealsStatus.loaded,
            deals: deals,
            filteredDeals: deals,
            clearMessage: true,
          ),
        );
      },
      onError: (error) {
        if (isClosed) {
          return;
        }
        _masarDealsCubitDebug(
          'watchDeal error company=$companyId dealId=$dealId '
          'errorType=${error.runtimeType} error=$error',
        );
        _dealsInitialLoadTimeout.complete();
        emit(
          state.copyWith(
            status: DealsStatus.failure,
            message: _dealErrorMessage(error),
          ),
        );
      },
    );
  }

  void watchDeals({
    required String companyId,
    required UserRole role,
    required String currentUserId,
    String? teamId,
    ArchiveFilter archiveFilter = ArchiveFilter.active,
    int? limit,
    bool resetPage = true,
    bool usePagination = true,
  }) {
    _watchedCompanyId = companyId;
    _watchedRole = role;
    _watchedCurrentUserId = currentUserId;
    _watchedTeamId = teamId;
    _watchedArchiveFilter = archiveFilter;
    final pageLimit = usePagination
        ? (resetPage ? _defaultPageLimit : limit ?? state.pageLimit)
        : state.pageLimit;
    final watchLimit = usePagination ? pageLimit : _dashboardWatchLimit;
    final watchFamilyKey = _dealsWatchFamilyKey(
      companyId: companyId,
      role: role,
      currentUserId: currentUserId,
      teamId: teamId,
      archiveFilter: archiveFilter,
    );
    final watchKey = _dealsWatchKey(
      companyId: companyId,
      role: role,
      currentUserId: currentUserId,
      teamId: teamId,
      archiveFilter: archiveFilter,
      pageLimit: pageLimit,
      watchLimit: watchLimit,
      usePagination: usePagination,
    );
    final activeWatchLimit = _activeDealsWatchLimit;
    final hasReusableActiveWatch = resetPage &&
        _dealsSubscription != null &&
        _activeDealsWatchFamilyKey == watchFamilyKey &&
        activeWatchLimit != null &&
        activeWatchLimit >= watchLimit &&
        state.status != DealsStatus.failure &&
        (state.deals.isNotEmpty ||
            state.status == DealsStatus.loaded ||
            state.status == DealsStatus.saved ||
            state.status == DealsStatus.empty);
    if (hasReusableActiveWatch) {
      _masarDealsCubitDebug(
        'watchDeals skipped covered active company=$companyId '
        'role=${role.name} currentUserId=$currentUserId teamId=$teamId '
        'archive=${archiveFilter.name} usePagination=$usePagination '
        'resetPage=$resetPage pageLimit=$pageLimit watchLimit=$watchLimit '
        'activeWatchLimit=$activeWatchLimit status=${state.status} '
        'rows=${state.deals.length} key=$watchKey activeKey=$_activeDealsWatchKey '
        'family=$watchFamilyKey kpi=${_debugKpiCounts(state.kpiCounts)}',
      );
      if (!state.kpiCounts.hasAll(_kpiCountKeys)) {
        unawaited(_refreshKpiCounts(reason: 'watch-covered-missing-kpi'));
      }
      return;
    }
    if (state.hasLocalFilters &&
        usePagination &&
        _dealsSubscription != null &&
        state.deals.isNotEmpty &&
        (_activeDealsWatchLimit ?? 0) >= _dashboardWatchLimit) {
      _masarDealsCubitDebug(
        'watchDeals skipped narrow reload while local filters active '
        'company=$companyId role=${role.name} currentUserId=$currentUserId '
        'teamId=$teamId archive=${archiveFilter.name} pageLimit=$pageLimit '
        'watchLimit=$watchLimit activeWatchLimit=$_activeDealsWatchLimit '
        'rows=${state.deals.length} status=${state.status} '
        'activeKey=$_activeDealsWatchKey family=$watchFamilyKey',
      );
      return;
    }
    final now = DateTime.now();
    final activeStartedAt = _activeDealsWatchStartedAt;
    final isRecentDuplicate = _activeDealsWatchKey == watchKey &&
        activeStartedAt != null &&
        now.difference(activeStartedAt) < _duplicateWatchStartDebounce;
    if (resetPage && _dealsSubscription != null && isRecentDuplicate) {
      _masarDealsCubitDebug(
        'watchDeals skipped duplicate active company=$companyId '
        'role=${role.name} currentUserId=$currentUserId teamId=$teamId '
        'archive=${archiveFilter.name} usePagination=$usePagination '
        'resetPage=$resetPage pageLimit=$pageLimit watchLimit=$watchLimit '
        'status=${state.status} rows=${state.deals.length} key=$watchKey '
        'family=$watchFamilyKey kpi=${_debugKpiCounts(state.kpiCounts)}',
      );
      if (!state.kpiCounts.hasAll(_kpiCountKeys)) {
        unawaited(_refreshKpiCounts(reason: 'watch-duplicate-missing-kpi'));
      }
      return;
    }
    final watchGeneration = ++_dealsWatchGeneration;
    _activeDealsWatchKey = watchKey;
    _activeDealsWatchFamilyKey = watchFamilyKey;
    _activeDealsWatchStartedAt = now;
    _activeDealsWatchLimit = watchLimit;
    _masarDealsCubitDebug(
      'watchDeals start gen=$watchGeneration company=$companyId '
      'role=${role.name} currentUserId=$currentUserId teamId=$teamId '
      'archive=${archiveFilter.name} usePagination=$usePagination '
      'resetPage=$resetPage pageLimit=$pageLimit watchLimit=$watchLimit '
      'currentRows=${state.deals.length} key=$watchKey '
      'kpi=${_debugKpiCounts(state.kpiCounts)}',
    );
    emit(
      state.copyWith(
        status: resetPage || state.deals.isEmpty
            ? DealsStatus.loading
            : DealsStatus.loadingMore,
        pageLimit: pageLimit,
        clearMessage: true,
        clearLastAction: true,
      ),
    );
    if (resetPage || !state.kpiCounts.hasAll(_kpiCountKeys)) {
      unawaited(_refreshKpiCounts(reason: 'watch-start'));
    }
    _dealsSubscription?.cancel();
    _dealsInitialLoadTimeout.start(() {
      if (isClosed ||
          (state.status != DealsStatus.loading &&
              state.status != DealsStatus.loadingMore) ||
          state.deals.isNotEmpty) {
        return;
      }
      emit(
        state.copyWith(
          status: DealsStatus.failure,
          message: AppErrorMessages.connectionTimeout,
        ),
      );
    });
    _dealsSubscription = _watchDealsUseCase(
      companyId: companyId,
      role: role,
      currentUserId: currentUserId,
      teamId: teamId,
      archiveFilter: archiveFilter,
      limit: watchLimit,
    ).listen(
      (deals) {
        if (isClosed) {
          return;
        }
        if (watchGeneration != _dealsWatchGeneration ||
            _activeDealsWatchKey != watchKey) {
          _masarDealsCubitDebug(
            'watchDeals data ignored stale gen=$watchGeneration '
            'latestGen=$_dealsWatchGeneration company=$companyId '
            'count=${deals.length} key=$watchKey activeKey=$_activeDealsWatchKey',
          );
          return;
        }
        _masarDealsCubitDebug(
          'watchDeals data gen=$watchGeneration company=$companyId '
          'count=${deals.length} role=${role.name} '
          'currentUserId=$currentUserId teamId=$teamId '
          'archive=${archiveFilter.name} watchLimit=$watchLimit key=$watchKey',
        );
        _dealsInitialLoadTimeout.complete();
        emit(
          state.copyWith(
            status: deals.isEmpty ? DealsStatus.empty : DealsStatus.loaded,
            deals: deals,
            filteredDeals: _applyFilters(deals),
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
        if (watchGeneration != _dealsWatchGeneration ||
            _activeDealsWatchKey != watchKey) {
          _masarDealsCubitDebug(
            'watchDeals error ignored stale gen=$watchGeneration '
            'latestGen=$_dealsWatchGeneration company=$companyId key=$watchKey '
            'activeKey=$_activeDealsWatchKey errorType=${error.runtimeType} '
            'error=$error',
          );
          return;
        }
        _masarDealsCubitDebug(
          'watchDeals error gen=$watchGeneration company=$companyId '
          'role=${role.name} currentUserId=$currentUserId teamId=$teamId '
          'archive=${archiveFilter.name} watchLimit=$watchLimit key=$watchKey '
          'errorType=${error.runtimeType} error=$error',
        );
        _dealsInitialLoadTimeout.complete();
        emit(
          state.copyWith(
            status: DealsStatus.failure,
            message: _dealErrorMessage(error),
          ),
        );
      },
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
    final role = _watchedRole;
    final currentUserId = _watchedCurrentUserId;
    if (companyId == null ||
        companyId.trim().isEmpty ||
        role == null ||
        currentUserId == null ||
        currentUserId.trim().isEmpty) {
      return Future<void>.value();
    }

    final scopeKey = _kpiScopeKey(
      companyId: companyId,
      role: role,
      currentUserId: currentUserId,
      teamId: _watchedTeamId,
      archiveFilter: _watchedArchiveFilter,
    );
    final inFlight = _inFlightKpiRefresh;
    if (!force && inFlight != null && _inFlightKpiRefreshKey == scopeKey) {
      _masarDealsCubitDebug(
        'kpi skipped duplicate inFlight reason=$reason key=$scopeKey',
      );
      return inFlight;
    }

    final lastAt = _lastSuccessfulKpiRefreshAt;
    if (!force &&
        reason == 'stream-data' &&
        _lastSuccessfulKpiRefreshKey == scopeKey &&
        lastAt != null &&
        DateTime.now().difference(lastAt) < _streamKpiRefreshDebounce) {
      _masarDealsCubitDebug(
        'kpi skipped recent stream-data key=$scopeKey',
      );
      return Future<void>.value();
    }

    final refreshSerial = ++_kpiRefreshSerial;
    final refresh = _runKpiRefresh(
      companyId: companyId,
      role: role,
      currentUserId: currentUserId,
      teamId: _watchedTeamId,
      archiveFilter: _watchedArchiveFilter,
      scopeKey: scopeKey,
      reason: reason,
      refreshSerial: refreshSerial,
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
    required UserRole role,
    required String currentUserId,
    required String? teamId,
    required ArchiveFilter archiveFilter,
    required String scopeKey,
    required String reason,
    required int refreshSerial,
  }) async {
    try {
      _masarDealsCubitDebug(
        'kpi start reason=$reason company=$companyId role=${role.name} '
        'currentUserId=$currentUserId teamId=$teamId '
        'archive=${archiveFilter.name} key=$scopeKey',
      );
      final counts = await _countsDataSource.dealCounts(
        companyId: companyId,
        role: role,
        currentUserId: currentUserId,
        teamId: teamId,
        archiveFilter: archiveFilter,
      );
      final currentKey = _currentKpiScopeKey();
      final shouldApply = !_isClosing &&
          !isClosed &&
          _kpiRefreshSerial == refreshSerial &&
          currentKey == scopeKey;
      if (shouldApply) {
        _lastSuccessfulKpiRefreshKey = scopeKey;
        _lastSuccessfulKpiRefreshAt = DateTime.now();
        _masarDealsCubitDebug(
          'kpi success reason=$reason company=$companyId role=${role.name} '
          'currentUserId=$currentUserId teamId=$teamId '
          'archive=${archiveFilter.name} kpi=${_debugKpiCounts(counts)}',
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
        _masarDealsCubitDebug(
          'kpi discarded stale reason=$reason discardReason=$discardReason '
          'company=$companyId key=$scopeKey serial=$refreshSerial '
          'latestSerial=$_kpiRefreshSerial currentKey=$currentKey '
          'isClosing=$_isClosing isClosed=$isClosed',
        );
      }
    } catch (error) {
      _masarDealsCubitDebug(
        'kpi error reason=$reason company=$companyId role=${role.name} '
        'currentUserId=$currentUserId teamId=$teamId '
        'archive=${archiveFilter.name} errorType=${error.runtimeType} '
        'error=$error',
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
    final role = _watchedRole;
    final currentUserId = _watchedCurrentUserId;
    if (companyId == null ||
        companyId.trim().isEmpty ||
        role == null ||
        currentUserId == null ||
        currentUserId.trim().isEmpty) {
      return null;
    }
    return _kpiScopeKey(
      companyId: companyId,
      role: role,
      currentUserId: currentUserId,
      teamId: _watchedTeamId,
      archiveFilter: _watchedArchiveFilter,
    );
  }

  String _kpiScopeKey({
    required String companyId,
    required UserRole role,
    required String currentUserId,
    required String? teamId,
    required ArchiveFilter archiveFilter,
  }) {
    return <String>[
      companyId.trim(),
      role.name,
      currentUserId.trim(),
      teamId?.trim() ?? '',
      archiveFilter.name,
    ].join('|');
  }

  String _dealsWatchFamilyKey({
    required String companyId,
    required UserRole role,
    required String currentUserId,
    required String? teamId,
    required ArchiveFilter archiveFilter,
  }) {
    return <String>[
      companyId.trim(),
      role.name,
      currentUserId.trim(),
      teamId?.trim() ?? '',
      archiveFilter.name,
    ].join('|');
  }

  String _dealsWatchKey({
    required String companyId,
    required UserRole role,
    required String currentUserId,
    required String? teamId,
    required ArchiveFilter archiveFilter,
    required int pageLimit,
    required int watchLimit,
    required bool usePagination,
  }) {
    return <String>[
      companyId.trim(),
      role.name,
      currentUserId.trim(),
      teamId?.trim() ?? '',
      archiveFilter.name,
      pageLimit.toString(),
      watchLimit.toString(),
      usePagination.toString(),
    ].join('|');
  }

  String _debugKpiCounts(ModuleKpiCounts counts) {
    final values = counts.values.entries
        .map((entry) => '${entry.key}=${entry.value}')
        .join(',');
    final failed = counts.failedKeys.join(',');
    return 'values={$values} failed=[$failed]';
  }

  void _debugCheckKpiInvariant() {
    debugCheckModuleKpiInvariant(
      module: 'deals',
      loadedRows: state.deals.length,
      totalCount: state.kpiCounts.valueOrNull('total'),
      hasLocalFilters: state.searchQuery.trim().isNotEmpty ||
          state.stageFilter != null ||
          state.assignedToFilter.trim().isNotEmpty ||
          state.closingDateFilter != null ||
          state.workQueueFilter != null,
      scopeLabel: state.archiveFilter.name,
    );
  }

  void loadMoreDeals() {
    final companyId = _watchedCompanyId;
    final role = _watchedRole;
    final currentUserId = _watchedCurrentUserId;
    if (companyId == null ||
        companyId.isEmpty ||
        role == null ||
        currentUserId == null ||
        currentUserId.isEmpty ||
        state.status == DealsStatus.loading ||
        state.status == DealsStatus.loadingMore) {
      return;
    }

    final nextLimit = state.pageLimit + _pageIncrement;
    if (state.filteredDeals.length > state.pageLimit) {
      emit(state.copyWith(pageLimit: nextLimit));
      _debugCheckKpiInvariant();
      return;
    }
    if (!state.canLoadMore) {
      return;
    }

    watchDeals(
      companyId: companyId,
      role: role,
      currentUserId: currentUserId,
      teamId: _watchedTeamId,
      archiveFilter: _watchedArchiveFilter,
      limit: nextLimit,
      resetPage: false,
    );
  }

  void _reloadCurrentDealScopeAfterFilterChange() {
    final companyId = _watchedCompanyId;
    final role = _watchedRole;
    final currentUserId = _watchedCurrentUserId;
    if (companyId == null ||
        companyId.trim().isEmpty ||
        role == null ||
        currentUserId == null ||
        currentUserId.trim().isEmpty) {
      return;
    }
    if (state.hasLocalFilters &&
        _dealsSubscription != null &&
        state.deals.isNotEmpty &&
        (_activeDealsWatchLimit ?? 0) >= _dashboardWatchLimit) {
      _masarDealsCubitDebug(
        'watchDeals skipped filter reload broad active company=$companyId '
        'role=${role.name} currentUserId=$currentUserId '
        'activeWatchLimit=$_activeDealsWatchLimit rows=${state.deals.length} '
        'status=${state.status} activeKey=$_activeDealsWatchKey',
      );
      return;
    }
    watchDeals(
      companyId: companyId,
      role: role,
      currentUserId: currentUserId,
      teamId: _watchedTeamId,
      archiveFilter: _watchedArchiveFilter,
      resetPage: true,
      usePagination: !state.hasLocalFilters,
    );
  }

  void setArchiveFilter(
    ArchiveFilter archiveFilter, {
    required String companyId,
    required UserRole role,
    required String currentUserId,
    String? teamId,
  }) {
    emit(state.copyWith(archiveFilter: archiveFilter));
    watchDeals(
      companyId: companyId,
      role: role,
      currentUserId: currentUserId,
      teamId: teamId,
      archiveFilter: archiveFilter,
    );
  }

  void setSearchQuery(String query) {
    emit(
      state.copyWith(
        searchQuery: query,
        pageLimit: _defaultPageLimit,
        filteredDeals: _applyFilters(state.deals, searchQuery: query),
      ),
    );
    _reloadCurrentDealScopeAfterFilterChange();
  }

  void setStageFilter(DealStage? stage) {
    emit(
      state.copyWith(
        stageFilter: stage,
        pageLimit: _defaultPageLimit,
        clearStageFilter: stage == null,
        filteredDeals: _applyFilters(
          state.deals,
          stageFilter: stage,
          overrideStageFilter: true,
        ),
      ),
    );
    _reloadCurrentDealScopeAfterFilterChange();
  }

  void setAssignedToFilter(String assignedTo) {
    emit(
      state.copyWith(
        assignedToFilter: assignedTo,
        pageLimit: _defaultPageLimit,
        filteredDeals: _applyFilters(state.deals, assignedToFilter: assignedTo),
      ),
    );
    _reloadCurrentDealScopeAfterFilterChange();
  }

  void setClosingDateFilter(DealClosingDateFilter? filter) {
    emit(
      state.copyWith(
        closingDateFilter: filter,
        pageLimit: _defaultPageLimit,
        clearClosingDateFilter: filter == null,
        filteredDeals: _applyFilters(
          state.deals,
          closingDateFilter: filter,
          overrideClosingDateFilter: true,
        ),
      ),
    );
    _reloadCurrentDealScopeAfterFilterChange();
  }

  void setWorkQueueFilter(DealWorkQueueFilter? filter) {
    emit(
      state.copyWith(
        workQueueFilter: filter,
        pageLimit: _defaultPageLimit,
        clearWorkQueueFilter: filter == null,
        filteredDeals: _applyFilters(
          state.deals,
          workQueueFilter: filter,
          overrideWorkQueueFilter: true,
        ),
      ),
    );
    _reloadCurrentDealScopeAfterFilterChange();
  }

  void clearFilters() {
    emit(
      state.copyWith(
        searchQuery: '',
        assignedToFilter: '',
        pageLimit: _defaultPageLimit,
        clearStageFilter: true,
        clearClosingDateFilter: true,
        clearWorkQueueFilter: true,
        filteredDeals: _applyFilters(
          state.deals,
          searchQuery: '',
          stageFilter: null,
          assignedToFilter: '',
          closingDateFilter: null,
          workQueueFilter: null,
          overrideStageFilter: true,
          overrideClosingDateFilter: true,
          overrideWorkQueueFilter: true,
        ),
      ),
    );
    _reloadCurrentDealScopeAfterFilterChange();
  }

  Future<bool> createDeal({
    required String companyId,
    required Deal deal,
  }) {
    return _save(
      action: DealsAction.createDeal,
      operation: () => _createDealUseCase(companyId: companyId, deal: deal),
      afterSuccess: (result) {
        final createdDeal = result as Deal;
        unawaited(
          _writeAuditLog(
            companyId: companyId,
            actorId: createdDeal.createdBy,
            action: AuditLogAction.create,
            recordId: createdDeal.id,
            recordTitle: _dealTitle(createdDeal),
            recordSubtitle: _dealSubtitle(createdDeal),
            metadata: {
              'newStage': dealStageToValue(createdDeal.stage),
              'assignedTo': createdDeal.assignedTo,
              'assignedToName': createdDeal.assignedToName,
              'teamId': createdDeal.teamId,
              'teamName': createdDeal.teamName,
              'managerId': createdDeal.managerId,
              'managerName': createdDeal.managerName,
            },
          ),
        );
      },
    );
  }

  Future<bool> updateDeal({
    required String companyId,
    required Deal deal,
  }) {
    final previousDeal = dealById(deal.id);
    return _save(
      action: DealsAction.updateDeal,
      operation: () => _updateDealUseCase(companyId: companyId, deal: deal),
      afterSuccess: (result) {
        final updatedDeal = result as Deal;
        final stageChanged =
            previousDeal != null && previousDeal.stage != updatedDeal.stage;
        unawaited(
          _writeAuditLog(
            companyId: companyId,
            actorId: updatedDeal.updatedBy,
            action: stageChanged
                ? AuditLogAction.stageChange
                : AuditLogAction.update,
            recordId: updatedDeal.id,
            recordTitle: _dealTitle(updatedDeal),
            recordSubtitle: _dealSubtitle(updatedDeal),
            metadata: {
              if (previousDeal != null) ...{
                'previousStage': dealStageToValue(previousDeal.stage),
                'newStage': dealStageToValue(updatedDeal.stage),
              },
              'assignedTo': updatedDeal.assignedTo,
              'assignedToName': updatedDeal.assignedToName,
              'teamId': updatedDeal.teamId,
              'teamName': updatedDeal.teamName,
              'managerId': updatedDeal.managerId,
              'managerName': updatedDeal.managerName,
            },
          ),
        );
      },
    );
  }

  Future<bool> updateDealStage({
    required String companyId,
    required String dealId,
    required DealStage stage,
    required String lostReason,
    required String updatedBy,
  }) {
    final previousDeal = dealById(dealId);
    return _save(
      action: DealsAction.updateStage,
      operation: () => _updateDealStageUseCase(
        companyId: companyId,
        dealId: dealId,
        stage: stage,
        lostReason: lostReason,
        updatedBy: updatedBy,
      ),
      afterSuccess: (_) {
        unawaited(
          _writeAuditLog(
            companyId: companyId,
            actorId: updatedBy,
            action: AuditLogAction.stageChange,
            recordId: dealId,
            recordTitle: previousDeal == null ? 'Deal' : _dealTitle(previousDeal),
            recordSubtitle: previousDeal == null
                ? ''
                : _dealSubtitle(previousDeal),
            metadata: {
              if (previousDeal != null)
                'previousStage': dealStageToValue(previousDeal.stage),
              'newStage': dealStageToValue(stage),
              if (previousDeal != null) ...{
                'assignedTo': previousDeal.assignedTo,
                'assignedToName': previousDeal.assignedToName,
                'teamId': previousDeal.teamId,
                'teamName': previousDeal.teamName,
                'managerId': previousDeal.managerId,
                'managerName': previousDeal.managerName,
              },
            },
          ),
        );
      },
    );
  }

  Future<bool> archiveDeal({
    required String companyId,
    required String dealId,
    required String updatedBy,
    String reason = '',
  }) {
    final deal = dealById(dealId);
    return _save(
      action: DealsAction.archiveDeal,
      operation: () => _archiveDealUseCase(
        companyId: companyId,
        dealId: dealId,
        updatedBy: updatedBy,
        reason: reason,
      ),
      afterSuccess: (_) {
        unawaited(
          _writeAuditLog(
            companyId: companyId,
            actorId: updatedBy,
            action: AuditLogAction.archive,
            recordId: dealId,
            recordTitle: deal == null ? 'Deal' : _dealTitle(deal),
            recordSubtitle: deal == null ? '' : _dealSubtitle(deal),
            metadata: {
              if (deal != null) ...{
                'assignedTo': deal.assignedTo,
                'assignedToName': deal.assignedToName,
                'teamId': deal.teamId,
                'teamName': deal.teamName,
                'managerId': deal.managerId,
                'managerName': deal.managerName,
              },
            },
          ),
        );
      },
    );
  }

  Future<bool> restoreDeal({
    required String companyId,
    required String dealId,
    required String updatedBy,
  }) {
    final deal = dealById(dealId);
    return _save(
      action: DealsAction.restoreDeal,
      operation: () => _restoreDealUseCase(
        companyId: companyId,
        dealId: dealId,
        updatedBy: updatedBy,
      ),
      afterSuccess: (_) {
        unawaited(
          _writeAuditLog(
            companyId: companyId,
            actorId: updatedBy,
            action: AuditLogAction.restore,
            recordId: dealId,
            recordTitle: deal == null ? 'Deal' : _dealTitle(deal),
            recordSubtitle: deal == null ? '' : _dealSubtitle(deal),
            metadata: {
              if (deal != null) ...{
                'assignedTo': deal.assignedTo,
                'assignedToName': deal.assignedToName,
                'teamId': deal.teamId,
                'teamName': deal.teamName,
                'managerId': deal.managerId,
                'managerName': deal.managerName,
              },
            },
          ),
        );
      },
    );
  }

  Future<bool> _save({
    required DealsAction action,
    required Future<dynamic> Function() operation,
    void Function(dynamic result)? afterSuccess,
  }) async {
    emit(
      state.copyWith(
        status: DealsStatus.saving,
        clearMessage: true,
        clearLastAction: true,
      ),
    );
    try {
      final result = await operation();
      afterSuccess?.call(result);
      if (isClosed) {
        return false;
      }
      unawaited(_refreshKpiCounts(reason: 'mutation', force: true));
      final updatedDeals = result is Deal
          ? _upsertDealInCurrentList(result)
          : state.deals;
      emit(
        state.copyWith(
          status: DealsStatus.saved,
          deals: updatedDeals,
          filteredDeals: result is Deal
              ? _applyFilters(
                  updatedDeals,
                  searchQuery: state.searchQuery,
                  stageFilter: state.stageFilter,
                  assignedToFilter: state.assignedToFilter,
                  closingDateFilter: state.closingDateFilter,
                  workQueueFilter: state.workQueueFilter,
                )
              : state.filteredDeals,
          clearMessage: true,
          lastAction: action,
        ),
      );
      return true;
    } on DealException catch (error) {
      if (!isClosed) {
        emit(
          state.copyWith(
            status: DealsStatus.failure,
            message: error.message,
            lastAction: action,
          ),
        );
      }
      return false;
    } catch (_) {
      if (!isClosed) {
        emit(
          state.copyWith(
            status: DealsStatus.failure,
            message: AppErrorMessages.unknown,
            lastAction: action,
          ),
        );
      }
      return false;
    }
  }

  void clearAction() {
    emit(state.copyWith(clearLastAction: true));
  }

  Deal? dealById(String dealId) {
    for (final deal in state.deals) {
      if (deal.id == dealId) {
        return deal;
      }
    }
    return null;
  }


  List<Deal> _upsertDealInCurrentList(Deal updated) {
    final next = List<Deal>.of(state.deals);
    final index = next.indexWhere((deal) => deal.id == updated.id);
    if (index < 0) {
      next.insert(0, updated);
    } else {
      next[index] = updated;
    }
    return next;
  }

  List<Deal> _applyFilters(
    List<Deal> deals, {
    String? searchQuery,
    DealStage? stageFilter,
    String? assignedToFilter,
    DealClosingDateFilter? closingDateFilter,
    DealWorkQueueFilter? workQueueFilter,
    bool overrideStageFilter = false,
    bool overrideClosingDateFilter = false,
    bool overrideWorkQueueFilter = false,
  }) {
    final query = (searchQuery ?? state.searchQuery).trim().toLowerCase();
    final selectedStage = overrideStageFilter
        ? stageFilter
        : stageFilter ?? state.stageFilter;
    final selectedAssignedTo = (assignedToFilter ?? state.assignedToFilter).trim();
    final selectedClosingFilter = overrideClosingDateFilter
        ? closingDateFilter
        : closingDateFilter ?? state.closingDateFilter;
    final selectedWorkQueueFilter = overrideWorkQueueFilter
        ? workQueueFilter
        : workQueueFilter ?? state.workQueueFilter;
    final now = DateTime.now();

    return deals.where((deal) {
      final searchText = [
        deal.clientName,
        deal.clientEmail,
        deal.clientPhone,
        deal.leadName,
        deal.leadPhone,
        deal.propertyTitle,
        deal.propertyLocation,
        deal.assignedToName,
        deal.assignedToEmail,
        deal.notes,
        deal.stage.name,
      ].join(' ').toLowerCase();
      final matchesSearch = query.isEmpty || searchText.contains(query);
      final matchesStage = selectedStage == null || deal.stage == selectedStage;
      final matchesAssignee =
          selectedAssignedTo.isEmpty || deal.assignedTo == selectedAssignedTo;
      final matchesClosingDate = selectedClosingFilter == null ||
          _matchesClosingDate(deal, selectedClosingFilter, now);
      final matchesWorkQueue = selectedWorkQueueFilter == null ||
          _matchesWorkQueue(deal, selectedWorkQueueFilter, now);
      return matchesSearch &&
          matchesStage &&
          matchesAssignee &&
          matchesClosingDate &&
          matchesWorkQueue;
    }).toList();
  }

  bool _matchesWorkQueue(
    Deal deal,
    DealWorkQueueFilter filter,
    DateTime now,
  ) {
    final open = DashboardTruthRules.isOpenDeal(deal);
    switch (filter) {
      case DealWorkQueueFilter.open:
        return open;
      case DealWorkQueueFilter.atRisk:
        if (!open) {
          return false;
        }
        return DashboardTruthRules.isDealAtRisk(deal, now);
      case DealWorkQueueFilter.wonThisMonth:
        return DashboardTruthRules.isDealWonThisMonth(deal, now);
    }
  }

  bool _matchesClosingDate(
    Deal deal,
    DealClosingDateFilter filter,
    DateTime now,
  ) {
    final closingDate = deal.closingDate;
    if (closingDate == null) {
      return false;
    }
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(closingDate.year, closingDate.month, closingDate.day);
    switch (filter) {
      case DealClosingDateFilter.past:
        return day.isBefore(today);
      case DealClosingDateFilter.thisWeek:
        final weekEnd = today.add(Duration(days: 7 - today.weekday));
        return !day.isBefore(today) && !day.isAfter(weekEnd);
      case DealClosingDateFilter.thisMonth:
        return day.year == today.year && day.month == today.month;
    }
  }

  DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  String _dealErrorMessage(Object error) {
    if (error is DealException) {
      return error.message;
    }
    return AppErrorMessages.unknown;
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
          module: AuditLogModule.deals,
          recordId: recordId,
          recordTitle: recordTitle,
          recordSubtitle: recordSubtitle,
          createdAt: DateTime.now(),
          metadata: metadata,
        ),
      );
    } catch (_) {
      // Audit logging is best-effort and must not block deal workflows.
    }
  }

  @override
  Future<void> close() {
    _isClosing = true;
    _dealsInitialLoadTimeout.cancel();
    _dealsSubscription?.cancel();
    return super.close();
  }
}

String _dealTitle(Deal deal) {
  final clientName = deal.clientName.trim();
  final propertyTitle = deal.propertyTitle.trim();
  if (clientName.isNotEmpty && propertyTitle.isNotEmpty) {
    return '$clientName - $propertyTitle';
  }
  if (clientName.isNotEmpty) {
    return clientName;
  }
  if (propertyTitle.isNotEmpty) {
    return propertyTitle;
  }
  return 'Deal';
}

String _dealSubtitle(Deal deal) {
  final location = deal.propertyLocation.trim();
  if (location.isNotEmpty) {
    return location;
  }
  return dealStageToValue(deal.stage);
}
