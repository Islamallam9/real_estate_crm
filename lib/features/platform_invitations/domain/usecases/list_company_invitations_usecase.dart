import '../entities/platform_invitation.dart';
import '../repositories/platform_invitation_repository.dart';

class ListCompanyInvitationsUseCase {
  const ListCompanyInvitationsUseCase(this._repository);

  final PlatformInvitationRepository _repository;

  Future<List<PlatformInvitation>> call({String? status}) {
    return _repository.listCompanyInvitations(status: status);
  }
}
