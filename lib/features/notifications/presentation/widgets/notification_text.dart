import 'package:intl/intl.dart' as intl;

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/attention_reminder.dart';
import '../../domain/entities/crm_notification.dart';

String notificationTitle(AppLocalizations l, CrmNotification notification) {
  return switch (notification.type) {
    CrmNotificationType.leadAssigned => l.notificationLeadAssignedTitle,
    CrmNotificationType.leadReassigned => l.notificationLeadReassignedTitle,
    CrmNotificationType.leadRemovedFromYou =>
      l.notificationLeadRemovedFromYouTitle,
    CrmNotificationType.taskAssigned => l.notificationTaskAssignedTitle,
    CrmNotificationType.taskReassigned => l.notificationTaskReassignedTitle,
    CrmNotificationType.taskRemovedFromYou =>
      l.notificationTaskRemovedFromYouTitle,
    CrmNotificationType.appointmentAssigned =>
      l.notificationAppointmentAssignedTitle,
    CrmNotificationType.appointmentReassigned =>
      l.notificationAppointmentReassignedTitle,
    CrmNotificationType.appointmentRemovedFromYou =>
      l.notificationAppointmentRemovedFromYouTitle,
    CrmNotificationType.appointmentDueNow =>
      l.notificationAppointmentDueNowTitle,
    CrmNotificationType.appointmentRescheduled =>
      l.notificationAppointmentRescheduledTitle,
    CrmNotificationType.appointmentCancelled =>
      l.notificationAppointmentCancelledTitle,
    CrmNotificationType.appointmentCompleted =>
      l.notificationAppointmentCompletedTitle,
    CrmNotificationType.appointmentMissed =>
      l.notificationAppointmentMissedTitle,
    CrmNotificationType.teamAppointmentAssigned =>
      l.notificationTeamAppointmentAssignedTitle,
    CrmNotificationType.teamAppointmentReassigned =>
      l.notificationTeamAppointmentReassignedTitle,
    CrmNotificationType.teamAppointmentRescheduled =>
      l.notificationTeamAppointmentRescheduledTitle,
    CrmNotificationType.teamAppointmentCancelled =>
      l.notificationTeamAppointmentCancelledTitle,
    CrmNotificationType.teamAppointmentCompleted =>
      l.notificationTeamAppointmentCompletedTitle,
    CrmNotificationType.teamAppointmentMissed =>
      l.notificationTeamAppointmentMissedTitle,
    CrmNotificationType.clientAssigned => l.notificationClientAssignedTitle,
    CrmNotificationType.clientReassigned => l.notificationClientReassignedTitle,
    CrmNotificationType.clientRemovedFromYou =>
      l.notificationClientRemovedFromYouTitle,
    CrmNotificationType.dealAssigned => l.notificationDealAssignedTitle,
    CrmNotificationType.dealReassigned => l.notificationDealReassignedTitle,
    CrmNotificationType.dealRemovedFromYou =>
      l.notificationDealRemovedFromYouTitle,
    CrmNotificationType.leadImportantStatusChanged =>
      l.notificationLeadImportantStatusChangedTitle,
    CrmNotificationType.dealStageChanged =>
      l.notificationDealStageChangedTitle,
    CrmNotificationType.dealImportantStatusChanged =>
      l.notificationDealImportantStatusChangedTitle,
    CrmNotificationType.dealWon => l.notificationDealWonTitle,
    CrmNotificationType.dealLost => l.notificationDealLostTitle,
    CrmNotificationType.taskStatusChanged =>
      l.notificationTaskStatusChangedTitle,
    CrmNotificationType.teamMemberAssigned =>
      l.notificationTeamMemberAssignedTitle,
    CrmNotificationType.teamMemberReassigned =>
      l.notificationTeamMemberReassignedTitle,
    CrmNotificationType.teamMemberRemovedFromRecord =>
      l.notificationTeamMemberRemovedTitle,
    CrmNotificationType.teamLeadStatusChanged =>
      l.notificationTeamLeadStatusChangedTitle,
    CrmNotificationType.teamDealStageChanged =>
      l.notificationTeamDealStageChangedTitle,
    CrmNotificationType.teamTaskStatusChanged =>
      l.notificationTeamTaskStatusChangedTitle,
    CrmNotificationType.genericStatusChanged =>
      l.notificationGenericStatusChangedTitle,
    CrmNotificationType.followUpDueToday => l.notificationFollowUpDueTodayTitle,
    CrmNotificationType.followUpOverdue => l.notificationFollowUpOverdueTitle,
    CrmNotificationType.taskDueToday => l.notificationTaskDueTodayTitle,
    CrmNotificationType.taskOverdue => l.notificationTaskOverdueTitle,
    CrmNotificationType.dataHealthIssue => l.notificationDataHealthIssueTitle,
    CrmNotificationType.systemInfo => notification.fallbackTitle.trim().isEmpty
        ? l.notificationSystemInfoTitle
        : notification.fallbackTitle.trim(),
    CrmNotificationType.unknown => notification.fallbackTitle.trim().isEmpty
        ? l.notificationGenericTitle
        : notification.fallbackTitle.trim(),
  };
}

String notificationBody(AppLocalizations l, CrmNotification notification) {
  final record = _recordLabel(l, notification.recordTitle);
  final actor = notification.actorName.trim();
  if (notification.type == CrmNotificationType.leadRemovedFromYou) {
    return l.notificationRecordNoLongerAssignedBody(record);
  }
  if (notification.type == CrmNotificationType.appointmentDueNow) {
    return l.notificationRecordBody(record);
  }
  if (notification.type == CrmNotificationType.taskRemovedFromYou ||
      notification.type == CrmNotificationType.appointmentRemovedFromYou ||
      notification.type == CrmNotificationType.clientRemovedFromYou ||
      notification.type == CrmNotificationType.dealRemovedFromYou) {
    return l.notificationRecordNoLongerAssignedBody(record);
  }
  if (notification.type == CrmNotificationType.leadImportantStatusChanged ||
      notification.type == CrmNotificationType.dealStageChanged ||
      notification.type == CrmNotificationType.dealImportantStatusChanged ||
      notification.type == CrmNotificationType.dealWon ||
      notification.type == CrmNotificationType.dealLost ||
      notification.type == CrmNotificationType.taskStatusChanged ||
      notification.type == CrmNotificationType.appointmentRescheduled ||
      notification.type == CrmNotificationType.appointmentCancelled ||
      notification.type == CrmNotificationType.appointmentCompleted ||
      notification.type == CrmNotificationType.appointmentMissed ||
      notification.type == CrmNotificationType.teamLeadStatusChanged ||
      notification.type == CrmNotificationType.teamDealStageChanged ||
      notification.type == CrmNotificationType.teamTaskStatusChanged ||
      notification.type == CrmNotificationType.teamAppointmentRescheduled ||
      notification.type == CrmNotificationType.teamAppointmentCancelled ||
      notification.type == CrmNotificationType.teamAppointmentCompleted ||
      notification.type == CrmNotificationType.teamAppointmentMissed ||
      notification.type == CrmNotificationType.genericStatusChanged) {
    final next = (notification.metadata['newStatus'] ??
            notification.metadata['newStage'] ??
            '')
        .toString()
        .trim();
    if (next.isNotEmpty) {
      final label = _statusLabel(l, next);
      return actor.isEmpty
          ? l.notificationStatusChangedBody(record, label)
          : l.notificationStatusChangedByActorBody(record, label, actor);
    }
  }
  if (notification.type == CrmNotificationType.teamMemberAssigned ||
      notification.type == CrmNotificationType.teamMemberReassigned ||
      notification.type == CrmNotificationType.teamMemberRemovedFromRecord ||
      notification.type == CrmNotificationType.teamAppointmentAssigned ||
      notification.type == CrmNotificationType.teamAppointmentReassigned) {
    final member = (notification.metadata['assignedToName'] ??
            notification.metadata['previousAssignedToName'] ??
            '')
        .toString()
        .trim();
    final previousMember =
        (notification.metadata['previousAssignedToName'] ?? '')
            .toString()
            .trim();
    if ((notification.type == CrmNotificationType.teamMemberReassigned ||
            notification.type == CrmNotificationType.teamAppointmentReassigned) &&
        previousMember.isNotEmpty &&
        member.isNotEmpty &&
        previousMember != member) {
      return actor.isEmpty
          ? l.notificationTeamMemberReassignedBody(
              record,
              previousMember,
              member,
            )
          : l.notificationTeamMemberReassignedByActorBody(
              record,
              previousMember,
              member,
              actor,
            );
    }
    final cleanMember = member.isEmpty ? l.teamMembersShort : member;
    if (notification.type == CrmNotificationType.teamMemberRemovedFromRecord) {
      return actor.isEmpty
          ? l.notificationTeamMemberRemovedBody(record, cleanMember)
          : l.notificationTeamMemberRemovedByActorBody(
              record,
              cleanMember,
              actor,
            );
    }
    return actor.isEmpty
        ? l.notificationTeamMemberAssignedBody(record, cleanMember)
        : l.notificationTeamMemberAssignedByActorBody(
            record,
            cleanMember,
            actor,
          );
  }
  if (notification.type == CrmNotificationType.systemInfo ||
      notification.type == CrmNotificationType.unknown) {
    return notification.fallbackBody.trim().isEmpty
        ? l.notificationGenericBody(record)
        : notification.fallbackBody.trim();
  }
  if (notification.type == CrmNotificationType.dataHealthIssue) {
    final issueType = (notification.metadata['issueType'] ?? '')
        .toString()
        .trim();
    return l.notificationDataHealthIssueBody(
      record,
      _dataHealthIssueLabel(l, issueType),
    );
  }
  if (actor.isNotEmpty) {
    return l.notificationRecordByActorBody(record, actor);
  }
  return l.notificationRecordBody(record);
}

String reminderTitle(AppLocalizations l, AttentionReminder reminder) {
  return switch (reminder.type) {
    AttentionReminderType.followUpDueToday => l.notificationFollowUpDueTodayTitle,
    AttentionReminderType.followUpOverdue => l.notificationFollowUpOverdueTitle,
    AttentionReminderType.taskDueToday => l.notificationTaskDueTodayTitle,
    AttentionReminderType.taskOverdue => l.notificationTaskOverdueTitle,
    AttentionReminderType.appointmentToday =>
      l.notificationAppointmentTodayAttentionTitle,
    AttentionReminderType.appointmentDueNow =>
      l.notificationAppointmentDueNowTitle,
    AttentionReminderType.appointmentMissed =>
      l.notificationAppointmentMissedAttentionTitle,
    AttentionReminderType.appointmentUpcomingSoon =>
      l.notificationAppointmentUpcomingSoonTitle,
    AttentionReminderType.unassignedLead => l.notificationUnassignedLeadTitle,
  };
}

String reminderBody(AppLocalizations l, AttentionReminder reminder) {
  final record = _recordLabel(l, reminder.recordTitle);
  final assignee = reminder.assignedToName.trim();
  if (reminder.type == AttentionReminderType.unassignedLead) {
    return l.notificationUnassignedLeadBody(record);
  }
  if (assignee.isNotEmpty) {
    return l.notificationReminderAssignedBody(record, assignee);
  }
  return l.notificationRecordBody(record);
}

String moduleLabel(AppLocalizations l, String module) {
  return switch (module) {
    'leads' => l.leads,
    'tasks' => l.tasks,
    'appointments' => l.appointments,
    'deals' => l.deals,
    'clients' => l.clients,
    'properties' => l.properties,
    'support' => l.supportCenter,
    'dataHealth' => l.dataHealth,
    _ => l.notificationSystemModule,
  };
}

String relativeTime(AppLocalizations l, DateTime? value) {
  if (value == null) {
    return '';
  }
  final now = DateTime.now();
  final local = value.toLocal();
  final diff = now.difference(local);
  if (diff.inMinutes < 1) {
    return l.dashboardJustNow;
  }
  if (diff.inHours < 1) {
    return l.dashboardMinutesAgo(diff.inMinutes);
  }
  if (diff.inHours < 24) {
    return l.dashboardHoursAgo(diff.inHours);
  }
  final yesterday = DateTime(now.year, now.month, now.day - 1);
  final localDay = DateTime(local.year, local.month, local.day);
  if (localDay == yesterday) {
    return l.dashboardYesterday;
  }
  return intl.DateFormat.yMMMd(l.localeName).format(local);
}

String dueDateLabel(AppLocalizations l, DateTime? value) {
  if (value == null) {
    return '';
  }
  return intl.DateFormat.yMMMd(l.localeName).format(value.toLocal());
}

String _recordLabel(AppLocalizations l, String value) {
  final clean = value.trim();
  return clean.isEmpty ? l.notificationRecordFallback : clean;
}

String _statusLabel(AppLocalizations l, String value) {
  return switch (value) {
    'new' => l.newLead,
    'contacted' => l.contacted,
    'interested' => l.interested,
    'visitScheduled' => l.visitScheduled,
    'negotiation' => l.negotiation,
    'hot' => value,
    'qualified' => l.qualified,
    'converted' => value,
    'proposal' => l.proposal,
    'won' || 'closedWon' => l.won,
    'lost' || 'closedLost' => l.lost,
    'reservation' || 'reserved' => l.reserved,
    'completed' => l.completed,
    'cancelled' || 'canceled' => l.cancelled,
    'missed' => l.appointmentStatusMissed,
    'rescheduled' => l.appointmentStatusRescheduled,
    'closed' => value,
    'contract' => value,
    _ => value,
  };
}

String _dataHealthIssueLabel(AppLocalizations l, String value) {
  return switch (value) {
    'missingAssignee' => l.missingAssignee,
    'missingSnapshots' => l.missingSnapshots,
    'inactiveAssignee' => l.inactiveAssignees,
    'ineligibleAssignee' => l.invalidAssignees,
    'staleSnapshots' => l.staleTeamSnapshots,
    _ => l.dataHealth,
  };
}
