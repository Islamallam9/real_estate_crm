import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/error_mapper.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/constants/notification_limits.dart';
import '../../domain/entities/attention_reminder.dart';
import '../cubit/notifications_cubit.dart';
import '../cubit/notifications_state.dart';
import 'notification_cards.dart';
import '../../../../core/widgets/masar_loading_view.dart';

class NotificationBellButton extends StatelessWidget {
  const NotificationBellButton({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final profile = authState.userProfile;
    if (profile == null) {
      return _BellIconButton(
        compact: compact,
        unreadCount: 0,
        onPressed: () {
          AppFeedback.info(
            context,
            AppLocalizations.of(context)!.notificationsUnavailableInPlatform,
          );
        },
      );
    }

    final authUid = authState.user?.uid ?? '';
    if (authUid.isEmpty || profile.uid != authUid) {
      return _BellIconButton(
        compact: compact,
        unreadCount: 0,
        onPressed: () {
          AppFeedback.info(
            context,
            AppLocalizations.of(context)!.notificationsUnavailableInPlatform,
          );
        },
      );
    }
    return BlocBuilder<NotificationsCubit, NotificationsState>(
      buildWhen: (previous, current) =>
          previous.effectiveBadgeCount != current.effectiveBadgeCount ||
          previous.notifications != current.notifications ||
          previous.reminders != current.reminders,
      builder: (context, state) {
        final badgeCount = state.effectiveBadgeCount;
        return _BellIconButton(
          compact: compact,
          unreadCount: badgeCount,
          onPressed: () {
            final width = MediaQuery.sizeOf(context).width;
            if (width < 720) {
              context.go(RouteNames.notifications);
              return;
            }
            _showNotificationsPanel(
              context: context,
              cubit: context.read<NotificationsCubit>(),
              companyId: profile.companyId,
              currentUserId: authUid,
            );
          },
        );
      },
    );
  }
}

class _BellIconButton extends StatelessWidget {
  const _BellIconButton({
    required this.compact,
    required this.unreadCount,
    required this.onPressed,
  });

  final bool compact;
  final int unreadCount;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final button = IconButton(
      tooltip: l.notifications,
      onPressed: onPressed,
      icon: Badge(
        isLabelVisible: unreadCount > 0,
        label: Text(unreadCount > 99 ? '99+' : unreadCount.toString()),
        child: const Icon(Icons.notifications_none),
      ),
    );

    if (!compact) {
      return button;
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.inputSurface(context),
        border: Border.all(color: AppColors.borderColor(context)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: button,
    );
  }
}

Future<void> _showNotificationsPanel({
  required BuildContext context,
  required NotificationsCubit cubit,
  required String companyId,
  required String currentUserId,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black.withValues(alpha: 0.08),
    transitionDuration: const Duration(milliseconds: 140),
    pageBuilder: (dialogContext, _, __) {
      return BlocProvider.value(
        value: cubit,
        child: _NotificationsPanel(
          companyId: companyId,
          currentUserId: currentUserId,
        ),
      );
    },
    transitionBuilder: (_, animation, __, child) {
      return FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -0.03),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      );
    },
  );
}

class _NotificationsPanel extends StatefulWidget {
  const _NotificationsPanel({
    required this.companyId,
    required this.currentUserId,
  });

  final String companyId;
  final String currentUserId;

  @override
  State<_NotificationsPanel> createState() => _NotificationsPanelState();
}

class _NotificationsPanelState extends State<_NotificationsPanel> {
  bool _attentionExpanded = true;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final panelHeight = (MediaQuery.sizeOf(context).height - 88)
        .clamp(280.0, 520.0)
        .toDouble();
    return SafeArea(
      child: Align(
        alignment: AlignmentDirectional.topEnd,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(0, 68, 20, 0),
          child: Material(
            color: AppColors.cardSurface(context),
            borderRadius: AppRadius.xLarge,
            elevation: 12,
            child: Container(
              width: 360,
              height: panelHeight,
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.borderColor(context)),
                borderRadius: AppRadius.xLarge,
              ),
              child: BlocBuilder<NotificationsCubit, NotificationsState>(
                builder: (context, state) {
                  final reminders = _latestPanelReminders(state.reminders);
                  return Column(
                    mainAxisSize: MainAxisSize.max,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              l.notifications,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                          ),
                          TextButton(
                            onPressed: !state.hasUnreadNotifications ||
                                    state.markingAllRead
                                ? null
                                : () => context
                                    .read<NotificationsCubit>()
                                    .markAllRead(
                                      companyId: widget.companyId,
                                      currentUserId: widget.currentUserId,
                                    ),
                            child: state.markingAllRead
                                ? const SizedBox.square(
                                    dimension: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(l.markAllRead),
                          ),
                        ],
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.only(
                            bottom: AppSpacing.xs,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (reminders.isNotEmpty) ...[
                                const SizedBox(height: AppSpacing.sm),
                                _AttentionPanelHeader(
                                  count: reminders.length,
                                  expanded: _attentionExpanded,
                                  onToggle: () {
                                    setState(() {
                                      _attentionExpanded = !_attentionExpanded;
                                    });
                                  },
                                ),
                                AnimatedCrossFade(
                                  firstChild: const SizedBox.shrink(),
                                  secondChild: Padding(
                                    padding: const EdgeInsets.only(
                                      top: AppSpacing.xs,
                                    ),
                                    child: Column(
                                      children: [
                                        for (final reminder in reminders)
                                          AttentionReminderCard(
                                            reminder: reminder,
                                            onClear: () => context
                                                .read<NotificationsCubit>()
                                                .clearAttentionReminder(
                                                  reminder.id,
                                                ),
                                            onOpen: () => _openRoute(
                                              context,
                                              reminder.route,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  crossFadeState: _attentionExpanded
                                      ? CrossFadeState.showSecond
                                      : CrossFadeState.showFirst,
                                  duration: const Duration(milliseconds: 180),
                                ),
                              ],
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                l.notifications,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelLarge
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              _PanelNotificationList(
                                companyId: widget.companyId,
                                state: state,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: TextButton.icon(
                          onPressed: () {
                            Navigator.of(context).pop();
                            context.go(RouteNames.notifications);
                          },
                          icon: const Icon(Icons.arrow_forward, size: 16),
                          label: Text(l.viewAll),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AttentionPanelHeader extends StatelessWidget {
  const _AttentionPanelHeader({
    required this.count,
    required this.expanded,
    required this.onToggle,
  });

  final int count;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final textColor = AppColors.textSecondaryColor(context);
    return Material(
      color: AppColors.inputSurface(context),
      borderRadius: AppRadius.large,
      child: InkWell(
        onTap: onToggle,
        borderRadius: AppRadius.large,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(10, 8, 8, 8),
          child: Row(
            children: [
              Icon(
                Icons.notifications_active_outlined,
                size: 17,
                color: AppColors.warningColor(context),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  '${l.attentionNeeded} ($count)',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppColors.textPrimaryColor(context),
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              Text(
                expanded ? l.collapseAttentionNeeded : l.expandAttentionNeeded,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(width: AppSpacing.xs),
              AnimatedRotation(
                turns: expanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 180),
                child: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 20,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


List<AttentionReminder> _latestPanelReminders(
  List<AttentionReminder> reminders,
) {
  final sorted = [...reminders]..sort((a, b) {
      final aDate = a.dueAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = b.dueAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final dateCompare = bDate.compareTo(aDate);
      if (dateCompare != 0) {
        return dateCompare;
      }
      return b.id.compareTo(a.id);
    });
  return sorted;
}

class _PanelNotificationList extends StatelessWidget {
  const _PanelNotificationList({
    required this.companyId,
    required this.state,
  });

  final String companyId;
  final NotificationsState state;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    if (state.status == NotificationsStatus.loading &&
        state.notifications.isEmpty) {
      return const Center(child: MasarLogoLoader(size: 36));
    }
    if (state.status == NotificationsStatus.failure &&
        state.notifications.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: _PanelInlineMessage(
          icon: Icons.error_outline,
          message: state.message == null
              ? l.notificationStreamError
              : localizeErrorMessage(l, state.message),
        ),
      );
    }
    if (state.unreadCount > 0 &&
        state.visibleUnreadCount == 0 &&
        state.notifications.isEmpty &&
        state.status == NotificationsStatus.loaded) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: _PanelInlineMessage(
          icon: Icons.notifications_paused_outlined,
          message: l.notificationDataRepairNeededMessage,
        ),
      );
    }
    if (state.notifications.isEmpty) {
      return AppEmptyState(
        title: l.noNotificationsYet,
        message: l.noNotificationsYetMessage,
        icon: Icons.notifications_none,
      );
    }
    final visibleNotifications =
        state.notifications.take(notificationDropdownLimit).toList();
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: visibleNotifications.length,
      itemBuilder: (context, index) {
        final notification = visibleNotifications[index];
        return NotificationCard(
          notification: notification,
          isMarking: state.markingNotificationId == notification.id,
          onMarkRead: () => context.read<NotificationsCubit>().markAsRead(
                companyId: companyId,
                notification: notification,
              ),
          onClear: () => context.read<NotificationsCubit>().clearNotification(
                companyId: companyId,
                notification: notification,
              ),
          onOpen: () async {
            await context.read<NotificationsCubit>().markAsRead(
                  companyId: companyId,
                  notification: notification,
                );
            if (context.mounted) {
              _openRoute(context, notification.route);
            }
          },
        );
      },
    );
  }
}

class _PanelInlineMessage extends StatelessWidget {
  const _PanelInlineMessage({
    required this.icon,
    required this.message,
  });

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.inputSurface(context),
        border: Border.all(color: AppColors.borderColor(context)),
        borderRadius: AppRadius.large,
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(10, 9, 10, 9),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.warningColor(context)),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                message,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondaryColor(context),
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void _openRoute(BuildContext context, String route) {
  final cleanRoute = route.trim();
  final l = AppLocalizations.of(context)!;
  if (!_isAllowedNotificationRoute(cleanRoute)) {
    AppFeedback.warning(context, l.notificationRouteUnavailable);
    return;
  }
  final router = GoRouter.of(context);
  Navigator.of(context, rootNavigator: true).maybePop();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    router.go(cleanRoute);
  });
}

bool _isAllowedNotificationRoute(String route) {
  return route == RouteNames.dashboard ||
      route == RouteNames.dataHealth ||
      route == RouteNames.appointments ||
      route.startsWith('/appointments/') ||
      route.startsWith('/leads/') ||
      route.startsWith('/tasks/') ||
      route.startsWith('/deals/') ||
      route.startsWith('/clients/') ||
      route.startsWith('/properties/');
}
