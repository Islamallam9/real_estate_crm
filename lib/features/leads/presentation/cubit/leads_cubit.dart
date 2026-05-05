import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/lead.dart';
import '../../domain/entities/lead_note.dart';
import '../../domain/entities/lead_timeline_event.dart';
import '../../domain/errors/lead_exception.dart';
import '../../domain/usecases/add_lead_note_usecase.dart';
import '../../domain/usecases/add_lead_timeline_event_usecase.dart';
import '../../domain/usecases/archive_lead_usecase.dart';
import '../../domain/usecases/create_lead_usecase.dart';
import '../../domain/usecases/get_lead_by_id_usecase.dart';
import '../../domain/usecases/update_lead_usecase.dart';
import '../../domain/usecases/watch_lead_notes_usecase.dart';
import '../../domain/usecases/watch_lead_timeline_usecase.dart';
import '../../domain/usecases/watch_leads_usecase.dart';
import 'leads_state.dart';

class LeadsCubit extends Cubit<LeadsState> {
  LeadsCubit({
    required CreateLeadUseCase createLeadUseCase,
    required ArchiveLeadUseCase archiveLeadUseCase,
    required UpdateLeadUseCase updateLeadUseCase,
    required GetLeadByIdUseCase getLeadByIdUseCase,
    required WatchLeadsUseCase watchLeadsUseCase,
    required AddLeadNoteUseCase addLeadNoteUseCase,
    required WatchLeadNotesUseCase watchLeadNotesUseCase,
    required AddLeadTimelineEventUseCase addLeadTimelineEventUseCase,
    required WatchLeadTimelineUseCase watchLeadTimelineUseCase,
  }) : _createLeadUseCase = createLeadUseCase,
       _archiveLeadUseCase = archiveLeadUseCase,
       _updateLeadUseCase = updateLeadUseCase,
       _getLeadByIdUseCase = getLeadByIdUseCase,
       _watchLeadsUseCase = watchLeadsUseCase,
       _addLeadNoteUseCase = addLeadNoteUseCase,
       _watchLeadNotesUseCase = watchLeadNotesUseCase,
       _addLeadTimelineEventUseCase = addLeadTimelineEventUseCase,
       _watchLeadTimelineUseCase = watchLeadTimelineUseCase,
       super(const LeadsState.initial());

  final CreateLeadUseCase _createLeadUseCase;
  final ArchiveLeadUseCase _archiveLeadUseCase;
  final UpdateLeadUseCase _updateLeadUseCase;
  final GetLeadByIdUseCase _getLeadByIdUseCase;
  final WatchLeadsUseCase _watchLeadsUseCase;
  final AddLeadNoteUseCase _addLeadNoteUseCase;
  final WatchLeadNotesUseCase _watchLeadNotesUseCase;
  final AddLeadTimelineEventUseCase _addLeadTimelineEventUseCase;
  final WatchLeadTimelineUseCase _watchLeadTimelineUseCase;

  StreamSubscription<List<Lead>>? _leadsSubscription;
  StreamSubscription<List<LeadNote>>? _notesSubscription;
  StreamSubscription<List<LeadTimelineEvent>>? _timelineSubscription;

  void watchLeads({required String companyId, String? assignedTo}) {
    emit(state.copyWith(status: LeadsStatus.loading, clearMessage: true));
    _leadsSubscription?.cancel();
    _leadsSubscription =
        _watchLeadsUseCase(companyId: companyId, assignedTo: assignedTo).listen(
          (leads) {
            final filtered = _applyFilters(leads);
            emit(
              state.copyWith(
                status: filtered.isEmpty
                    ? LeadsStatus.empty
                    : LeadsStatus.loaded,
                leads: leads,
                filteredLeads: filtered,
                clearMessage: true,
              ),
            );
          },
          onError: (_) {
            emit(
              state.copyWith(
                status: LeadsStatus.failure,
                message: 'Unable to load leads. Please try again.',
              ),
            );
          },
        );
  }

  void setSearchQuery(String query) {
    emit(
      state.copyWith(
        searchQuery: query,
        filteredLeads: _applyFilters(state.leads, searchQuery: query),
      ),
    );
  }

  void setStatusFilter(LeadStatus? status) {
    emit(
      state.copyWith(
        statusFilter: status,
        clearStatusFilter: status == null,
        filteredLeads: _applyFilters(state.leads, statusFilter: status),
      ),
    );
  }

  void setSourceFilter(LeadSource? source) {
    emit(
      state.copyWith(
        sourceFilter: source,
        clearSourceFilter: source == null,
        filteredLeads: _applyFilters(state.leads, sourceFilter: source),
      ),
    );
  }

  void setPriorityFilter(LeadPriority? priority) {
    emit(
      state.copyWith(
        priorityFilter: priority,
        clearPriorityFilter: priority == null,
        filteredLeads: _applyFilters(state.leads, priorityFilter: priority),
      ),
    );
  }

  Future<void> createLead({
    required String companyId,
    required Lead lead,
    required String actorName,
  }) async {
    emit(state.copyWith(status: LeadsStatus.saving, clearMessage: true));
    try {
      final createdLead = await _createLeadUseCase(
        companyId: companyId,
        lead: lead,
      );
      await _addTimelineEvent(
        companyId: companyId,
        leadId: createdLead.id,
        type: 'created',
        title: 'lead_created',
        description: '',
        oldValue: '',
        newValue: '',
        createdBy: lead.createdBy,
        createdByName: actorName,
      );
      if (createdLead.assignedTo.isNotEmpty) {
        await _addTimelineEvent(
          companyId: companyId,
          leadId: createdLead.id,
          type: 'assigned',
          title: 'lead_assigned',
          description: 'assignedTo',
          oldValue: '',
          newValue: createdLead.assignedToName.isNotEmpty
              ? createdLead.assignedToName
              : createdLead.assignedTo,
          createdBy: lead.createdBy,
          createdByName: actorName,
        );
      }
      emit(state.copyWith(status: LeadsStatus.saved, clearMessage: true));
    } on LeadException catch (error) {
      emit(state.copyWith(status: LeadsStatus.failure, message: error.message));
    } catch (_) {
      emit(
        state.copyWith(
          status: LeadsStatus.failure,
          message: 'Unable to create lead. Please try again.',
        ),
      );
    }
  }

  Future<void> updateLead({
    required String companyId,
    required Lead lead,
    required String actorName,
  }) async {
    emit(state.copyWith(status: LeadsStatus.saving, clearMessage: true));
    try {
      final current = await _getLeadByIdUseCase(
        companyId: companyId,
        leadId: lead.id,
      );
      final updated = await _updateLeadUseCase(
        companyId: companyId,
        lead: lead,
      );
      await _addLeadUpdateEvents(
        companyId: companyId,
        oldLead: current,
        newLead: updated,
        actorName: actorName,
      );
      emit(state.copyWith(status: LeadsStatus.saved, clearMessage: true));
    } on LeadException catch (error) {
      emit(state.copyWith(status: LeadsStatus.failure, message: error.message));
    } catch (_) {
      emit(
        state.copyWith(
          status: LeadsStatus.failure,
          message: 'Unable to update lead. Please try again.',
        ),
      );
    }
  }

  Future<void> updateStatus({
    required String companyId,
    required String updatedBy,
    required String actorName,
    required LeadStatus status,
  }) async {
    final lead = state.selectedLead;
    if (lead == null || lead.status == status) {
      return;
    }
    await updateLead(
      companyId: companyId,
      lead: lead.copyWith(
        status: status,
        updatedAt: DateTime.now(),
        updatedBy: updatedBy,
      ),
      actorName: actorName,
    );
    await loadLead(companyId: companyId, leadId: lead.id);
  }

  Future<void> archiveLead({
    required String companyId,
    required String leadId,
    required String archivedBy,
    required String actorName,
  }) async {
    emit(state.copyWith(status: LeadsStatus.saving, clearMessage: true));
    try {
      await _archiveLeadUseCase(
        companyId: companyId,
        leadId: leadId,
        archivedBy: archivedBy,
      );
      await _addTimelineEvent(
        companyId: companyId,
        leadId: leadId,
        type: 'archived',
        title: 'lead_archived',
        description: '',
        oldValue: '',
        newValue: '',
        createdBy: archivedBy,
        createdByName: actorName,
      );
      emit(state.copyWith(status: LeadsStatus.saved, clearMessage: true));
    } on LeadException catch (error) {
      emit(state.copyWith(status: LeadsStatus.failure, message: error.message));
    } catch (_) {
      emit(
        state.copyWith(
          status: LeadsStatus.failure,
          message: 'Unable to archive lead. Please try again.',
        ),
      );
    }
  }

  Future<void> loadLead({
    required String companyId,
    required String leadId,
  }) async {
    emit(state.copyWith(status: LeadsStatus.loading, clearMessage: true));
    try {
      final lead = await _getLeadByIdUseCase(
        companyId: companyId,
        leadId: leadId,
      );
      emit(
        state.copyWith(
          status: LeadsStatus.loaded,
          selectedLead: lead,
          clearMessage: true,
        ),
      );
    } on LeadException catch (error) {
      emit(state.copyWith(status: LeadsStatus.failure, message: error.message));
    } catch (_) {
      emit(
        state.copyWith(
          status: LeadsStatus.failure,
          message: 'Unable to load lead.',
        ),
      );
    }
  }

  void watchNotes({required String companyId, required String leadId}) {
    _notesSubscription?.cancel();
    _notesSubscription =
        _watchLeadNotesUseCase(companyId: companyId, leadId: leadId).listen(
          (notes) => emit(state.copyWith(notes: notes)),
          onError: (_) {
            emit(
              state.copyWith(
                status: LeadsStatus.failure,
                message: 'Unable to load notes. Please try again.',
              ),
            );
          },
        );
  }

  void watchTimeline({required String companyId, required String leadId}) {
    _timelineSubscription?.cancel();
    _timelineSubscription =
        _watchLeadTimelineUseCase(companyId: companyId, leadId: leadId).listen(
          (events) => emit(state.copyWith(timeline: events)),
          onError: (_) {
            emit(
              state.copyWith(
                status: LeadsStatus.failure,
                message: 'Unable to load lead timeline.',
              ),
            );
          },
        );
  }

  Future<void> addNote({
    required String companyId,
    required String leadId,
    required String text,
    required String createdBy,
    required String actorName,
  }) async {
    if (text.trim().isEmpty) {
      return;
    }
    try {
      await _addLeadNoteUseCase(
        companyId: companyId,
        leadId: leadId,
        note: LeadNote(
          id: '',
          leadId: leadId,
          companyId: companyId,
          text: text.trim(),
          createdAt: DateTime.now(),
          createdBy: createdBy,
        ),
      );
      await _addTimelineEvent(
        companyId: companyId,
        leadId: leadId,
        type: 'noteAdded',
        title: 'note_added',
        description: text.trim(),
        oldValue: '',
        newValue: '',
        createdBy: createdBy,
        createdByName: actorName,
      );
    } on LeadException catch (error) {
      emit(state.copyWith(status: LeadsStatus.failure, message: error.message));
    } catch (_) {
      emit(
        state.copyWith(
          status: LeadsStatus.failure,
          message: 'Unable to add note. Please try again.',
        ),
      );
    }
  }

  Future<void> _addLeadUpdateEvents({
    required String companyId,
    required Lead oldLead,
    required Lead newLead,
    required String actorName,
  }) async {
    Future<void> addFieldEvent({
      required String field,
      required String oldValue,
      required String newValue,
      String type = 'updated',
      String title = 'field_changed',
    }) async {
      if (oldValue == newValue) {
        return;
      }
      await _addTimelineEvent(
        companyId: companyId,
        leadId: newLead.id,
        type: type,
        title: title,
        description: field,
        oldValue: oldValue,
        newValue: newValue,
        createdBy: newLead.updatedBy,
        createdByName: actorName,
      );
    }

    await addFieldEvent(
      field: 'fullName',
      oldValue: oldLead.fullName,
      newValue: newLead.fullName,
    );
    await addFieldEvent(
      field: 'phone',
      oldValue: oldLead.phone,
      newValue: newLead.phone,
    );
    await addFieldEvent(
      field: 'email',
      oldValue: oldLead.email,
      newValue: newLead.email,
    );
    await addFieldEvent(
      field: 'source',
      oldValue: oldLead.source.name,
      newValue: newLead.source.name,
    );
    await addFieldEvent(
      field: 'status',
      oldValue: oldLead.status.name,
      newValue: newLead.status.name,
      type: 'statusChanged',
      title: 'status_changed',
    );
    await addFieldEvent(
      field: 'priority',
      oldValue: oldLead.priority.name,
      newValue: newLead.priority.name,
    );
    await addFieldEvent(
      field: 'budget',
      oldValue: '${oldLead.budgetMin}-${oldLead.budgetMax}',
      newValue: '${newLead.budgetMin}-${newLead.budgetMax}',
    );
    await addFieldEvent(
      field: 'preferredLocation',
      oldValue: oldLead.preferredLocation,
      newValue: newLead.preferredLocation,
    );
    await addFieldEvent(
      field: 'preferredPropertyType',
      oldValue: oldLead.preferredPropertyType,
      newValue: newLead.preferredPropertyType,
    );
    await addFieldEvent(
      field: 'notes',
      oldValue: oldLead.notes,
      newValue: newLead.notes,
    );
    await addFieldEvent(
      field: 'assignedTo',
      oldValue: oldLead.assignedToName.isNotEmpty
          ? oldLead.assignedToName
          : oldLead.assignedTo,
      newValue: newLead.assignedToName.isNotEmpty
          ? newLead.assignedToName
          : newLead.assignedTo,
      type: oldLead.assignedTo.isEmpty ? 'assigned' : 'reassigned',
      title: oldLead.assignedTo.isEmpty ? 'lead_assigned' : 'lead_reassigned',
    );
  }

  Future<void> _addTimelineEvent({
    required String companyId,
    required String leadId,
    required String type,
    required String title,
    required String description,
    required String oldValue,
    required String newValue,
    required String createdBy,
    required String createdByName,
  }) {
    return _addLeadTimelineEventUseCase(
      companyId: companyId,
      leadId: leadId,
      event: LeadTimelineEvent(
        id: '',
        leadId: leadId,
        companyId: companyId,
        type: type,
        title: title,
        description: description,
        oldValue: oldValue,
        newValue: newValue,
        createdAt: DateTime.now(),
        createdBy: createdBy,
        createdByName: createdByName,
        metadata: const {},
      ),
    );
  }

  List<Lead> _applyFilters(
    List<Lead> leads, {
    String? searchQuery,
    LeadStatus? statusFilter,
    LeadSource? sourceFilter,
    LeadPriority? priorityFilter,
  }) {
    final query = (searchQuery ?? state.searchQuery).trim().toLowerCase();
    final status = statusFilter ?? state.statusFilter;
    final source = sourceFilter ?? state.sourceFilter;
    final priority = priorityFilter ?? state.priorityFilter;

    return leads.where((lead) {
      final matchesQuery =
          query.isEmpty ||
          lead.fullName.toLowerCase().contains(query) ||
          lead.phone.toLowerCase().contains(query) ||
          lead.email.toLowerCase().contains(query);
      final matchesStatus = status == null || lead.status == status;
      final matchesSource = source == null || lead.source == source;
      final matchesPriority = priority == null || lead.priority == priority;
      return matchesQuery && matchesStatus && matchesSource && matchesPriority;
    }).toList();
  }

  @override
  Future<void> close() {
    _leadsSubscription?.cancel();
    _notesSubscription?.cancel();
    _timelineSubscription?.cancel();
    return super.close();
  }
}
