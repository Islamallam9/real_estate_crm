import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/role_constants.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/crm_app_shell.dart';
import '../../../../core/widgets/masar_refresh_indicator.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../domain/constants/notification_limits.dart';
import '../../domain/entities/attention_reminder.dart';
import '../../domain/entities/crm_notification.dart';
import '../cubit/notifications_cubit.dart';
import '../cubit/notifications_state.dart';
import '../routing/notification_route_resolver.dart';
import '../widgets/notification_cards.dart';
import '../widgets/notification_push_status_card.dart';
import '../widgets/notifications_scope.dart';

enum _NotificationFilter {
  all,
  unread,
  attention,
  leads,
  tasks,
  clients,
  deals,
  system,
}

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  static Widget withDependencies() {
    return const NotificationsPage();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final page = CrmAppShell(
      selectedItem: CrmNavigationItem.dashboard,
      title: l.notifications,
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          if (authState.status == AuthStatus.initial ||
              authState.status == AuthStatus.loading) {
            return const AppLoading();
          }
          final profile = authState.userProfile;
          if (profile == null) {
            return AppEmptyState(
              title: l.notifications,
              message: l.notificationsUnavailableInPlatform,
              icon: Icons.notifications_none,
            );
          }
          final authUid = authState.user?.uid ?? '';
          if (authUid.isEmpty) {
            return AppEmptyState(
              title: l.notifications,
              message: l.notificationsUnavailableInPlatform,
              icon: Icons.notifications_none,
            );
          }
          if (profile.uid != authUid) {
            return const AppLoading();
          }
          return _NotificationsWorkspace(
            companyId: profile.companyId,
            currentUserId: authUid,
            role: profile.role,
            managerTeamId: profile.teamId,
          );
        },
      ),
    );
    return _hasNotificationsCubit(context)
        ? page
        : NotificationsScope(child: page);
  }
}

const String _notificationCenterAttentionConsumer = 'notification-center';

bool _hasNotificationsCubit(BuildContext context) {
  try {
    context.read<NotificationsCubit>();
    return true;
  } catch (_) {
    return false;
  }
}

class _NotificationsWorkspace extends StatefulWidget {
  const _NotificationsWorkspace({
    required this.companyId,
    required this.currentUserId,
    required this.role,
    required this.managerTeamId,
  });

  final String companyId;
  final String currentUserId;
  final UserRole role;
  final String managerTeamId;

  @override
  State<_NotificationsWorkspace> createState() => _NotificationsWorkspaceState();
}

class _NotificationsWorkspaceState extends State<_NotificationsWorkspace> {
  _NotificationFilter _filter = _NotificationFilter.all;
  late final NotificationsCubit _notificationsCubit;

  @override
  void initState() {
    super.initState();
    _notificationsCubit = context.read<NotificationsCubit>();
    _watch();
  }

  @override
  void didUpdateWidget(covariant _NotificationsWorkspace oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.companyId != widget.companyId ||
        oldWidget.currentUserId != widget.currentUserId ||
        oldWidget.role != widget.role ||
        oldWidget.managerTeamId != widget.managerTeamId) {
      _watch();
    }
  }

  void _watch() {
    _notificationsCubit.watchCenter(
          companyId: widget.companyId,
          currentUserId: widget.currentUserId,
          role: widget.role,
          managerTeamId: widget.managerTeamId,
          notificationsLimit: notificationHistoryPageLimit,
        );
  }

  Future<void> _refresh() async {
    _notificationsCubit.refreshCenter(
          companyId: widget.companyId,
          currentUserId: widget.currentUserId,
          role: widget.role,
          managerTeamId: widget.managerTeamId,
          notificationsLimit: notificationHistoryPageLimit,
        );
    await Future<void>.delayed(const Duration(milliseconds: 650));
  }

  @override
  void dispose() {
    _notificationsCubit.releaseAttentionReminders(
      _notificationCenterAttentionConsumer,
    );
    _notificationsCubit.watchShell(
      companyId: widget.companyId,
      currentUserId: widget.currentUserId,
      role: widget.role,
      managerTeamId: widget.managerTeamId,
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return BlocBuilder<NotificationsCubit, NotificationsState>(
      builder: (context, state) {
        final notifications = _filteredNotifications(state.notifications);
        final reminders = _filteredReminders(state.reminders);

        if (state.status == NotificationsStatus.loading &&
            state.notifications.isEmpty) {
          return const AppLoading();
        }
        return LayoutBuilder(
          builder: (context, constraints) {
            final narrow = constraints.maxWidth < 760;
            final header = _PageHeader(
              unreadCount: state.effectiveBadgeCount,
              isMarkingAllRead: state.markingAllRead,
              onMarkAllRead: !state.hasUnreadNotifications
                  ? null
                  : () => context.read<NotificationsCubit>().markAllRead(
                        companyId: widget.companyId,
                        currentUserId: widget.currentUserId,
                      ),
            );
            final filters = _FilterChips(
              selected: _filter,
              onSelected: (filter) => setState(() => _filter = filter),
            );

            if (narrow) {
              return SingleChildScrollView(
                physics: const MasarRefreshPhysics(parent: BouncingScrollPhysics()),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.only(bottom: 96),
                  child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    header,
                    const SizedBox(height: 8),
                    const NotificationPushStatusCard(),
                    const SizedBox(height: 8),
                    filters,
                    const SizedBox(height: AppSpacing.sm),
                    _MobileNotificationSections(
                      state: state,
                      notifications: notifications,
                      reminders: reminders,
                      companyId: widget.companyId,
                    ),
                    ],
                  ),
                );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                header,
                const SizedBox(height: 8),
                const NotificationPushStatusCard(),
                const SizedBox(height: 8),
                filters,
                const SizedBox(height: AppSpacing.sm),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const MasarRefreshPhysics(parent: BouncingScrollPhysics()),
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: _NotificationsList(
                            state: state,
                            notifications: notifications,
                            companyId: widget.companyId,
                            shrinkWrap: true,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        SizedBox(
                          width: 330,
                          child: _AttentionList(
                            state: state,
                            reminders: reminders,
                            shrinkWrap: true,
                          ),
                        ),
                      ],
                      ),
                    ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  List<CrmNotification> _filteredNotifications(
    List<CrmNotification> notifications,
  ) {
    final filtered = switch (_filter) {
      _NotificationFilter.all => notifications,
      _NotificationFilter.unread =>
        notifications.where((item) => !item.isRead).toList(),
      _NotificationFilter.attention => const <CrmNotification>[],
      _NotificationFilter.leads =>
        notifications.where((item) => item.module == 'leads').toList(),
      _NotificationFilter.tasks =>
        notifications.where((item) => item.module == 'tasks').toList(),
      _NotificationFilter.clients =>
        notifications.where((item) => item.module == 'clients').toList(),
      _NotificationFilter.deals =>
        notifications.where((item) => item.module == 'deals').toList(),
      _NotificationFilter.system => notifications
          .where((item) =>
              item.module == 'system' ||
              item.module == 'dataHealth' ||
              item.type == CrmNotificationType.systemInfo ||
              item.type == CrmNotificationType.dataHealthIssue)
          .toList(),
    };
    return _sortNotificationsForDisplay(filtered);
  }

  List<CrmNotification> _sortNotificationsForDisplay(
    List<CrmNotification> notifications,
  ) {
    final sorted = [...notifications]..sort((a, b) {
        if (a.isRead != b.isRead) {
          return a.isRead ? 1 : -1;
        }
        final aDate =
            a.createdAt ?? a.readAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate =
            b.createdAt ?? b.readAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final dateCompare = bDate.compareTo(aDate);
        if (dateCompare != 0) {
          return dateCompare;
        }
        return b.id.compareTo(a.id);
      });
    return sorted;
  }

  List<AttentionReminder> _filteredReminders(List<AttentionReminder> reminders) {
    return switch (_filter) {
      _NotificationFilter.all || _NotificationFilter.attention => reminders,
      _NotificationFilter.leads =>
        reminders.where((item) => item.module == 'leads').toList(),
      _NotificationFilter.tasks =>
        reminders.where((item) => item.module == 'tasks').toList(),
      _NotificationFilter.clients => const [],
      _NotificationFilter.deals =>
        reminders.where((item) => item.module == 'deals').toList(),
      _ => const [],
    };
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({
    required this.unreadCount,
    required this.isMarkingAllRead,
    required this.onMarkAllRead,
  });

  final int unreadCount;
  final bool isMarkingAllRead;
  final VoidCallback? onMarkAllRead;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final action = AppButton(
      label: l.markAllRead,
      icon: Icons.done_all,
      variant: AppButtonVariant.secondary,
      isLoading: isMarkingAllRead,
      onPressed: onMarkAllRead,
    );
    final titleBlock = Row(
      children: [
        Icon(
          Icons.notifications_active_outlined,
          color: AppColors.primaryColor(context),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l.notificationCenter,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                l.notificationCenterSubtitle(unreadCount),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondaryColor(context),
                    ),
              ),
            ],
          ),
        ),
      ],
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.cardSurface(context),
        border: Border.all(color: AppColors.borderColor(context)),
        borderRadius: AppRadius.xLarge,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 12,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 520) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  titleBlock,
                  const SizedBox(height: AppSpacing.sm),
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: action,
                  ),
                ],
              );
            }
            return Row(
              children: [
                Expanded(child: titleBlock),
                const SizedBox(width: AppSpacing.md),
                action,
              ],
            );
          },
        ),
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  const _FilterChips({
    required this.selected,
    required this.onSelected,
  });

  final _NotificationFilter selected;
  final ValueChanged<_NotificationFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final labels = <_NotificationFilter, String>{
      _NotificationFilter.all: l.all,
      _NotificationFilter.unread: l.unread,
      _NotificationFilter.attention: l.attention,
      _NotificationFilter.leads: l.leads,
      _NotificationFilter.tasks: l.tasks,
      _NotificationFilter.clients: l.clients,
      _NotificationFilter.deals: l.deals,
      _NotificationFilter.system: l.system,
    };
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: [
        for (final entry in labels.entries)
          ChoiceChip(
            label: Text(entry.value),
            selected: selected == entry.key,
            showCheckmark: false,
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            onSelected: (_) => onSelected(entry.key),
          ),
      ],
    );
  }
}

class _MobileNotificationSections extends StatelessWidget {
  const _MobileNotificationSections({
    required this.state,
    required this.notifications,
    required this.reminders,
    required this.companyId,
  });

  final NotificationsState state;
  final List<CrmNotification> notifications;
  final List<AttentionReminder> reminders;
  final String companyId;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _AttentionList(state: state, reminders: reminders, shrinkWrap: true),
        const SizedBox(height: AppSpacing.md),
        _NotificationsList(
          state: state,
          notifications: notifications,
          companyId: companyId,
          shrinkWrap: true,
        ),
      ],
    );
  }
}

class _NotificationsList extends StatelessWidget {
  const _NotificationsList({
    required this.state,
    required this.notifications,
    required this.companyId,
    this.shrinkWrap = false,
  });

  final NotificationsState state;
  final List<CrmNotification> notifications;
  final String companyId;
  final bool shrinkWrap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final Widget content;
    final hasHiddenUnreadHistory = state.effectiveUnreadCount > 0 &&
        notifications.isEmpty &&
        state.status == NotificationsStatus.loaded;
    if (state.status == NotificationsStatus.failure && notifications.isEmpty) {
      content = _InlineErrorMessage(
        message: state.message == null
            ? l.notificationStreamError
            : localizeErrorMessage(l, state.message),
      );
    } else if (hasHiddenUnreadHistory) {
      content = AppEmptyState(
        title: l.notificationDataRepairNeededTitle,
        message: l.notificationDataRepairNeededMessage,
        icon: Icons.notifications_none,
      );
    } else if (notifications.isEmpty) {
      content = AppEmptyState(
        title: l.noNotificationsYet,
        message: l.noNotificationsYetMessage,
        icon: Icons.notifications_none,
      );
    } else {
      content = ListView.builder(
            shrinkWrap: shrinkWrap,
            physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return NotificationCard(
                notification: notification,
                isMarking: state.markingNotificationId == notification.id,
                onMarkRead: () =>
                    context.read<NotificationsCubit>().markAsRead(
                          companyId: companyId,
                          notification: notification,
                        ),
                onResolve: notification.needsAction
                    ? () => context.read<NotificationsCubit>().markResolved(
                          companyId: companyId,
                          notification: notification,
                        )
                    : null,
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
                    _openNotificationRoute(context, notification);
                  }
                },
              );
            },
          );
    }
    return _SectionCard(
      title: l.notifications,
      expandChild: !shrinkWrap && notifications.isNotEmpty,
      child: content,
    );
  }
}

class _AttentionList extends StatefulWidget {
  const _AttentionList({
    required this.state,
    required this.reminders,
    this.shrinkWrap = false,
  });

  final NotificationsState state;
  final List<AttentionReminder> reminders;
  final bool shrinkWrap;

  @override
  State<_AttentionList> createState() => _AttentionListState();
}

class _AttentionListState extends State<_AttentionList> {
  bool _expanded = false;

  @override
  void didUpdateWidget(covariant _AttentionList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.reminders.length <= 3 && _expanded) {
      _expanded = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final canToggle = widget.reminders.length > 3;
    final visibleReminders = canToggle && !_expanded
        ? widget.reminders.take(3).toList()
        : widget.reminders;
    Widget content;
    if (widget.state.reminderMessage != null) {
      content = _InlineErrorMessage(
        message: _localizedAttentionError(l, widget.state.reminderMessage),
      );
    } else if (widget.reminders.isEmpty) {
      content = AppEmptyState(
        title: l.noUrgentReminders,
        message: l.noUrgentRemindersMessage,
        icon: Icons.event_available,
      );
    } else {
      content = ListView.builder(
        shrinkWrap: true,
        physics: widget.shrinkWrap || !_expanded
            ? const NeverScrollableScrollPhysics()
            : null,
        itemCount: visibleReminders.length,
        itemBuilder: (context, index) {
          final reminder = visibleReminders[index];
          return AttentionReminderCard(
            reminder: reminder,
            onOpen: () => _openReminderRoute(context, reminder),
          );
        },
      );
    }
    return _SectionCard(
      title: l.attentionNeeded,
      expandChild: !widget.shrinkWrap && widget.reminders.isNotEmpty,
      trailing: canToggle
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _CountBadge(value: widget.reminders.length),
                const SizedBox(width: 4),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: () => setState(() => _expanded = !_expanded),
                  icon: AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: const Icon(Icons.keyboard_arrow_down_rounded),
                  ),
                ),
              ],
            )
          : widget.reminders.isNotEmpty
              ? _CountBadge(value: widget.reminders.length)
              : null,
      child: content,
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.value});

  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.warningColor(context).withValues(alpha: 0.10),
        border: Border.all(
          color: AppColors.warningColor(context).withValues(alpha: 0.28),
        ),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        value.toString(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.warningColor(context),
              fontWeight: FontWeight.w900,
            ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
    required this.expandChild,
    this.trailing,
  });

  final String title;
  final Widget child;
  final bool expandChild;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.cardSurface(context),
        border: Border.all(color: AppColors.borderColor(context)),
        borderRadius: AppRadius.xLarge,
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            if (expandChild) Expanded(child: child) else child,
          ],
        ),
      ),
    );
  }
}

class _InlineErrorMessage extends StatelessWidget {
  const _InlineErrorMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.errorColor(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.035),
        border: Border.all(color: color.withValues(alpha: 0.24)),
        borderRadius: AppRadius.large,
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(12, 10, 12, 10),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: color, size: 18),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                message,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textPrimaryColor(context),
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

void _openNotificationRoute(
  BuildContext context,
  CrmNotification notification,
) {
  final l = AppLocalizations.of(context)!;
  final resolution = NotificationRouteResolver.resolve(notification);
  if (resolution.usedFallback) {
    AppFeedback.warning(context, l.notificationRouteUnavailable);
  }
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (context.mounted) {
      context.go(resolution.route);
    }
  });
}

void _openReminderRoute(BuildContext context, AttentionReminder reminder) {
  final l = AppLocalizations.of(context)!;
  final resolution = NotificationRouteResolver.resolveReminder(reminder);
  if (resolution.usedFallback) {
    AppFeedback.warning(context, l.notificationRouteUnavailable);
  }
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (context.mounted) {
      context.go(resolution.route);
    }
  });
}

String _localizedAttentionError(AppLocalizations l, String? message) {
  if (message == null || message == AppErrorMessages.unknown) {
    return l.notificationStreamError;
  }
  return localizeErrorMessage(l, message);
}
