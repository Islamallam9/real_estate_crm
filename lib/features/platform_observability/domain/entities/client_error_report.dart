import 'platform_error_log.dart';

class ClientErrorReport {
  const ClientErrorReport({
    required this.source,
    required this.severity,
    required this.message,
    required this.stackHash,
    this.companyId = '',
    this.companyName = '',
    this.userId = '',
    this.userEmail = '',
    this.userRole = '',
    this.route = '',
    this.module = '',
    this.errorCode = '',
    this.shortStack = '',
    this.appVersion = '',
    this.buildNumber = '',
    this.platform = '',
    this.deviceType = '',
    this.userAgent = '',
    this.timezone = '',
    this.metadata = const {},
  });

  final String companyId;
  final String companyName;
  final String userId;
  final String userEmail;
  final String userRole;
  final String route;
  final String module;
  final PlatformErrorSource source;
  final PlatformErrorSeverity severity;
  final String message;
  final String errorCode;
  final String stackHash;
  final String shortStack;
  final String appVersion;
  final String buildNumber;
  final String platform;
  final String deviceType;
  final String userAgent;
  final String timezone;
  final Map<String, Object?> metadata;
}
