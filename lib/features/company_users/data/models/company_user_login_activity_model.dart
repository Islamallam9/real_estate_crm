import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/company_user_login_activity.dart';

class CompanyUserLoginActivityModel extends CompanyUserLoginActivity {
  const CompanyUserLoginActivityModel({
    required super.id,
    required super.uid,
    required super.companyId,
    required super.email,
    required super.role,
    required super.fullName,
    required super.createdAt,
    super.ipAddress,
    super.platform,
    super.browser,
    super.deviceType,
    super.locale,
    super.timezone,
    super.appVersion,
  });

  factory CompanyUserLoginActivityModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const <String, dynamic>{};
    return CompanyUserLoginActivityModel(
      id: data['id'] as String? ?? doc.id,
      uid: data['uid'] as String? ?? '',
      companyId: data['companyId'] as String? ?? '',
      email: data['email'] as String? ?? '',
      role: data['role'] as String? ?? '',
      fullName: data['fullName'] as String? ?? '',
      createdAt: _nullableDateTimeFromValue(
        data['createdAt'] ?? data['loginAt'],
      ),
      ipAddress: data['ipAddress'] as String? ?? '',
      platform: data['platform'] as String? ?? '',
      browser: data['browser'] as String? ?? '',
      deviceType: data['deviceType'] as String? ?? '',
      locale: data['locale'] as String? ?? '',
      timezone: data['timezone'] as String? ?? '',
      appVersion: data['appVersion'] as String? ?? '',
    );
  }
}

DateTime? _nullableDateTimeFromValue(Object? value) {
  if (value is Timestamp) {
    return value.toDate();
  }
  if (value is DateTime) {
    return value;
  }
  return null;
}
