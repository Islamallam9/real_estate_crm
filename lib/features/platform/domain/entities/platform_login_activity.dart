import 'package:equatable/equatable.dart';

class PlatformLoginActivity extends Equatable {
  const PlatformLoginActivity({
    required this.id,
    required this.uid,
    required this.companyId,
    required this.fullName,
    required this.email,
    required this.role,
    required this.createdAt,
    this.ipAddress = '',
    this.platform = '',
    this.browser = '',
    this.deviceType = '',
    this.locale = '',
    this.timezone = '',
    this.appVersion = '',
    this.authProvider = '',
  });

  final String id;
  final String uid;
  final String companyId;
  final String fullName;
  final String email;
  final String role;
  final DateTime? createdAt;
  final String ipAddress;
  final String platform;
  final String browser;
  final String deviceType;
  final String locale;
  final String timezone;
  final String appVersion;
  final String authProvider;

  @override
  List<Object?> get props => [
        id,
        uid,
        companyId,
        fullName,
        email,
        role,
        createdAt,
        ipAddress,
        platform,
        browser,
        deviceType,
        locale,
        timezone,
        appVersion,
        authProvider,
      ];
}
