import 'dart:async';

import '../../../../core/archive/archive_filter.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../dashboard/domain/services/dashboard_truth_rules.dart';
import '../../../../core/utils/initial_load_timeout.dart';
import '../../../audit_logs/domain/entities/audit_log.dart';
import '../../../audit_logs/domain/usecases/create_audit_log_usecase.dart';
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
import '../../domain/usecases/restore_lead_usecase.dart';
import '../../domain/usecases/update_lead_usecase.dart';
import '../../domain/usecases/watch_lead_notes_usecase.dart';
import '../../domain/usecases/watch_lead_timeline_usecase.dart';
import '../../domain/usecases/watch_leads_usecase.dart';
import 'leads_state.dart';

class LeadsCubit extends Cubit<LeadsState> {
  LeadsCubit({
    required CreateLeadUseCase createLeadUseCase,
    required ArchiveLeadUseCase archiveLeadUseCase,
    required RestoreLeadUseCase restoreLeadUseCase,
    required UpdateLeadUseCase updateLeadUseCase,
    required GetLeadByIdUseCase getLeadByIdUseCase,
    required WatchLeadsUseCase watchLeadsUseCase,
    required AddLeadNoteUseCase addLeadNoteUseCase,
    required WatchLeadNotesUseCase watchLeadNotesUseCase,
    required AddLeadTimelineEventUseCase addLeadTimelineEventUseCase,
    required WatchLeadTimelineUseCase watchLeadTimelineUseCase,
    required CreateAuditLogUseCase createAuditLogUseCase,
  }) : _createLeadUseCase = createLeadUseCase,
       _archiveLeadUseCase = archiveLeadUseCase,
       _restoreLeadUseCase = restoreLeadUseCase,
       _updateLeadUseCase = updateLeadUseCase,
       _getLeadByIdUseCase = getLeadByIdUseCase,
       _watchLeadsUseCase = watchLeadsUseCase,
       _addLeadNoteUseCase = addLeadNoteUseCase,
       _watchLeadNotesUseCase = watchLeadNotesUseCase,
       _addLeadTimelineEventUseCase = addLeadTimelineEventUseCase,
       _watchLeadTimelineUseCase = watchLeadTimelineUseCase,
       _createAuditLogUseCase = createAuditLogUseCase,
       super(const LeadsState.initial());

  final CreateLeadUseCase _createLeadUseCase;
  final ArchiveLeadUseCase _archiveLeadUseCase;
  final RestoreLeadUseCase _restoreLeadUseCase;
  final UpdateLeadUseCase _updateLeadUseCase;
  final GetLeadByIdUseCase _getLeadByIdUseCase;
  final WatchLeadsUseCase _watchLeadsUseCase;
  final AddLeadNoteUseCase _addLeadNoteUseCase;
  final WatchLeadNotesUseCase _watchLeadNotesUseCase;
  final AddLeadTimelineEventUseCase _addLeadTimelineEventUseCase;
  final WatchLeadTimelineUseCase _watchLeadTimelineUseCase;
  final CreateAuditLogUseCase _createAuditLogUseCase;

  StreamSubscription<List<Lead>>? _leadsSubscription;
  StreamSubscription<List<LeadNote>>? _notesSubscription;
  StreamSubscription<List<LeadTimelineEvent>>? _timelineSubscription;
  final InitialLoadTimeout _leadsInitialLoadTimeout = InitialLoadTimeout();
  Future<bool> _hasConnection() async {
    final results = await Connectivity().checkConnectivity();
    return results.any((result) => result != ConnectivityResult.none);
  }

  Future<T> _guardFirebaseAction<T>(Future<T> Function() action) async {
    final connected = await _hasConnection();

    if (!connected) {
      throw const LeadException(AppErrorMessages.unableToConnect);
    }

    return action();
  }

  String _leadErrorMessage(Object error, String fallback) {
    if (error is LeadException) {
      return error.message;
    }

    return fallback;
  }

  void watchLeads({
    required String companyId,
    String? assignedTo,
    String? managerId,
    String? teamId,
    ArchiveFilter archiveFilter = ArchiveFilter.active,
  }) {
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
        _watchLeadsUseCase(
          companyId: companyId,
          assignedTo: assignedTo,
          managerId: managerId,
          teamId: teamId,
          archiveFilter: archiveFilter,
        ).listen(
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
              workQueueFilter: state.workQueueFilter,
            );
            emit(
              state.copyWith(
                status: filtered.isEmpty
                    ? LeadsStatus.empty
                    : LeadsStatus.loaded,
                leads: leads,
                filteredLeads: filtered,
                archiveFilter: archiveFilter,
                clearMessage: true,
              ),
            );
          },
          onError: (error) {
            if (isClosed) {
              return;
            }
            _leadsInitialLoadTimeout.complete();
            emit(
              state.copyWith(
                status: LeadsStatus.failure,
                message: _leadErrorMessage(
                  error,
                  AppErrorMessages.unknown,
                ),
              ),
            );
          },
        );
  }

  void setArchiveFilter(
    ArchiveFilter archiveFilter, {
    required String companyId,
    String? assignedTo,
    String? managerId,
    String? teamId,
  }) {
    emit(state.copyWith(archiveFilter: archiveFilter));
    watchLeads(
      companyId: companyId,
      assignedTo: assignedTo,
      managerId: managerId,
      teamId: teamId,
      archiveFilter: archiveFilter,
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
          workQueueFilter: state.workQueueFilter,
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
          workQueueFilter: state.workQueueFilter,
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
          workQueueFilter: state.workQueueFilter,
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
          workQueueFilter: state.workQueueFilter,
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
          workQueueFilter: state.workQueueFilter,
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
          workQueueFilter: state.workQueueFilter,
        ),
      ),
    );
  }

  void setWorkQueueFilter(LeadWorkQueueFilter? workQueueFilter) {
    emit(
      state.copyWith(
        workQueueFilter: workQueueFilter,
        clearWorkQueueFilter: workQueueFilter == null,
        filteredLeads: _applyFilters(
          state.leads,
          searchQuery: state.searchQuery,
          statusFilter: state.statusFilter,
          sourceFilter: state.sourceFilter,
          priorityFilter: state.priorityFilter,
          assignedToFilter: state.assignedToFilter,
          followUpFilter: state.followUpFilter,
          workQueueFilter: workQueueFilter,
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
      unawaited(
        _writeAuditLog(
          companyId: companyId,
          actorId: createdLead.createdBy,
          actorName: actorName,
          action: AuditLogAction.create,
          recordId: createdLead.id,
          recordTitle: _leadTitle(createdLead),
          recordSubtitle: _leadSubtitle(createdLead),
          metadata: {
            'status': _leadStatusValue(createdLead.status),
            'assignedTo': createdLead.assignedTo,
            'assignedToName': createdLead.assignedToName,
            'teamId': createdLead.teamId,
            'teamName': createdLead.teamName,
            'managerId': createdLead.managerId,
            'managerName': createdLead.managerName,
          },
        ),
      );
      if (createdLead.assignedTo.isNotEmpty) {
        unawaited(
          _writeAuditLog(
            companyId: companyId,
            actorId: createdLead.createdBy,
            actorName: actorName,
            action: AuditLogAction.assign,
            recordId: createdLead.id,
            recordTitle: _leadTitle(createdLead),
            recordSubtitle: _leadSubtitle(createdLead),
            metadata: {
              'assignedTo': createdLead.assignedTo,
              'assignedToName': createdLead.assignedToName,
              'teamId': createdLead.teamId,
              'teamName': createdLead.teamName,
              'managerId': createdLead.managerId,
              'managerName': createdLead.managerName,
            },
          ),
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
      final auditAction = current.status != updated.status
          ? AuditLogAction.statusChange
          : current.assignedTo != updated.assignedTo
          ? AuditLogAction.assign
          : AuditLogAction.update;
      final auditMetadata = _leadChangeAuditMetadata(current, updated);
      unawaited(
        _writeAuditLog(
          companyId: companyId,
          actorId: updated.updatedBy,
          actorName: actorName,
          action: auditAction,
          recordId: updated.id,
          recordTitle: _leadTitle(updated),
          recordSubtitle: _leadSubtitle(updated),
          metadata: auditMetadata,
        ),
      );
      if (isClosed) {
        return;
      }
      final updatedLeads = _replaceLeadInCurrentList(updated);
      emit(
        state.copyWith(
          status: LeadsStatus.saved,
          leads: updatedLeads,
          filteredLeads: _applyFilters(
            updatedLeads,
            searchQuery: state.searchQuery,
            statusFilter: state.statusFilter,
            sourceFilter: state.sourceFilter,
            priorityFilter: state.priorityFilter,
            assignedToFilter: state.assignedToFilter,
            followUpFilter: state.followUpFilter,
            workQueueFilter: state.workQueueFilter,
          ),
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


  List<Lead> _replaceLeadInCurrentList(Lead updated) {
    final index = state.leads.indexWhere((lead) => lead.id == updated.id);
    if (index < 0) {
      return state.leads;
    }
    final next = List<Lead>.of(state.leads);
    next[index] = updated;
    return next;
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
    String reason = '',
  }) async {
    emit(state.copyWith(status: LeadsStatus.saving, clearMessage: true));
    try {
      await _guardFirebaseAction(
        () => _archiveLeadUseCase(
          companyId: companyId,
          leadId: leadId,
          archivedBy: archivedBy,
          reason: reason,
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
      final lead = state.selectedLead ?? _leadById(leadId);
      unawaited(
        _writeAuditLog(
          companyId: companyId,
          actorId: archivedBy,
          actorName: actorName,
          action: AuditLogAction.archive,
          recordId: leadId,
          recordTitle: lead == null ? 'Lead' : _leadTitle(lead),
          recordSubtitle: lead == null ? '' : _leadSubtitle(lead),
          metadata: {
            if (lead != null) ...{
              'assignedTo': lead.assignedTo,
              'assignedToName': lead.assignedToName,
              'teamId': lead.teamId,
              'teamName': lead.teamName,
              'managerId': lead.managerId,
              'managerName': lead.managerName,
            },
          },
        ),
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

  Future<void> restoreLead({
    required String companyId,
    required String leadId,
    required String restoredBy,
    required String actorName,
  }) async {
    emit(state.copyWith(status: LeadsStatus.saving, clearMessage: true));
    try {
      await _guardFirebaseAction(
        () => _restoreLeadUseCase(
          companyId: companyId,
          leadId: leadId,
          restoredBy: restoredBy,
        ),
      );
      final lead = state.selectedLead ?? _leadById(leadId);
      unawaited(
        _writeAuditLog(
          companyId: companyId,
          actorId: restoredBy,
          actorName: actorName,
          action: AuditLogAction.restore,
          recordId: leadId,
          recordTitle: lead == null ? 'Lead' : _leadTitle(lead),
          recordSubtitle: lead == null ? '' : _leadSubtitle(lead),
          metadata: {
            if (lead != null) ...{
              'assignedTo': lead.assignedTo,
              'assignedToName': lead.assignedToName,
              'teamId': lead.teamId,
              'teamName': lead.teamName,
              'managerId': lead.managerId,
              'managerName': lead.managerName,
            },
          },
        ),
      );
      if (isClosed) {
        return;
      }
      emit(
        state.copyWith(
          status: LeadsStatus.saved,
          clearMessage: true,
          lastAction: LeadsAction.restoreLead,
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
            'Unable to restore lead. Please try again.',
          ),
          lastAction: LeadsAction.restoreLead,
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
      field: 'sourceDetails',
      oldValue: oldLead.sourceDetails,
      newValue: newLead.sourceDetails,
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

  Map<String, Object?> _leadChangeAuditMetadata(
    Lead oldLead,
    Lead newLead,
  ) {
    final changes = <Map<String, String>>[];

    void addChange(String field, String oldValue, String newValue) {
      if (oldValue == newValue) {
        return;
      }
      changes.add({
        'field': field,
        'oldValue': oldValue,
        'newValue': newValue,
      });
    }

    addChange('fullName', oldLead.fullName, newLead.fullName);
    addChange('phone', oldLead.phone, newLead.phone);
    addChange('email', oldLead.email, newLead.email);
    addChange('source', oldLead.source.name, newLead.source.name);
    addChange('sourceDetails', oldLead.sourceDetails, newLead.sourceDetails);
    addChange('status', oldLead.status.name, newLead.status.name);
    addChange('priority', oldLead.priority.name, newLead.priority.name);
    addChange(
      'budgetMin',
      oldLead.budgetMin.toString(),
      newLead.budgetMin.toString(),
    );
    addChange(
      'budgetMax',
      oldLead.budgetMax.toString(),
      newLead.budgetMax.toString(),
    );
    addChange(
      'preferredLocation',
      oldLead.preferredLocation,
      newLead.preferredLocation,
    );
    addChange(
      'preferredPropertyType',
      oldLead.preferredPropertyType,
      newLead.preferredPropertyType,
    );
    addChange('notes', oldLead.notes, newLead.notes);
    addChange(
      'lastContactAt',
      _timelineDateValue(oldLead.lastContactAt),
      _timelineDateValue(newLead.lastContactAt),
    );
    addChange(
      'nextFollowUpAt',
      _timelineDateValue(oldLead.nextFollowUpAt),
      _timelineDateValue(newLead.nextFollowUpAt),
    );
    addChange(
      'assignedTo',
      oldLead.assignedToName.isNotEmpty ? oldLead.assignedToName : oldLead.assignedTo,
      newLead.assignedToName.isNotEmpty ? newLead.assignedToName : newLead.assignedTo,
    );

    return {
      if (oldLead.status != newLead.status) ...{
        'previousStatus': _leadStatusValue(oldLead.status),
        'newStatus': _leadStatusValue(newLead.status),
      },
      'assignedTo': newLead.assignedTo,
      'assignedToName': newLead.assignedToName,
      'teamId': newLead.teamId,
      'teamName': newLead.teamName,
      'managerId': newLead.managerId,
      'managerName': newLead.managerName,
      if (changes.isNotEmpty) ...{
        'changedFields': changes,
        'changesSummary': changes
            .map((change) => change['field'] ?? '')
            .where((field) => field.isNotEmpty)
            .join(', '),
      },
    };
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

  Future<void> _writeAuditLog({
    required String companyId,
    required String actorId,
    required String actorName,
    required AuditLogAction action,
    required String recordId,
    required String recordTitle,
    required String recordSubtitle,
    required Map<String, Object?> metadata,
  }) async {
    try {
      await _createAuditLogUseCase(
        companyId: companyId,
        auditLog: AuditLog(
          id: '',
          companyId: companyId,
          actorId: actorId,
          actorName: actorName,
          actorEmail: '',
          actorRole: '',
          action: action,
          module: AuditLogModule.leads,
          recordId: recordId,
          recordTitle: recordTitle,
          recordSubtitle: recordSubtitle,
          createdAt: DateTime.now(),
          metadata: metadata,
        ),
      );
    } catch (_) {
      // Audit logging is best-effort and must not block lead workflows.
    }
  }

  Lead? _leadById(String leadId) {
    for (final lead in state.leads) {
      if (lead.id == leadId) {
        return lead;
      }
    }
    return null;
  }

  List<Lead> _applyFilters(
    List<Lead> leads, {
    String? searchQuery,
    LeadStatus? statusFilter,
    LeadSource? sourceFilter,
    LeadPriority? priorityFilter,
    String? assignedToFilter,
    LeadFollowUpFilter? followUpFilter,
    LeadWorkQueueFilter? workQueueFilter,
  }) {
    final query = (searchQuery ?? '').trim().toLowerCase();
    final status = statusFilter;
    final source = sourceFilter;
    final priority = priorityFilter;
    final assignedTo = assignedToFilter;
    final followUp = followUpFilter;
    final workQueue = workQueueFilter;

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
      final matchesWorkQueue =
          workQueue == null || _matchesWorkQueueFilter(lead, workQueue);
      return matchesQuery &&
          matchesStatus &&
          matchesSource &&
          matchesPriority &&
          matchesAssignee &&
          matchesFollowUp &&
          matchesWorkQueue;
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

  return switch (filter) {
    LeadFollowUpFilter.overdue =>
      DashboardTruthRules.isOverdueFollowUpLead(lead, today),
    LeadFollowUpFilter.dueToday =>
      DashboardTruthRules.isDueTodayFollowUpLead(lead, today),
    LeadFollowUpFilter.upcoming =>
      DashboardTruthRules.isActiveLead(lead) &&
          DashboardTruthRules.dateOnly(nextFollowUpAt).isAfter(
            DashboardTruthRules.dateOnly(today),
          ),
    LeadFollowUpFilter.notScheduled => false,
  };
}

bool _matchesWorkQueueFilter(Lead lead, LeadWorkQueueFilter filter) {
  return switch (filter) {
    LeadWorkQueueFilter.active => _isActiveLead(lead),
    LeadWorkQueueFilter.newToday => _dateOnly(lead.createdAt) == _dateOnly(DateTime.now()),
    LeadWorkQueueFilter.hot => _isHotLead(lead),
    LeadWorkQueueFilter.stale => _isStaleLead(lead),
    LeadWorkQueueFilter.unassigned =>
      _isActiveLead(lead) && lead.assignedTo.trim().isEmpty,
  };
}

bool _isActiveLead(Lead lead) {
  return DashboardTruthRules.isActiveLead(lead);
}

bool _isHotLead(Lead lead) {
  return DashboardTruthRules.isHotLead(lead);
}

bool _isStaleLead(Lead lead) {
  if (!_isActiveLead(lead)) {
    return false;
  }
  final lastTouch = _latestDate([
    lead.lastContactAt,
    lead.updatedAt,
    lead.createdAt,
  ]);
  if (lastTouch == null) {
    return false;
  }
  final today = _dateOnly(DateTime.now());
  return today.difference(_dateOnly(lastTouch.toLocal())).inDays > 5;
}

DateTime? _latestDate(List<DateTime?> dates) {
  DateTime? latest;
  for (final date in dates) {
    if (date == null) {
      continue;
    }
    if (latest == null || date.isAfter(latest)) {
      latest = date;
    }
  }
  return latest;
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
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '${local.year}-$month-$day $hour:$minute';
}

String _leadTitle(Lead lead) {
  final name = lead.fullName.trim();
  return name.isEmpty ? 'Lead' : name;
}

String _leadSubtitle(Lead lead) {
  final phone = lead.phone.trim();
  if (phone.isNotEmpty) {
    return phone;
  }
  return _leadStatusValue(lead.status);
}

String _leadStatusValue(LeadStatus status) {
  return switch (status) {
    LeadStatus.newLead => 'new',
    LeadStatus.contacted => 'contacted',
    LeadStatus.interested => 'interested',
    LeadStatus.visitScheduled => 'visitScheduled',
    LeadStatus.negotiation => 'negotiation',
    LeadStatus.won => 'won',
    LeadStatus.lost => 'lost',
  };
}
