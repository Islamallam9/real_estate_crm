import 'package:equatable/equatable.dart';

import '../../../../core/archive/archive_filter.dart';
import '../../domain/entities/lead.dart';
import '../../domain/entities/lead_note.dart';
import '../../domain/entities/lead_timeline_event.dart';

enum LeadsStatus { initial, loading, loaded, saving, saved, empty, failure }

enum LeadFollowUpFilter { overdue, dueToday, upcoming, notScheduled }

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
    this.archiveFilter = ArchiveFilter.active,
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
      archiveFilter = ArchiveFilter.active,
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
  final ArchiveFilter archiveFilter;
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
    ArchiveFilter? archiveFilter,
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
      archiveFilter: archiveFilter ?? this.archiveFilter,
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
    archiveFilter,
    message,
    lastAction,
  ];
}
