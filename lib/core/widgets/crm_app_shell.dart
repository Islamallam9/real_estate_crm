import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_event.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import '../localization/locale_cubit.dart';
import '../theme/app_colors.dart';
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
    case CrmNavigationItem.more:
      break;
  }
}

class _DesktopShell extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final colors = _CrmShellColors.of(context);

    return Scaffold(
      backgroundColor: colors.background,
      body: Row(
        children: [
          _Sidebar(
            selectedItem: selectedItem,
            items: items,
            onItemSelected: onItemSelected,
          ),
          Expanded(
            child: Column(
              children: [
                _TopBar(title: title ?? _labelFor(context, selectedItem)),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: child,
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
        toolbarHeight: 100,
        automaticallyImplyLeading: false,
        title: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
            AppSpacing.md,
            AppSpacing.sm,
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
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.xl,
          ),
          child: child,
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
            height: 88,
            padding: const EdgeInsetsDirectional.fromSTEB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.sm,
              AppSpacing.md,
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
                          fontWeight: FontWeight.w700,
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
                  onTap: () => Navigator.of(sheetContext).pop(),
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
    this.onItemSelected,
  });

  final CrmNavigationItem selectedItem;
  final List<_CrmShellItem> items;
  final ValueChanged<CrmNavigationItem>? onItemSelected;

  @override
  Widget build(BuildContext context) {
    final colors = _CrmShellColors.of(context);

    return Container(
      width: 248,
      decoration: BoxDecoration(
        color: colors.chromeSurface,
        border: BorderDirectional(end: BorderSide(color: colors.border)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _BrandHeader(),
              const SizedBox(height: AppSpacing.lg),
              for (final item in items)
                _SidebarItem(
                  item: item,
                  selected: item.item == selectedItem,
                  onTap: () => onItemSelected?.call(item.item),
                ),
              const Spacer(),
              const _ProfileSummary(),
            ],
          ),
        ),
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.apartment, color: Colors.white, size: 22),
        ),
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
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                AppLocalizations.of(context)!.salesWorkspace,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodySmall?.copyWith(
                  color: _CrmShellColors.of(context).textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
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

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Material(
        color: selected
            ? colors.selectedSurface
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                Icon(
                  selected ? item.selectedIcon : item.icon,
                  color: color,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    item.label(context),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyMedium?.copyWith(
                      color: color,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
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
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = _CrmShellColors.of(context);

    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.chromeSurface,
        border: Border(bottom: BorderSide(color: colors.border)),
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
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
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
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              const SizedBox(width: AppSpacing.sm),
              const _NotificationIconButton(),
              const SizedBox(width: AppSpacing.xs),
              const _LanguageMenuButton(),
              const _ThemeToggleButton(),
              const _LogoutIconButton(),
              const SizedBox(width: AppSpacing.sm),
              const _UserAvatar(),
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

class _LogoutIconButton extends StatelessWidget {
  const _LogoutIconButton();

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: AppLocalizations.of(context)!.logoutTooltip,
      onPressed: () {
        context.read<AuthBloc>().add(const AuthSignOutRequested());
      },
      icon: const Icon(Icons.logout),
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

class _ProfileSummary extends StatelessWidget {
  const _ProfileSummary();

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

        return Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: colors.cardSurface,
            border: Border.all(color: colors.border),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              _UserAvatar(name: fullName),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      localizations.workspace,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _UserAvatar extends StatelessWidget {
  const _UserAvatar({this.name});

  final String? name;

  @override
  Widget build(BuildContext context) {
    final initial = _initialFor(name ?? AppLocalizations.of(context)!.crmUser);
    final colors = _CrmShellColors.of(context);

    return CircleAvatar(
      radius: 18,
      backgroundColor: colors.primary,
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
        inputSurface: AppColors.background,
        selectedSurface: Color(0x14123047),
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
