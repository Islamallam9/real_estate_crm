import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_shadows.dart';

class MasarTabItem {
  const MasarTabItem({
    required this.label,
    required this.icon,
    this.badge,
  });

  final String label;
  final IconData icon;
  final String? badge;
}

class MasarTabBar extends StatefulWidget {
  const MasarTabBar({
    super.key,
    required this.tabs,
    this.compact = false,
    this.fullWidth = false,
  });

  final List<MasarTabItem> tabs;
  final bool compact;
  final bool fullWidth;

  @override
  State<MasarTabBar> createState() => _MasarTabBarState();
}

class _MasarTabBarState extends State<MasarTabBar> {
  TabController? _controller;
  int? _lastControllerIndex;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = DefaultTabController.maybeOf(context);
    if (_controller == controller) {
      return;
    }

    _controller?.removeListener(_handleControllerChange);
    _controller = controller;
    _lastControllerIndex = controller?.index;
    _controller?.addListener(_handleControllerChange);
  }

  @override
  void dispose() {
    _controller?.removeListener(_handleControllerChange);
    super.dispose();
  }

  void _handleControllerChange() {
    final nextIndex = _controller?.index;
    if (!mounted || nextIndex == _lastControllerIndex) {
      return;
    }

    _lastControllerIndex = nextIndex;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null || widget.tabs.isEmpty) {
      return const SizedBox.shrink();
    }

    final isDark = AppColors.isDark(context);
    final surface = isDark
        ? AppColors.darkSurfaceAlt.withValues(alpha: 0.84)
        : AppColors.cardSurface(context).withValues(alpha: 0.92);
    final border = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : AppColors.borderColor(context).withValues(alpha: 0.84);
    final isMobileWeb = kIsWeb && MediaQuery.sizeOf(context).width < 720;

    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.compact ? 18 : 26),
      child: _OptionalTabBlur(
        enabled: !isMobileWeb,
        child: Container(
          width: widget.fullWidth ? double.infinity : null,
          padding: EdgeInsets.all(widget.compact ? 4 : 6),
          decoration: BoxDecoration(
            color: surface,
            border: Border.all(color: border),
            borderRadius: BorderRadius.circular(widget.compact ? 18 : 26),
            boxShadow: isMobileWeb
                ? null
                : isDark
                ? [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.20),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ]
                : AppShadows.card,
          ),
          child: _SegmentedTabButtons(
            tabs: widget.tabs,
            selectedIndex:
            controller.index.clamp(0, widget.tabs.length - 1).toInt(),
            compact: widget.compact,
            fullWidth: widget.fullWidth,
            onChanged: (index) {
              if (controller.index != index) {
                controller.animateTo(
                  index,
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeOutCubic,
                );
              }
            },
          ),
        ),
      ),
    );
  }
}

class MasarSwitchTabItem {
  const MasarSwitchTabItem({
    required this.label,
    required this.icon,
    this.badge,
  });

  final String label;
  final IconData icon;
  final String? badge;
}

class MasarSwitchTabBar extends StatelessWidget {
  const MasarSwitchTabBar({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onChanged,
    this.compact = false,
  });

  final List<MasarSwitchTabItem> tabs;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (tabs.isEmpty) {
      return const SizedBox.shrink();
    }

    final isDark = AppColors.isDark(context);
    final surface = isDark
        ? AppColors.darkSurfaceAlt.withValues(alpha: 0.84)
        : AppColors.cardSurface(context).withValues(alpha: 0.92);
    final border = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : AppColors.borderColor(context).withValues(alpha: 0.84);
    final isMobileWeb = kIsWeb && MediaQuery.sizeOf(context).width < 720;

    return ClipRRect(
      borderRadius: BorderRadius.circular(compact ? 18 : 26),
      child: _OptionalTabBlur(
        enabled: !isMobileWeb,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(compact ? 4 : 6),
          decoration: BoxDecoration(
            color: surface,
            border: Border.all(color: border),
            borderRadius: BorderRadius.circular(compact ? 18 : 26),
            boxShadow: isMobileWeb
                ? null
                : isDark
                ? [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.20),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ]
                : AppShadows.card,
          ),
          child: _SegmentedTabButtons(
            tabs: [
              for (final tab in tabs)
                MasarTabItem(
                  label: tab.label,
                  icon: tab.icon,
                  badge: tab.badge,
                ),
            ],
            selectedIndex: selectedIndex.clamp(0, tabs.length - 1).toInt(),
            compact: compact,
            fullWidth: true,
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }
}

class _SegmentedTabButtons extends StatelessWidget {
  const _SegmentedTabButtons({
    required this.tabs,
    required this.selectedIndex,
    required this.onChanged,
    required this.compact,
    required this.fullWidth,
  });

  final List<MasarTabItem> tabs;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final bool compact;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    if (tabs.isEmpty) {
      return const SizedBox.shrink();
    }

    final isDark = AppColors.isDark(context);
    final primary = AppColors.primaryColor(context);
    final selectedForeground =
    isDark ? const Color(0xFF050505) : AppColors.textStrong;
    final inactiveForeground = AppColors.textSecondaryColor(context);

    Widget buildButton(int index) {
      final tab = tabs[index];
      final selected = index == selectedIndex;
      final textColor = selected ? selectedForeground : inactiveForeground;

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Material(
          color: selected ? primary.withValues(alpha: 0.96) : Colors.transparent,
          borderRadius: BorderRadius.circular(compact ? 14 : 20),
          child: InkWell(
            onTap: () => onChanged(index),
            borderRadius: BorderRadius.circular(compact ? 14 : 20),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 10 : 13,
                vertical: compact ? 8 : 11,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(
                        tab.icon,
                        size: compact ? 18 : 20,
                        color: textColor,
                      ),
                      if (tab.badge != null)
                        PositionedDirectional(
                          top: -8,
                          end: -9,
                          child: Container(
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            padding: const EdgeInsetsDirectional.symmetric(
                              horizontal: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.errorColor(context),
                              borderRadius: AppRadius.large,
                              border: Border.all(
                                color: AppColors.cardSurface(context),
                                width: 1.2,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              tab.badge!,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                height: 1,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 7),
                  Flexible(
                    child: Text(
                      tab.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: textColor,
                        fontWeight:
                        selected ? FontWeight.w900 : FontWeight.w700,
                        fontSize: compact ? 11 : 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (fullWidth) {
      return Row(
        children: [
          for (var index = 0; index < tabs.length; index++)
            Expanded(child: buildButton(index)),
        ],
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var index = 0; index < tabs.length; index++) buildButton(index),
        ],
      ),
    );
  }
}

class _OptionalTabBlur extends StatelessWidget {
  const _OptionalTabBlur({
    required this.enabled,
    required this.child,
  });

  final bool enabled;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!enabled) {
      return child;
    }

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
      child: child,
    );
  }
}