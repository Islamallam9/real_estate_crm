import 'package:equatable/equatable.dart';

enum CrmNotificationType {
  leadAssigned,
  leadReassigned,
  leadRemovedFromYou,
  taskAssigned,
  taskReassigned,
  taskRemovedFromYou,
  appointmentAssigned,
  appointmentReassigned,
  appointmentRemovedFromYou,
  appointmentDueSoon,
  appointmentDueNow,
  appointmentRescheduled,
  appointmentCancelled,
  appointmentCompleted,
  appointmentMissed,
  teamAppointmentAssigned,
  teamAppointmentReassigned,
  teamAppointmentDueSoon,
  teamAppointmentDueNow,
  teamAppointmentRescheduled,
  teamAppointmentCancelled,
  teamAppointmentCompleted,
  teamAppointmentMissed,
  clientAssigned,
  clientReassigned,
  clientRemovedFromYou,
  dealAssigned,
  dealReassigned,
  dealRemovedFromYou,
  leadImportantStatusChanged,
  dealStageChanged,
  dealImportantStatusChanged,
  dealWon,
  dealLost,
  taskStatusChanged,
  teamMemberAssigned,
  teamMemberReassigned,
  teamMemberRemovedFromRecord,
  teamLeadStatusChanged,
  teamDealStageChanged,
  teamTaskStatusChanged,
  genericStatusChanged,
  followUpDueToday,
  followUpOverdue,
  taskDueToday,
  taskOverdue,
  systemInfo,
  dataHealthIssue,
  unknown,
}

enum CrmNotificationPriority { low, normal, high, urgent }

enum CrmNotificationActionState { none, actionNeeded, resolved, dismissed }

class CrmNotification extends Equatable {
  const CrmNotification({
    required this.id,
    required this.companyId,
    required this.recipientUid,
    required this.recipientRole,
    required this.type,
    required this.module,
    required this.recordId,
    required this.recordTitle,
    required this.recordSubtitle,
    required this.route,
    required this.actorUid,
    required this.actorName,
    required this.teamId,
    required this.teamName,
    required this.managerId,
    required this.priority,
    required this.isRead,
    required this.readAt,
    required this.createdAt,
    required this.actionState,
    required this.resolvedAt,
    required this.dismissedAt,
    required this.metadata,
    this.fallbackTitle = '',
    this.fallbackBody = '',
  });

  final String id;
  final String companyId;
  final String recipientUid;
  final String recipientRole;
  final CrmNotificationType type;
  final String module;
  final String recordId;
  final String recordTitle;
  final String recordSubtitle;
  final String route;
  final String actorUid;
  final String actorName;
  final String teamId;
  final String teamName;
  final String managerId;
  final CrmNotificationPriority priority;
  final bool isRead;
  final DateTime? readAt;
  final DateTime? createdAt;
  final CrmNotificationActionState actionState;
  final DateTime? resolvedAt;
  final DateTime? dismissedAt;
  final Map<String, Object?> metadata;
  final String fallbackTitle;
  final String fallbackBody;

  bool get needsAction => actionState == CrmNotificationActionState.actionNeeded;

  bool get isDismissed => actionState == CrmNotificationActionState.dismissed;

  bool get isResolved => actionState == CrmNotificationActionState.resolved;

  CrmNotification copyWith({
    bool? isRead,
    DateTime? readAt,
    CrmNotificationActionState? actionState,
    DateTime? resolvedAt,
    DateTime? dismissedAt,
  }) {
    return CrmNotification(
      id: id,
      companyId: companyId,
      recipientUid: recipientUid,
      recipientRole: recipientRole,
      type: type,
      module: module,
      recordId: recordId,
      recordTitle: recordTitle,
      recordSubtitle: recordSubtitle,
      route: route,
      actorUid: actorUid,
      actorName: actorName,
      teamId: teamId,
      teamName: teamName,
      managerId: managerId,
      priority: priority,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt,
      actionState: actionState ?? this.actionState,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      dismissedAt: dismissedAt ?? this.dismissedAt,
      metadata: metadata,
      fallbackTitle: fallbackTitle,
      fallbackBody: fallbackBody,
    );
  }

  @override
  List<Object?> get props => [
        id,
        companyId,
        recipientUid,
        recipientRole,
        type,
        module,
        recordId,
        recordTitle,
        recordSubtitle,
        route,
        actorUid,
        actorName,
        teamId,
        teamName,
        managerId,
        priority,
        isRead,
        readAt,
        createdAt,
        actionState,
        resolvedAt,
        dismissedAt,
        metadata,
        fallbackTitle,
        fallbackBody,
      ];
}

CrmNotificationType notificationTypeFromValue(String value) {
  return CrmNotificationType.values.firstWhere(
    (type) => type.name == value,
    orElse: () => CrmNotificationType.unknown,
  );
}

String notificationTypeToValue(CrmNotificationType type) {
  return type == CrmNotificationType.unknown ? 'unknown' : type.name;
}

CrmNotificationPriority notificationPriorityFromValue(String value) {
  return CrmNotificationPriority.values.firstWhere(
    (priority) => priority.name == value,
    orElse: () => CrmNotificationPriority.normal,
  );
}

String notificationPriorityToValue(CrmNotificationPriority priority) {
  return priority.name;
}

CrmNotificationActionState notificationActionStateFromValue(String value) {
  return CrmNotificationActionState.values.firstWhere(
    (state) => state.name == value,
    orElse: () => CrmNotificationActionState.none,
  );
}

String notificationActionStateToValue(CrmNotificationActionState state) {
  return state.name;
}

bool notificationTypeUsuallyNeedsAction(CrmNotificationType type) {
  return switch (type) {
    CrmNotificationType.followUpDueToday ||
    CrmNotificationType.followUpOverdue ||
    CrmNotificationType.taskDueToday ||
    CrmNotificationType.taskOverdue ||
    CrmNotificationType.appointmentDueSoon ||
    CrmNotificationType.appointmentDueNow ||
    CrmNotificationType.appointmentMissed ||
    CrmNotificationType.teamAppointmentDueSoon ||
    CrmNotificationType.teamAppointmentDueNow ||
    CrmNotificationType.teamAppointmentMissed ||
    CrmNotificationType.dataHealthIssue => true,
    _ => false,
  };
}
