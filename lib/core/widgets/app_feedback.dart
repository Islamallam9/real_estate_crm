import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

enum _AppFeedbackTone { success, error, warning, info }

class AppFeedback {
  const AppFeedback._();

  static final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  static void success(BuildContext context, String message) {
    _show(context, message, _AppFeedbackTone.success);
  }

  static void error(BuildContext context, String message) {
    _show(context, message, _AppFeedbackTone.error);
  }

  static void warning(BuildContext context, String message) {
    _show(context, message, _AppFeedbackTone.warning);
  }

  static void info(BuildContext context, String message) {
    _show(context, message, _AppFeedbackTone.info);
  }

  static void _show(
    BuildContext context,
    String message,
    _AppFeedbackTone tone,
  ) {
    if (scaffoldMessengerKey.currentState == null) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final messenger = scaffoldMessengerKey.currentState;
      final safeContext = scaffoldMessengerKey.currentContext ?? context;
      if (messenger == null || !messenger.mounted) {
        return;
      }

      final colors = _FeedbackColors.of(safeContext, tone);
      final bottomInset = MediaQuery.maybeOf(safeContext)?.padding.bottom ?? 0;

      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            elevation: 0,
            backgroundColor: Colors.transparent,
            padding: EdgeInsets.zero,
            margin: EdgeInsetsDirectional.fromSTEB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              AppSpacing.md + bottomInset,
            ),
            duration: const Duration(seconds: 3),
            content: DecoratedBox(
              decoration: BoxDecoration(
                color: colors.background,
                border: Border.all(color: colors.border),
                borderRadius: AppRadius.large,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.10),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(
                  AppSpacing.sm,
                  10,
                  AppSpacing.md,
                  10,
                ),
                child: Row(
                  children: [
                    Icon(_iconFor(tone), color: colors.foreground, size: 20),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        message,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(safeContext).textTheme.bodyMedium?.copyWith(
                              color: colors.text,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
    });
  }

  static IconData _iconFor(_AppFeedbackTone tone) {
    return switch (tone) {
      _AppFeedbackTone.success => Icons.check_circle_outline,
      _AppFeedbackTone.error => Icons.error_outline,
      _AppFeedbackTone.warning => Icons.warning_amber_rounded,
      _AppFeedbackTone.info => Icons.info_outline,
    };
  }
}

class _FeedbackColors {
  const _FeedbackColors({
    required this.background,
    required this.border,
    required this.foreground,
    required this.text,
  });

  final Color background;
  final Color border;
  final Color foreground;
  final Color text;

  factory _FeedbackColors.of(BuildContext context, _AppFeedbackTone tone) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final text = AppColors.textPrimaryColor(context);

    if (isDark) {
      return switch (tone) {
        _AppFeedbackTone.success => _FeedbackColors(
          background: AppColors.darkSurface,
          border: const Color(0xFF1F6B42),
          foreground: AppColors.successColor(context),
          text: text,
        ),
        _AppFeedbackTone.error => _FeedbackColors(
          background: AppColors.darkSurface,
          border: const Color(0xFF7F2D2D),
          foreground: AppColors.errorColor(context),
          text: text,
        ),
        _AppFeedbackTone.warning => _FeedbackColors(
          background: AppColors.darkSurface,
          border: AppColors.darkPrimary,
          foreground: AppColors.warningColor(context),
          text: text,
        ),
        _AppFeedbackTone.info => _FeedbackColors(
          background: AppColors.darkSurface,
          border: const Color(0xFF315A8E),
          foreground: AppColors.infoColor(context),
          text: text,
        ),
      };
    }

    return switch (tone) {
      _AppFeedbackTone.success => _FeedbackColors(
        background: AppColors.surface,
        border: AppColors.successSoft,
        foreground: AppColors.successColor(context),
        text: text,
      ),
      _AppFeedbackTone.error => _FeedbackColors(
        background: AppColors.surface,
        border: AppColors.errorSoft,
        foreground: AppColors.errorColor(context),
        text: text,
      ),
      _AppFeedbackTone.warning => _FeedbackColors(
        background: AppColors.surface,
        border: AppColors.primaryBorder,
        foreground: AppColors.warningColor(context),
        text: text,
      ),
      _AppFeedbackTone.info => _FeedbackColors(
        background: AppColors.surface,
        border: AppColors.infoSoft,
        foreground: AppColors.infoColor(context),
        text: text,
      ),
    };
  }
}
