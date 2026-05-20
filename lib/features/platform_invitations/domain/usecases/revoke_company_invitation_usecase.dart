import '../repositories/platform_invitation_repository.dart';

class RevokeCompanyInvitationUseCase {
  const RevokeCompanyInvitationUseCase(this._repository);

  final PlatformInvitationRepository _repository;

  Future<void> call({required String invitationId}) {
    return _repository.revokeCompanyInvitation(invitationId: invitationId);
  }
}
