import 'package:bloc/bloc.dart';

import '../../domain/usecases/create_company_invitation_usecase.dart';
import '../../domain/usecases/list_company_invitations_usecase.dart';
import '../../domain/usecases/revoke_company_invitation_usecase.dart';
import 'platform_invitations_state.dart';

class PlatformInvitationsCubit extends Cubit<PlatformInvitationsState> {
  PlatformInvitationsCubit({
    required CreateCompanyInvitationUseCase createCompanyInvitationUseCase,
    required ListCompanyInvitationsUseCase listCompanyInvitationsUseCase,
    required RevokeCompanyInvitationUseCase revokeCompanyInvitationUseCase,
  }) : _createCompanyInvitationUseCase = createCompanyInvitationUseCase,
       _listCompanyInvitationsUseCase = listCompanyInvitationsUseCase,
       _revokeCompanyInvitationUseCase = revokeCompanyInvitationUseCase,
       super(const PlatformInvitationsState.initial());

  final CreateCompanyInvitationUseCase _createCompanyInvitationUseCase;
  final ListCompanyInvitationsUseCase _listCompanyInvitationsUseCase;
  final RevokeCompanyInvitationUseCase _revokeCompanyInvitationUseCase;

  Future<void> loadInvitations() async {
    emit(
      state.copyWith(
        status: PlatformInvitationsStatus.loading,
        clearMessage: true,
      ),
    );
    try {
      final invitations = await _listCompanyInvitationsUseCase();
      emit(
        state.copyWith(
          status: PlatformInvitationsStatus.ready,
          invitations: invitations,
          clearMessage: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: PlatformInvitationsStatus.failure,
          message: error.toString(),
        ),
      );
    }
  }

  void updateFilter(PlatformInvitationFilter filter) {
    emit(state.copyWith(filter: filter, clearMessage: true));
  }

  void clearCreatedInvitation() {
    emit(state.copyWith(clearCreatedInvitation: true, clearMessage: true));
  }

  Future<bool> createInvitation({
    required String planId,
    required String planName,
    required int userLimit,
    required int storageLimitMb,
    required Map<String, bool> features,
    required String locale,
    required String timezone,
    required DateTime expiresAt,
    required String notes,
  }) async {
    emit(
      state.copyWith(
        status: PlatformInvitationsStatus.saving,
        clearCreatedInvitation: true,
        clearMessage: true,
      ),
    );
    try {
      final created = await _createCompanyInvitationUseCase(
        planId: planId,
        planName: planName,
        userLimit: userLimit,
        storageLimitMb: storageLimitMb,
        features: features,
        locale: locale,
        timezone: timezone,
        expiresAt: expiresAt,
          notes: notes,
      );
      final invitations = await _listCompanyInvitationsUseCase();
      emit(
        state.copyWith(
          status: PlatformInvitationsStatus.ready,
          invitations: invitations,
          createdInvitation: created,
          clearMessage: true,
        ),
      );
      return true;
    } catch (error) {
      emit(
        state.copyWith(
          status: PlatformInvitationsStatus.failure,
          message: error.toString(),
        ),
      );
      return false;
    }
  }

  Future<bool> revokeInvitation(String invitationId) async {
    emit(
      state.copyWith(
        status: PlatformInvitationsStatus.saving,
        activeActionId: invitationId,
        clearMessage: true,
      ),
    );
    try {
      await _revokeCompanyInvitationUseCase(invitationId: invitationId);
      final invitations = await _listCompanyInvitationsUseCase();
      emit(
        state.copyWith(
          status: PlatformInvitationsStatus.ready,
          invitations: invitations,
          clearActiveAction: true,
          clearMessage: true,
        ),
      );
      return true;
    } catch (error) {
      emit(
        state.copyWith(
          status: PlatformInvitationsStatus.failure,
          message: error.toString(),
          clearActiveAction: true,
        ),
      );
      return false;
    }
  }
}
