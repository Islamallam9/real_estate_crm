import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_event.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import '../localization/locale_cubit.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../routing/route_names.dart';
import 'responsive_layout.dart';

enum CrmNavigationItem { dashboard, leads, properties, clients, tasks }

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

  @override
  Widget build(BuildContext context) {
    final effectiveOnItemSelected =
        onItemSelected ?? (item) => _goToItem(context, item);

    return _AuthLogoutListener(
      child: ResponsiveLayout(
        mobile: _MobileShell(
          selectedItem: selectedItem,
          title: title,
          items: _items,
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
    case CrmNavigationItem.clients:
    case CrmNavigationItem.tasks:
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
    return Scaffold(
      backgroundColor: AppColors.background,
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(title ?? _labelFor(context, selectedItem)),
        centerTitle: false,
        actions: const [
          _NotificationIconButton(),
          _LanguageMenuButton(),
          _LogoutIconButton(),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: child,
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: items.indexWhere((item) => item.item == selectedItem),
        onDestinationSelected: (index) =>
            onItemSelected?.call(items[index].item),
        destinations: [
          for (final item in items)
            NavigationDestination(
              icon: Icon(item.icon),
              selectedIcon: Icon(item.selectedIcon),
              label: item.label(context),
            ),
        ],
      ),
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
    return Container(
      width: 248,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(right: BorderSide(color: AppColors.border)),
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
                  color: AppColors.textSecondary,
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
    final color = selected ? AppColors.primary : AppColors.textSecondary;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Material(
        color: selected
            ? AppColors.primary.withValues(alpha: 0.08)
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

    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
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
  const _NotificationIconButton();

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: AppLocalizations.of(context)!.notifications,
      onPressed: () {},
      icon: const Icon(Icons.notifications_none),
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

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const _UserAvatar(),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.crmUser,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  AppLocalizations.of(context)!.workspace,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
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

class _UserAvatar extends StatelessWidget {
  const _UserAvatar();

  @override
  Widget build(BuildContext context) {
    return const CircleAvatar(
      radius: 18,
      backgroundColor: AppColors.primary,
      child: Text(
        'U',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
      ),
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
  }
}
