import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/audit_log.dart';

class AuditLogModel extends AuditLog {
  const AuditLogModel({
    required super.id,
    required super.companyId,
    required super.actorId,
    required super.actorName,
    required super.actorEmail,
    required super.actorRole,
    required super.action,
    required super.module,
    required super.recordId,
    required super.recordTitle,
    required super.recordSubtitle,
    super.assignedTo,
    super.teamId,
    super.teamName,
    super.managerId,
    super.managerName,
    required super.createdAt,
    required super.metadata,
  });

  factory AuditLogModel.fromEntity(AuditLog auditLog) {
    return AuditLogModel(
      id: auditLog.id,
      companyId: auditLog.companyId,
      actorId: auditLog.actorId,
      actorName: auditLog.actorName,
      actorEmail: auditLog.actorEmail,
      actorRole: auditLog.actorRole,
      action: auditLog.action,
      module: auditLog.module,
      recordId: auditLog.recordId,
      recordTitle: auditLog.recordTitle,
      recordSubtitle: auditLog.recordSubtitle,
      assignedTo: auditLog.assignedTo,
      teamId: auditLog.teamId,
      teamName: auditLog.teamName,
      managerId: auditLog.managerId,
      managerName: auditLog.managerName,
      createdAt: auditLog.createdAt,
      metadata: auditLog.metadata,
    );
  }

  factory AuditLogModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    if (data == null) {
      throw StateError('Audit log data was not found.');
    }

    return AuditLogModel(
      id: data['id'] as String? ?? document.id,
      companyId: data['companyId'] as String? ?? '',
      actorId: data['actorId'] as String? ?? '',
      actorName: data['actorName'] as String? ?? '',
      actorEmail: data['actorEmail'] as String? ?? '',
      actorRole: data['actorRole'] as String? ?? '',
      action: auditLogActionFromValue(data['action'] as String? ?? 'update'),
      module: auditLogModuleFromValue(data['module'] as String? ?? 'leads'),
      recordId: data['recordId'] as String? ?? '',
      recordTitle: data['recordTitle'] as String? ?? '',
      recordSubtitle: data['recordSubtitle'] as String? ?? '',
      assignedTo: data['assignedTo'] as String? ?? '',
      teamId: data['teamId'] as String? ?? '',
      teamName: data['teamName'] as String? ?? '',
      managerId: data['managerId'] as String? ?? '',
      managerName: data['managerName'] as String? ?? '',
      createdAt: _dateTimeFromValue(data['createdAt']),
      metadata: Map<String, Object?>.from(
        data['metadata'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'companyId': companyId,
      'actorId': actorId,
      'actorName': actorName,
      'actorEmail': actorEmail,
      'actorRole': actorRole,
      'action': auditLogActionToValue(action),
      'module': auditLogModuleToValue(module),
      'recordId': recordId,
      'recordTitle': recordTitle,
      'recordSubtitle': recordSubtitle,
      'assignedTo': assignedTo,
      'teamId': teamId,
      'teamName': teamName,
      'managerId': managerId,
      'managerName': managerName,
      'createdAt': Timestamp.fromDate(createdAt),
      'metadata': metadata,
    };
  }
}

AuditLogAction auditLogActionFromValue(String value) {
  return switch (value) {
    'create' => AuditLogAction.create,
    'update' => AuditLogAction.update,
    'archive' => AuditLogAction.archive,
    'deactivate' => AuditLogAction.deactivate,
    'assign' => AuditLogAction.assign,
    'statusChange' => AuditLogAction.statusChange,
    'stageChange' => AuditLogAction.stageChange,
    'complete' => AuditLogAction.complete,
    'cancel' => AuditLogAction.cancel,
    'imageAdded' => AuditLogAction.imageAdded,
    'imageRemoved' => AuditLogAction.imageRemoved,
    _ => AuditLogAction.update,
  };
}

String auditLogActionToValue(AuditLogAction action) {
  return action.name;
}

AuditLogModule auditLogModuleFromValue(String value) {
  return switch (value) {
    'clients' => AuditLogModule.clients,
    'properties' => AuditLogModule.properties,
    'tasks' => AuditLogModule.tasks,
    'deals' => AuditLogModule.deals,
    'leads' => AuditLogModule.leads,
    _ => AuditLogModule.leads,
  };
}

String auditLogModuleToValue(AuditLogModule module) {
  return module.name;
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
