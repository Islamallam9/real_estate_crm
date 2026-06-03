import '../../../../core/constants/role_constants.dart';
import '../../../users/domain/entities/company_metadata.dart';
import '../../../app_update/domain/entities/android_release_policy.dart';
import '../entities/android_version_adoption.dart';
import '../entities/company_data_health_report.dart';
import '../entities/password_reset_link_result.dart';
import '../entities/platform_company_user.dart';
import '../entities/platform_login_activity.dart';
import '../entities/platform_payment_history.dart';
import '../entities/release_intelligence.dart';

abstract interface class PlatformRepository {
  Stream<List<CompanyMetadata>> watchCompanies();

  Stream<List<PlatformCompanyUser>> watchCompanyUsers({
    required String companyId,
  });

  Stream<List<PlatformLoginActivity>> watchCompanyLoginActivity({
    required String companyId,
    int limit = 300,
  });

  Stream<List<PlatformPaymentHistory>> watchPaymentHistory({
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
    int? trialDays,
    String trialDurationUnit = 'days',
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
    DateTime? trialEndsAt,
    int? trialDurationValue,
    String? trialDurationUnit,
  });

  Future<CompanyDataHealthReport> getCompanyDataHealthReport({
    required String companyId,
  });

  Future<void> backfillAssignedRecordSnapshots({
    required String companyId,
    required String module,
    required String recordId,
  });

  Future<void> refreshCompanyStorageUsage({required String companyId});

  Future<void> markCompanyPaymentPaid({
    required String companyId,
    required double amount,
    required String currency,
    required DateTime paymentDate,
    required DateTime nextPaymentDueAt,
    required String paymentCycle,
    required String notes,
  });

  Future<void> extendCompanyPaymentDueDate({
    required String companyId,
    required DateTime nextPaymentDueAt,
    required String notes,
  });

  Future<void> updateCompanyPaymentStatus({
    required String companyId,
    required String paymentStatus,
    DateTime? nextPaymentDueAt,
    DateTime? gracePeriodEndsAt,
    String? suspendedReason,
    String? notes,
  });

  Future<Map<String, dynamic>> exportCompanyData({
    required String companyId,
    List<String>? collections,
  });

  Future<AndroidReleasePolicy> getAndroidReleasePolicy();

  Future<AndroidVersionAdoptionSummary> getAndroidVersionAdoption({
    String? companyId,
  });

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
  });

  Future<ReleaseIntelligenceSummary> getReleaseIntelligenceSummary({
    int activeWithinDays = 30,
  });

  Future<List<VersionAdoptionRow>> getPlatformVersionAdoption({
    String platform = 'all',
    String? companyId,
    int activeWithinDays = 30,
    bool includeInactive = false,
  });

  Future<List<PlatformDeviceInstallRow>> getPlatformDeviceList({
    String platform = 'all',
    String? companyId,
    int activeWithinDays = 30,
    int limit = 120,
  });

  Future<List<DeviceVersionEventRow>> getPlatformVersionHistory({
    String platform = 'all',
    String? companyId,
    int limit = 120,
  });

  Future<void> createPlatformReleaseRecord({
    required String platform,
    required String appVersion,
    required int buildNumber,
    required int minimumSupportedBuildNumber,
    required int latestBuildNumber,
    required String updateUrl,
    required bool enabled,
    required bool releaseReady,
    required String status,
  });
}
