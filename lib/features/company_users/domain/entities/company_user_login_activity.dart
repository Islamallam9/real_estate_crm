import 'package:equatable/equatable.dart';

class CompanyUserLoginActivity extends Equatable {
  const CompanyUserLoginActivity({
    required this.id,
    required this.uid,
    required this.companyId,
    required this.email,
    required this.role,
    required this.fullName,
    required this.createdAt,
    this.ipAddress = '',
    this.platform = '',
    this.browser = '',
    this.deviceType = '',
    this.locale = '',
    this.timezone = '',
    this.appVersion = '',
  });

  final String id;
  final String uid;
  final String companyId;
  final String email;
  final String role;
  final String fullName;
  final DateTime? createdAt;
  final String ipAddress;
  final String platform;
  final String browser;
  final String deviceType;
  final String locale;
  final String timezone;
  final String appVersion;

  @override
  List<Object?> get props => [
        id,
        uid,
        companyId,
        email,
        role,
        fullName,
        createdAt,
        ipAddress,
        platform,
        browser,
        deviceType,
        locale,
        timezone,
        appVersion,
      ];
}
