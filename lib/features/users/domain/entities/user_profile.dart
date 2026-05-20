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
    this.mustChangePassword = false,
    this.passwordSetupMethod = '',
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
  final bool mustChangePassword;
  final String passwordSetupMethod;

  UserProfile copyWith({
    String? uid,
    String? companyId,
    String? fullName,
    String? email,
    String? phone,
    UserRole? role,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
    String? teamId,
    String? teamName,
    String? managerId,
    String? managerName,
    String? photoUrl,
    String? photoStoragePath,
    DateTime? lastLoginAt,
    String? lastLoginIp,
    String? lastLoginUserAgent,
    String? lastLoginPlatform,
    String? lastLoginBrowser,
    String? lastLoginDeviceType,
    String? lastLoginLocale,
    String? lastLoginTimezone,
    bool? mustChangePassword,
    String? passwordSetupMethod,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      companyId: companyId ?? this.companyId,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      teamId: teamId ?? this.teamId,
      teamName: teamName ?? this.teamName,
      managerId: managerId ?? this.managerId,
      managerName: managerName ?? this.managerName,
      photoUrl: photoUrl ?? this.photoUrl,
      photoStoragePath: photoStoragePath ?? this.photoStoragePath,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      lastLoginIp: lastLoginIp ?? this.lastLoginIp,
      lastLoginUserAgent: lastLoginUserAgent ?? this.lastLoginUserAgent,
      lastLoginPlatform: lastLoginPlatform ?? this.lastLoginPlatform,
      lastLoginBrowser: lastLoginBrowser ?? this.lastLoginBrowser,
      lastLoginDeviceType: lastLoginDeviceType ?? this.lastLoginDeviceType,
      lastLoginLocale: lastLoginLocale ?? this.lastLoginLocale,
      lastLoginTimezone: lastLoginTimezone ?? this.lastLoginTimezone,
      mustChangePassword: mustChangePassword ?? this.mustChangePassword,
      passwordSetupMethod: passwordSetupMethod ?? this.passwordSetupMethod,
    );
  }

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
    mustChangePassword,
    passwordSetupMethod,
  ];
}
