import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../l10n/app_localizations.dart';
import '../cubit/notification_push_token_cubit.dart';
import '../cubit/notification_push_token_state.dart';

enum NotificationPushStatusCardMode { banner, inline }

class NotificationPushStatusCard extends StatelessWidget {
  const NotificationPushStatusCard({
    super.key,
    this.mode = NotificationPushStatusCardMode.inline,
  });

  final NotificationPushStatusCardMode mode;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotificationPushTokenCubit, NotificationPushTokenState>(
      buildWhen: (previous, current) =>
          previous.status != current.status ||
          previous.isSyncing != current.isSyncing ||
          previous.scope != current.scope ||
          previous.uid != current.uid ||
          previous.token != current.token ||
          previous.lastError != current.lastError ||
          previous.promptDismissedUntil != current.promptDismissedUntil ||
          previous.localRegistrationHint != current.localRegistrationHint,
      builder: (context, state) {
        if (mode == NotificationPushStatusCardMode.banner) {
          if (!state.canShowPromptBanner) {
            return const SizedBox.shrink();
          }
        } else if (!state.canShowManualControl && !state.isRegistered) {
          return const SizedBox.shrink();
        }

        final card = _NotificationPushStatusCardBody(
          state: state,
          compact: mode == NotificationPushStatusCardMode.banner,
          showDismissActions: mode == NotificationPushStatusCardMode.banner,
        );

        if (mode != NotificationPushStatusCardMode.banner) {
          return card;
        }

        return Dismissible(
          key: ValueKey('notification-permission-banner:${state.scope.name}:${state.companyId}:${state.uid}:${state.status.name}:${state.lastError}'),
          direction: DismissDirection.horizontal,
          onDismissed: (_) => _dismissForCurrentState(context, state),
          child: card,
        );
      },
    );
  }

  void _dismissForCurrentState(
    BuildContext context,
    NotificationPushTokenState state,
  ) {
    final cubit = context.read<NotificationPushTokenCubit>();
    if (state.status == NotificationPushTokenStatus.failed) {
      cubit.snoozePrompt(const Duration(hours: 24));
      return;
    }
    if (state.status == NotificationPushTokenStatus.denied ||
        state.status == NotificationPushTokenStatus.unavailable) {
      cubit.snoozePrompt(const Duration(days: 14));
      return;
    }
    cubit.snoozePrompt(const Duration(days: 7));
  }
}

class _NotificationPushStatusCardBody extends StatelessWidget {
  const _NotificationPushStatusCardBody({
    required this.state,
    required this.compact,
    required this.showDismissActions,
  });

  final NotificationPushTokenState state;
  final bool compact;
  final bool showDismissActions;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final title = _title(l, state);
    final body = _body(l, state);
    final icon = _icon(state);
    final iconColor = _iconColor(context, state);
    final maxWidth = MediaQuery.sizeOf(context).width < 720
        ? MediaQuery.sizeOf(context).width - 24
        : (compact ? 440.0 : double.infinity);

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.cardSurface(context),
          borderRadius: AppRadius.xLarge,
          border: Border.all(color: AppColors.borderColor(context)),
          boxShadow: compact ? const [] : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final narrow = constraints.maxWidth < 430;
              final leading = Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconColor, size: 21),
              );
              final text = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimaryColor(context),
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    body,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondaryColor(context),
                          height: 1.28,
                        ),
                  ),
                ],
              );
              final actions = _actions(context, state, showDismissActions);
              if (narrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        leading,
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(child: text),
                      ],
                    ),
                    if (actions.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.xs,
                        alignment: WrapAlignment.end,
                        children: actions,
                      ),
                    ],
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  leading,
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: text),
                  if (actions.isNotEmpty) ...[
                    const SizedBox(width: AppSpacing.md),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      alignment: WrapAlignment.end,
                      children: actions,
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }


  Future<void> _handlePrimaryAction(
    BuildContext context,
    NotificationPushTokenState state,
    NotificationPushTokenCubit cubit,
  ) async {
    if (kIsWeb && state.status == NotificationPushTokenStatus.permissionRequired) {
      final l = AppLocalizations.of(context)!;
      final navigator = Navigator.maybeOf(context, rootNavigator: true);
      if (navigator != null) {
        final confirmed = await showDialog<bool>(
          context: navigator.context,
          useRootNavigator: true,
          builder: (dialogContext) => AlertDialog(
            title: Text(l.notificationPermissionPromptTitle),
            content: Text(l.notificationPermissionPromptBody),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(l.notNow),
              ),
              FilledButton.icon(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                icon: const Icon(Icons.notifications_active_outlined, size: 18),
                label: Text(l.notificationPermissionEnableAction),
              ),
            ],
          ),
        );
        if (confirmed != true) {
          await cubit.snoozePrompt(const Duration(days: 7));
          return;
        }
      }
    }
    await cubit.requestPermissionAndSync();
  }

  List<Widget> _actions(
    BuildContext context,
    NotificationPushTokenState state,
    bool showDismissActions,
  ) {
    final l = AppLocalizations.of(context)!;
    final cubit = context.read<NotificationPushTokenCubit>();
    if (state.isRegistered) {
      return const <Widget>[];
    }
    final primaryLabel = state.status == NotificationPushTokenStatus.failed ||
            state.status == NotificationPushTokenStatus.unavailable
        ? l.retry
        : l.notificationPermissionEnableAction;
    final actions = <Widget>[
      AppButton(
        label: primaryLabel,
        icon: Icons.notifications_active_outlined,
        isLoading: state.isSyncing,
        onPressed: state.isSyncing
            ? null
            : () => _handlePrimaryAction(context, state, cubit),
      ),
    ];
    if (showDismissActions) {
      actions.add(
        TextButton(
          onPressed: state.isSyncing
              ? null
              : () {
                  final duration = state.status == NotificationPushTokenStatus.failed
                      ? const Duration(hours: 24)
                      : const Duration(days: 7);
                  cubit.snoozePrompt(duration);
                },
          child: Text(
            state.status == NotificationPushTokenStatus.failed
                ? l.dismiss
                : l.notNow,
          ),
        ),
      );
    }
    return actions;
  }

  String _title(AppLocalizations l, NotificationPushTokenState state) {
    if (state.isRegistered) {
      return l.notificationPermissionEnabledTitle;
    }
    if (state.hasConfigurationError) {
      return l.notificationPermissionConfigurationIssueTitle;
    }
    if (state.status == NotificationPushTokenStatus.failed ||
        state.status == NotificationPushTokenStatus.unavailable) {
      return l.notificationPermissionNotConnectedTitle;
    }
    if (state.status == NotificationPushTokenStatus.denied) {
      return l.notificationPermissionBlockedTitle;
    }
    return l.notificationPermissionPromptTitle;
  }

  String _body(AppLocalizations l, NotificationPushTokenState state) {
    if (state.isRegistered) {
      return l.notificationPermissionEnabledBody;
    }
    if (state.hasConfigurationError) {
      return l.notificationPermissionConfigurationIssueBody;
    }
    if (state.status == NotificationPushTokenStatus.failed) {
      return l.notificationPermissionSyncFailedBody;
    }
    if (state.status == NotificationPushTokenStatus.denied) {
      return l.notificationPermissionBlockedBody;
    }
    if (state.status == NotificationPushTokenStatus.unavailable) {
      return l.notificationPermissionUnavailableBody;
    }
    return l.notificationPermissionPromptBody;
  }

  IconData _icon(NotificationPushTokenState state) {
    if (state.isRegistered) {
      return Icons.verified_rounded;
    }
    if (state.status == NotificationPushTokenStatus.failed ||
        state.hasConfigurationError) {
      return Icons.sync_problem_rounded;
    }
    if (state.status == NotificationPushTokenStatus.denied) {
      return Icons.notifications_off_outlined;
    }
    return Icons.notifications_active_outlined;
  }

  Color _iconColor(BuildContext context, NotificationPushTokenState state) {
    if (state.isRegistered) {
      return AppColors.success;
    }
    if (state.status == NotificationPushTokenStatus.failed ||
        state.hasConfigurationError) {
      return AppColors.warning;
    }
    return AppColors.primaryColor(context);
  }
}
