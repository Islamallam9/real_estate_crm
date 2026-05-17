import 'package:equatable/equatable.dart';

import '../../../../core/constants/role_constants.dart';

class UserProfile extends Equatable {
  const UserProfile({
    required this.uid,
    required this.companyId,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.role,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    this.updatedBy = '',
    this.teamId = '',
    this.teamName = '',
    this.managerId = '',
    this.managerName = '',
    this.photoUrl = '',
    this.photoStoragePath = '',
    this.lastLoginAt,
    this.lastLoginIp = '',
    this.lastLoginUserAgent = '',
    this.lastLoginPlatform = '',
    this.lastLoginBrowser = '',
    this.lastLoginDeviceType = '',
    this.lastLoginLocale = '',
    this.lastLoginTimezone = '',
  });

  final String uid;
  final String companyId;
  final String fullName;
  final String email;
  final String phone;
  final UserRole role;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;
  final String updatedBy;
  final String teamId;
  final String teamName;
  final String managerId;
  final String managerName;
  final String photoUrl;
  final String photoStoragePath;
  final DateTime? lastLoginAt;
  final String lastLoginIp;
  final String lastLoginUserAgent;
  final String lastLoginPlatform;
  final String lastLoginBrowser;
  final String lastLoginDeviceType;
  final String lastLoginLocale;
  final String lastLoginTimezone;

  @override
  List<Object?> get props => [
    uid,
    companyId,
    fullName,
    email,
    phone,
    role,
    isActive,
    createdAt,
    updatedAt,
    createdBy,
    updatedBy,
    teamId,
    teamName,
    managerId,
    managerName,
    photoUrl,
    photoStoragePath,
    lastLoginAt,
    lastLoginIp,
    lastLoginUserAgent,
    lastLoginPlatform,
    lastLoginBrowser,
    lastLoginDeviceType,
    lastLoginLocale,
    lastLoginTimezone,
  ];
}
