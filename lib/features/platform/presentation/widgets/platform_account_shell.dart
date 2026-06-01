import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';

class PlatformAccountShell extends StatelessWidget {
  const PlatformAccountShell({
    super.key,
    required this.title,
    required this.child,
    required this.selected,
  });

  final String title;
  final Widget child;
  final PlatformAccountNavItem selected;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 1040;
    return Scaffold(
      backgroundColor: AppColors.appBackground(context),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              _PlatformAccountTopBar(title: title),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: wide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(
                            width: 260,
                            child: _PlatformAccountSidebar(selected: selected),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(child: child),
                        ],
                      )
                    : Column(
                        children: [
                          _PlatformAccountMobileNav(selected: selected),
                          const SizedBox(height: AppSpacing.md),
                          Expanded(child: child),
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

enum PlatformAccountNavItem {
  overview,
  notifications,
  monitoring,
  support,
  profile,
  settings,
}

class _PlatformAccountTopBar extends StatelessWidget {
  const _PlatformAccountTopBar({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.chromeSurface(context).withValues(alpha: 0.96),
        border: Border.all(color: AppColors.borderColor(context)),
        borderRadius: AppRadius.xLarge,
      ),
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          final name = _platformUserName(authState, l.platformAdmin);
          final email = (authState.user?.email ?? '').trim();
          final photoUrl = (authState.user?.photoUrl ?? '').trim();
          return Row(
            children: [
              _PlatformAccountAvatar(name: name, photoUrl: photoUrl),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    if (email.isNotEmpty)
                      Text(
                        email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondaryColor(context),
                            ),
                      ),
                  ],
                ),
              ),
              IconButton(
                tooltip: l.platformDashboard,
                onPressed: () => context.go(RouteNames.platform),
                icon: const Icon(Icons.admin_panel_settings_outlined),
              ),
              IconButton(
                tooltip: l.logout,
                onPressed: () =>
                    context.read<AuthBloc>().add(const AuthSignOutRequested()),
                icon: const Icon(Icons.logout),
                color: AppColors.errorColor(context),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PlatformAccountSidebar extends StatelessWidget {
  const _PlatformAccountSidebar({required this.selected});

  final PlatformAccountNavItem selected;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.cardSurface(context),
        border: Border.all(color: AppColors.borderColor(context)),
        borderRadius: AppRadius.xLarge,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l.platformDashboard,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: ListView(
              children: [
                for (final item in PlatformAccountNavItem.values)
                  _PlatformAccountNavTile(
                    item: item,
                    selected: selected == item,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlatformAccountMobileNav extends StatelessWidget {
  const _PlatformAccountMobileNav({required this.selected});

  final PlatformAccountNavItem selected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: PlatformAccountNavItem.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.xs),
        itemBuilder: (context, index) {
          final item = PlatformAccountNavItem.values[index];
          return ChoiceChip(
            avatar: Icon(_iconFor(item), size: 18),
            label: Text(_labelFor(context, item)),
            selected: selected == item,
            onSelected: (_) => context.go(_routeFor(item)),
          );
        },
      ),
    );
  }
}

class _PlatformAccountNavTile extends StatelessWidget {
  const _PlatformAccountNavTile({
    required this.item,
    required this.selected,
  });

  final PlatformAccountNavItem item;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? AppColors.textPrimaryColor(context)
        : AppColors.textSecondaryColor(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Material(
        color: selected
            ? AppColors.primaryColor(context).withValues(alpha: .16)
            : Colors.transparent,
        borderRadius: AppRadius.large,
        child: InkWell(
          borderRadius: AppRadius.large,
          onTap: () => context.go(_routeFor(item)),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                Icon(_iconFor(item), size: 20, color: color),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    _labelFor(context, item),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: color,
                          fontWeight:
                              selected ? FontWeight.w800 : FontWeight.w600,
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

class _PlatformAccountAvatar extends StatelessWidget {
  const _PlatformAccountAvatar({required this.name, required this.photoUrl});

  final String name;
  final String photoUrl;

  @override
  Widget build(BuildContext context) {
    final fallback = CircleAvatar(
      radius: 18,
      backgroundColor: AppColors.primaryColor(context),
      child: Text(
        name.trim().isEmpty ? 'P' : name.trim().substring(0, 1).toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
    if (photoUrl.trim().isEmpty) {
      return fallback;
    }
    return ClipOval(
      child: SizedBox(
        width: 36,
        height: 36,
        child: Image.network(
          photoUrl.trim(),
          fit: BoxFit.cover,
          gaplessPlayback: true,
          errorBuilder: (_, __, ___) => fallback,
        ),
      ),
    );
  }
}

String _labelFor(BuildContext context, PlatformAccountNavItem item) {
  final l = AppLocalizations.of(context)!;
  return switch (item) {
    PlatformAccountNavItem.overview => l.platformDashboard,
    PlatformAccountNavItem.notifications => l.platformNotifications,
    PlatformAccountNavItem.monitoring => l.platformMonitoring,
    PlatformAccountNavItem.support => l.platformSupportInbox,
    PlatformAccountNavItem.profile => l.profile,
    PlatformAccountNavItem.settings => l.settings,
  };
}

IconData _iconFor(PlatformAccountNavItem item) {
  return switch (item) {
    PlatformAccountNavItem.overview => Icons.dashboard_outlined,
    PlatformAccountNavItem.notifications => Icons.notifications_outlined,
    PlatformAccountNavItem.monitoring => Icons.monitor_heart_outlined,
    PlatformAccountNavItem.support => Icons.support_agent_outlined,
    PlatformAccountNavItem.profile => Icons.person_outline,
    PlatformAccountNavItem.settings => Icons.settings_outlined,
  };
}

String _routeFor(PlatformAccountNavItem item) {
  return switch (item) {
    PlatformAccountNavItem.overview => RouteNames.platform,
    PlatformAccountNavItem.notifications => RouteNames.platformNotifications,
    PlatformAccountNavItem.monitoring => RouteNames.platformMonitoring,
    PlatformAccountNavItem.support => RouteNames.platformSupport,
    PlatformAccountNavItem.profile => RouteNames.profile,
    PlatformAccountNavItem.settings => RouteNames.settings,
  };
}

String _platformUserName(AuthState state, String fallback) {
  final fullName = (state.user?.fullName ?? '').trim();
  if (fullName.isNotEmpty) {
    return fullName;
  }
  final displayName = (state.user?.displayName ?? '').trim();
  if (displayName.isNotEmpty) {
    return displayName;
  }
  final email = (state.user?.email ?? '').trim();
  return email.isEmpty ? fallback : email;
}
