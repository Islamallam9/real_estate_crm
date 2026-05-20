import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/platform_notification.dart';

class PlatformNotificationModel extends PlatformNotification {
  const PlatformNotificationModel({
    required super.id,
    required super.type,
    required super.title,
    required super.message,
    required super.severity,
    required super.isRead,
    required super.createdAt,
    required super.updatedAt,
    required super.readAt,
    required super.actorId,
    required super.actorName,
    required super.actorEmail,
    required super.companyId,
    required super.companyName,
    required super.route,
    required super.metadata,
    required super.source,
  });

  factory PlatformNotificationModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    if (data == null) {
      throw StateError('Platform notification data was not found.');
    }

    return PlatformNotificationModel(
      id: data['id'] as String? ?? document.id,
      type: platformNotificationTypeFromValue(data['type'] as String? ?? ''),
      title: data['title'] as String? ?? '',
      message: data['message'] as String? ?? '',
      severity: platformNotificationSeverityFromValue(
        data['severity'] as String? ?? '',
      ),
      isRead: data['isRead'] as bool? ?? false,
      createdAt: _dateTimeFromValue(data['createdAt']),
      updatedAt: _dateTimeFromValue(data['updatedAt']),
      readAt: _dateTimeFromValue(data['readAt']),
      actorId: data['actorId'] as String? ?? '',
      actorName: data['actorName'] as String? ?? '',
      actorEmail: data['actorEmail'] as String? ?? '',
      companyId: data['companyId'] as String? ?? '',
      companyName: data['companyName'] as String? ?? '',
      route: data['route'] as String? ?? '',
      metadata: _metadataFromValue(data['metadata']),
      source: platformNotificationSourceFromValue(
        data['source'] as String? ?? '',
      ),
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
