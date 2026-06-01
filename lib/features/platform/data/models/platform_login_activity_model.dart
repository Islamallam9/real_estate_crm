import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/platform_login_activity.dart';

class PlatformLoginActivityModel extends PlatformLoginActivity {
  const PlatformLoginActivityModel({
    required super.id,
    required super.uid,
    required super.companyId,
    required super.fullName,
    required super.email,
    required super.role,
    required super.createdAt,
    super.ipAddress,
    super.platform,
    super.browser,
    super.deviceType,
    super.locale,
    super.timezone,
    super.appVersion,
    super.authProvider,
  });

  factory PlatformLoginActivityModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const <String, dynamic>{};
    return PlatformLoginActivityModel(
      id: data['id'] as String? ?? doc.id,
      uid: data['uid'] as String? ?? '',
      companyId: data['companyId'] as String? ?? '',
      fullName: data['fullName'] as String? ?? '',
      email: data['email'] as String? ?? '',
      role: data['role'] as String? ?? '',
      createdAt: _dateTimeFromValue(data['createdAt']),
      ipAddress: data['ipAddress'] as String? ?? '',
      platform: data['platform'] as String? ?? '',
      browser: data['browser'] as String? ?? '',
      deviceType: data['deviceType'] as String? ?? '',
      locale: data['locale'] as String? ?? '',
      timezone: data['timezone'] as String? ?? '',
      appVersion: data['appVersion'] as String? ?? '',
      authProvider: data['authProvider'] as String? ?? '',
    );
  }
}

DateTime? _dateTimeFromValue(Object? value) {
  if (value is Timestamp) {
    return value.toDate();
  }
  if (value is DateTime) {
    return value;
  }
  return null;
}
