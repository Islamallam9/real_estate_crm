import 'package:equatable/equatable.dart';

import '../../../../core/constants/role_constants.dart';

enum JourneyRecordType { lead, client, deal }

enum JourneyTargetType { lead, client, task, appointment, deal, audit, system }

enum JourneyItemType {
  recordCreated,
  recordUpdated,
  recordArchived,
  recordRestored,
  leadTimeline,
  taskCreated,
  taskUpdated,
  taskCompleted,
  taskCancelled,
  taskOverdue,
  appointmentCreated,
  appointmentScheduled,
  appointmentCompleted,
  appointmentCancelled,
  appointmentMissed,
  appointmentRescheduled,
  dealCreated,
  dealUpdated,
  dealStageChanged,
  dealWon,
  dealLost,
  dealAtRisk,
  auditCreated,
  auditUpdated,
}

enum JourneyTone { neutral, info, success, warning, danger }

class JourneyQueryScope extends Equatable {
  const JourneyQueryScope({
    required this.companyId,
    required this.currentUserId,
    required this.role,
    this.teamId = '',
    this.managerId = '',
  });

  final String companyId;
  final String currentUserId;
  final UserRole role;
  final String teamId;
  final String managerId;

  bool get canReadAudit => role == UserRole.admin || role == UserRole.manager;

  @override
  List<Object?> get props => [companyId, currentUserId, role, teamId, managerId];
}

class JourneyItem extends Equatable {
  const JourneyItem({
    required this.id,
    required this.type,
    required this.targetType,
    required this.targetId,
    required this.title,
    required this.subtitle,
    required this.occurredAt,
    required this.tone,
    this.actorName = '',
    this.statusLabel = '',
    this.metadata = const <String, Object?>{},
  });

  final String id;
  final JourneyItemType type;
  final JourneyTargetType targetType;
  final String targetId;
  final String title;
  final String subtitle;
  final DateTime occurredAt;
  final JourneyTone tone;
  final String actorName;
  final String statusLabel;
  final Map<String, Object?> metadata;

  @override
  List<Object?> get props => [
        id,
        type,
        targetType,
        targetId,
        title,
        subtitle,
        occurredAt,
        tone,
        actorName,
        statusLabel,
        metadata,
      ];
}

class JourneyRecommendation extends Equatable {
  const JourneyRecommendation({
    required this.title,
    required this.subtitle,
    required this.tone,
    this.actionLabel = '',
    this.actionRoute = '',
  });

  final String title;
  final String subtitle;
  final JourneyTone tone;
  final String actionLabel;
  final String actionRoute;

  bool get hasAction => actionLabel.trim().isNotEmpty && actionRoute.trim().isNotEmpty;

  @override
  List<Object?> get props => [title, subtitle, tone, actionLabel, actionRoute];
}
