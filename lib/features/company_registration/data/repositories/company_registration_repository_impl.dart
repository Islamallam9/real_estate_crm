import '../../domain/entities/company_invitation_preview.dart';
import '../../domain/repositories/company_registration_repository.dart';
import '../datasources/company_registration_remote_data_source.dart';

class CompanyRegistrationRepositoryImpl
    implements CompanyRegistrationRepository {
  const CompanyRegistrationRepositoryImpl({required this.remoteDataSource});

  final CompanyRegistrationRemoteDataSource remoteDataSource;

  @override
  Future<CompanyInvitationPreview> validateInvitation({
    required String invitationCode,
  }) {
    return remoteDataSource.validateInvitation(invitationCode: invitationCode);
  }

  @override
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
  }) {
    return remoteDataSource.acceptInvitation(
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
