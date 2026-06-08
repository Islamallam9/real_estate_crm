import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/firebase_paths.dart';
import '../../../../core/constants/role_constants.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../users/data/models/company_metadata_model.dart';
import '../../../users/domain/entities/company_metadata.dart';
import '../../../app_update/domain/entities/android_release_policy.dart';
import '../../domain/entities/android_version_adoption.dart';
import '../../domain/entities/password_reset_link_result.dart';
import '../../domain/entities/platform_company_user.dart';
import '../../domain/entities/platform_login_activity.dart';
import '../../domain/entities/release_intelligence.dart';
import '../models/company_data_health_report_model.dart';
import '../models/platform_company_user_model.dart';
import '../models/platform_login_activity_model.dart';
import '../models/platform_payment_history_model.dart';

abstract interface class PlatformRemoteDataSource {
  Stream<List<CompanyMetadata>> watchCompanies();

  Stream<List<PlatformCompanyUser>> watchCompanyUsers({
    required String companyId,
  });

  Stream<List<PlatformLoginActivity>> watchCompanyLoginActivity({
    required String companyId,
    int limit = 300,
  });

  Stream<List<PlatformPaymentHistoryModel>> watchPaymentHistory({
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

  Future<CompanyDataHealthReportModel> getCompanyDataHealthReport({
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

class FirebasePlatformRemoteDataSource implements PlatformRemoteDataSource {
  FirebasePlatformRemoteDataSource({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  @override
  Stream<List<CompanyMetadata>> watchCompanies() {
    return _firestore
        .collection('companies')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map(CompanyMetadataModel.fromFirestore).toList();
        });
  }

  @override
  Stream<List<PlatformCompanyUser>> watchCompanyUsers({
    required String companyId,
  }) {
    return _firestore
        .collection(FirebasePaths.companyUsers(companyId))
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(PlatformCompanyUserModel.fromFirestore)
              .where((user) => user.companyId == companyId)
              .toList();
        });
  }

  @override
  Stream<List<PlatformLoginActivity>> watchCompanyLoginActivity({
    required String companyId,
    int limit = 300,
  }) {
    return _firestore
        .collection('${FirebasePaths.company(companyId)}/login_activity')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(PlatformLoginActivityModel.fromFirestore)
              .where((item) => item.companyId == companyId)
              .toList();
        });
  }

  @override
  Stream<List<PlatformPaymentHistoryModel>> watchPaymentHistory({
    required String companyId,
  }) {
    return _firestore
        .collection('${FirebasePaths.company(companyId)}/payment_history')
        .orderBy('createdAt', descending: true)
        .limit(60)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(PlatformPaymentHistoryModel.fromFirestore)
              .where((item) => item.companyId == companyId)
              .toList();
        });
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
  }) async {
    await _call('createCompanyWithAdmin', {
      'companyId': companyId,
      'companyName': companyName,
      'adminFullName': adminFullName,
      'adminEmail': adminEmail,
      'adminPhone': adminPhone,
      'locale': locale,
      'timezone': timezone,
      if (trialDays != null && trialDays > 0) ...{
        'trialDurationValue': trialDays,
        'trialDurationUnit': trialDurationUnit,
        'trialDays': _legacyTrialDays(trialDays, trialDurationUnit),
      },
    });
  }

  @override
  Future<void> addUserToCompany({
    required String companyId,
    required String fullName,
    required String email,
    required String phone,
    required UserRole role,
  }) async {
    await _call('addUserToCompany', {
      'companyId': companyId,
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'role': RoleConstants.toValue(role),
    });
  }

  @override
  Future<void> setCompanyActiveStatus({
    required String companyId,
    required bool isActive,
  }) async {
    await _call('setCompanyActiveStatus', {
      'companyId': companyId,
      'isActive': isActive,
    });
  }

  @override
  Future<void> setCompanyUserActiveStatus({
    required String companyId,
    required String uid,
    required bool isActive,
  }) async {
    await _call('setCompanyUserActiveStatus', {
      'companyId': companyId,
      'uid': uid,
      'isActive': isActive,
    });
  }

  @override
  Future<void> setCompanyUserPassword({
    required String companyId,
    required String uid,
    required String newPassword,
  }) async {
    await _call('setCompanyUserPassword', {
      'companyId': companyId,
      'uid': uid,
      'newPassword': newPassword,
    });
  }

  @override
  Future<void> setCompanyUserEmail({
    required String companyId,
    required String uid,
    required String newEmail,
  }) async {
    await _call('setCompanyUserEmail', {
      'companyId': companyId,
      'uid': uid,
      'newEmail': newEmail,
    });
  }

  @override
  Future<PasswordResetLinkResult> generateCompanyUserPasswordResetLink({
    required String companyId,
    required String uid,
  }) async {
    final data = await _callMap('generateCompanyUserPasswordResetLink', {
      'companyId': companyId,
      'uid': uid,
    });
    return PasswordResetLinkResult(
      uid: data['uid'] as String? ?? '',
      companyId: data['companyId'] as String? ?? '',
      email: data['email'] as String? ?? '',
      passwordResetLink: data['passwordResetLink'] as String? ?? '',
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
  }) async {
    await _call('updateCompanyPlatformSettings', {
      'companyId': companyId,
      if (name != null) 'name': name,
      if (displayName != null) 'displayName': displayName,
      if (status != null) 'status': status,
      if (isActive != null) 'isActive': isActive,
      if (settings != null) 'settings': settings,
      if (limits != null) 'limits': limits,
      if (features != null) 'features': features,
      if (trialEndsAt != null) 'trialEndsAt': trialEndsAt.toUtc().toIso8601String(),
      if (trialDurationValue != null) 'trialDurationValue': trialDurationValue,
      if (trialDurationUnit != null) 'trialDurationUnit': trialDurationUnit,
    });
  }

  @override
  Future<CompanyDataHealthReportModel> getCompanyDataHealthReport({
    required String companyId,
  }) async {
    final data = await _callMap('getCompanyDataHealthReport', {
      'companyId': companyId,
    });
    return CompanyDataHealthReportModel.fromMap(data);
  }

  @override
  Future<void> backfillAssignedRecordSnapshots({
    required String companyId,
    required String module,
    required String recordId,
  }) async {
    await _call('backfillAssignedRecordSnapshots', {
      'companyId': companyId,
      'module': module,
      'recordId': recordId,
    });
  }

  @override
  Future<void> refreshCompanyStorageUsage({required String companyId}) async {
    await _call('refreshCompanyStorageUsage', {'companyId': companyId});
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
  }) async {
    await _call('markCompanyPaymentPaid', {
      'companyId': companyId,
      'amount': amount,
      'currency': currency,
      'paymentDate': paymentDate.toUtc().toIso8601String(),
      'nextPaymentDueAt': nextPaymentDueAt.toUtc().toIso8601String(),
      'paymentCycle': paymentCycle,
      'notes': notes,
    });
  }

  @override
  Future<void> extendCompanyPaymentDueDate({
    required String companyId,
    required DateTime nextPaymentDueAt,
    required String notes,
  }) async {
    await _call('extendCompanyPaymentDueDate', {
      'companyId': companyId,
      'nextPaymentDueAt': nextPaymentDueAt.toUtc().toIso8601String(),
      'notes': notes,
    });
  }

  @override
  Future<void> updateCompanyPaymentStatus({
    required String companyId,
    required String paymentStatus,
    DateTime? nextPaymentDueAt,
    DateTime? gracePeriodEndsAt,
    String? suspendedReason,
    String? notes,
  }) async {
    await _call('updateCompanyPaymentStatus', {
      'companyId': companyId,
      'paymentStatus': paymentStatus,
      if (nextPaymentDueAt != null)
        'nextPaymentDueAt': nextPaymentDueAt.toUtc().toIso8601String(),
      if (gracePeriodEndsAt != null)
        'gracePeriodEndsAt': gracePeriodEndsAt.toUtc().toIso8601String(),
      if (suspendedReason != null) 'suspendedReason': suspendedReason,
      if (notes != null) 'notes': notes,
    });
  }

  @override
  Future<Map<String, dynamic>> exportCompanyData({
    required String companyId,
    List<String>? collections,
  }) {
    return _callMap('exportCompanyDataForPlatform', {
      'companyId': companyId,
      if (collections != null && collections.isNotEmpty) 'collections': collections,
    });
  }

  @override
  Future<AndroidReleasePolicy> getAndroidReleasePolicy() async {
    final data = await _callMap('getAndroidReleasePolicy', {
      'appVersion': AppConstants.appVersion,
      'buildNumber': AppConstants.appBuildNumber,
      'platform': 'android',
    });
    return _androidReleasePolicyFromMap(data);
  }

  @override
  Future<AndroidVersionAdoptionSummary> getAndroidVersionAdoption({
    String? companyId,
  }) async {
    final normalizedCompanyId = companyId?.trim();
    final data = await _callMap('getAndroidVersionAdoption', {
      'platform': 'android',
      if (normalizedCompanyId != null && normalizedCompanyId.isNotEmpty)
        'companyId': normalizedCompanyId,
    });
    return _androidVersionAdoptionFromMap(data);
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
  }) async {
    await _call('updateAndroidReleasePolicy', {
      'enabled': enabled,
      'releaseReady': releaseReady,
      'appVersion': AppConstants.appVersion,
      'buildNumber': AppConstants.appBuildNumber,
      'minimumSupportedBuildNumber': minimumSupportedBuildNumber,
      'latestBuildNumber': latestBuildNumber,
      'updateUrl': updateUrl,
      'titleEn': titleEn,
      'titleAr': titleAr,
      'bodyEn': bodyEn,
      'bodyAr': bodyAr,
    });
  }

  @override
  Future<ReleaseIntelligenceSummary> getReleaseIntelligenceSummary({
    int activeWithinDays = 30,
  }) async {
    final data = await _callMap('getReleaseIntelligenceSummary', {
      'activeWithinDays': activeWithinDays,
    });
    return _releaseIntelligenceSummaryFromMap(data);
  }

  @override
  Future<List<VersionAdoptionRow>> getPlatformVersionAdoption({
    String platform = 'all',
    String? companyId,
    int activeWithinDays = 30,
    bool includeInactive = false,
  }) async {
    final data = await _callMap('getPlatformVersionAdoption', {
      'platform': platform,
      if (companyId != null && companyId.trim().isNotEmpty)
        'companyId': companyId.trim(),
      'activeWithinDays': activeWithinDays,
      'includeInactive': includeInactive,
    });
    return _adoptionRows(data['rows']);
  }

  @override
  Future<List<PlatformDeviceInstallRow>> getPlatformDeviceList({
    String platform = 'all',
    String? companyId,
    int activeWithinDays = 30,
    int limit = 120,
  }) async {
    final data = await _callMap('getPlatformDeviceList', {
      'platform': platform,
      if (companyId != null && companyId.trim().isNotEmpty)
        'companyId': companyId.trim(),
      'activeWithinDays': activeWithinDays,
      'limit': limit,
    });
    return _deviceRows(data['rows']);
  }

  @override
  Future<List<DeviceVersionEventRow>> getPlatformVersionHistory({
    String platform = 'all',
    String? companyId,
    int limit = 120,
  }) async {
    final data = await _callMap('getPlatformVersionHistory', {
      'platform': platform,
      if (companyId != null && companyId.trim().isNotEmpty)
        'companyId': companyId.trim(),
      'limit': limit,
    });
    return _versionEventRows(data['rows']);
  }

  @override
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
  }) async {
    await _call('createPlatformReleaseRecord', {
      'platform': platform,
      'appVersion': appVersion,
      'buildNumber': buildNumber,
      'minimumSupportedBuildNumber': minimumSupportedBuildNumber,
      'latestBuildNumber': latestBuildNumber,
      'updateUrl': updateUrl,
      'enabled': enabled,
      'releaseReady': releaseReady,
      'status': status,
      'channel': 'production',
      'releaseType': 'patch',
    });
  }

  Future<void> _call(String name, Map<String, Object?> data) async {
    await _callMap(name, data);
  }

  Future<Map<String, dynamic>> _callMap(
    String name,
    Map<String, Object?> data,
  ) async {
    try {
      final result = await _functions.httpsCallable(name).call(data);
      final value = result.data;
      if (value is Map) {
        return Map<String, dynamic>.from(value);
      }
      return const {};
    } on FirebaseFunctionsException catch (error) {
      throw Exception(error.message ?? AppErrorMessages.permissionDenied);
    } on FirebaseException catch (error) {
      throw Exception(_mapFirebaseError(error));
    }
  }
}


AndroidReleasePolicy _androidReleasePolicyFromMap(Map<String, dynamic> data) {
  return AndroidReleasePolicy(
    enabled: data['enabled'] == true,
    releaseReady: data['releaseReady'] == true,
    updateRequired: data['updateRequired'] == true,
    updateAvailable: data['updateAvailable'] == true,
    currentBuildNumber: _intValue(data['currentBuildNumber']),
    minimumSupportedBuildNumber: _intValue(data['minimumSupportedBuildNumber']),
    latestBuildNumber: _intValue(data['latestBuildNumber']),
    updateUrl: (data['updateUrl'] as String? ?? '').trim(),
    latestVersionName: (data['latestVersionName'] as String? ??
            data['latestVersion'] as String? ??
            data['appVersion'] as String? ??
            '')
        .trim(),
    serverTime: _dateValue(data['serverTime']) ?? DateTime.now(),
    gracePeriodStartedAt: _dateValue(data['gracePeriodStartedAt']),
    gracePeriodEndsAt: _dateValue(data['gracePeriodEndsAt']),
    titleEn: data['titleEn'] as String? ?? '',
    titleAr: data['titleAr'] as String? ?? '',
    bodyEn: data['bodyEn'] as String? ?? '',
    bodyAr: data['bodyAr'] as String? ?? '',
  );
}

int _intValue(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

DateTime? _dateValue(Object? value) {
  if (value is String && value.trim().isNotEmpty) {
    return DateTime.tryParse(value)?.toLocal();
  }
  return null;
}

String _mapFirebaseError(FirebaseException error) {
  switch (error.code) {
    case 'unavailable':
    case 'network-request-failed':
    case 'deadline-exceeded':
      return AppErrorMessages.unableToConnect;
    case 'permission-denied':
    case 'unauthenticated':
      return AppErrorMessages.permissionDenied;
    default:
      return AppErrorMessages.unknown;
  }
}

int _legacyTrialDays(int value, String unit) {
  final normalized = unit.trim().toLowerCase();
  if (normalized == 'minutes') {
    return (value / (60 * 24)).ceil().clamp(1, 3650).toInt();
  }
  if (normalized == 'hours') {
    return (value / 24).ceil().clamp(1, 3650).toInt();
  }
  return value;
}

AndroidVersionAdoptionSummary _androidVersionAdoptionFromMap(
  Map<String, dynamic> data,
) {
  // The Cloud Function has returned this optional dashboard payload in more
  // than one shape while the release-management screen evolved. Keep the
  // parser tolerant so valid Android token data never appears empty just
  // because the backend used `rows/active*` instead of `versions/*Count`.
  final rawVersions = data['versions'] ?? data['rows'];
  final versions = rawVersions is List
      ? rawVersions
          .whereType<Map>()
          .map((item) {
            final userCount = _intValue(
              item['userCount'] ?? item['activeUsers'] ?? item['totalActiveUsers'],
            );
            final deviceCount = _intValue(
              item['deviceCount'] ??
                  item['activeDevices'] ??
                  item['totalActiveDevices'],
            );
            final companyCount = _intValue(
              item['companyCount'] ??
                  item['activeCompanies'] ??
                  item['totalActiveCompanies'],
            );
            return AndroidVersionAdoption(
              appVersion: (item['appVersion'] as String? ?? '').trim(),
              buildNumber: _intValue(item['buildNumber']),
              userCount: userCount,
              deviceCount: deviceCount,
              companyCount: companyCount,
              latestSeenAt: _dateValue(item['latestSeenAt']),
            );
          })
          .toList()
      : const <AndroidVersionAdoption>[];

  final computedUsers = versions.fold<int>(
    0,
    (total, version) => total + version.userCount,
  );
  final computedDevices = versions.fold<int>(
    0,
    (total, version) => total + version.deviceCount,
  );
  final parsedUsers = _intValue(data['totalActiveUsers'] ?? data['activeUsers']);
  final parsedDevices = _intValue(
    data['totalActiveDevices'] ?? data['activeDevices'],
  );

  return AndroidVersionAdoptionSummary(
    versions: versions,
    totalActiveUsers: parsedUsers == 0 ? computedUsers : parsedUsers,
    totalActiveDevices: parsedDevices == 0 ? computedDevices : parsedDevices,
  );
}

ReleaseIntelligenceSummary _releaseIntelligenceSummaryFromMap(
  Map<String, dynamic> data,
) {
  final push = data['pushHealth'] is Map
      ? Map<String, dynamic>.from(data['pushHealth'] as Map)
      : const <String, dynamic>{};
  return ReleaseIntelligenceSummary(
    activeUsers: _intValue(data['activeUsers']),
    activeDevices: _intValue(data['activeDevices']),
    activeWebUsers: _intValue(data['activeWebUsers']),
    activeWebDevices: _intValue(data['activeWebDevices']),
    activeAndroidUsers: _intValue(data['activeAndroidUsers']),
    activeAndroidDevices: _intValue(data['activeAndroidDevices']),
    usersBelowLatestBuild: _intValue(data['usersBelowLatestBuild']),
    devicesBelowLatestBuild: _intValue(data['devicesBelowLatestBuild']),
    usersBelowMinimumBuild: _intValue(data['usersBelowMinimumBuild']),
    devicesBelowMinimumBuild: _intValue(data['devicesBelowMinimumBuild']),
    pushConnected: _intValue(push['connected']),
    pushBlocked: _intValue(push['blocked']),
    pushMissing: _intValue(push['missing']),
    pushInvalidFailed: _intValue(push['invalidFailed']),
    pushUnknown: _intValue(push['unknown']),
    latestWebRelease: _releaseRecordOrNull(data['latestWebRelease']),
    latestAndroidRelease: _releaseRecordOrNull(data['latestAndroidRelease']),
    releases: _releaseRows(data['releases']),
    adoptionRows: _adoptionRows(data['adoptionRows']),
    recentVersionChanges: _versionEventRows(data['recentVersionChanges']),
    lastUpdated: _dateValue(data['lastUpdated']),
  );
}

PlatformReleaseRecord? _releaseRecordOrNull(Object? value) {
  if (value is! Map) return null;
  return _releaseRecord(Map<String, dynamic>.from(value));
}

List<PlatformReleaseRecord> _releaseRows(Object? value) {
  if (value is! List) return const [];
  return value
      .whereType<Map>()
      .map((item) => _releaseRecord(Map<String, dynamic>.from(item)))
      .toList();
}

PlatformReleaseRecord _releaseRecord(Map<String, dynamic> data) {
  return PlatformReleaseRecord(
    id: data['id'] as String? ?? '',
    platform: data['platform'] as String? ?? '',
    appVersion: data['appVersion'] as String? ?? '',
    buildNumber: _intValue(data['buildNumber']),
    channel: data['channel'] as String? ?? '',
    releaseType: data['releaseType'] as String? ?? '',
    status: data['status'] as String? ?? '',
    releaseReady: data['releaseReady'] == true,
    enabled: data['enabled'] == true,
    minimumSupportedBuildNumber: _intValue(data['minimumSupportedBuildNumber']),
    latestBuildNumber: _intValue(data['latestBuildNumber']),
    updateUrl: data['updateUrl'] as String? ?? '',
    apkFileName: data['apkFileName'] as String? ?? '',
    notesEn: data['notesEn'] as String? ?? '',
    notesAr: data['notesAr'] as String? ?? '',
    createdByName: data['createdByName'] as String? ?? '',
    createdAt: _dateValue(data['createdAt']),
    updatedAt: _dateValue(data['updatedAt']),
    releasedAt: _dateValue(data['releasedAt']),
    disabledAt: _dateValue(data['disabledAt']),
  );
}

List<VersionAdoptionRow> _adoptionRows(Object? value) {
  if (value is! List) return const [];
  return value.whereType<Map>().map((item) {
    final data = Map<String, dynamic>.from(item);
    return VersionAdoptionRow(
      platform: data['platform'] as String? ?? '',
      appVersion: data['appVersion'] as String? ?? '',
      buildNumber: _intValue(data['buildNumber']),
      activeUsers: _intValue(data['activeUsers']),
      activeDevices: _intValue(data['activeDevices']),
      activeCompanies: _intValue(data['activeCompanies']),
      status: data['status'] as String? ?? '',
      latestSeenAt: _dateValue(data['latestSeenAt']),
    );
  }).toList();
}

List<PlatformDeviceInstallRow> _deviceRows(Object? value) {
  if (value is! List) return const [];
  return value.whereType<Map>().map((item) {
    final data = Map<String, dynamic>.from(item);
    return PlatformDeviceInstallRow(
      installId: data['installId'] as String? ?? '',
      uid: data['uid'] as String? ?? '',
      companyId: data['companyId'] as String? ?? '',
      companyName: data['companyName'] as String? ?? '',
      fullName: data['fullName'] as String? ?? '',
      email: data['email'] as String? ?? '',
      role: data['role'] as String? ?? '',
      platform: data['platform'] as String? ?? '',
      appVersion: data['appVersion'] as String? ?? '',
      buildNumber: _intValue(data['buildNumber']),
      notificationPermission: data['notificationPermission'] as String? ?? '',
      notificationTokenStatus:
          data['notificationTokenStatus'] as String? ?? '',
      browser: data['browser'] as String? ?? '',
      os: data['os'] as String? ?? '',
      deviceModel: data['deviceModel'] as String? ?? '',
      tokenHashPrefix: data['tokenHashPrefix'] as String? ?? '',
      lastSeenAt: _dateValue(data['lastSeenAt']),
    );
  }).toList();
}

List<DeviceVersionEventRow> _versionEventRows(Object? value) {
  if (value is! List) return const [];
  return value.whereType<Map>().map((item) {
    final data = Map<String, dynamic>.from(item);
    return DeviceVersionEventRow(
      eventId: data['eventId'] as String? ?? '',
      uid: data['uid'] as String? ?? '',
      companyId: data['companyId'] as String? ?? '',
      companyName: data['companyName'] as String? ?? '',
      role: data['role'] as String? ?? '',
      platform: data['platform'] as String? ?? '',
      installId: data['installId'] as String? ?? '',
      userName: data['userName'] as String? ?? '',
      oldVersion: data['oldVersion'] as String? ?? '',
      oldBuildNumber: _intValue(data['oldBuildNumber']),
      newVersion: data['newVersion'] as String? ?? '',
      newBuildNumber: _intValue(data['newBuildNumber']),
      source: data['source'] as String? ?? '',
      createdAt: _dateValue(data['createdAt']),
    );
  }).toList();
}
