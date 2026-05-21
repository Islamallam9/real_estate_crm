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
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite ? constraints.maxWidth : 720.0;
        final columns = width >= 980
            ? 4
            : width >= 620
                ? 2
                : 1;
        final cardWidth = columns == 1
            ? double.infinity
            : (width - ((columns - 1) * AppSpacing.sm)) / columns;

        return SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1180),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const _ShimmerObject(
                        width: 52,
                        height: 52,
                        radius: AppRadius.large,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: const [
                            _ShimmerObject(height: 18, width: 220),
                            SizedBox(height: AppSpacing.xs),
                            _ShimmerObject(height: 12, width: 150),
                          ],
                        ),
                      ),
                      if (width > 520) ...[
                        const SizedBox(width: AppSpacing.sm),
                        const _ShimmerObject(width: 120, height: 38),
                      ],
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      for (var index = 0; index < (columns == 1 ? 4 : 6); index++)
                        SizedBox(
                          width: cardWidth,
                          child: const _MetricSkeletonCard(),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      SizedBox(
                        width: columns == 1 ? double.infinity : (width - AppSpacing.sm) * 0.58,
                        child: const _ChartSkeletonCard(),
                      ),
                      SizedBox(
                        width: columns == 1 ? double.infinity : (width - AppSpacing.sm) * 0.42,
                        child: const _ListSkeletonCard(),
                      ),
                    ],
                  ),
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
        );
      },
    );
  }
}

class _ShimmerObject extends StatelessWidget {
  const _ShimmerObject({
    this.width,
    required this.height,
    this.radius,
  });

  final double? width;
  final double height;
  final BorderRadiusGeometry? radius;

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: AppShimmerBlock(
        width: width,
        height: height,
        borderRadius: radius ?? AppRadius.medium,
      ),
    );
  }
}

class _MetricSkeletonCard extends StatelessWidget {
  const _MetricSkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.cardSurface(context),
        borderRadius: AppRadius.xLarge,
        border: Border.all(color: AppColors.borderColor(context)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _ShimmerObject(width: 42, height: 42, radius: AppRadius.large),
              Spacer(),
              _ShimmerObject(width: 58, height: 22, radius: AppRadius.large),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          _ShimmerObject(width: 86, height: 26),
          SizedBox(height: AppSpacing.xs),
          _ShimmerObject(width: 140, height: 12),
        ],
      ),
    );
  }
}

class _ChartSkeletonCard extends StatelessWidget {
  const _ChartSkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.cardSurface(context),
        borderRadius: AppRadius.xLarge,
        border: Border.all(color: AppColors.borderColor(context)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ShimmerObject(width: 180, height: 18),
          SizedBox(height: AppSpacing.lg),
          Expanded(
            child: Center(
              child: _ShimmerObject(width: 136, height: 136, radius: AppRadius.xLarge),
            ),
          ),
        ],
      ),
    );
  }
}

class _ListSkeletonCard extends StatelessWidget {
  const _ListSkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.cardSurface(context),
        borderRadius: AppRadius.xLarge,
        border: Border.all(color: AppColors.borderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _ShimmerObject(width: 170, height: 18),
          SizedBox(height: AppSpacing.md),
          _SkeletonRow(),
          SizedBox(height: AppSpacing.sm),
          _SkeletonRow(),
          SizedBox(height: AppSpacing.sm),
          _SkeletonRow(),
        ],
      ),
    );
  }
}

class _SkeletonRow extends StatelessWidget {
  const _SkeletonRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        _ShimmerObject(width: 38, height: 38, radius: AppRadius.large),
        SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ShimmerObject(height: 13),
              SizedBox(height: AppSpacing.xs),
              _ShimmerObject(width: 130, height: 10),
            ],
          ),
        ),
      ],
    );
  }
}
