import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_status_badge.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/platform_notification.dart';
import '../cubit/platform_notifications_cubit.dart';
import '../cubit/platform_notifications_state.dart';

class PlatformNotificationsBell extends StatelessWidget {
  const PlatformNotificationsBell({
    super.key,
    this.onPressed,
    this.compact = false,
  });

  final VoidCallback? onPressed;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return BlocBuilder<PlatformNotificationsCubit, PlatformNotificationsState>(
      buildWhen: (previous, current) =>
          previous.unreadCount != current.unreadCount ||
          previous.status != current.status,
      builder: (context, state) {
        final count = state.unreadCount;
        return IconButton(
          tooltip: l.platformNotifications,
          onPressed: onPressed,
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                compact
                    ? Icons.notifications_none_outlined
                    : Icons.notifications_active_outlined,
              ),
              if (count > 0)
                PositionedDirectional(
                  top: -8,
                  end: -8,
                  child: Container(
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.errorColor(context),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: AppColors.cardSurface(context),
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      count > 99 ? '99+' : count.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class PlatformNotificationsPanel extends StatelessWidget {
  const PlatformNotificationsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return BlocConsumer<PlatformNotificationsCubit, PlatformNotificationsState>(
      listenWhen: (previous, current) =>
          previous.message != current.message && current.message != null,
      listener: (context, state) {
        AppFeedback.error(context, state.message ?? l.errorOccurred);
      },
      builder: (context, state) {
        return _Panel(
          title: l.platformNotifications,
          action: AppButton(
            label: l.markAllRead,
            icon: Icons.done_all_outlined,
            variant: AppButtonVariant.secondary,
            isLoading: state.markingAllRead,
            onPressed: state.unreadCount == 0 || state.markingAllRead
                ? null
                : () => context.read<PlatformNotificationsCubit>().markAllRead(),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l.platformNotificationsSubtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondaryColor(context),
                    ),
              ),
              const SizedBox(height: AppSpacing.md),
              _NotificationFilters(state: state),
              const SizedBox(height: AppSpacing.md),
              if (state.status == PlatformNotificationsStatus.loading)
                const AppLoading()
              else if (state.filteredNotifications.isEmpty)
                AppEmptyState(
                  icon: Icons.notifications_none_outlined,
                  title: l.noPlatformNotifications,
                  message: l.noPlatformNotificationsMessage,
                )
              else
                Column(
                  children: [
                    for (final notification in state.filteredNotifications) ...[
                      _NotificationTile(notification: notification),
                      if (notification != state.filteredNotifications.last)
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

class _NotificationFilters extends StatelessWidget {
  const _NotificationFilters({required this.state});

  final PlatformNotificationsState state;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: PlatformNotificationFilter.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.xs),
        itemBuilder: (context, index) {
          final filter = PlatformNotificationFilter.values[index];
          return ChoiceChip(
            label: Text(_filterLabel(l, filter)),
            selected: state.filter == filter,
            onSelected: (_) {
              context.read<PlatformNotificationsCubit>().setFilter(filter);
            },
          );
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification});

  final PlatformNotification notification;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final severityColor = _severityColor(context, notification.severity);
    final isMarking = context.select(
      (PlatformNotificationsCubit cubit) =>
          cubit.state.markingNotificationId == notification.id,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: notification.isRead
            ? AppColors.cardSurface(context)
            : AppColors.selectedSurface(context).withValues(alpha: 0.44),
        border: Border.all(
          color: notification.isRead
              ? AppColors.borderColor(context)
              : severityColor.withValues(alpha: 0.42),
        ),
        borderRadius: AppRadius.large,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final narrow = constraints.maxWidth < 620;
            final leading = _SeverityIcon(
              icon: _notificationIcon(notification),
              color: severityColor,
            );
            final body = _NotificationBody(notification: notification);
            final actions = _NotificationActions(
              notification: notification,
              isMarking: isMarking,
            );
            if (narrow) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      leading,
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(child: body),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  actions,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                leading,
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: body),
                const SizedBox(width: AppSpacing.sm),
                actions,
              ],
            );
          },
        ),
      ),
    );
  }
}

class _NotificationBody extends StatelessWidget {
  const _NotificationBody({required this.notification});

  final PlatformNotification notification;

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
            Text(
              _notificationTitle(l, notification),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            if (!notification.isRead)
              AppStatusBadge(
                label: l.unread,
                tone: AppStatusTone.info,
              ),
            AppStatusBadge(
              label: _severityLabel(l, notification.severity),
              tone: _severityTone(notification.severity),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          _notificationMessage(l, notification),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondaryColor(context),
              ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            if (notification.companyName.trim().isNotEmpty)
              _MetaPill(label: l.company, value: notification.companyName),
            _MetaPill(
              label: l.source,
              value: _sourceLabel(l, notification.source),
            ),
            if (notification.createdAt != null)
              _MetaPill(
                label: l.createdAt,
                value: _relativeTime(l, notification.createdAt!),
              ),
          ],
        ),
      ],
    );
  }
}

class _NotificationActions extends StatelessWidget {
  const _NotificationActions({
    required this.notification,
    required this.isMarking,
  });

  final PlatformNotification notification;
  final bool isMarking;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      alignment: WrapAlignment.end,
      children: [
        if (notification.route.trim().isNotEmpty)
          IconButton(
            tooltip: l.open,
            onPressed: () {
              if (!notification.isRead) {
                context.read<PlatformNotificationsCubit>().markRead(
                      notification: notification,
                      isRead: true,
                    );
              }
              final route = notification.route.trim();
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (context.mounted) {
                  context.go(route);
                }
              });
            },
            icon: const Icon(Icons.open_in_new_outlined),
          ),
        IconButton(
          tooltip: notification.isRead ? l.markUnread : l.markRead,
          onPressed: isMarking
              ? null
              : () => context.read<PlatformNotificationsCubit>().markRead(
                    notification: notification,
                    isRead: !notification.isRead,
                  ),
          icon: isMarking
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(
                  notification.isRead
                      ? Icons.mark_email_unread_outlined
                      : Icons.mark_email_read_outlined,
                ),
        ),
      ],
    );
  }
}

class _SeverityIcon extends StatelessWidget {
  const _SeverityIcon({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppRadius.large,
      ),
      child: Icon(icon, color: color),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.appBackground(context),
        border: Border.all(color: AppColors.borderColor(context)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 5,
        ),
        child: Text(
          '$label: $value',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.textSecondaryColor(context),
                fontWeight: FontWeight.w800,
              ),
        ),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.title, required this.child, this.action});

  final String title;
  final Widget child;
  final Widget? action;

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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              if (action != null) action!,
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}

String _filterLabel(AppLocalizations l, PlatformNotificationFilter filter) {
  return switch (filter) {
    PlatformNotificationFilter.all => l.all,
    PlatformNotificationFilter.unread => l.unread,
    PlatformNotificationFilter.urgent => l.platformNotificationSeverityUrgent,
    PlatformNotificationFilter.support => l.platformSupportInbox,
    PlatformNotificationFilter.company => l.company,
    PlatformNotificationFilter.invitation => l.invitations,
    PlatformNotificationFilter.storage => l.platformNotificationStorageLabel,
  };
}

String _notificationTitle(
  AppLocalizations l,
  PlatformNotification notification,
) {
  return switch (notification.type) {
    PlatformNotificationType.companyRegistered =>
      l.platformNotificationCompanyRegistered,
    PlatformNotificationType.companyCreated =>
      l.platformNotificationCompanyCreated,
    PlatformNotificationType.companyStatusChanged =>
      l.platformNotificationCompanyStatusChanged,
    PlatformNotificationType.companySettingsChanged =>
      l.platformNotificationCompanySettingsChanged,
    PlatformNotificationType.companyFeatureChanged =>
      l.platformNotificationCompanyFeatureChanged,
    PlatformNotificationType.companyLimitChanged =>
      l.platformNotificationCompanyLimitChanged,
    PlatformNotificationType.companyUserCreated =>
      l.platformNotificationCompanyUserCreated,
    PlatformNotificationType.companyUserStatusChanged =>
      l.platformNotificationCompanyUserStatusChanged,
    PlatformNotificationType.companyUserPasswordReset =>
      l.platformNotificationCompanyUserPasswordReset,
    PlatformNotificationType.dealWon => l.platformNotificationDealWon,
    PlatformNotificationType.dealLost => l.platformNotificationDealLost,
    PlatformNotificationType.invitationCreated =>
      l.platformNotificationInvitationCreated,
    PlatformNotificationType.invitationAccepted =>
      l.platformNotificationInvitationAccepted,
    PlatformNotificationType.invitationRevoked =>
      l.platformNotificationInvitationRevoked,
    PlatformNotificationType.supportTicketCreated ||
    PlatformNotificationType.urgentSupportTicketCreated =>
      l.platformNotificationSupportTicketCreated,
    PlatformNotificationType.feedbackSubmitted =>
      l.platformNotificationFeedbackSubmitted,
    PlatformNotificationType.supportTicketStatusChanged =>
      l.platformNotificationSupportTicketStatusChanged,
    PlatformNotificationType.storageUsageRefreshed =>
      l.platformNotificationStorageUsageRefreshed,
    PlatformNotificationType.storageNearLimit =>
      l.platformNotificationStorageNearLimit,
    PlatformNotificationType.platformFunctionFailed =>
      l.platformNotificationFunctionFailed,
    PlatformNotificationType.unknown => l.platformNotificationUnknown,
  };
}

String _notificationMessage(
  AppLocalizations l,
  PlatformNotification notification,
) {
  final customMessage = notification.message.trim();
  if (customMessage.isNotEmpty) {
    return customMessage;
  }
  final company = notification.companyName.trim();
  final actor = notification.actorName.trim().isNotEmpty
      ? notification.actorName.trim()
      : notification.actorEmail.trim();
  if (company.isNotEmpty && actor.isNotEmpty) {
    return l.platformNotificationCompanyActorMessage(company, actor);
  }
  if (company.isNotEmpty) {
    return l.platformNotificationCompanyMessage(company);
  }
  if (actor.isNotEmpty) {
    return l.platformNotificationActorMessage(actor);
  }
  return l.platformNotificationGenericMessage;
}

String _severityLabel(AppLocalizations l, PlatformNotificationSeverity severity) {
  return switch (severity) {
    PlatformNotificationSeverity.info => l.platformNotificationSeverityInfo,
    PlatformNotificationSeverity.success =>
      l.platformNotificationSeveritySuccess,
    PlatformNotificationSeverity.warning =>
      l.platformNotificationSeverityWarning,
    PlatformNotificationSeverity.urgent => l.platformNotificationSeverityUrgent,
  };
}

String _sourceLabel(AppLocalizations l, PlatformNotificationSource source) {
  return switch (source) {
    PlatformNotificationSource.platform => l.platform,
    PlatformNotificationSource.support => l.platformSupportInbox,
    PlatformNotificationSource.invitation => l.invitations,
    PlatformNotificationSource.company => l.company,
    PlatformNotificationSource.user => l.user,
    PlatformNotificationSource.storage => l.platformNotificationStorageLabel,
    PlatformNotificationSource.system => l.system,
  };
}

AppStatusTone _severityTone(PlatformNotificationSeverity severity) {
  return switch (severity) {
    PlatformNotificationSeverity.info => AppStatusTone.info,
    PlatformNotificationSeverity.success => AppStatusTone.success,
    PlatformNotificationSeverity.warning => AppStatusTone.warning,
    PlatformNotificationSeverity.urgent => AppStatusTone.error,
  };
}

Color _severityColor(
  BuildContext context,
  PlatformNotificationSeverity severity,
) {
  return switch (severity) {
    PlatformNotificationSeverity.info => AppColors.infoColor(context),
    PlatformNotificationSeverity.success => AppColors.successColor(context),
    PlatformNotificationSeverity.warning => AppColors.warningColor(context),
    PlatformNotificationSeverity.urgent => AppColors.errorColor(context),
  };
}

IconData _notificationIcon(PlatformNotification notification) {
  return switch (notification.source) {
    PlatformNotificationSource.support => Icons.support_agent_outlined,
    PlatformNotificationSource.invitation => Icons.mark_email_unread_outlined,
    PlatformNotificationSource.company => Icons.apartment_outlined,
    PlatformNotificationSource.user => Icons.manage_accounts_outlined,
    PlatformNotificationSource.storage => Icons.storage_outlined,
    PlatformNotificationSource.system => Icons.settings_suggest_outlined,
    PlatformNotificationSource.platform => Icons.space_dashboard_outlined,
  };
}

String _relativeTime(AppLocalizations l, DateTime value) {
  final now = DateTime.now();
  final difference = now.difference(value.toLocal());
  if (difference.inMinutes < 1) {
    return l.dashboardJustNow;
  }
  if (difference.inHours < 1) {
    return l.dashboardMinutesAgo(difference.inMinutes);
  }
  if (difference.inHours < 24) {
    return l.dashboardHoursAgo(difference.inHours);
  }
  if (difference.inDays == 1) {
    return l.dashboardYesterday;
  }
  return l.daysAgo(difference.inDays);
}
