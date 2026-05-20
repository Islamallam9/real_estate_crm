import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_event.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import '../../features/global_search/data/datasources/global_search_remote_data_source.dart';
import '../../features/global_search/data/repositories/global_search_repository_impl.dart';
import '../../features/global_search/domain/entities/global_search_result.dart';
import '../../features/global_search/domain/usecases/search_global_data_usecase.dart';
import '../../features/global_search/presentation/cubit/global_search_cubit.dart';
import '../../features/global_search/presentation/cubit/global_search_state.dart';
import '../../features/notifications/presentation/cubit/notifications_cubit.dart';
import '../../features/notifications/presentation/widgets/notification_bell_button.dart';
import '../../features/notifications/presentation/widgets/notifications_scope.dart';
import '../../features/users/domain/entities/company_metadata.dart';
import '../constants/role_constants.dart';
import '../localization/locale_cubit.dart';
import '../permissions/company_feature_gate.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import '../theme/theme_cubit.dart';
import '../../l10n/app_localizations.dart';
import '../routing/route_names.dart';
import 'app_feedback.dart';
import 'masar_brand.dart';
import 'responsive_layout.dart';

enum CrmNavigationItem {
  dashboard,
  leads,
  properties,
  clients,
  tasks,
  appointments,
  deals,
  reports,
  users,
  teams,
  dataHealth,
  support,
  more,
}

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
    _CrmShellItem(
      item: CrmNavigationItem.appointments,
      icon: Icons.event_note_outlined,
      selectedIcon: Icons.event_note,
    ),
    _CrmShellItem(
      item: CrmNavigationItem.deals,
      icon: Icons.handshake_outlined,
      selectedIcon: Icons.handshake,
    ),
    _CrmShellItem(
      item: CrmNavigationItem.reports,
      icon: Icons.bar_chart_outlined,
      selectedIcon: Icons.bar_chart,
    ),
    _CrmShellItem(
      item: CrmNavigationItem.users,
      icon: Icons.manage_accounts_outlined,
      selectedIcon: Icons.manage_accounts,
    ),
    _CrmShellItem(
      item: CrmNavigationItem.teams,
      icon: Icons.groups_outlined,
      selectedIcon: Icons.groups,
    ),
    _CrmShellItem(
      item: CrmNavigationItem.dataHealth,
      icon: Icons.health_and_safety_outlined,
      selectedIcon: Icons.health_and_safety,
    ),
    _CrmShellItem(
      item: CrmNavigationItem.support,
      icon: Icons.support_agent_outlined,
      selectedIcon: Icons.support_agent,
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
    final companyMetadata = context.select(
      (AuthBloc bloc) => bloc.state.companyMetadata,
    );
    final authState = context.watch<AuthBloc>().state;
    final desktopItems = _visibleItemsForRole(_items, authState.userProfile?.role);
    final mobileItems = _mobileItems;
    final effectiveOnItemSelected =
        onItemSelected ?? (item) => _goToItem(context, item);

    return _AuthLogoutListener(
      child: _CrmNotificationsScope(
        authState: authState,
        child: ResponsiveLayout(
          mobile: _MobileShell(
            selectedItem: selectedItem,
            title: title,
            items: mobileItems,
            companyMetadata: companyMetadata,
            onItemSelected: effectiveOnItemSelected,
            child: child,
          ),
          tablet: _DesktopShell(
            selectedItem: selectedItem,
            title: title,
            items: desktopItems,
            onItemSelected: effectiveOnItemSelected,
            child: child,
          ),
          desktop: _DesktopShell(
            selectedItem: selectedItem,
            title: title,
            items: desktopItems,
            onItemSelected: effectiveOnItemSelected,
            child: child,
          ),
        ),
      ),
    );
  }
}

class _CrmNotificationsScope extends StatelessWidget {
  const _CrmNotificationsScope({
    required this.authState,
    required this.child,
  });

  final AuthState authState;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final profile = authState.userProfile;
    final authUid = authState.user?.uid ?? '';
    if (profile == null ||
        authUid.isEmpty ||
        !authState.companyMetadata.isFeatureEnabled(CompanyFeature.notifications)) {
      return child;
    }

    return NotificationsScope(
      child: _CrmNotificationsStarter(
        companyId: profile.companyId,
        currentUserId: authUid,
        role: profile.role,
        managerTeamId: profile.teamId,
        child: child,
      ),
    );
  }
}

class _CrmNotificationsStarter extends StatefulWidget {
  const _CrmNotificationsStarter({
    required this.companyId,
    required this.currentUserId,
    required this.role,
    required this.managerTeamId,
    required this.child,
  });

  final String companyId;
  final String currentUserId;
  final UserRole role;
  final String managerTeamId;
  final Widget child;

  @override
  State<_CrmNotificationsStarter> createState() =>
      _CrmNotificationsStarterState();
}

class _CrmNotificationsStarterState extends State<_CrmNotificationsStarter> {
  @override
  void initState() {
    super.initState();
    _watchNotifications();
  }

  @override
  void didUpdateWidget(covariant _CrmNotificationsStarter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.companyId != widget.companyId ||
        oldWidget.currentUserId != widget.currentUserId ||
        oldWidget.role != widget.role ||
        oldWidget.managerTeamId != widget.managerTeamId) {
      _watchNotifications();
    }
  }

  void _watchNotifications() {
    context.read<NotificationsCubit>().watch(
          companyId: widget.companyId,
          currentUserId: widget.currentUserId,
          role: widget.role,
          managerTeamId: widget.managerTeamId,
        );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}


bool _isNavigationItemEnabled(
  CompanyMetadata? companyMetadata,
  CrmNavigationItem item,
) {
  final feature = _featureForNavigationItem(item);
  if (feature == null) {
    return true;
  }
  return companyMetadata.isFeatureEnabled(feature);
}

CompanyFeature? _featureForNavigationItem(CrmNavigationItem item) {
  return switch (item) {
    CrmNavigationItem.dashboard => null,
    CrmNavigationItem.leads => CompanyFeature.leads,
    CrmNavigationItem.properties => CompanyFeature.properties,
    CrmNavigationItem.clients => CompanyFeature.clients,
    CrmNavigationItem.tasks => CompanyFeature.tasks,
    CrmNavigationItem.appointments => CompanyFeature.appointments,
    CrmNavigationItem.deals => CompanyFeature.deals,
    CrmNavigationItem.reports => CompanyFeature.reports,
    CrmNavigationItem.users => null,
    CrmNavigationItem.teams => null,
    CrmNavigationItem.dataHealth => null,
    CrmNavigationItem.support => null,
    CrmNavigationItem.more => null,
  };
}

void _goToItem(BuildContext context, CrmNavigationItem item) {
  final authState = context.read<AuthBloc>().state;
  if (!_isNavigationItemEnabled(authState.companyMetadata, item)) {
    AppFeedback.error(
      context,
      AppLocalizations.of(context)!.featureNotEnabledForWorkspace,
    );
    return;
  }

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
    case CrmNavigationItem.appointments:
      context.go(RouteNames.appointments);
    case CrmNavigationItem.deals:
      context.go(RouteNames.deals);
    case CrmNavigationItem.reports:
      context.go(RouteNames.reports);
    case CrmNavigationItem.users:
      context.go(RouteNames.users);
    case CrmNavigationItem.teams:
      context.go(RouteNames.teams);
    case CrmNavigationItem.dataHealth:
      context.go(RouteNames.dataHealth);
    case CrmNavigationItem.support:
      context.go(RouteNames.support);
    case CrmNavigationItem.more:
      break;
  }
}

List<_CrmShellItem> _visibleItemsForRole(
  List<_CrmShellItem> items,
  UserRole? role,
) {
  return items.where((item) {
    if (item.item == CrmNavigationItem.users) {
      return role == UserRole.admin;
    }
    if (item.item == CrmNavigationItem.teams) {
      return role == UserRole.admin || role == UserRole.manager;
    }
    if (item.item == CrmNavigationItem.dataHealth) {
      return role == UserRole.admin;
    }
    if (item.item == CrmNavigationItem.appointments) {
      return role != UserRole.viewer;
    }
    return true;
  }).toList();
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
    final warmTint = isDark ? AppColors.darkShellRaised : AppColors.backgroundSoft;
    final highlight = isDark ? AppColors.darkPrimary : AppColors.backgroundHighlight;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: base,
        gradient: RadialGradient(
          center: AlignmentDirectional.topEnd.resolve(Directionality.of(context)),
          radius: intense ? 1.2 : 0.75,
          colors: [
            highlight.withValues(alpha: isDark ? 0.12 : 0.88),
            warmTint.withValues(alpha: isDark ? 0.16 : 0.62),
            base,
          ],
          stops: const [0, 0.42, 1],
        ),
      ),
      child: CustomPaint(
        painter: _WorkspacePatternPainter(
          color: isDark
              ? AppColors.darkTextPrimary.withValues(
                  alpha: intense ? 0.022 : 0.012,
                )
              : AppColors.shellBorder.withValues(
                  alpha: intense ? 0.22 : 0.12,
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

class _MobileShell extends StatefulWidget {
  const _MobileShell({
    required this.selectedItem,
    required this.items,
    required this.companyMetadata,
    required this.child,
    this.title,
    this.onItemSelected,
  });

  final CrmNavigationItem selectedItem;
  final List<_CrmShellItem> items;
  final CompanyMetadata? companyMetadata;
  final Widget child;
  final String? title;
  final ValueChanged<CrmNavigationItem>? onItemSelected;

  @override
  State<_MobileShell> createState() => _MobileShellState();
}

class _MobileShellState extends State<_MobileShell> {
  static const _scrollThreshold = 18.0;

  bool _showBottomNavigation = true;
  bool _modalOpen = false;
  double _scrollDelta = 0;

  Future<void> _openMoreSheet() async {
    setState(() {
      _modalOpen = true;
      _showBottomNavigation = true;
    });
    await _showMobileMoreSheet(context);
    if (mounted) {
      setState(() => _modalOpen = false);
    }
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification.metrics.axis != Axis.vertical || _modalOpen) {
      return false;
    }

    if (FocusManager.instance.primaryFocus != null ||
        MediaQuery.viewInsetsOf(context).bottom > 0) {
      _showNavigationIfNeeded();
      return false;
    }

    if (notification.metrics.pixels <= notification.metrics.minScrollExtent + 8) {
      _scrollDelta = 0;
      _showNavigationIfNeeded();
      return false;
    }

    if (notification is ScrollUpdateNotification) {
      final delta = notification.scrollDelta ?? 0;
      if (delta == 0) {
        return false;
      }
      if ((_scrollDelta > 0 && delta < 0) || (_scrollDelta < 0 && delta > 0)) {
        _scrollDelta = 0;
      }
      _scrollDelta += delta;

      if (_scrollDelta > _scrollThreshold && _showBottomNavigation) {
        setState(() => _showBottomNavigation = false);
        _scrollDelta = 0;
      } else if (_scrollDelta < -_scrollThreshold && !_showBottomNavigation) {
        setState(() => _showBottomNavigation = true);
        _scrollDelta = 0;
      }
    }

    return false;
  }

  void _showNavigationIfNeeded() {
    if (!_showBottomNavigation) {
      setState(() => _showBottomNavigation = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = _CrmShellColors.of(context);
    final effectiveShowBottomNavigation =
        _showBottomNavigation || MediaQuery.viewInsetsOf(context).bottom > 0;

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
            title: widget.title ?? _labelFor(context, widget.selectedItem),
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        top: false,
        child: _WorkspaceBackground(
          child: NotificationListener<ScrollNotification>(
            onNotification: _handleScrollNotification,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                AppSpacing.lg,
              ),
              child: widget.child,
            ),
          ),
        ),
      ),
      bottomNavigationBar: AnimatedSlide(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        offset: effectiveShowBottomNavigation ? Offset.zero : const Offset(0, 1),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 160),
          opacity: effectiveShowBottomNavigation ? 1 : 0,
          child: IgnorePointer(
            ignoring: !effectiveShowBottomNavigation,
            child: _MobileBottomNavigation(
              selectedItem: widget.selectedItem,
              items: widget.items,
              companyMetadata: widget.companyMetadata,
              onItemSelected: (item) {
                if (item == CrmNavigationItem.more) {
                  _openMoreSheet();
                  return;
                }
                widget.onItemSelected?.call(item);
              },
            ),
          ),
        ),
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
          previous.user?.fullName != current.user?.fullName ||
          previous.userProfile?.photoUrl != current.userProfile?.photoUrl ||
          previous.user?.photoUrl != current.user?.photoUrl,
      builder: (context, state) {
        final localizations = AppLocalizations.of(context)!;
        final fullName = _resolvedUserName(state, localizations.crmUser);
        final photoUrl = _resolvedUserPhotoUrl(state);
        _debugProfileImageSources(state, 'mobile shell avatar');

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
                Tooltip(
                  message: localizations.profile,
                  child: const _ProfileMenuButton(compact: true),
                ),
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
                const _MobileSearchIconButton(),
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
    required this.companyMetadata,
    required this.onItemSelected,
  });

  final CrmNavigationItem selectedItem;
  final List<_CrmShellItem> items;
  final CompanyMetadata? companyMetadata;
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
                      enabled: _isNavigationItemEnabled(
                        companyMetadata,
                        item.item,
                      ),
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
        (selectedItem == CrmNavigationItem.tasks ||
            selectedItem == CrmNavigationItem.appointments ||
            selectedItem == CrmNavigationItem.deals ||
            selectedItem == CrmNavigationItem.reports ||
            selectedItem == CrmNavigationItem.users ||
            selectedItem == CrmNavigationItem.teams ||
            selectedItem == CrmNavigationItem.dataHealth ||
            selectedItem == CrmNavigationItem.support);
  }
}

class _MobileNavItemButton extends StatelessWidget {
  const _MobileNavItemButton({
    required this.item,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final _CrmShellItem item;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = _CrmShellColors.of(context);
    final color = !enabled
        ? colors.textSecondary.withValues(alpha: 0.45)
        : selected
            ? colors.primary
            : colors.textSecondary;

    return Semantics(
      button: true,
      selected: selected,
      enabled: enabled,
      child: InkWell(
        onTap: enabled ? onTap : null,
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
                  enabled
                      ? (selected ? item.selectedIcon : item.icon)
                      : Icons.lock_outline,
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

Future<void> _showMobileMoreSheet(BuildContext context) {
  final authState = context.read<AuthBloc>().state;
  final companyMetadata = authState.companyMetadata;
  final role = authState.userProfile?.role;
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    isDismissible: true,
    enableDrag: true,
    useSafeArea: true,
    showDragHandle: false,
    barrierColor: Colors.black.withValues(alpha: 0.18),
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
                  enabled: companyMetadata.isFeatureEnabled(CompanyFeature.tasks),
                  disabledSubtitle: localizations.moduleDisabled,
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    context.go(RouteNames.tasks);
                  },
                ),
                if (role != UserRole.viewer)
                  _MoreSheetTile(
                    icon: Icons.event_note_outlined,
                    label: localizations.appointments,
                    enabled: companyMetadata.isFeatureEnabled(
                      CompanyFeature.appointments,
                    ),
                    disabledSubtitle: localizations.moduleDisabled,
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      context.go(RouteNames.appointments);
                    },
                  ),
                _MoreSheetTile(
                  icon: Icons.handshake_outlined,
                  label: localizations.deals,
                  enabled: companyMetadata.isFeatureEnabled(CompanyFeature.deals),
                  disabledSubtitle: localizations.moduleDisabled,
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    context.go(RouteNames.deals);
                  },
                ),
                _MoreSheetTile(
                  icon: Icons.bar_chart_outlined,
                  label: localizations.reports,
                  enabled: companyMetadata.isFeatureEnabled(CompanyFeature.reports),
                  disabledSubtitle: localizations.moduleDisabled,
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    context.go(RouteNames.reports);
                  },
                ),
                if (role == UserRole.admin)
                  _MoreSheetTile(
                    icon: Icons.manage_accounts_outlined,
                    label: localizations.userManagement,
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      context.go(RouteNames.users);
                    },
                  ),
                if (role == UserRole.admin || role == UserRole.manager)
                  _MoreSheetTile(
                    icon: Icons.groups_outlined,
                    label: localizations.teamManagement,
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      context.go(RouteNames.teams);
                    },
                  ),
                if (role == UserRole.admin)
                  _MoreSheetTile(
                    icon: Icons.health_and_safety_outlined,
                    label: localizations.dataHealth,
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      context.go(RouteNames.dataHealth);
                    },
                  ),
                _MoreSheetTile(
                  icon: Icons.support_agent_outlined,
                  label: localizations.supportCenter,
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    context.go(RouteNames.support);
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
    this.subtitle,
    this.disabledSubtitle,
    this.enabled = true,
    this.isDestructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String? subtitle;
  final String? disabledSubtitle;
  final bool enabled;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final colors = _CrmShellColors.of(context);
    final effectiveColor = !enabled
        ? colors.textSecondary.withValues(alpha: 0.55)
        : isDestructive
            ? colors.error
            : colors.textPrimary;
    final effectiveSubtitle = enabled ? subtitle : disabledSubtitle ?? subtitle;

    return ListTile(
      enabled: enabled,
      leading: Icon(enabled ? icon : Icons.lock_outline, color: effectiveColor),
      title: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: effectiveColor, fontWeight: FontWeight.w600),
      ),
      subtitle: effectiveSubtitle == null
          ? null
          : Text(
              effectiveSubtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: colors.textSecondary),
            ),
      onTap: enabled ? onTap : null,
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
                              enabled: _isNavigationItemEnabled(
                                context.select(
                                  (AuthBloc bloc) => bloc.state.companyMetadata,
                                ),
                                item.item,
                              ),
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
    return isDark ? AppColors.darkShell : AppColors.shell;
  }

  Color _sidebarRaisedColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? AppColors.darkShellRaised : AppColors.shellRaised;
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader({required this.isCollapsed});

  final bool isCollapsed;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final brandTextColor = isDark ? AppColors.darkTextPrimary : AppColors.shellText;
    final brandMutedColor =
    isDark ? AppColors.darkTextSecondary : AppColors.shellTextMuted;

    final mark = Container(
      width: 42,
      height: 42,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkShellRaised : AppColors.primaryLight,
        borderRadius: AppRadius.large,
        border: Border.all(
          color: isDark
              ? AppColors.darkBorder
              : AppColors.primaryBorder.withValues(alpha: 0.7),
        ),
      ),
      child: const MasarBrandMark(size: 30),
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
                      color: brandTextColor,
                  ),
                ),
                Text(
                  AppLocalizations.of(context)!.salesWorkspace,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall?.copyWith(
                      color: brandMutedColor,
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
    required this.enabled,
    required this.isCollapsed,
    required this.onTap,
  });

  final _CrmShellItem item;
  final bool selected;
  final bool enabled;
  final bool isCollapsed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedTextColor = isDark ? AppColors.shellText : AppColors.shellText;
    final inactiveTextColor =
    isDark ? AppColors.darkTextSecondary : AppColors.shellTextMuted;
    final color = !enabled
        ? inactiveTextColor.withValues(alpha: 0.48)
        : selected
            ? selectedTextColor
            : inactiveTextColor;
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
        color: selected
            ? (isDark ? AppColors.darkPrimary : AppColors.shellActive)
            : Colors.transparent,
        borderRadius: AppRadius.large,
        border: selected
            ? Border.all(
          color: isDark
              ? AppColors.darkPrimaryHover.withValues(alpha: 0.28)
              : AppColors.primaryPressed.withValues(alpha: 0.18),
        )
            : null,
      ),
      child: Row(
        mainAxisAlignment:
            isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
        children: [
          Icon(
            enabled ? (selected ? item.selectedIcon : item.icon) : Icons.lock_outline,
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
            if (!enabled)
              Icon(
                Icons.lock_outline,
                size: 14,
                color: color,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark ? AppColors.darkPrimary : AppColors.primaryDeep;
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
        color: isDark ? AppColors.darkShellRaised : AppColors.shellRaised,
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.shellBorder,
        ),
        borderRadius: compact ? AppRadius.medium : AppRadius.large,
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
                    readOnly: true,
                    textInputAction: TextInputAction.search,
                    onTap: () => _showGlobalSearchDialog(context),
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
            (current.status == AuthStatus.unauthenticated ||
                (current.status == AuthStatus.failure &&
                    previous.status == AuthStatus.loading &&
                    previous.user != null &&
                    current.user != null));
      },
      listener: (context, state) {
        final localizations = AppLocalizations.of(context)!;
        if (state.status == AuthStatus.unauthenticated) {
          AppFeedback.success(context, localizations.loggedOutSuccessfully);
          context.go(RouteNames.login);
          return;
        }
        if (state.status == AuthStatus.failure) {
          AppFeedback.error(context, localizations.authErrorSignOutFailed);
        }
      },
      child: child,
    );
  }
}


class _MobileSearchIconButton extends StatelessWidget {
  const _MobileSearchIconButton();

  @override
  Widget build(BuildContext context) {
    final colors = _CrmShellColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.inputSurface,
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        tooltip: AppLocalizations.of(context)!.searchCrm,
        onPressed: () => _showGlobalSearchDialog(context),
        icon: const Icon(Icons.search),
      ),
    );
  }
}

Future<void> _showGlobalSearchDialog(
  BuildContext context, {
  String initialQuery = '',
}) {
  final authState = context.read<AuthBloc>().state;
  final profile = authState.userProfile;
  final user = authState.user;
  if (profile == null || user == null) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final l = AppLocalizations.of(dialogContext)!;
        return AlertDialog(
          title: Text(l.searchCrm),
          content: Text(l.missingCompanyProfile),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(l.close),
            ),
          ],
        );
      },
    );
  }

  final repository = GlobalSearchRepositoryImpl(
    remoteDataSource: FirestoreGlobalSearchRemoteDataSource(),
  );

  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      final l = AppLocalizations.of(dialogContext)!;
      return BlocProvider(
        create: (_) => GlobalSearchCubit(
          searchGlobalDataUseCase: SearchGlobalDataUseCase(repository),
          companyId: profile.companyId,
          currentUserId: user.uid,
          role: profile.role,
          includeUsers: profile.role == UserRole.admin ||
              profile.role == UserRole.manager,
          enabledModules: _enabledSearchModules(authState),
        )..queryChanged(initialQuery),
        child: AlertDialog(
          title: Text(l.searchCrm),
          content: _GlobalSearchDialogContent(
            initialQuery: initialQuery,
            onSelected: (result) {
              Navigator.of(dialogContext).pop();
              context.go(result.route);
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(l.close),
            ),
          ],
        ),
      );
    },
  );
}

class _GlobalSearchDialogContent extends StatefulWidget {
  const _GlobalSearchDialogContent({
    required this.initialQuery,
    required this.onSelected,
  });

  final String initialQuery;
  final ValueChanged<GlobalSearchResult> onSelected;

  @override
  State<_GlobalSearchDialogContent> createState() =>
      _GlobalSearchDialogContentState();
}

class _GlobalSearchDialogContentState extends State<_GlobalSearchDialogContent> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery);
    if (widget.initialQuery.trim().isNotEmpty) {
      context.read<GlobalSearchCubit>().queryChanged(widget.initialQuery);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return SizedBox(
      width: 520,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: l.searchCrm,
              prefixIcon: const Icon(Icons.search),
            ),
            onChanged: context.read<GlobalSearchCubit>().queryChanged,
          ),
          const SizedBox(height: AppSpacing.md),
          BlocBuilder<GlobalSearchCubit, GlobalSearchState>(
            builder: (context, state) {
              if (state.query.length < 2) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  child: Text(
                    l.searchCrm,
                    style: TextStyle(
                      color: AppColors.textSecondaryColor(context),
                    ),
                  ),
                );
              }

              if (state.status == GlobalSearchStatus.loading) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (state.status == GlobalSearchStatus.failure) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  child: Text(
                    l.unableToConnect,
                    style: TextStyle(color: AppColors.errorColor(context)),
                  ),
                );
              }

              if (state.results.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  child: Text(
                    l.noCompaniesFoundMessage,
                    style: TextStyle(
                      color: AppColors.textSecondaryColor(context),
                    ),
                  ),
                );
              }

              final grouped = _groupSearchResults(state.results);
              return ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 360),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: grouped.length,
                  itemBuilder: (context, index) {
                    final entry = grouped[index];
                    return _GlobalSearchGroup(
                      module: entry.key,
                      results: entry.value,
                      onSelected: widget.onSelected,
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

List<MapEntry<GlobalSearchModule, List<GlobalSearchResult>>> _groupSearchResults(
  List<GlobalSearchResult> results,
) {
  final grouped = <GlobalSearchModule, List<GlobalSearchResult>>{};
  for (final result in results) {
    grouped.putIfAbsent(result.module, () => []).add(result);
  }
  return grouped.entries.toList();
}

Set<GlobalSearchModule> _enabledSearchModules(AuthState authState) {
  final metadata = authState.companyMetadata;
  final role = authState.userProfile?.role;
  return {
    if (metadata.isFeatureEnabled(CompanyFeature.leads))
      GlobalSearchModule.leads,
    if (metadata.isFeatureEnabled(CompanyFeature.clients))
      GlobalSearchModule.clients,
    if (metadata.isFeatureEnabled(CompanyFeature.properties))
      GlobalSearchModule.properties,
    if (metadata.isFeatureEnabled(CompanyFeature.deals))
      GlobalSearchModule.deals,
    if (metadata.isFeatureEnabled(CompanyFeature.tasks))
      GlobalSearchModule.tasks,
    if (role == UserRole.admin || role == UserRole.manager)
      GlobalSearchModule.users,
  };
}

class _GlobalSearchGroup extends StatelessWidget {
  const _GlobalSearchGroup({
    required this.module,
    required this.results,
    required this.onSelected,
  });

  final GlobalSearchModule module;
  final List<GlobalSearchResult> results;
  final ValueChanged<GlobalSearchResult> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = _CrmShellColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.xs),
            child: Text(
              _searchModuleLabel(context, module),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
          for (final result in results)
            Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: AppSpacing.xs),
              color: colors.inputSurface,
              shape: RoundedRectangleBorder(
                borderRadius: AppRadius.large,
                side: BorderSide(color: colors.border),
              ),
              child: ListTile(
                leading: Icon(_searchModuleIcon(module), color: colors.primary),
                title: Text(
                  result.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text(
                  _searchSubtitle(result),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: result.status.trim().isEmpty
                    ? null
                    : Text(
                        result.status,
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                onTap: () => onSelected(result),
              ),
            ),
        ],
      ),
    );
  }
}

String _searchSubtitle(GlobalSearchResult result) {
  final parts = [
    result.subtitle,
    result.owner,
  ].where((part) => part.trim().isNotEmpty).toList();
  return parts.isEmpty ? result.route : parts.join(' - ');
}

String _searchModuleLabel(BuildContext context, GlobalSearchModule module) {
  final l = AppLocalizations.of(context)!;
  return switch (module) {
    GlobalSearchModule.leads => l.leads,
    GlobalSearchModule.clients => l.clients,
    GlobalSearchModule.properties => l.properties,
    GlobalSearchModule.deals => l.deals,
    GlobalSearchModule.tasks => l.tasks,
    GlobalSearchModule.users => l.teamMembers,
  };
}

IconData _searchModuleIcon(GlobalSearchModule module) {
  return switch (module) {
    GlobalSearchModule.leads => Icons.people_alt_outlined,
    GlobalSearchModule.clients => Icons.person_outline,
    GlobalSearchModule.properties => Icons.business_outlined,
    GlobalSearchModule.deals => Icons.handshake_outlined,
    GlobalSearchModule.tasks => Icons.checklist_outlined,
    GlobalSearchModule.users => Icons.badge_outlined,
  };
}

class _NotificationIconButton extends StatelessWidget {
  const _NotificationIconButton({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    if (!authState.companyMetadata.isFeatureEnabled(CompanyFeature.notifications)) {
      return const SizedBox.shrink();
    }
    return NotificationBellButton(compact: compact);
  }
}

enum _ProfileMenuAction { profile, settings, logout }

class _ProfileMenuButton extends StatelessWidget {
  const _ProfileMenuButton({this.compact = false});

  final bool compact;

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
        final photoUrl = _resolvedUserPhotoUrl(authState);
        _debugProfileImageSources(authState, 'account menu avatar');

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
              case _ProfileMenuAction.profile:
                context.go(RouteNames.profile);
              case _ProfileMenuAction.settings:
                context.go(RouteNames.settings);
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
                  photoUrl: photoUrl,
                ),
              ),
              const PopupMenuDivider(height: 1),
              PopupMenuItem<_ProfileMenuAction>(
                value: _ProfileMenuAction.profile,
                child: _ProfileMenuTile(
                  icon: Icons.person_outline,
                  label: l.profile,
                ),
              ),
              PopupMenuItem<_ProfileMenuAction>(
                value: _ProfileMenuAction.settings,
                child: _ProfileMenuTile(
                  icon: Icons.settings_outlined,
                  label: l.settings,
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
              padding: EdgeInsets.all(compact ? 0 : 2),
              child: _UserAvatar(name: userName, photoUrl: photoUrl),
            ),
          ),
        );
      },
    );
  }
}

class _ProfileMenuHeader extends StatelessWidget {
  const _ProfileMenuHeader({
    required this.name,
    required this.subtitle,
    required this.photoUrl,
  });

  final String name;
  final String subtitle;
  final String photoUrl;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _UserAvatar(name: name, photoUrl: photoUrl),
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
  const _UserAvatar({this.name, this.photoUrl});

  final String? name;
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    final cleanPhotoUrl = (photoUrl ?? '').trim();
    final initial = _initialFor(name ?? AppLocalizations.of(context)!.crmUser);
    final fallback = _UserInitialAvatar(initial: initial);

    if (cleanPhotoUrl.isEmpty) {
      return fallback;
    }

    return ClipOval(
      child: SizedBox(
        width: 36,
        height: 36,
        child: Image.network(
          cleanPhotoUrl,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
          errorBuilder: (_, __, ___) => fallback,
        ),
      ),
    );
  }
}

class _UserInitialAvatar extends StatelessWidget {
  const _UserInitialAvatar({required this.initial});

  final String initial;

  @override
  Widget build(BuildContext context) {
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

String _resolvedUserPhotoUrl(AuthState state) {
  final profilePhoto = (state.userProfile?.photoUrl ?? '').trim();
  if (profilePhoto.isNotEmpty) {
    return profilePhoto;
  }
  return (state.user?.photoUrl ?? '').trim();
}

void _debugProfileImageSources(AuthState state, String source) {
  // Intentionally silent. Avoid noisy profile image logs and URL/token output.
  return;
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
        chromeSurface: AppColors.backgroundSoft,
        cardSurface: AppColors.surface,
        inputSurface: AppColors.backgroundHighlight,
        selectedSurface: AppColors.primaryLight,
        border: AppColors.border,
        textPrimary: AppColors.textPrimary,
        textSecondary: AppColors.textSecondary,
        primary: AppColors.primaryDeep,
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
    case CrmNavigationItem.appointments:
      return localizations.appointments;
    case CrmNavigationItem.deals:
      return localizations.deals;
    case CrmNavigationItem.reports:
      return localizations.reports;
    case CrmNavigationItem.users:
      return localizations.userManagement;
    case CrmNavigationItem.teams:
      return localizations.teamManagement;
    case CrmNavigationItem.dataHealth:
      return localizations.dataHealth;
    case CrmNavigationItem.support:
      return localizations.supportCenter;
    case CrmNavigationItem.more:
      return localizations.more;
  }
}
