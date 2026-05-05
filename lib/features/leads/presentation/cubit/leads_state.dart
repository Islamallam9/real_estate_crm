import 'package:equatable/equatable.dart';

import '../../domain/entities/lead.dart';
import '../../domain/entities/lead_note.dart';
import '../../domain/entities/lead_timeline_event.dart';

enum LeadsStatus { initial, loading, loaded, saving, saved, empty, failure }

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
    this.message,
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
      message = null;

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
  final String? message;

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
    String? message,
    bool clearSelectedLead = false,
    bool clearMessage = false,
    bool clearStatusFilter = false,
    bool clearSourceFilter = false,
    bool clearPriorityFilter = false,
    bool clearAssignedToFilter = false,
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
      message: clearMessage ? null : message ?? this.message,
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
    message,
  ];
}
