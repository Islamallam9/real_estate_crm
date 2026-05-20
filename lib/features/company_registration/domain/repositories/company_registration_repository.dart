import '../entities/company_invitation_preview.dart';

abstract interface class CompanyRegistrationRepository {
  Future<CompanyInvitationPreview> validateInvitation({
    required String invitationCode,
  });

  Future<CompanyRegistrationResult> acceptInvitation({
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
  });
}
