import 'package:equatable/equatable.dart';

import '../../../../core/constants/role_constants.dart';
import '../../../deals/domain/entities/deal.dart';
import '../../../leads/domain/entities/lead.dart';
import '../../../properties/domain/entities/property.dart';

enum DashboardKpiType {
  activeLeads,
  newLeadsToday,
  hotOpportunities,
  dueTodayFollowUps,
  overdueFollowUps,
  overdueActions,
  appointmentsToday,
  missedAppointments,
  overdueTasks,
  pipelineDeals,
  expectedPipelineValue,
  expectedCommission,
  wonDealsThisMonth,
  stuckDeals,
  unassignedLeads,
  teamWorkload,
  activeProperties,
}

enum DashboardTodayModule { appointment, followUp, task, deal }

enum DashboardTodayUrgency { normal, dueToday, overdue }

enum DashboardPerformanceSeriesType { leads, appointments, followUps, deals, pipelineValue, properties }

enum DashboardOpportunityType { lead, deal, property }

enum DashboardDailyInsightType {
  contactedTodayStillOverdue,
  noNextFollowUp,
  staleLeads,
  conversionUp,
  calm,
  notEnoughData,
}

class DashboardAnalytics extends Equatable {
  const DashboardAnalytics({
    required this.role,
    required this.metrics,
    required this.leadTrend,
    required this.followUpBars,
    required this.appointmentBars,
    required this.dealStages,
    required this.leadSources,
    required this.todayItems,
    required this.calendarItems,
    required this.performanceSeries,
    required this.teamPerformance,
    required this.teamRows,
    required this.importantOpportunities,
    required this.dailyInsight,
  });

  final UserRole role;
  final List<DashboardKpiMetric> metrics;
  final List<DashboardTrendPoint> leadTrend;
  final List<DashboardBarMetric> followUpBars;
  final List<DashboardBarMetric> appointmentBars;
  final List<DashboardDealStageMetric> dealStages;
  final List<DashboardLeadSourceMetric> leadSources;
  final List<DashboardTodayItem> todayItems;
  final List<DashboardTodayItem> calendarItems;
  final List<DashboardChartSeries> performanceSeries;
  final DashboardTeamPerformance teamPerformance;
  final List<DashboardTeamPerformanceRow> teamRows;
  final List<DashboardOpportunityItem> importantOpportunities;
  final DashboardDailyInsight dailyInsight;

  num get pipelineValueTotal => dealStages.fold<num>(
        0,
        (total, item) => total + item.expectedValue,
      );

  int get stuckDealsCount => dealStages.fold<int>(
        0,
        (total, item) => total + item.stuckCount,
      );

  int get closingThisMonthCount => dealStages.fold<int>(
        0,
        (total, item) => total + item.closingThisMonthCount,
      );

  int get openPipelineDeals => dealStages.fold<int>(
        0,
        (total, item) {
          if (item.stage == DealStage.won || item.stage == DealStage.lost) {
            return total;
          }
          return total + item.count;
        },
      );

  @override
  List<Object?> get props => [
        role,
        metrics,
        leadTrend,
        followUpBars,
        appointmentBars,
        dealStages,
        leadSources,
        todayItems,
        calendarItems,
        performanceSeries,
        teamPerformance,
        teamRows,
        importantOpportunities,
        dailyInsight,
      ];
}

class DashboardKpiMetric extends Equatable {
  const DashboardKpiMetric({
    required this.type,
    required this.value,
    required this.valueLabel,
    required this.sparkline,
    this.trendPercent,
  });

  final DashboardKpiType type;
  final num value;
  final String valueLabel;
  final List<int> sparkline;
  final int? trendPercent;

  @override
  List<Object?> get props => [type, value, valueLabel, sparkline, trendPercent];
}

class DashboardTrendPoint extends Equatable {
  const DashboardTrendPoint({
    required this.date,
    required this.value,
  });

  final DateTime date;
  final int value;

  @override
  List<Object?> get props => [date, value];
}

class DashboardChartSeries extends Equatable {
  const DashboardChartSeries({
    required this.type,
    required this.points,
  });

  final DashboardPerformanceSeriesType type;
  final List<DashboardTrendPoint> points;

  @override
  List<Object?> get props => [type, points];
}

class DashboardBarMetric extends Equatable {
  const DashboardBarMetric({
    required this.key,
    required this.value,
  });

  final String key;
  final int value;

  @override
  List<Object?> get props => [key, value];
}

class DashboardDealStageMetric extends Equatable {
  const DashboardDealStageMetric({
    required this.stage,
    required this.count,
    required this.expectedValue,
    required this.stuckCount,
    required this.closingThisMonthCount,
  });

  final DealStage stage;
  final int count;
  final num expectedValue;
  final int stuckCount;
  final int closingThisMonthCount;

  @override
  List<Object?> get props => [
        stage,
        count,
        expectedValue,
        stuckCount,
        closingThisMonthCount,
      ];
}

class DashboardLeadSourceMetric extends Equatable {
  const DashboardLeadSourceMetric({
    required this.source,
    required this.count,
  });

  final LeadSource source;
  final int count;

  @override
  List<Object?> get props => [source, count];
}

class DashboardTodayItem extends Equatable {
  const DashboardTodayItem({
    required this.id,
    required this.module,
    required this.recordId,
    required this.title,
    required this.subtitle,
    required this.dueAt,
    required this.urgency,
  });

  final String id;
  final DashboardTodayModule module;
  final String recordId;
  final String title;
  final String subtitle;
  final DateTime? dueAt;
  final DashboardTodayUrgency urgency;

  @override
  List<Object?> get props => [
        id,
        module,
        recordId,
        title,
        subtitle,
        dueAt,
        urgency,
      ];
}

class DashboardTeamPerformanceRow extends Equatable {
  const DashboardTeamPerformanceRow({
    required this.userId,
    required this.name,
    required this.leads,
    required this.appointments,
    required this.deals,
    required this.wonDeals,
    required this.pipelineValue,
    required this.tasks,
    required this.completedTasks,
    required this.overdueTasks,
    required this.activeRecords,
    this.conversionPercent,
  });

  final String userId;
  final String name;

  /// Assigned non-archived leads in the currently scoped dashboard stream.
  /// This is intentionally separate from [activeRecords] so the UI does not
  /// label a mixed workload number as leads.
  final int leads;
  final int appointments;
  final int deals;
  final int wonDeals;
  final num pipelineValue;
  final int tasks;
  final int completedTasks;
  final int overdueTasks;

  /// Mixed workload used for sorting/weighting only: active leads + open tasks
  /// + open deals. Do not display this as a raw lead count.
  final int activeRecords;
  final int? conversionPercent;

  @override
  List<Object?> get props => [
        userId,
        name,
        leads,
        appointments,
        deals,
        wonDeals,
        pipelineValue,
        tasks,
        completedTasks,
        overdueTasks,
        activeRecords,
        conversionPercent,
      ];
}

class DashboardOpportunityItem extends Equatable {
  const DashboardOpportunityItem({
    required this.id,
    required this.type,
    required this.recordId,
    required this.title,
    required this.ownerName,
    required this.value,
    required this.score,
    this.leadStatus,
    this.dealStage,
    this.propertyStatus,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final DashboardOpportunityType type;
  final String recordId;
  final String title;
  final String ownerName;
  final num value;
  final int score;
  final LeadStatus? leadStatus;
  final DealStage? dealStage;
  final PropertyStatus? propertyStatus;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  @override
  List<Object?> get props => [
        id,
        type,
        recordId,
        title,
        ownerName,
        value,
        score,
        leadStatus,
        dealStage,
        propertyStatus,
        createdAt,
        updatedAt,
      ];
}

class DashboardDailyInsight extends Equatable {
  const DashboardDailyInsight({
    required this.type,
    this.primaryValue = 0,
    this.secondaryValue = 0,
    this.percent = 0,
  });

  final DashboardDailyInsightType type;
  final int primaryValue;
  final int secondaryValue;
  final int percent;

  @override
  List<Object?> get props => [type, primaryValue, secondaryValue, percent];
}

class DashboardTeamPerformance extends Equatable {
  const DashboardTeamPerformance({
    required this.role,
    required this.isLimited,
    required this.overdueActions,
    required this.dueTodayActions,
    required this.appointmentsToday,
    this.topActiveAgent,
    this.overloadedAssignee,
  });

  final UserRole role;
  final bool isLimited;
  final int overdueActions;
  final int dueTodayActions;
  final int appointmentsToday;
  final DashboardAgentPerformance? topActiveAgent;
  final DashboardAgentPerformance? overloadedAssignee;

  @override
  List<Object?> get props => [
        role,
        isLimited,
        overdueActions,
        dueTodayActions,
        appointmentsToday,
        topActiveAgent,
        overloadedAssignee,
      ];
}

class DashboardAgentPerformance extends Equatable {
  const DashboardAgentPerformance({
    required this.userId,
    required this.name,
    required this.activeRecords,
    required this.overdueActions,
    required this.dueTodayActions,
  });

  final String userId;
  final String name;
  final int activeRecords;
  final int overdueActions;
  final int dueTodayActions;

  @override
  List<Object?> get props => [
        userId,
        name,
        activeRecords,
        overdueActions,
        dueTodayActions,
      ];
}
