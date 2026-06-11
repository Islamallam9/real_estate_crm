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
      createdAt: _dateTimeFromAuditData(data),
      metadata: _metadataFromValue(data['metadata']),
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
    'restore' => AuditLogAction.restore,
    'deactivate' => AuditLogAction.deactivate,
    'assign' => AuditLogAction.assign,
    'statusChange' => AuditLogAction.statusChange,
    'stageChange' => AuditLogAction.stageChange,
    'complete' => AuditLogAction.complete,
    'cancel' => AuditLogAction.cancel,
    'imageAdded' => AuditLogAction.imageAdded,
    'imageRemoved' => AuditLogAction.imageRemoved,
    'exportGenerated' => AuditLogAction.exportGenerated,
    'exported' => AuditLogAction.exported,
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
    'appointments' => AuditLogModule.appointments,
    'users' => AuditLogModule.users,
    'teams' => AuditLogModule.teams,
    'reports' => AuditLogModule.reports,
    'exports' => AuditLogModule.exports,
    'auditLogs' => AuditLogModule.auditLogs,
    'leads' => AuditLogModule.leads,
    _ => AuditLogModule.other,
  };
}

String auditLogModuleToValue(AuditLogModule module) {
  return module.name;
}

DateTime _dateTimeFromAuditData(Map<String, dynamic> data) {
  final createdAt = _dateTimeFromValue(data['createdAt']);
  final clientCreatedAt = _dateTimeFromValue(data['clientCreatedAt']);
  final serverCreatedAt = _dateTimeFromValue(data['serverCreatedAt']);
  final updatedAt = _dateTimeFromValue(data['updatedAt']);

  // Never fall back to DateTime.now() for audit documents. During offline/cache
  // reconciliation, pending server timestamps can be temporarily missing. Showing
  // those records as "now" makes old rows jump to the current laptop time every
  // time the audit stream refreshes. Invalid/pending audit rows are skipped by
  // the data source until Firestore returns a real timestamp.
  final candidate = createdAt ?? clientCreatedAt ?? serverCreatedAt ?? updatedAt;
  if (candidate == null) {
    throw StateError('Audit log timestamp is missing or invalid.');
  }
  return candidate;
}

DateTime? _dateTimeFromValue(Object? value) {
  DateTime? parsed;
  if (value is Timestamp) {
    parsed = value.toDate();
  } else if (value is DateTime) {
    parsed = value;
  } else if (value is int) {
    parsed = DateTime.fromMillisecondsSinceEpoch(value);
  } else if (value is double) {
    parsed = DateTime.fromMillisecondsSinceEpoch(value.toInt());
  } else if (value is String && value.trim().isNotEmpty) {
    parsed = DateTime.tryParse(value.trim());
  }
  if (parsed == null) {
    return null;
  }
  final local = parsed.toLocal();
  final now = DateTime.now();
  if (local.isAfter(now.add(const Duration(minutes: 10)))) {
    return null;
  }
  if (local.isBefore(DateTime(now.year - 5))) {
    return null;
  }
  return local;
}

Map<String, Object?> _metadataFromValue(Object? value) {
  if (value is Map) {
    return value.map(
      (key, item) => MapEntry(key.toString(), item),
    );
  }
  return const <String, Object?>{};
}
