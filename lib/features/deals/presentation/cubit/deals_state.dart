import 'package:equatable/equatable.dart';

import '../../../../core/archive/archive_filter.dart';
import '../../domain/entities/deal.dart';

enum DealsStatus { initial, loading, loaded, saving, saved, empty, failure }

enum DealsAction { none, createDeal, updateDeal, updateStage, archiveDeal, restoreDeal }

enum DealClosingDateFilter { past, thisWeek, thisMonth }

class DealsState extends Equatable {
  const DealsState({
    required this.status,
    this.deals = const [],
    this.filteredDeals = const [],
    this.searchQuery = '',
    this.stageFilter,
    this.assignedToFilter = '',
    this.closingDateFilter,
    this.archiveFilter = ArchiveFilter.active,
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
      archiveFilter = ArchiveFilter.active,
      message = null,
      lastAction = DealsAction.none;

  final DealsStatus status;
  final List<Deal> deals;
  final List<Deal> filteredDeals;
  final String searchQuery;
  final DealStage? stageFilter;
  final String assignedToFilter;
  final DealClosingDateFilter? closingDateFilter;
  final ArchiveFilter archiveFilter;
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
    ArchiveFilter? archiveFilter,
    String? message,
    DealsAction? lastAction,
    bool clearStageFilter = false,
    bool clearClosingDateFilter = false,
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
      archiveFilter: archiveFilter ?? this.archiveFilter,
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
    archiveFilter,
    message,
    lastAction,
  ];
}
