import 'package:cloud_functions/cloud_functions.dart';

import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/android_release_policy.dart';

class AppUpdateRemoteDataSource {
  AppUpdateRemoteDataSource({FirebaseFunctions? functions})
      : _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFunctions _functions;

  Future<AndroidReleasePolicy> getAndroidReleasePolicy() async {
    final response = await _functions.httpsCallable('getAndroidReleasePolicy').call({
      'appVersion': AppConstants.appVersion,
      'buildNumber': AppConstants.appBuildNumber,
      'platform': 'android',
    });
    final data = Map<String, dynamic>.from(response.data as Map);
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
}
