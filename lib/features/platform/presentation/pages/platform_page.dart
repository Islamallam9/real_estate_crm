import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/role_constants.dart';
import '../../../../core/localization/locale_cubit.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_dropdown.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_search_field.dart';
import '../../../../core/widgets/app_status_badge.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../users/domain/entities/company_metadata.dart';
import '../../data/datasources/platform_remote_data_source.dart';
import '../../data/repositories/platform_repository_impl.dart';
import '../../domain/entities/platform_company_user.dart';
import '../../domain/usecases/add_user_to_company_usecase.dart';
import '../../domain/usecases/create_company_with_admin_usecase.dart';
import '../../domain/usecases/set_company_active_status_usecase.dart';
import '../../domain/usecases/set_company_user_active_status_usecase.dart';
import '../../domain/usecases/update_company_platform_settings_usecase.dart';
import '../../domain/usecases/watch_platform_companies_usecase.dart';
import '../../domain/usecases/watch_platform_company_users_usecase.dart';
import '../cubit/platform_cubit.dart';
import '../cubit/platform_state.dart';

class PlatformPage extends StatelessWidget {
  const PlatformPage({super.key});

  static Widget withDependencies() {
    final remoteDataSource = FirebasePlatformRemoteDataSource();
    final repository = PlatformRepositoryImpl(
      remoteDataSource: remoteDataSource,
    );

    return BlocProvider(
      create: (_) => PlatformCubit(
        watchCompaniesUseCase: WatchPlatformCompaniesUseCase(repository),
        watchCompanyUsersUseCase: WatchPlatformCompanyUsersUseCase(repository),
        createCompanyWithAdminUseCase: CreateCompanyWithAdminUseCase(
          repository,
        ),
        addUserToCompanyUseCase: AddUserToCompanyUseCase(repository),
        setCompanyActiveStatusUseCase: SetCompanyActiveStatusUseCase(
          repository,
        ),
        setCompanyUserActiveStatusUseCase:
            SetCompanyUserActiveStatusUseCase(repository),
        updateCompanyPlatformSettingsUseCase:
            UpdateCompanyPlatformSettingsUseCase(repository),
      )..watchCompanies(),
      child: const PlatformPage(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return BlocListener<PlatformCubit, PlatformState>(
      listenWhen: (previous, current) {
        return previous.status != current.status &&
            current.status == PlatformStatus.failure &&
            current.message != null;
      },
      listener: (context, state) {
        if (!context.mounted) {
          return;
        }
        AppFeedback.error(context, state.message ?? l.unableToSave);
      },
      child: Scaffold(
        backgroundColor: AppColors.appBackground(context),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
                const _PlatformTopBar(),
                const SizedBox(height: AppSpacing.md),
                Expanded(
                  child: BlocBuilder<PlatformCubit, PlatformState>(
                    builder: (context, state) {
                      if (state.status == PlatformStatus.loading) {
                        return const AppLoading();
                      }

                      if (state.status == PlatformStatus.failure &&
                          state.companies.isEmpty) {
                        return AppErrorView(
                          message: state.message ?? l.somethingWentWrong,
                          onRetry: context.read<PlatformCubit>().watchCompanies,
                        );
                      }

                      return _PlatformWorkspace(state: state);
                    },
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


class _PlatformTopBar extends StatelessWidget {
  const _PlatformTopBar();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final compact = MediaQuery.sizeOf(context).width < 760;

    return Container(
      height: compact ? 74 : 66,
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.md,
        AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.chromeSurface(context).withValues(alpha: 0.96),
        border: Border.all(color: AppColors.borderColor(context)),
        borderRadius: AppRadius.xLarge,
      ),
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          final adminName = _platformUserName(authState, l.platformAdmin);
          final greeting = _platformGreeting(l, DateTime.now());

          return Row(
            children: [
              _PlatformAvatar(name: adminName),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.platformDashboard,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.textPrimaryColor(context),
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$greeting, $adminName',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondaryColor(context),
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
              if (!compact) ...[
                SizedBox(
                  width: 320,
                  child: TextField(
                    readOnly: true,
                    decoration: InputDecoration(
                      hintText: l.searchCrm,
                      prefixIcon: const Icon(Icons.search),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
              const _PlatformNotificationButton(),
              const SizedBox(width: AppSpacing.xs),
              const _PlatformLanguageButton(),
              const _PlatformThemeButton(),
              const SizedBox(width: AppSpacing.xs),
              const _PlatformProfileMenu(),
            ],
          );
        },
      ),
    );
  }
}

class _PlatformNotificationButton extends StatelessWidget {
  const _PlatformNotificationButton();

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: AppLocalizations.of(context)!.notifications,
      onPressed: () {},
      icon: const Icon(Icons.notifications_none),
    );
  }
}

class _PlatformLanguageButton extends StatelessWidget {
  const _PlatformLanguageButton();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return PopupMenuButton<String>(
      tooltip: l.language,
      icon: const Icon(Icons.language),
      onSelected: (languageCode) {
        final localeCubit = context.read<LocaleCubit>();
        if (languageCode == 'ar') {
          localeCubit.setArabic();
        } else {
          localeCubit.setEnglish();
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem<String>(value: 'en', child: Text(l.english)),
        PopupMenuItem<String>(value: 'ar', child: Text(l.arabic)),
      ],
    );
  }
}

class _PlatformThemeButton extends StatelessWidget {
  const _PlatformThemeButton();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return BlocBuilder<ThemeCubit, ThemeMode>(
      builder: (context, themeMode) {
        final isDark = themeMode == ThemeMode.dark;
        return IconButton(
          tooltip: isDark ? l.lightMode : l.darkMode,
          onPressed: () => context.read<ThemeCubit>().toggle(),
          icon: Icon(
            isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
          ),
        );
      },
    );
  }
}

enum _PlatformProfileAction { settings, logout }

class _PlatformProfileMenu extends StatelessWidget {
  const _PlatformProfileMenu();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final userName = _platformUserName(authState, l.platformAdmin);
        final email = (authState.user?.email ?? '').trim();

        return PopupMenuButton<_PlatformProfileAction>(
          tooltip: l.profile,
          position: PopupMenuPosition.under,
          color: AppColors.cardSurface(context),
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.xLarge,
            side: BorderSide(color: AppColors.borderColor(context)),
          ),
          onSelected: (action) {
            switch (action) {
              case _PlatformProfileAction.settings:
                _showPlatformSettingsSheet(context);
              case _PlatformProfileAction.logout:
                context.read<AuthBloc>().add(const AuthSignOutRequested());
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem<_PlatformProfileAction>(
              enabled: false,
              child: Row(
                children: [
                  _PlatformAvatar(name: userName),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        if (email.isNotEmpty)
                          Text(
                            email,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.textSecondaryColor(context),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const PopupMenuDivider(height: 1),
            PopupMenuItem<_PlatformProfileAction>(
              value: _PlatformProfileAction.settings,
              child: _PlatformProfileMenuTile(
                icon: Icons.settings_outlined,
                label: l.settings,
              ),
            ),
            PopupMenuItem<_PlatformProfileAction>(
              value: _PlatformProfileAction.logout,
              child: _PlatformProfileMenuTile(
                icon: Icons.logout,
                label: l.logout,
                destructive: true,
              ),
            ),
          ],
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.borderColor(context)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: _PlatformAvatar(name: userName),
            ),
          ),
        );
      },
    );
  }
}

class _PlatformProfileMenuTile extends StatelessWidget {
  const _PlatformProfileMenuTile({
    required this.icon,
    required this.label,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
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
            style: TextStyle(color: color, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class _PlatformAvatar extends StatelessWidget {
  const _PlatformAvatar({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 18,
      backgroundColor: AppColors.primaryColor(context),
      child: Text(
        _initialFor(name),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

void _showPlatformSettingsSheet(BuildContext context) {
  final localeCubit = context.read<LocaleCubit>();
  final themeCubit = context.read<ThemeCubit>();
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    backgroundColor: AppColors.cardSurface(context),
    builder: (sheetContext) {
      final l = AppLocalizations.of(sheetContext)!;
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l.settings,
                style: Theme.of(sheetContext).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: AppSpacing.md),
              BlocBuilder<ThemeCubit, ThemeMode>(
                bloc: themeCubit,
                builder: (context, themeMode) {
                  final isDark = themeMode == ThemeMode.dark;
                  return SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l.theme),
                    subtitle: Text(isDark ? l.darkMode : l.lightMode),
                    value: isDark,
                    onChanged: (_) => themeCubit.toggle(),
                  );
                },
              ),
              BlocBuilder<LocaleCubit, Locale?>(
                bloc: localeCubit,
                builder: (context, locale) {
                  final selected = locale?.languageCode ?? 'en';
                  return Column(
                    children: [
                      RadioListTile<String>(
                        contentPadding: EdgeInsets.zero,
                        title: Text(l.english),
                        value: 'en',
                        groupValue: selected,
                        onChanged: (_) => localeCubit.setEnglish(),
                      ),
                      RadioListTile<String>(
                        contentPadding: EdgeInsets.zero,
                        title: Text(l.arabic),
                        value: 'ar',
                        groupValue: selected,
                        onChanged: (_) => localeCubit.setArabic(),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              AppButton(
                label: l.logout,
                icon: Icons.logout,
                variant: AppButtonVariant.danger,
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  context.read<AuthBloc>().add(const AuthSignOutRequested());
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}

String _platformGreeting(AppLocalizations l, DateTime now) {
  final hour = now.hour;
  if (hour < 12) {
    return l.dashboardGoodMorning;
  }
  if (hour < 18) {
    return l.dashboardGoodAfternoon;
  }
  return l.dashboardGoodEvening;
}

String _platformUserName(AuthState state, String fallback) {
  final fullName = (state.user?.fullName ?? '').trim();
  if (fullName.isNotEmpty) {
    return fullName;
  }
  final email = (state.user?.email ?? '').trim();
  if (email.isNotEmpty) {
    return email;
  }
  return fallback;
}

enum _PlatformSection {
  overview,
  companies,
  details,
  users,
  settings,
  features,
  limits,
  preview,
}

class _PlatformWorkspace extends StatefulWidget {
  const _PlatformWorkspace({required this.state});

  final PlatformState state;

  @override
  State<_PlatformWorkspace> createState() => _PlatformWorkspaceState();
}

class _PlatformWorkspaceState extends State<_PlatformWorkspace> {
  var _section = _PlatformSection.overview;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 1040;
    final content = _PlatformSectionContent(
      section: _section,
      state: widget.state,
      onSectionSelected: (section) => setState(() => _section = section),
    );

    if (!wide) {
      return Column(
        children: [
          _PlatformMobileNavigation(
            selected: _section,
            onSelected: (section) => setState(() => _section = section),
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(child: content),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: 260,
          child: _PlatformSidebar(
            selected: _section,
            state: widget.state,
            onSelected: (section) => setState(() => _section = section),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(child: content),
      ],
    );
  }
}

class _PlatformSectionContent extends StatelessWidget {
  const _PlatformSectionContent({
    required this.section,
    required this.state,
    required this.onSectionSelected,
  });

  final _PlatformSection section;
  final PlatformState state;
  final ValueChanged<_PlatformSection> onSectionSelected;

  @override
  Widget build(BuildContext context) {
    final children = switch (section) {
      _PlatformSection.overview => [
        _PlatformHeader(state: state),
        const SizedBox(height: AppSpacing.md),
        _PlatformKpis(state: state),
        const SizedBox(height: AppSpacing.md),
        _OverviewGrid(
          state: state,
          onOpenCompanies: () => onSectionSelected(_PlatformSection.companies),
          onOpenSettings: () => onSectionSelected(_PlatformSection.settings),
          onOpenPreview: () => onSectionSelected(_PlatformSection.preview),
        ),
      ],
      _PlatformSection.companies => [_CompaniesPanel(state: state)],
      _PlatformSection.details => [_CompanyDetailsPanel(state: state)],
      _PlatformSection.users => [_CompanyUsersPanel(state: state)],
      _PlatformSection.settings => [_CompanySettingsPanel(state: state)],
      _PlatformSection.features => [_CompanyFeaturesPanel(state: state)],
      _PlatformSection.limits => [_CompanyLimitsPanel(state: state)],
      _PlatformSection.preview => [_CompanyPreviewPanel(state: state)],
    };

    return ListView(
      children: children,
    );
  }
}

class _PlatformSidebar extends StatelessWidget {
  const _PlatformSidebar({
    required this.selected,
    required this.state,
    required this.onSelected,
  });

  final _PlatformSection selected;
  final PlatformState state;
  final ValueChanged<_PlatformSection> onSelected;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final company = state.selectedCompany;
    final name = company == null
        ? l.noCompanySelected
        : _companyTitle(company);

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
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primaryColor(context).withValues(alpha: .14),
                  borderRadius: AppRadius.large,
                ),
                child: Icon(
                  Icons.admin_panel_settings_outlined,
                  color: AppColors.primaryColor(context),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.platformDashboard,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      name,
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
          ),
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: ListView(
              children: [
                for (final section in _PlatformSection.values)
                  _PlatformNavItem(
                    label: _sectionLabel(l, section),
                    icon: _sectionIcon(section),
                    selected: selected == section,
                    onTap: () => onSelected(section),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }
}

class _PlatformMobileNavigation extends StatelessWidget {
  const _PlatformMobileNavigation({
    required this.selected,
    required this.onSelected,
  });

  final _PlatformSection selected;
  final ValueChanged<_PlatformSection> onSelected;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _PlatformSection.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.xs),
        itemBuilder: (context, index) {
          final section = _PlatformSection.values[index];
          return ChoiceChip(
            avatar: Icon(_sectionIcon(section), size: 18),
            label: Text(_sectionLabel(l, section)),
            selected: selected == section,
            onSelected: (_) => onSelected(section),
          );
        },
      ),
    );
  }
}

class _PlatformNavItem extends StatelessWidget {
  const _PlatformNavItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

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
          onTap: onTap,
          borderRadius: AppRadius.large,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                Icon(icon, size: 20, color: color),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: color,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
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

class _PlatformHeader extends StatelessWidget {
  const _PlatformHeader({required this.state});

  final PlatformState state;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final authState = context.watch<AuthBloc>().state;
    final user = authState.user;
    final adminLabel = [
      if ((user?.fullName ?? '').trim().isNotEmpty) user!.fullName,
      if ((user?.email ?? '').trim().isNotEmpty) user!.email,
    ].join(' - ');

    return _Panel(
      title: l.platformDashboard,
      child: Wrap(
        spacing: AppSpacing.lg,
        runSpacing: AppSpacing.sm,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Text(
              l.platformDashboardSubtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondaryColor(context),
              ),
            ),
          ),
          if (adminLabel.isNotEmpty)
            _InfoChip(label: l.platformAdmin, value: adminLabel),
        ],
      ),
    );
  }
}

class _PlatformKpis extends StatelessWidget {
  const _PlatformKpis({required this.state});

  final PlatformState state;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final companies = state.companies;
    final activeCompanies = companies.where(_isOperationalCompany).length;
    final inactiveCompanies =
        companies.where((company) => !_isOperationalCompany(company)).length;
    final trialCompanies =
        companies.where((company) => company.status == 'trial').length;
    final recentCompanies = companies.where((company) {
      return DateTime.now().difference(company.createdAt).inDays <= 30;
    }).length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1100
            ? 5
            : constraints.maxWidth >= 760
                ? 3
                : 2;
        return GridView.count(
          crossAxisCount: columns,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AppSpacing.sm,
          crossAxisSpacing: AppSpacing.sm,
          childAspectRatio: constraints.maxWidth < 520 ? 1.65 : 2.2,
          children: [
            _KpiCard(
              label: l.totalCompanies,
              value: companies.length.toString(),
              icon: Icons.apartment_outlined,
              tone: AppStatusTone.info,
            ),
            _KpiCard(
              label: l.activeCompanies,
              value: activeCompanies.toString(),
              icon: Icons.check_circle_outline,
              tone: AppStatusTone.success,
            ),
            _KpiCard(
              label: l.inactiveCompanies,
              value: inactiveCompanies.toString(),
              icon: Icons.block_outlined,
              tone: AppStatusTone.error,
            ),
            _KpiCard(
              label: l.trialCompanies,
              value: trialCompanies.toString(),
              icon: Icons.hourglass_top_outlined,
              tone: AppStatusTone.warning,
            ),
            _KpiCard(
              label: l.recentlyCreatedCompanies,
              value: recentCompanies.toString(),
              icon: Icons.calendar_month_outlined,
              tone: AppStatusTone.neutral,
            ),
          ],
        );
      },
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.tone,
  });

  final String label;
  final String value;
  final IconData icon;
  final AppStatusTone tone;

  @override
  Widget build(BuildContext context) {
    final color = _toneColor(context, tone);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.cardSurface(context),
        border: Border.all(color: AppColors.borderColor(context)),
        borderRadius: AppRadius.large,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: AppRadius.large,
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondaryColor(context),
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

class _CompaniesPanel extends StatefulWidget {
  const _CompaniesPanel({required this.state});

  final PlatformState state;

  @override
  State<_CompaniesPanel> createState() => _CompaniesPanelState();
}

class _CompaniesPanelState extends State<_CompaniesPanel> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.state.searchQuery);
  }

  @override
  void didUpdateWidget(covariant _CompaniesPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state.searchQuery != _searchController.text) {
      _searchController.text = widget.state.searchQuery;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final state = widget.state;
    final companies = state.filteredCompanies;

    return _Panel(
      title: l.platformCompanies,
      action: AppButton(
        label: l.createCompany,
        icon: Icons.add_business,
        onPressed: state.status == PlatformStatus.saving
            ? null
            : () => _showCreateCompanyDialog(context),
      ),
      child: state.companies.isEmpty
          ? AppEmptyState(
              icon: Icons.business_outlined,
              title: l.noCompanies,
              message: l.noCompaniesMessage,
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppSearchField(
                  controller: _searchController,
                  hint: l.searchCompanies,
                  onChanged: context.read<PlatformCubit>().updateSearchQuery,
                  onClear: () {
                    _searchController.clear();
                    context.read<PlatformCubit>().updateSearchQuery('');
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                _CompanyFilterChips(state: state),
                const SizedBox(height: AppSpacing.md),
                if (companies.isEmpty)
                  AppEmptyState(
                    icon: Icons.search_off_outlined,
                    title: l.noCompaniesFound,
                    message: l.noCompaniesFoundMessage,
                  )
                else
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 560),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: companies.length,
                      itemBuilder: (context, index) {
                        final company = companies[index];
                        return _CompanyTile(
                          company: company,
                          selected: state.selectedCompany?.id == company.id,
                          onTap: () {
                            context
                                .read<PlatformCubit>()
                                .selectCompany(company.id);
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
    );
  }
}

class _CompanyFilterChips extends StatelessWidget {
  const _CompanyFilterChips({required this.state});

  final PlatformState state;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: [
        for (final filter in PlatformCompanyFilter.values)
          ChoiceChip(
            label: Text(_companyFilterLabel(l, filter)),
            selected: state.companyFilter == filter,
            onSelected: (_) {
              context.read<PlatformCubit>().updateCompanyFilter(filter);
            },
          ),
      ],
    );
  }
}

class _CompanyDetailsPanel extends StatelessWidget {
  const _CompanyDetailsPanel({required this.state});

  final PlatformState state;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final company = state.selectedCompany;
    if (company == null) {
      return _Panel(
        title: l.companyDetails,
        child: AppEmptyState(
          icon: Icons.apartment_outlined,
          title: l.noCompanySelected,
          message: l.noCompanySelectedMessage,
        ),
      );
    }

    final companyBusy = state.activeCompanyActionId == company.id;
    final companyActive = _isOperationalCompany(company);
    final userLimit = _limitValue(company.limits['users']);
    final userLimitReached =
        userLimit != null && state.companyUsers.length >= userLimit;

    return _Panel(
      title: company.displayName.isEmpty ? company.name : company.displayName,
      action: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.xs,
        children: [
          AppButton(
            label: l.previewDashboard,
            icon: Icons.dashboard_customize_outlined,
            variant: AppButtonVariant.secondary,
            onPressed: () => _openPreview(context, company),
          ),
          AppButton(
            label: companyActive ? l.deactivateCompany : l.activateCompany,
            icon: companyActive ? Icons.block : Icons.check_circle_outline,
            variant: companyActive
                ? AppButtonVariant.danger
                : AppButtonVariant.secondary,
            isLoading: companyBusy,
            onPressed: companyBusy
                ? null
                : () async {
                    final success = await context
                        .read<PlatformCubit>()
                        .setCompanyActiveStatus(
                          companyId: company.id,
                          isActive: !companyActive,
                        );
                    if (context.mounted && success) {
                      AppFeedback.success(context, l.savedSuccessfully);
                    }
                  },
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _InfoChip(label: l.companyIdSlug, value: company.id),
              _InfoChip(label: l.status, value: _statusLabel(l, company)),
              _InfoChip(
                label: l.createdAt,
                value: _formatDate(context, company.createdAt),
              ),
              _InfoChip(
                label: l.updatedAt,
                value: _formatDate(context, company.updatedAt),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _CompanyMetadataSections(company: company),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: Text(
                  l.companyUsers,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              AppButton(
                label: l.addUser,
                icon: Icons.person_add_alt_1,
                variant: AppButtonVariant.secondary,
                onPressed: state.status == PlatformStatus.saving ||
                        userLimitReached
                    ? null
                    : () => _showAddUserDialog(context, company.id),
              ),
            ],
          ),
          if (userLimitReached) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              l.userLimitReached,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.warningColor(context),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          if (state.companyUsers.isEmpty)
            AppEmptyState(
              icon: Icons.people_outline,
              title: l.noCompanyUsers,
              message: l.noCompanyUsersMessage,
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 360),
              child: _UsersTable(
                companyId: company.id,
                users: state.companyUsers,
                activeUserActionId: state.activeUserActionId,
              ),
            ),
        ],
      ),
    );
  }
}

class _OverviewGrid extends StatelessWidget {
  const _OverviewGrid({
    required this.state,
    required this.onOpenCompanies,
    required this.onOpenSettings,
    required this.onOpenPreview,
  });

  final PlatformState state;
  final VoidCallback onOpenCompanies;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenPreview;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final company = state.selectedCompany;

    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 840;
        final children = [
          _Panel(
            title: l.platformCompanies,
            action: AppButton(
              label: l.platformCompanies,
              icon: Icons.apartment_outlined,
              variant: AppButtonVariant.secondary,
              onPressed: onOpenCompanies,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.platformDashboardSubtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondaryColor(context),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    _InfoChip(
                      label: l.totalCompanies,
                      value: state.companies.length.toString(),
                    ),
                    _InfoChip(
                      label: l.activeCompanies,
                      value: state.companies
                          .where(_isOperationalCompany)
                          .length
                          .toString(),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _Panel(
            title: company == null ? l.companyDetails : _companyTitle(company),
            action: company == null
                ? null
                : Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.xs,
                    children: [
                      AppButton(
                        label: l.editCompanySettings,
                        icon: Icons.tune,
                        variant: AppButtonVariant.secondary,
                        onPressed: onOpenSettings,
                      ),
                      AppButton(
                        label: l.previewDashboard,
                        icon: Icons.dashboard_customize_outlined,
                        variant: AppButtonVariant.secondary,
                        onPressed: onOpenPreview,
                      ),
                    ],
                  ),
            child: company == null
                ? AppEmptyState(
                    icon: Icons.apartment_outlined,
                    title: l.noCompanySelected,
                    message: l.noCompanySelectedMessage,
                  )
                : Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      _InfoChip(label: l.companyIdSlug, value: company.id),
                      _InfoChip(label: l.status, value: _statusLabel(l, company)),
                      _InfoChip(
                        label: l.usersUsed,
                        value: _usersUsedLabel(context, state, company),
                      ),
                      _InfoChip(
                        label: l.storageLimitMb,
                        value: _limitLabel(context, company.limits['storageMb']),
                      ),
                    ],
                  ),
          ),
        ];

        if (narrow) {
          return Column(
            children: [
              for (final child in children) ...[
                child,
                if (child != children.last)
                  const SizedBox(height: AppSpacing.md),
              ],
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final child in children) ...[
              Expanded(child: child),
              if (child != children.last)
                const SizedBox(width: AppSpacing.md),
            ],
          ],
        );
      },
    );
  }
}

class _CompanyUsersPanel extends StatelessWidget {
  const _CompanyUsersPanel({required this.state});

  final PlatformState state;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final company = state.selectedCompany;
    if (company == null) {
      return _Panel(
        title: l.companyUsers,
        child: AppEmptyState(
          icon: Icons.people_outline,
          title: l.noCompanySelected,
          message: l.noCompanySelectedMessage,
        ),
      );
    }

    final userLimit = _limitValue(company.limits['users']);
    final userLimitReached =
        userLimit != null && state.companyUsers.length >= userLimit;

    return _Panel(
      title: l.companyUsers,
      action: AppButton(
        label: l.addUser,
        icon: Icons.person_add_alt_1,
        variant: AppButtonVariant.secondary,
        onPressed: state.status == PlatformStatus.saving || userLimitReached
            ? null
            : () => _showAddUserDialog(context, company.id),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _InfoChip(
                label: l.usersUsed,
                value: _usersUsedLabel(context, state, company),
              ),
              _InfoChip(
                label: l.userLimit,
                value: _limitLabel(context, company.limits['users']),
              ),
            ],
          ),
          if (userLimitReached) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              l.userLimitReached,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.warningColor(context),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          if (state.companyUsers.isEmpty)
            AppEmptyState(
              icon: Icons.people_outline,
              title: l.noCompanyUsers,
              message: l.noCompanyUsersMessage,
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 620),
              child: _UsersTable(
                companyId: company.id,
                users: state.companyUsers,
                activeUserActionId: state.activeUserActionId,
              ),
            ),
        ],
      ),
    );
  }
}

class _CompanySettingsPanel extends StatelessWidget {
  const _CompanySettingsPanel({required this.state});

  final PlatformState state;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final company = state.selectedCompany;
    if (company == null) {
      return _Panel(
        title: l.companySettings,
        child: AppEmptyState(
          icon: Icons.tune,
          title: l.noCompanySelected,
          message: l.noCompanySelectedMessage,
        ),
      );
    }

    return _Panel(
      title: l.companySettings,
      action: AppButton(
        label: l.editCompanySettings,
        icon: Icons.edit_outlined,
        variant: AppButtonVariant.secondary,
        isLoading: state.activeSettingsActionId == 'settings',
        onPressed: state.status == PlatformStatus.saving
            ? null
            : () => _showEditCompanySettingsDialog(context, company),
      ),
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          _InfoChip(label: l.companyName, value: _companyTitle(company)),
          _InfoChip(label: l.companyIdSlug, value: company.id),
          _InfoChip(label: l.status, value: _statusLabel(l, company)),
          _InfoChip(
            label: l.active,
            value: company.isActive ? l.active : l.inactive,
          ),
          _InfoChip(
            label: l.locale,
            value: company.settings['locale']?.toString() ?? l.notAvailable,
          ),
          _InfoChip(
            label: l.timezone,
            value: company.settings['timezone']?.toString() ?? l.notAvailable,
          ),
          _InfoChip(
            label: l.updatedAt,
            value: _formatDate(context, company.updatedAt),
          ),
        ],
      ),
    );
  }
}

class _CompanyFeaturesPanel extends StatelessWidget {
  const _CompanyFeaturesPanel({required this.state});

  final PlatformState state;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final company = state.selectedCompany;
    if (company == null) {
      return _Panel(
        title: l.companyFeatures,
        child: AppEmptyState(
          icon: Icons.extension_outlined,
          title: l.noCompanySelected,
          message: l.noCompanySelectedMessage,
        ),
      );
    }

    return _Panel(
      title: l.companyFeatures,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 900 ? 2 : 1;
          return GridView.count(
            crossAxisCount: columns,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: AppSpacing.sm,
            mainAxisSpacing: AppSpacing.sm,
            childAspectRatio: constraints.maxWidth < 480 ? 3.1 : 4.4,
            children: [
              for (final feature in _featureKeys)
                _FeatureToggleCard(
                  company: company,
                  feature: feature,
                  state: state,
                ),
            ],
          );
        },
      ),
    );
  }
}

class _FeatureToggleCard extends StatelessWidget {
  const _FeatureToggleCard({
    required this.company,
    required this.feature,
    required this.state,
  });

  final CompanyMetadata company;
  final String feature;
  final PlatformState state;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final actionId = 'feature:$feature';
    final enabled = _featureEnabled(company, feature);
    final busy = state.activeSettingsActionId == actionId;

    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.appBackground(context),
        border: Border.all(color: AppColors.borderColor(context)),
        borderRadius: AppRadius.large,
      ),
      child: Row(
        children: [
          Icon(
            enabled ? Icons.toggle_on_outlined : Icons.toggle_off_outlined,
            color: enabled
                ? AppColors.successColor(context)
                : AppColors.textSecondaryColor(context),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _featureLabel(l, feature),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  enabled ? l.featureEnabled : l.featureDisabled,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondaryColor(context),
                  ),
                ),
              ],
            ),
          ),
          if (busy)
            const SizedBox.square(
              dimension: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Switch(
              value: enabled,
              onChanged: state.status == PlatformStatus.saving
                  ? null
                  : (value) async {
                      final success = await context
                          .read<PlatformCubit>()
                          .updateCompanyPlatformSettings(
                            companyId: company.id,
                            features: {feature: value},
                            actionId: actionId,
                          );
                      if (context.mounted && success) {
                        AppFeedback.success(context, l.settingsSaved);
                      }
                    },
            ),
        ],
      ),
    );
  }
}

class _CompanyLimitsPanel extends StatelessWidget {
  const _CompanyLimitsPanel({required this.state});

  final PlatformState state;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final company = state.selectedCompany;
    if (company == null) {
      return _Panel(
        title: l.companyLimits,
        child: AppEmptyState(
          icon: Icons.speed_outlined,
          title: l.noCompanySelected,
          message: l.noCompanySelectedMessage,
        ),
      );
    }

    return _Panel(
      title: l.companyLimits,
      action: AppButton(
        label: l.editCompanySettings,
        icon: Icons.edit_outlined,
        variant: AppButtonVariant.secondary,
        onPressed: state.status == PlatformStatus.saving
            ? null
            : () => _showEditCompanySettingsDialog(context, company),
      ),
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          _InfoChip(
            label: l.usersUsed,
            value: _usersUsedLabel(context, state, company),
          ),
          _InfoChip(
            label: l.userLimit,
            value: _limitLabel(context, company.limits['users']),
          ),
          _InfoChip(
            label: l.storageLimitMb,
            value: _limitLabel(context, company.limits['storageMb']),
          ),
        ],
      ),
    );
  }
}

class _CompanyPreviewPanel extends StatelessWidget {
  const _CompanyPreviewPanel({required this.state});

  final PlatformState state;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final company = state.selectedCompany;
    if (company == null) {
      return _Panel(
        title: l.companyDashboardPreview,
        child: AppEmptyState(
          icon: Icons.dashboard_customize_outlined,
          title: l.noCompanySelected,
          message: l.noCompanySelectedMessage,
        ),
      );
    }

    return _Panel(
      title: l.companyDashboardPreview,
      action: AppButton(
        label: l.previewDashboard,
        icon: Icons.dashboard_customize_outlined,
        onPressed: () => _openPreview(context, company),
      ),
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          AppStatusBadge(label: l.readOnlyPreview, tone: AppStatusTone.info),
          _InfoChip(label: l.companyName, value: _companyTitle(company)),
          _InfoChip(label: l.companyIdSlug, value: company.id),
          _InfoChip(label: l.status, value: _statusLabel(l, company)),
        ],
      ),
    );
  }
}

class _CompanyMetadataSections extends StatelessWidget {
  const _CompanyMetadataSections({required this.company});

  final CompanyMetadata company;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final locale = company.settings['locale']?.toString() ?? l.notAvailable;
    final timezone = company.settings['timezone']?.toString() ?? l.notAvailable;
    final userLimit = company.limits['users']?.toString() ?? l.notAvailable;
    final storageLimit =
        company.limits['storageMb']?.toString() ?? l.notAvailable;

    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 720;
        final sections = [
          _MiniSection(
            title: l.companySettings,
            children: [
              _InfoChip(label: l.locale, value: locale),
              _InfoChip(label: l.timezone, value: timezone),
            ],
          ),
          _MiniSection(
            title: l.companyLimits,
            children: [
              _InfoChip(label: l.userLimit, value: userLimit),
              _InfoChip(label: l.storageLimitMb, value: storageLimit),
            ],
          ),
          _MiniSection(
            title: l.companyFeatures,
            children: [
              for (final feature in _featureKeys)
                _FeatureChip(
                  label: _featureLabel(l, feature),
                  enabled: company.features[feature] as bool? ?? false,
                ),
            ],
          ),
        ];

        if (narrow) {
          return Column(
            children: [
              for (final section in sections) ...[
                section,
                if (section != sections.last)
                  const SizedBox(height: AppSpacing.sm),
              ],
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final section in sections) ...[
              Expanded(child: section),
              if (section != sections.last)
                const SizedBox(width: AppSpacing.sm),
            ],
          ],
        );
      },
    );
  }
}

class _MiniSection extends StatelessWidget {
  const _MiniSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.appBackground(context),
        border: Border.all(color: AppColors.borderColor(context)),
        borderRadius: AppRadius.large,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: children,
          ),
        ],
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  const _FeatureChip({required this.label, required this.enabled});

  final String label;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return AppStatusBadge(
      label: label,
      tone: enabled ? AppStatusTone.success : AppStatusTone.neutral,
    );
  }
}

class _CompanyTile extends StatelessWidget {
  const _CompanyTile({
    required this.company,
    required this.selected,
    required this.onTap,
  });

  final CompanyMetadata company;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: selected
            ? AppColors.primaryColor(context).withValues(alpha: 0.10)
            : AppColors.cardSurface(context),
        borderRadius: AppRadius.large,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.large,
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              border: Border.all(
                color: selected
                    ? AppColors.primaryColor(context)
                    : AppColors.borderColor(context),
              ),
              borderRadius: AppRadius.large,
            ),
            child: Row(
              children: [
                Icon(Icons.apartment, color: colors.primary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        company.displayName.isEmpty
                            ? company.name
                            : company.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${company.id} - ${_statusLabel(l, company)}',
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
            ),
          ),
        ),
      ),
    );
  }
}

class _UsersTable extends StatelessWidget {
  const _UsersTable({
    required this.companyId,
    required this.users,
    required this.activeUserActionId,
  });

  final String companyId;
  final List<PlatformCompanyUser> users;
  final String? activeUserActionId;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return ListView.builder(
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        final isBusy = activeUserActionId == user.uid;
        return Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.cardSurface(context),
              border: Border.all(color: AppColors.borderColor(context)),
              borderRadius: AppRadius.large,
            ),
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                CircleAvatar(
                  child: Text(_initialFor(user.fullName)),
                ),
                SizedBox(
                  width: 280,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.fullName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        '${user.email} - ${_roleLabel(l, user.role)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondaryColor(context),
                        ),
                      ),
                    ],
                  ),
                ),
                AppStatusBadge(
                  label: user.isActive ? l.active : l.inactive,
                  tone: user.isActive
                      ? AppStatusTone.success
                      : AppStatusTone.neutral,
                ),
                AppButton(
                  label: user.isActive ? l.deactivateUser : l.activateUser,
                  icon: user.isActive ? Icons.block : Icons.check_circle_outline,
                  variant: user.isActive
                      ? AppButtonVariant.danger
                      : AppButtonVariant.secondary,
                  isLoading: isBusy,
                  onPressed: isBusy
                      ? null
                      : () async {
                          final success = await context
                              .read<PlatformCubit>()
                              .setCompanyUserActiveStatus(
                                companyId: companyId,
                                uid: user.uid,
                                isActive: !user.isActive,
                              );
                          if (context.mounted && success) {
                            AppFeedback.success(context, l.savedSuccessfully);
                          }
                        },
                ),
              ],
            ),
          );
      },
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.title, required this.child, this.action});

  final String title;
  final Widget child;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.cardSurface(context),
        border: Border.all(color: AppColors.borderColor(context)),
        borderRadius: AppRadius.xLarge,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 180, maxWidth: 520),
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (action != null) action!,
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.appBackground(context),
        border: Border.all(color: AppColors.borderColor(context)),
        borderRadius: AppRadius.large,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondaryColor(context),
            ),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 260),
            child: Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _showCreateCompanyDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (_) => _CreateCompanyDialog(cubit: context.read<PlatformCubit>()),
  );
}

Future<void> _showAddUserDialog(BuildContext context, String companyId) {
  return showDialog<void>(
    context: context,
    builder: (_) => _AddUserDialog(
      cubit: context.read<PlatformCubit>(),
      companyId: companyId,
    ),
  );
}

Future<void> _showEditCompanySettingsDialog(
  BuildContext context,
  CompanyMetadata company,
) {
  return showDialog<void>(
    context: context,
    builder: (_) => _EditCompanySettingsDialog(
      cubit: context.read<PlatformCubit>(),
      company: company,
    ),
  );
}

class _EditCompanySettingsDialog extends StatefulWidget {
  const _EditCompanySettingsDialog({
    required this.cubit,
    required this.company,
  });

  final PlatformCubit cubit;
  final CompanyMetadata company;

  @override
  State<_EditCompanySettingsDialog> createState() =>
      _EditCompanySettingsDialogState();
}

class _EditCompanySettingsDialogState
    extends State<_EditCompanySettingsDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _companyName;
  late final TextEditingController _displayName;
  late final TextEditingController _timezone;
  late final TextEditingController _userLimit;
  late final TextEditingController _storageLimit;
  late String _locale;
  late String _status;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    final company = widget.company;
    _companyName = TextEditingController(text: company.name);
    _displayName = TextEditingController(
      text: company.displayName.isEmpty ? company.name : company.displayName,
    );
    _timezone = TextEditingController(
      text: company.settings['timezone']?.toString() ?? 'Africa/Cairo',
    );
    _userLimit = TextEditingController(
      text: (_limitValue(company.limits['users']) ?? 25).toString(),
    );
    _storageLimit = TextEditingController(
      text: (_limitValue(company.limits['storageMb']) ?? 1024).toString(),
    );
    _locale = _localeValue(company);
    _status = company.status == 'trial'
        ? 'trial'
        : (_isOperationalCompany(company) ? 'active' : 'inactive');
  }

  @override
  void dispose() {
    _companyName.dispose();
    _displayName.dispose();
    _timezone.dispose();
    _userLimit.dispose();
    _storageLimit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(l.editCompanySettings),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppTextField(
                  controller: _companyName,
                  label: l.companyName,
                  enabled: !_saving,
                  validator: (value) => _required(value, l),
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: _displayName,
                  label: l.companyDisplayName,
                  enabled: !_saving,
                  validator: (value) => _required(value, l),
                ),
                const SizedBox(height: AppSpacing.md),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final narrow = constraints.maxWidth < 520;
                    final status = AppDropdown<String>(
                      label: l.status,
                      value: _status,
                      items: const ['active', 'trial', 'inactive'],
                      itemLabelBuilder: (value) =>
                          _companyStatusOptionLabel(l, value),
                      enabled: !_saving,
                      onChanged: (value) => setState(() => _status = value),
                    );
                    final locale = AppDropdown<String>(
                      label: l.locale,
                      value: _locale,
                      items: const ['en', 'ar'],
                      itemLabelBuilder: (value) =>
                          value == 'ar' ? l.arabic : l.english,
                      enabled: !_saving,
                      onChanged: (value) => setState(() => _locale = value),
                    );

                    if (narrow) {
                      return Column(
                        children: [
                          status,
                          const SizedBox(height: AppSpacing.md),
                          locale,
                        ],
                      );
                    }

                    return Row(
                      children: [
                        Expanded(child: status),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(child: locale),
                      ],
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: _timezone,
                  label: l.timezone,
                  enabled: !_saving,
                  validator: (value) => _required(value, l),
                ),
                const SizedBox(height: AppSpacing.md),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final narrow = constraints.maxWidth < 520;
                    final users = AppTextField(
                      controller: _userLimit,
                      label: l.userLimit,
                      keyboardType: TextInputType.number,
                      enabled: !_saving,
                      validator: (value) => _positiveInteger(value, l),
                    );
                    final storage = AppTextField(
                      controller: _storageLimit,
                      label: l.storageLimitMb,
                      keyboardType: TextInputType.number,
                      enabled: !_saving,
                      validator: (value) => _positiveInteger(value, l),
                    );

                    if (narrow) {
                      return Column(
                        children: [
                          users,
                          const SizedBox(height: AppSpacing.md),
                          storage,
                        ],
                      );
                    }

                    return Row(
                      children: [
                        Expanded(child: users),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(child: storage),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: Text(l.cancel),
        ),
        AppButton(
          label: l.saveSettings,
          isLoading: _saving,
          onPressed: _saving ? null : _submit,
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _saving = true);
    final success = await widget.cubit.updateCompanyPlatformSettings(
      companyId: widget.company.id,
      name: _companyName.text.trim(),
      displayName: _displayName.text.trim(),
      status: _status,
      isActive: _status != 'inactive',
      settings: {
        'locale': _locale,
        'timezone': _timezone.text.trim(),
      },
      limits: {
        'users': int.parse(_userLimit.text.trim()),
        'storageMb': int.parse(_storageLimit.text.trim()),
      },
      actionId: 'settings',
    );
    if (!mounted) {
      return;
    }

    setState(() => _saving = false);
    if (success) {
      AppFeedback.success(context, AppLocalizations.of(context)!.settingsSaved);
      Navigator.of(context).pop();
    }
  }
}

class _CreateCompanyDialog extends StatefulWidget {
  const _CreateCompanyDialog({required this.cubit});

  final PlatformCubit cubit;

  @override
  State<_CreateCompanyDialog> createState() => _CreateCompanyDialogState();
}

class _CreateCompanyDialogState extends State<_CreateCompanyDialog> {
  final _formKey = GlobalKey<FormState>();
  final _companyName = TextEditingController();
  final _companyId = TextEditingController();
  final _adminName = TextEditingController();
  final _adminEmail = TextEditingController();
  final _adminPhone = TextEditingController();
  final _timezone = TextEditingController(text: 'Africa/Cairo');
  var _locale = 'en';
  var _saving = false;

  @override
  void dispose() {
    _companyName.dispose();
    _companyId.dispose();
    _adminName.dispose();
    _adminEmail.dispose();
    _adminPhone.dispose();
    _timezone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l.createCompany),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppTextField(
                  controller: _companyName,
                  label: l.companyName,
                  enabled: !_saving,
                  validator: (value) => _required(value, l),
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: _companyId,
                  label: l.companyIdSlug,
                  enabled: !_saving,
                  validator: (value) => _required(value, l),
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: _adminName,
                  label: l.firstAdminFullName,
                  enabled: !_saving,
                  validator: (value) => _required(value, l),
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: _adminEmail,
                  label: l.firstAdminEmail,
                  keyboardType: TextInputType.emailAddress,
                  enabled: !_saving,
                  validator: (value) => _required(value, l),
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: _adminPhone,
                  label: l.firstAdminPhone,
                  keyboardType: TextInputType.phone,
                  enabled: !_saving,
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: AppDropdown<String>(
                        label: l.defaultLocale,
                        value: _locale,
                        items: const ['en', 'ar'],
                        itemLabelBuilder: (value) =>
                            value == 'ar' ? l.arabic : l.english,
                        enabled: !_saving,
                        onChanged: (value) => setState(() => _locale = value),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: AppTextField(
                        controller: _timezone,
                        label: l.timezone,
                        enabled: !_saving,
                        validator: (value) => _required(value, l),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: Text(l.cancel),
        ),
        AppButton(
          label: l.createCompany,
          isLoading: _saving,
          onPressed: _saving ? null : _submit,
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _saving = true);
    final success = await widget.cubit.createCompanyWithAdmin(
      companyId: _companyId.text.trim(),
      companyName: _companyName.text.trim(),
      adminFullName: _adminName.text.trim(),
      adminEmail: _adminEmail.text.trim(),
      adminPhone: _adminPhone.text.trim(),
      locale: _locale,
      timezone: _timezone.text.trim(),
    );
    if (!mounted) {
      return;
    }
    setState(() => _saving = false);
    if (success) {
      AppFeedback.success(
        context,
        AppLocalizations.of(context)!.createCompanySuccess,
      );
      Navigator.of(context).pop();
    }
  }
}

class _AddUserDialog extends StatefulWidget {
  const _AddUserDialog({required this.cubit, required this.companyId});

  final PlatformCubit cubit;
  final String companyId;

  @override
  State<_AddUserDialog> createState() => _AddUserDialogState();
}

class _AddUserDialogState extends State<_AddUserDialog> {
  final _formKey = GlobalKey<FormState>();
  final _fullName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  var _role = UserRole.salesAgent;
  var _saving = false;

  @override
  void dispose() {
    _fullName.dispose();
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l.addUser),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppTextField(
                  controller: _fullName,
                  label: l.fullName,
                  enabled: !_saving,
                  validator: (value) => _required(value, l),
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: _email,
                  label: l.email,
                  keyboardType: TextInputType.emailAddress,
                  enabled: !_saving,
                  validator: (value) => _required(value, l),
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: _phone,
                  label: l.phone,
                  keyboardType: TextInputType.phone,
                  enabled: !_saving,
                ),
                const SizedBox(height: AppSpacing.md),
                AppDropdown<UserRole>(
                  label: l.role,
                  value: _role,
                  items: UserRole.values,
                  itemLabelBuilder: (role) => _roleLabel(l, role),
                  enabled: !_saving,
                  onChanged: (role) => setState(() => _role = role),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: Text(l.cancel),
        ),
        AppButton(
          label: l.addUser,
          isLoading: _saving,
          onPressed: _saving ? null : _submit,
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _saving = true);
    final success = await widget.cubit.addUserToCompany(
      companyId: widget.companyId,
      fullName: _fullName.text.trim(),
      email: _email.text.trim(),
      phone: _phone.text.trim(),
      role: _role,
    );
    if (!mounted) {
      return;
    }
    setState(() => _saving = false);
    if (success) {
      AppFeedback.success(context, AppLocalizations.of(context)!.addUserSuccess);
      Navigator.of(context).pop();
    }
  }
}

String _statusLabel(AppLocalizations l, CompanyMetadata company) {
  if (!company.isActive || company.status == 'inactive') {
    return l.inactive;
  }
  if (company.status == 'trial') {
    return l.trial;
  }
  return l.active;
}

bool _isOperationalCompany(CompanyMetadata company) {
  return company.isActive && company.status != 'inactive';
}

String _companyFilterLabel(AppLocalizations l, PlatformCompanyFilter filter) {
  return switch (filter) {
    PlatformCompanyFilter.all => l.allCompanies,
    PlatformCompanyFilter.active => l.active,
    PlatformCompanyFilter.inactive => l.inactive,
    PlatformCompanyFilter.trial => l.trial,
  };
}

String _sectionLabel(AppLocalizations l, _PlatformSection section) {
  return switch (section) {
    _PlatformSection.overview => l.platformOverview,
    _PlatformSection.companies => l.platformCompanies,
    _PlatformSection.details => l.companyDetails,
    _PlatformSection.users => l.companyUsers,
    _PlatformSection.settings => l.companySettings,
    _PlatformSection.features => l.companyFeatures,
    _PlatformSection.limits => l.companyLimits,
    _PlatformSection.preview => l.companyDashboardPreview,
  };
}

IconData _sectionIcon(_PlatformSection section) {
  return switch (section) {
    _PlatformSection.overview => Icons.space_dashboard_outlined,
    _PlatformSection.companies => Icons.apartment_outlined,
    _PlatformSection.details => Icons.badge_outlined,
    _PlatformSection.users => Icons.people_outline,
    _PlatformSection.settings => Icons.tune,
    _PlatformSection.features => Icons.extension_outlined,
    _PlatformSection.limits => Icons.speed_outlined,
    _PlatformSection.preview => Icons.dashboard_customize_outlined,
  };
}

const _featureKeys = [
  'leads',
  'clients',
  'properties',
  'tasks',
  'deals',
  'reports',
  'auditLogs',
  'notifications',
];

String _featureLabel(AppLocalizations l, String feature) {
  return switch (feature) {
    'leads' => l.leads,
    'clients' => l.clients,
    'properties' => l.properties,
    'tasks' => l.tasks,
    'deals' => l.deals,
    'reports' => l.reports,
    'auditLogs' => l.auditLogs,
    'notifications' => l.notifications,
    _ => feature,
  };
}

bool _featureEnabled(CompanyMetadata company, String feature) {
  return company.features[feature] as bool? ?? true;
}

String _companyTitle(CompanyMetadata company) {
  return company.displayName.trim().isEmpty
      ? company.name
      : company.displayName;
}

void _openPreview(BuildContext context, CompanyMetadata company) {
  final name = Uri.encodeComponent(_companyTitle(company));
  context.go('${RouteNames.platformCompanyDashboard(company.id)}?name=$name');
}

int? _limitValue(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    return int.tryParse(value);
  }
  return null;
}

String _limitLabel(BuildContext context, Object? value) {
  return _limitValue(value)?.toString() ??
      AppLocalizations.of(context)!.notAvailable;
}

String _usersUsedLabel(
  BuildContext context,
  PlatformState state,
  CompanyMetadata company,
) {
  final limit = _limitValue(company.limits['users']);
  if (limit == null) {
    return state.companyUsers.length.toString();
  }
  return '${state.companyUsers.length} / $limit';
}

String _localeValue(CompanyMetadata company) {
  final locale = company.settings['locale']?.toString();
  return locale == 'ar' ? 'ar' : 'en';
}

String _companyStatusOptionLabel(AppLocalizations l, String status) {
  return switch (status) {
    'active' => l.active,
    'trial' => l.trial,
    'inactive' => l.inactive,
    _ => status,
  };
}

Color _toneColor(BuildContext context, AppStatusTone tone) {
  return switch (tone) {
    AppStatusTone.success => AppColors.successColor(context),
    AppStatusTone.warning => AppColors.warningColor(context),
    AppStatusTone.error => AppColors.errorColor(context),
    AppStatusTone.info => AppColors.infoColor(context),
    AppStatusTone.neutral => AppColors.primaryColor(context),
  };
}

String _roleLabel(AppLocalizations l, UserRole role) {
  switch (role) {
    case UserRole.admin:
      return l.admin;
    case UserRole.manager:
      return l.manager;
    case UserRole.salesAgent:
      return l.salesAgent;
    case UserRole.marketing:
      return l.marketing;
    case UserRole.viewer:
      return l.viewer;
  }
}

String _initialFor(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return 'U';
  }
  return trimmed.substring(0, 1).toUpperCase();
}

String _formatDate(BuildContext context, DateTime value) {
  final localeName = Localizations.localeOf(context).toString();
  return DateFormat.yMd(localeName).add_jm().format(value.toLocal());
}

String? _required(String? value, AppLocalizations l) {
  return (value ?? '').trim().isEmpty ? l.requiredField : null;
}

String? _positiveInteger(String? value, AppLocalizations l) {
  final parsed = int.tryParse((value ?? '').trim());
  return parsed == null || parsed <= 0 ? l.enterValidNumber : null;
}
