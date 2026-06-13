import '../../../../core/constants/role_constants.dart';
import '../../../../core/intelligence/lead_nba_evaluator.dart';
import '../../../../core/intelligence/sales_attention_level.dart';
import '../../../../core/intelligence/sales_next_action_type.dart';
import '../../../appointments/domain/entities/appointment.dart';
import '../../../deals/domain/entities/deal.dart';
import '../../../leads/domain/entities/lead.dart';
import '../../../tasks/domain/entities/crm_task.dart';
import '../entities/sales_command_center.dart';
import 'dashboard_truth_rules.dart';

class SalesCommandCenterRules {
  const SalesCommandCenterRules({
    this.staleLeadDays = DashboardTruthRules.staleLeadDays,
    this.highPriorityStaleLeadDays = DashboardTruthRules.highPriorityStaleLeadDays,
    this.stuckDealDays = 14,
    this.feedbackWindowDays = 7,
    this.overloadedTaskThreshold = 3,
  });

  final int staleLeadDays;
  final int highPriorityStaleLeadDays;
  final int stuckDealDays;
  final int feedbackWindowDays;
  final int overloadedTaskThreshold;

  SalesCommandSummary build(SalesCommandCenterRuleInput input) {
    if (input.role == UserRole.viewer) {
      return SalesCommandSummary(
        sections: _sections(
          today: const [],
          hot: const [],
          overdueFollowUps: const SalesCommandSection(
            type: SalesCommandSectionType.overdueFollowUps,
            items: [],
          ),
          missedAppointments: const SalesCommandSection(
            type: SalesCommandSectionType.missedAppointments,
            items: [],
          ),
          overdueTasks: const SalesCommandSection(
            type: SalesCommandSectionType.overdueTasks,
            items: [],
          ),
          stuckDeals: const SalesCommandSection(
            type: SalesCommandSectionType.stuckDeals,
            items: [],
          ),
          risk: const [],
          pressure: const [],
          includeTeamPressure: false,
        ),
        updatedAt: input.now,
        highPriorityCount: 0,
        mediumPriorityCount: 0,
        lowPriorityCount: 0,
        dueTodayCount: 0,
        overdueCount: 0,
        hotOpportunityCount: 0,
        atRiskCount: 0,
        teamPressureCount: 0,
        isLimitedForRole: true,
      );
    }

    final todayCandidates = <SalesCommandItem>[];
    final hotCandidates = <SalesCommandItem>[];
    final riskCandidates = <SalesCommandItem>[];
    final pressureCandidates = <SalesCommandItem>[];

    if (input.includeLeads) {
      _addLeadCandidates(
        input,
        todayCandidates,
        hotCandidates,
        riskCandidates,
        pressureCandidates,
      );
    }
    if (input.includeTasks) {
      _addTaskCandidates(input, todayCandidates, riskCandidates);
      _addOverloadedAssignees(input, pressureCandidates);
    }
    if (input.includeDeals) {
      _addDealCandidates(input, todayCandidates, hotCandidates, riskCandidates);
    }
    if (input.includeAppointments) {
      _addAppointmentCandidates(input, todayCandidates, riskCandidates);
    }

    final today = _pickTodayPriorities(todayCandidates);
    final usedRecords = today.map((item) => item.recordKey).toSet();
    final hot = _pickSectionItems(
      hotCandidates,
      limit: 5,
      usedRecords: usedRecords,
    );
    usedRecords.addAll(hot.map((item) => item.recordKey));
    final risk = _pickSectionItems(
      riskCandidates,
      limit: 5,
      usedRecords: usedRecords,
    );
    final pressure = _pickSectionItems(
      pressureCandidates,
      limit: 4,
      usedRecords: const <String>{},
    );

    final allCandidates = _uniqueItems([
      ...todayCandidates,
      ...hotCandidates,
      ...riskCandidates,
      ...pressureCandidates,
    ]);
    final overdueFollowUps = _operationalGroupItems(
      SalesCommandSectionType.overdueFollowUps,
      riskCandidates,
      (item) => item.reason == DashboardAttentionReason.overdueFollowUp,
    );
    final missedAppointments = _operationalGroupItems(
      SalesCommandSectionType.missedAppointments,
      riskCandidates,
      (item) => item.reason == DashboardAttentionReason.appointmentMissed,
    );
    final overdueTasks = _operationalGroupItems(
      SalesCommandSectionType.overdueTasks,
      riskCandidates,
      (item) => item.reason == DashboardAttentionReason.overdueTask,
    );
    final stuckDeals = _operationalGroupItems(
      SalesCommandSectionType.stuckDeals,
      riskCandidates,
      (item) =>
          item.module == DashboardCommandModule.deal &&
          item.reason == DashboardAttentionReason.dealAtRisk,
    );
    final dueTodayFollowUpsCount = _uniqueRecordCount(
      todayCandidates.where((item) {
        return item.module == DashboardCommandModule.lead &&
            item.reason == DashboardAttentionReason.dueTodayFollowUp;
      }),
    );
    final hotLeadsCount = _uniqueRecordCount(
      hotCandidates.where((item) {
        return item.module == DashboardCommandModule.lead &&
            item.reason == DashboardAttentionReason.hotLead;
      }),
    );
    return SalesCommandSummary(
      sections: _sections(
        today: today,
        hot: hot,
        overdueFollowUps: overdueFollowUps,
        missedAppointments: missedAppointments,
        overdueTasks: overdueTasks,
        stuckDeals: stuckDeals,
        risk: risk,
        pressure: pressure,
        includeTeamPressure: _canSeeTeamPressure(input.role),
      ),
      updatedAt: input.now,
      highPriorityCount: allCandidates
          .where((item) => item.priority == DashboardPriority.high)
          .length,
      mediumPriorityCount: allCandidates
          .where((item) => item.priority == DashboardPriority.medium)
          .length,
      lowPriorityCount: allCandidates
          .where((item) => item.priority == DashboardPriority.low)
          .length,
      dueTodayCount: dueTodayFollowUpsCount,
      overdueCount: overdueFollowUps.count,
      hotOpportunityCount: hotLeadsCount,
      atRiskCount: stuckDeals.count,
      teamPressureCount: _uniqueItems(pressureCandidates).length,
    );
  }

  void _addLeadCandidates(
    SalesCommandCenterRuleInput input,
    List<SalesCommandItem> today,
    List<SalesCommandItem> hot,
    List<SalesCommandItem> risk,
    List<SalesCommandItem> pressure,
  ) {
    for (final lead in input.leads) {
      final decision = LeadNbaEvaluator.evaluate(
        LeadNbaInput(
          status: _leadStatusValue(lead.status),
          priority: _leadPriorityValue(lead.priority),
          isArchived: lead.isArchived,
          assignedTo: lead.assignedTo,
          canViewUnassignedLeads: input.canViewUnassignedLeads,
          createdAt: lead.createdAt,
          updatedAt: lead.updatedAt,
          lastContactAt: lead.lastContactAt,
          nextActionAt: lead.nextFollowUpAt,
          now: input.now,
          staleDays: staleLeadDays,
          highPriorityStaleDays: highPriorityStaleLeadDays,
        ),
      );

      if (!decision.isActionableNow) {
        continue;
      }

      final item = _leadItemForDecision(
        lead: lead,
        decision: decision,
      );

      switch (decision.nextActionType) {
        case SalesNextActionType.assignLead:
          today.add(item);
          pressure.add(item);
        case SalesNextActionType.followUp:
          today.add(item);
          if (decision.reason == 'overdueFollowUp') {
            risk.add(item);
          } else {
            hot.add(item);
          }
        case SalesNextActionType.contactLead:
        case SalesNextActionType.createDeal:
          today.add(item);
          hot.add(item);
        case SalesNextActionType.scheduleAppointment:
        case SalesNextActionType.createAppointment:
          hot.add(item);
        case SalesNextActionType.setNextStep:
          today.add(item);
          hot.add(item);
        case SalesNextActionType.reviewStaleLead:
          risk.add(item);
        case SalesNextActionType.none:
        case SalesNextActionType.futureFollowUp:
        case SalesNextActionType.managerReview:
        case SalesNextActionType.closeLost:
          break;
      }
    }
  }

  SalesCommandItem _leadItemForDecision({
    required Lead lead,
    required LeadNbaDecision decision,
  }) {
    final reason = _leadReasonForDecision(decision);
    final priority = _dashboardPriorityForDecision(lead, decision);
    final priorityBoost = _leadPriorityBoost(lead.priority);
    final statusBoost = _leadStatusBoost(lead.status);
    final dueAt = decision.dueAt?.toLocal();
    final relatedAt = decision.relatedAt?.toLocal();
    final ageDays = decision.ageDays;
    final score = _leadDecisionScore(
      decision: decision,
      lead: lead,
      priorityBoost: priorityBoost,
      statusBoost: statusBoost,
      ageDays: ageDays,
    );

    return _leadItem(
      lead: lead,
      reason: reason,
      priority: priority,
      dueAt: dueAt,
      relatedDate: relatedAt,
      sortDate: dueAt ?? relatedAt ?? lead.updatedAt,
      score: score,
      ageDays: ageDays,
      actionType: decision.nextActionType == SalesNextActionType.assignLead
          ? DashboardCommandActionType.assignLead
          : DashboardCommandActionType.openLead,
    );
  }

  DashboardAttentionReason _leadReasonForDecision(LeadNbaDecision decision) {
    switch (decision.nextActionType) {
      case SalesNextActionType.assignLead:
        return DashboardAttentionReason.unassignedLead;
      case SalesNextActionType.followUp:
        return decision.reason == 'overdueFollowUp'
            ? DashboardAttentionReason.overdueFollowUp
            : DashboardAttentionReason.dueTodayFollowUp;
      case SalesNextActionType.reviewStaleLead:
        return DashboardAttentionReason.staleLead;
      case SalesNextActionType.contactLead:
      case SalesNextActionType.scheduleAppointment:
      case SalesNextActionType.createAppointment:
      case SalesNextActionType.createDeal:
      case SalesNextActionType.setNextStep:
      case SalesNextActionType.futureFollowUp:
      case SalesNextActionType.managerReview:
      case SalesNextActionType.closeLost:
      case SalesNextActionType.none:
        return DashboardAttentionReason.hotLead;
    }
  }

  DashboardPriority _dashboardPriorityForDecision(
    Lead lead,
    LeadNbaDecision decision,
  ) {
    if (decision.attentionLevel == SalesAttentionLevel.urgent ||
        decision.attentionLevel == SalesAttentionLevel.manager ||
        lead.priority == LeadPriority.high) {
      return DashboardPriority.high;
    }
    if (decision.attentionLevel == SalesAttentionLevel.info) {
      return DashboardPriority.low;
    }
    return DashboardPriority.medium;
  }

  int _leadDecisionScore({
    required LeadNbaDecision decision,
    required Lead lead,
    required int priorityBoost,
    required int statusBoost,
    int? ageDays,
  }) {
    final base = switch (decision.nextActionType) {
      SalesNextActionType.followUp =>
        decision.reason == 'overdueFollowUp' ? 94 : 84,
      SalesNextActionType.assignLead => 82,
      SalesNextActionType.contactLead => 80,
      SalesNextActionType.createDeal => 78,
      SalesNextActionType.scheduleAppointment ||
      SalesNextActionType.createAppointment => 74,
      SalesNextActionType.setNextStep => 72,
      SalesNextActionType.reviewStaleLead => 64,
      SalesNextActionType.managerReview => 86,
      SalesNextActionType.closeLost => 58,
      SalesNextActionType.none || SalesNextActionType.futureFollowUp => 0,
    };
    return base +
        priorityBoost +
        statusBoost +
        (ageDays == null ? 0 : ageDays.clamp(0, 12).toInt());
  }

  void _addTaskCandidates(
    SalesCommandCenterRuleInput input,
    List<SalesCommandItem> today,
    List<SalesCommandItem> risk,
  ) {
    for (final task in input.tasks) {
      if (!DashboardTruthRules.isOpenTask(task) || task.dueDate == null) {
        continue;
      }
      final dueAt = task.dueDate!.toLocal();
      final dueDay = DashboardTruthRules.dateOnly(dueAt);
      final boost = _taskPriorityBoost(task.priority);

      if (dueDay.isBefore(input.today)) {
        final item = _taskItem(
          task: task,
          reason: DashboardAttentionReason.overdueTask,
          priority: task.priority == TaskPriority.high
              ? DashboardPriority.high
              : DashboardPriority.medium,
          dueAt: dueAt,
          score: 90 +
              boost +
              input.today.difference(dueDay).inDays.clamp(0, 8).toInt(),
          ageDays: input.today.difference(dueDay).inDays,
        );
        today.add(item);
        risk.add(item);
      } else if (dueDay == input.today) {
        today.add(
          _taskItem(
            task: task,
            reason: DashboardAttentionReason.dueTodayTask,
            priority: task.priority == TaskPriority.high
                ? DashboardPriority.high
                : DashboardPriority.medium,
            dueAt: dueAt,
            score: 76 + boost,
          ),
        );
      }
    }
  }

  void _addDealCandidates(
    SalesCommandCenterRuleInput input,
    List<SalesCommandItem> today,
    List<SalesCommandItem> hot,
    List<SalesCommandItem> risk,
  ) {
    for (final deal in input.deals) {
      if (!DashboardTruthRules.isOpenDeal(deal)) {
        continue;
      }

      final closingDate = deal.closingDate?.toLocal();
      final updatedAt = deal.updatedAt?.toLocal() ?? deal.createdAt?.toLocal();
      final stageBoost = _dealStageBoost(deal.stage);
      final valueBoost = deal.expectedValue > 0 ? 6 : 0;

      if (closingDate != null &&
          !_dateOnly(closingDate).isAfter(input.today)) {
        final item = _dealItem(
          deal: deal,
          reason: DashboardAttentionReason.dealAtRisk,
          priority: DashboardPriority.high,
          dueAt: closingDate,
          sortDate: closingDate,
          score: 88 + stageBoost + valueBoost,
          ageDays: input.today.difference(_dateOnly(closingDate)).inDays,
        );
        today.add(item);
        risk.add(item);
        continue;
      }

      if (updatedAt != null) {
        final ageDays = input.now.difference(updatedAt).inDays;
        if (DashboardTruthRules.isDealAtRisk(
          deal,
          input.now,
          staleDays: stuckDealDays,
        )) {
          risk.add(
            _dealItem(
              deal: deal,
              reason: DashboardAttentionReason.dealAtRisk,
              priority: DashboardPriority.medium,
              relatedDate: updatedAt,
              sortDate: updatedAt,
              score: 66 +
                  stageBoost +
                  valueBoost +
                  ageDays.clamp(0, 12).toInt(),
              ageDays: ageDays,
            ),
          );
          continue;
        }
      }

      if (deal.stage == DealStage.qualified ||
          deal.stage == DealStage.proposal ||
          deal.stage == DealStage.negotiation ||
          deal.expectedValue > 0) {
        hot.add(
          _dealItem(
            deal: deal,
            reason: DashboardAttentionReason.hotLead,
            priority: deal.stage == DealStage.negotiation
                ? DashboardPriority.high
                : DashboardPriority.medium,
            relatedDate: updatedAt,
            sortDate: updatedAt,
            score: 68 + stageBoost + valueBoost,
          ),
        );
      }
    }
  }

  void _addAppointmentCandidates(
    SalesCommandCenterRuleInput input,
    List<SalesCommandItem> today,
    List<SalesCommandItem> risk,
  ) {
    for (final appointment in input.appointments) {
      final scheduledAt = appointment.scheduledAt?.toLocal();
      final endAt = (appointment.endAt ?? appointment.scheduledAt)?.toLocal();
      final isOpenStatus = appointment.status == AppointmentStatus.scheduled ||
          appointment.status == AppointmentStatus.rescheduled;

      if (DashboardTruthRules.isMissedAppointment(appointment, input.now)) {
        final ageDays = endAt == null ? 0 : input.now.difference(endAt).inDays;
        if (ageDays > feedbackWindowDays) {
          continue;
        }
        final item = _appointmentItem(
          appointment: appointment,
          reason: DashboardAttentionReason.appointmentMissed,
          priority: DashboardPriority.medium,
          dueAt: scheduledAt,
          sortDate: scheduledAt ?? endAt,
          score: 62 - ageDays.clamp(0, 4).toInt(),
          ageDays: endAt == null ? null : ageDays,
        );
        today.add(item);
        risk.add(item);
        continue;
      }

      if (isOpenStatus &&
          scheduledAt != null &&
          !scheduledAt.isAfter(input.now) &&
          (endAt == null || !endAt.isBefore(input.now))) {
        today.add(
          _appointmentItem(
            appointment: appointment,
            reason: DashboardAttentionReason.appointmentDueNow,
            priority: DashboardPriority.medium,
            dueAt: scheduledAt,
            sortDate: scheduledAt,
            score: 60,
          ),
        );
        continue;
      }

      if (isOpenStatus &&
          scheduledAt != null &&
          _dateOnly(scheduledAt) == input.today &&
          scheduledAt.isAfter(input.now)) {
        today.add(
          _appointmentItem(
            appointment: appointment,
            reason: DashboardAttentionReason.appointmentUpcoming,
            priority: DashboardPriority.low,
            dueAt: scheduledAt,
            sortDate: scheduledAt,
            score: 44,
          ),
        );
        continue;
      }

      if (appointment.status == AppointmentStatus.completed &&
          appointment.outcomeNotes.trim().isEmpty &&
          endAt != null &&
          endAt.isBefore(input.now) &&
          input.now.difference(endAt).inDays <= feedbackWindowDays) {
        risk.add(
          _appointmentItem(
            appointment: appointment,
            reason: DashboardAttentionReason.appointmentNeedsFeedback,
            priority: DashboardPriority.medium,
            dueAt: endAt,
            sortDate: endAt,
            score: 58,
            ageDays: input.now.difference(endAt).inDays,
          ),
        );
      }
    }
  }

  void _addOverloadedAssignees(
    SalesCommandCenterRuleInput input,
    List<SalesCommandItem> pressure,
  ) {
    if (!_canSeeTeamPressure(input.role)) {
      return;
    }

    final overdueByAssignee = <String, List<CrmTask>>{};
    for (final task in input.tasks) {
      if (!DashboardTruthRules.isOpenTask(task) || task.dueDate == null) {
        continue;
      }
      final assignee = task.assignedTo.trim();
      if (assignee.isEmpty ||
          !_dateOnly(task.dueDate!.toLocal()).isBefore(input.today)) {
        continue;
      }
      overdueByAssignee.putIfAbsent(assignee, () => <CrmTask>[]).add(task);
    }

    for (final entry in overdueByAssignee.entries) {
      if (entry.value.length < overloadedTaskThreshold) {
        continue;
      }
      entry.value.sort((a, b) {
        final aDate = a.dueDate ?? DateTime(9999);
        final bDate = b.dueDate ?? DateTime(9999);
        return aDate.compareTo(bDate);
      });
      final firstTask = entry.value.first;
      final oldestDue = firstTask.dueDate?.toLocal();
      pressure.add(
        SalesCommandItem(
          id: 'user:${entry.key}:overdue-load',
          module: DashboardCommandModule.user,
          recordId: entry.key,
          title: _fallback(firstTask.assignedToName, entry.key),
          subtitle: firstTask.teamName,
          reason: DashboardAttentionReason.overloadedAssignee,
          priority: entry.value.length >= overloadedTaskThreshold + 2
              ? DashboardPriority.high
              : DashboardPriority.medium,
          dueAt: oldestDue,
          assignedTo: entry.key,
          assignedToName: firstTask.assignedToName,
          teamId: firstTask.teamId,
          managerId: firstTask.managerId,
          actionType: DashboardCommandActionType.openTasks,
          sortDate: oldestDue,
          count: entry.value.length,
          score: 70 + entry.value.length.clamp(0, 8).toInt(),
          ageDays: oldestDue == null
              ? null
              : input.today.difference(_dateOnly(oldestDue)).inDays,
        ),
      );
    }
  }

  List<SalesCommandItem> _uniqueItems(Iterable<SalesCommandItem> items) {
    final byId = <String, SalesCommandItem>{};
    for (final item in items) {
      byId[item.id] = item;
    }
    return byId.values.toList();
  }

  int _uniqueRecordCount(Iterable<SalesCommandItem> items) {
    return items.map((item) => item.recordKey).toSet().length;
  }

  List<SalesCommandItem> _pickTodayPriorities(List<SalesCommandItem> items) {
    final selected = <SalesCommandItem>[];
    final usedRecords = <String>{};
    var appointmentCount = 0;
    var taskAndFollowUpCount = 0;
    final sorted = [...items]..sort(_compareCommandItems);

    for (final item in sorted) {
      if (selected.length >= 5 || !usedRecords.add(item.recordKey)) {
        continue;
      }
      if (item.module == DashboardCommandModule.appointment) {
        if (appointmentCount >= 2) {
          continue;
        }
        appointmentCount++;
      }
      if (item.module == DashboardCommandModule.task ||
          item.reason == DashboardAttentionReason.overdueFollowUp ||
          item.reason == DashboardAttentionReason.dueTodayFollowUp) {
        if (taskAndFollowUpCount >= 2) {
          continue;
        }
        taskAndFollowUpCount++;
      }
      selected.add(item);
    }
    return selected;
  }

  List<SalesCommandItem> _pickSectionItems(
    List<SalesCommandItem> candidates, {
    required int limit,
    required Set<String> usedRecords,
  }) {
    final selected = <SalesCommandItem>[];
    final localUsed = <String>{};
    final sorted = [...candidates]..sort(_compareCommandItems);
    for (final item in sorted) {
      if (selected.length >= limit ||
          usedRecords.contains(item.recordKey) ||
          !localUsed.add(item.recordKey)) {
        continue;
      }
      selected.add(item);
    }
    return selected;
  }

  SalesCommandSection _operationalGroupItems(
    SalesCommandSectionType type,
    List<SalesCommandItem> candidates,
    bool Function(SalesCommandItem item) test,
  ) {
    final matching = candidates.where(test).toList()..sort(_compareCommandItems);
    final selected = <SalesCommandItem>[];
    final usedRecords = <String>{};
    for (final item in matching) {
      if (selected.length >= 5 || !usedRecords.add(item.recordKey)) {
        continue;
      }
      selected.add(item);
    }
    return SalesCommandSection(
      type: type,
      items: selected,
      totalCount: matching.map((item) => item.recordKey).toSet().length,
    );
  }

  SalesCommandItem _leadItem({
    required Lead lead,
    required DashboardAttentionReason reason,
    required DashboardPriority priority,
    required int score,
    DateTime? dueAt,
    DateTime? relatedDate,
    DateTime? sortDate,
    int? ageDays,
    DashboardCommandActionType actionType = DashboardCommandActionType.openLead,
  }) {
    return SalesCommandItem(
      id: 'lead:${lead.id}:${reason.name}',
      module: DashboardCommandModule.lead,
      recordId: lead.id,
      title: _fallback(lead.fullName, lead.phone),
      subtitle: _fallback(lead.phone, lead.email),
      reason: reason,
      priority: priority,
      dueAt: dueAt,
      relatedDate: relatedDate,
      assignedTo: lead.assignedTo,
      assignedToName: lead.assignedToName,
      teamId: lead.teamId,
      managerId: lead.managerId,
      actionType: actionType,
      createdAt: lead.createdAt,
      sortDate: sortDate ?? lead.updatedAt,
      score: score,
      ageDays: ageDays,
    );
  }

  SalesCommandItem _taskItem({
    required CrmTask task,
    required DashboardAttentionReason reason,
    required DashboardPriority priority,
    required int score,
    DateTime? dueAt,
    int? ageDays,
  }) {
    return SalesCommandItem(
      id: 'task:${task.id}:${reason.name}',
      module: DashboardCommandModule.task,
      recordId: task.id,
      title: task.title,
      subtitle: _fallback(task.relatedTitle, task.assignedToName),
      reason: reason,
      priority: priority,
      dueAt: dueAt,
      assignedTo: task.assignedTo,
      assignedToName: task.assignedToName,
      teamId: task.teamId,
      managerId: task.managerId,
      actionType: DashboardCommandActionType.openTask,
      createdAt: task.createdAt,
      sortDate: dueAt ?? task.updatedAt ?? task.createdAt,
      score: score,
      ageDays: ageDays,
      dedupeKey: _taskBusinessRecordKey(task),
    );
  }

  String? _taskBusinessRecordKey(CrmTask task) {
    final relatedId = task.relatedId.trim();
    if (relatedId.isEmpty) {
      return null;
    }
    return switch (task.relatedType) {
      TaskRelatedType.lead => 'lead:$relatedId',
      TaskRelatedType.client => 'client:$relatedId',
      TaskRelatedType.deal => 'deal:$relatedId',
      TaskRelatedType.property => 'property:$relatedId',
      TaskRelatedType.general => null,
    };
  }

  SalesCommandItem _appointmentItem({
    required Appointment appointment,
    required DashboardAttentionReason reason,
    required DashboardPriority priority,
    required int score,
    DateTime? dueAt,
    DateTime? sortDate,
    int? ageDays,
  }) {
    return SalesCommandItem(
      id: 'appointment:${appointment.id}:${reason.name}',
      module: DashboardCommandModule.appointment,
      recordId: appointment.id,
      title: appointment.title,
      subtitle: _fallback(
        appointment.relatedTitle,
        appointment.assignedToName,
      ),
      reason: reason,
      priority: priority,
      dueAt: dueAt,
      assignedTo: appointment.assignedTo,
      assignedToName: appointment.assignedToName,
      teamId: appointment.teamId,
      managerId: appointment.managerId,
      actionType: DashboardCommandActionType.openAppointment,
      createdAt: appointment.createdAt,
      sortDate: sortDate ?? appointment.scheduledAt ?? appointment.updatedAt,
      score: score,
      ageDays: ageDays,
    );
  }

  SalesCommandItem _dealItem({
    required Deal deal,
    required DashboardAttentionReason reason,
    required DashboardPriority priority,
    required int score,
    DateTime? dueAt,
    DateTime? relatedDate,
    DateTime? sortDate,
    int? ageDays,
  }) {
    return SalesCommandItem(
      id: 'deal:${deal.id}:${reason.name}',
      module: DashboardCommandModule.deal,
      recordId: deal.id,
      title: _fallback(deal.clientName, deal.propertyTitle),
      subtitle: _fallback(deal.propertyTitle, deal.propertyLocation),
      reason: reason,
      priority: priority,
      dueAt: dueAt,
      relatedDate: relatedDate,
      assignedTo: deal.assignedTo,
      assignedToName: deal.assignedToName,
      teamId: deal.teamId,
      managerId: deal.managerId,
      actionType: DashboardCommandActionType.openDeal,
      createdAt: deal.createdAt,
      sortDate: sortDate ?? deal.updatedAt ?? deal.createdAt,
      score: score,
      ageDays: ageDays,
    );
  }
}

class SalesCommandCenterRuleInput {
  const SalesCommandCenterRuleInput({
    required this.role,
    required this.now,
    required this.leads,
    required this.tasks,
    required this.deals,
    required this.appointments,
    required this.includeLeads,
    required this.includeTasks,
    required this.includeDeals,
    required this.includeAppointments,
    required this.canViewUnassignedLeads,
  });

  final UserRole role;
  final DateTime now;
  final List<Lead> leads;
  final List<CrmTask> tasks;
  final List<Deal> deals;
  final List<Appointment> appointments;
  final bool includeLeads;
  final bool includeTasks;
  final bool includeDeals;
  final bool includeAppointments;
  final bool canViewUnassignedLeads;

  DateTime get today => _dateOnly(now);
}

List<SalesCommandSection> _sections({
  required List<SalesCommandItem> today,
  required List<SalesCommandItem> hot,
  required SalesCommandSection overdueFollowUps,
  required SalesCommandSection missedAppointments,
  required SalesCommandSection overdueTasks,
  required SalesCommandSection stuckDeals,
  required List<SalesCommandItem> risk,
  required List<SalesCommandItem> pressure,
  required bool includeTeamPressure,
}) {
  return [
    SalesCommandSection(
      type: SalesCommandSectionType.todayPriorities,
      items: today,
    ),
    SalesCommandSection(
      type: SalesCommandSectionType.hotOpportunities,
      items: hot,
    ),
    SalesCommandSection(
      type: SalesCommandSectionType.overdueFollowUps,
      items: overdueFollowUps.items,
      totalCount: overdueFollowUps.count,
    ),
    SalesCommandSection(
      type: SalesCommandSectionType.missedAppointments,
      items: missedAppointments.items,
      totalCount: missedAppointments.count,
    ),
    SalesCommandSection(
      type: SalesCommandSectionType.overdueTasks,
      items: overdueTasks.items,
      totalCount: overdueTasks.count,
    ),
    SalesCommandSection(
      type: SalesCommandSectionType.stuckDeals,
      items: stuckDeals.items,
      totalCount: stuckDeals.count,
    ),
    SalesCommandSection(
      type: SalesCommandSectionType.atRisk,
      items: risk,
    ),
    if (includeTeamPressure)
      SalesCommandSection(
        type: SalesCommandSectionType.teamPressure,
        items: pressure,
      ),
  ];
}

bool _canSeeTeamPressure(UserRole role) {
  return role == UserRole.admin || role == UserRole.manager;
}

DateTime _dateOnly(DateTime value) {
  final local = value.toLocal();
  return DateTime(local.year, local.month, local.day);
}

DateTime? _latestDate(List<DateTime?> dates) {
  DateTime? latest;
  for (final date in dates) {
    if (date == null) {
      continue;
    }
    if (latest == null || date.isAfter(latest)) {
      latest = date;
    }
  }
  return latest;
}

String _fallback(String value, String fallback) {
  final trimmed = value.trim();
  if (trimmed.isNotEmpty) {
    return trimmed;
  }
  return fallback.trim();
}

String _leadStatusValue(LeadStatus status) {
  return switch (status) {
    LeadStatus.newLead => 'new',
    LeadStatus.contacted => 'contacted',
    LeadStatus.interested => 'interested',
    LeadStatus.visitScheduled => 'visitScheduled',
    LeadStatus.negotiation => 'negotiation',
    LeadStatus.won => 'won',
    LeadStatus.lost => 'lost',
  };
}

String _leadPriorityValue(LeadPriority priority) {
  return switch (priority) {
    LeadPriority.low => 'low',
    LeadPriority.medium => 'medium',
    LeadPriority.high => 'high',
  };
}

int _leadPriorityBoost(LeadPriority priority) {
  return switch (priority) {
    LeadPriority.high => 14,
    LeadPriority.medium => 6,
    LeadPriority.low => 0,
  };
}

int _leadStatusBoost(LeadStatus status) {
  return switch (status) {
    LeadStatus.negotiation => 12,
    LeadStatus.visitScheduled => 10,
    LeadStatus.interested => 8,
    LeadStatus.contacted => 4,
    LeadStatus.newLead => 2,
    LeadStatus.won || LeadStatus.lost => 0,
  };
}

int _taskPriorityBoost(TaskPriority priority) {
  return switch (priority) {
    TaskPriority.high => 12,
    TaskPriority.medium => 5,
    TaskPriority.low => 0,
  };
}

int _dealStageBoost(DealStage stage) {
  return switch (stage) {
    DealStage.negotiation => 12,
    DealStage.proposal => 9,
    DealStage.qualified => 6,
    DealStage.newDeal => 2,
    DealStage.won || DealStage.lost => 0,
  };
}

int _compareCommandItems(SalesCommandItem a, SalesCommandItem b) {
  final score = b.score.compareTo(a.score);
  if (score != 0) {
    return score;
  }
  final priority = _priorityRank(b.priority).compareTo(_priorityRank(a.priority));
  if (priority != 0) {
    return priority;
  }
  final aDate = a.sortDate ?? a.dueAt ?? a.relatedDate ?? DateTime(9999);
  final bDate = b.sortDate ?? b.dueAt ?? b.relatedDate ?? DateTime(9999);
  return aDate.compareTo(bDate);
}

int _priorityRank(DashboardPriority priority) {
  return switch (priority) {
    DashboardPriority.high => 3,
    DashboardPriority.medium => 2,
    DashboardPriority.low => 1,
  };
}
