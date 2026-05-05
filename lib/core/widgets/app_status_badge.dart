import 'package:flutter/material.dart';

import '../theme/app_radius.dart';

enum AppStatusTone { neutral, success, warning, error, info }

class AppStatusBadge extends StatelessWidget {
  const AppStatusBadge({
    super.key,
    required this.label,
    this.tone = AppStatusTone.neutral,
  });

  final String label;
  final AppStatusTone tone;

  @override
  Widget build(BuildContext context) {
    final colors = _colorsFor(context, tone);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: AppRadius.small,
        border: Border.all(color: colors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: colors.foreground,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  _BadgeColors _colorsFor(BuildContext context, AppStatusTone tone) {
    final scheme = Theme.of(context).colorScheme;

    return switch (tone) {
      AppStatusTone.success => const _BadgeColors(
        background: Color(0xFFEAF7EF),
        foreground: Color(0xFF15803D),
        border: Color(0xFFC8EAD3),
      ),
      AppStatusTone.warning => const _BadgeColors(
        background: Color(0xFFFFF7E6),
        foreground: Color(0xFF9A5B00),
        border: Color(0xFFF2D49B),
      ),
      AppStatusTone.error => const _BadgeColors(
        background: Color(0xFFFFEDEA),
        foreground: Color(0xFFB42318),
        border: Color(0xFFF4C7C1),
      ),
      AppStatusTone.info => const _BadgeColors(
        background: Color(0xFFEFF6FF),
        foreground: Color(0xFF2563EB),
        border: Color(0xFFC8DDFF),
      ),
      AppStatusTone.neutral => _BadgeColors(
        background: scheme.surface,
        foreground: scheme.onSurfaceVariant,
        border: scheme.outlineVariant,
      ),
    };
  }
}

class _BadgeColors {
  const _BadgeColors({
    required this.background,
    required this.foreground,
    required this.border,
  });

  final Color background;
  final Color foreground;
  final Color border;
}
