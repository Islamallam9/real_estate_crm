import '../entities/company_invitation_preview.dart';
import '../repositories/company_registration_repository.dart';

class ValidateCompanyInvitationUseCase {
  const ValidateCompanyInvitationUseCase(this._repository);

  final CompanyRegistrationRepository _repository;

  Future<CompanyInvitationPreview> call({required String invitationCode}) {
    return _repository.validateInvitation(invitationCode: invitationCode);
  }
}
