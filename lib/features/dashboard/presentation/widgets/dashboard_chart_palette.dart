import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/dashboard_analytics.dart';

abstract final class DashboardChartPalette {
  static Color seriesColor(
    BuildContext context,
    DashboardPerformanceSeriesType type,
  ) {
    return switch (type) {
      DashboardPerformanceSeriesType.leads => AppColors.successColor(context),
      DashboardPerformanceSeriesType.appointments => AppColors.primaryColor(context),
      DashboardPerformanceSeriesType.followUps => AppColors.errorColor(context),
      DashboardPerformanceSeriesType.deals => AppColors.infoColor(context),
      DashboardPerformanceSeriesType.pipelineValue => const Color(0xFF0EA5E9),
      DashboardPerformanceSeriesType.properties => const Color(0xFF9333EA),
    };
  }

  static Color kpiColor(BuildContext context, DashboardKpiType type) {
    return switch (type) {
      DashboardKpiType.activeLeads => AppColors.infoColor(context),
      DashboardKpiType.newLeadsToday => AppColors.primaryColor(context),
      DashboardKpiType.hotOpportunities => AppColors.errorColor(context),
      DashboardKpiType.dueTodayFollowUps => AppColors.warningColor(context),
      DashboardKpiType.overdueFollowUps => AppColors.errorColor(context),
      DashboardKpiType.overdueActions => AppColors.errorColor(context),
      DashboardKpiType.appointmentsToday => AppColors.primaryColor(context),
      DashboardKpiType.missedAppointments => AppColors.errorColor(context),
      DashboardKpiType.overdueTasks => AppColors.errorColor(context),
      DashboardKpiType.pipelineDeals ||
      DashboardKpiType.expectedPipelineValue =>
        AppColors.successColor(context),
      DashboardKpiType.expectedCommission => AppColors.successColor(context),
      DashboardKpiType.wonDealsThisMonth => AppColors.successColor(context),
      DashboardKpiType.stuckDeals => AppColors.warningColor(context),
      DashboardKpiType.unassignedLeads => AppColors.warningColor(context),
      DashboardKpiType.teamWorkload => AppColors.infoColor(context),
      DashboardKpiType.activeProperties => const Color(0xFF9333EA),
    };
  }

  static Color dealStageColor(BuildContext context, int index) {
    final colors = categorical(context);
    return colors[index % colors.length];
  }

  static Color leadSourceColor(BuildContext context, int index) {
    final colors = categorical(context);
    return colors[(index + 1) % colors.length];
  }

  static List<Color> categorical(BuildContext context) {
    return [
      AppColors.infoColor(context),
      AppColors.successColor(context),
      AppColors.warningColor(context),
      const Color(0xFF8B5CF6),
      AppColors.errorColor(context),
      AppColors.textMutedColor(context),
    ];
  }
}
