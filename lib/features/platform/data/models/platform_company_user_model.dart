import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/role_constants.dart';
import '../../domain/entities/platform_company_user.dart';

class PlatformCompanyUserModel extends PlatformCompanyUser {
  const PlatformCompanyUserModel({
    required super.uid,
    required super.companyId,
    required super.fullName,
    required super.email,
    required super.phone,
    required super.role,
    required super.isActive,
    required super.createdAt,
    required super.createdBy,
    required super.updatedAt,
    required super.updatedBy,
    super.lastLoginAt,
    super.lastLoginIp,
    super.lastLoginUserAgent,
    super.lastLoginPlatform,
    super.lastLoginBrowser,
    super.lastLoginDeviceType,
    super.lastLoginLocale,
    super.lastLoginTimezone,
  });

  factory PlatformCompanyUserModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    if (data == null) {
      throw StateError('Company user data was not found.');
    }

    return PlatformCompanyUserModel(
      uid: data['uid'] as String? ?? document.id,
      companyId: data['companyId'] as String? ?? '',
      fullName: data['fullName'] as String? ?? '',
      email: data['email'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      role: RoleConstants.fromValue(data['role'] as String? ?? ''),
      isActive: data['isActive'] as bool? ?? false,
      createdAt: _dateTimeFromValue(data['createdAt']),
      createdBy: data['createdBy'] as String? ?? '',
      updatedAt: _dateTimeFromValue(data['updatedAt']),
      updatedBy: data['updatedBy'] as String? ?? '',
      lastLoginAt: _nullableDateTimeFromValue(data['lastLoginAt']),
      lastLoginIp: data['lastLoginIp'] as String? ?? '',
      lastLoginUserAgent: data['lastLoginUserAgent'] as String? ?? '',
      lastLoginPlatform: data['lastLoginPlatform'] as String? ?? '',
      lastLoginBrowser: data['lastLoginBrowser'] as String? ?? '',
      lastLoginDeviceType: data['lastLoginDeviceType'] as String? ?? '',
      lastLoginLocale: data['lastLoginLocale'] as String? ?? '',
      lastLoginTimezone: data['lastLoginTimezone'] as String? ?? '',
    );
  }
}

DateTime? _nullableDateTimeFromValue(Object? value) {
  if (value == null) {
    return null;
  }
  return _dateTimeFromValue(value);
}

DateTime _dateTimeFromValue(Object? value) {
  if (value is Timestamp) {
    return value.toDate();
  }

  if (value is DateTime) {
    return value;
  }

  return DateTime.fromMillisecondsSinceEpoch(0);
}
