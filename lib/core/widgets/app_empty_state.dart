import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/app_colors.dart';
import 'app_button.dart';

class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onActionPressed,
  });

  final String title;
  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onActionPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 44, color: AppColors.primaryColor(context)),
              const SizedBox(height: AppSpacing.md),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppColors.textPrimaryColor(context),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondaryColor(context),
                ),
                textAlign: TextAlign.center,
              ),
              if (actionLabel != null && onActionPressed != null) ...[
                const SizedBox(height: AppSpacing.lg),
                AppButton(label: actionLabel!, onPressed: onActionPressed),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
