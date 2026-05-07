import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/crm_task.dart';

class CrmTaskModel extends CrmTask {
  const CrmTaskModel({
    required super.id,
    required super.companyId,
    required super.title,
    required super.description,
    required super.assignedTo,
    required super.assignedToName,
    required super.assignedToEmail,
    required super.relatedType,
    required super.relatedId,
    required super.relatedTitle,
    required super.relatedSubtitle,
    required super.dueDate,
    required super.status,
    required super.priority,
    required super.createdAt,
    required super.updatedAt,
    required super.createdBy,
    required super.updatedBy,
    required super.isActive,
  });

  factory CrmTaskModel.fromEntity(CrmTask task) {
    return CrmTaskModel(
      id: task.id,
      companyId: task.companyId,
      title: task.title,
      description: task.description,
      assignedTo: task.assignedTo,
      assignedToName: task.assignedToName,
      assignedToEmail: task.assignedToEmail,
      relatedType: task.relatedType,
      relatedId: task.relatedId,
      relatedTitle: task.relatedTitle,
      relatedSubtitle: task.relatedSubtitle,
      dueDate: task.dueDate,
      status: task.status,
      priority: task.priority,
      createdAt: task.createdAt,
      updatedAt: task.updatedAt,
      createdBy: task.createdBy,
      updatedBy: task.updatedBy,
      isActive: task.isActive,
    );
  }

  factory CrmTaskModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    if (data == null) {
      throw StateError('Task data was not found.');
    }

    return CrmTaskModel(
      id: data['id'] as String? ?? document.id,
      companyId: data['companyId'] as String? ?? '',
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      assignedTo: data['assignedTo'] as String? ?? '',
      assignedToName: data['assignedToName'] as String? ?? '',
      assignedToEmail: data['assignedToEmail'] as String? ?? '',
      relatedType: _relatedTypeFromValue(data['relatedType']),
      relatedId: data['relatedId'] as String? ?? '',
      relatedTitle: data['relatedTitle'] as String? ?? '',
      relatedSubtitle: data['relatedSubtitle'] as String? ?? '',
      dueDate: _dateTimeFromValue(data['dueDate']),
      status: _statusFromValue(data['status']),
      priority: _priorityFromValue(data['priority']),
      createdAt: _dateTimeFromValue(data['createdAt']),
      updatedAt: _dateTimeFromValue(data['updatedAt']),
      createdBy: data['createdBy'] as String? ?? '',
      updatedBy: data['updatedBy'] as String? ?? '',
      isActive: data['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'companyId': companyId,
      'title': title,
      'description': description,
      'assignedTo': assignedTo,
      'assignedToName': assignedToName,
      'assignedToEmail': assignedToEmail,
      'relatedType': relatedType.name,
      'relatedId': relatedId,
      'relatedTitle': relatedTitle,
      'relatedSubtitle': relatedSubtitle,
      'dueDate': dueDate == null ? null : Timestamp.fromDate(dueDate!),
      'status': status.name,
      'priority': priority.name,
      'createdAt': createdAt == null ? null : Timestamp.fromDate(createdAt!),
      'updatedAt': updatedAt == null ? null : Timestamp.fromDate(updatedAt!),
      'createdBy': createdBy,
      'updatedBy': updatedBy,
      'isActive': isActive,
    };
  }
}

TaskRelatedType _relatedTypeFromValue(Object? value) {
  final name = value as String? ?? TaskRelatedType.general.name;
  return TaskRelatedType.values.firstWhere(
    (type) => type.name == name,
    orElse: () => TaskRelatedType.general,
  );
}

TaskStatus _statusFromValue(Object? value) {
  final name = value as String? ?? TaskStatus.pending.name;
  return TaskStatus.values.firstWhere(
    (status) => status.name == name,
    orElse: () => TaskStatus.pending,
  );
}

TaskPriority _priorityFromValue(Object? value) {
  final name = value as String? ?? TaskPriority.medium.name;
  return TaskPriority.values.firstWhere(
    (priority) => priority.name == name,
    orElse: () => TaskPriority.medium,
  );
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
