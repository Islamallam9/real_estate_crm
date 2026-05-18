import 'package:equatable/equatable.dart';

enum AuditLogAction {
  create,
  update,
  archive,
  deactivate,
  assign,
  statusChange,
  stageChange,
  complete,
  cancel,
  imageAdded,
  imageRemoved,
}

enum AuditLogModule { leads, clients, properties, tasks, deals }

class AuditLog extends Equatable {
  const AuditLog({
    required this.id,
    required this.companyId,
    required this.actorId,
    required this.actorName,
    required this.actorEmail,
    required this.actorRole,
    required this.action,
    required this.module,
    required this.recordId,
    required this.recordTitle,
    required this.recordSubtitle,
    this.assignedTo = '',
    this.teamId = '',
    this.teamName = '',
    this.managerId = '',
    this.managerName = '',
    required this.createdAt,
    required this.metadata,
  });

  final String id;
  final String companyId;
  final String actorId;
  final String actorName;
  final String actorEmail;
  final String actorRole;
  final AuditLogAction action;
  final AuditLogModule module;
  final String recordId;
  final String recordTitle;
  final String recordSubtitle;
  final String assignedTo;
  final String teamId;
  final String teamName;
  final String managerId;
  final String managerName;
  final DateTime createdAt;
  final Map<String, Object?> metadata;

  @override
  List<Object?> get props => [
    id,
    companyId,
    actorId,
    actorName,
    actorEmail,
    actorRole,
    action,
    module,
    recordId,
    recordTitle,
    recordSubtitle,
    assignedTo,
    teamId,
    teamName,
    managerId,
    managerName,
    createdAt,
    metadata,
  ];
}
