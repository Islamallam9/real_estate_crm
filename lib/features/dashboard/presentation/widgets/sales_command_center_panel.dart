import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' as intl;

import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_status_badge.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/sales_command_center.dart';

class SalesCommandCenterPanel extends StatelessWidget {
  const SalesCommandCenterPanel({
    super.key,
    required this.summary,
    this.readOnly = false,
  });

  final SalesCommandSummary summary;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final priorityItems = _topCommandItems(summary);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.cardSurface(context),
        border: Border.all(color: AppColors.borderColor(context)),
        borderRadius: AppRadius.xLarge,
        boxShadow: Theme.of(context).brightness == Brightness.dark
            ? null
            : AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CommandCenterHeader(summary: summary, readOnly: readOnly),
          const SizedBox(height: AppSpacing.md),
          if (priorityItems.isEmpty)
            _CommandCenterEmpty(summary: summary)
          else
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeOut,
              child: Column(
                key: ValueKey('sales-command-${summary.totalCount}'),
                children: [
                  for (var index = 0; index < priorityItems.length; index++) ...[
                    _CommandItemCard(
                      item: priorityItems[index],
                      readOnly: readOnly,
                    ),
                    if (index != priorityItems.length - 1)
                      Divider(
                        height: AppSpacing.md,
                        color: AppColors.borderColor(context),
                      ),
                  ],
                ],
              ),
            ),
          if (priorityItems.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              _salesCommandFooterLabel(l),
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textSecondaryColor(context),
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ],
      ),
    );
  }

  List<SalesCommandItem> _topCommandItems(SalesCommandSummary summary) {
    final used = <String>{};
    final items = [
      for (final section in summary.sections)
        for (final item in section.items)
          if (used.add(item.recordKey)) item,
    ]..sort((a, b) {
        final score = b.score.compareTo(a.score);
        if (score != 0) {
          return score;
        }
        final priority = _priorityRank(b.priority).compareTo(
          _priorityRank(a.priority),
        );
        if (priority != 0) {
          return priority;
        }
        final aDate = a.sortDate ?? a.dueAt ?? a.relatedDate ?? DateTime(9999);
        final bDate = b.sortDate ?? b.dueAt ?? b.relatedDate ?? DateTime(9999);
        return aDate.compareTo(bDate);
      });
    return items.take(5).toList();
  }
}

class _CommandCenterHeader extends StatelessWidget {
  const _CommandCenterHeader({
    required this.summary,
    required this.readOnly,
  });

  final SalesCommandSummary summary;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.salesCommandCenterTitle,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l.salesCommandCenterSubtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondaryColor(context),
                        ),
                  ),
                ],
              ),
            ),
            if (readOnly) ...[
              const SizedBox(width: AppSpacing.sm),
              AppStatusBadge(
                label: l.readOnlyPreview,
                tone: AppStatusTone.info,
              ),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            _MetricChip(
              label: l.dashboardKpiDueTodayFollowUps,
              value: summary.dueTodayCount,
              tone: AppStatusTone.warning,
            ),
            _MetricChip(
              label: l.dashboardOverdueFollowUps,
              value: summary.overdueCount,
              tone: AppStatusTone.error,
            ),
            _MetricChip(
              label: l.salesCommandMetricHot,
              value: summary.hotOpportunityCount,
              tone: AppStatusTone.info,
            ),
            _MetricChip(
              label: l.dashboardDealRisks,
              value: summary.atRiskCount,
              tone: AppStatusTone.warning,
            ),
          ],
        ),
      ],
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.label,
    required this.value,
    required this.tone,
  });

  final String label;
  final int value;
  final AppStatusTone tone;

  @override
  Widget build(BuildContext context) {
    return AppStatusBadge(label: '$label $value', tone: tone);
  }
}

class _CommandSectionCard extends StatelessWidget {
  const _CommandSectionCard({
    required this.section,
    required this.readOnly,
  });

  final SalesCommandSection section;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.inputSurface(context),
        border: Border.all(color: AppColors.borderColor(context)),
        borderRadius: AppRadius.large,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  _sectionIcon(section.type),
                  size: 18,
                  color: AppColors.primaryColor(context),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    _sectionTitle(l, section.type),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
                AppStatusBadge(
                  label: section.count.toString(),
                  tone: _sectionTone(section.type),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              _sectionSubtitle(l, section.type),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondaryColor(context),
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            if (section.isEmpty)
              _SectionEmpty(message: _sectionEmptyMessage(l, section.type))
            else
              Column(
                children: [
                  for (var index = 0; index < section.items.length; index++) ...[
                    _CommandItemCard(
                      item: section.items[index],
                      readOnly: readOnly,
                    ),
                    if (index != section.items.length - 1)
                      Divider(
                        height: AppSpacing.md,
                        color: AppColors.borderColor(context),
                      ),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _CommandItemCard extends StatelessWidget {
  const _CommandItemCard({
    required this.item,
    required this.readOnly,
  });

  final SalesCommandItem item;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final route = readOnly ? null : _routeFor(item);
    final onOpen = route == null ? null : () => context.go(route);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onOpen,
        borderRadius: AppRadius.large,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PriorityRail(priority: item.priority),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: [
                        AppStatusBadge(
                          label: _priorityLabel(l, item.priority),
                          tone: _priorityTone(item.priority),
                        ),
                        AppStatusBadge(
                          label: _moduleLabel(l, item.module),
                          tone: AppStatusTone.neutral,
                        ),
                        if (_timeLabel(context, item).isNotEmpty)
                          AppStatusBadge(
                            label: _timeLabel(context, item),
                            tone: _timeTone(item),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      _fallback(item.title, _moduleLabel(l, item.module)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    if (item.subtitle.trim().isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        item.subtitle.trim(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondaryColor(context),
                              height: 1.25,
                            ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xs),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '${l.salesCommandWhyThisAppears}: ',
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                          TextSpan(text: _reasonSentence(context, item)),
                        ],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondaryColor(context),
                            height: 1.25,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              SizedBox(
                width: 82,
                child: AppButton(
                  label: l.salesCommandOpenAction,
                  variant: AppButtonVariant.ghost,
                  onPressed: onOpen,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _routeFor(SalesCommandItem item) {
    return switch (item.actionType) {
      DashboardCommandActionType.openLead ||
      DashboardCommandActionType.assignLead =>
        RouteNames.leadDetails(item.recordId),
      DashboardCommandActionType.openTask => RouteNames.taskEdit(item.recordId),
      DashboardCommandActionType.openDeal => RouteNames.dealDetails(item.recordId),
      DashboardCommandActionType.openAppointment =>
        RouteNames.appointmentEdit(item.recordId),
      DashboardCommandActionType.createFollowUp => RouteNames.tasksCreate,
      DashboardCommandActionType.openClient =>
        RouteNames.clientDetails(item.recordId),
      DashboardCommandActionType.openTasks => RouteNames.tasks,
    };
  }
}

class _PriorityRail extends StatelessWidget {
  const _PriorityRail({required this.priority});

  final DashboardPriority priority;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 4,
      height: 76,
      decoration: BoxDecoration(
        color: _priorityColor(context, priority),
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

class _CommandCenterEmpty extends StatelessWidget {
  const _CommandCenterEmpty({required this.summary});

  final SalesCommandSummary summary;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle_outline_rounded,
            color: AppColors.successColor(context),
            size: 22,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              summary.isLimitedForRole
                  ? l.salesCommandLimitedMessage
                  : l.salesCommandEmptyMessage,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondaryColor(context),
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionEmpty extends StatelessWidget {
  const _SectionEmpty({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondaryColor(context),
            fontWeight: FontWeight.w700,
          ),
    );
  }
}

String _sectionTitle(AppLocalizations l, SalesCommandSectionType type) {
  return switch (type) {
    SalesCommandSectionType.todayPriorities =>
      l.salesCommandTodayPrioritiesTitle,
    SalesCommandSectionType.hotOpportunities =>
      l.salesCommandHotOpportunitiesTitle,
    SalesCommandSectionType.overdueFollowUps => l.dashboardOverdueFollowUps,
    SalesCommandSectionType.missedAppointments => l.missedAppointments,
    SalesCommandSectionType.overdueTasks => l.dashboardOverdueTasks,
    SalesCommandSectionType.stuckDeals => l.dashboardStuckDeals,
    SalesCommandSectionType.atRisk => l.salesCommandAtRiskTitle,
    SalesCommandSectionType.teamPressure => l.salesCommandTeamPressureTitle,
  };
}

String _sectionSubtitle(AppLocalizations l, SalesCommandSectionType type) {
  return switch (type) {
    SalesCommandSectionType.todayPriorities =>
      l.salesCommandTodayPrioritiesSubtitle,
    SalesCommandSectionType.hotOpportunities =>
      l.salesCommandHotOpportunitiesSubtitle,
    SalesCommandSectionType.overdueFollowUps =>
      l.salesCommandWhyOverdueFollowUp,
    SalesCommandSectionType.missedAppointments =>
      l.salesCommandWhyAppointmentMissed,
    SalesCommandSectionType.overdueTasks => l.salesCommandWhyOverdueTask,
    SalesCommandSectionType.stuckDeals => l.salesCommandWhyDealAtRisk,
    SalesCommandSectionType.atRisk => l.salesCommandAtRiskSubtitle,
    SalesCommandSectionType.teamPressure =>
      l.salesCommandTeamPressureSubtitle,
  };
}

String _sectionEmptyMessage(AppLocalizations l, SalesCommandSectionType type) {
  return switch (type) {
    SalesCommandSectionType.todayPriorities =>
      l.salesCommandNoTodayPriorities,
    SalesCommandSectionType.hotOpportunities =>
      l.salesCommandNoHotOpportunities,
    SalesCommandSectionType.overdueFollowUps =>
      l.salesCommandNoTodayPriorities,
    SalesCommandSectionType.missedAppointments => l.salesCommandNoAtRisk,
    SalesCommandSectionType.overdueTasks => l.salesCommandNoAtRisk,
    SalesCommandSectionType.stuckDeals => l.salesCommandNoAtRisk,
    SalesCommandSectionType.atRisk => l.salesCommandNoAtRisk,
    SalesCommandSectionType.teamPressure => l.salesCommandNoTeamPressure,
  };
}

IconData _sectionIcon(SalesCommandSectionType type) {
  return switch (type) {
    SalesCommandSectionType.todayPriorities => Icons.bolt_outlined,
    SalesCommandSectionType.hotOpportunities => Icons.local_fire_department_outlined,
    SalesCommandSectionType.overdueFollowUps => Icons.phone_missed_outlined,
    SalesCommandSectionType.missedAppointments => Icons.event_busy_outlined,
    SalesCommandSectionType.overdueTasks => Icons.assignment_late_outlined,
    SalesCommandSectionType.stuckDeals => Icons.hourglass_bottom_outlined,
    SalesCommandSectionType.atRisk => Icons.report_problem_outlined,
    SalesCommandSectionType.teamPressure => Icons.groups_outlined,
  };
}

AppStatusTone _sectionTone(SalesCommandSectionType type) {
  return switch (type) {
    SalesCommandSectionType.todayPriorities => AppStatusTone.warning,
    SalesCommandSectionType.hotOpportunities => AppStatusTone.info,
    SalesCommandSectionType.overdueFollowUps ||
    SalesCommandSectionType.missedAppointments ||
    SalesCommandSectionType.overdueTasks ||
    SalesCommandSectionType.stuckDeals =>
      AppStatusTone.error,
    SalesCommandSectionType.atRisk => AppStatusTone.error,
    SalesCommandSectionType.teamPressure => AppStatusTone.warning,
  };
}

String _priorityLabel(AppLocalizations l, DashboardPriority priority) {
  return switch (priority) {
    DashboardPriority.high => l.high,
    DashboardPriority.medium => l.medium,
    DashboardPriority.low => l.low,
  };
}

String _moduleLabel(AppLocalizations l, DashboardCommandModule module) {
  return switch (module) {
    DashboardCommandModule.lead => l.salesCommandModuleLead,
    DashboardCommandModule.task => l.salesCommandModuleTask,
    DashboardCommandModule.deal => l.salesCommandModuleDeal,
    DashboardCommandModule.appointment => l.salesCommandModuleAppointment,
    DashboardCommandModule.client => l.salesCommandModuleClient,
    DashboardCommandModule.user => l.salesCommandModuleUser,
    DashboardCommandModule.team => l.salesCommandModuleTeam,
  };
}

String _reasonSentence(BuildContext context, SalesCommandItem item) {
  final l = AppLocalizations.of(context)!;
  return switch (item.reason) {
    DashboardAttentionReason.overdueFollowUp =>
      l.salesCommandWhyOverdueFollowUp,
    DashboardAttentionReason.dueTodayFollowUp =>
      l.salesCommandWhyDueTodayFollowUp,
    DashboardAttentionReason.overdueTask => l.salesCommandWhyOverdueTask,
    DashboardAttentionReason.dueTodayTask => l.salesCommandWhyDueTodayTask,
    DashboardAttentionReason.staleLead =>
      l.salesCommandWhyStaleLead(item.ageDays ?? 0),
    DashboardAttentionReason.hotLead => l.salesCommandWhyHotLead,
    DashboardAttentionReason.leadNeedsContact =>
      l.salesCommandWhyLeadNeedsContact,
    DashboardAttentionReason.leadMissingNextStep =>
      l.salesCommandWhyLeadMissingNextStep,
    DashboardAttentionReason.leadNeedsAppointment =>
      l.salesCommandWhyLeadNeedsAppointment,
    DashboardAttentionReason.leadNeedsDeal => l.salesCommandWhyLeadNeedsDeal,
    DashboardAttentionReason.unassignedLead =>
      l.salesCommandWhyUnassignedLead,
    DashboardAttentionReason.appointmentMissed =>
      l.salesCommandWhyAppointmentMissed,
    DashboardAttentionReason.appointmentDueNow =>
      l.salesCommandWhyAppointmentDueNow,
    DashboardAttentionReason.appointmentUpcoming =>
      l.salesCommandWhyAppointmentUpcoming,
    DashboardAttentionReason.appointmentNeedsFeedback =>
      l.salesCommandWhyAppointmentNeedsFeedback,
    DashboardAttentionReason.dealAtRisk => l.salesCommandWhyDealAtRisk,
    DashboardAttentionReason.overloadedAssignee =>
      l.salesCommandWhyOverloadedAssignee(
        _fallback(item.assignedToName, item.title),
        item.count ?? 0,
      ),
  };
}

String _timeLabel(BuildContext context, SalesCommandItem item) {
  final l = AppLocalizations.of(context)!;
  final dueAt = item.dueAt;
  if (dueAt == null) {
    final age = item.ageDays;
    return age == null || age <= 0 ? '' : l.salesCommandAgeDays(age);
  }

  final today = _dateOnly(DateTime.now());
  final dueDay = _dateOnly(dueAt);
  if (dueDay.isBefore(today)) {
    return l.salesCommandOverdueByDays(today.difference(dueDay).inDays);
  }
  if (dueDay == today) {
    return l.salesCommandDueToday;
  }
  return l.salesCommandDueAt(_formatDate(context, dueAt));
}

AppStatusTone _timeTone(SalesCommandItem item) {
  final dueAt = item.dueAt;
  if (dueAt == null) {
    return AppStatusTone.neutral;
  }
  final today = _dateOnly(DateTime.now());
  final dueDay = _dateOnly(dueAt);
  if (dueDay.isBefore(today)) {
    return AppStatusTone.error;
  }
  if (dueDay == today) {
    return AppStatusTone.warning;
  }
  return AppStatusTone.info;
}

String _formatDate(BuildContext context, DateTime value) {
  final localeName = AppLocalizations.of(context)!.localeName;
  return intl.DateFormat.MMMd(localeName).add_jm().format(value.toLocal());
}

DateTime _dateOnly(DateTime value) {
  final local = value.toLocal();
  return DateTime(local.year, local.month, local.day);
}

AppStatusTone _priorityTone(DashboardPriority priority) {
  return switch (priority) {
    DashboardPriority.high => AppStatusTone.error,
    DashboardPriority.medium => AppStatusTone.warning,
    DashboardPriority.low => AppStatusTone.info,
  };
}

int _priorityRank(DashboardPriority priority) {
  return switch (priority) {
    DashboardPriority.high => 3,
    DashboardPriority.medium => 2,
    DashboardPriority.low => 1,
  };
}

Color _priorityColor(BuildContext context, DashboardPriority priority) {
  return switch (priority) {
    DashboardPriority.high => AppColors.errorColor(context),
    DashboardPriority.medium => AppColors.warningColor(context),
    DashboardPriority.low => AppColors.infoColor(context),
  };
}

String _fallback(String value, String fallback) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? fallback.trim() : trimmed;
}


String _salesCommandFooterLabel(AppLocalizations l) {
  return l.localeName.toLowerCase().startsWith('ar')
      ? 'تحتاج إلى متابعة الآن'
      : 'Needs attention now';
}
