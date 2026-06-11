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
    super.teamId,
    super.teamName,
    super.managerId,
    super.managerName,
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
      teamId: task.teamId,
      teamName: task.teamName,
      managerId: task.managerId,
      managerName: task.managerName,
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

    final pathCompanyId = document.reference.parent.parent?.id ?? '';

    return CrmTaskModel(
      id: _stringFromValue(data['id'], fallback: document.id),
      companyId: pathCompanyId.isNotEmpty
          ? pathCompanyId
          : _stringFromValue(data['companyId']),
      title: _stringFromValue(data['title']),
      description: _stringFromValue(data['description']),
      assignedTo: _stringFromValue(data['assignedTo']),
      assignedToName: _stringFromValue(data['assignedToName']),
      assignedToEmail: _stringFromValue(data['assignedToEmail']),
      teamId: _stringFromValue(data['teamId']),
      teamName: _stringFromValue(data['teamName']),
      managerId: _stringFromValue(data['managerId']),
      managerName: _stringFromValue(data['managerName']),
      relatedType: _relatedTypeFromValue(data['relatedType']),
      relatedId: _stringFromValue(data['relatedId']),
      relatedTitle: _stringFromValue(data['relatedTitle']),
      relatedSubtitle: _stringFromValue(data['relatedSubtitle']),
      dueDate: _dateTimeFromValue(data['dueDate']),
      status: _statusFromValue(data['status']),
      priority: _priorityFromValue(data['priority']),
      createdAt: _dateTimeFromValue(data['createdAt']),
      updatedAt: _dateTimeFromValue(data['updatedAt']),
      createdBy: _stringFromValue(data['createdBy']),
      updatedBy: _stringFromValue(data['updatedBy']),
      isActive: _boolFromValue(data['isActive'], fallback: true),
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
      'teamId': teamId,
      'teamName': teamName,
      'managerId': managerId,
      'managerName': managerName,
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


String _stringFromValue(Object? value, {String fallback = ''}) {
  if (value == null) {
    return fallback;
  }
  if (value is String) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? fallback : value;
  }
  return value.toString();
}

bool _boolFromValue(Object? value, {required bool fallback}) {
  if (value is bool) {
    return value;
  }
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'true') {
      return true;
    }
    if (normalized == 'false') {
      return false;
    }
  }
  return fallback;
}

TaskRelatedType _relatedTypeFromValue(Object? value) {
  final name = _stringFromValue(
    value,
    fallback: TaskRelatedType.general.name,
  );
  return TaskRelatedType.values.firstWhere(
    (type) => type.name == name,
    orElse: () => TaskRelatedType.general,
  );
}

TaskStatus _statusFromValue(Object? value) {
  final name = _stringFromValue(
    value,
    fallback: TaskStatus.pending.name,
  );
  return TaskStatus.values.firstWhere(
    (status) => status.name == name,
    orElse: () => TaskStatus.pending,
  );
}

TaskPriority _priorityFromValue(Object? value) {
  final name = _stringFromValue(
    value,
    fallback: TaskPriority.medium.name,
  );
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
