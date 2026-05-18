import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/crm_notification.dart';

class CrmNotificationModel extends CrmNotification {
  const CrmNotificationModel({
    required super.id,
    required super.companyId,
    required super.recipientUid,
    required super.recipientRole,
    required super.type,
    required super.module,
    required super.recordId,
    required super.recordTitle,
    required super.recordSubtitle,
    required super.route,
    required super.actorUid,
    required super.actorName,
    required super.teamId,
    required super.teamName,
    required super.managerId,
    required super.priority,
    required super.isRead,
    required super.readAt,
    required super.createdAt,
    required super.metadata,
    super.fallbackTitle,
    super.fallbackBody,
  });

  factory CrmNotificationModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    if (data == null) {
      throw StateError('Notification data was not found.');
    }
    return CrmNotificationModel(
      id: data['id'] as String? ?? document.id,
      companyId: data['companyId'] as String? ?? '',
      recipientUid: data['recipientUid'] as String? ?? '',
      recipientRole: data['recipientRole'] as String? ?? '',
      type: notificationTypeFromValue(data['type'] as String? ?? ''),
      module: data['module'] as String? ?? '',
      recordId: data['recordId'] as String? ?? '',
      recordTitle: data['recordTitle'] as String? ?? '',
      recordSubtitle: data['recordSubtitle'] as String? ?? '',
      route: data['route'] as String? ?? '',
      actorUid: data['actorUid'] as String? ?? '',
      actorName: data['actorName'] as String? ?? '',
      teamId: data['teamId'] as String? ?? '',
      teamName: data['teamName'] as String? ?? '',
      managerId: data['managerId'] as String? ?? '',
      priority: notificationPriorityFromValue(
        data['priority'] as String? ?? '',
      ),
      isRead: data['isRead'] as bool? ?? false,
      readAt: _dateTimeFromValue(data['readAt']),
      createdAt: _dateTimeFromValue(data['createdAt']),
      metadata: _metadataFromValue(data['metadata']),
      fallbackTitle: data['fallbackTitle'] as String? ?? '',
      fallbackBody: data['fallbackBody'] as String? ?? '',
    );
  }
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

DateTime? _dateTimeFromValue(Object? value) {
  if (value is Timestamp) {
    return value.toDate();
  }
  if (value is DateTime) {
    return value;
  }
  return null;
}
