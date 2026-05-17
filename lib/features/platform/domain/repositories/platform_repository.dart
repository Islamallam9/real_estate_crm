import '../../../../core/constants/role_constants.dart';
import '../../../users/domain/entities/company_metadata.dart';
import '../entities/password_reset_link_result.dart';
import '../entities/platform_company_user.dart';

abstract interface class PlatformRepository {
  Stream<List<CompanyMetadata>> watchCompanies();

  Stream<List<PlatformCompanyUser>> watchCompanyUsers({
    required String companyId,
  });

  Future<void> createCompanyWithAdmin({
    required String companyId,
    required String companyName,
    required String adminFullName,
    required String adminEmail,
    required String adminPhone,
    required String locale,
    required String timezone,
  });

  Future<void> addUserToCompany({
    required String companyId,
    required String fullName,
    required String email,
    required String phone,
    required UserRole role,
  });

  Future<void> setCompanyActiveStatus({
    required String companyId,
    required bool isActive,
  });

  Future<void> setCompanyUserActiveStatus({
    required String companyId,
    required String uid,
    required bool isActive,
  });

  Future<void> setCompanyUserPassword({
    required String companyId,
    required String uid,
    required String newPassword,
  });

  Future<void> setCompanyUserEmail({
    required String companyId,
    required String uid,
    required String newEmail,
  });

  Future<PasswordResetLinkResult> generateCompanyUserPasswordResetLink({
    required String companyId,
    required String uid,
  });

  Future<void> updateCompanyPlatformSettings({
    required String companyId,
    String? name,
    String? displayName,
    String? status,
    bool? isActive,
    Map<String, Object?>? settings,
    Map<String, Object?>? limits,
    Map<String, Object?>? features,
  });
}
