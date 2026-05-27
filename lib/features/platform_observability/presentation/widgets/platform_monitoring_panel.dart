import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_dropdown.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_status_badge.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../users/domain/entities/company_metadata.dart';
import '../../../platform_notifications/domain/entities/platform_notification.dart';
import '../../../platform_notifications/presentation/cubit/platform_notifications_cubit.dart';
import '../../../platform_notifications/presentation/cubit/platform_notifications_state.dart';
import '../../domain/entities/platform_error_log.dart';
import '../cubit/platform_observability_cubit.dart';
import '../cubit/platform_observability_state.dart';

class PlatformMonitoringPanel extends StatelessWidget {
  const PlatformMonitoringPanel({super.key, required this.companies});

  final List<CompanyMetadata> companies;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return BlocConsumer<PlatformObservabilityCubit, PlatformObservabilityState>(
      listenWhen: (previous, current) =>
          previous.message != current.message && current.message != null,
      listener: (context, state) {
        AppFeedback.error(context, (state.message ?? l.errorOccurred).replaceFirst('Exception: ', ''));
      },
      builder: (context, state) {
        return _MonitoringPanelShell(
          title: l.platformMonitoring,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l.platformMonitoringSubtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondaryColor(context),
                    ),
              ),
              const SizedBox(height: AppSpacing.md),
              BlocBuilder<PlatformNotificationsCubit, PlatformNotificationsState>(
                builder: (context, notificationState) {
                  return _MonitoringKpis(
                    state: state,
                    notificationErrorCount: _notificationErrorCount(notificationState.notifications),
                    notificationErrorTodayCount: _notificationErrorTodayCount(notificationState.notifications),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.md),
              _MonitoringFilters(state: state, companies: companies),
              const SizedBox(height: AppSpacing.md),
              if (state.status == PlatformObservabilityStatus.loading)
                const AppLoading()
              else if (state.filteredLogs.isEmpty)
                AppEmptyState(
                  icon: Icons.monitor_heart_outlined,
                  title: l.noPlatformErrors,
                  message: l.noPlatformErrorsMessage,
                )
              else
                Column(
                  children: [
                    for (final log in state.filteredLogs) ...[
                      _ErrorLogCard(log: log),
                      if (log != state.filteredLogs.last)
                        const SizedBox(height: AppSpacing.sm),
                    ],
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}

class _MonitoringPanelShell extends StatelessWidget {
  const _MonitoringPanelShell({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.cardSurface(context),
        border: Border.all(color: AppColors.borderColor(context)),
        borderRadius: AppRadius.xLarge,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}


int _notificationErrorCount(List<PlatformNotification> notifications) {
  return notifications.where(_isErrorNotification).length;
}

int _notificationErrorTodayCount(List<PlatformNotification> notifications) {
  final now = DateTime.now();
  final start = DateTime(now.year, now.month, now.day);
  return notifications.where((notification) {
    final createdAt = notification.createdAt?.toLocal();
    return _isErrorNotification(notification) &&
        createdAt != null &&
        !createdAt.isBefore(start);
  }).length;
}

bool _isErrorNotification(PlatformNotification notification) {
  return notification.type == PlatformNotificationType.platformFunctionFailed ||
      notification.severity == PlatformNotificationSeverity.urgent ||
      notification.source == PlatformNotificationSource.system;
}

class _MonitoringKpis extends StatelessWidget {
  const _MonitoringKpis({
    required this.state,
    required this.notificationErrorCount,
    required this.notificationErrorTodayCount,
  });

  final PlatformObservabilityState state;
  final int notificationErrorCount;
  final int notificationErrorTodayCount;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1000
            ? 4
            : constraints.maxWidth >= 640
                ? 2
                : 1;
        return GridView.count(
          crossAxisCount: columns,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AppSpacing.sm,
          crossAxisSpacing: AppSpacing.sm,
          childAspectRatio: constraints.maxWidth < 520 ? 3.4 : 2.9,
          children: [
            _MonitoringKpiCard(
              label: l.activeIncidents,
              value: (state.activeIncidentCount + notificationErrorCount).toString(),
              icon: Icons.warning_amber_outlined,
              tone: AppStatusTone.warning,
            ),
            _MonitoringKpiCard(
              label: l.fatalErrors,
              value: state.fatalErrorCount.toString(),
              icon: Icons.error_outline,
              tone: AppStatusTone.error,
            ),
            _MonitoringKpiCard(
              label: l.errorsToday,
              value: (state.errorsTodayCount + notificationErrorTodayCount).toString(),
              icon: Icons.today_outlined,
              tone: AppStatusTone.info,
            ),
            _MonitoringKpiCard(
              label: l.affectedCompanies,
              value: state.affectedCompanyCount.toString(),
              icon: Icons.apartment_outlined,
              tone: AppStatusTone.neutral,
            ),
          ],
        );
      },
    );
  }
}

class _MonitoringKpiCard extends StatelessWidget {
  const _MonitoringKpiCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.tone,
  });

  final String label;
  final String value;
  final IconData icon;
  final AppStatusTone tone;

  @override
  Widget build(BuildContext context) {
    final color = _toneColor(context, tone);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.inputSurface(context),
        border: Border.all(color: AppColors.borderColor(context)),
        borderRadius: AppRadius.large,
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .12),
              borderRadius: AppRadius.large,
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondaryColor(context),
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MonitoringFilters extends StatelessWidget {
  const _MonitoringFilters({required this.state, required this.companies});

  final PlatformObservabilityState state;
  final List<CompanyMetadata> companies;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cubit = context.read<PlatformObservabilityCubit>();
    final companyIds = <String>['', ...companies.map((company) => company.id)];
    final modules = <String>['', ...state.modules];
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        SizedBox(
          width: 240,
          child: AppDropdown<String>(
            label: l.company,
            value: state.companyId,
            items: companyIds,
            itemLabelBuilder: (id) {
              if (id.isEmpty) {
                return l.allCompanies;
              }
              return _companyNameFor(companies, id);
            },
            onChanged: cubit.setCompany,
          ),
        ),
        SizedBox(
          width: 190,
          child: AppDropdown<String>(
            label: l.severity,
            value: state.severity == null
                ? ''
                : platformErrorSeverityValue(state.severity!),
            items: [
              '',
              for (final severity in PlatformErrorSeverity.values)
                platformErrorSeverityValue(severity),
            ],
            itemLabelBuilder: (value) => value.isEmpty
                ? l.allSeverities
                : _severityLabel(l, platformErrorSeverityFromValue(value)),
            onChanged: (value) => cubit.setSeverity(
              value.isEmpty ? null : platformErrorSeverityFromValue(value),
            ),
          ),
        ),
        SizedBox(
          width: 220,
          child: AppDropdown<String>(
            label: l.source,
            value: state.source == null
                ? ''
                : platformErrorSourceValue(state.source!),
            items: [
              '',
              for (final source in PlatformErrorSource.values)
                platformErrorSourceValue(source),
            ],
            itemLabelBuilder: (value) => value.isEmpty
                ? l.allErrorSources
                : _sourceLabel(l, platformErrorSourceFromValue(value)),
            onChanged: (value) => cubit.setSource(
              value.isEmpty ? null : platformErrorSourceFromValue(value),
            ),
          ),
        ),
        SizedBox(
          width: 190,
          child: AppDropdown<String>(
            label: l.module,
            value: state.module,
            items: modules,
            itemLabelBuilder: (value) => value.isEmpty ? l.allModules : value,
            onChanged: cubit.setModule,
          ),
        ),
        SizedBox(
          width: 210,
          child: AppDropdown<PlatformErrorResolvedFilter>(
            label: l.status,
            value: state.resolvedFilter,
            items: PlatformErrorResolvedFilter.values,
            itemLabelBuilder: (filter) => _resolvedFilterLabel(l, filter),
            onChanged: cubit.setResolvedFilter,
          ),
        ),
        SizedBox(
          width: 180,
          child: AppDropdown<PlatformErrorDateFilter>(
            label: l.filterByDate,
            value: state.dateFilter,
            items: PlatformErrorDateFilter.values,
            itemLabelBuilder: (filter) => _dateFilterLabel(l, filter),
            onChanged: cubit.setDateFilter,
          ),
        ),
      ],
    );
  }
}

class _ErrorLogCard extends StatelessWidget {
  const _ErrorLogCard({required this.log});

  final PlatformErrorLog log;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final severityColor = _severityColor(context, log.severity);
    final isResolving = context.select(
      (PlatformObservabilityCubit cubit) => cubit.state.resolvingLogId == log.id,
    );

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: log.resolved
            ? AppColors.cardSurface(context)
            : severityColor.withValues(alpha: .05),
        border: Border.all(
          color: log.resolved
              ? AppColors.borderColor(context)
              : severityColor.withValues(alpha: .34),
        ),
        borderRadius: AppRadius.large,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 720;
          final header = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: severityColor.withValues(alpha: .12),
                  borderRadius: AppRadius.large,
                ),
                child: Icon(
                  log.severity == PlatformErrorSeverity.fatal
                      ? Icons.dangerous_outlined
                      : Icons.error_outline,
                  color: severityColor,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: _ErrorLogSummary(log: log)),
            ],
          );
          final actions = _ErrorLogActions(
            log: log,
            isResolving: isResolving,
          );

          if (narrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                header,
                const SizedBox(height: AppSpacing.sm),
                _ErrorMetaWrap(log: log),
                const SizedBox(height: AppSpacing.sm),
                actions,
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    header,
                    const SizedBox(height: AppSpacing.sm),
                    _ErrorMetaWrap(log: log),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              SizedBox(width: 170, child: actions),
            ],
          );
        },
      ),
    );
  }
}

class _ErrorLogSummary extends StatelessWidget {
  const _ErrorLogSummary({required this.log});

  final PlatformErrorLog log;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            AppStatusBadge(
              label: _severityLabel(l, log.severity),
              tone: _severityTone(log.severity),
            ),
            AppStatusBadge(
              label: log.resolved ? l.resolved : l.unresolved,
              tone: log.resolved ? AppStatusTone.success : AppStatusTone.warning,
            ),
            AppStatusBadge(
              label: _sourceLabel(l, log.source),
              tone: AppStatusTone.neutral,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          log.message,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          [
            if (log.companyName.trim().isNotEmpty) log.companyName.trim(),
            if (log.module.trim().isNotEmpty) log.module.trim(),
            if (log.route.trim().isNotEmpty) log.route.trim(),
          ].join(' / '),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondaryColor(context),
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}

class _ErrorMetaWrap extends StatelessWidget {
  const _ErrorMetaWrap({required this.log});

  final PlatformErrorLog log;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        _MetaChip(label: l.occurrenceCount, value: '${log.occurrenceCount}'),
        _MetaChip(label: l.lastSeenAt, value: _formatDate(context, log.lastSeenAt)),
        if (log.errorCode.trim().isNotEmpty)
          _MetaChip(label: l.errorCode, value: log.errorCode),
        if (log.userEmail.trim().isNotEmpty)
          _MetaChip(label: l.email, value: log.userEmail),
      ],
    );
  }
}

class _ErrorLogActions extends StatelessWidget {
  const _ErrorLogActions({required this.log, required this.isResolving});

  final PlatformErrorLog log;
  final bool isResolving;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        AppButton(
          label: l.viewDetails,
          icon: Icons.open_in_new,
          variant: AppButtonVariant.secondary,
          onPressed: () => _showErrorDetails(context, log),
        ),
        const SizedBox(height: AppSpacing.xs),
        AppButton(
          label: l.copyCode,
          icon: Icons.copy_outlined,
          variant: AppButtonVariant.secondary,
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: _errorCopyText(log)));
            if (context.mounted) {
              AppFeedback.success(context, l.linkCopied);
            }
          },
        ),
        if (!log.resolved) ...[
          const SizedBox(height: AppSpacing.xs),
          AppButton(
            label: l.markResolved,
            icon: Icons.task_alt_outlined,
            isLoading: isResolving,
            onPressed: isResolving
                ? null
                : () async {
                    final success = await context
                        .read<PlatformObservabilityCubit>()
                        .markResolved(log);
                    if (context.mounted && success) {
                      AppFeedback.success(
                        context,
                        l.platformMonitoringResolvedMessage,
                      );
                    }
                  },
          ),
        ],
      ],
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: AppColors.inputSurface(context),
        border: Border.all(color: AppColors.borderColor(context)),
        borderRadius: AppRadius.large,
      ),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: TextStyle(color: AppColors.textSecondaryColor(context)),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ],
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}

Future<void> _showErrorDetails(BuildContext context, PlatformErrorLog log) {
  final cubit = context.read<PlatformObservabilityCubit>();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: AppColors.cardSurface(context),
    builder: (sheetContext) {
      final l = AppLocalizations.of(sheetContext)!;
      final height = MediaQuery.sizeOf(sheetContext).height * .86;
      return BlocProvider.value(
        value: cubit,
        child: SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: height),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l.errorDetails,
                    style: Theme.of(sheetContext).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _DetailSection(
                    children: [
                      _DetailRow(label: l.message, value: log.message),
                      _DetailRow(
                        label: l.severity,
                        value: _severityLabel(l, log.severity),
                      ),
                      _DetailRow(
                        label: l.source,
                        value: _sourceLabel(l, log.source),
                      ),
                      _DetailRow(label: l.module, value: log.module),
                      _DetailRow(label: l.currentRoute, value: log.route),
                      _DetailRow(label: l.errorCode, value: log.errorCode),
                      _DetailRow(label: l.stackHash, value: log.stackHash),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _DetailSection(
                    children: [
                      _DetailRow(label: l.company, value: log.companyName),
                      _DetailRow(label: l.companyIdSlug, value: log.companyId),
                      _DetailRow(label: l.user, value: log.userId),
                      _DetailRow(label: l.email, value: log.userEmail),
                      _DetailRow(label: l.role, value: log.userRole),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _DetailSection(
                    children: [
                      _DetailRow(label: l.appVersion, value: log.appVersion),
                      _DetailRow(label: l.buildNumber, value: log.buildNumber),
                      _DetailRow(label: l.platform, value: log.platform),
                      _DetailRow(label: l.device, value: log.deviceType),
                      _DetailRow(label: l.timezone, value: log.timezone),
                      _DetailRow(label: l.ownerNotified, value: _yesNo(l, log.ownerNotified)),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _DetailSection(
                    children: [
                      _DetailRow(label: l.occurrenceCount, value: '${log.occurrenceCount}'),
                      _DetailRow(label: l.firstSeenAt, value: _formatDate(sheetContext, log.firstSeenAt)),
                      _DetailRow(label: l.lastSeenAt, value: _formatDate(sheetContext, log.lastSeenAt)),
                      _DetailRow(label: l.status, value: log.resolved ? l.resolved : l.unresolved),
                      _DetailRow(label: l.resolvedBy, value: log.resolvedByEmail.isNotEmpty ? log.resolvedByEmail : log.resolvedBy),
                      _DetailRow(label: l.resolvedAt, value: _formatDate(sheetContext, log.resolvedAt)),
                    ],
                  ),
                  if (log.shortStack.trim().isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    _CodeBlock(label: l.shortStack, value: log.shortStack),
                  ],
                  if (log.metadata.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    _CodeBlock(
                      label: l.metadata,
                      value: _metadataText(log.metadata),
                    ),
                  ],
                  if (!log.resolved) ...[
                    const SizedBox(height: AppSpacing.md),
                    BlocBuilder<PlatformObservabilityCubit,
                        PlatformObservabilityState>(
                      builder: (context, state) {
                        final isResolving = state.resolvingLogId == log.id;
                        return Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: AppButton(
                            label: l.markResolved,
                            icon: Icons.task_alt_outlined,
                            isLoading: isResolving,
                            onPressed: isResolving
                                ? null
                                : () async {
                                    final success = await context
                                        .read<PlatformObservabilityCubit>()
                                        .markResolved(log);
                                    if (context.mounted && success) {
                                      Navigator.of(context).maybePop();
                                      AppFeedback.success(
                                        context,
                                        l.platformMonitoringResolvedMessage,
                                      );
                                    }
                                  },
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.inputSurface(context),
        border: Border.all(color: AppColors.borderColor(context)),
        borderRadius: AppRadius.large,
      ),
      child: Column(children: children),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final displayValue = value.trim().isEmpty ? l.notAvailable : value.trim();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 132,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondaryColor(context),
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: SelectableText(
              displayValue,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CodeBlock extends StatelessWidget {
  const _CodeBlock({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.appBackground(context),
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
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondaryColor(context),
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              IconButton(
                tooltip: AppLocalizations.of(context)!.linkCopied,
                icon: const Icon(Icons.copy_outlined, size: 17),
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: value));
                  if (context.mounted) {
                    AppFeedback.success(context, AppLocalizations.of(context)!.linkCopied);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SelectableText(
              value,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                    height: 1.35,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}


String _errorCopyText(PlatformErrorLog log) {
  final buffer = StringBuffer()
    ..writeln('Message: ${log.message}')
    ..writeln('Severity: ${log.severity.name}')
    ..writeln('Source: ${log.source.name}')
    ..writeln('Company: ${log.companyName} (${log.companyId})')
    ..writeln('User: ${log.userEmail} (${log.userId})')
    ..writeln('Route: ${log.route}')
    ..writeln('Code: ${log.errorCode}')
    ..writeln('Occurrences: ${log.occurrenceCount}')
    ..writeln('Last seen: ${log.lastSeenAt}')
    ..writeln('Stack hash: ${log.stackHash}');
  if (log.shortStack.trim().isNotEmpty) {
    buffer
      ..writeln('')
      ..writeln('Short stack:')
      ..writeln(log.shortStack.trim());
  }
  if (log.metadata.isNotEmpty) {
    buffer
      ..writeln('')
      ..writeln('Metadata:')
      ..writeln(_metadataText(log.metadata));
  }
  return buffer.toString();
}

String _companyNameFor(List<CompanyMetadata> companies, String companyId) {
  for (final company in companies) {
    if (company.id == companyId) {
      final title = company.displayName.trim().isNotEmpty
          ? company.displayName.trim()
          : company.name.trim();
      return title.isEmpty ? company.id : title;
    }
  }
  return companyId;
}

String _severityLabel(AppLocalizations l, PlatformErrorSeverity severity) {
  return switch (severity) {
    PlatformErrorSeverity.info => l.errorSeverityInfo,
    PlatformErrorSeverity.warning => l.errorSeverityWarning,
    PlatformErrorSeverity.error => l.errorSeverityError,
    PlatformErrorSeverity.fatal => l.errorSeverityFatal,
  };
}

String _sourceLabel(AppLocalizations l, PlatformErrorSource source) {
  return switch (source) {
    PlatformErrorSource.flutterWeb => l.errorSourceFlutterWeb,
    PlatformErrorSource.flutterMobile => l.errorSourceFlutterMobile,
    PlatformErrorSource.cloudFunction => l.errorSourceCloudFunction,
    PlatformErrorSource.firestoreRule => l.errorSourceFirestoreRule,
    PlatformErrorSource.storage => l.errorSourceStorage,
    PlatformErrorSource.unknown => l.errorSourceUnknown,
  };
}

String _resolvedFilterLabel(
  AppLocalizations l,
  PlatformErrorResolvedFilter filter,
) {
  return switch (filter) {
    PlatformErrorResolvedFilter.all => l.resolvedAndUnresolved,
    PlatformErrorResolvedFilter.unresolved => l.unresolvedOnly,
    PlatformErrorResolvedFilter.resolved => l.resolvedOnly,
  };
}

String _dateFilterLabel(AppLocalizations l, PlatformErrorDateFilter filter) {
  return switch (filter) {
    PlatformErrorDateFilter.all => l.allTime,
    PlatformErrorDateFilter.last24Hours => l.last24Hours,
    PlatformErrorDateFilter.last7Days => l.last7Days,
    PlatformErrorDateFilter.last30Days => l.last30Days,
  };
}

AppStatusTone _severityTone(PlatformErrorSeverity severity) {
  return switch (severity) {
    PlatformErrorSeverity.info => AppStatusTone.info,
    PlatformErrorSeverity.warning => AppStatusTone.warning,
    PlatformErrorSeverity.error => AppStatusTone.error,
    PlatformErrorSeverity.fatal => AppStatusTone.error,
  };
}

Color _severityColor(BuildContext context, PlatformErrorSeverity severity) {
  return switch (severity) {
    PlatformErrorSeverity.info => AppColors.infoColor(context),
    PlatformErrorSeverity.warning => AppColors.warningColor(context),
    PlatformErrorSeverity.error => AppColors.errorColor(context),
    PlatformErrorSeverity.fatal => AppColors.errorColor(context),
  };
}

Color _toneColor(BuildContext context, AppStatusTone tone) {
  return switch (tone) {
    AppStatusTone.success => AppColors.successColor(context),
    AppStatusTone.warning => AppColors.warningColor(context),
    AppStatusTone.error => AppColors.errorColor(context),
    AppStatusTone.info => AppColors.infoColor(context),
    AppStatusTone.neutral => AppColors.textSecondaryColor(context),
  };
}

String _formatDate(BuildContext context, DateTime? value) {
  final l = AppLocalizations.of(context)!;
  if (value == null) {
    return l.notAvailable;
  }
  final locale = Localizations.localeOf(context).toLanguageTag();
  return DateFormat.yMMMd(locale).add_jm().format(value.toLocal());
}

String _yesNo(AppLocalizations l, bool value) {
  return value ? l.yes : l.no;
}

String _metadataText(Map<String, Object?> metadata) {
  final lines = <String>[];
  for (final entry in metadata.entries) {
    lines.add('${entry.key}: ${entry.value ?? ''}');
  }
  return lines.join('\n');
}
