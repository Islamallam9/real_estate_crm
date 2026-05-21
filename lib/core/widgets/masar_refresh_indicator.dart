import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_shadows.dart';
import 'masar_brand.dart';

class MasarRefreshIndicator extends StatefulWidget {
  const MasarRefreshIndicator({
    super.key,
    required this.onRefresh,
    required this.child,
  });

  final Future<void> Function() onRefresh;
  final Widget child;

  @override
  State<MasarRefreshIndicator> createState() => _MasarRefreshIndicatorState();
}

class _MasarRefreshIndicatorState extends State<MasarRefreshIndicator> {
  RefreshIndicatorStatus? _status;

  bool get _visible {
    final status = _status;
    return status != null &&
        status != RefreshIndicatorStatus.canceled &&
        status != RefreshIndicatorStatus.done;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        RefreshIndicator.noSpinner(
          onRefresh: widget.onRefresh,
          onStatusChange: (status) {
            if (!mounted || status == _status) {
              return;
            }
            setState(() => _status = status);
          },
          triggerMode: RefreshIndicatorTriggerMode.anywhere,
          notificationPredicate: (notification) =>
              notification.metrics.axis == Axis.vertical,
          child: widget.child,
        ),
        PositionedDirectional(
          top: 8,
          start: 0,
          end: 0,
          child: IgnorePointer(
            child: AnimatedOpacity(
              opacity: _visible ? 1 : 0,
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOutCubic,
              child: AnimatedSlide(
                offset: _visible ? Offset.zero : const Offset(0, -0.35),
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                child: Center(
                  child: _MasarRefreshBadge(status: _status),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MasarRefreshBadge extends StatelessWidget {
  const _MasarRefreshBadge({required this.status});

  final RefreshIndicatorStatus? status;

  @override
  Widget build(BuildContext context) {
    final isRefreshing = status == RefreshIndicatorStatus.refresh ||
        status == RefreshIndicatorStatus.snap;
    final primary = AppColors.primaryColor(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      width: isRefreshing ? 48 : 42,
      height: isRefreshing ? 48 : 42,
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: AppColors.cardSurface(context).withValues(alpha: 0.96),
        borderRadius: AppRadius.large,
        border: Border.all(color: primary.withValues(alpha: 0.28)),
        boxShadow: AppShadows.card,
      ),
      child: AnimatedRotation(
        turns: isRefreshing ? 1 : 0,
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeInOutCubic,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(child: MasarBrandMark(size: 26)),
        ),
      ),
    );
  }
}

class MasarRefreshPhysics extends AlwaysScrollableScrollPhysics {
  const MasarRefreshPhysics({super.parent});

  @override
  MasarRefreshPhysics applyTo(ScrollPhysics? ancestor) {
    return MasarRefreshPhysics(parent: buildParent(ancestor));
  }
}
