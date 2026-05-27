import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import 'masar_brand.dart';

class MasarLoadingView extends StatelessWidget {
  const MasarLoadingView({
    super.key,
    this.message,
    this.compact = false,
    this.overlay = false,
  });

  final String? message;
  final bool compact;
  final bool overlay;

  @override
  Widget build(BuildContext context) {
    final content = Center(
      child: _MasarLoadingCard(message: message, compact: compact),
    );

    if (!overlay) return content;

    return Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.appBackground(context).withValues(alpha: 0.66),
        ),
        child: content,
      ),
    );
  }
}


class MasarLogoLoader extends StatefulWidget {
  const MasarLogoLoader({
    super.key,
    this.size = 42,
    this.message,
  });

  final double size;
  final String? message;

  @override
  State<MasarLogoLoader> createState() => _MasarLogoLoaderState();
}

class _MasarLogoLoaderState extends State<MasarLogoLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final message = widget.message?.trim() ?? '';
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final scale = 0.94 + (_controller.value * 0.06);
            return Transform.scale(
              scale: scale,
              child: child,
            );
          },
          child: MasarBrandMark(size: widget.size),
        ),
        if (message.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            message,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondaryColor(context),
                ),
          ),
        ],
      ],
    );
  }
}

class _MasarLoadingCard extends StatelessWidget {
  const _MasarLoadingCard({required this.compact, this.message});

  final String? message;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final width = compact ? 172.0 : 240.0;
    return Container(
      width: width,
      padding: EdgeInsets.all(compact ? AppSpacing.md : AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.cardSurface(context).withValues(alpha: 0.96),
        borderRadius: AppRadius.xLarge,
        border: Border.all(color: AppColors.borderColor(context)),
        boxShadow: Theme.of(context).brightness == Brightness.dark
            ? AppShadows.subtle
            : AppShadows.card,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _MiniBrandMark(size: compact ? 42 : 52),
          SizedBox(height: compact ? AppSpacing.sm : AppSpacing.md),
          const _PremiumLoadingDots(),
          if (message != null && message!.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              message!,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondaryColor(context),
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MiniBrandMark extends StatelessWidget {
  const _MiniBrandMark({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.primaryColor(context).withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(size * 0.28),
        border: Border.all(
          color: AppColors.primaryColor(context).withValues(alpha: 0.24),
        ),
      ),
      child: MasarBrandMark(size: size * 0.70),
    );
  }
}

class _PremiumLoadingDots extends StatefulWidget {
  const _PremiumLoadingDots();

  @override
  State<_PremiumLoadingDots> createState() => _PremiumLoadingDotsState();
}

class _PremiumLoadingDotsState extends State<_PremiumLoadingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1050),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var index = 0; index < 3; index++)
              Transform.translate(
                offset: Offset(0, -math.sin((_controller.value * math.pi * 2) - (index * 0.75)) * 4),
                child: Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: Color.lerp(
                      AppColors.borderColor(context),
                      AppColors.primaryColor(context),
                      0.35 + (math.sin((_controller.value * math.pi * 2) - (index * 0.75)) + 1) * 0.32,
                    ),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
