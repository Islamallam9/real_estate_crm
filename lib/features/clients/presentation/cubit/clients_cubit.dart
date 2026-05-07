import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/error_mapper.dart';
import '../../domain/entities/client.dart';
import '../../domain/errors/client_exception.dart';
import '../../domain/usecases/archive_client_usecase.dart';
import '../../domain/usecases/create_client_usecase.dart';
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
    required ArchiveClientUseCase archiveClientUseCase,
  }) : _watchClientsUseCase = watchClientsUseCase,
       _watchClientUseCase = watchClientUseCase,
       _createClientUseCase = createClientUseCase,
       _updateClientUseCase = updateClientUseCase,
       _archiveClientUseCase = archiveClientUseCase,
      super(const ClientsState.initial());

  final WatchClientsUseCase _watchClientsUseCase;
  final WatchClientUseCase _watchClientUseCase;
  final CreateClientUseCase _createClientUseCase;
  final UpdateClientUseCase _updateClientUseCase;
  final ArchiveClientUseCase _archiveClientUseCase;

  StreamSubscription<List<Client>>? _clientsSubscription;
  StreamSubscription<Client?>? _clientSubscription;

  void watchClients({required String companyId, String? assignedTo}) {
    emit(
      state.copyWith(
        status: ClientsStatus.loading,
        clearMessage: true,
        clearLastAction: true,
      ),
    );
    _clientsSubscription?.cancel();
    _clientsSubscription = _watchClientsUseCase(
      companyId: companyId,
      assignedTo: assignedTo,
    ).listen(
      (clients) {
        if (isClosed) {
          return;
        }
        emit(
          state.copyWith(
            status: clients.isEmpty ? ClientsStatus.empty : ClientsStatus.loaded,
            clients: clients,
            filteredClients: _applyFilters(
              clients,
              searchQuery: state.searchQuery,
            ),
            clearMessage: true,
          ),
        );
      },
      onError: (error) {
        if (isClosed) {
          return;
        }
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
    _clientSubscription = _watchClientUseCase(
      companyId: companyId,
      clientId: clientId,
    ).listen(
      (client) {
        if (isClosed) {
          return;
        }
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
      await _createClientUseCase(companyId: companyId, client: client);
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
      await _updateClientUseCase(companyId: companyId, client: client);
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

  Future<void> archiveClient({
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
      await _archiveClientUseCase(
        companyId: companyId,
        clientId: clientId,
        updatedBy: updatedBy,
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

  void clearAction() {
    emit(state.copyWith(clearLastAction: true));
  }

  String _clientErrorMessage(Object error, String fallback) {
    if (error is ClientException) {
      return error.message;
    }

    return fallback;
  }

  List<Client> _applyFilters(
    List<Client> clients, {
    String? searchQuery,
  }) {
    final query = (searchQuery ?? '').trim().toLowerCase();
    final filtered = clients.where((client) {
      return query.isEmpty ||
          client.fullName.toLowerCase().contains(query) ||
          client.phone.toLowerCase().contains(query) ||
          client.email.toLowerCase().contains(query) ||
          client.preferredLocation.toLowerCase().contains(query) ||
          client.preferredPropertyType.toLowerCase().contains(query);
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
    _clientsSubscription?.cancel();
    _clientSubscription?.cancel();
    return super.close();
  }
}
