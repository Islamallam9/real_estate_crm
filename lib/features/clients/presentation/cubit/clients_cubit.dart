import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/archive/archive_filter.dart';
import '../../../../core/errors/error_mapper.dart';
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

  StreamSubscription<List<Client>>? _clientsSubscription;
  StreamSubscription<Client?>? _clientSubscription;
  final InitialLoadTimeout _clientsInitialLoadTimeout = InitialLoadTimeout();
  final InitialLoadTimeout _clientInitialLoadTimeout = InitialLoadTimeout();

  void watchClients({
    required String companyId,
    String? assignedTo,
    String? managerId,
    String? teamId,
    ArchiveFilter archiveFilter = ArchiveFilter.active,
  }) {
    emit(
      state.copyWith(
        status: ClientsStatus.loading,
        clearMessage: true,
        clearLastAction: true,
      ),
    );
    _clientsSubscription?.cancel();
    _clientsInitialLoadTimeout.start(() {
      if (isClosed ||
          state.status != ClientsStatus.loading ||
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
            clearMessage: true,
          ),
        );
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
        filteredClients: _applyFilters(state.clients, searchQuery: query),
      ),
    );
  }

  void setAssignedToFilter(String? assignedTo) {
    emit(
      state.copyWith(
        assignedToFilter: assignedTo,
        clearAssignedToFilter: assignedTo == null,
        filteredClients: _applyFilters(
          state.clients,
          assignedToFilter: assignedTo,
          overrideAssignedToFilter: true,
        ),
      ),
    );
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
          action: AuditLogAction.restore,
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
      emit(
        state.copyWith(
          status: ClientsStatus.saved,
          clearMessage: true,
          lastAction: ClientsAction.updateClient,
        ),
      );
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

  Future<void> assignClient({
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
        return;
      }
      emit(
        state.copyWith(
          status: ClientsStatus.saved,
          clearMessage: true,
          lastAction: ClientsAction.assignClient,
        ),
      );
    } on ClientException catch (error) {
      if (isClosed) {
        return;
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
        return;
      }
      emit(
        state.copyWith(
          status: ClientsStatus.failure,
          message: AppErrorMessages.unknown,
          lastAction: ClientsAction.assignClient,
        ),
      );
    }
  }

  Future<void> archiveClient({
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
        return;
      }
      emit(
        state.copyWith(
          status: ClientsStatus.saved,
          clearMessage: true,
          lastAction: ClientsAction.archiveClient,
        ),
      );
    } on ClientException catch (error) {
      if (isClosed) {
        return;
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
        return;
      }
      emit(
        state.copyWith(
          status: ClientsStatus.failure,
          message: AppErrorMessages.unknown,
          lastAction: ClientsAction.archiveClient,
        ),
      );
    }
  }

  Future<void> restoreClient({
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
        return;
      }
      emit(
        state.copyWith(
          status: ClientsStatus.saved,
          clearMessage: true,
          lastAction: ClientsAction.restoreClient,
        ),
      );
    } on ClientException catch (error) {
      if (isClosed) {
        return;
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
        return;
      }
      emit(
        state.copyWith(
          status: ClientsStatus.failure,
          message: AppErrorMessages.unknown,
          lastAction: ClientsAction.restoreClient,
        ),
      );
    }
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
      final matchesAssignee =
          selectedAssignedTo == null ||
          selectedAssignedTo.isEmpty ||
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
    _clientsInitialLoadTimeout.cancel();
    _clientInitialLoadTimeout.cancel();
    _clientsSubscription?.cancel();
    _clientSubscription?.cancel();
    return super.close();
  }
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
