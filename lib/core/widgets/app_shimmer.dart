import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

class AppShimmer extends StatefulWidget {
  const AppShimmer({
    super.key,
    required this.child,
    this.baseColor,
    this.highlightColor,
  });

  final Widget child;
  final Color? baseColor;
  final Color? highlightColor;

  @override
  State<AppShimmer> createState() => _AppShimmerState();
}

class _AppShimmerState extends State<AppShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1250),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = widget.baseColor ??
        AppColors.borderColor(context).withValues(alpha: 0.34);
    final highlight = widget.highlightColor ??
        AppColors.cardSurface(context).withValues(alpha: 0.92);

    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            final width = bounds.width <= 0 ? 1.0 : bounds.width;
            final start = -1.0 + (_controller.value * 2.4);
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [base, highlight, base],
              stops: const [0.25, 0.50, 0.75],
              transform: _SlidingGradientTransform(start * width),
            ).createShader(bounds);
          },
          child: child,
        );
      },
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  const _SlidingGradientTransform(this.offset);

  final double offset;

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(offset, 0, 0);
  }
}

class AppShimmerBlock extends StatelessWidget {
  const AppShimmerBlock({
    super.key,
    this.width,
    required this.height,
    this.borderRadius,
  });

  final double? width;
  final double height;
  final BorderRadiusGeometry? borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.borderColor(context).withValues(alpha: 0.34),
        borderRadius: borderRadius ?? AppRadius.medium,
      ),
    );
  }
}

class AppShimmerLoading extends StatelessWidget {
  const AppShimmerLoading({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final text = message?.trim();
    return AppShimmer(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const AppShimmerBlock(width: 52, height: 52),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: const [
                          AppShimmerBlock(height: 16),
                          SizedBox(height: AppSpacing.xs),
                          AppShimmerBlock(height: 12),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                const AppShimmerBlock(height: 72),
                const SizedBox(height: AppSpacing.sm),
                const AppShimmerBlock(height: 72),
                const SizedBox(height: AppSpacing.sm),
                const AppShimmerBlock(height: 72),
                if (text != null && text.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    text,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondaryColor(context),
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
