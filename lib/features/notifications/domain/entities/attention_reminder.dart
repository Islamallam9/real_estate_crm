import 'package:equatable/equatable.dart';

enum AttentionReminderType {
  followUpDueToday,
  followUpOverdue,
  taskDueToday,
  taskOverdue,
  appointmentToday,
  appointmentDueNow,
  appointmentMissed,
  appointmentUpcomingSoon,
  unassignedLead,
}

class AttentionReminder extends Equatable {
  const AttentionReminder({
    required this.id,
    required this.type,
    required this.module,
    required this.recordId,
    required this.recordTitle,
    required this.recordSubtitle,
    required this.route,
    required this.dueAt,
    required this.assignedToName,
    this.count = 1,
  });

  final String id;
  final AttentionReminderType type;
  final String module;
  final String recordId;
  final String recordTitle;
  final String recordSubtitle;
  final String route;
  final DateTime? dueAt;
  final String assignedToName;
  final int count;

  @override
  List<Object?> get props => [
        id,
        type,
        module,
        recordId,
        recordTitle,
        recordSubtitle,
        route,
        dueAt,
        assignedToName,
        count,
      ];
}
