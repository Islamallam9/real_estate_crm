import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';

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
    final primary = AppColors.primaryColor(context);
    final selectedForeground = isDark ? const Color(0xFF050505) : AppColors.textStrong;
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: widget.fullWidth ? constraints.maxWidth : 0,
                  ),
                  child: GNav(
                    selectedIndex: (controller.index.clamp(0, widget.tabs.length - 1) as int),
                    onTabChange: (index) {
                      if (controller.index != index) {
                        controller.animateTo(
                          index,
                          duration: const Duration(milliseconds: 240),
                          curve: Curves.easeOutCubic,
                        );
                      }
                    },
                    gap: widget.compact ? 5 : 7,
                    iconSize: widget.compact ? 18 : 20,
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    backgroundColor: Colors.transparent,
                    color: AppColors.textSecondaryColor(context),
                    activeColor: selectedForeground,
                    textStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: selectedForeground,
                          fontWeight: FontWeight.w900,
                          fontSize: widget.compact ? 11 : 12,
                          overflow: TextOverflow.ellipsis,
                        ),
                    tabBackgroundColor: primary.withValues(alpha: 0.96),
                    tabBorderRadius: widget.compact ? 14 : 20,
                    padding: EdgeInsets.symmetric(
                      horizontal: widget.compact ? 10 : 13,
                      vertical: widget.compact ? 8 : 11,
                    ),
                    tabs: [
                      for (final tab in widget.tabs)
                        GButton(
                          icon: tab.icon,
                          text: tab.badge == null ? tab.label : '${tab.label}  ${tab.badge}',
                          leading: tab.badge == null
                              ? null
                              : _TabBadgeIcon(icon: tab.icon, badge: tab.badge!),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _TabBadgeIcon extends StatelessWidget {
  const _TabBadgeIcon({required this.icon, required this.badge});

  final IconData icon;
  final String badge;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon, size: 20),
        PositionedDirectional(
          top: -8,
          end: -9,
          child: Container(
            constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
            padding: const EdgeInsetsDirectional.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: AppColors.errorColor(context),
              borderRadius: AppRadius.large,
              border: Border.all(color: AppColors.cardSurface(context), width: 1.2),
            ),
            alignment: Alignment.center,
            child: Text(
              badge,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
            ),
          ),
        ),
      ],
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
    final primary = AppColors.primaryColor(context);
    final selectedForeground = isDark ? const Color(0xFF050505) : AppColors.textStrong;
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
                  child: GNav(
                    selectedIndex: (selectedIndex.clamp(0, tabs.length - 1) as int),
                    onTabChange: onChanged,
                    gap: compact ? 5 : 7,
                    iconSize: compact ? 18 : 20,
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    backgroundColor: Colors.transparent,
                    color: AppColors.textSecondaryColor(context),
                    activeColor: selectedForeground,
                    textStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: selectedForeground,
                          fontWeight: FontWeight.w900,
                          fontSize: compact ? 11 : 12,
                          overflow: TextOverflow.ellipsis,
                        ),
                    tabBackgroundColor: primary.withValues(alpha: 0.96),
                    tabBorderRadius: compact ? 14 : 20,
                    padding: EdgeInsets.symmetric(
                      horizontal: compact ? 10 : 13,
                      vertical: compact ? 8 : 11,
                    ),
                    tabs: [
                      for (final tab in tabs)
                        GButton(
                          icon: tab.icon,
                          text: tab.badge == null ? tab.label : '${tab.label}  ${tab.badge}',
                          leading: tab.badge == null
                              ? null
                              : _TabBadgeIcon(icon: tab.icon, badge: tab.badge!),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _OptionalTabBlur extends StatelessWidget {
  const _OptionalTabBlur({required this.enabled, required this.child});

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
