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

  Future<AndroidVersionAdoptionSummary> getAndroidVersionAdoption();

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
  Future<AndroidVersionAdoptionSummary> getAndroidVersionAdoption() async {
    final data = await _callMap('getAndroidVersionAdoption', {
      'platform': 'android',
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
      'minimumSupportedBuildNumber': minimumSupportedBuildNumber,
      'latestBuildNumber': latestBuildNumber,
      'updateUrl': updateUrl,
      'titleEn': titleEn,
      'titleAr': titleAr,
      'bodyEn': bodyEn,
      'bodyAr': bodyAr,
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
  final rawVersions = data['versions'];
  final versions = rawVersions is List
      ? rawVersions
          .whereType<Map>()
          .map((item) => AndroidVersionAdoption(
                appVersion: (item['appVersion'] as String? ?? '').trim(),
                buildNumber: _intValue(item['buildNumber']),
                userCount: _intValue(item['userCount']),
                deviceCount: _intValue(item['deviceCount']),
                companyCount: _intValue(item['companyCount']),
                latestSeenAt: _dateValue(item['latestSeenAt']),
              ))
          .toList()
      : const <AndroidVersionAdoption>[];
  return AndroidVersionAdoptionSummary(
    versions: versions,
    totalActiveUsers: _intValue(data['totalActiveUsers']),
    totalActiveDevices: _intValue(data['totalActiveDevices']),
  );
}
