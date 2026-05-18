import '../../../../core/constants/role_constants.dart';
import '../../../users/domain/entities/company_metadata.dart';
import '../../domain/entities/company_data_health_report.dart';
import '../../domain/entities/password_reset_link_result.dart';
import '../../domain/entities/platform_company_user.dart';
import '../../domain/repositories/platform_repository.dart';
import '../datasources/platform_remote_data_source.dart';

class PlatformRepositoryImpl implements PlatformRepository {
  const PlatformRepositoryImpl({required PlatformRemoteDataSource remoteDataSource})
    : _remoteDataSource = remoteDataSource;

  final PlatformRemoteDataSource _remoteDataSource;

  @override
  Stream<List<CompanyMetadata>> watchCompanies() {
    return _remoteDataSource.watchCompanies();
  }

  @override
  Stream<List<PlatformCompanyUser>> watchCompanyUsers({
    required String companyId,
  }) {
    return _remoteDataSource.watchCompanyUsers(companyId: companyId);
  }

  @override
  Future<void> createCompanyWithAdmin({
    required String companyId,
    required String companyName,
    required String adminFullName,
    required String adminEmail,
    required String adminPhone,
    required String locale,
    required String timezone,
  }) {
    return _remoteDataSource.createCompanyWithAdmin(
      companyId: companyId,
      companyName: companyName,
      adminFullName: adminFullName,
      adminEmail: adminEmail,
      adminPhone: adminPhone,
      locale: locale,
      timezone: timezone,
    );
  }

  @override
  Future<void> addUserToCompany({
    required String companyId,
    required String fullName,
    required String email,
    required String phone,
    required UserRole role,
  }) {
    return _remoteDataSource.addUserToCompany(
      companyId: companyId,
      fullName: fullName,
      email: email,
      phone: phone,
      role: role,
    );
  }

  @override
  Future<void> setCompanyActiveStatus({
    required String companyId,
    required bool isActive,
  }) {
    return _remoteDataSource.setCompanyActiveStatus(
      companyId: companyId,
      isActive: isActive,
    );
  }

  @override
  Future<void> setCompanyUserActiveStatus({
    required String companyId,
    required String uid,
    required bool isActive,
  }) {
    return _remoteDataSource.setCompanyUserActiveStatus(
      companyId: companyId,
      uid: uid,
      isActive: isActive,
    );
  }

  @override
  Future<void> setCompanyUserPassword({
    required String companyId,
    required String uid,
    required String newPassword,
  }) {
    return _remoteDataSource.setCompanyUserPassword(
      companyId: companyId,
      uid: uid,
      newPassword: newPassword,
    );
  }

  @override
  Future<void> setCompanyUserEmail({
    required String companyId,
    required String uid,
    required String newEmail,
  }) {
    return _remoteDataSource.setCompanyUserEmail(
      companyId: companyId,
      uid: uid,
      newEmail: newEmail,
    );
  }

  @override
  Future<PasswordResetLinkResult> generateCompanyUserPasswordResetLink({
    required String companyId,
    required String uid,
  }) {
    return _remoteDataSource.generateCompanyUserPasswordResetLink(
      companyId: companyId,
      uid: uid,
    );
  }

  @override
  Future<void> updateCompanyPlatformSettings({
    required String companyId,
    String? name,
    String? displayName,
    String? status,
    bool? isActive,
    Map<String, Object?>? settings,
    Map<String, Object?>? limits,
    Map<String, Object?>? features,
  }) {
    return _remoteDataSource.updateCompanyPlatformSettings(
      companyId: companyId,
      name: name,
      displayName: displayName,
      status: status,
      isActive: isActive,
      settings: settings,
      limits: limits,
      features: features,
    );
  }

  @override
  Future<CompanyDataHealthReport> getCompanyDataHealthReport({
    required String companyId,
  }) {
    return _remoteDataSource.getCompanyDataHealthReport(companyId: companyId);
  }

  @override
  Future<void> backfillAssignedRecordSnapshots({
    required String companyId,
    required String module,
    required String recordId,
  }) {
    return _remoteDataSource.backfillAssignedRecordSnapshots(
      companyId: companyId,
      module: module,
      recordId: recordId,
    );
  }
}
