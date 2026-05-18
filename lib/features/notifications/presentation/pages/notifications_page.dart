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
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../domain/constants/notification_limits.dart';
import '../../domain/entities/attention_reminder.dart';
import '../../domain/entities/crm_notification.dart';
import '../cubit/notifications_cubit.dart';
import '../cubit/notifications_state.dart';
import '../widgets/notification_cards.dart';

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
    return CrmAppShell(
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
          return _NotificationsWorkspace(
            companyId: profile.companyId,
            currentUserId: authUid,
            role: profile.role,
            managerTeamId: profile.teamId,
          );
        },
      ),
    );
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

  @override
  void initState() {
    super.initState();
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
    context.read<NotificationsCubit>().watch(
          companyId: widget.companyId,
          currentUserId: widget.currentUserId,
          role: widget.role,
          managerTeamId: widget.managerTeamId,
          notificationsLimit: notificationHistoryPageLimit,
        );
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
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _PageHeader(
                  unreadCount: state.unreadCount,
                  isMarkingAllRead: state.markingAllRead,
                  onMarkAllRead: state.unreadCount == 0
                      ? null
                      : () => context.read<NotificationsCubit>().markAllRead(
                            companyId: widget.companyId,
                            currentUserId: widget.currentUserId,
                          ),
                ),
                const SizedBox(height: 8),
                _FilterChips(
                  selected: _filter,
                  onSelected: (filter) => setState(() => _filter = filter),
                ),
                const SizedBox(height: AppSpacing.sm),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: narrow
                        ? _MobileNotificationSections(
                            state: state,
                            notifications: notifications,
                            reminders: reminders,
                            companyId: widget.companyId,
                          )
                        : Row(
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
    return switch (_filter) {
      _NotificationFilter.all => notifications,
      _NotificationFilter.unread =>
        notifications.where((item) => !item.isRead).toList(),
      _NotificationFilter.attention => const [],
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
    final hasHiddenUnreadHistory = state.unreadCount > 0 &&
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
    return _SectionCard(
      title: l.notifications,
      expandChild: !shrinkWrap && notifications.isNotEmpty,
      child: content,
    );
  }
}

class _AttentionList extends StatelessWidget {
  const _AttentionList({
    required this.state,
    required this.reminders,
    this.shrinkWrap = false,
  });

  final NotificationsState state;
  final List<AttentionReminder> reminders;
  final bool shrinkWrap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    Widget content;
    if (state.reminderMessage != null) {
      content = _InlineErrorMessage(
        message: localizeErrorMessage(l, state.reminderMessage),
      );
    } else if (reminders.isEmpty) {
      content = AppEmptyState(
        title: l.noUrgentReminders,
        message: l.noUrgentRemindersMessage,
        icon: Icons.event_available,
      );
    } else {
      content = ListView.builder(
        shrinkWrap: shrinkWrap,
        physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
        itemCount: reminders.length,
        itemBuilder: (context, index) {
          final reminder = reminders[index];
          return AttentionReminderCard(
            reminder: reminder,
            onOpen: () => _openRoute(context, reminder.route),
          );
        },
      );
    }
    return _SectionCard(
      title: l.attentionNeeded,
      expandChild: !shrinkWrap && reminders.isNotEmpty,
      child: content,
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
    required this.expandChild,
  });

  final String title;
  final Widget child;
  final bool expandChild;

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
            Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w800),
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

void _openRoute(BuildContext context, String route) {
  final cleanRoute = route.trim();
  final l = AppLocalizations.of(context)!;
  if (!_isAllowedNotificationRoute(cleanRoute)) {
    AppFeedback.warning(context, l.notificationRouteUnavailable);
    return;
  }
  context.go(cleanRoute);
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
