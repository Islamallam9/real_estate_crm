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
    required super.deliveryMode,
    required super.recipientScope,
    required super.dedupeKey,
    required super.isRead,
    required super.readAt,
    required super.createdAt,
    required super.actionState,
    required super.resolvedAt,
    required super.dismissedAt,
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
      id: _stringFromValue(data['id'], fallback: document.id),
      companyId: _stringFromValue(data['companyId']),
      recipientUid: _stringFromValue(data['recipientUid']),
      recipientRole: _stringFromValue(data['recipientRole']),
      type: notificationTypeFromValue(_stringFromValue(data['type'])),
      module: _stringFromValue(data['module']),
      recordId: _stringFromValue(data['recordId']),
      recordTitle: _stringFromValue(data['recordTitle']),
      recordSubtitle: _stringFromValue(data['recordSubtitle']),
      route: _stringFromValue(data['route']),
      actorUid: _stringFromValue(data['actorUid']),
      actorName: _stringFromValue(data['actorName']),
      teamId: _stringFromValue(data['teamId']),
      teamName: _stringFromValue(data['teamName']),
      managerId: _stringFromValue(data['managerId']),
      priority: notificationPriorityFromValue(
        _stringFromValue(data['priority']),
      ),
      deliveryMode: notificationDeliveryModeFromValue(
        _stringFromValue(data['deliveryMode']),
      ),
      recipientScope: notificationRecipientScopeFromValue(
        _stringFromValue(data['recipientScope']),
      ),
      dedupeKey: _stringFromValue(data['dedupeKey']),
      isRead: data['isRead'] as bool? ?? false,
      readAt: _dateTimeFromValue(data['readAt']),
      createdAt: _dateTimeFromValue(data['createdAt']),
      actionState: _actionStateFromData(data),
      resolvedAt: _dateTimeFromValue(data['resolvedAt']),
      dismissedAt: _dateTimeFromValue(data['dismissedAt']),
      metadata: _metadataFromValue(data['metadata']),
      fallbackTitle: _stringFromValue(data['fallbackTitle']),
      fallbackBody: _stringFromValue(data['fallbackBody']),
    );
  }
}

Map<String, Object?> _metadataFromValue(Object? value) {
  if (value is Map<String, dynamic>) {
    return value.map(
      (key, entry) => MapEntry(key, _safeMetadataValue(entry)),
    );
  }
  if (value is Map) {
    final clean = <String, Object?>{};
    for (final entry in value.entries) {
      final key = _stringFromValue(entry.key);
      if (key.isEmpty) {
        continue;
      }
      clean[key] = _safeMetadataValue(entry.value);
    }
    return clean;
  }
  return const {};
}

Object? _safeMetadataValue(Object? value) {
  if (value == null ||
      value is String ||
      value is num ||
      value is bool ||
      value is Timestamp ||
      value is DateTime) {
    return value;
  }
  if (value is Map<String, dynamic>) {
    return value.map(
      (key, entry) => MapEntry(key, _safeMetadataValue(entry)),
    );
  }
  if (value is Map) {
    final clean = <String, Object?>{};
    for (final entry in value.entries) {
      final key = _stringFromValue(entry.key);
      if (key.isEmpty) {
        continue;
      }
      clean[key] = _safeMetadataValue(entry.value);
    }
    return clean;
  }
  if (value is Iterable) {
    return value
        .map(_safeMetadataValue)
        .where((entry) => entry != null)
        .take(20)
        .toList(growable: false);
  }
  return null;
}

String _stringFromValue(Object? value, {String fallback = ''}) {
  if (value is String) {
    return value;
  }
  if (value is num || value is bool) {
    return value.toString();
  }
  return fallback;
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

CrmNotificationActionState _actionStateFromData(Map<String, dynamic> data) {
  final stored = _stringFromValue(data['actionState']).trim();
  if (stored.isNotEmpty) {
    return notificationActionStateFromValue(stored);
  }
  if (data['dismissedAt'] != null || data['isDismissed'] == true) {
    return CrmNotificationActionState.dismissed;
  }
  if (data['resolvedAt'] != null || data['isResolved'] == true) {
    return CrmNotificationActionState.resolved;
  }
  final type = notificationTypeFromValue(_stringFromValue(data['type']));
  if (notificationTypeUsuallyNeedsAction(type)) {
    return CrmNotificationActionState.actionNeeded;
  }
  return CrmNotificationActionState.none;
}
