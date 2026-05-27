import 'package:equatable/equatable.dart';

enum PlatformErrorSource {
  flutterWeb,
  flutterMobile,
  cloudFunction,
  firestoreRule,
  storage,
  unknown,
}

enum PlatformErrorSeverity { info, warning, error, fatal }

class PlatformErrorLog extends Equatable {
  const PlatformErrorLog({
    required this.id,
    required this.companyId,
    required this.companyName,
    required this.userId,
    required this.userEmail,
    required this.userRole,
    required this.route,
    required this.module,
    required this.source,
    required this.severity,
    required this.message,
    required this.errorCode,
    required this.stackHash,
    required this.shortStack,
    required this.occurrenceCount,
    required this.firstSeenAt,
    required this.lastSeenAt,
    required this.createdAt,
    required this.appVersion,
    required this.buildNumber,
    required this.platform,
    required this.deviceType,
    required this.userAgent,
    required this.timezone,
    required this.resolved,
    required this.resolvedBy,
    required this.resolvedByEmail,
    required this.resolvedAt,
    required this.ownerNotified,
    required this.metadata,
  });

  final String id;
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
  final int occurrenceCount;
  final DateTime? firstSeenAt;
  final DateTime? lastSeenAt;
  final DateTime? createdAt;
  final String appVersion;
  final String buildNumber;
  final String platform;
  final String deviceType;
  final String userAgent;
  final String timezone;
  final bool resolved;
  final String resolvedBy;
  final String resolvedByEmail;
  final DateTime? resolvedAt;
  final bool ownerNotified;
  final Map<String, Object?> metadata;

  @override
  List<Object?> get props => [
        id,
        companyId,
        companyName,
        userId,
        userEmail,
        userRole,
        route,
        module,
        source,
        severity,
        message,
        errorCode,
        stackHash,
        shortStack,
        occurrenceCount,
        firstSeenAt,
        lastSeenAt,
        createdAt,
        appVersion,
        buildNumber,
        platform,
        deviceType,
        userAgent,
        timezone,
        resolved,
        resolvedBy,
        resolvedByEmail,
        resolvedAt,
        ownerNotified,
        metadata,
      ];
}

PlatformErrorSource platformErrorSourceFromValue(String value) {
  return switch (value) {
    'flutter_web' => PlatformErrorSource.flutterWeb,
    'flutter_mobile' => PlatformErrorSource.flutterMobile,
    'cloud_function' => PlatformErrorSource.cloudFunction,
    'firestore_rule' => PlatformErrorSource.firestoreRule,
    'storage' => PlatformErrorSource.storage,
    _ => PlatformErrorSource.unknown,
  };
}

String platformErrorSourceValue(PlatformErrorSource source) {
  return switch (source) {
    PlatformErrorSource.flutterWeb => 'flutter_web',
    PlatformErrorSource.flutterMobile => 'flutter_mobile',
    PlatformErrorSource.cloudFunction => 'cloud_function',
    PlatformErrorSource.firestoreRule => 'firestore_rule',
    PlatformErrorSource.storage => 'storage',
    PlatformErrorSource.unknown => 'unknown',
  };
}

PlatformErrorSeverity platformErrorSeverityFromValue(String value) {
  return switch (value) {
    'info' => PlatformErrorSeverity.info,
    'warning' => PlatformErrorSeverity.warning,
    'fatal' => PlatformErrorSeverity.fatal,
    _ => PlatformErrorSeverity.error,
  };
}

String platformErrorSeverityValue(PlatformErrorSeverity severity) {
  return switch (severity) {
    PlatformErrorSeverity.info => 'info',
    PlatformErrorSeverity.warning => 'warning',
    PlatformErrorSeverity.error => 'error',
    PlatformErrorSeverity.fatal => 'fatal',
  };
}
