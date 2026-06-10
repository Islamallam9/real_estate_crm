import 'package:equatable/equatable.dart';

import '../../../../core/stats/module_kpi_counts_data_source.dart';

import '../../../../core/archive/archive_filter.dart';
import '../../domain/entities/lead.dart';
import '../../domain/entities/lead_note.dart';
import '../../domain/entities/lead_timeline_event.dart';

enum LeadsStatus { initial, loading, loadingMore, loaded, saving, saved, empty, failure }

enum LeadFollowUpFilter { overdue, dueToday, upcoming, notScheduled }

enum LeadWorkQueueFilter {
  active,
  newToday,
  hot,
  stale,
  contactedTodayStillOverdue,
  unassigned,
}

enum LeadsAction {
  none,
  createLead,
  updateLead,
  archiveLead,
  restoreLead,
  updateStatus,
  assignLead,
  addNote,
  markContactedToday,
}

class LeadsState extends Equatable {
  const LeadsState({
    required this.status,
    this.leads = const [],
    this.filteredLeads = const [],
    this.notes = const [],
    this.timeline = const [],
    this.selectedLead,
    this.searchQuery = '',
    this.statusFilter,
    this.sourceFilter,
    this.priorityFilter,
    this.assignedToFilter,
    this.followUpFilter,
    this.workQueueFilter,
    this.archiveFilter = ArchiveFilter.active,
    this.pageLimit = 15,
    this.hasExactListScope = true,
    this.kpiCounts = const ModuleKpiCounts.empty(),
    this.message,
    this.lastAction = LeadsAction.none,
  });

  const LeadsState.initial()
    : status = LeadsStatus.initial,
      leads = const [],
      filteredLeads = const [],
      notes = const [],
      timeline = const [],
      selectedLead = null,
      searchQuery = '',
      statusFilter = null,
      sourceFilter = null,
      priorityFilter = null,
      assignedToFilter = null,
      followUpFilter = null,
      workQueueFilter = null,
      archiveFilter = ArchiveFilter.active,
      pageLimit = 15,
      hasExactListScope = true,
      kpiCounts = const ModuleKpiCounts.empty(),
      message = null,
      lastAction = LeadsAction.none;

  final LeadsStatus status;
  final List<Lead> leads;
  final List<Lead> filteredLeads;
  final List<LeadNote> notes;
  final List<LeadTimelineEvent> timeline;
  final Lead? selectedLead;
  final String searchQuery;
  final LeadStatus? statusFilter;
  final LeadSource? sourceFilter;
  final LeadPriority? priorityFilter;
  final String? assignedToFilter;
  final LeadFollowUpFilter? followUpFilter;
  final LeadWorkQueueFilter? workQueueFilter;
  final ArchiveFilter archiveFilter;
  final int pageLimit;
  final bool hasExactListScope;
  final ModuleKpiCounts kpiCounts;
  bool get hasLocalFilters {
    return searchQuery.trim().isNotEmpty ||
        statusFilter != null ||
        sourceFilter != null ||
        priorityFilter != null ||
        followUpFilter != null ||
        workQueueFilter != null;
  }

  int? get filteredTotalCount {
    if (hasLocalFilters || !hasExactListScope) {
      return null;
    }
    return kpiCounts.valueOrNull('total');
  }

  bool get canLoadMore {
    if (hasLocalFilters || !hasExactListScope) {
      return false;
    }
    final total = filteredTotalCount;
    if (total != null) {
      return filteredLeads.length < total;
    }
    return false;
  }
  final String? message;
  final LeadsAction lastAction;

  LeadsState copyWith({
    LeadsStatus? status,
    List<Lead>? leads,
    List<Lead>? filteredLeads,
    List<LeadNote>? notes,
    List<LeadTimelineEvent>? timeline,
    Lead? selectedLead,
    String? searchQuery,
    LeadStatus? statusFilter,
    LeadSource? sourceFilter,
    LeadPriority? priorityFilter,
    String? assignedToFilter,
    LeadFollowUpFilter? followUpFilter,
    LeadWorkQueueFilter? workQueueFilter,
    ArchiveFilter? archiveFilter,
    int? pageLimit,
    bool? hasExactListScope,
    ModuleKpiCounts? kpiCounts,
    String? message,
    LeadsAction? lastAction,
    bool clearSelectedLead = false,
    bool clearMessage = false,
    bool clearLastAction = false,
    bool clearStatusFilter = false,
    bool clearSourceFilter = false,
    bool clearPriorityFilter = false,
    bool clearAssignedToFilter = false,
    bool clearFollowUpFilter = false,
    bool clearWorkQueueFilter = false,
  }) {
    return LeadsState(
      status: status ?? this.status,
      leads: leads ?? this.leads,
      filteredLeads: filteredLeads ?? this.filteredLeads,
      notes: notes ?? this.notes,
      timeline: timeline ?? this.timeline,
      selectedLead: clearSelectedLead
          ? null
          : selectedLead ?? this.selectedLead,
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: clearStatusFilter
          ? null
          : statusFilter ?? this.statusFilter,
      sourceFilter: clearSourceFilter
          ? null
          : sourceFilter ?? this.sourceFilter,
      priorityFilter: clearPriorityFilter
          ? null
          : priorityFilter ?? this.priorityFilter,
      assignedToFilter: clearAssignedToFilter
          ? null
          : assignedToFilter ?? this.assignedToFilter,
      followUpFilter: clearFollowUpFilter
          ? null
          : followUpFilter ?? this.followUpFilter,
      workQueueFilter: clearWorkQueueFilter
          ? null
          : workQueueFilter ?? this.workQueueFilter,
      archiveFilter: archiveFilter ?? this.archiveFilter,
      pageLimit: pageLimit ?? this.pageLimit,
      hasExactListScope: hasExactListScope ?? this.hasExactListScope,
      kpiCounts: kpiCounts ?? this.kpiCounts,
      message: clearMessage ? null : message ?? this.message,
      lastAction: clearLastAction
          ? LeadsAction.none
          : lastAction ?? this.lastAction,
    );
  }

  @override
  List<Object?> get props => [
    status,
    leads,
    filteredLeads,
    notes,
    timeline,
    selectedLead,
    searchQuery,
    statusFilter,
    sourceFilter,
    priorityFilter,
    assignedToFilter,
    followUpFilter,
    workQueueFilter,
    archiveFilter,
    pageLimit,
    hasExactListScope,
    kpiCounts,
    message,
    lastAction,
  ];
}
