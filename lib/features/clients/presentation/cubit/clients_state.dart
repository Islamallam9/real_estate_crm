import 'package:equatable/equatable.dart';

import '../../../../core/stats/module_kpi_counts_data_source.dart';

import '../../../../core/archive/archive_filter.dart';
import '../../domain/entities/client.dart';

enum ClientsStatus { initial, loading, loadingMore, loaded, saving, saved, empty, failure }

enum ClientsAction {
  none,
  createClient,
  updateClient,
  assignClient,
  archiveClient,
  restoreClient,
}

class ClientsState extends Equatable {
  const ClientsState({
    required this.status,
    this.clients = const [],
    this.filteredClients = const [],
    this.selectedClient,
    this.searchQuery = '',
    this.assignedToFilter,
    this.archiveFilter = ArchiveFilter.active,
    this.pageLimit = 15,
    this.kpiCounts = const ModuleKpiCounts.empty(),
    this.message,
    this.lastAction = ClientsAction.none,
  });

  const ClientsState.initial()
    : status = ClientsStatus.initial,
      clients = const [],
      filteredClients = const [],
      selectedClient = null,
      searchQuery = '',
      assignedToFilter = null,
      archiveFilter = ArchiveFilter.active,
      pageLimit = 15,
      kpiCounts = const ModuleKpiCounts.empty(),
      message = null,
      lastAction = ClientsAction.none;

  final ClientsStatus status;
  final List<Client> clients;
  final List<Client> filteredClients;
  final Client? selectedClient;
  final String searchQuery;
  final String? assignedToFilter;
  final ArchiveFilter archiveFilter;
  final int pageLimit;
  final ModuleKpiCounts kpiCounts;
  bool get hasLocalTableFilters {
    return searchQuery.trim().isNotEmpty ||
        (assignedToFilter ?? '').trim().isNotEmpty;
  }

  int? get filteredTotalCount {
    if (hasLocalTableFilters) {
      return null;
    }
    return kpiCounts.valueOrNull('total');
  }

  bool get canLoadMore {
    if (filteredClients.length > pageLimit) {
      return true;
    }
    if (hasLocalTableFilters) {
      return false;
    }
    final total = filteredTotalCount;
    if (total != null) {
      return filteredClients.length < total;
    }
    return false;
  }
  final String? message;
  final ClientsAction lastAction;

  ClientsState copyWith({
    ClientsStatus? status,
    List<Client>? clients,
    List<Client>? filteredClients,
    Client? selectedClient,
    String? searchQuery,
    String? assignedToFilter,
    ArchiveFilter? archiveFilter,
    int? pageLimit,
    ModuleKpiCounts? kpiCounts,
    String? message,
    ClientsAction? lastAction,
    bool clearMessage = false,
    bool clearLastAction = false,
    bool clearSelectedClient = false,
    bool clearAssignedToFilter = false,
  }) {
    return ClientsState(
      status: status ?? this.status,
      clients: clients ?? this.clients,
      filteredClients: filteredClients ?? this.filteredClients,
      selectedClient: clearSelectedClient
          ? null
          : selectedClient ?? this.selectedClient,
      searchQuery: searchQuery ?? this.searchQuery,
      assignedToFilter: clearAssignedToFilter
          ? null
          : assignedToFilter ?? this.assignedToFilter,
      archiveFilter: archiveFilter ?? this.archiveFilter,
      pageLimit: pageLimit ?? this.pageLimit,
      kpiCounts: kpiCounts ?? this.kpiCounts,
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
    assignedToFilter,
    archiveFilter,
    pageLimit,
    kpiCounts,
    message,
    lastAction,
  ];
}
