import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/lead.dart';
import '../../domain/errors/lead_exception.dart';
import '../../domain/usecases/archive_lead_usecase.dart';
import '../../domain/usecases/create_lead_usecase.dart';
import '../../domain/usecases/get_lead_by_id_usecase.dart';
import '../../domain/usecases/update_lead_usecase.dart';
import '../../domain/usecases/watch_leads_usecase.dart';
import 'leads_state.dart';

class LeadsCubit extends Cubit<LeadsState> {
  LeadsCubit({
    required CreateLeadUseCase createLeadUseCase,
    required ArchiveLeadUseCase archiveLeadUseCase,
    required UpdateLeadUseCase updateLeadUseCase,
    required GetLeadByIdUseCase getLeadByIdUseCase,
    required WatchLeadsUseCase watchLeadsUseCase,
  }) : _createLeadUseCase = createLeadUseCase,
       _archiveLeadUseCase = archiveLeadUseCase,
       _updateLeadUseCase = updateLeadUseCase,
       _getLeadByIdUseCase = getLeadByIdUseCase,
       _watchLeadsUseCase = watchLeadsUseCase,
       super(const LeadsState.initial());

  final CreateLeadUseCase _createLeadUseCase;
  final ArchiveLeadUseCase _archiveLeadUseCase;
  final UpdateLeadUseCase _updateLeadUseCase;
  final GetLeadByIdUseCase _getLeadByIdUseCase;
  final WatchLeadsUseCase _watchLeadsUseCase;

  StreamSubscription<List<Lead>>? _leadsSubscription;

  void watchLeads({required String companyId}) {
    emit(state.copyWith(status: LeadsStatus.loading, clearMessage: true));
    _leadsSubscription?.cancel();
    _leadsSubscription = _watchLeadsUseCase(companyId: companyId).listen(
      (leads) {
        emit(
          state.copyWith(
            status: leads.isEmpty ? LeadsStatus.empty : LeadsStatus.loaded,
            leads: leads,
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

  Future<void> createLead({
    required String companyId,
    required Lead lead,
  }) async {
    emit(state.copyWith(status: LeadsStatus.saving, clearMessage: true));

    try {
      await _createLeadUseCase(companyId: companyId, lead: lead);
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
  }) async {
    emit(state.copyWith(status: LeadsStatus.saving, clearMessage: true));

    try {
      await _updateLeadUseCase(companyId: companyId, lead: lead);
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

  Future<void> archiveLead({
    required String companyId,
    required String leadId,
    required String archivedBy,
  }) async {
    emit(state.copyWith(status: LeadsStatus.saving, clearMessage: true));

    try {
      await _archiveLeadUseCase(
        companyId: companyId,
        leadId: leadId,
        archivedBy: archivedBy,
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

  @override
  Future<void> close() {
    _leadsSubscription?.cancel();
    return super.close();
  }
}
