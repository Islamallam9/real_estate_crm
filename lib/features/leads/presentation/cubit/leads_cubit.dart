import 'dart:async';

import '../../../../core/errors/error_mapper.dart';
import '../../../../core/utils/initial_load_timeout.dart';
import '../../domain/errors/lead_exception.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../domain/entities/lead.dart';
import '../../domain/entities/lead_note.dart';
import '../../domain/entities/lead_timeline_event.dart';
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
  final InitialLoadTimeout _leadsInitialLoadTimeout = InitialLoadTimeout();
  static const Duration _firebaseTimeout = Duration(seconds: 10);

  Future<bool> _hasConnection() async {
    final results = await Connectivity().checkConnectivity();
    return results.any((result) => result != ConnectivityResult.none);
  }

  Future<T> _guardFirebaseAction<T>(Future<T> Function() action) async {
    final connected = await _hasConnection();

    if (!connected) {
      throw const LeadException(AppErrorMessages.unableToConnect);
    }

    return action().timeout(
      _firebaseTimeout,
      onTimeout: () {
        throw const LeadException(AppErrorMessages.unableToConnect);
      },
    );
  }

  String _leadErrorMessage(Object error, String fallback) {
    if (error is LeadException) {
      return error.message;
    }

    return fallback;
  }

  void watchLeads({required String companyId, String? assignedTo}) {
    emit(state.copyWith(status: LeadsStatus.loading, clearMessage: true));
    _leadsSubscription?.cancel();
    _leadsInitialLoadTimeout.start(() {
      if (isClosed || state.status != LeadsStatus.loading || state.leads.isNotEmpty) {
        return;
      }
      emit(
        state.copyWith(
          status: LeadsStatus.failure,
          message: AppErrorMessages.connectionTimeout,
        ),
      );
    });
    _leadsSubscription =
        _watchLeadsUseCase(companyId: companyId, assignedTo: assignedTo).listen(
          (leads) {
            if (isClosed) {
              return;
            }
            _leadsInitialLoadTimeout.complete();
            final filtered = _applyFilters(
              leads,
              searchQuery: state.searchQuery,
              statusFilter: state.statusFilter,
              sourceFilter: state.sourceFilter,
              priorityFilter: state.priorityFilter,
              assignedToFilter: state.assignedToFilter,
              followUpFilter: state.followUpFilter,
            );
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
            if (isClosed) {
              return;
            }
            _leadsInitialLoadTimeout.complete();
            emit(
              state.copyWith(
                status: LeadsStatus.failure,
                message: AppErrorMessages.connectionTimeout,
              ),
            );
          },
        );
  }

  void setSearchQuery(String query) {
    emit(
      state.copyWith(
        searchQuery: query,
        filteredLeads: _applyFilters(
          state.leads,
          searchQuery: query,
          statusFilter: state.statusFilter,
          sourceFilter: state.sourceFilter,
          priorityFilter: state.priorityFilter,
          assignedToFilter: state.assignedToFilter,
          followUpFilter: state.followUpFilter,
        ),
      ),
    );
  }

  void setStatusFilter(LeadStatus? status) {
    emit(
      state.copyWith(
        statusFilter: status,
        clearStatusFilter: status == null,
        filteredLeads: _applyFilters(
          state.leads,
          searchQuery: state.searchQuery,
          statusFilter: status,
          sourceFilter: state.sourceFilter,
          priorityFilter: state.priorityFilter,
          assignedToFilter: state.assignedToFilter,
          followUpFilter: state.followUpFilter,
        ),
      ),
    );
  }

  void setSourceFilter(LeadSource? source) {
    emit(
      state.copyWith(
        sourceFilter: source,
        clearSourceFilter: source == null,
        filteredLeads: _applyFilters(
          state.leads,
          searchQuery: state.searchQuery,
          statusFilter: state.statusFilter,
          sourceFilter: source,
          priorityFilter: state.priorityFilter,
          assignedToFilter: state.assignedToFilter,
          followUpFilter: state.followUpFilter,
        ),
      ),
    );
  }

  void setPriorityFilter(LeadPriority? priority) {
    emit(
      state.copyWith(
        priorityFilter: priority,
        clearPriorityFilter: priority == null,
        filteredLeads: _applyFilters(
          state.leads,
          searchQuery: state.searchQuery,
          statusFilter: state.statusFilter,
          sourceFilter: state.sourceFilter,
          priorityFilter: priority,
          assignedToFilter: state.assignedToFilter,
          followUpFilter: state.followUpFilter,
        ),
      ),
    );
  }

  void setAssignedToFilter(String? assignedTo) {
    emit(
      state.copyWith(
        assignedToFilter: assignedTo,
        clearAssignedToFilter: assignedTo == null,
        filteredLeads: _applyFilters(
          state.leads,
          searchQuery: state.searchQuery,
          statusFilter: state.statusFilter,
          sourceFilter: state.sourceFilter,
          priorityFilter: state.priorityFilter,
          assignedToFilter: assignedTo,
          followUpFilter: state.followUpFilter,
        ),
      ),
    );
  }

  void setFollowUpFilter(LeadFollowUpFilter? followUpFilter) {
    emit(
      state.copyWith(
        followUpFilter: followUpFilter,
        clearFollowUpFilter: followUpFilter == null,
        filteredLeads: _applyFilters(
          state.leads,
          searchQuery: state.searchQuery,
          statusFilter: state.statusFilter,
          sourceFilter: state.sourceFilter,
          priorityFilter: state.priorityFilter,
          assignedToFilter: state.assignedToFilter,
          followUpFilter: followUpFilter,
        ),
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
      final createdLead = await _guardFirebaseAction(
        () => _createLeadUseCase(companyId: companyId, lead: lead),
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
      if (isClosed) {
        return;
      }
      emit(
        state.copyWith(
          status: LeadsStatus.saved,
          clearMessage: true,
          lastAction: createdLead.assignedTo.isNotEmpty
              ? LeadsAction.assignLead
              : LeadsAction.createLead,
        ),
      );
    } on LeadException catch (error) {
      if (isClosed) {
        return;
      }
      emit(state.copyWith(status: LeadsStatus.failure, message: error.message));
    } catch (error) {
      if (isClosed) {
        return;
      }
      emit(
        state.copyWith(
          status: LeadsStatus.failure,
          message: _leadErrorMessage(
            error,
            'Unable to create lead. Please try again.',
          ),
          lastAction: LeadsAction.createLead,
        ),
      );
    }
  }

  Future<void> updateLead({
    required String companyId,
    required Lead lead,
    required String actorName,
    LeadsAction? successAction,
  }) async {
    emit(state.copyWith(status: LeadsStatus.saving, clearMessage: true));
    try {
      final current = await _guardFirebaseAction(
        () => _getLeadByIdUseCase(companyId: companyId, leadId: lead.id),
      );
      final updated = await _guardFirebaseAction(
        () => _updateLeadUseCase(
          companyId: companyId,
          lead: lead,
          currentLead: current,
        ),
      );
      await _addLeadUpdateEvents(
        companyId: companyId,
        oldLead: current,
        newLead: updated,
        actorName: actorName,
      );
      if (isClosed) {
        return;
      }
      emit(
        state.copyWith(
          status: LeadsStatus.saved,
          selectedLead: updated,
          clearMessage: true,
          lastAction:
              successAction ??
              (current.assignedTo != updated.assignedTo
                  ? LeadsAction.assignLead
                  : LeadsAction.updateLead),
        ),
      );
    } on LeadException catch (error) {
      if (isClosed) {
        return;
      }
      emit(state.copyWith(status: LeadsStatus.failure, message: error.message));
    } catch (error) {
      if (isClosed) {
        return;
      }
      emit(
        state.copyWith(
          status: LeadsStatus.failure,
          message: _leadErrorMessage(
            error,
            'Unable to update lead. Please try again.',
          ),
          lastAction: LeadsAction.updateLead,
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
      successAction: LeadsAction.updateStatus,
    );
  }

  Future<void> archiveLead({
    required String companyId,
    required String leadId,
    required String archivedBy,
    required String actorName,
  }) async {
    emit(state.copyWith(status: LeadsStatus.saving, clearMessage: true));
    try {
      await _guardFirebaseAction(
        () => _archiveLeadUseCase(
          companyId: companyId,
          leadId: leadId,
          archivedBy: archivedBy,
        ),
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
      if (isClosed) {
        return;
      }
      emit(
        state.copyWith(
          status: LeadsStatus.saved,
          clearMessage: true,
          lastAction: LeadsAction.archiveLead,
        ),
      );
    } on LeadException catch (error) {
      if (isClosed) {
        return;
      }
      emit(state.copyWith(status: LeadsStatus.failure, message: error.message));
    } catch (error) {
      if (isClosed) {
        return;
      }
      emit(
        state.copyWith(
          status: LeadsStatus.failure,
          message: _leadErrorMessage(
            error,
            'Unable to archive lead. Please try again.',
          ),
          lastAction: LeadsAction.archiveLead,
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
      if (isClosed) {
        return;
      }
      emit(
        state.copyWith(
          status: LeadsStatus.loaded,
          selectedLead: lead,
          clearMessage: true,
        ),
      );
    } on LeadException catch (error) {
      if (isClosed) {
        return;
      }
      emit(state.copyWith(status: LeadsStatus.failure, message: error.message));
    } catch (_) {
      if (isClosed) {
        return;
      }
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
          (notes) {
            if (isClosed) {
              return;
            }
            emit(state.copyWith(notes: notes));
          },
          onError: (_) {
            if (isClosed) {
              return;
            }
            emit(state.copyWith(notes: const <LeadNote>[]));
          },
        );
  }

  void watchTimeline({required String companyId, required String leadId}) {
    _timelineSubscription?.cancel();
    _timelineSubscription =
        _watchLeadTimelineUseCase(companyId: companyId, leadId: leadId).listen(
          (events) {
            if (isClosed) {
              return;
            }
            emit(state.copyWith(timeline: events));
          },
          onError: (_) {
            if (isClosed) {
              return;
            }
            emit(state.copyWith(timeline: const <LeadTimelineEvent>[]));
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
      await _guardFirebaseAction(
        () => _addLeadNoteUseCase(
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
        ),
      );

      await _guardFirebaseAction(
        () => _addTimelineEvent(
          companyId: companyId,
          leadId: leadId,
          type: 'noteAdded',
          title: 'note_added',
          description: text.trim(),
          oldValue: '',
          newValue: '',
          createdBy: createdBy,
          createdByName: actorName,
        ),
      );
      if (isClosed) {
        return;
      }
      emit(
        state.copyWith(
          status: LeadsStatus.saved,
          clearMessage: true,
          lastAction: LeadsAction.addNote,
        ),
      );
    } on LeadException catch (error) {
      if (isClosed) {
        return;
      }
      emit(state.copyWith(status: LeadsStatus.failure, message: error.message));
    } catch (error) {
      if (isClosed) {
        return;
      }
      emit(
        state.copyWith(
          status: LeadsStatus.failure,
          message: _leadErrorMessage(
            error,
            'Unable to add note. Please try again.',
          ),
          lastAction: LeadsAction.addNote,
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
      field: 'lastContactAt',
      oldValue: _timelineDateValue(oldLead.lastContactAt),
      newValue: _timelineDateValue(newLead.lastContactAt),
    );
    await addFieldEvent(
      field: 'nextFollowUpAt',
      oldValue: _timelineDateValue(oldLead.nextFollowUpAt),
      newValue: _timelineDateValue(newLead.nextFollowUpAt),
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
  }) async {
    try {
      await _addLeadTimelineEventUseCase(
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
    } catch (_) {
      // Timeline logging is best-effort so a denied optional log write does not
      // turn a successful lead action into a failed UI state.
    }
  }

  List<Lead> _applyFilters(
    List<Lead> leads, {
    String? searchQuery,
    LeadStatus? statusFilter,
    LeadSource? sourceFilter,
    LeadPriority? priorityFilter,
    String? assignedToFilter,
    LeadFollowUpFilter? followUpFilter,
  }) {
    final query = (searchQuery ?? '').trim().toLowerCase();
    final status = statusFilter;
    final source = sourceFilter;
    final priority = priorityFilter;
    final assignedTo = assignedToFilter;
    final followUp = followUpFilter;

    final filtered = leads.where((lead) {
      final matchesQuery =
          query.isEmpty ||
          lead.fullName.toLowerCase().contains(query) ||
          lead.phone.toLowerCase().contains(query) ||
          lead.email.toLowerCase().contains(query);
      final matchesStatus = status == null || lead.status == status;
      final matchesSource = source == null || lead.source == source;
      final matchesPriority = priority == null || lead.priority == priority;
      final matchesAssignee =
          assignedTo == null || lead.assignedTo == assignedTo;
      final matchesFollowUp =
          followUp == null || _matchesFollowUpFilter(lead, followUp);
      return matchesQuery &&
          matchesStatus &&
          matchesSource &&
          matchesPriority &&
          matchesAssignee &&
          matchesFollowUp;
    }).toList();

    filtered.sort(_compareByFollowUpUrgency);
    return filtered;
  }

  @override
  Future<void> close() {
    _leadsInitialLoadTimeout.cancel();
    _leadsSubscription?.cancel();
    _notesSubscription?.cancel();
    _timelineSubscription?.cancel();
    return super.close();
  }
}

bool _matchesFollowUpFilter(Lead lead, LeadFollowUpFilter filter) {
  final nextFollowUpAt = lead.nextFollowUpAt;
  if (nextFollowUpAt == null) {
    return filter == LeadFollowUpFilter.notScheduled;
  }

  final today = DateTime.now();
  final todayOnly = DateTime(today.year, today.month, today.day);
  final localFollowUp = nextFollowUpAt.toLocal();
  final followUpOnly = DateTime(
    localFollowUp.year,
    localFollowUp.month,
    localFollowUp.day,
  );

  return switch (filter) {
    LeadFollowUpFilter.overdue => followUpOnly.isBefore(todayOnly),
    LeadFollowUpFilter.dueToday => followUpOnly == todayOnly,
    LeadFollowUpFilter.upcoming => followUpOnly.isAfter(todayOnly),
    LeadFollowUpFilter.notScheduled => false,
  };
}

int _compareByFollowUpUrgency(Lead a, Lead b) {
  final rankComparison = _followUpUrgencyRank(
    a,
  ).compareTo(_followUpUrgencyRank(b));
  if (rankComparison != 0) {
    return rankComparison;
  }

  final rank = _followUpUrgencyRank(a);
  final aNext = a.nextFollowUpAt;
  final bNext = b.nextFollowUpAt;
  if (rank == 3 && aNext != null && bNext != null) {
    final aDate = _dateOnly(aNext.toLocal());
    final bDate = _dateOnly(bNext.toLocal());
    final dateComparison = aDate.compareTo(bDate);
    if (dateComparison != 0) {
      return dateComparison;
    }
  }

  return b.updatedAt.compareTo(a.updatedAt);
}

int _followUpUrgencyRank(Lead lead) {
  final today = _dateOnly(DateTime.now());
  final nextFollowUpAt = lead.nextFollowUpAt;
  if (nextFollowUpAt != null) {
    final followUpDate = _dateOnly(nextFollowUpAt.toLocal());
    if (followUpDate.isBefore(today)) {
      return 0;
    }
    if (followUpDate == today) {
      return 2;
    }
    return 3;
  }

  final lastContactAt = lead.lastContactAt;
  if (lastContactAt != null) {
    final staleBefore = today.subtract(const Duration(days: 7));
    if (_dateOnly(lastContactAt.toLocal()).isBefore(staleBefore)) {
      return 1;
    }
  }

  return 4;
}

DateTime _dateOnly(DateTime value) {
  return DateTime(value.year, value.month, value.day);
}

String _timelineDateValue(DateTime? value) {
  if (value == null) {
    return '';
  }

  final local = value.toLocal();
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  return '${local.year}-$month-$day';
}
