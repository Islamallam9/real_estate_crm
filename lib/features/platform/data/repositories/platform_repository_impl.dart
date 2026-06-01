import '../../../../core/constants/role_constants.dart';
import '../../../users/domain/entities/company_metadata.dart';
import '../../../app_update/domain/entities/android_release_policy.dart';
import '../../domain/entities/android_version_adoption.dart';
import '../../domain/entities/company_data_health_report.dart';
import '../../domain/entities/password_reset_link_result.dart';
import '../../domain/entities/platform_company_user.dart';
import '../../domain/entities/platform_login_activity.dart';
import '../../domain/entities/platform_payment_history.dart';
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
  Stream<List<PlatformLoginActivity>> watchCompanyLoginActivity({
    required String companyId,
    int limit = 300,
  }) {
    return _remoteDataSource.watchCompanyLoginActivity(
      companyId: companyId,
      limit: limit,
    );
  }

  @override
  Stream<List<PlatformPaymentHistory>> watchPaymentHistory({
    required String companyId,
  }) {
    return _remoteDataSource.watchPaymentHistory(companyId: companyId);
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
    int? trialDays,
    String trialDurationUnit = 'days',
  }) {
    return _remoteDataSource.createCompanyWithAdmin(
      companyId: companyId,
      companyName: companyName,
      adminFullName: adminFullName,
      adminEmail: adminEmail,
      adminPhone: adminPhone,
      locale: locale,
      timezone: timezone,
      trialDays: trialDays,
      trialDurationUnit: trialDurationUnit,
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
    DateTime? trialEndsAt,
    int? trialDurationValue,
    String? trialDurationUnit,
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
      trialEndsAt: trialEndsAt,
      trialDurationValue: trialDurationValue,
      trialDurationUnit: trialDurationUnit,
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

  @override
  Future<void> refreshCompanyStorageUsage({required String companyId}) {
    return _remoteDataSource.refreshCompanyStorageUsage(companyId: companyId);
  }

  @override
  Future<void> markCompanyPaymentPaid({
    required String companyId,
    required double amount,
    required String currency,
    required DateTime paymentDate,
    required DateTime nextPaymentDueAt,
    required String paymentCycle,
    required String notes,
  }) {
    return _remoteDataSource.markCompanyPaymentPaid(
      companyId: companyId,
      amount: amount,
      currency: currency,
      paymentDate: paymentDate,
      nextPaymentDueAt: nextPaymentDueAt,
      paymentCycle: paymentCycle,
      notes: notes,
    );
  }

  @override
  Future<void> extendCompanyPaymentDueDate({
    required String companyId,
    required DateTime nextPaymentDueAt,
    required String notes,
  }) {
    return _remoteDataSource.extendCompanyPaymentDueDate(
      companyId: companyId,
      nextPaymentDueAt: nextPaymentDueAt,
      notes: notes,
    );
  }

  @override
  Future<void> updateCompanyPaymentStatus({
    required String companyId,
    required String paymentStatus,
    DateTime? nextPaymentDueAt,
    DateTime? gracePeriodEndsAt,
    String? suspendedReason,
    String? notes,
  }) {
    return _remoteDataSource.updateCompanyPaymentStatus(
      companyId: companyId,
      paymentStatus: paymentStatus,
      nextPaymentDueAt: nextPaymentDueAt,
      gracePeriodEndsAt: gracePeriodEndsAt,
      suspendedReason: suspendedReason,
      notes: notes,
    );
  }

  @override
  Future<Map<String, dynamic>> exportCompanyData({
    required String companyId,
    List<String>? collections,
  }) {
    return _remoteDataSource.exportCompanyData(
      companyId: companyId,
      collections: collections,
    );
  }

  @override
  Future<AndroidReleasePolicy> getAndroidReleasePolicy() {
    return _remoteDataSource.getAndroidReleasePolicy();
  }

  @override
  Future<AndroidVersionAdoptionSummary> getAndroidVersionAdoption() {
    return _remoteDataSource.getAndroidVersionAdoption();
  }

  @override
  Future<void> updateAndroidReleasePolicy({
    required bool enabled,
    required bool releaseReady,
    required int minimumSupportedBuildNumber,
    required int latestBuildNumber,
    required String updateUrl,
    required String titleEn,
    required String titleAr,
    required String bodyEn,
    required String bodyAr,
  }) {
    return _remoteDataSource.updateAndroidReleasePolicy(
      enabled: enabled,
      releaseReady: releaseReady,
      minimumSupportedBuildNumber: minimumSupportedBuildNumber,
      latestBuildNumber: latestBuildNumber,
      updateUrl: updateUrl,
      titleEn: titleEn,
      titleAr: titleAr,
      bodyEn: bodyEn,
      bodyAr: bodyAr,
    );
  }

}
