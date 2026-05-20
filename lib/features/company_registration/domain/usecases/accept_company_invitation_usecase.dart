import '../entities/company_invitation_preview.dart';
import '../repositories/company_registration_repository.dart';

class AcceptCompanyInvitationUseCase {
  const AcceptCompanyInvitationUseCase(this._repository);

  final CompanyRegistrationRepository _repository;

  Future<CompanyRegistrationResult> call({
    required String invitationCode,
    required String companyName,
    required String companySlug,
    required String companyPhone,
    required String companyCity,
    required String companyWebsite,
    required String adminFullName,
    required String adminPhone,
    required String adminEmail,
    required String password,
    required String confirmPassword,
    required String locale,
    required String timezone,
  }) {
    return _repository.acceptInvitation(
      invitationCode: invitationCode,
      companyName: companyName,
      companySlug: companySlug,
      companyPhone: companyPhone,
      companyCity: companyCity,
      companyWebsite: companyWebsite,
      adminFullName: adminFullName,
      adminPhone: adminPhone,
      adminEmail: adminEmail,
      password: password,
      confirmPassword: confirmPassword,
      locale: locale,
      timezone: timezone,
    );
  }
}
