import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/platform_error_log.dart';

class PlatformErrorLogModel extends PlatformErrorLog {
  const PlatformErrorLogModel({
    required super.id,
    required super.companyId,
    required super.companyName,
    required super.userId,
    required super.userEmail,
    required super.userRole,
    required super.route,
    required super.module,
    required super.source,
    required super.severity,
    required super.message,
    required super.errorCode,
    required super.stackHash,
    required super.shortStack,
    required super.occurrenceCount,
    required super.firstSeenAt,
    required super.lastSeenAt,
    required super.createdAt,
    required super.appVersion,
    required super.buildNumber,
    required super.platform,
    required super.deviceType,
    required super.userAgent,
    required super.timezone,
    required super.resolved,
    required super.resolvedBy,
    required super.resolvedByEmail,
    required super.resolvedAt,
    required super.ownerNotified,
    required super.metadata,
  });

  factory PlatformErrorLogModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? const <String, dynamic>{};
    return PlatformErrorLogModel.fromMap(data, fallbackId: document.id);
  }

  factory PlatformErrorLogModel.fromMap(
    Map<String, dynamic> data, {
    String fallbackId = '',
  }) {
    return PlatformErrorLogModel(
      id: data['id'] as String? ?? fallbackId,
      companyId: data['companyId'] as String? ?? '',
      companyName: data['companyName'] as String? ?? '',
      userId: data['userId'] as String? ?? '',
      userEmail: data['userEmail'] as String? ?? '',
      userRole: data['userRole'] as String? ?? '',
      route: data['route'] as String? ?? '',
      module: data['module'] as String? ?? '',
      source: platformErrorSourceFromValue(data['source'] as String? ?? ''),
      severity: platformErrorSeverityFromValue(
        data['severity'] as String? ?? '',
      ),
      message: data['message'] as String? ?? '',
      errorCode: data['errorCode'] as String? ?? '',
      stackHash: data['stackHash'] as String? ?? '',
      shortStack: data['shortStack'] as String? ?? '',
      occurrenceCount: (data['occurrenceCount'] as num?)?.toInt() ?? 0,
      firstSeenAt: _dateTimeFromValue(data['firstSeenAt']),
      lastSeenAt: _dateTimeFromValue(data['lastSeenAt']),
      createdAt: _dateTimeFromValue(data['createdAt']),
      appVersion: data['appVersion'] as String? ?? '',
      buildNumber: data['buildNumber'] as String? ?? '',
      platform: data['platform'] as String? ?? '',
      deviceType: data['deviceType'] as String? ?? '',
      userAgent: data['userAgent'] as String? ?? '',
      timezone: data['timezone'] as String? ?? '',
      resolved: data['resolved'] as bool? ?? false,
      resolvedBy: data['resolvedBy'] as String? ?? '',
      resolvedByEmail: data['resolvedByEmail'] as String? ?? '',
      resolvedAt: _dateTimeFromValue(data['resolvedAt']),
      ownerNotified: data['ownerNotified'] as bool? ?? false,
      metadata: _metadataFromValue(data['metadata']),
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
  if (value is String) {
    return DateTime.tryParse(value);
  }
  return null;
}

Map<String, Object?> _metadataFromValue(Object? value) {
  if (value is Map<String, dynamic>) {
    return Map<String, Object?>.from(value);
  }
  if (value is Map) {
    return value.map((key, entry) => MapEntry(key.toString(), entry));
  }
  return const {};
}
