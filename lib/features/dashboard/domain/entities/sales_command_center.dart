import 'package:equatable/equatable.dart';

enum SalesCommandSectionType {
  todayPriorities,
  hotOpportunities,
  overdueFollowUps,
  missedAppointments,
  overdueTasks,
  stuckDeals,
  atRisk,
  teamPressure,
}

enum DashboardCommandModule {
  lead,
  task,
  deal,
  appointment,
  client,
  user,
  team,
}

enum DashboardAttentionReason {
  overdueFollowUp,
  dueTodayFollowUp,
  overdueTask,
  dueTodayTask,
  staleLead,
  hotLead,
  leadNeedsContact,
  leadMissingNextStep,
  leadNeedsAppointment,
  leadNeedsDeal,
  unassignedLead,
  appointmentMissed,
  appointmentDueNow,
  appointmentUpcoming,
  appointmentNeedsFeedback,
  dealAtRisk,
  overloadedAssignee,
}

enum DashboardPriority { high, medium, low }

enum DashboardCommandActionType {
  openLead,
  openTask,
  openDeal,
  openAppointment,
  createFollowUp,
  assignLead,
  openClient,
  openTasks,
}

class SalesCommandItem extends Equatable {
  const SalesCommandItem({
    required this.id,
    required this.module,
    required this.recordId,
    required this.title,
    required this.subtitle,
    required this.reason,
    required this.priority,
    required this.actionType,
    required this.score,
    this.dueAt,
    this.relatedDate,
    this.assignedTo = '',
    this.assignedToName = '',
    this.teamId = '',
    this.managerId = '',
    this.createdAt,
    this.sortDate,
    this.count,
    this.ageDays,
    this.dedupeKey,
  });

  final String id;
  final DashboardCommandModule module;
  final String recordId;
  final String title;
  final String subtitle;
  final DashboardAttentionReason reason;
  final DashboardPriority priority;
  final int score;
  final DateTime? dueAt;
  final DateTime? relatedDate;
  final String assignedTo;
  final String assignedToName;
  final String teamId;
  final String managerId;
  final DashboardCommandActionType actionType;
  final DateTime? createdAt;
  final DateTime? sortDate;
  final int? count;
  final int? ageDays;
  final String? dedupeKey;

  String get recordKey {
    final key = dedupeKey?.trim();
    if (key != null && key.isNotEmpty) {
      return key;
    }
    return '${module.name}:$recordId';
  }

  @override
  List<Object?> get props => [
        id,
        module,
        recordId,
        title,
        subtitle,
        reason,
        priority,
        score,
        dueAt,
        relatedDate,
        assignedTo,
        assignedToName,
        teamId,
        managerId,
        actionType,
        createdAt,
        sortDate,
        count,
        ageDays,
        dedupeKey,
      ];
}

class SalesCommandSection extends Equatable {
  const SalesCommandSection({
    required this.type,
    required this.items,
    this.totalCount,
  });

  final SalesCommandSectionType type;
  final List<SalesCommandItem> items;
  final int? totalCount;

  bool get isEmpty => items.isEmpty;
  int get count => totalCount ?? items.length;

  @override
  List<Object?> get props => [type, items, totalCount];
}

class SalesCommandSummary extends Equatable {
  const SalesCommandSummary({
    required this.sections,
    required this.updatedAt,
    required this.highPriorityCount,
    required this.mediumPriorityCount,
    required this.lowPriorityCount,
    required this.dueTodayCount,
    required this.overdueCount,
    required this.hotOpportunityCount,
    required this.atRiskCount,
    required this.teamPressureCount,
    this.isLimitedForRole = false,
  });

  final List<SalesCommandSection> sections;
  final DateTime updatedAt;
  final int highPriorityCount;
  final int mediumPriorityCount;
  final int lowPriorityCount;
  final int dueTodayCount;
  final int overdueCount;
  final int hotOpportunityCount;
  final int atRiskCount;
  final int teamPressureCount;
  final bool isLimitedForRole;

  int get totalCount {
    final visible = <String>{};
    for (final section in sections) {
      for (final item in section.items) {
        visible.add(item.recordKey);
      }
    }
    return visible.length;
  }

  SalesCommandSection section(SalesCommandSectionType type) {
    for (final section in sections) {
      if (section.type == type) {
        return section;
      }
    }
    return SalesCommandSection(type: type, items: const []);
  }

  @override
  List<Object?> get props => [
        sections,
        updatedAt,
        highPriorityCount,
        mediumPriorityCount,
        lowPriorityCount,
        dueTodayCount,
        overdueCount,
        hotOpportunityCount,
        atRiskCount,
        teamPressureCount,
        isLimitedForRole,
      ];
}
