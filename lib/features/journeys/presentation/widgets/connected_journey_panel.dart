import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_status_badge.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/datasources/connected_journey_remote_data_source.dart';
import '../../data/repositories/connected_journey_repository_impl.dart';
import '../../domain/entities/connected_journey.dart';
import '../../domain/usecases/watch_connected_journey_usecase.dart';
import '../cubit/connected_journey_cubit.dart';
import '../cubit/connected_journey_state.dart';

class ConnectedJourneyPanel extends StatelessWidget {
  const ConnectedJourneyPanel({
    super.key,
    required this.recordType,
    required this.recordId,
    required this.scope,
    this.baseItems = const <JourneyItem>[],
    this.recommendations = const <JourneyRecommendation>[],
    this.compact = false,
  });

  final JourneyRecordType recordType;
  final String recordId;
  final JourneyQueryScope scope;
  final List<JourneyItem> baseItems;
  final List<JourneyRecommendation> recommendations;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final repository = ConnectedJourneyRepositoryImpl(
      remoteDataSource: FirestoreConnectedJourneyRemoteDataSource(),
    );
    return BlocProvider(
      key: ValueKey('journey:${scope.companyId}:${scope.currentUserId}:${recordType.name}:$recordId'),
      create: (_) => ConnectedJourneyCubit(
        watchConnectedJourneyUseCase: WatchConnectedJourneyUseCase(repository),
      )..watch(recordType: recordType, recordId: recordId, scope: scope),
      child: _ConnectedJourneyBody(
        baseItems: baseItems,
        recommendations: recommendations,
        compact: compact,
      ),
    );
  }
}

class _ConnectedJourneyBody extends StatelessWidget {
  const _ConnectedJourneyBody({
    required this.baseItems,
    required this.recommendations,
    required this.compact,
  });

  final List<JourneyItem> baseItems;
  final List<JourneyRecommendation> recommendations;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return BlocBuilder<ConnectedJourneyCubit, ConnectedJourneyState>(
      builder: (context, state) {
        final items = _mergedItems(baseItems, state.remoteItems);
        final loading = state.status == ConnectedJourneyStatus.loading && items.isEmpty;
        return Container(
          padding: EdgeInsets.all(compact ? AppSpacing.sm : AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.cardSurface(context),
            border: Border.all(color: AppColors.borderColor(context)),
            borderRadius: AppRadius.large,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor(context).withValues(alpha: 0.12),
                      borderRadius: AppRadius.medium,
                    ),
                    child: Icon(
                      Icons.account_tree_outlined,
                      size: 18,
                      color: AppColors.primaryColor(context),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.connectedJourneyTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                height: 1.1,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l.connectedJourneySubtitle,
                          maxLines: compact ? 1 : 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondaryColor(context),
                                fontWeight: FontWeight.w500,
                                height: 1.25,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _JourneySummaryStrip(items: items),
              const SizedBox(height: AppSpacing.md),
              _RecommendationStrip(recommendations: recommendations),
              const SizedBox(height: AppSpacing.md),
              if (loading)
                const Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.3),
                  ),
                )
              else if (items.isEmpty)
                _JourneyEmptyState(message: l.journeyNoActivity)
              else
                Column(
                  children: [
                    for (var index = 0; index < items.length; index++)
                      _JourneyTimelineTile(
                        item: items[index],
                        isLast: index == items.length - 1,
                      ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}


class _JourneySummaryStrip extends StatelessWidget {
  const _JourneySummaryStrip({required this.items});

  final List<JourneyItem> items;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final counts = [
      _JourneySummaryMetric(
        label: l.timeline,
        value: items
            .where((item) => item.targetType != JourneyTargetType.task &&
                item.targetType != JourneyTargetType.appointment &&
                item.targetType != JourneyTargetType.deal)
            .length,
        icon: Icons.timeline_outlined,
        tone: JourneyTone.info,
      ),
      _JourneySummaryMetric(
        label: l.tasks,
        value: items.where((item) => item.targetType == JourneyTargetType.task).length,
        icon: Icons.task_alt_outlined,
        tone: JourneyTone.warning,
      ),
      _JourneySummaryMetric(
        label: l.appointments,
        value: items.where((item) => item.targetType == JourneyTargetType.appointment).length,
        icon: Icons.event_available_outlined,
        tone: JourneyTone.success,
      ),
      _JourneySummaryMetric(
        label: l.deals,
        value: items.where((item) => item.targetType == JourneyTargetType.deal).length,
        icon: Icons.handshake_outlined,
        tone: JourneyTone.neutral,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth < 520 ? 2 : 4;
        const gap = 7.0;
        final width = (constraints.maxWidth - ((columns - 1) * gap)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final metric in counts)
              SizedBox(
                width: width,
                child: _JourneySummaryChip(metric: metric),
              ),
          ],
        );
      },
    );
  }
}

class _JourneySummaryMetric {
  const _JourneySummaryMetric({
    required this.label,
    required this.value,
    required this.icon,
    required this.tone,
  });

  final String label;
  final int value;
  final IconData icon;
  final JourneyTone tone;
}

class _JourneySummaryChip extends StatelessWidget {
  const _JourneySummaryChip({required this.metric});

  final _JourneySummaryMetric metric;

  @override
  Widget build(BuildContext context) {
    final color = _toneColor(context, metric.tone);
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 9, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.inputSurface(context),
        border: Border.all(color: AppColors.borderColor(context)),
        borderRadius: AppRadius.medium,
      ),
      child: Row(
        children: [
          Icon(metric.icon, size: 15, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              metric.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textSecondaryColor(context),
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          Text(
            metric.value.toString(),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w900,
                ),
          ),
        ],
      ),
    );
  }
}

class _RecommendationStrip extends StatelessWidget {
  const _RecommendationStrip({required this.recommendations});

  final List<JourneyRecommendation> recommendations;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final visible = recommendations.isEmpty
        ? [
            JourneyRecommendation(
              title: l.journeyActionEverythingCalm,
              subtitle: l.journeyActionEverythingCalmDescription,
              tone: JourneyTone.success,
            ),
          ]
        : recommendations.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l.journeyRecommendedNextAction,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.textSecondaryColor(context),
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: AppSpacing.xs),
        for (var index = 0; index < visible.length; index++) ...[
          _RecommendationCard(recommendation: visible[index]),
          if (index != visible.length - 1) const SizedBox(height: AppSpacing.xs),
        ],
      ],
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({required this.recommendation});

  final JourneyRecommendation recommendation;

  @override
  Widget build(BuildContext context) {
    final color = _toneColor(context, recommendation.tone);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color.withValues(alpha: 0.22)),
        borderRadius: AppRadius.large,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_recommendationIcon(recommendation.tone), color: color, size: 18),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recommendation.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  recommendation.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondaryColor(context),
                        fontWeight: FontWeight.w500,
                        height: 1.25,
                      ),
                ),
              ],
            ),
          ),
          if (recommendation.hasAction) ...[
            const SizedBox(width: AppSpacing.xs),
            AppButton(
              label: recommendation.actionLabel,
              variant: AppButtonVariant.secondary,
              onPressed: () => context.go(recommendation.actionRoute),
            ),
          ],
        ],
      ),
    );
  }
}

class _JourneyTimelineTile extends StatelessWidget {
  const _JourneyTimelineTile({required this.item, required this.isLast});

  final JourneyItem item;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final color = _toneColor(context, item.tone);
    final route = _targetRoute(item);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 26,
            child: Column(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(color: color.withValues(alpha: 0.30)),
                  ),
                  child: Icon(_itemIcon(item), color: color, size: 13),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 1,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: AppColors.borderColor(context),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.sm),
              child: Material(
                color: AppColors.inputSurface(context),
                borderRadius: AppRadius.large,
                child: InkWell(
                  onTap: route == null ? null : () => context.go(route),
                  borderRadius: AppRadius.large,
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.borderColor(context)),
                      borderRadius: AppRadius.large,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _itemTitle(l, item),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            AppStatusBadge(
                              label: _targetLabel(l, item.targetType),
                              tone: _statusTone(item.tone),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        if (item.title.trim().isNotEmpty)
                          Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.textPrimaryColor(context),
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        if (item.subtitle.trim().isNotEmpty)
                          Text(
                            item.subtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondaryColor(context),
                                  fontWeight: FontWeight.w500,
                                  height: 1.25,
                                ),
                          ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _itemMetaLine(context, item),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: AppColors.textMutedColor(context),
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                            if (route != null)
                              Text(
                                l.journeyOpenRecord,
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: AppColors.primaryColor(context),
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _JourneyEmptyState extends StatelessWidget {
  const _JourneyEmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.inputSurface(context),
        borderRadius: AppRadius.large,
        border: Border.all(color: AppColors.borderColor(context)),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondaryColor(context),
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

List<JourneyItem> _mergedItems(List<JourneyItem> baseItems, List<JourneyItem> remoteItems) {
  final map = <String, JourneyItem>{};
  for (final item in [...baseItems, ...remoteItems]) {
    map[item.id] = item;
  }
  final items = map.values.toList()
    ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
  return items.take(60).toList();
}

String? _targetRoute(JourneyItem item) {
  if (item.targetId.trim().isEmpty) {
    return null;
  }
  return switch (item.targetType) {
    JourneyTargetType.lead => RouteNames.leadDetails(item.targetId),
    JourneyTargetType.client => RouteNames.clientDetails(item.targetId),
    JourneyTargetType.task => RouteNames.taskEdit(item.targetId),
    JourneyTargetType.appointment => RouteNames.appointmentEdit(item.targetId),
    JourneyTargetType.deal => RouteNames.dealDetails(item.targetId),
    JourneyTargetType.audit || JourneyTargetType.system => null,
  };
}

String _itemTitle(AppLocalizations l, JourneyItem item) {
  return switch (item.type) {
    JourneyItemType.recordCreated => l.journeyItemRecordCreated,
    JourneyItemType.recordUpdated => l.updated,
    JourneyItemType.recordArchived => l.archived,
    JourneyItemType.recordRestored => l.restore,
    JourneyItemType.leadTimeline => l.timeline,
    JourneyItemType.taskCreated => l.createTask,
    JourneyItemType.taskUpdated => l.tasks,
    JourneyItemType.taskCompleted => l.completed,
    JourneyItemType.taskCancelled => l.cancelled,
    JourneyItemType.taskOverdue => l.overdue,
    JourneyItemType.appointmentCreated => l.newAppointment,
    JourneyItemType.appointmentScheduled => l.scheduledAt,
    JourneyItemType.appointmentCompleted => l.completed,
    JourneyItemType.appointmentCancelled => l.cancelled,
    JourneyItemType.appointmentMissed => l.missedAppointments,
    JourneyItemType.appointmentRescheduled => l.reschedule,
    JourneyItemType.dealCreated => l.createDeal,
    JourneyItemType.dealUpdated => l.deals,
    JourneyItemType.dealStageChanged => l.updateStage,
    JourneyItemType.dealWon => l.won,
    JourneyItemType.dealLost => l.lost,
    JourneyItemType.dealAtRisk => l.dashboardStuckDeals,
    JourneyItemType.auditCreated => l.journeyItemAuditCreated,
    JourneyItemType.auditUpdated => l.journeyItemAuditUpdated,
  };
}

String _targetLabel(AppLocalizations l, JourneyTargetType type) {
  return switch (type) {
    JourneyTargetType.lead => l.lead,
    JourneyTargetType.client => l.client,
    JourneyTargetType.task => l.tasks,
    JourneyTargetType.appointment => l.appointments,
    JourneyTargetType.deal => l.deals,
    JourneyTargetType.audit => l.auditInfo,
    JourneyTargetType.system => l.system,
  };
}

IconData _itemIcon(JourneyItem item) {
  return switch (item.targetType) {
    JourneyTargetType.lead => Icons.person_search_outlined,
    JourneyTargetType.client => Icons.person_outline_rounded,
    JourneyTargetType.task => Icons.task_alt_rounded,
    JourneyTargetType.appointment => Icons.event_available_outlined,
    JourneyTargetType.deal => Icons.handshake_outlined,
    JourneyTargetType.audit => Icons.history_rounded,
    JourneyTargetType.system => Icons.auto_awesome_motion_outlined,
  };
}

IconData _recommendationIcon(JourneyTone tone) {
  return switch (tone) {
    JourneyTone.success => Icons.check_circle_outline_rounded,
    JourneyTone.warning => Icons.warning_amber_rounded,
    JourneyTone.danger => Icons.report_problem_outlined,
    JourneyTone.info => Icons.lightbulb_outline_rounded,
    JourneyTone.neutral => Icons.info_outline_rounded,
  };
}

Color _toneColor(BuildContext context, JourneyTone tone) {
  return switch (tone) {
    JourneyTone.success => AppColors.successColor(context),
    JourneyTone.warning => AppColors.warningColor(context),
    JourneyTone.danger => AppColors.errorColor(context),
    JourneyTone.info => AppColors.infoColor(context),
    JourneyTone.neutral => AppColors.textMutedColor(context),
  };
}

AppStatusTone _statusTone(JourneyTone tone) {
  return switch (tone) {
    JourneyTone.success => AppStatusTone.success,
    JourneyTone.warning => AppStatusTone.warning,
    JourneyTone.danger => AppStatusTone.error,
    JourneyTone.info => AppStatusTone.info,
    JourneyTone.neutral => AppStatusTone.neutral,
  };
}

String _itemMetaLine(BuildContext context, JourneyItem item) {
  final actor = item.actorName.trim();
  final date = _formatDate(context, item.occurredAt);
  if (actor.isEmpty) {
    return date;
  }
  return '$actor • $date';
}

String _formatDate(BuildContext context, DateTime value) {
  return DateFormat.yMMMd(Localizations.localeOf(context).toString())
      .add_jm()
      .format(value.toLocal());
}
