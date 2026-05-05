import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/lead_timeline_event.dart';

class LeadTimelineEventModel extends LeadTimelineEvent {
  const LeadTimelineEventModel({
    required super.id,
    required super.leadId,
    required super.companyId,
    required super.type,
    required super.title,
    required super.description,
    required super.oldValue,
    required super.newValue,
    required super.createdAt,
    required super.createdBy,
    required super.createdByName,
    required super.metadata,
  });

  factory LeadTimelineEventModel.fromEntity(LeadTimelineEvent event) {
    return LeadTimelineEventModel(
      id: event.id,
      leadId: event.leadId,
      companyId: event.companyId,
      type: event.type,
      title: event.title,
      description: event.description,
      oldValue: event.oldValue,
      newValue: event.newValue,
      createdAt: event.createdAt,
      createdBy: event.createdBy,
      createdByName: event.createdByName,
      metadata: event.metadata,
    );
  }

  factory LeadTimelineEventModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? <String, dynamic>{};
    return LeadTimelineEventModel(
      id: data['id'] as String? ?? document.id,
      leadId: data['leadId'] as String? ?? '',
      companyId: data['companyId'] as String? ?? '',
      type: data['type'] as String? ?? '',
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      oldValue: data['oldValue'] as String? ?? '',
      newValue: data['newValue'] as String? ?? '',
      createdAt: _dateTimeFromValue(data['createdAt']),
      createdBy: data['createdBy'] as String? ?? '',
      createdByName: data['createdByName'] as String? ?? '',
      metadata:
          (data['metadata'] as Map<String, dynamic>?) ?? <String, dynamic>{},
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'leadId': leadId,
      'companyId': companyId,
      'type': type,
      'title': title,
      'description': description,
      'oldValue': oldValue,
      'newValue': newValue,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
      'createdByName': createdByName,
      'metadata': metadata,
    };
  }
}

DateTime _dateTimeFromValue(Object? value) {
  if (value is Timestamp) {
    return value.toDate();
  }
  if (value is DateTime) {
    return value;
  }
  return DateTime.fromMillisecondsSinceEpoch(0);
}
