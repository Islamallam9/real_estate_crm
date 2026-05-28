import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/attention_reminder.dart';
import '../../domain/entities/crm_notification.dart';
import 'notification_text.dart';

class NotificationCard extends StatelessWidget {
  const NotificationCard({
    super.key,
    required this.notification,
    required this.onOpen,
    required this.onMarkRead,
    this.onResolve,
    this.onClear,
    this.isMarking = false,
  });

  final CrmNotification notification;
  final VoidCallback onOpen;
  final VoidCallback onMarkRead;
  final VoidCallback? onResolve;
  final VoidCallback? onClear;
  final bool isMarking;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final unread = !notification.isRead;
    final needsAction = notification.needsAction;
    final resolved = notification.isResolved;
    final borderColor = needsAction
        ? _priorityColor(context, notification).withValues(alpha: 0.42)
        : unread
            ? AppColors.primaryColor(context).withValues(alpha: 0.42)
            : AppColors.borderColor(context);
    final title = notificationTitle(l, notification);
    final body = notificationBody(l, notification).trim();

    return Card(
      elevation: 0,
      margin: const EdgeInsetsDirectional.only(bottom: AppSpacing.xs),
      color: needsAction
          ? _priorityColor(context, notification).withValues(alpha: 0.035)
          : unread
              ? AppColors.primaryColor(context).withValues(alpha: 0.035)
              : AppColors.cardSurface(context),
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.large,
        side: BorderSide(color: borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(12, 10, 8, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _UnreadDot(visible: unread),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: _ModulePill(
                            label: moduleLabel(l, notification.module),
                          ),
                        ),
                        if (needsAction || resolved) ...[
                          const SizedBox(width: AppSpacing.xs),
                          Flexible(
                            child: _StatePill(
                              label: needsAction ? l.attentionNeeded : l.resolved,
                              color: needsAction
                                  ? _priorityColor(context, notification)
                                  : AppColors.successColor(context),
                            ),
                          ),
                        ],
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            relativeTime(l, notification.createdAt),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.end,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: AppColors.textSecondaryColor(context),
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimaryColor(context),
                          ),
                    ),
                    if (body.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        body,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondaryColor(context),
                              height: 1.25,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (onClear != null)
                    SizedBox.square(
                      dimension: 30,
                      child: IconButton(
                        tooltip: l.clearNotification,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints.tightFor(
                          width: 30,
                          height: 30,
                        ),
                        onPressed: onClear,
                        icon: const Icon(Icons.close_rounded, size: 17),
                      ),
                    ),
                  if (unread)
                    SizedBox.square(
                      dimension: 30,
                      child: IconButton(
                        tooltip: l.markRead,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints.tightFor(
                          width: 30,
                          height: 30,
                        ),
                        onPressed: isMarking ? null : onMarkRead,
                        icon: isMarking
                            ? const SizedBox.square(
                                dimension: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.done, size: 17),
                      ),
                    ),
                  Icon(
                    Directionality.of(context) == TextDirection.rtl
                        ? Icons.chevron_left
                        : Icons.chevron_right,
                    size: 20,
                    color: AppColors.textSecondaryColor(context),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AttentionReminderCard extends StatelessWidget {
  const AttentionReminderCard({
    super.key,
    required this.reminder,
    required this.onOpen,
    this.onClear,
  });

  final AttentionReminder reminder;
  final VoidCallback onOpen;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final isOverdue = reminder.type == AttentionReminderType.followUpOverdue ||
        reminder.type == AttentionReminderType.taskOverdue ||
        reminder.type == AttentionReminderType.appointmentMissed;
    final isDueNow = reminder.type == AttentionReminderType.appointmentDueNow;
    final accentColor = isOverdue || isDueNow
        ? AppColors.errorColor(context)
        : AppColors.warningColor(context);
    final body = [
      reminderBody(l, reminder),
      dueDateLabel(l, reminder.dueAt),
    ].where((part) => part.trim().isNotEmpty).join(' - ');

    return Card(
      elevation: 0,
      margin: const EdgeInsetsDirectional.only(bottom: AppSpacing.xs),
      color: accentColor.withValues(alpha: 0.035),
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.large,
        side: BorderSide(color: accentColor.withValues(alpha: 0.28)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(12, 9, 8, 9),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.10),
                  borderRadius: AppRadius.medium,
                ),
                child: Icon(
                  isOverdue || isDueNow
                      ? Icons.warning_amber_rounded
                      : Icons.event_available,
                  color: accentColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      reminderTitle(l, reminder),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimaryColor(context),
                          ),
                    ),
                    if (body.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        body,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondaryColor(context),
                              height: 1.25,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (onClear != null)
                    SizedBox.square(
                      dimension: 30,
                      child: IconButton(
                        tooltip: l.clearNotification,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints.tightFor(
                          width: 30,
                          height: 30,
                        ),
                        onPressed: onClear,
                        icon: const Icon(Icons.close_rounded, size: 17),
                      ),
                    ),
                  Icon(
                    Directionality.of(context) == TextDirection.rtl
                        ? Icons.chevron_left
                        : Icons.chevron_right,
                    size: 20,
                    color: AppColors.textSecondaryColor(context),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UnreadDot extends StatelessWidget {
  const _UnreadDot({required this.visible});

  final bool visible;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 7),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: visible ? 8 : 0,
        height: visible ? 8 : 0,
        decoration: BoxDecoration(
          color: AppColors.primaryColor(context),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}


Color _priorityColor(BuildContext context, CrmNotification notification) {
  return switch (notification.priority) {
    CrmNotificationPriority.urgent => AppColors.errorColor(context),
    CrmNotificationPriority.high => AppColors.warningColor(context),
    CrmNotificationPriority.low => AppColors.textSecondaryColor(context),
    CrmNotificationPriority.normal => AppColors.primaryColor(context),
  };
}

class _StatePill extends StatelessWidget {
  const _StatePill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
              ),
        ),
      ),
    );
  }
}

class _InlineActionChip extends StatelessWidget {
  const _InlineActionChip({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 15),
      label: Text(label),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      onPressed: onPressed,
    );
  }
}

class _ModulePill extends StatelessWidget {
  const _ModulePill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.primaryColor(context).withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.primaryColor(context),
                fontWeight: FontWeight.w800,
              ),
        ),
      ),
    );
  }
}
