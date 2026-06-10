import 'package:equatable/equatable.dart';

import '../../../../core/stats/module_kpi_counts_data_source.dart';

import '../../../../core/archive/archive_filter.dart';
import '../../domain/entities/deal.dart';

enum DealsStatus { initial, loading, loadingMore, loaded, saving, saved, empty, failure }

enum DealsAction { none, createDeal, updateDeal, updateStage, archiveDeal, restoreDeal }

enum DealClosingDateFilter { past, thisWeek, thisMonth }

enum DealWorkQueueFilter { open, atRisk, wonThisMonth }

class DealsState extends Equatable {
  const DealsState({
    required this.status,
    this.deals = const [],
    this.filteredDeals = const [],
    this.searchQuery = '',
    this.stageFilter,
    this.assignedToFilter = '',
    this.closingDateFilter,
    this.workQueueFilter,
    this.archiveFilter = ArchiveFilter.active,
    this.pageLimit = 15,
    this.kpiCounts = const ModuleKpiCounts.empty(),
    this.message,
    this.lastAction = DealsAction.none,
  });

  const DealsState.initial()
    : status = DealsStatus.initial,
      deals = const [],
      filteredDeals = const [],
      searchQuery = '',
      stageFilter = null,
      assignedToFilter = '',
      closingDateFilter = null,
      workQueueFilter = null,
      archiveFilter = ArchiveFilter.active,
      pageLimit = 15,
      kpiCounts = const ModuleKpiCounts.empty(),
      message = null,
      lastAction = DealsAction.none;

  final DealsStatus status;
  final List<Deal> deals;
  final List<Deal> filteredDeals;
  final String searchQuery;
  final DealStage? stageFilter;
  final String assignedToFilter;
  final DealClosingDateFilter? closingDateFilter;
  final DealWorkQueueFilter? workQueueFilter;
  final ArchiveFilter archiveFilter;
  final int pageLimit;
  final ModuleKpiCounts kpiCounts;
  bool get hasLocalFilters {
    return searchQuery.trim().isNotEmpty ||
        stageFilter != null ||
        assignedToFilter.trim().isNotEmpty ||
        closingDateFilter != null ||
        workQueueFilter != null;
  }

  int? get filteredTotalCount {
    if (searchQuery.trim().isNotEmpty ||
        assignedToFilter.trim().isNotEmpty ||
        closingDateFilter != null) {
      return null;
    }
    if (stageFilter == null && workQueueFilter == null) {
      return kpiCounts.valueOrNull('total');
    }
    if (stageFilter == DealStage.lost && workQueueFilter == null) {
      return kpiCounts.valueOrNull('lost');
    }
    if (stageFilter == null) {
      return switch (workQueueFilter) {
        DealWorkQueueFilter.open => kpiCounts.valueOrNull('open'),
        DealWorkQueueFilter.atRisk => kpiCounts.valueOrNull('atRisk'),
        DealWorkQueueFilter.wonThisMonth => kpiCounts.valueOrNull('wonThisMonth'),
        _ => null,
      };
    }
    return null;
  }

  bool get canLoadMore {
    if (filteredDeals.length > pageLimit) {
      return true;
    }
    if (hasLocalFilters) {
      return false;
    }
    final total = filteredTotalCount;
    if (total != null) {
      return filteredDeals.length < total;
    }
    return false;
  }
  final String? message;
  final DealsAction lastAction;

  DealsState copyWith({
    DealsStatus? status,
    List<Deal>? deals,
    List<Deal>? filteredDeals,
    String? searchQuery,
    DealStage? stageFilter,
    String? assignedToFilter,
    DealClosingDateFilter? closingDateFilter,
    DealWorkQueueFilter? workQueueFilter,
    ArchiveFilter? archiveFilter,
    int? pageLimit,
    ModuleKpiCounts? kpiCounts,
    String? message,
    DealsAction? lastAction,
    bool clearStageFilter = false,
    bool clearClosingDateFilter = false,
    bool clearWorkQueueFilter = false,
    bool clearMessage = false,
    bool clearLastAction = false,
  }) {
    return DealsState(
      status: status ?? this.status,
      deals: deals ?? this.deals,
      filteredDeals: filteredDeals ?? this.filteredDeals,
      searchQuery: searchQuery ?? this.searchQuery,
      stageFilter: clearStageFilter ? null : stageFilter ?? this.stageFilter,
      assignedToFilter: assignedToFilter ?? this.assignedToFilter,
      closingDateFilter: clearClosingDateFilter
          ? null
          : closingDateFilter ?? this.closingDateFilter,
      workQueueFilter: clearWorkQueueFilter
          ? null
          : workQueueFilter ?? this.workQueueFilter,
      archiveFilter: archiveFilter ?? this.archiveFilter,
      pageLimit: pageLimit ?? this.pageLimit,
      kpiCounts: kpiCounts ?? this.kpiCounts,
      message: clearMessage ? null : message ?? this.message,
      lastAction: clearLastAction ? DealsAction.none : lastAction ?? this.lastAction,
    );
  }

  @override
  List<Object?> get props => [
    status,
    deals,
    filteredDeals,
    searchQuery,
    stageFilter,
    assignedToFilter,
    closingDateFilter,
    workQueueFilter,
    archiveFilter,
    pageLimit,
    kpiCounts,
    message,
    lastAction,
  ];
}
