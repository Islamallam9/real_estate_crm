import 'package:flutter/material.dart';

import '../theme/app_radius.dart';

enum AppButtonVariant { primary, secondary, danger, ghost }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.isExpanded = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final AppButtonVariant variant;
  final bool isLoading;
  final bool isExpanded;

  @override
  Widget build(BuildContext context) {
    final child = _ButtonContent(
      label: label,
      icon: icon,
      isLoading: isLoading,
    );
    final effectiveOnPressed = isLoading ? null : onPressed;

    final scaleWrapper = _PressableButton(child: child);

    final button = switch (variant) {
      AppButtonVariant.primary => FilledButton(
        onPressed: effectiveOnPressed,
        child: scaleWrapper,
      ),
      AppButtonVariant.secondary => OutlinedButton(
        onPressed: effectiveOnPressed,
        child: scaleWrapper,
      ),
      AppButtonVariant.danger => FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.error,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.large),
        ),
        onPressed: effectiveOnPressed,
        child: scaleWrapper,
      ),
      AppButtonVariant.ghost => TextButton(
        onPressed: effectiveOnPressed,
        child: scaleWrapper,
      ),
    };

    return isExpanded
        ? SizedBox(width: double.infinity, child: button)
        : button;
  }
}

class _PressableButton extends StatelessWidget {
  const _PressableButton({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 120),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeOut,
      child: child,
    );
  }
}

class _ButtonContent extends StatelessWidget {
  const _ButtonContent({
    required this.label,
    required this.icon,
    required this.isLoading,
  });

  final String label;
  final IconData? icon;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const SizedBox.square(
        dimension: 18,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    if (icon == null) {
      return Text(label);
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
          ),
        ),
      ],
    );
  }
}
