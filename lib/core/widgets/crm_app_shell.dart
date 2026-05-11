import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_event.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import '../localization/locale_cubit.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import '../theme/theme_cubit.dart';
import '../../l10n/app_localizations.dart';
import '../routing/route_names.dart';
import 'responsive_layout.dart';

enum CrmNavigationItem { dashboard, leads, properties, clients, tasks, more }

class CrmAppShell extends StatelessWidget {
  const CrmAppShell({
    super.key,
    required this.selectedItem,
    required this.child,
    this.title,
    this.onItemSelected,
  });

  final CrmNavigationItem selectedItem;
  final Widget child;
  final String? title;
  final ValueChanged<CrmNavigationItem>? onItemSelected;

  static const _items = <_CrmShellItem>[
    _CrmShellItem(
      item: CrmNavigationItem.dashboard,
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
    ),
    _CrmShellItem(
      item: CrmNavigationItem.leads,
      icon: Icons.people_alt_outlined,
      selectedIcon: Icons.people_alt,
    ),
    _CrmShellItem(
      item: CrmNavigationItem.properties,
      icon: Icons.business_outlined,
      selectedIcon: Icons.business,
    ),
    _CrmShellItem(
      item: CrmNavigationItem.clients,
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
    ),
    _CrmShellItem(
      item: CrmNavigationItem.tasks,
      icon: Icons.checklist_outlined,
      selectedIcon: Icons.checklist,
    ),
  ];

  static const _mobileItems = <_CrmShellItem>[
    _CrmShellItem(
      item: CrmNavigationItem.dashboard,
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
    ),
    _CrmShellItem(
      item: CrmNavigationItem.leads,
      icon: Icons.people_alt_outlined,
      selectedIcon: Icons.people_alt,
    ),
    _CrmShellItem(
      item: CrmNavigationItem.properties,
      icon: Icons.business_outlined,
      selectedIcon: Icons.business,
    ),
    _CrmShellItem(
      item: CrmNavigationItem.clients,
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
    ),
    _CrmShellItem(
      item: CrmNavigationItem.more,
      icon: Icons.more_horiz,
      selectedIcon: Icons.more,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final effectiveOnItemSelected =
        onItemSelected ?? (item) => _goToItem(context, item);

    return _AuthLogoutListener(
      child: ResponsiveLayout(
        mobile: _MobileShell(
          selectedItem: selectedItem,
          title: title,
          items: _mobileItems,
          onItemSelected: effectiveOnItemSelected,
          child: child,
        ),
        tablet: _DesktopShell(
          selectedItem: selectedItem,
          title: title,
          items: _items,
          onItemSelected: effectiveOnItemSelected,
          child: child,
        ),
        desktop: _DesktopShell(
          selectedItem: selectedItem,
          title: title,
          items: _items,
          onItemSelected: effectiveOnItemSelected,
          child: child,
        ),
      ),
    );
  }
}

void _goToItem(BuildContext context, CrmNavigationItem item) {
  switch (item) {
    case CrmNavigationItem.dashboard:
      context.go(RouteNames.dashboard);
    case CrmNavigationItem.leads:
      context.go(RouteNames.leads);
    case CrmNavigationItem.properties:
      context.go(RouteNames.properties);
    case CrmNavigationItem.clients:
      context.go(RouteNames.clients);
    case CrmNavigationItem.tasks:
      context.go(RouteNames.tasks);
    case CrmNavigationItem.more:
      break;
  }
}

class _DesktopShell extends StatefulWidget {
  const _DesktopShell({
    required this.selectedItem,
    required this.items,
    required this.child,
    this.title,
    this.onItemSelected,
  });

  final CrmNavigationItem selectedItem;
  final List<_CrmShellItem> items;
  final Widget child;
  final String? title;
  final ValueChanged<CrmNavigationItem>? onItemSelected;

  @override
  State<_DesktopShell> createState() => _DesktopShellState();
}

class _DesktopShellState extends State<_DesktopShell> {
  bool _isSidebarCollapsed = false;

  @override
  Widget build(BuildContext context) {
    final colors = _CrmShellColors.of(context);

    return Scaffold(
      backgroundColor: colors.background,
      body: _WorkspaceBackground(
        intense: true,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              _Sidebar(
                selectedItem: widget.selectedItem,
                items: widget.items,
                isCollapsed: _isSidebarCollapsed,
                onToggleCollapsed: () {
                  setState(() => _isSidebarCollapsed = !_isSidebarCollapsed);
                },
                onItemSelected: widget.onItemSelected,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  children: [
                    _TopBar(
                      title: widget.title ??
                          _labelFor(context, widget.selectedItem),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        switchInCurve: Curves.easeOut,
                        switchOutCurve: Curves.easeIn,
                        transitionBuilder: (incoming, animation) {
                          final direction =
                              Directionality.of(context) == TextDirection.rtl
                                  ? -1.0
                                  : 1.0;
                          final offset = Tween<Offset>(
                            begin: Offset(0.018 * direction, 0),
                            end: Offset.zero,
                          ).animate(animation);
                          return FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: offset,
                              child: incoming,
                            ),
                          );
                        },
                        child: Padding(
                          key: ValueKey(widget.selectedItem),
                          padding: const EdgeInsetsDirectional.fromSTEB(
                            AppSpacing.sm,
                            0,
                            AppSpacing.sm,
                            AppSpacing.sm,
                          ),
                          child: widget.child,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WorkspaceBackground extends StatelessWidget {
  const _WorkspaceBackground({required this.child, this.intense = false});

  final Widget child;
  final bool intense;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = AppColors.appBackground(context);
    final primary = AppColors.primaryColor(context);
    final secondary = isDark ? AppColors.darkInfo : AppColors.secondary;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: base,
        gradient: RadialGradient(
          center: AlignmentDirectional.topEnd.resolve(Directionality.of(context)),
          radius: intense ? 1.2 : 0.75,
          colors: [
            primary.withValues(alpha: isDark ? 0.18 : 0.11),
            secondary.withValues(alpha: isDark ? 0.08 : 0.045),
            base,
          ],
          stops: const [0, 0.42, 1],
        ),
      ),
      child: CustomPaint(
        painter: _WorkspacePatternPainter(
          color: isDark
              ? Colors.white.withValues(alpha: intense ? 0.022 : 0.012)
              : AppColors.primaryDark.withValues(
                  alpha: intense ? 0.024 : 0.012,
                ),
          compact: !intense,
        ),
        child: child,
      ),
    );
  }
}

class _WorkspacePatternPainter extends CustomPainter {
  const _WorkspacePatternPainter({required this.color, required this.compact});

  final Color color;
  final bool compact;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    final step = compact ? 36.0 : 28.0;

    for (var x = 0.0; x < size.width; x += step) {
      for (var y = 0.0; y < size.height; y += step) {
        canvas.drawCircle(Offset(x, y), compact ? 0.7 : 0.9, paint);
      }
    }

    if (!compact) {
      final linePaint = Paint()
        ..color = color.withValues(alpha: 0.26)
        ..strokeWidth = 0.8;
      canvas.drawLine(
        Offset(size.width * 0.86, 0),
        Offset(size.width, size.height * 0.16),
        linePaint,
      );
      canvas.drawLine(
        Offset(size.width * 0.90, size.height),
        Offset(size.width, size.height * 0.84),
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WorkspacePatternPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.compact != compact;
  }
}

class _MobileShell extends StatelessWidget {
  const _MobileShell({
    required this.selectedItem,
    required this.items,
    required this.child,
    this.title,
    this.onItemSelected,
  });

  final CrmNavigationItem selectedItem;
  final List<_CrmShellItem> items;
  final Widget child;
  final String? title;
  final ValueChanged<CrmNavigationItem>? onItemSelected;

  @override
  Widget build(BuildContext context) {
    final colors = _CrmShellColors.of(context);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        surfaceTintColor: colors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        shadowColor: Colors.transparent,
        titleSpacing: 0,
        toolbarHeight: 76,
        automaticallyImplyLeading: false,
        title: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
            AppSpacing.md,
            AppSpacing.xs,
            AppSpacing.md,
            0,
          ),
          child: _MobileHeaderCard(
            title: title ?? _labelFor(context, selectedItem),
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        top: false,
        child: _WorkspaceBackground(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.lg,
            ),
            child: child,
          ),
        ),
      ),
      bottomNavigationBar: _MobileBottomNavigation(
        selectedItem: selectedItem,
        items: items,
        onItemSelected: (item) {
          if (item == CrmNavigationItem.more) {
            _showMobileMoreSheet(context);
            return;
          }
          onItemSelected?.call(item);
        },
      ),
    );
  }
}

class _MobileHeaderCard extends StatelessWidget {
  const _MobileHeaderCard({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = _CrmShellColors.of(context);

    return BlocBuilder<AuthBloc, AuthState>(
      buildWhen: (previous, current) =>
          previous.userProfile?.fullName != current.userProfile?.fullName ||
          previous.user?.fullName != current.user?.fullName,
      builder: (context, state) {
        final localizations = AppLocalizations.of(context)!;
        final fullName = _resolvedUserName(state, localizations.crmUser);

        return Material(
          color: colors.chromeSurface,
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(26),
          ),
          child: Container(
            height: 64,
            padding: const EdgeInsetsDirectional.fromSTEB(
              AppSpacing.md,
              AppSpacing.xs,
              AppSpacing.sm,
              AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: colors.border)),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(26),
              ),
            ),
            child: Row(
              children: [
                _UserAvatar(name: fullName),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        fullName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall?.copyWith(
                          color: colors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                const _NotificationIconButton(compact: true),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MobileBottomNavigation extends StatelessWidget {
  const _MobileBottomNavigation({
    required this.selectedItem,
    required this.items,
    required this.onItemSelected,
  });

  final CrmNavigationItem selectedItem;
  final List<_CrmShellItem> items;
  final ValueChanged<CrmNavigationItem> onItemSelected;

  @override
  Widget build(BuildContext context) {
    final colors = _CrmShellColors.of(context);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.xs,
          AppSpacing.md,
          AppSpacing.sm,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.chromeSurface,
            border: Border.all(color: colors.border),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              AppSpacing.sm,
              AppSpacing.xs,
              AppSpacing.sm,
              AppSpacing.xs,
            ),
            child: Row(
              children: [
                for (final item in items)
                  Expanded(
                    child: _MobileNavItemButton(
                      item: item,
                      selected: _isMobileItemSelected(item.item),
                      onTap: () => onItemSelected(item.item),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _isMobileItemSelected(CrmNavigationItem item) {
    if (item == selectedItem) {
      return true;
    }
    return item == CrmNavigationItem.more &&
        selectedItem == CrmNavigationItem.tasks;
  }
}

class _MobileNavItemButton extends StatelessWidget {
  const _MobileNavItemButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _CrmShellItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = _CrmShellColors.of(context);
    final color = selected ? colors.primary : colors.textSecondary;

    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: selected
                ? colors.selectedSurface
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: AnimatedScale(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            scale: selected ? 1.03 : 1,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  selected ? item.selectedIcon : item.icon,
                  size: 21,
                  color: color,
                ),
                const SizedBox(height: 3),
                Text(
                  item.label(context),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: textTheme.labelSmall?.copyWith(
                    color: color,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

void _showMobileMoreSheet(BuildContext context) {
  final authBloc = context.read<AuthBloc>();
  final localeCubit = context.read<LocaleCubit>();
  final themeCubit = context.read<ThemeCubit>();
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    isDismissible: true,
    enableDrag: true,
    useSafeArea: true,
    showDragHandle: false,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      final localizations = AppLocalizations.of(sheetContext)!;
      final maxHeight = MediaQuery.sizeOf(sheetContext).height * 0.85;

      return Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          constraints: BoxConstraints(maxHeight: maxHeight),
          decoration: BoxDecoration(
            color: _CrmShellColors.of(sheetContext).chromeSurface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(28),
            ),
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.md + MediaQuery.paddingOf(sheetContext).bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: _CrmShellColors.of(sheetContext).textSecondary,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                _MoreSheetTile(
                  icon: Icons.checklist_outlined,
                  label: localizations.tasks,
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    context.go(RouteNames.tasks);
                  },
                ),
                _MoreSheetTile(
                  icon: Icons.handshake_outlined,
                  label: localizations.deals,
                  onTap: () => Navigator.of(sheetContext).pop(),
                ),
                _MoreSheetTile(
                  icon: Icons.bar_chart_outlined,
                  label: localizations.reports,
                  onTap: () => Navigator.of(sheetContext).pop(),
                ),

                const Divider(height: AppSpacing.lg),
              _LanguageSheetActions(localeCubit: localeCubit),
                const SizedBox(height: AppSpacing.sm),
                _ThemeSheetAction(themeCubit: themeCubit),
                const Divider(height: AppSpacing.lg),
                _MoreSheetTile(
                  icon: Icons.logout,
                  label: localizations.logout,
                  isDestructive: true,
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    authBloc.add(const AuthSignOutRequested());
                  },
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _MoreSheetTile extends StatelessWidget {
  const _MoreSheetTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final colors = _CrmShellColors.of(context);
    final effectiveColor = isDestructive ? colors.error : colors.textPrimary;

    return ListTile(
      leading: Icon(icon, color: effectiveColor),
      title: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: effectiveColor, fontWeight: FontWeight.w600),
      ),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }
}

class _LanguageSheetActions extends StatelessWidget {
  const _LanguageSheetActions({required this.localeCubit});

  final LocaleCubit localeCubit;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return BlocBuilder<LocaleCubit, Locale?>(
      bloc: localeCubit,
      builder: (context, locale) {
        final selectedLanguage = locale?.languageCode ?? 'en';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                localizations.language,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: _CrmShellColors.of(context).textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Expanded(
                  child: _LanguageChoiceButton(
                    label: localizations.english,
                    selected: selectedLanguage == 'en',
                    onTap: () {
                      Navigator.of(context).pop();
                      localeCubit.setEnglish();
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _LanguageChoiceButton(
                    label: localizations.arabic,
                    selected: selectedLanguage == 'ar',
                    onTap: () {
                      Navigator.of(context).pop();
                      localeCubit.setArabic();
                    },
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
class _LanguageChoiceButton extends StatelessWidget {
  const _LanguageChoiceButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        backgroundColor: selected
            ? _CrmShellColors.of(context).selectedSurface
            : _CrmShellColors.of(context).cardSurface,
        foregroundColor: selected
            ? _CrmShellColors.of(context).primary
            : _CrmShellColors.of(context).textPrimary,
        side: BorderSide(
          color: selected
              ? _CrmShellColors.of(context).primary
              : _CrmShellColors.of(context).border,
        ),
      ),
      child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.selectedItem,
    required this.items,
    required this.isCollapsed,
    required this.onToggleCollapsed,
    this.onItemSelected,
  });

  final CrmNavigationItem selectedItem;
  final List<_CrmShellItem> items;
  final bool isCollapsed;
  final VoidCallback onToggleCollapsed;
  final ValueChanged<CrmNavigationItem>? onItemSelected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 190),
      curve: Curves.easeOutCubic,
      width: isCollapsed ? 76 : 262,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [_sidebarColor(context), _sidebarRaisedColor(context)],
        ),
        borderRadius: _sidebarRadius(context),
        boxShadow: AppShadows.shell,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Column(
                crossAxisAlignment: isCollapsed
                    ? CrossAxisAlignment.center
                    : CrossAxisAlignment.start,
                children: [
                  _BrandHeader(isCollapsed: isCollapsed),
                  const SizedBox(height: AppSpacing.lg),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          for (final item in items)
                            _SidebarItem(
                              item: item,
                              selected: item.item == selectedItem,
                              isCollapsed: isCollapsed,
                              onTap: () => onItemSelected?.call(item.item),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
              ),
            ),
          ),
          PositionedDirectional(
            top: 76,
            end: -15,
            child: _SidebarUtilities(
              isCollapsed: isCollapsed,
              onToggleCollapsed: onToggleCollapsed,
            ),
          ),
        ],
      ),
    );
  }

  BorderRadius _sidebarRadius(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    return BorderRadiusDirectional.only(
      topStart: const Radius.circular(30),
      bottomStart: const Radius.circular(30),
      topEnd: Radius.circular(isRtl ? 30 : 38),
      bottomEnd: Radius.circular(isRtl ? 30 : 38),
    ).resolve(Directionality.of(context));
  }

  Color _sidebarColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xFF0C1B2E) : const Color(0xFF245C98);
  }

  Color _sidebarRaisedColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xFF132B46) : const Color(0xFF1B4A7E);
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader({required this.isCollapsed});

  final bool isCollapsed;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final mark = Container(
      width: 42,
      height: 42,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: AppRadius.large,
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: const Icon(Icons.apartment, color: AppColors.shellText, size: 22),
    );

    if (isCollapsed) {
      return Tooltip(
        message: AppLocalizations.of(context)!.appName,
        child: mark,
      );
    }

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(2, 2, 2, AppSpacing.xs),
      child: Row(
        children: [
          mark,
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.appName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.shellText,
                  ),
                ),
                Text(
                  AppLocalizations.of(context)!.salesWorkspace,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.shellTextMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.item,
    required this.selected,
    required this.isCollapsed,
    required this.onTap,
  });

  final _CrmShellItem item;
  final bool selected;
  final bool isCollapsed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final color = selected ? Colors.white : AppColors.shellTextMuted;
    final label = item.label(context);

    final child = AnimatedContainer(
      duration: const Duration(milliseconds: 170),
      curve: Curves.easeOutCubic,
      width: double.infinity,
      padding: EdgeInsetsDirectional.fromSTEB(
        isCollapsed ? 0 : AppSpacing.sm,
        11,
        isCollapsed ? 0 : AppSpacing.sm,
        11,
      ),
      decoration: BoxDecoration(
        color: selected ? Colors.white.withValues(alpha: 0.16) : Colors.transparent,
        borderRadius: AppRadius.large,
        border: selected
            ? Border.all(color: Colors.white.withValues(alpha: 0.14))
            : null,
      ),
      child: Row(
        mainAxisAlignment:
            isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
        children: [
          Icon(
            selected ? item.selectedIcon : item.icon,
            color: color,
            size: 20,
          ),
          if (!isCollapsed) ...[
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodyMedium?.copyWith(
                  color: color,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Tooltip(
        message: isCollapsed ? label : '',
        child: Material(
          color: Colors.transparent,
          borderRadius: AppRadius.large,
          child: InkWell(
            onTap: onTap,
            borderRadius: AppRadius.large,
            child: child,
          ),
        ),
      ),
    );
  }
}

class _SidebarUtilities extends StatelessWidget {
  const _SidebarUtilities({
    required this.isCollapsed,
    required this.onToggleCollapsed,
  });

  final bool isCollapsed;
  final VoidCallback onToggleCollapsed;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final textDirection = Directionality.of(context);
    final collapseIcon = isCollapsed
        ? (textDirection == TextDirection.rtl
            ? Icons.keyboard_double_arrow_left
            : Icons.keyboard_double_arrow_right)
        : (textDirection == TextDirection.rtl
            ? Icons.keyboard_double_arrow_right
            : Icons.keyboard_double_arrow_left);

    return Align(
      alignment: AlignmentDirectional.center,
      child: _SidebarUtilityButton(
        icon: collapseIcon,
        label: localizations.more,
        isCollapsed: true,
        showLabel: false,
        onTap: onToggleCollapsed,
      ),
    );
  }
}

class _SidebarUtilityButton extends StatelessWidget {
  const _SidebarUtilityButton({
    required this.icon,
    required this.label,
    required this.isCollapsed,
    this.onTap,
    this.showLabel = true,
  });

  final IconData icon;
  final String label;
  final bool isCollapsed;
  final VoidCallback? onTap;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final colors = _CrmShellColors.of(context);
    final color = colors.primary;
    final compact = isCollapsed || !showLabel;
    final content = Container(
      width: compact ? 38 : double.infinity,
      height: compact ? 38 : null,
      padding: EdgeInsetsDirectional.fromSTEB(
        compact ? 0 : AppSpacing.sm,
        compact ? 0 : 10,
        compact ? 0 : AppSpacing.sm,
        compact ? 0 : 10,
      ),
      decoration: BoxDecoration(
        color: colors.cardSurface,
        borderRadius: compact ? AppRadius.medium : AppRadius.large,
        border: Border.all(color: colors.border),
        boxShadow: Theme.of(context).brightness == Brightness.dark
            ? null
            : AppShadows.card,
      ),
      child: Row(
        mainAxisAlignment:
            compact ? MainAxisAlignment.center : MainAxisAlignment.start,
        children: [
          Icon(icon, size: 19, color: color),
          if (!isCollapsed && showLabel) ...[
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );

    return Tooltip(
      message: isCollapsed || !showLabel ? label : '',
      child: Material(
        color: Colors.transparent,
        borderRadius: AppRadius.large,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.large,
          child: content,
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = _CrmShellColors.of(context);

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.chromeSurface.withValues(alpha: 0.94),
        border: Border.all(color: colors.border),
        borderRadius: AppRadius.xLarge,
        boxShadow: Theme.of(context).brightness == Brightness.dark
            ? null
            : AppShadows.card,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 620;

          return Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (!compact)
                Flexible(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context)!.searchCrm,
                      prefixIcon: const Icon(Icons.search),
                      isDense: true,
                    ),
                  ),
                ),
              const SizedBox(width: AppSpacing.sm),
              const _NotificationIconButton(),
              const SizedBox(width: AppSpacing.xs),
              const _LanguageMenuButton(),
              const _ThemeToggleButton(),
              //const _LogoutIconButton(),
              const SizedBox(width: AppSpacing.sm),
              const _ProfileMenuButton(),
            ],
          );
        },
      ),
    );
  }
}

class _ThemeSheetAction extends StatelessWidget {
  const _ThemeSheetAction({required this.themeCubit});

  final ThemeCubit themeCubit;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final colors = _CrmShellColors.of(context);

    return BlocBuilder<ThemeCubit, ThemeMode>(
      bloc: themeCubit,
      builder: (context, themeMode) {
        final isDark = themeMode == ThemeMode.dark;

        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(
            isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
            color: colors.textPrimary,
          ),
          title: Text(
            localizations.theme,
            style: TextStyle(
              color: colors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          subtitle: Text(
            isDark ? localizations.darkMode : localizations.lightMode,
            style: TextStyle(color: colors.textSecondary),
          ),
          trailing: Switch(
            value: isDark,
            activeThumbColor: colors.primary,
            activeTrackColor: colors.primary.withValues(alpha: 0.35),
            inactiveThumbColor: colors.textSecondary,
            inactiveTrackColor: colors.border,
            onChanged: (_) => themeCubit.toggle(),
          ),
          onTap: themeCubit.toggle,
        );
      },
    );
  }
}
class _ThemeToggleButton extends StatelessWidget {
  const _ThemeToggleButton();

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return BlocBuilder<ThemeCubit, ThemeMode>(
      builder: (context, themeMode) {
        final isDark = themeMode == ThemeMode.dark;

        return IconButton(
          tooltip: isDark ? localizations.lightMode : localizations.darkMode,
          onPressed: () => context.read<ThemeCubit>().toggle(),
          icon: Icon(
            isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
          ),
        );
      },
    );
  }
}

class _LogoutIconButton extends StatelessWidget {
  const _LogoutIconButton();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final isLoading = state.status == AuthStatus.loading;

        return IconButton(
          tooltip: AppLocalizations.of(context)!.logoutTooltip,
          onPressed: isLoading
              ? null
              : () {
                  context.read<AuthBloc>().add(const AuthSignOutRequested());
                },
          icon: isLoading
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.logout),
        );
      },
    );
  }
}

class _LanguageMenuButton extends StatelessWidget {
  const _LanguageMenuButton();

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return PopupMenuButton<String>(
      tooltip: localizations.language,
      icon: const Icon(Icons.language),
      onSelected: (languageCode) {
        final localeCubit = context.read<LocaleCubit>();
        if (languageCode == 'ar') {
          localeCubit.setArabic();
        } else {
          localeCubit.setEnglish();
        }
      },
      itemBuilder: (context) {
        return [
          PopupMenuItem<String>(
            value: 'en',
            child: Text(localizations.english),
          ),
          PopupMenuItem<String>(value: 'ar', child: Text(localizations.arabic)),
        ];
      },
    );
  }
}

class _AuthLogoutListener extends StatelessWidget {
  const _AuthLogoutListener({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (previous, current) {
        return previous.status != current.status &&
            current.status == AuthStatus.unauthenticated;
      },
      listener: (context, state) => context.go(RouteNames.login),
      child: child,
    );
  }
}

class _NotificationIconButton extends StatelessWidget {
  const _NotificationIconButton({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = _CrmShellColors.of(context);
    final button = IconButton(
      tooltip: AppLocalizations.of(context)!.notifications,
      onPressed: () {},
      icon: const Icon(Icons.notifications_none),
    );

    if (!compact) {
      return button;
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.inputSurface,
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: button,
    );
  }
}

enum _ProfileMenuAction { english, arabic, theme, logout }

class _ProfileMenuButton extends StatelessWidget {
  const _ProfileMenuButton();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final colors = _CrmShellColors.of(context);

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final userName = _resolvedUserName(authState, l.crmUser);
        final email = (authState.userProfile?.email ??
                authState.user?.email ??
                '')
            .trim();

        return BlocBuilder<ThemeCubit, ThemeMode>(
          builder: (context, themeMode) {
            final isDark = themeMode == ThemeMode.dark;

            return PopupMenuButton<_ProfileMenuAction>(
              tooltip: l.profile,
              position: PopupMenuPosition.under,
              offset: const Offset(0, AppSpacing.xs),
              color: colors.cardSurface,
              elevation: 10,
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: AppRadius.xLarge,
                side: BorderSide(color: colors.border),
              ),
              onSelected: (action) {
                switch (action) {
                  case _ProfileMenuAction.english:
                    context.read<LocaleCubit>().setEnglish();
                  case _ProfileMenuAction.arabic:
                    context.read<LocaleCubit>().setArabic();
                  case _ProfileMenuAction.theme:
                    context.read<ThemeCubit>().toggle();
                  case _ProfileMenuAction.logout:
                    context.read<AuthBloc>().add(const AuthSignOutRequested());
                }
              },
              itemBuilder: (menuContext) {
                return [
                  PopupMenuItem<_ProfileMenuAction>(
                    enabled: false,
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.md,
                      AppSpacing.md,
                      AppSpacing.sm,
                    ),
                    child: _ProfileMenuHeader(
                      name: userName,
                      subtitle: email,
                    ),
                  ),
                  const PopupMenuDivider(height: 1),
                  PopupMenuItem<_ProfileMenuAction>(
                    enabled: false,
                    child: _ProfileMenuTile(
                      icon: Icons.person_outline,
                      label: l.profile,
                      trailing: l.comingSoon,
                    ),
                  ),
                  PopupMenuItem<_ProfileMenuAction>(
                    enabled: false,
                    child: _ProfileMenuTile(
                      icon: Icons.settings_outlined,
                      label: l.settings,
                      trailing: l.comingSoon,
                    ),
                  ),
                  const PopupMenuDivider(height: 1),
                  PopupMenuItem<_ProfileMenuAction>(
                    value: _ProfileMenuAction.logout,
                    child: _ProfileMenuTile(
                      icon: Icons.logout,
                      label: l.logout,
                      destructive: true,
                    ),
                  ),
                ];
              },
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: colors.border),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: _UserAvatar(name: userName),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _ProfileMenuHeader extends StatelessWidget {
  const _ProfileMenuHeader({required this.name, required this.subtitle});

  final String name;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _UserAvatar(name: name),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              if (subtitle.isNotEmpty)
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondaryColor(context),
                      ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileMenuTile extends StatelessWidget {
  const _ProfileMenuTile({
    required this.icon,
    required this.label,
    this.trailing,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final String? trailing;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive
        ? AppColors.errorColor(context)
        : AppColors.textPrimaryColor(context);

    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: AppSpacing.sm),
          Text(
            trailing!,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textSecondaryColor(context),
                ),
          ),
        ],
      ],
    );
  }
}

class _UserAvatar extends StatelessWidget {
  const _UserAvatar({this.name});

  final String? name;

  @override
  Widget build(BuildContext context) {
    final initial = _initialFor(name ?? AppLocalizations.of(context)!.crmUser);

    return CircleAvatar(
      radius: 18,
      backgroundColor: AppColors.primary,
      child: Text(
        initial,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

String _initialFor(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return 'U';
  }
  return trimmed.substring(0, 1).toUpperCase();
}

String _resolvedUserName(AuthState state, String fallback) {
  final profileName = (state.userProfile?.fullName ?? '').trim();
  if (profileName.isNotEmpty) {
    return profileName;
  }

  final userName = (state.user?.fullName ?? '').trim();
  if (userName.isNotEmpty) {
    return userName;
  }

  return fallback;
}

class _CrmShellColors {
  const _CrmShellColors({
    required this.background,
    required this.chromeSurface,
    required this.cardSurface,
    required this.inputSurface,
    required this.selectedSurface,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.primary,
    required this.error,
  });

  final Color background;
  final Color chromeSurface;
  final Color cardSurface;
  final Color inputSurface;
  final Color selectedSurface;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color primary;
  final Color error;

  factory _CrmShellColors.of(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (!isDark) {
      return const _CrmShellColors(
        background: AppColors.background,
        chromeSurface: AppColors.surface,
        cardSurface: AppColors.surface,
        inputSurface: AppColors.surfaceMuted,
        selectedSurface: Color(0x174058E8),
        border: AppColors.border,
        textPrimary: AppColors.textPrimary,
        textSecondary: AppColors.textSecondary,
        primary: AppColors.primary,
        error: AppColors.error,
      );
    }

    return const _CrmShellColors(
      background: AppColors.darkBackground,
      chromeSurface: AppColors.darkSurface,
      cardSurface: AppColors.darkCardSurface,
      inputSurface: AppColors.darkSurfaceAlt,
      selectedSurface: AppColors.darkSelectedSurface,
      border: AppColors.darkBorder,
      textPrimary: AppColors.darkTextPrimary,
      textSecondary: AppColors.darkTextSecondary,
      primary: AppColors.darkPrimary,
      error: AppColors.darkError,
    );
  }
}

class _CrmShellItem {
  const _CrmShellItem({
    required this.item,
    required this.icon,
    required this.selectedIcon,
  });

  final CrmNavigationItem item;
  final IconData icon;
  final IconData selectedIcon;

  String label(BuildContext context) => _labelFor(context, item);
}

String _labelFor(BuildContext context, CrmNavigationItem item) {
  final localizations = AppLocalizations.of(context)!;

  switch (item) {
    case CrmNavigationItem.dashboard:
      return localizations.dashboard;
    case CrmNavigationItem.leads:
      return localizations.leads;
    case CrmNavigationItem.properties:
      return localizations.properties;
    case CrmNavigationItem.clients:
      return localizations.clients;
    case CrmNavigationItem.tasks:
      return localizations.tasks;
    case CrmNavigationItem.more:
      return localizations.more;
  }
}
