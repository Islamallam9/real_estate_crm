import '../../../../core/constants/role_constants.dart';
import '../../../appointments/domain/entities/appointment.dart';
import '../../../deals/domain/entities/deal.dart';
import '../../../leads/domain/entities/lead.dart';
import '../../../properties/domain/entities/property.dart';
import '../../../tasks/domain/entities/crm_task.dart';
import '../../../users/domain/entities/user_profile.dart';
import '../entities/dashboard_analytics.dart';
import 'dashboard_truth_rules.dart';

class DashboardAnalyticsRules {
  const DashboardAnalyticsRules({
    this.trendDays = 7,
    this.performanceDays = 30,
    this.stuckDealDays = 14,
  });

  final int trendDays;
  final int performanceDays;
  final int stuckDealDays;

  DashboardAnalytics build(DashboardAnalyticsInput input) {
    final activeLeads =
        input.leads.where(DashboardTruthRules.isActiveLead).toList();
    final newLeadsToday = input.leads.where((lead) {
      return _dateOnly(lead.createdAt) == input.today;
    }).toList();
    final hotOpportunities =
        input.leads.where(DashboardTruthRules.isHotLead).toList();
    final dueTodayFollowUps = input.leads.where((lead) {
      final date = lead.nextFollowUpAt;
      return date != null && _dateOnly(date) == input.today;
    }).toList();
    final overdueFollowUps = input.leads.where((lead) {
      return DashboardTruthRules.isOverdueFollowUpLead(lead, input.today);
    }).toList();
    final overdueTasks = input.tasks.where((task) {
      return DashboardTruthRules.isOverdueTask(task, input.today);
    }).toList();
    final todayTasks = input.tasks.where((task) {
      final date = task.dueDate;
      return DashboardTruthRules.isOpenTask(task) &&
          date != null &&
          _dateOnly(date) == input.today;
    }).toList();
    final openTasks =
        input.tasks.where(DashboardTruthRules.isOpenTask).toList();
    final todayAppointments = input.appointments.where((appointment) {
      final date = appointment.scheduledAt;
      return date != null && _dateOnly(date) == input.today;
    }).toList();
    final missedAppointments = input.appointments.where((appointment) {
      return DashboardTruthRules.isMissedAppointment(appointment, input.now);
    }).toList();
    final openDeals =
        input.deals.where(DashboardTruthRules.isOpenDeal).toList();
    final stuckDeals = openDeals.where((deal) {
      return DashboardTruthRules.isDealAtRisk(
        deal,
        input.now,
        staleDays: stuckDealDays,
      );
    }).toList();
    final wonDealsThisMonth = input.deals.where((deal) {
      final closedAt = _dealClosedAt(deal)?.toLocal();
      return deal.stage == DealStage.won &&
          closedAt != null &&
          closedAt.year == input.now.year &&
          closedAt.month == input.now.month;
    }).toList();
    final unassignedLeads = activeLeads.where((lead) {
      return lead.assignedTo.trim().isEmpty;
    }).toList();
    final teamWorkload = activeLeads.length + openTasks.length + openDeals.length;
    final activeProperties = input.properties.where((property) {
      return property.status == PropertyStatus.available;
    }).toList();

    final leadSparkline = _countsByTrailingDays(
      input.now,
      input.leads.map((lead) => lead.createdAt),
      trendDays,
    );

    return DashboardAnalytics(
      role: input.role,
      metrics: [
        if (input.includeLeads)
          DashboardKpiMetric(
            type: DashboardKpiType.activeLeads,
            value: activeLeads.length,
            valueLabel: activeLeads.length.toString(),
            sparkline: leadSparkline,
            trendPercent: _trendPercent(
              _countThisWindow(input.now, input.leads.map((lead) => lead.createdAt)),
              _countPreviousWindow(input.now, input.leads.map((lead) => lead.createdAt)),
            ),
          ),
        if (input.includeLeads)
          DashboardKpiMetric(
            type: DashboardKpiType.newLeadsToday,
            value: newLeadsToday.length,
            valueLabel: newLeadsToday.length.toString(),
            sparkline: _countsByTrailingDays(
              input.now,
              input.leads.map((lead) => lead.createdAt),
              trendDays,
            ),
            trendPercent: _trendPercent(
              _countThisWindow(input.now, input.leads.map((lead) => lead.createdAt)),
              _countPreviousWindow(input.now, input.leads.map((lead) => lead.createdAt)),
            ),
          ),
        if (input.includeLeads)
          DashboardKpiMetric(
            type: DashboardKpiType.hotOpportunities,
            value: hotOpportunities.length,
            valueLabel: hotOpportunities.length.toString(),
            sparkline: _countsByTrailingDays(
              input.now,
              hotOpportunities.map((lead) => lead.updatedAt),
              trendDays,
            ),
            trendPercent: _trendPercent(
              _countThisWindow(input.now, hotOpportunities.map((lead) => lead.updatedAt)),
              _countPreviousWindow(input.now, hotOpportunities.map((lead) => lead.updatedAt)),
            ),
          ),
        if (input.includeLeads)
          DashboardKpiMetric(
            type: DashboardKpiType.dueTodayFollowUps,
            value: dueTodayFollowUps.length,
            valueLabel: dueTodayFollowUps.length.toString(),
            sparkline: _countsByTrailingDays(
              input.now,
              input.leads.map((lead) => lead.nextFollowUpAt),
              trendDays,
            ),
            trendPercent: _trendPercent(
              _countThisWindow(input.now, input.leads.map((lead) => lead.nextFollowUpAt)),
              _countPreviousWindow(input.now, input.leads.map((lead) => lead.nextFollowUpAt)),
            ),
          ),
        if (input.includeLeads)
          DashboardKpiMetric(
            type: DashboardKpiType.overdueFollowUps,
            value: overdueFollowUps.length,
            valueLabel: overdueFollowUps.length.toString(),
            sparkline: _countsByTrailingDays(
              input.now,
              overdueFollowUps.map((lead) => lead.nextFollowUpAt),
              trendDays,
            ),
            trendPercent: _trendPercent(
              _countThisWindow(input.now, overdueFollowUps.map((lead) => lead.nextFollowUpAt)),
              _countPreviousWindow(input.now, overdueFollowUps.map((lead) => lead.nextFollowUpAt)),
            ),
          ),
        if (input.includeLeads || input.includeTasks)
          DashboardKpiMetric(
            type: DashboardKpiType.overdueActions,
            value: overdueFollowUps.length + overdueTasks.length,
            valueLabel: (overdueFollowUps.length + overdueTasks.length).toString(),
            sparkline: _countsByTrailingDays(
              input.now,
              [
                ...overdueFollowUps.map((lead) => lead.nextFollowUpAt),
                ...overdueTasks.map((task) => task.dueDate),
              ],
              trendDays,
            ),
            trendPercent: _trendPercent(
              _countThisWindow(
                input.now,
                [
                  ...overdueFollowUps.map((lead) => lead.nextFollowUpAt),
                  ...overdueTasks.map((task) => task.dueDate),
                ],
              ),
              _countPreviousWindow(
                input.now,
                [
                  ...overdueFollowUps.map((lead) => lead.nextFollowUpAt),
                  ...overdueTasks.map((task) => task.dueDate),
                ],
              ),
            ),
          ),
        if (input.includeAppointments)
          DashboardKpiMetric(
            type: DashboardKpiType.appointmentsToday,
            value: todayAppointments.length,
            valueLabel: todayAppointments.length.toString(),
            sparkline: _countsByTrailingDays(
              input.now,
              input.appointments.map((appointment) => appointment.scheduledAt),
              trendDays,
            ),
            trendPercent: _trendPercent(
              _countThisWindow(input.now, input.appointments.map((appointment) => appointment.scheduledAt)),
              _countPreviousWindow(input.now, input.appointments.map((appointment) => appointment.scheduledAt)),
            ),
          ),
        if (input.includeAppointments)
          DashboardKpiMetric(
            type: DashboardKpiType.missedAppointments,
            value: missedAppointments.length,
            valueLabel: missedAppointments.length.toString(),
            sparkline: _countsByTrailingDays(
              input.now,
              missedAppointments.map((appointment) => appointment.scheduledAt),
              trendDays,
            ),
            trendPercent: _trendPercent(
              _countThisWindow(input.now, missedAppointments.map((appointment) => appointment.scheduledAt)),
              _countPreviousWindow(input.now, missedAppointments.map((appointment) => appointment.scheduledAt)),
            ),
          ),
        if (input.includeTasks)
          DashboardKpiMetric(
            type: DashboardKpiType.overdueTasks,
            value: overdueTasks.length,
            valueLabel: overdueTasks.length.toString(),
            sparkline: _countsByTrailingDays(
              input.now,
              overdueTasks.map((task) => task.dueDate),
              trendDays,
            ),
            trendPercent: _trendPercent(
              _countThisWindow(input.now, overdueTasks.map((task) => task.dueDate)),
              _countPreviousWindow(input.now, overdueTasks.map((task) => task.dueDate)),
            ),
          ),
        if (input.includeDeals && openDeals.any((deal) => deal.expectedValue > 0))
          DashboardKpiMetric(
            type: DashboardKpiType.expectedPipelineValue,
            value: openDeals.fold<num>(0, (sum, deal) => sum + deal.expectedValue),
            valueLabel: '',
            sparkline: _valueByTrailingDays(
              input.now,
              openDeals,
              trendDays,
            ),
            trendPercent: _trendPercent(
              _valueThisWindow(input.now, openDeals),
              _valuePreviousWindow(input.now, openDeals),
            ),
          )
        else if (input.includeDeals)
          DashboardKpiMetric(
            type: DashboardKpiType.pipelineDeals,
            value: openDeals.length,
            valueLabel: openDeals.length.toString(),
            sparkline: _countsByTrailingDays(
              input.now,
              openDeals.map((deal) => deal.updatedAt ?? deal.createdAt),
              trendDays,
            ),
            trendPercent: _trendPercent(
              _countThisWindow(input.now, openDeals.map((deal) => deal.updatedAt ?? deal.createdAt)),
              _countPreviousWindow(input.now, openDeals.map((deal) => deal.updatedAt ?? deal.createdAt)),
            ),
          ),
        if (input.includeDeals && openDeals.any((deal) => deal.commission > 0))
          DashboardKpiMetric(
            type: DashboardKpiType.expectedCommission,
            value: openDeals.fold<num>(0, (sum, deal) => sum + deal.commission),
            valueLabel: '',
            sparkline: _commissionByTrailingDays(input.now, openDeals, trendDays),
            trendPercent: _trendPercent(
              _commissionThisWindow(input.now, openDeals),
              _commissionPreviousWindow(input.now, openDeals),
            ),
          ),
        if (input.includeDeals)
          DashboardKpiMetric(
            type: DashboardKpiType.wonDealsThisMonth,
            value: wonDealsThisMonth.length,
            valueLabel: wonDealsThisMonth.length.toString(),
            sparkline: _countsByTrailingDays(
              input.now,
              wonDealsThisMonth.map(_dealClosedAt),
              trendDays,
            ),
            trendPercent: _trendPercent(
              _countThisWindow(input.now, wonDealsThisMonth.map(_dealClosedAt)),
              _countPreviousWindow(input.now, wonDealsThisMonth.map(_dealClosedAt)),
            ),
          ),
        if (input.includeDeals)
          DashboardKpiMetric(
            type: DashboardKpiType.stuckDeals,
            value: stuckDeals.length,
            valueLabel: stuckDeals.length.toString(),
            sparkline: _countsByTrailingDays(
              input.now,
              stuckDeals.map((deal) => deal.updatedAt ?? deal.createdAt),
              trendDays,
            ),
            trendPercent: _trendPercent(
              _countThisWindow(input.now, stuckDeals.map((deal) => deal.updatedAt ?? deal.createdAt)),
              _countPreviousWindow(input.now, stuckDeals.map((deal) => deal.updatedAt ?? deal.createdAt)),
            ),
          ),
        if (input.includeLeads && input.canViewUnassignedLeads)
          DashboardKpiMetric(
            type: DashboardKpiType.unassignedLeads,
            value: unassignedLeads.length,
            valueLabel: unassignedLeads.length.toString(),
            sparkline: _countsByTrailingDays(
              input.now,
              unassignedLeads.map((lead) => lead.createdAt),
              trendDays,
            ),
            trendPercent: _trendPercent(
              _countThisWindow(input.now, unassignedLeads.map((lead) => lead.createdAt)),
              _countPreviousWindow(input.now, unassignedLeads.map((lead) => lead.createdAt)),
            ),
          ),
        if (input.role == UserRole.admin || input.role == UserRole.manager)
          DashboardKpiMetric(
            type: DashboardKpiType.teamWorkload,
            value: teamWorkload,
            valueLabel: teamWorkload.toString(),
            sparkline: _countsByTrailingDays(
              input.now,
              [
                ...input.leads.map((lead) => lead.updatedAt),
                ...input.tasks.map((task) => task.dueDate ?? task.updatedAt ?? task.createdAt),
                ...input.deals.map((deal) => deal.updatedAt ?? deal.createdAt),
              ],
              trendDays,
            ),
            trendPercent: _trendPercent(
              _countThisWindow(
                input.now,
                [
                  ...input.leads.map((lead) => lead.updatedAt),
                  ...input.tasks.map((task) => task.dueDate ?? task.updatedAt ?? task.createdAt),
                  ...input.deals.map((deal) => deal.updatedAt ?? deal.createdAt),
                ],
              ),
              _countPreviousWindow(
                input.now,
                [
                  ...input.leads.map((lead) => lead.updatedAt),
                  ...input.tasks.map((task) => task.dueDate ?? task.updatedAt ?? task.createdAt),
                  ...input.deals.map((deal) => deal.updatedAt ?? deal.createdAt),
                ],
              ),
            ),
          ),
        if (input.includeProperties)
          DashboardKpiMetric(
            type: DashboardKpiType.activeProperties,
            value: activeProperties.length,
            valueLabel: activeProperties.length.toString(),
            sparkline: _countsByTrailingDays(
              input.now,
              input.properties.map((property) => property.updatedAt),
              trendDays,
            ),
            trendPercent: _trendPercent(
              _countThisWindow(input.now, input.properties.map((property) => property.updatedAt)),
              _countPreviousWindow(input.now, input.properties.map((property) => property.updatedAt)),
            ),
          ),
      ],
      leadTrend: [
        for (var index = trendDays - 1; index >= 0; index--)
          DashboardTrendPoint(
            date: _dateOnly(input.now.subtract(Duration(days: index))),
            value: _countOnDay(
              input.leads.map((lead) => lead.createdAt),
              input.now.subtract(Duration(days: index)),
            ),
          ),
      ],
      followUpBars: [
        DashboardBarMetric(key: 'completed', value: _completedFollowUps(input.tasks).length),
        DashboardBarMetric(key: 'dueToday', value: dueTodayFollowUps.length + todayTasks.length),
        DashboardBarMetric(key: 'overdue', value: overdueFollowUps.length + overdueTasks.length),
      ],
      appointmentBars: [
        DashboardBarMetric(
          key: 'booked',
          value: todayAppointments
              .where((appointment) =>
                  appointment.status == AppointmentStatus.scheduled ||
                  appointment.status == AppointmentStatus.rescheduled)
              .length,
        ),
        DashboardBarMetric(
          key: 'completed',
          value: todayAppointments
              .where((appointment) => appointment.status == AppointmentStatus.completed)
              .length,
        ),
        DashboardBarMetric(
          key: 'missed',
          value: todayAppointments
              .where((appointment) => appointment.status == AppointmentStatus.missed)
              .length,
        ),
      ],
      dealStages: [
        for (final stage in DealStage.values)
          DashboardDealStageMetric(
            stage: stage,
            count: input.deals.where((deal) => deal.stage == stage).length,
            expectedValue: input.deals
                .where((deal) =>
                    deal.stage == stage &&
                    DashboardTruthRules.isOpenDeal(deal))
                .fold<num>(0, (sum, deal) => sum + deal.expectedValue),
            stuckCount: input.deals.where((deal) {
              return deal.stage == stage &&
                  DashboardTruthRules.isDealAtRisk(
                    deal,
                    input.now,
                    staleDays: stuckDealDays,
                  );
            }).length,
            closingThisMonthCount: input.deals.where((deal) {
              final closingDate = deal.closingDate;
              return deal.stage == stage &&
                  DashboardTruthRules.isOpenDeal(deal) &&
                  closingDate != null &&
                  closingDate.year == input.now.year &&
                  closingDate.month == input.now.month;
            }).length,
          ),
      ],
      leadSources: [
        for (final source in LeadSource.values)
          DashboardLeadSourceMetric(
            source: source,
            count: input.leads.where((lead) => lead.source == source).length,
          ),
      ].where((item) => item.count > 0).toList(),
      todayItems: _todayItems(
        input,
        day: input.today,
        includeOverdue: true,
        dueTodayFollowUps: dueTodayFollowUps,
        overdueFollowUps: overdueFollowUps,
        todayTasks: todayTasks,
        overdueTasks: overdueTasks,
        todayAppointments: todayAppointments,
        openDeals: openDeals,
      ),
      calendarItems: _calendarItems(input),
      performanceSeries: _performanceSeries(input, openDeals),
      teamPerformance: _teamPerformance(
        input,
        overdueActions: overdueFollowUps.length + overdueTasks.length,
        dueTodayActions: dueTodayFollowUps.length + todayTasks.length,
        appointmentsToday: todayAppointments.length,
      ),
      teamRows: _teamRows(input),
      importantOpportunities: _importantOpportunities(input),
      dailyInsight: _dailyInsight(
        input,
        staleLeads: _staleLeads(input).length,
        urgentActions: overdueFollowUps.length + overdueTasks.length,
      ),
    );
  }

  List<DashboardTodayItem> _todayItems(
    DashboardAnalyticsInput input, {
    required DateTime day,
    required bool includeOverdue,
    required List<Lead> dueTodayFollowUps,
    required List<Lead> overdueFollowUps,
    required List<CrmTask> todayTasks,
    required List<CrmTask> overdueTasks,
    required List<Appointment> todayAppointments,
    required List<Deal> openDeals,
  }) {
    final items = <DashboardTodayItem>[
      for (final appointment in todayAppointments)
        DashboardTodayItem(
          id: 'appointment:${appointment.id}',
          module: DashboardTodayModule.appointment,
          recordId: appointment.id,
          title: _fallback(appointment.title, appointment.relatedTitle),
          subtitle: _fallback(appointment.relatedTitle, appointment.assignedToName),
          dueAt: appointment.scheduledAt?.toLocal(),
          urgency: _appointmentUrgency(input, appointment),
        ),
      if (includeOverdue)
        for (final lead in overdueFollowUps)
        DashboardTodayItem(
          id: 'lead:${lead.id}:overdue',
          module: DashboardTodayModule.followUp,
          recordId: lead.id,
          title: _fallback(lead.fullName, lead.phone),
          subtitle: _fallback(lead.assignedToName, lead.phone),
          dueAt: lead.nextFollowUpAt?.toLocal(),
          urgency: DashboardTodayUrgency.overdue,
        ),
      for (final lead in dueTodayFollowUps)
        DashboardTodayItem(
          id: 'lead:${lead.id}:today',
          module: DashboardTodayModule.followUp,
          recordId: lead.id,
          title: _fallback(lead.fullName, lead.phone),
          subtitle: _fallback(lead.assignedToName, lead.phone),
          dueAt: lead.nextFollowUpAt?.toLocal(),
          urgency: DashboardTodayUrgency.dueToday,
        ),
      if (includeOverdue)
        for (final task in overdueTasks)
        DashboardTodayItem(
          id: 'task:${task.id}:overdue',
          module: DashboardTodayModule.task,
          recordId: task.id,
          title: task.title,
          subtitle: _fallback(task.relatedTitle, task.assignedToName),
          dueAt: task.dueDate?.toLocal(),
          urgency: DashboardTodayUrgency.overdue,
        ),
      for (final task in todayTasks)
        DashboardTodayItem(
          id: 'task:${task.id}:today',
          module: DashboardTodayModule.task,
          recordId: task.id,
          title: task.title,
          subtitle: _fallback(task.relatedTitle, task.assignedToName),
          dueAt: task.dueDate?.toLocal(),
          urgency: DashboardTodayUrgency.dueToday,
        ),
      for (final deal in openDeals.where((deal) {
        final closingDate = deal.closingDate;
        return closingDate != null && _dateOnly(closingDate) == day;
      }))
        DashboardTodayItem(
          id: 'deal:${deal.id}:closing',
          module: DashboardTodayModule.deal,
          recordId: deal.id,
          title: _fallback(deal.clientName, deal.propertyTitle),
          subtitle: _fallback(deal.propertyTitle, deal.assignedToName),
          dueAt: deal.closingDate?.toLocal(),
          urgency: DashboardTodayUrgency.dueToday,
        ),
    ];

    items.sort((a, b) {
      final urgency = _urgencyRank(b.urgency).compareTo(_urgencyRank(a.urgency));
      if (urgency != 0) {
        return urgency;
      }
      final aDate = a.dueAt ?? DateTime(9999);
      final bDate = b.dueAt ?? DateTime(9999);
      return aDate.compareTo(bDate);
    });
    return items.take(8).toList();
  }

  List<DashboardTodayItem> _calendarItems(DashboardAnalyticsInput input) {
    final openDeals =
        input.deals.where(DashboardTruthRules.isOpenDeal).toList();
    final items = <DashboardTodayItem>[
      if (input.includeAppointments)
        for (final appointment in input.appointments.where((item) => item.scheduledAt != null))
          DashboardTodayItem(
            id: 'appointment:${appointment.id}',
            module: DashboardTodayModule.appointment,
            recordId: appointment.id,
            title: _fallback(appointment.title, appointment.relatedTitle),
            subtitle: _fallback(appointment.relatedTitle, appointment.assignedToName),
            dueAt: appointment.scheduledAt?.toLocal(),
            urgency: _appointmentUrgency(input, appointment),
          ),
      if (input.includeLeads)
        for (final item in _leadCalendarItems(input))
          item,
      if (input.includeTasks)
        for (final item in _taskCalendarItems(input))
          item,
      if (input.includeDeals)
        for (final item in _dealCalendarItems(input, openDeals))
          item,
    ];
    items.sort((a, b) {
      final aDate = a.dueAt ?? DateTime(9999);
      final bDate = b.dueAt ?? DateTime(9999);
      return aDate.compareTo(bDate);
    });
    return items;
  }

  List<DashboardTodayItem> _leadCalendarItems(DashboardAnalyticsInput input) {
    final items = <DashboardTodayItem>[];
    for (final lead in input.leads.where(DashboardTruthRules.isActiveLead)) {
      final dueAt = lead.nextFollowUpAt?.toLocal();
      if (dueAt == null) {
        continue;
      }
      items.add(
        DashboardTodayItem(
          id: 'lead:${lead.id}:follow-up',
          module: DashboardTodayModule.followUp,
          recordId: lead.id,
          title: _fallback(lead.fullName, lead.phone),
          subtitle: _fallback(lead.assignedToName, lead.phone),
          dueAt: dueAt,
          urgency: _urgencyForDate(input, dueAt),
        ),
      );
    }
    return items;
  }

  List<DashboardTodayItem> _taskCalendarItems(DashboardAnalyticsInput input) {
    final items = <DashboardTodayItem>[];
    for (final task in input.tasks.where(DashboardTruthRules.isOpenTask)) {
      final dueAt = task.dueDate?.toLocal();
      if (dueAt == null) {
        continue;
      }
      items.add(
        DashboardTodayItem(
          id: 'task:${task.id}:due',
          module: DashboardTodayModule.task,
          recordId: task.id,
          title: task.title,
          subtitle: _fallback(task.relatedTitle, task.assignedToName),
          dueAt: dueAt,
          urgency: _urgencyForDate(input, dueAt),
        ),
      );
    }
    return items;
  }

  List<DashboardTodayItem> _dealCalendarItems(
    DashboardAnalyticsInput input,
    List<Deal> openDeals,
  ) {
    final items = <DashboardTodayItem>[];
    for (final deal in openDeals) {
      final dueAt = deal.closingDate?.toLocal();
      if (dueAt == null) {
        continue;
      }
      items.add(
        DashboardTodayItem(
          id: 'deal:${deal.id}:closing',
          module: DashboardTodayModule.deal,
          recordId: deal.id,
          title: _fallback(deal.clientName, deal.propertyTitle),
          subtitle: _fallback(deal.propertyTitle, deal.assignedToName),
          dueAt: dueAt,
          urgency: _urgencyForDate(input, dueAt),
        ),
      );
    }
    return items;
  }

  DashboardTodayUrgency _urgencyForDate(
    DashboardAnalyticsInput input,
    DateTime dueAt,
  ) {
    final day = _dateOnly(dueAt);
    if (day.isBefore(input.today)) {
      return DashboardTodayUrgency.overdue;
    }
    if (day == input.today) {
      return DashboardTodayUrgency.dueToday;
    }
    return DashboardTodayUrgency.normal;
  }

  List<DashboardChartSeries> _performanceSeries(
    DashboardAnalyticsInput input,
    List<Deal> openDeals,
  ) {
    return [
      if (input.includeLeads)
        DashboardChartSeries(
          type: DashboardPerformanceSeriesType.leads,
          points: _trendPoints(
            input.now,
            input.leads.map((lead) => lead.createdAt),
            performanceDays,
          ),
        ),
      if (input.includeAppointments)
        DashboardChartSeries(
          type: DashboardPerformanceSeriesType.appointments,
          points: _trendPoints(
            input.now,
            input.appointments.map((appointment) => appointment.scheduledAt),
            performanceDays,
          ),
        ),
      if (input.includeLeads || input.includeTasks)
        DashboardChartSeries(
          type: DashboardPerformanceSeriesType.followUps,
          points: _trendPoints(
            input.now,
            [
              if (input.includeLeads)
                ...input.leads.map((lead) => lead.nextFollowUpAt),
              if (input.includeTasks)
                ...input.tasks.map((task) => task.dueDate),
            ],
            performanceDays,
          ),
        ),
      if (input.includeDeals)
        DashboardChartSeries(
          type: DashboardPerformanceSeriesType.deals,
          points: _trendPoints(
            input.now,
            input.deals.map((deal) => deal.updatedAt ?? deal.createdAt),
            performanceDays,
          ),
        ),
      if (input.includeProperties)
        DashboardChartSeries(
          type: DashboardPerformanceSeriesType.properties,
          points: _trendPoints(
            input.now,
            input.properties.map((property) => property.updatedAt),
            performanceDays,
          ),
        ),
    ];
  }

  List<DashboardTeamPerformanceRow> _teamRows(DashboardAnalyticsInput input) {
    if (input.role == UserRole.viewer) {
      return const <DashboardTeamPerformanceRow>[];
    }

    final rows = <String, _TeamRowAccumulator>{};

    _TeamRowAccumulator row(String id, String name) {
      final cleanId = id.trim();
      if (cleanId.isEmpty) {
        return _TeamRowAccumulator('', '');
      }
      final cleanName = _fallback(name, cleanId);
      return rows.putIfAbsent(cleanId, () => _TeamRowAccumulator(cleanId, cleanName));
    }

    // Team Activity must be user-based first, not activity-based first.
    // Otherwise active agents with zero records disappear from the dashboard.
    for (final user in input.activeUsers.where(_isOperationalUser)) {
      row(user.uid, user.fullName);
    }

    if (input.includeLeads) {
      for (final lead in input.leads.where((item) => !item.isArchived)) {
        final assignedTo = lead.assignedTo.trim();
        if (assignedTo.isEmpty) {
          continue;
        }
        final item = row(assignedTo, lead.assignedToName);
        item.leads++;
        if (DashboardTruthRules.isActiveLead(lead)) {
          item.activeRecords++;
        }
      }
    }

    if (input.includeTasks) {
      for (final task in input.tasks) {
        final assignedTo = task.assignedTo.trim();
        if (assignedTo.isEmpty) {
          continue;
        }
        final item = row(assignedTo, task.assignedToName);
        item.tasks++;
        if (task.status == TaskStatus.completed) {
          item.completedTasks++;
        }
        if (DashboardTruthRules.isOverdueTask(task, input.today)) {
          item.overdueTasks++;
        }
        if (DashboardTruthRules.isOpenTask(task)) {
          item.activeRecords++;
        }
      }
    }

    if (input.includeAppointments) {
      for (final appointment in input.appointments) {
        final assignedTo = appointment.assignedTo.trim();
        if (assignedTo.isEmpty) {
          continue;
        }
        row(assignedTo, appointment.assignedToName).appointments++;
      }
    }

    if (input.includeDeals) {
      for (final deal in input.deals.where((item) => item.isActive && !item.isArchived)) {
        final assignedTo = deal.assignedTo.trim();
        if (assignedTo.isEmpty) {
          continue;
        }
        final item = row(assignedTo, deal.assignedToName);
        item.deals++;
        if (deal.stage == DealStage.won) {
          item.wonDeals++;
        }
        if (DashboardTruthRules.isOpenDeal(deal)) {
          item.activeRecords++;
          item.pipelineValue += deal.expectedValue;
        }
      }
    }

    final result = rows.values
        .where((item) => item.userId.trim().isNotEmpty)
        .map((item) => item.toEntity())
        .where((row) => _isOperationalTeamRow(row, input.activeUsers))
        .toList();
    result.sort((a, b) {
      final score = _teamRowScore(b).compareTo(_teamRowScore(a));
      if (score != 0) {
        return score;
      }
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return result;
  }

  List<DashboardOpportunityItem> _importantOpportunities(
    DashboardAnalyticsInput input,
  ) {
    final items = <DashboardOpportunityItem>[];

    if (input.includeDeals) {
      for (final deal in input.deals.where(DashboardTruthRules.isOpenDeal)) {
        final stageScore = switch (deal.stage) {
          DealStage.negotiation => 80,
          DealStage.proposal => 72,
          DealStage.qualified => 62,
          DealStage.newDeal => 45,
          DealStage.won || DealStage.lost => 0,
        };
        items.add(
          DashboardOpportunityItem(
            id: 'deal:${deal.id}',
            type: DashboardOpportunityType.deal,
            recordId: deal.id,
            title: _fallback(deal.clientName, deal.propertyTitle),
            ownerName: deal.assignedToName,
            value: deal.expectedValue,
            score: stageScore + (deal.expectedValue > 0 ? 20 : 0),
            dealStage: deal.stage,
            createdAt: deal.createdAt,
            updatedAt: deal.updatedAt,
          ),
        );
      }
    }

    if (input.includeLeads) {
      for (final lead in input.leads.where(DashboardTruthRules.isHotLead)) {
        final value = lead.budgetMax > 0 ? lead.budgetMax : lead.budgetMin;
        final priorityScore = switch (lead.priority) {
          LeadPriority.high => 78,
          LeadPriority.medium => 58,
          LeadPriority.low => 42,
        };
        items.add(
          DashboardOpportunityItem(
            id: 'lead:${lead.id}',
            type: DashboardOpportunityType.lead,
            recordId: lead.id,
            title: _fallback(lead.fullName, lead.phone),
            ownerName: lead.assignedToName,
            value: value,
            score: priorityScore + (value > 0 ? 12 : 0),
            leadStatus: lead.status,
            createdAt: lead.createdAt,
            updatedAt: lead.updatedAt,
          ),
        );
      }
    }

    if (input.includeProperties) {
      for (final property in input.properties.where((item) {
        return item.status == PropertyStatus.available && !item.isArchived;
      })) {
        items.add(
          DashboardOpportunityItem(
            id: 'property:${property.id}',
            type: DashboardOpportunityType.property,
            recordId: property.id,
            title: _fallback(property.title, property.location),
            ownerName: property.ownerName,
            value: property.price,
            score: 38 + (property.price > 0 ? 10 : 0),
            propertyStatus: property.status,
            createdAt: property.createdAt,
            updatedAt: property.updatedAt,
          ),
        );
      }
    }

    items.sort((a, b) {
      final score = b.score.compareTo(a.score);
      if (score != 0) {
        return score;
      }
      final aDate = a.updatedAt ?? a.createdAt ?? DateTime(0);
      final bDate = b.updatedAt ?? b.createdAt ?? DateTime(0);
      return bDate.compareTo(aDate);
    });
    return items.take(5).toList();
  }

  DashboardDailyInsight _dailyInsight(
    DashboardAnalyticsInput input, {
    required int staleLeads,
    required int urgentActions,
  }) {
    if (staleLeads > 0) {
      return DashboardDailyInsight(
        type: DashboardDailyInsightType.staleLeads,
        primaryValue: staleLeads,
      );
    }

    final currentRate = _conversionRate(input, current: true);
    final previousRate = _conversionRate(input, current: false);
    if (currentRate != null && previousRate != null && currentRate > previousRate) {
      return DashboardDailyInsight(
        type: DashboardDailyInsightType.conversionUp,
        percent: ((currentRate - previousRate) * 100).round(),
      );
    }

    if (input.leads.isNotEmpty || input.deals.isNotEmpty || input.appointments.isNotEmpty) {
      return DashboardDailyInsight(
        type: urgentActions == 0
            ? DashboardDailyInsightType.calm
            : DashboardDailyInsightType.notEnoughData,
      );
    }

    return const DashboardDailyInsight(type: DashboardDailyInsightType.notEnoughData);
  }

  List<Lead> _staleLeads(DashboardAnalyticsInput input) {
    return input.leads.where((lead) {
      if (!DashboardTruthRules.isActiveLead(lead)) {
        return false;
      }
      final lastTouch = _latestDate([lead.lastContactAt, lead.updatedAt, lead.createdAt]);
      return lastTouch != null && input.now.difference(lastTouch.toLocal()).inDays > 5;
    }).toList();
  }

  double? _conversionRate(DashboardAnalyticsInput input, {required bool current}) {
    final now = _dateOnly(input.now);
    final start = current
        ? DateTime(now.year, now.month)
        : DateTime(now.year, now.month - 1);
    final end = current ? DateTime(now.year, now.month + 1) : DateTime(now.year, now.month);
    final createdLeads = input.leads.where((lead) {
      final createdAt = lead.createdAt.toLocal();
      return !createdAt.isBefore(start) && createdAt.isBefore(end);
    }).length;
    if (createdLeads == 0) {
      return null;
    }
    final wonSignals = input.leads.where((lead) {
          final updatedAt = lead.updatedAt.toLocal();
          return lead.status == LeadStatus.won &&
              !updatedAt.isBefore(start) &&
              updatedAt.isBefore(end);
        }).length +
        input.deals.where((deal) {
          final updatedAt = (deal.updatedAt ?? deal.createdAt)?.toLocal();
          return deal.stage == DealStage.won &&
              updatedAt != null &&
              !updatedAt.isBefore(start) &&
              updatedAt.isBefore(end);
        }).length;
    return wonSignals / createdLeads;
  }

  DashboardTeamPerformance _teamPerformance(
    DashboardAnalyticsInput input, {
    required int overdueActions,
    required int dueTodayActions,
    required int appointmentsToday,
  }) {
    if (input.role == UserRole.viewer) {
      return DashboardTeamPerformance(
        role: input.role,
        isLimited: true,
        overdueActions: 0,
        dueTodayActions: 0,
        appointmentsToday: 0,
      );
    }

    final byUser = <String, _AgentAccumulator>{};
    void touch({
      required String id,
      required String name,
      int active = 0,
      int overdue = 0,
      int dueToday = 0,
    }) {
      final cleanId = id.trim();
      if (cleanId.isEmpty) {
        return;
      }
      final item = byUser.putIfAbsent(
        cleanId,
        () => _AgentAccumulator(cleanId, _fallback(name, cleanId)),
      );
      item.activeRecords += active;
      item.overdueActions += overdue;
      item.dueTodayActions += dueToday;
    }

    for (final lead in input.leads.where(DashboardTruthRules.isActiveLead)) {
      final followUp = lead.nextFollowUpAt;
      touch(
        id: lead.assignedTo,
        name: lead.assignedToName,
        active: 1,
        overdue: followUp != null && _dateOnly(followUp).isBefore(input.today) ? 1 : 0,
        dueToday: followUp != null && _dateOnly(followUp) == input.today ? 1 : 0,
      );
    }
    for (final task in input.tasks.where(DashboardTruthRules.isOpenTask)) {
      final dueDate = task.dueDate;
      touch(
        id: task.assignedTo,
        name: task.assignedToName,
        active: 1,
        overdue: dueDate != null && _dateOnly(dueDate).isBefore(input.today) ? 1 : 0,
        dueToday: dueDate != null && _dateOnly(dueDate) == input.today ? 1 : 0,
      );
    }
    for (final deal in input.deals.where(DashboardTruthRules.isOpenDeal)) {
      touch(
        id: deal.assignedTo,
        name: deal.assignedToName,
        active: 1,
      );
    }

    final agents = byUser.values.map((item) => item.toEntity()).toList();
    agents.sort((a, b) => b.activeRecords.compareTo(a.activeRecords));
    final overloaded = [...agents]
      ..sort((a, b) => b.overdueActions.compareTo(a.overdueActions));

    return DashboardTeamPerformance(
      role: input.role,
      isLimited: false,
      overdueActions: overdueActions,
      dueTodayActions: dueTodayActions,
      appointmentsToday: appointmentsToday,
      topActiveAgent: agents.isEmpty ? null : agents.first,
      overloadedAssignee:
          overloaded.isEmpty || overloaded.first.overdueActions == 0 ? null : overloaded.first,
    );
  }
}

class DashboardAnalyticsInput {
  const DashboardAnalyticsInput({
    required this.role,
    required this.now,
    required this.leads,
    required this.properties,
    required this.tasks,
    required this.appointments,
    required this.deals,
    required this.activeUsers,
    required this.includeLeads,
    required this.includeProperties,
    required this.includeTasks,
    required this.includeAppointments,
    required this.includeDeals,
    required this.canViewUnassignedLeads,
  });

  final UserRole role;
  final DateTime now;
  final List<Lead> leads;
  final List<Property> properties;
  final List<CrmTask> tasks;
  final List<Appointment> appointments;
  final List<Deal> deals;
  final List<UserProfile> activeUsers;
  final bool includeLeads;
  final bool includeProperties;
  final bool includeTasks;
  final bool includeAppointments;
  final bool includeDeals;
  final bool canViewUnassignedLeads;

  DateTime get today => _dateOnly(now);
}

class _AgentAccumulator {
  _AgentAccumulator(this.userId, this.name);

  final String userId;
  final String name;
  int activeRecords = 0;
  int overdueActions = 0;
  int dueTodayActions = 0;

  DashboardAgentPerformance toEntity() {
    return DashboardAgentPerformance(
      userId: userId,
      name: name,
      activeRecords: activeRecords,
      overdueActions: overdueActions,
      dueTodayActions: dueTodayActions,
    );
  }
}


bool _isOperationalUser(UserProfile user) {
  return user.isActive &&
      (user.role == UserRole.salesAgent || user.role == UserRole.marketing);
}

bool _isOperationalTeamRow(
  DashboardTeamPerformanceRow row,
  List<UserProfile> activeUsers,
) {
  UserProfile? matchingUser;
  for (final user in activeUsers) {
    if (user.uid == row.userId) {
      matchingUser = user;
      break;
    }
  }
  if (matchingUser != null) {
    return _isOperationalUser(matchingUser);
  }

  final label = '${row.userId} ${row.name}'.toLowerCase().trim();
  if (label.isEmpty) {
    return false;
  }
  if (label.contains('admin') ||
      label.contains('manager') ||
      label.contains('مدير') ||
      label.contains('مسؤول')) {
    return false;
  }
  return row.leads > 0 ||
      row.tasks > 0 ||
      row.completedTasks > 0 ||
      row.appointments > 0 ||
      row.deals > 0 ||
      row.pipelineValue > 0;
}

num _teamRowScore(DashboardTeamPerformanceRow row) {
  return row.pipelineValue +
      (row.wonDeals * 150000) +
      (row.deals * 100000) +
      (row.completedTasks * 45000) +
      (row.appointments * 35000) +
      (row.leads * 20000) +
      (row.activeRecords * 15000) -
      (row.overdueTasks * 60000);
}

class _TeamRowAccumulator {
  _TeamRowAccumulator(this.userId, this.name);

  final String userId;
  final String name;
  int leads = 0;
  int appointments = 0;
  int deals = 0;
  int wonDeals = 0;
  num pipelineValue = 0;
  int tasks = 0;
  int completedTasks = 0;
  int overdueTasks = 0;
  int activeRecords = 0;

  DashboardTeamPerformanceRow toEntity() {
    final completionPercent = tasks > 0
        ? ((completedTasks / tasks) * 100).round()
        : deals > 0
            ? ((wonDeals / deals) * 100).round()
            : null;
    return DashboardTeamPerformanceRow(
      userId: userId,
      name: name,
      leads: leads,
      appointments: appointments,
      deals: deals,
      wonDeals: wonDeals,
      pipelineValue: pipelineValue,
      tasks: tasks,
      completedTasks: completedTasks,
      overdueTasks: overdueTasks,
      activeRecords: activeRecords,
      conversionPercent: completionPercent,
    );
  }
}

DateTime? _dealClosedAt(Deal deal) {
  return deal.closingDate ?? deal.updatedAt ?? deal.createdAt;
}

List<CrmTask> _completedFollowUps(List<CrmTask> tasks) {
  return tasks.where((task) {
    return task.status == TaskStatus.completed &&
        (task.relatedType == TaskRelatedType.lead ||
            task.relatedType == TaskRelatedType.client ||
            task.relatedType == TaskRelatedType.deal);
  }).toList();
}

DashboardTodayUrgency _appointmentUrgency(
  DashboardAnalyticsInput input,
  Appointment appointment,
) {
  final endAt = (appointment.endAt ?? appointment.scheduledAt)?.toLocal();
  if (appointment.status == AppointmentStatus.missed ||
      ((appointment.status == AppointmentStatus.scheduled ||
              appointment.status == AppointmentStatus.rescheduled) &&
          endAt != null &&
          endAt.isBefore(input.now))) {
    return DashboardTodayUrgency.overdue;
  }
  return DashboardTodayUrgency.dueToday;
}

List<int> _countsByTrailingDays(
  DateTime now,
  Iterable<DateTime?> dates,
  int days,
) {
  return [
    for (var index = days - 1; index >= 0; index--)
      _countOnDay(dates, now.subtract(Duration(days: index))),
  ];
}

List<int> _valueByTrailingDays(DateTime now, List<Deal> deals, int days) {
  return [
    for (var index = days - 1; index >= 0; index--)
      deals
          .where((deal) => _dateOnly(deal.updatedAt ?? deal.createdAt ?? now) ==
              _dateOnly(now.subtract(Duration(days: index))))
          .fold<int>(0, (sum, deal) => sum + deal.expectedValue.round()),
  ];
}

List<int> _commissionByTrailingDays(DateTime now, List<Deal> deals, int days) {
  return [
    for (var index = days - 1; index >= 0; index--)
      deals
          .where((deal) => _dateOnly(deal.updatedAt ?? deal.createdAt ?? now) ==
              _dateOnly(now.subtract(Duration(days: index))))
          .fold<int>(0, (sum, deal) => sum + deal.commission.round()),
  ];
}

List<DashboardTrendPoint> _trendPoints(
  DateTime now,
  Iterable<DateTime?> dates,
  int days,
) {
  return [
    for (var index = days - 1; index >= 0; index--)
      DashboardTrendPoint(
        date: _dateOnly(now.subtract(Duration(days: index))),
        value: _countOnDay(dates, now.subtract(Duration(days: index))),
      ),
  ];
}

List<DashboardTrendPoint> _valueTrendPoints(
  DateTime now,
  List<Deal> deals,
  int days,
) {
  return [
    for (var index = days - 1; index >= 0; index--)
      DashboardTrendPoint(
        date: _dateOnly(now.subtract(Duration(days: index))),
        value: deals
            .where((deal) =>
                _dateOnly(deal.updatedAt ?? deal.createdAt ?? now) ==
                _dateOnly(now.subtract(Duration(days: index))))
            .fold<int>(0, (sum, deal) => sum + deal.expectedValue.round()),
      ),
  ];
}

int _countOnDay(Iterable<DateTime?> dates, DateTime day) {
  final target = _dateOnly(day);
  return dates.where((date) => date != null && _dateOnly(date) == target).length;
}

int _countThisWindow(DateTime now, Iterable<DateTime?> dates) {
  final start = _dateOnly(now).subtract(const Duration(days: 6));
  final end = _dateOnly(now).add(const Duration(days: 1));
  return dates.where((date) {
    if (date == null) {
      return false;
    }
    final local = date.toLocal();
    return !local.isBefore(start) && local.isBefore(end);
  }).length;
}

int _countPreviousWindow(DateTime now, Iterable<DateTime?> dates) {
  final start = _dateOnly(now).subtract(const Duration(days: 13));
  final end = _dateOnly(now).subtract(const Duration(days: 6));
  return dates.where((date) {
    if (date == null) {
      return false;
    }
    final local = date.toLocal();
    return !local.isBefore(start) && local.isBefore(end);
  }).length;
}

int _valueThisWindow(DateTime now, Iterable<Deal> deals) {
  final start = _dateOnly(now).subtract(const Duration(days: 6));
  final end = _dateOnly(now).add(const Duration(days: 1));
  return deals.where((deal) {
    final date = deal.updatedAt ?? deal.createdAt;
    if (date == null) {
      return false;
    }
    final local = date.toLocal();
    return !local.isBefore(start) && local.isBefore(end);
  }).fold<int>(0, (sum, deal) => sum + deal.expectedValue.round());
}

int _valuePreviousWindow(DateTime now, Iterable<Deal> deals) {
  final start = _dateOnly(now).subtract(const Duration(days: 13));
  final end = _dateOnly(now).subtract(const Duration(days: 6));
  return deals.where((deal) {
    final date = deal.updatedAt ?? deal.createdAt;
    if (date == null) {
      return false;
    }
    final local = date.toLocal();
    return !local.isBefore(start) && local.isBefore(end);
  }).fold<int>(0, (sum, deal) => sum + deal.expectedValue.round());
}

int _commissionThisWindow(DateTime now, Iterable<Deal> deals) {
  final start = _dateOnly(now).subtract(const Duration(days: 6));
  final end = _dateOnly(now).add(const Duration(days: 1));
  return deals.where((deal) {
    final date = deal.updatedAt ?? deal.createdAt;
    if (date == null) {
      return false;
    }
    final local = date.toLocal();
    return !local.isBefore(start) && local.isBefore(end);
  }).fold<int>(0, (sum, deal) => sum + deal.commission.round());
}

int _commissionPreviousWindow(DateTime now, Iterable<Deal> deals) {
  final start = _dateOnly(now).subtract(const Duration(days: 13));
  final end = _dateOnly(now).subtract(const Duration(days: 6));
  return deals.where((deal) {
    final date = deal.updatedAt ?? deal.createdAt;
    if (date == null) {
      return false;
    }
    final local = date.toLocal();
    return !local.isBefore(start) && local.isBefore(end);
  }).fold<int>(0, (sum, deal) => sum + deal.commission.round());
}

int? _trendPercent(int current, int previous) {
  if (previous == 0) {
    return current == 0 ? null : 100;
  }
  return (((current - previous) / previous) * 100).round();
}

int _urgencyRank(DashboardTodayUrgency urgency) {
  return switch (urgency) {
    DashboardTodayUrgency.overdue => 3,
    DashboardTodayUrgency.dueToday => 2,
    DashboardTodayUrgency.normal => 1,
  };
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
