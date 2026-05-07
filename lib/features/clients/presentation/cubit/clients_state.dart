import 'package:equatable/equatable.dart';

import '../../domain/entities/client.dart';

enum ClientsStatus { initial, loading, loaded, saving, saved, empty, failure }

enum ClientsAction { none, createClient, updateClient, archiveClient }

class ClientsState extends Equatable {
  const ClientsState({
    required this.status,
    this.clients = const [],
    this.filteredClients = const [],
    this.selectedClient,
    this.searchQuery = '',
    this.message,
    this.lastAction = ClientsAction.none,
  });

  const ClientsState.initial()
    : status = ClientsStatus.initial,
      clients = const [],
      filteredClients = const [],
      selectedClient = null,
      searchQuery = '',
      message = null,
      lastAction = ClientsAction.none;

  final ClientsStatus status;
  final List<Client> clients;
  final List<Client> filteredClients;
  final Client? selectedClient;
  final String searchQuery;
  final String? message;
  final ClientsAction lastAction;

  ClientsState copyWith({
    ClientsStatus? status,
    List<Client>? clients,
    List<Client>? filteredClients,
    Client? selectedClient,
    String? searchQuery,
    String? message,
    ClientsAction? lastAction,
    bool clearMessage = false,
    bool clearLastAction = false,
    bool clearSelectedClient = false,
  }) {
    return ClientsState(
      status: status ?? this.status,
      clients: clients ?? this.clients,
      filteredClients: filteredClients ?? this.filteredClients,
      selectedClient: clearSelectedClient
          ? null
          : selectedClient ?? this.selectedClient,
      searchQuery: searchQuery ?? this.searchQuery,
      message: clearMessage ? null : message ?? this.message,
      lastAction: clearLastAction
          ? ClientsAction.none
          : lastAction ?? this.lastAction,
    );
  }

  @override
  List<Object?> get props => [
    status,
    clients,
    filteredClients,
    selectedClient,
    searchQuery,
    message,
    lastAction,
  ];
}
