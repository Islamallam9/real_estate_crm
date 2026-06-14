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
                        if (_journeyDetail(l, item).isNotEmpty)
                          Text(
                            _journeyDetail(l, item),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondaryColor(context),
                                  fontWeight: FontWeight.w700,
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

String _journeyDetail(AppLocalizations l, JourneyItem item) {
  return switch (item.targetType) {
    JourneyTargetType.lead => _leadJourneyDetail(l, item),
    JourneyTargetType.client => _clientJourneyDetail(l, item),
    JourneyTargetType.task => _taskJourneyDetail(l, item),
    JourneyTargetType.appointment => _appointmentJourneyDetail(l, item),
    JourneyTargetType.deal => _dealJourneyDetail(l, item),
    JourneyTargetType.audit => _auditJourneyDetail(l, item),
    JourneyTargetType.system => _reasonDetail(l, item),
  };
}

String _leadJourneyDetail(AppLocalizations l, JourneyItem item) {
  final parts = <String>[];
  _addMetadataLabel(parts, l.status, _statusValueLabel(l, _metadata(item, 'status')));
  _addMetadataLabel(parts, l.priority, _priorityValueLabel(l, _metadata(item, 'priority')));
  _addMetadataLabel(parts, l.source, _sourceValueLabel(l, _metadata(item, 'source')));
  _addMetadataLabel(parts, l.assignedToLabel, _metadata(item, 'assignedToName'));
  _addMetadataLabel(parts, l.lastContact, _journeyMetadataDateTimeLabel(l, _metadata(item, 'lastContactAt')));
  _addMetadataLabel(parts, l.nextFollowUp, _journeyMetadataDateTimeLabel(l, _metadata(item, 'nextFollowUpAt')));
  return _firstDetail(parts, fallback: _reasonDetail(l, item));
}

String _clientJourneyDetail(AppLocalizations l, JourneyItem item) {
  final parts = <String>[];
  final budgetMin = _metadata(item, 'budgetMin');
  final budgetMax = _metadata(item, 'budgetMax');
  if (budgetMin.isNotEmpty || budgetMax.isNotEmpty) {
    _addMetadataLabel(parts, l.budget, [budgetMin, budgetMax].where((v) => v.trim().isNotEmpty).join(' - '));
  }
  _addMetadataLabel(parts, l.preferredLocation, _metadata(item, 'preferredLocation'));
  _addMetadataLabel(parts, l.preferredPropertyType, _metadata(item, 'preferredPropertyType'));
  _addMetadataLabel(parts, l.assignedToLabel, _metadata(item, 'assignedToName'));
  return _firstDetail(parts, fallback: _reasonDetail(l, item));
}

String _taskJourneyDetail(AppLocalizations l, JourneyItem item) {
  final parts = <String>[];
  _addMetadataLabel(parts, l.status, _taskStatusLabel(l, _metadata(item, 'status')));
  _addMetadataLabel(parts, l.priority, _priorityValueLabel(l, _metadata(item, 'priority')));
  _addMetadataLabel(parts, l.dueDate, _journeyMetadataDateTimeLabel(l, _metadata(item, 'dueDate')));
  _addMetadataLabel(parts, l.assignedToLabel, _metadata(item, 'assignedToName'));
  return _firstDetail(parts, fallback: _reasonDetail(l, item));
}

String _appointmentJourneyDetail(AppLocalizations l, JourneyItem item) {
  final parts = <String>[];
  if (item.type == JourneyItemType.appointmentRescheduled) {
    final previousScheduledAt = _metadata(item, 'previousScheduledAt');
    final scheduledAt = _metadata(item, 'scheduledAt');
    if (previousScheduledAt.isNotEmpty && scheduledAt.isNotEmpty) {
      parts.add(l.changedFromTo(
        _journeyMetadataDateTimeLabel(l, previousScheduledAt),
        _journeyMetadataDateTimeLabel(l, scheduledAt),
      ));
    }
  }
  _addMetadataLabel(parts, l.status, _appointmentStatusLabel(l, _metadata(item, 'status')));
  _addMetadataLabel(parts, l.scheduledAt, _journeyMetadataDateTimeLabel(l, _metadata(item, 'scheduledAt')));
  _addMetadataLabel(parts, l.appointmentOutcome, _appointmentOutcomeLabel(l, _metadata(item, 'outcome')));
  _addMetadataLabel(parts, l.cancellationReason, _metadata(item, 'cancellationReason'));
  _addMetadataLabel(parts, l.notes, _metadata(item, 'outcomeNotes'));
  return _firstDetail(parts, fallback: _reasonDetail(l, item));
}

String _dealJourneyDetail(AppLocalizations l, JourneyItem item) {
  final parts = <String>[];
  _addMetadataLabel(parts, l.stage, _dealStageLabel(l, _metadata(item, 'stage')));
  _addMetadataLabel(parts, l.expectedValue, _numberLabel(_metadata(item, 'expectedValue')));
  _addMetadataLabel(parts, l.commission, _numberLabel(_metadata(item, 'commission')));
  _addMetadataLabel(parts, l.closingDate, _journeyMetadataDateTimeLabel(l, _metadata(item, 'closingDate')));
  _addMetadataLabel(parts, l.lostReason, _dealLostReasonLabel(l, _metadata(item, 'lostReason')));
  _addMetadataLabel(parts, l.assignedToLabel, _metadata(item, 'assignedToName'));
  return _firstDetail(parts, fallback: _reasonDetail(l, item));
}

String _auditJourneyDetail(AppLocalizations l, JourneyItem item) {
  final parts = <String>[];
  final changedFields = item.metadata['changedFields'];
  if (changedFields is Iterable) {
    for (final entry in changedFields) {
      if (entry is! Map) {
        continue;
      }
      final field = (entry['field'] ?? '').toString();
      final oldValue = (entry['oldValue'] ?? '').toString();
      final newValue = (entry['newValue'] ?? '').toString();
      if (field.trim().isEmpty || oldValue == newValue) {
        continue;
      }
      parts.add('${_auditFieldLabel(l, field)}: ${l.changedFromTo(
        _auditValueLabel(l, field, oldValue),
        _auditValueLabel(l, field, newValue),
      )}');
    }
  }
  _addMetadataLabel(parts, l.status, _auditValueLabel(l, 'status', _metadata(item, 'newStatus')));
  _addMetadataLabel(parts, l.assignedToLabel, _metadata(item, 'assignedToName'));
  _addMetadataLabel(parts, l.lostReason, _dealLostReasonLabel(l, _metadata(item, 'lostReason')));
  _addMetadataLabel(parts, l.cancellationReason, _metadata(item, 'cancellationReason'));
  _addMetadataLabel(parts, l.appointmentOutcome, _appointmentOutcomeLabel(l, _metadata(item, 'outcome')));
  _addMetadataLabel(parts, l.notes, _metadata(item, 'notes'));
  return _firstDetail(parts, fallback: _reasonDetail(l, item));
}

String _reasonDetail(AppLocalizations l, JourneyItem item) {
  final reason = _metadata(item, 'reason').trim();
  if (reason.isNotEmpty) {
    return '${l.journeyReason}: $reason';
  }
  return '';
}

void _addMetadataLabel(List<String> parts, String label, String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty || trimmed == '0' || trimmed == '0.0') {
    return;
  }
  parts.add('$label: $trimmed');
}

String _firstDetail(List<String> parts, {String fallback = ''}) {
  final clean = parts.where((part) => part.trim().isNotEmpty).take(3).toList();
  if (clean.isNotEmpty) {
    return clean.join(' • ');
  }
  return fallback;
}

String _metadata(JourneyItem item, String key) {
  final value = item.metadata[key];
  return value == null ? '' : value.toString().trim();
}

String _numberLabel(String value) {
  final parsed = num.tryParse(value.trim());
  if (parsed == null || parsed == 0) {
    return '';
  }
  return parsed.toStringAsFixed(parsed.truncateToDouble() == parsed ? 0 : 2);
}

String _journeyMetadataDateTimeLabel(AppLocalizations l, String value) {
  final parsed = DateTime.tryParse(value);
  if (parsed == null) {
    return value;
  }
  return DateFormat.yMMMd(l.localeName).add_jm().format(parsed.toLocal());
}

String _appointmentOutcomeLabel(AppLocalizations l, String value) {
  return switch (value) {
    'successfulMeeting' => l.appointmentOutcomeSuccessfulMeeting,
    'noAnswer' => l.appointmentOutcomeNoAnswer,
    'clientPostponed' => l.appointmentOutcomeClientPostponed,
    'clientNotInterested' => l.appointmentOutcomeClientNotInterested,
    'followUpNeeded' => l.appointmentOutcomeFollowUpNeeded,
    'dealOpportunity' => l.appointmentOutcomeDealOpportunity,
    'pendingDecision' => l.appointmentOutcomePendingDecision,
    'other' => l.appointmentOutcomeOther,
    _ => value,
  };
}

String _appointmentStatusLabel(AppLocalizations l, String value) {
  return switch (value) {
    'scheduled' => l.localeName.toLowerCase().startsWith('ar') ? 'مجدول' : 'Scheduled',
    'rescheduled' => l.localeName.toLowerCase().startsWith('ar') ? 'أُعيدت جدولته' : 'Rescheduled',
    'completed' => l.completed,
    'cancelled' || 'canceled' => l.cancelled,
    'missed' => l.localeName.toLowerCase().startsWith('ar') ? 'فائت' : 'Missed',
    _ => value,
  };
}

String _taskStatusLabel(AppLocalizations l, String value) {
  return switch (value) {
    'pending' => l.pending,
    'inProgress' => l.inProgress,
    'completed' => l.completed,
    'cancelled' || 'canceled' => l.cancelled,
    _ => value,
  };
}

String _priorityValueLabel(AppLocalizations l, String value) {
  return switch (value) {
    'high' => l.high,
    'medium' => l.medium,
    'low' => l.low,
    _ => value,
  };
}

String _sourceValueLabel(AppLocalizations l, String value) {
  return switch (value) {
    'facebook' => l.facebook,
    'website' => l.website,
    'phoneCall' => l.phoneCall,
    'whatsapp' => l.whatsapp,
    'referral' => l.referral,
    'walkIn' => l.walkIn,
    'other' => l.other,
    _ => value,
  };
}

String _statusValueLabel(AppLocalizations l, String value) {
  return switch (value) {
    'newLead' || 'new' => l.newLeadStatus,
    'contacted' => l.contactedLeadStatus,
    'interested' => l.interestedLeadStatus,
    'visitScheduled' => l.visitScheduledLeadStatus,
    'negotiation' => l.negotiationLeadStatus,
    'won' => l.wonLeadStatus,
    'lost' => l.lostLeadStatus,
    _ => value,
  };
}

String _dealStageLabel(AppLocalizations l, String value) {
  return switch (value) {
    'new' || 'newDeal' => l.newDealStage,
    'qualified' => l.qualified,
    'proposal' => l.proposal,
    'negotiation' => l.negotiation,
    'won' => l.won,
    'lost' => l.lost,
    _ => value,
  };
}

String _dealLostReasonLabel(AppLocalizations l, String value) {
  return switch (value) {
    'budgetMismatch' => l.dealLostReasonBudgetMismatch,
    'locationMismatch' => l.dealLostReasonLocationMismatch,
    'boughtElsewhere' => l.dealLostReasonBoughtElsewhere,
    'notReady' => l.dealLostReasonNotReady,
    'noResponse' => l.dealLostReasonNoResponse,
    'wrongNumber' => l.dealLostReasonWrongNumber,
    'lostToCompetitor' => l.dealLostReasonLostToCompetitor,
    'duplicate' => l.dealLostReasonDuplicate,
    'other' => l.dealLostReasonOther,
    _ => value,
  };
}

String _auditFieldLabel(AppLocalizations l, String field) {
  return switch (field) {
    'status' || 'appointmentStatus' || 'taskStatus' => l.status,
    'stage' => l.stage,
    'assignedTo' || 'assignedToName' => l.assignedToLabel,
    'scheduledAt' => l.scheduledAt,
    'dueDate' => l.dueDate,
    'outcome' => l.appointmentOutcome,
    'lostReason' => l.lostReason,
    'cancellationReason' => l.cancellationReason,
    'expectedValue' => l.expectedValue,
    'commission' => l.commission,
    'priority' => l.priority,
    'source' => l.source,
    'nextFollowUpAt' => l.nextFollowUp,
    'lastContactAt' => l.lastContact,
    _ => field,
  };
}

String _auditValueLabel(AppLocalizations l, String field, String value) {
  if (value.trim().isEmpty) {
    return l.notAvailable;
  }
  return switch (field) {
    'status' => _statusValueLabel(l, value),
    'stage' => _dealStageLabel(l, value),
    'priority' => _priorityValueLabel(l, value),
    'source' => _sourceValueLabel(l, value),
    'outcome' => _appointmentOutcomeLabel(l, value),
    'lostReason' => _dealLostReasonLabel(l, value),
    'scheduledAt' || 'dueDate' || 'nextFollowUpAt' || 'lastContactAt' =>
      _journeyMetadataDateTimeLabel(l, value),
    _ => value,
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
