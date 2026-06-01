import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/firebase_paths.dart';
import '../../../../core/constants/role_constants.dart';
import '../../../appointments/data/models/appointment_model.dart';
import '../../../appointments/domain/entities/appointment.dart';
import '../../../audit_logs/data/models/audit_log_model.dart';
import '../../../audit_logs/domain/entities/audit_log.dart';
import '../../../deals/data/models/deal_model.dart';
import '../../../deals/domain/entities/deal.dart';
import '../../../tasks/data/models/crm_task_model.dart';
import '../../../tasks/domain/entities/crm_task.dart';
import '../../domain/entities/connected_journey.dart';

class FirestoreConnectedJourneyRemoteDataSource {
  FirestoreConnectedJourneyRemoteDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<List<JourneyItem>> watchTaskItems({
    required JourneyRecordType recordType,
    required String recordId,
    required JourneyQueryScope scope,
  }) {
    final relatedType = _taskRelatedType(recordType);
    if (relatedType == null || recordId.trim().isEmpty) {
      return Stream<List<JourneyItem>>.empty();
    }
    Query<Map<String, dynamic>> query = _firestore
        .collection(FirebasePaths.companyTasks(scope.companyId))
        .where('relatedType', isEqualTo: relatedType.name)
        .where('relatedId', isEqualTo: recordId.trim());
    query = _applyOperationalScope(query, scope);

    return query.limit(40).snapshots().map((snapshot) {
      return snapshot.docs
          .map(CrmTaskModel.fromFirestore)
          .where((task) => task.isActive)
          .map(_taskToJourneyItem)
          .toList();
    });
  }

  Stream<List<JourneyItem>> watchAppointmentItems({
    required JourneyRecordType recordType,
    required String recordId,
    required JourneyQueryScope scope,
  }) {
    final relatedType = _appointmentRelatedType(recordType);
    if (relatedType == null || recordId.trim().isEmpty) {
      return Stream<List<JourneyItem>>.empty();
    }
    Query<Map<String, dynamic>> query = _firestore
        .collection(FirebasePaths.companyAppointments(scope.companyId))
        .where('relatedType', isEqualTo: relatedType.name)
        .where('relatedId', isEqualTo: recordId.trim());
    query = _applyOperationalScope(query, scope);

    return query.limit(40).snapshots().map((snapshot) {
      return snapshot.docs
          .map(AppointmentModel.fromFirestore)
          .map(_appointmentToJourneyItem)
          .toList();
    });
  }

  Stream<List<JourneyItem>> watchDealItems({
    required JourneyRecordType recordType,
    required String recordId,
    required JourneyQueryScope scope,
  }) {
    final fieldName = switch (recordType) {
      JourneyRecordType.lead => 'leadId',
      JourneyRecordType.client => 'clientId',
      JourneyRecordType.deal => '',
    };
    if (fieldName.isEmpty || recordId.trim().isEmpty) {
      return Stream<List<JourneyItem>>.empty();
    }
    Query<Map<String, dynamic>> query = _firestore
        .collection(FirebasePaths.companyDeals(scope.companyId))
        .where(fieldName, isEqualTo: recordId.trim());
    query = _applyOperationalScope(query, scope);

    return query.limit(30).snapshots().map((snapshot) {
      return snapshot.docs.map(DealModel.fromFirestore).map(_dealToJourneyItem).toList();
    });
  }

  Stream<List<JourneyItem>> watchAuditItems({
    required JourneyRecordType recordType,
    required String recordId,
    required JourneyQueryScope scope,
  }) {
    if (!scope.canReadAudit || recordId.trim().isEmpty) {
      return Stream<List<JourneyItem>>.empty();
    }
    Query<Map<String, dynamic>> query = _firestore
        .collection(FirebasePaths.companyAuditLogs(scope.companyId))
        .where('recordId', isEqualTo: recordId.trim())
        .where('module', isEqualTo: _auditModuleValue(recordType));
    if (scope.role == UserRole.manager) {
      query = query.where('managerId', isEqualTo: scope.currentUserId);
    }

    return query.limit(40).snapshots().map((snapshot) {
      return snapshot.docs.map(AuditLogModel.fromFirestore).map(_auditToJourneyItem).toList();
    });
  }

  Query<Map<String, dynamic>> _applyOperationalScope(
    Query<Map<String, dynamic>> query,
    JourneyQueryScope scope,
  ) {
    return switch (scope.role) {
      UserRole.admin => query,
      UserRole.manager => query.where('managerId', isEqualTo: scope.currentUserId),
      UserRole.salesAgent || UserRole.marketing || UserRole.viewer =>
        query.where('assignedTo', isEqualTo: scope.currentUserId),
    };
  }
}

TaskRelatedType? _taskRelatedType(JourneyRecordType type) {
  return switch (type) {
    JourneyRecordType.lead => TaskRelatedType.lead,
    JourneyRecordType.client => TaskRelatedType.client,
    JourneyRecordType.deal => TaskRelatedType.deal,
  };
}

AppointmentRelatedType? _appointmentRelatedType(JourneyRecordType type) {
  return switch (type) {
    JourneyRecordType.lead => AppointmentRelatedType.lead,
    JourneyRecordType.client => AppointmentRelatedType.client,
    JourneyRecordType.deal => AppointmentRelatedType.deal,
  };
}

String _auditModuleValue(JourneyRecordType type) {
  return switch (type) {
    JourneyRecordType.lead => 'leads',
    JourneyRecordType.client => 'clients',
    JourneyRecordType.deal => 'deals',
  };
}

JourneyItem _taskToJourneyItem(CrmTask task) {
  final now = DateTime.now();
  final dueDate = task.dueDate;
  final overdue = dueDate != null &&
      dueDate.isBefore(DateTime(now.year, now.month, now.day)) &&
      task.status != TaskStatus.completed &&
      task.status != TaskStatus.cancelled;
  final type = task.status == TaskStatus.completed
      ? JourneyItemType.taskCompleted
      : task.status == TaskStatus.cancelled
          ? JourneyItemType.taskCancelled
          : overdue
              ? JourneyItemType.taskOverdue
              : JourneyItemType.taskUpdated;
  return JourneyItem(
    id: 'task:${task.id}:${task.updatedAt?.millisecondsSinceEpoch ?? task.createdAt?.millisecondsSinceEpoch ?? 0}',
    type: type,
    targetType: JourneyTargetType.task,
    targetId: task.id,
    title: task.title,
    subtitle: task.relatedTitle.isNotEmpty ? task.relatedTitle : task.description,
    occurredAt: task.updatedAt ?? task.createdAt ?? dueDate ?? now,
    tone: overdue
        ? JourneyTone.danger
        : task.status == TaskStatus.completed
            ? JourneyTone.success
            : task.priority == TaskPriority.high
                ? JourneyTone.warning
                : JourneyTone.info,
    actorName: task.assignedToName,
    statusLabel: _humanizeToken(task.status.name),
  );
}

JourneyItem _appointmentToJourneyItem(Appointment appointment) {
  final occurredAt = appointment.updatedAt ?? appointment.scheduledAt ?? appointment.createdAt ?? DateTime.now();
  final type = switch (appointment.status) {
    AppointmentStatus.completed => JourneyItemType.appointmentCompleted,
    AppointmentStatus.cancelled => JourneyItemType.appointmentCancelled,
    AppointmentStatus.missed => JourneyItemType.appointmentMissed,
    AppointmentStatus.rescheduled => JourneyItemType.appointmentRescheduled,
    AppointmentStatus.scheduled => JourneyItemType.appointmentScheduled,
  };
  final tone = switch (appointment.status) {
    AppointmentStatus.completed => JourneyTone.success,
    AppointmentStatus.cancelled => JourneyTone.neutral,
    AppointmentStatus.missed => JourneyTone.danger,
    AppointmentStatus.rescheduled => JourneyTone.warning,
    AppointmentStatus.scheduled => JourneyTone.info,
  };
  return JourneyItem(
    id: 'appointment:${appointment.id}:${occurredAt.millisecondsSinceEpoch}',
    type: type,
    targetType: JourneyTargetType.appointment,
    targetId: appointment.id,
    title: appointment.title,
    subtitle: _appointmentJourneySubtitle(appointment),
    occurredAt: occurredAt,
    tone: tone,
    actorName: appointment.assignedToName,
    statusLabel: _humanizeToken(appointment.status.name),
    metadata: {
      'status': appointment.status.name,
      'outcome': appointment.outcome?.name ?? '',
      'outcomeNotes': appointment.outcomeNotes,
      'cancellationReason': appointment.cancellationReason,
      'scheduledAt': appointment.scheduledAt?.toIso8601String() ?? '',
      'previousScheduledAt':
          appointment.previousScheduledAt?.toIso8601String() ?? '',
    },
  );
}

String _appointmentJourneySubtitle(Appointment appointment) {
  if (appointment.status == AppointmentStatus.cancelled &&
      appointment.cancellationReason.trim().isNotEmpty) {
    return appointment.cancellationReason.trim();
  }
  if (appointment.status == AppointmentStatus.completed &&
      appointment.outcomeNotes.trim().isNotEmpty) {
    return appointment.outcomeNotes.trim();
  }
  if (appointment.relatedTitle.isNotEmpty) {
    return appointment.relatedTitle;
  }
  return appointment.location;
}

JourneyItem _dealToJourneyItem(Deal deal) {
  final occurredAt = deal.updatedAt ?? deal.createdAt ?? DateTime.now();
  final type = switch (deal.stage) {
    DealStage.won => JourneyItemType.dealWon,
    DealStage.lost => JourneyItemType.dealLost,
    _ => JourneyItemType.dealUpdated,
  };
  final tone = switch (deal.stage) {
    DealStage.won => JourneyTone.success,
    DealStage.lost => JourneyTone.danger,
    DealStage.negotiation || DealStage.proposal => JourneyTone.warning,
    _ => JourneyTone.info,
  };
  return JourneyItem(
    id: 'deal:${deal.id}:${occurredAt.millisecondsSinceEpoch}',
    type: type,
    targetType: JourneyTargetType.deal,
    targetId: deal.id,
    title: deal.clientName.isNotEmpty ? deal.clientName : deal.leadName,
    subtitle: deal.propertyTitle,
    occurredAt: occurredAt,
    tone: tone,
    actorName: deal.assignedToName,
    statusLabel: _humanizeToken(deal.stage.name),
    metadata: {'expectedValue': deal.expectedValue, 'commission': deal.commission},
  );
}

JourneyItem _auditToJourneyItem(AuditLog log) {
  final type = switch (log.action) {
    AuditLogAction.create => JourneyItemType.auditCreated,
    AuditLogAction.archive => JourneyItemType.recordArchived,
    AuditLogAction.restore => JourneyItemType.recordRestored,
    AuditLogAction.statusChange || AuditLogAction.stageChange => JourneyItemType.dealStageChanged,
    _ => JourneyItemType.auditUpdated,
  };
  return JourneyItem(
    id: 'audit:${log.id}',
    type: type,
    targetType: JourneyTargetType.audit,
    targetId: log.recordId,
    title: _cleanAuditTitle(log),
    subtitle: _cleanAuditSubtitle(log),
    occurredAt: log.createdAt,
    tone: _auditTone(log.action),
    actorName: log.actorName,
    statusLabel: _humanizeToken(log.action.name),
    metadata: log.metadata,
  );
}

String _cleanAuditTitle(AuditLog log) {
  final title = log.recordTitle.trim();
  if (title.isNotEmpty && !_isTechnicalToken(title)) {
    return title;
  }
  return _humanizeToken(log.action.name);
}

String _cleanAuditSubtitle(AuditLog log) {
  final subtitle = log.recordSubtitle.trim();
  if (subtitle.isNotEmpty && !_isTechnicalToken(subtitle)) {
    return subtitle;
  }
  final changedField = log.metadata['field']?.toString() ??
      log.metadata['fieldName']?.toString() ??
      log.metadata['changedField']?.toString() ??
      '';
  if (changedField.trim().isNotEmpty) {
    return _humanizeToken(changedField);
  }
  return _humanizeToken(log.action.name);
}

bool _isTechnicalToken(String value) {
  return RegExp(r'^[a-zA-Z]+(_[a-zA-Z]+)+$').hasMatch(value.trim());
}

String _humanizeToken(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return '';
  final spaced = trimmed
      .replaceAll('_', ' ')
      .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (match) => '${match[1]} ${match[2]}')
      .toLowerCase();
  return spaced.isEmpty ? trimmed : spaced[0].toUpperCase() + spaced.substring(1);
}

JourneyTone _auditTone(AuditLogAction action) {
  return switch (action) {
    AuditLogAction.create || AuditLogAction.restore || AuditLogAction.complete || AuditLogAction.imageAdded => JourneyTone.success,
    AuditLogAction.archive || AuditLogAction.deactivate || AuditLogAction.cancel || AuditLogAction.imageRemoved => JourneyTone.neutral,
    AuditLogAction.statusChange || AuditLogAction.stageChange => JourneyTone.warning,
    _ => JourneyTone.info,
  };
}
