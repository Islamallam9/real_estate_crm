import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/role_constants.dart';
import '../../domain/entities/user_profile.dart';

class UserProfileModel extends UserProfile {
  const UserProfileModel({
    required super.uid,
    required super.companyId,
    required super.fullName,
    required super.email,
    required super.phone,
    required super.role,
    required super.isActive,
    required super.createdAt,
    required super.updatedAt,
    required super.createdBy,
    super.updatedBy,
    super.teamId,
    super.teamName,
    super.managerId,
    super.managerName,
    super.photoUrl,
    super.photoStoragePath,
    super.lastLoginAt,
    super.lastLoginIp,
    super.lastLoginUserAgent,
    super.lastLoginPlatform,
    super.lastLoginBrowser,
    super.lastLoginDeviceType,
    super.lastLoginLocale,
    super.lastLoginTimezone,
    super.mustChangePassword,
    super.passwordSetupMethod,
  });

  factory UserProfileModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    if (data == null) {
      throw StateError('User profile data was not found.');
    }

    return UserProfileModel(
      uid: data['uid'] as String? ?? document.id,
      companyId: data['companyId'] as String? ?? '',
      fullName: data['fullName'] as String? ?? '',
      email: data['email'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      role: RoleConstants.fromValue(data['role'] as String? ?? ''),
      isActive: data['isActive'] as bool? ?? false,
      createdAt: _dateTimeFromValue(data['createdAt']),
      updatedAt: _dateTimeFromValue(data['updatedAt']),
      createdBy: data['createdBy'] as String? ?? '',
      updatedBy: data['updatedBy'] as String? ?? '',
      teamId: data['teamId'] as String? ?? '',
      teamName: data['teamName'] as String? ?? '',
      managerId: data['managerId'] as String? ?? '',
      managerName: data['managerName'] as String? ?? '',
      photoUrl: data['photoUrl'] as String? ?? '',
      photoStoragePath: data['photoStoragePath'] as String? ?? '',
      lastLoginAt: _nullableDateTimeFromValue(data['lastLoginAt']),
      lastLoginIp: data['lastLoginIp'] as String? ?? '',
      lastLoginUserAgent: data['lastLoginUserAgent'] as String? ?? '',
      lastLoginPlatform: data['lastLoginPlatform'] as String? ?? '',
      lastLoginBrowser: data['lastLoginBrowser'] as String? ?? '',
      lastLoginDeviceType: data['lastLoginDeviceType'] as String? ?? '',
      lastLoginLocale: data['lastLoginLocale'] as String? ?? '',
      lastLoginTimezone: data['lastLoginTimezone'] as String? ?? '',
      mustChangePassword: data['mustChangePassword'] as bool? ?? false,
      passwordSetupMethod: data['passwordSetupMethod'] as String? ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'companyId': companyId,
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'role': RoleConstants.toValue(role),
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'createdBy': createdBy,
      'updatedBy': updatedBy,
      'teamId': teamId,
      'teamName': teamName,
      'managerId': managerId,
      'managerName': managerName,
      'photoUrl': photoUrl,
      'photoStoragePath': photoStoragePath,
      if (lastLoginAt != null)
        'lastLoginAt': Timestamp.fromDate(lastLoginAt!),
      'lastLoginIp': lastLoginIp,
      'lastLoginUserAgent': lastLoginUserAgent,
      'lastLoginPlatform': lastLoginPlatform,
      'lastLoginBrowser': lastLoginBrowser,
      'lastLoginDeviceType': lastLoginDeviceType,
      'lastLoginLocale': lastLoginLocale,
      'lastLoginTimezone': lastLoginTimezone,
      'mustChangePassword': mustChangePassword,
      'passwordSetupMethod': passwordSetupMethod,
    };
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
