import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/role_constants.dart';
import '../../../../core/localization/locale_cubit.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../../core/utils/validators.dart';
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
import '../../../auth/presentation/widgets/change_password_dialog.dart';
import '../../../platform_invitations/data/datasources/platform_invitations_remote_data_source.dart';
import '../../../platform_invitations/data/repositories/platform_invitation_repository_impl.dart';
import '../../../platform_invitations/domain/entities/platform_invitation.dart';
import '../../../platform_invitations/domain/usecases/create_company_invitation_usecase.dart';
import '../../../platform_invitations/domain/usecases/list_company_invitations_usecase.dart';
import '../../../platform_invitations/domain/usecases/revoke_company_invitation_usecase.dart';
import '../../../platform_invitations/presentation/cubit/platform_invitations_cubit.dart';
import '../../../platform_invitations/presentation/cubit/platform_invitations_state.dart';
import '../../../platform_notifications/data/datasources/platform_notifications_remote_data_source.dart';
import '../../../platform_notifications/data/repositories/platform_notification_repository_impl.dart';
import '../../../platform_notifications/domain/usecases/mark_all_platform_notifications_read_usecase.dart';
import '../../../platform_notifications/domain/usecases/mark_platform_notification_read_usecase.dart';
import '../../../platform_notifications/domain/usecases/watch_platform_notifications_usecase.dart';
import '../../../platform_notifications/domain/usecases/watch_platform_unread_notifications_count_usecase.dart';
import '../../../platform_notifications/presentation/cubit/platform_notifications_cubit.dart';
import '../../../platform_notifications/presentation/widgets/platform_notifications_panel.dart';
import '../../../support/presentation/pages/platform_support_inbox_panel.dart';
import '../../domain/entities/company_data_health_report.dart';
import '../../../users/domain/entities/company_metadata.dart';
import '../../data/datasources/platform_remote_data_source.dart';
import '../../data/repositories/platform_repository_impl.dart';
import '../../domain/entities/platform_company_user.dart';
import '../../domain/usecases/add_user_to_company_usecase.dart';
import '../../domain/usecases/backfill_assigned_record_snapshots_usecase.dart';
import '../../domain/usecases/create_company_with_admin_usecase.dart';
import '../../domain/usecases/get_company_data_health_report_usecase.dart';
import '../../domain/usecases/generate_company_user_password_reset_link_usecase.dart';
import '../../domain/usecases/refresh_company_storage_usage_usecase.dart';
import '../../domain/usecases/set_company_active_status_usecase.dart';
import '../../domain/usecases/set_company_user_active_status_usecase.dart';
import '../../domain/usecases/set_company_user_email_usecase.dart';
import '../../domain/usecases/set_company_user_password_usecase.dart';
import '../../domain/usecases/update_company_platform_settings_usecase.dart';
import '../../domain/usecases/watch_platform_companies_usecase.dart';
import '../../domain/usecases/watch_platform_company_users_usecase.dart';
import '../cubit/platform_cubit.dart';
import '../cubit/platform_state.dart';

class PlatformPage extends StatelessWidget {
  const PlatformPage({
    super.key,
    this.initialSupportInbox = false,
    this.initialNotifications = false,
  });

  final bool initialSupportInbox;
  final bool initialNotifications;

  static Widget withDependencies({
    bool initialSupportInbox = false,
    bool initialNotifications = false,
  }) {
    final remoteDataSource = FirebasePlatformRemoteDataSource();
    final repository = PlatformRepositoryImpl(
      remoteDataSource: remoteDataSource,
    );
    final invitationsRemoteDataSource =
        FirebasePlatformInvitationsRemoteDataSource();
    final invitationsRepository = PlatformInvitationRepositoryImpl(
      remoteDataSource: invitationsRemoteDataSource,
    );
    final notificationsRemoteDataSource =
        FirestorePlatformNotificationsRemoteDataSource();
    final notificationsRepository = PlatformNotificationRepositoryImpl(
      remoteDataSource: notificationsRemoteDataSource,
    );

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => PlatformCubit(
            watchCompaniesUseCase: WatchPlatformCompaniesUseCase(repository),
            watchCompanyUsersUseCase: WatchPlatformCompanyUsersUseCase(
              repository,
            ),
            createCompanyWithAdminUseCase: CreateCompanyWithAdminUseCase(
              repository,
            ),
            addUserToCompanyUseCase: AddUserToCompanyUseCase(repository),
            setCompanyActiveStatusUseCase: SetCompanyActiveStatusUseCase(
              repository,
            ),
            setCompanyUserActiveStatusUseCase:
                SetCompanyUserActiveStatusUseCase(repository),
            setCompanyUserEmailUseCase: SetCompanyUserEmailUseCase(repository),
            setCompanyUserPasswordUseCase: SetCompanyUserPasswordUseCase(
              repository,
            ),
            generateCompanyUserPasswordResetLinkUseCase:
                GenerateCompanyUserPasswordResetLinkUseCase(repository),
            updateCompanyPlatformSettingsUseCase:
                UpdateCompanyPlatformSettingsUseCase(repository),
            getCompanyDataHealthReportUseCase:
                GetCompanyDataHealthReportUseCase(repository),
            backfillAssignedRecordSnapshotsUseCase:
                BackfillAssignedRecordSnapshotsUseCase(repository),
            refreshCompanyStorageUsageUseCase:
                RefreshCompanyStorageUsageUseCase(repository),
          )..watchCompanies(),
        ),
        BlocProvider(
          create: (_) => PlatformInvitationsCubit(
            createCompanyInvitationUseCase:
                CreateCompanyInvitationUseCase(invitationsRepository),
            listCompanyInvitationsUseCase:
                ListCompanyInvitationsUseCase(invitationsRepository),
            revokeCompanyInvitationUseCase:
                RevokeCompanyInvitationUseCase(invitationsRepository),
          )..loadInvitations(),
        ),
        BlocProvider(
          create: (_) => PlatformNotificationsCubit(
            watchNotificationsUseCase:
                WatchPlatformNotificationsUseCase(notificationsRepository),
            watchUnreadCountUseCase:
                WatchPlatformUnreadNotificationsCountUseCase(
              notificationsRepository,
            ),
            markNotificationReadUseCase:
                MarkPlatformNotificationReadUseCase(notificationsRepository),
            markAllReadUseCase:
                MarkAllPlatformNotificationsReadUseCase(
              notificationsRepository,
            ),
          )..watch(),
        ),
      ],
      child: PlatformPage(
        initialSupportInbox: initialSupportInbox,
        initialNotifications: initialNotifications,
      ),
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

                      return _PlatformWorkspace(
                        state: state,
                        initialSupportInbox: initialSupportInbox,
                        initialNotifications: initialNotifications,
                      );
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
          final adminPhotoUrl = (authState.user?.photoUrl ?? '').trim();

          return Row(
            children: [
              _PlatformAvatar(name: adminName, photoUrl: adminPhotoUrl),
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
                  width: 360,
                  child: AppSearchField(
                    hint: l.platformSearchHint,
                    onChanged: context.read<PlatformCubit>().updateSearchQuery,
                    onClear: () => context.read<PlatformCubit>().updateSearchQuery(''),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
              PlatformNotificationsBell(
                onPressed: () => context.go(RouteNames.platformNotifications),
              ),
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

enum _PlatformProfileAction { profile, settings, logout }

class _PlatformProfileMenu extends StatelessWidget {
  const _PlatformProfileMenu();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final userName = _platformUserName(authState, l.platformAdmin);
        final email = (authState.user?.email ?? '').trim();
        final photoUrl = (authState.user?.photoUrl ?? '').trim();

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
              case _PlatformProfileAction.profile:
                context.go(RouteNames.profile);
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
                  _PlatformAvatar(name: userName, photoUrl: photoUrl),
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
              value: _PlatformProfileAction.profile,
              child: _PlatformProfileMenuTile(
                icon: Icons.person_outline,
                label: l.profile,
              ),
            ),
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
              child: _PlatformAvatar(name: userName, photoUrl: photoUrl),
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
  const _PlatformAvatar({required this.name, this.photoUrl = ''});

  final String name;
  final String photoUrl;

  @override
  Widget build(BuildContext context) {
    final cleanUrl = photoUrl.trim();
    final fallback = CircleAvatar(
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

    if (cleanUrl.isEmpty) {
      return fallback;
    }

    return ClipOval(
      child: SizedBox(
        width: 36,
        height: 36,
        child: Image.network(
          cleanUrl,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
          errorBuilder: (_, __, ___) => fallback,
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
                label: l.changePassword,
                icon: Icons.lock_reset,
                variant: AppButtonVariant.secondary,
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  showChangePasswordDialog(context);
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
  notifications,
  invitations,
  companies,
  workspace,
  support,
  activity,
}

enum _WorkspaceTab {
  summary,
  users,
  features,
  limits,
  settings,
  maintenance,
  preview,
}

class _PlatformWorkspace extends StatefulWidget {
  const _PlatformWorkspace({
    required this.state,
    required this.initialSupportInbox,
    required this.initialNotifications,
  });

  final PlatformState state;
  final bool initialSupportInbox;
  final bool initialNotifications;

  @override
  State<_PlatformWorkspace> createState() => _PlatformWorkspaceState();
}

class _PlatformWorkspaceState extends State<_PlatformWorkspace> {
  late _PlatformSection _section;

  @override
  void initState() {
    super.initState();
    _section = widget.initialNotifications
        ? _PlatformSection.notifications
        : widget.initialSupportInbox
            ? _PlatformSection.support
            : _PlatformSection.overview;
  }

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
        _PlatformDashboardOverview(
          state: state,
          onOpenCompanies: () => onSectionSelected(_PlatformSection.companies),
          onOpenWorkspace: () => onSectionSelected(_PlatformSection.workspace),
          onOpenActivity: () => onSectionSelected(_PlatformSection.activity),
        ),
      ],
      _PlatformSection.invitations => const [_PlatformInvitationsPanel()],
      _PlatformSection.notifications => const [PlatformNotificationsPanel()],
      _PlatformSection.companies => [
        _CompaniesPanel(
          state: state,
          onOpenWorkspace: () => onSectionSelected(_PlatformSection.workspace),
        ),
      ],
      _PlatformSection.workspace => [_CompanyWorkspacePanel(state: state)],
      _PlatformSection.support => [
        PlatformSupportInboxPanel.withDependencies(companies: state.companies),
      ],
      _PlatformSection.activity => [_PlatformActivityPanel(state: state)],
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

class _PlatformDashboardOverview extends StatelessWidget {
  const _PlatformDashboardOverview({
    required this.state,
    required this.onOpenCompanies,
    required this.onOpenWorkspace,
    required this.onOpenActivity,
  });

  final PlatformState state;
  final VoidCallback onOpenCompanies;
  final VoidCallback onOpenWorkspace;
  final VoidCallback onOpenActivity;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PlatformHeroCard(state: state),
        const SizedBox(height: AppSpacing.md),
        _PlatformCurrentCompanySelector(state: state),
        const SizedBox(height: AppSpacing.md),
        _PlatformKpis(state: state),
        const SizedBox(height: AppSpacing.md),
        LayoutBuilder(
          builder: (context, constraints) {
            final narrow = constraints.maxWidth < 1040;
            final main = Column(
              children: [
                _SelectedCompanyDashboardCard(
                  state: state,
                  onOpenWorkspace: onOpenWorkspace,
                ),
                const SizedBox(height: AppSpacing.md),
                _DashboardCompaniesPanel(
                  state: state,
                  onOpenCompanies: onOpenCompanies,
                  onOpenWorkspace: onOpenWorkspace,
                ),
              ],
            );
            final side = Column(
              children: [
                _DashboardActivityPanel(
                  state: state,
                  onOpenActivity: onOpenActivity,
                ),
                const SizedBox(height: AppSpacing.md),
                _WorkspaceSummaryPanel(state: state),
              ],
            );

            if (narrow) {
              return Column(
                children: [
                  main,
                  const SizedBox(height: AppSpacing.md),
                  side,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 7, child: main),
                const SizedBox(width: AppSpacing.md),
                Expanded(flex: 5, child: side),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _PlatformHeroCard extends StatelessWidget {
  const _PlatformHeroCard({required this.state});

  final PlatformState state;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final authState = context.watch<AuthBloc>().state;
    final adminName = _platformUserName(authState, l.platformAdmin);
    final adminEmail = (authState.user?.email ?? '').trim();
    final photoUrl = (authState.user?.photoUrl ?? '').trim();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.cardSurface(context),
        border: Border.all(color: AppColors.borderColor(context)),
        borderRadius: AppRadius.xLarge,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 720;
          final titleBlock = Row(
            children: [
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primaryColor(context).withValues(alpha: .14),
                  borderRadius: AppRadius.large,
                ),
                child: Icon(
                  Icons.workspace_premium_outlined,
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
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l.platformDashboardHeroSubtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondaryColor(context),
                          ),
                    ),
                  ],
                ),
              ),
            ],
          );
          final ownerChip = _OwnerProfileChip(
            name: adminName,
            email: adminEmail,
            photoUrl: photoUrl,
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                titleBlock,
                const SizedBox(height: AppSpacing.md),
                ownerChip,
              ],
            );
          }
          return Row(
            children: [
              Expanded(child: titleBlock),
              const SizedBox(width: AppSpacing.md),
              ownerChip,
            ],
          );
        },
      ),
    );
  }
}

class _OwnerProfileChip extends StatelessWidget {
  const _OwnerProfileChip({
    required this.name,
    required this.email,
    required this.photoUrl,
  });

  final String name;
  final String email;
  final String photoUrl;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.sm,
        AppSpacing.xs,
        AppSpacing.md,
        AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.inputSurface(context),
        border: Border.all(color: AppColors.borderColor(context)),
        borderRadius: AppRadius.large,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PlatformAvatar(name: name, photoUrl: photoUrl),
          const SizedBox(width: AppSpacing.sm),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 220),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.platformOwnerGreeting(name),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                if (email.isNotEmpty)
                  Text(
                    _directionalIsolate(email),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondaryColor(context),
                        ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Icon(Icons.circle, color: AppColors.successColor(context), size: 10),
        ],
      ),
    );
  }
}

class _PlatformCurrentCompanySelector extends StatelessWidget {
  const _PlatformCurrentCompanySelector({required this.state});

  final PlatformState state;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final selected = state.selectedCompany;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.cardSurface(context),
        border: Border.all(color: AppColors.borderColor(context)),
        borderRadius: AppRadius.xLarge,
      ),
      child: Row(
        children: [
          Icon(Icons.apartment_outlined, color: AppColors.primaryColor(context)),
          const SizedBox(width: AppSpacing.sm),
          Text(
            l.platformCurrentCompany,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondaryColor(context),
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: AppDropdown<CompanyMetadata?>(
              label: l.platformCompanySelector,
              value: selected,
              items: <CompanyMetadata?>[...state.companies],
              itemLabelBuilder: (company) =>
                  company == null ? l.noCompanySelected : _companyTitle(company),
              onChanged: (company) {
                if (company != null) {
                  context.read<PlatformCubit>().selectCompany(company.id);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectedCompanyDashboardCard extends StatelessWidget {
  const _SelectedCompanyDashboardCard({
    required this.state,
    required this.onOpenWorkspace,
  });

  final PlatformState state;
  final VoidCallback onOpenWorkspace;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final company = state.selectedCompany;
    if (company == null) {
      return _Panel(
        title: l.platformSelectedCompany,
        child: AppEmptyState(
          icon: Icons.apartment_outlined,
          title: l.noCompanySelected,
          message: l.noCompanySelectedMessage,
        ),
      );
    }

    final active = _isOperationalCompany(company);
    final storageLimit = _limitValue(company.limits['storageMb']);

    return _Panel(
      title: _companyTitle(company),
      action: _SelectedCompanyActions(
        company: company,
        state: state,
        onOpenWorkspace: onOpenWorkspace,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primaryColor(context).withValues(alpha: .12),
                  borderRadius: AppRadius.large,
                ),
                child: Icon(
                  Icons.business_outlined,
                  color: AppColors.primaryColor(context),
                  size: 28,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    AppStatusBadge(
                      label: _statusLabel(l, company),
                      tone: active ? AppStatusTone.success : AppStatusTone.neutral,
                    ),
                    _InfoChip(label: l.companyIdSlug, value: company.id),
                    _InfoChip(
                      label: l.usersUsed,
                      value: _usersUsedLabel(context, state, company),
                    ),
                    _InfoChip(
                      label: l.createdAt,
                      value: _formatDate(context, company.createdAt),
                    ),
                    _InfoChip(
                      label: l.platformStorageUsage,
                      value: _storageUsageLabel(context, company, storageLimit),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            l.platformCompanyFeatures,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (final feature in _featureKeys)
                if (_featureEnabled(company, feature))
                  _FeatureChip(label: _featureLabel(l, feature), enabled: true),
            ],
          ),
        ],
      ),
    );
  }
}

class _SelectedCompanyActions extends StatelessWidget {
  const _SelectedCompanyActions({
    required this.company,
    required this.state,
    required this.onOpenWorkspace,
  });

  final CompanyMetadata company;
  final PlatformState state;
  final VoidCallback onOpenWorkspace;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: [
        AppButton(
          label: l.workspace,
          icon: Icons.view_quilt_outlined,
          variant: AppButtonVariant.secondary,
          onPressed: onOpenWorkspace,
        ),
        AppButton(
          label: l.previewDashboard,
          icon: Icons.dashboard_customize_outlined,
          variant: AppButtonVariant.secondary,
          onPressed: () => _openPreview(context, company),
        ),
        _CompanyMoreActionsMenu(company: company, state: state),
      ],
    );
  }
}

enum _CompanyMoreAction { settings, toggleActive }

class _CompanyMoreActionsMenu extends StatelessWidget {
  const _CompanyMoreActionsMenu({required this.company, required this.state});

  final CompanyMetadata company;
  final PlatformState state;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final active = _isOperationalCompany(company);
    final busy = state.activeCompanyActionId == company.id;
    return PopupMenuButton<_CompanyMoreAction>(
      tooltip: l.actions,
      enabled: !busy,
      icon: busy
          ? const SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.more_horiz),
      onSelected: (action) async {
        switch (action) {
          case _CompanyMoreAction.settings:
            await _showEditCompanySettingsDialog(context, company);
            return;
          case _CompanyMoreAction.toggleActive:
            final success = await context
                .read<PlatformCubit>()
                .setCompanyActiveStatus(
                  companyId: company.id,
                  isActive: !active,
                );
            if (context.mounted && success) {
              AppFeedback.success(context, l.savedSuccessfully);
            }
            return;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem<_CompanyMoreAction>(
          value: _CompanyMoreAction.settings,
          child: _MenuItem(icon: Icons.tune, label: l.companySettings),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<_CompanyMoreAction>(
          value: _CompanyMoreAction.toggleActive,
          child: _MenuItem(
            icon: active ? Icons.block : Icons.check_circle_outline,
            label: active ? l.deactivateCompany : l.activateCompany,
            danger: active,
          ),
        ),
      ],
    );
  }
}

class _DashboardCompaniesPanel extends StatefulWidget {
  const _DashboardCompaniesPanel({
    required this.state,
    required this.onOpenCompanies,
    required this.onOpenWorkspace,
  });

  final PlatformState state;
  final VoidCallback onOpenCompanies;
  final VoidCallback onOpenWorkspace;

  @override
  State<_DashboardCompaniesPanel> createState() => _DashboardCompaniesPanelState();
}

class _DashboardCompaniesPanelState extends State<_DashboardCompaniesPanel> {
  final _searchController = TextEditingController();
  PlatformCompanyFilter _filter = PlatformCompanyFilter.all;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final state = widget.state;
    final companies = _filteredCompanies(state.companies).take(6).toList();

    return _Panel(
      title: l.platformCompanies,
      action: AppButton(
        label: l.createCompany,
        icon: Icons.add_business,
        onPressed: state.status == PlatformStatus.saving
            ? null
            : () => _showCreateCompanyDialog(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _DashboardCompanyFilters(
            searchController: _searchController,
            filter: _filter,
            onSearchChanged: (_) => setState(() {}),
            onClearSearch: () {
              _searchController.clear();
              setState(() {});
            },
            onFilterChanged: (filter) => setState(() => _filter = filter),
          ),
          const SizedBox(height: AppSpacing.md),
          if (companies.isEmpty)
            AppEmptyState(
              icon: Icons.search_off_outlined,
              title: l.noCompaniesFound,
              message: l.noCompaniesFoundMessage,
            )
          else
            Column(
              children: [
                for (final company in companies) ...[
                  _DashboardCompanyRow(
                    company: company,
                    state: state,
                    selected: state.selectedCompany?.id == company.id,
                    onOpenWorkspace: () {
                      context.read<PlatformCubit>().selectCompany(company.id);
                      widget.onOpenWorkspace();
                    },
                  ),
                  if (company != companies.last)
                    const SizedBox(height: AppSpacing.xs),
                ],
              ],
            ),
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              onPressed: widget.onOpenCompanies,
              icon: const Icon(Icons.chevron_left),
              label: Text(l.platformViewAllCompanies),
            ),
          ),
        ],
      ),
    );
  }

  List<CompanyMetadata> _filteredCompanies(List<CompanyMetadata> companies) {
    final query = _searchController.text.trim().toLowerCase();
    return companies.where((company) {
      final matchesQuery = query.isEmpty ||
          company.id.toLowerCase().contains(query) ||
          company.name.toLowerCase().contains(query) ||
          company.displayName.toLowerCase().contains(query);
      final matchesFilter = switch (_filter) {
        PlatformCompanyFilter.all => true,
        PlatformCompanyFilter.active =>
          company.isActive && company.status != 'inactive',
        PlatformCompanyFilter.inactive =>
          !company.isActive || company.status == 'inactive',
        PlatformCompanyFilter.trial => company.status == 'trial',
      };
      return matchesQuery && matchesFilter;
    }).toList();
  }
}

class _DashboardCompanyFilters extends StatelessWidget {
  const _DashboardCompanyFilters({
    required this.searchController,
    required this.filter,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onFilterChanged,
  });

  final TextEditingController searchController;
  final PlatformCompanyFilter filter;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final ValueChanged<PlatformCompanyFilter> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return LayoutBuilder(
      builder: (context, constraints) {
        final search = AppSearchField(
          controller: searchController,
          hint: l.searchCompanies,
          onChanged: onSearchChanged,
          onClear: onClearSearch,
        );
        final filters = Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            for (final item in PlatformCompanyFilter.values)
              ChoiceChip(
                label: Text(_companyFilterLabel(l, item)),
                selected: filter == item,
                onSelected: (_) => onFilterChanged(item),
              ),
          ],
        );
        if (constraints.maxWidth < 680) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              search,
              const SizedBox(height: AppSpacing.sm),
              filters,
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: search),
            const SizedBox(width: AppSpacing.sm),
            Flexible(child: filters),
          ],
        );
      },
    );
  }
}

class _DashboardCompanyRow extends StatelessWidget {
  const _DashboardCompanyRow({
    required this.company,
    required this.state,
    required this.selected,
    required this.onOpenWorkspace,
  });

  final CompanyMetadata company;
  final PlatformState state;
  final bool selected;
  final VoidCallback onOpenWorkspace;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: selected
            ? AppColors.primaryColor(context).withValues(alpha: .08)
            : AppColors.inputSurface(context),
        border: Border.all(
          color: selected
              ? AppColors.primaryColor(context).withValues(alpha: .45)
              : AppColors.borderColor(context),
        ),
        borderRadius: AppRadius.large,
      ),
      child: Row(
        children: [
          Icon(Icons.business_outlined, color: AppColors.primaryColor(context)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _companyTitle(company),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                Text(
                  _directionalIsolate(company.id),
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
            label: _statusLabel(l, company),
            tone: _isOperationalCompany(company)
                ? AppStatusTone.success
                : AppStatusTone.neutral,
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            selected
                ? _usersUsedLabel(context, state, company)
                : _limitLabel(context, company.limits['users']),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondaryColor(context),
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            _formatDate(context, company.createdAt),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondaryColor(context),
                ),
          ),
          _CompanyActionsMenu(
            company: company,
            onOpenWorkspace: onOpenWorkspace,
          ),
        ],
      ),
    );
  }
}

class _DashboardActivityPanel extends StatelessWidget {
  const _DashboardActivityPanel({
    required this.state,
    required this.onOpenActivity,
  });

  final PlatformState state;
  final VoidCallback onOpenActivity;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final users = state.companyUsers
        .where((user) => user.lastLoginAt != null)
        .toList(growable: false)
      ..sort((a, b) => b.lastLoginAt!.compareTo(a.lastLoginAt!));
    final visible = users.take(5).toList(growable: false);

    return _Panel(
      title: l.platformRecentActivity,
      action: TextButton.icon(
        onPressed: visible.isEmpty ? null : onOpenActivity,
        icon: const Icon(Icons.history),
        label: Text(l.platformViewAllLogs),
      ),
      child: visible.isEmpty
          ? AppEmptyState(
              icon: Icons.manage_history_outlined,
              title: l.platformNoRecentActivity,
              message: l.noLoginActivityYet,
            )
          : Column(
              children: [
                for (final user in visible) ...[
                  _LoginActivityRow(user: user),
                  if (user != visible.last)
                    const SizedBox(height: AppSpacing.xs),
                ],
              ],
            ),
    );
  }
}

class _WorkspaceSummaryPanel extends StatelessWidget {
  const _WorkspaceSummaryPanel({required this.state});

  final PlatformState state;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final company = state.selectedCompany;
    final users = state.companyUsers;
    final adminsManagers = users.where((user) {
      return user.role == UserRole.admin || user.role == UserRole.manager;
    }).length;
    final activeUsers = users.where((user) => user.isActive).length;

    return _Panel(
      title: l.platformWorkspaceSummary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _SummaryMiniCard(
                label: l.platformTotalUsers,
                value: users.length.toString(),
                icon: Icons.people_outline,
              ),
              _SummaryMiniCard(
                label: l.platformAdminsManagers,
                value: adminsManagers.toString(),
                icon: Icons.admin_panel_settings_outlined,
              ),
              _SummaryMiniCard(
                label: l.platformActiveUsers,
                value: activeUsers.toString(),
                icon: Icons.person_outline,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _StorageProgressCard(
            company: company,
            isRefreshing: company != null &&
                state.activeStorageActionId == company.id &&
                state.status == PlatformStatus.saving,
          ),
        ],
      ),
    );
  }
}

class _SummaryMiniCard extends StatelessWidget {
  const _SummaryMiniCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.inputSurface(context),
        border: Border.all(color: AppColors.borderColor(context)),
        borderRadius: AppRadius.large,
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryColor(context), size: 20),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                Text(
                  label,
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
    );
  }
}

class _StorageProgressCard extends StatelessWidget {
  const _StorageProgressCard({
    required this.company,
    required this.isRefreshing,
  });

  final CompanyMetadata? company;
  final bool isRefreshing;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final storageLimit = company == null ? null : _limitValue(company!.limits['storageMb']);
    final usedBytes = company?.storageUsedBytes;
    final limitBytes = storageLimit == null ? null : storageLimit * 1024 * 1024;
    final ratio = usedBytes == null || limitBytes == null || limitBytes == 0
        ? 0.0
        : (usedBytes / limitBytes).clamp(0.0, 1.0).toDouble();
    final usageText = company == null
        ? l.notAvailable
        : _storageUsageLabel(context, company!, storageLimit);
    final updatedAt = company?.storageUsageUpdatedAt;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.inputSurface(context),
        border: Border.all(color: AppColors.borderColor(context)),
        borderRadius: AppRadius.large,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.storage_outlined, color: AppColors.primaryColor(context)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  l.platformStorageUsage,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              Text(
                usageText,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondaryColor(context),
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: AppRadius.small,
            child: LinearProgressIndicator(
              minHeight: 6,
              value: usedBytes == null ? null : ratio,
              backgroundColor: AppColors.borderColor(context),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: Text(
                  usedBytes == null
                      ? l.storageNotTrackedYet
                      : '${l.storageLastUpdated}: ${_formatNullableDate(context, updatedAt)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondaryColor(context),
                      ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              AppButton(
                label: l.refreshStorageUsage,
                icon: Icons.refresh,
                variant: AppButtonVariant.secondary,
                isLoading: isRefreshing,
                onPressed: company == null || isRefreshing
                    ? null
                    : () async {
                        final success = await context
                            .read<PlatformCubit>()
                            .refreshCompanyStorageUsage(companyId: company!.id);
                        if (context.mounted && success) {
                          AppFeedback.success(context, l.storageUsageUpdated);
                        }
                      },
              ),
            ],
          ),
        ],
      ),
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
  const _CompaniesPanel({
    required this.state,
    required this.onOpenWorkspace,
  });

  final PlatformState state;
  final VoidCallback onOpenWorkspace;

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
                          onOpenWorkspace: () {
                            context
                                .read<PlatformCubit>()
                                .selectCompany(company.id);
                            widget.onOpenWorkspace();
                          },
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

class _CompanyWorkspacePanel extends StatefulWidget {
  const _CompanyWorkspacePanel({required this.state});

  final PlatformState state;

  @override
  State<_CompanyWorkspacePanel> createState() => _CompanyWorkspacePanelState();
}

class _CompanyWorkspacePanelState extends State<_CompanyWorkspacePanel> {
  var _tab = _WorkspaceTab.summary;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final company = widget.state.selectedCompany;
    if (company == null) {
      return _Panel(
        title: l.workspace,
        child: AppEmptyState(
          icon: Icons.apartment_outlined,
          title: l.noCompanySelected,
          message: l.noCompanySelectedMessage,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _WorkspaceHeader(company: company, state: widget.state),
        const SizedBox(height: AppSpacing.md),
        _WorkspaceTabs(
          selected: _tab,
          onSelected: (tab) => setState(() => _tab = tab),
        ),
        const SizedBox(height: AppSpacing.md),
        switch (_tab) {
          _WorkspaceTab.summary => _CompanyDetailsPanel(state: widget.state),
          _WorkspaceTab.users => _CompanyUsersPanel(state: widget.state),
          _WorkspaceTab.features => _CompanyFeaturesPanel(state: widget.state),
          _WorkspaceTab.limits => _CompanyLimitsPanel(state: widget.state),
          _WorkspaceTab.settings => _CompanySettingsPanel(state: widget.state),
          _WorkspaceTab.maintenance =>
            _CompanyDataHealthPanel(state: widget.state),
          _WorkspaceTab.preview => _CompanyPreviewPanel(state: widget.state),
        },
      ],
    );
  }
}

class _WorkspaceHeader extends StatelessWidget {
  const _WorkspaceHeader({required this.company, required this.state});

  final CompanyMetadata company;
  final PlatformState state;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final companyActive = _isOperationalCompany(company);
    final busy = state.activeCompanyActionId == company.id;

    return _Panel(
      title: _companyTitle(company),
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
            isLoading: busy,
            onPressed: busy
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
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        crossAxisAlignment: WrapCrossAlignment.center,
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
    );
  }
}

class _WorkspaceTabs extends StatelessWidget {
  const _WorkspaceTabs({required this.selected, required this.onSelected});

  final _WorkspaceTab selected;
  final ValueChanged<_WorkspaceTab> onSelected;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _WorkspaceTab.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.xs),
        itemBuilder: (context, index) {
          final tab = _WorkspaceTab.values[index];
          return ChoiceChip(
            avatar: Icon(_workspaceTabIcon(tab), size: 18),
            label: Text(_workspaceTabLabel(l, tab)),
            selected: selected == tab,
            onSelected: (_) => onSelected(tab),
          );
        },
      ),
    );
  }
}

class _PlatformActivityPanel extends StatelessWidget {
  const _PlatformActivityPanel({required this.state});

  final PlatformState state;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final company = state.selectedCompany;
    final users = state.companyUsers
        .where((user) => user.lastLoginAt != null)
        .toList(growable: false)
      ..sort((a, b) {
        return b.lastLoginAt!.compareTo(a.lastLoginAt!);
      });
    final visibleUsers = users.take(50).toList(growable: false);

    return _Panel(
      title: l.recentLoginActivity,
      child: company == null
          ? AppEmptyState(
              icon: Icons.apartment_outlined,
              title: l.noCompanySelected,
              message: l.noCompanySelectedMessage,
            )
          : users.isEmpty
              ? AppEmptyState(
                  icon: Icons.manage_history_outlined,
                  title: l.noLoginActivityYet,
                  message: l.noCompanyUsersMessage,
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        _InfoChip(label: l.companyName, value: _companyTitle(company)),
                        _InfoChip(label: l.usersUsed, value: _usersUsedLabel(context, state, company)),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    for (final user in visibleUsers) ...[
                      _LoginActivityRow(user: user),
                      if (user != visibleUsers.last)
                        const SizedBox(height: AppSpacing.xs),
                    ],
                  ],
                ),
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

    return _Panel(
      title: l.companyDetails,
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
        ],
      ),
    );
  }
}

class _OverviewGrid extends StatelessWidget {
  const _OverviewGrid({
    required this.state,
    required this.onOpenCompanies,
    required this.onOpenWorkspace,
  });

  final PlatformState state;
  final VoidCallback onOpenCompanies;
  final VoidCallback onOpenWorkspace;

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
                        label: l.workspace,
                        icon: Icons.view_quilt_outlined,
                        variant: AppButtonVariant.secondary,
                        onPressed: onOpenWorkspace,
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

class _CompanyUsersPanel extends StatefulWidget {
  const _CompanyUsersPanel({required this.state});

  final PlatformState state;

  @override
  State<_CompanyUsersPanel> createState() => _CompanyUsersPanelState();
}

class _CompanyUsersPanelState extends State<_CompanyUsersPanel> {
  final _searchController = TextEditingController();
  UserRole? _roleFilter;
  bool? _activeFilter;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final state = widget.state;
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
    final filteredUsers = _filteredUsers(state.companyUsers);

    return _Panel(
      title: l.companyUsers,
      action: AppButton(
        label: l.platformSupportAddUser,
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
          _UserFiltersBar(
            searchController: _searchController,
            roleFilter: _roleFilter,
            activeFilter: _activeFilter,
            onSearchChanged: (_) => setState(() {}),
            onClearSearch: () {
              _searchController.clear();
              setState(() {});
            },
            onRoleChanged: (role) => setState(() => _roleFilter = role),
            onActiveChanged: (active) =>
                setState(() => _activeFilter = active),
          ),
          const SizedBox(height: AppSpacing.md),
          if (state.companyUsers.isEmpty)
            AppEmptyState(
              icon: Icons.people_outline,
              title: l.noCompanyUsers,
              message: l.noCompanyUsersMessage,
            )
          else if (filteredUsers.isEmpty)
            AppEmptyState(
              icon: Icons.search_off_outlined,
              title: l.noCompanyUsers,
              message: l.noCompaniesFoundMessage,
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 620),
              child: _UsersTable(
                companyId: company.id,
                users: filteredUsers,
                activeUserActionId: state.activeUserActionId,
              ),
            ),
        ],
      ),
    );
  }

  List<PlatformCompanyUser> _filteredUsers(List<PlatformCompanyUser> users) {
    final query = _searchController.text.trim().toLowerCase();
    return users.where((user) {
      final matchesQuery = query.isEmpty ||
          user.fullName.toLowerCase().contains(query) ||
          user.email.toLowerCase().contains(query) ||
          user.uid.toLowerCase().contains(query);
      final matchesRole = _roleFilter == null || user.role == _roleFilter;
      final matchesActive =
          _activeFilter == null || user.isActive == _activeFilter;
      return matchesQuery && matchesRole && matchesActive;
    }).toList();
  }
}

class _UserFiltersBar extends StatelessWidget {
  const _UserFiltersBar({
    required this.searchController,
    required this.roleFilter,
    required this.activeFilter,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onRoleChanged,
    required this.onActiveChanged,
  });

  final TextEditingController searchController;
  final UserRole? roleFilter;
  final bool? activeFilter;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final ValueChanged<UserRole?> onRoleChanged;
  final ValueChanged<bool?> onActiveChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 720;
        final search = AppSearchField(
          controller: searchController,
          hint: l.searchCrm,
          onChanged: onSearchChanged,
          onClear: onClearSearch,
        );
        final role = AppDropdown<UserRole?>(
          label: l.role,
          value: roleFilter,
          items: const [null, ...UserRole.values],
          itemLabelBuilder: (value) =>
              value == null ? l.allAgents : _roleLabel(l, value),
          onChanged: onRoleChanged,
        );
        final status = AppDropdown<bool?>(
          label: l.status,
          value: activeFilter,
          items: const [null, true, false],
          itemLabelBuilder: (value) => value == null
              ? l.allStatuses
              : (value ? l.active : l.inactive),
          onChanged: onActiveChanged,
        );

        if (narrow) {
          return Column(
            children: [
              search,
              const SizedBox(height: AppSpacing.sm),
              role,
              const SizedBox(height: AppSpacing.sm),
              status,
            ],
          );
        }

        return Row(
          children: [
            Expanded(flex: 2, child: search),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: role),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: status),
          ],
        );
      },
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
            : () => _showEditCompanySettingsDialog(
                  context,
                  company,
                  limitsOnly: true,
                ),
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

class _CompanyDataHealthPanel extends StatelessWidget {
  const _CompanyDataHealthPanel({required this.state});

  final PlatformState state;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final company = state.selectedCompany;
    if (company == null) {
      return AppEmptyState(
        icon: Icons.apartment_outlined,
        title: l.noCompanySelected,
        message: l.noCompanySelectedMessage,
      );
    }

    final report = state.dataHealthReport;
    return _Panel(
      title: l.dataHealth,
      action: AppButton(
        label: l.runDataHealthCheck,
        icon: Icons.fact_check_outlined,
        isLoading: state.dataHealthLoading,
        onPressed: state.dataHealthLoading
            ? null
            : () => context
                .read<PlatformCubit>()
                .loadDataHealthReport(company.id),
      ),
      child: report == null
          ? AppEmptyState(
              icon: Icons.health_and_safety_outlined,
              title: l.dataHealthNotRun,
              message: l.dataHealthNotRunMessage,
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (report.generatedAt != null) ...[
                  Text(
                    '${l.updatedAt}: ${_formatDate(context, report.generatedAt!)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondaryColor(context),
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
                LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.maxWidth >= 760 ? 2 : 1;
                    return GridView.count(
                      crossAxisCount: columns,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: AppSpacing.sm,
                      crossAxisSpacing: AppSpacing.sm,
                      childAspectRatio: constraints.maxWidth < 520 ? 2.1 : 3.4,
                      children: [
                        _KpiCard(
                          label: l.invalidAssignees,
                          value: report.invalidAssignees.toString(),
                          icon: Icons.person_off_outlined,
                          tone: AppStatusTone.error,
                        ),
                        _KpiCard(
                          label: l.inactiveAssignees,
                          value: report.inactiveAssignees.toString(),
                          icon: Icons.block_outlined,
                          tone: AppStatusTone.warning,
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                if (!report.hasIssues)
                  AppEmptyState(
                    icon: Icons.verified_outlined,
                    title: l.dataHealthClean,
                    message: l.dataHealthCleanMessage,
                  )
                else
                  _DataHealthIssueList(state: state, issues: report.issues),
              ],
            ),
    );
  }
}

class _DataHealthIssueList extends StatelessWidget {
  const _DataHealthIssueList({required this.state, required this.issues});

  final PlatformState state;
  final List<DataHealthIssue> issues;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l.dataHealthAffectedRecords,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: AppSpacing.sm),
        for (final issue in issues.take(80)) ...[
          _DataHealthIssueTile(
            state: state,
            issue: issue,
          ),
          const SizedBox(height: AppSpacing.xs),
        ],
      ],
    );
  }
}

class _DataHealthIssueTile extends StatelessWidget {
  const _DataHealthIssueTile({required this.state, required this.issue});

  final PlatformState state;
  final DataHealthIssue issue;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final companyId = state.selectedCompany?.id ?? '';
    final actionId = '${issue.module}/${issue.recordId}';
    final isRepairing = state.activeDataHealthActionId == actionId;
    final assigneeLabel = _dataHealthAssigneeLabel(l, issue);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.inputSurface(context),
        border: Border.all(color: AppColors.borderColor(context)),
        borderRadius: AppRadius.large,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AppStatusBadge(
            label: _moduleLabel(l, issue.module),
            tone: AppStatusTone.neutral,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  issue.title.isEmpty ? issue.recordId : issue.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_issueLabel(l, issue.issueType)} - $assigneeLabel',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondaryColor(context),
                      ),
                ),
                if (issue.suggestedAction.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    _dataHealthSuggestedAction(l, issue),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondaryColor(context),
                        ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              AppStatusBadge(
                label: issue.canBackfill
                    ? l.safeBackfillAvailable
                    : l.manualReview,
                tone: issue.canBackfill
                    ? AppStatusTone.info
                    : AppStatusTone.warning,
              ),
              if (issue.canBackfill)
                AppButton(
                  label: l.backfillSnapshots,
                  icon: Icons.auto_fix_high_outlined,
                  variant: AppButtonVariant.secondary,
                  isLoading: isRepairing,
                  onPressed: companyId.isEmpty || isRepairing
                      ? null
                      : () async {
                          final success = await context
                              .read<PlatformCubit>()
                              .backfillAssignedRecordSnapshots(
                                companyId: companyId,
                                module: issue.module,
                                recordId: issue.recordId,
                              );
                          if (context.mounted && success) {
                            AppFeedback.success(
                              context,
                              l.dataHealthRepairSuccess,
                            );
                          }
                        },
                ),
            ],
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
                  enabled: _featureEnabled(company, feature),
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
    required this.onOpenWorkspace,
    required this.onTap,
  });

  final CompanyMetadata company;
  final bool selected;
  final VoidCallback onOpenWorkspace;
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
            child: LayoutBuilder(
              builder: (context, constraints) {
                final narrow = constraints.maxWidth < 680;
                final title = Row(
                  children: [
                    Icon(Icons.apartment, color: colors.primary),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _companyTitle(company),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            company.id,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color:
                                      AppColors.textSecondaryColor(context),
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
                final meta = Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    AppStatusBadge(
                      label: _statusLabel(l, company),
                      tone: _isOperationalCompany(company)
                          ? AppStatusTone.success
                          : AppStatusTone.neutral,
                    ),
                    _InfoChip(
                      label: l.userLimit,
                      value: _limitLabel(context, company.limits['users']),
                    ),
                    _InfoChip(
                      label: l.companyFeatures,
                      value: _enabledFeaturesCount(company).toString(),
                    ),
                  ],
                );
                final actions = Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    _CompanyActionsMenu(
                      company: company,
                      onOpenWorkspace: onOpenWorkspace,
                    ),
                  ],
                );

                if (narrow) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      title,
                      const SizedBox(height: AppSpacing.sm),
                      meta,
                      const SizedBox(height: AppSpacing.sm),
                      actions,
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(flex: 3, child: title),
                    Expanded(flex: 3, child: meta),
                    actions,
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

enum _CompanyAction { workspace, preview }

class _CompanyActionsMenu extends StatelessWidget {
  const _CompanyActionsMenu({
    required this.company,
    required this.onOpenWorkspace,
  });

  final CompanyMetadata company;
  final VoidCallback onOpenWorkspace;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return PopupMenuButton<_CompanyAction>(
      tooltip: l.actions,
      icon: const Icon(Icons.more_horiz),
      onSelected: (action) {
        switch (action) {
          case _CompanyAction.workspace:
            onOpenWorkspace();
            return;
          case _CompanyAction.preview:
            _openPreview(context, company);
            return;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem<_CompanyAction>(
          value: _CompanyAction.workspace,
          child: _MenuItem(
            icon: Icons.view_quilt_outlined,
            label: l.workspace,
          ),
        ),
        PopupMenuItem<_CompanyAction>(
          value: _CompanyAction.preview,
          child: _MenuItem(
            icon: Icons.dashboard_customize_outlined,
            label: l.previewDashboard,
          ),
        ),
      ],
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
                _PlatformUserAvatar(
                  name: user.fullName,
                  photoUrl: user.photoUrl,
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
                        user.email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondaryColor(context),
                        ),
                      ),
                      if (user.teamName.trim().isNotEmpty ||
                          user.managerName.trim().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          [
                            if (user.teamName.trim().isNotEmpty)
                              user.teamName.trim(),
                            if (user.managerName.trim().isNotEmpty)
                              user.managerName.trim(),
                          ].join(' / '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: AppColors.textSecondaryColor(context),
                              ),
                        ),
                      ],
                      const SizedBox(height: 4),
                      _LoginDetails(user: user, compact: true),
                    ],
                  ),
                ),
                AppStatusBadge(
                  label: _roleLabel(l, user.role),
                  tone: AppStatusTone.info,
                ),
                AppStatusBadge(
                  label: user.isActive ? l.active : l.inactive,
                  tone: user.isActive
                      ? AppStatusTone.success
                      : AppStatusTone.neutral,
                ),
                if (isBusy)
                  const SizedBox.square(
                    dimension: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  _UserActionsMenu(companyId: companyId, user: user),
              ],
            ),
          );
      },
    );
  }
}

class _LoginActivityRow extends StatelessWidget {
  const _LoginActivityRow({required this.user});

  final PlatformCompanyUser user;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.inputSurface(context),
        border: Border.all(color: AppColors.borderColor(context)),
        borderRadius: AppRadius.large,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final identity = Row(
            children: [
              _PlatformUserAvatar(name: user.fullName, photoUrl: user.photoUrl),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondaryColor(context),
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              AppStatusBadge(
                label: _roleLabel(l, user.role),
                tone: AppStatusTone.info,
              ),
            ],
          );
          if (constraints.maxWidth < 640) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                identity,
                const SizedBox(height: AppSpacing.xs),
                _LoginDetails(user: user),
              ],
            );
          }
          return Row(
            children: [
              Expanded(flex: 3, child: identity),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                flex: 2,
                child: _LoginDetails(user: user),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _LoginDetails extends StatelessWidget {
  const _LoginDetails({required this.user, this.compact = false});

  final PlatformCompanyUser user;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final at = user.lastLoginAt;
    if (at == null) {
      return Text(
        l.noLoginActivityYet,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondaryColor(context),
            ),
      );
    }

    final rows = [
      _LoginInfoLine(label: l.lastLogin, value: _formatDate(context, at)),
      _LoginInfoLine(label: l.ipAddress, value: _loginValue(l, user.lastLoginIp)),
      _LoginInfoLine(label: l.device, value: _loginDeviceLabel(l, user)),
    ];

    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: rows.take(2).toList(growable: false),
      );
    }
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: 2,
      children: rows,
    );
  }
}

class _LoginInfoLine extends StatelessWidget {
  const _LoginInfoLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          TextSpan(text: _directionalIsolate(value)),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondaryColor(context),
      ),
    );
  }
}

class _PlatformUserAvatar extends StatelessWidget {
  const _PlatformUserAvatar({required this.name, required this.photoUrl});

  final String name;
  final String photoUrl;

  @override
  Widget build(BuildContext context) {
    final cleanUrl = photoUrl.trim();
    final fallback = CircleAvatar(child: Text(_initialFor(name)));
    if (cleanUrl.isEmpty) {
      return fallback;
    }

    return ClipOval(
      child: SizedBox(
        width: 40,
        height: 40,
        child: Image.network(
          cleanUrl,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
          errorBuilder: (_, __, ___) => fallback,
        ),
      ),
    );
  }
}

class _UserActionsMenu extends StatelessWidget {
  const _UserActionsMenu({required this.companyId, required this.user});

  final String companyId;
  final PlatformCompanyUser user;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return PopupMenuButton<_UserAction>(
      tooltip: l.actions,
      icon: const Icon(Icons.more_horiz),
      onSelected: (action) => _handleAction(context, action),
      itemBuilder: (context) => [
        PopupMenuItem<_UserAction>(
          value: _UserAction.changeEmail,
          child: _MenuItem(
            icon: Icons.alternate_email_rounded,
            label: l.changeEmail,
          ),
        ),
        PopupMenuItem<_UserAction>(
          value: _UserAction.setPassword,
          child: _MenuItem(icon: Icons.lock_reset, label: l.changePassword),
        ),
        PopupMenuItem<_UserAction>(
          value: _UserAction.resetLink,
          child: _MenuItem(icon: Icons.link, label: l.generateResetLink),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<_UserAction>(
          value: _UserAction.toggleActive,
          child: _MenuItem(
            icon: user.isActive ? Icons.block : Icons.check_circle_outline,
            label: user.isActive ? l.deactivateUser : l.activateUser,
            danger: user.isActive,
          ),
        ),
      ],
    );
  }

  Future<void> _handleAction(BuildContext context, _UserAction action) async {
    switch (action) {
      case _UserAction.changeEmail:
        return _showPlatformChangeEmailDialog(
          context,
          companyId: companyId,
          user: user,
        );
      case _UserAction.setPassword:
        return _showPlatformChangePasswordDialog(
          context,
          companyId: companyId,
          user: user,
        );
      case _UserAction.resetLink:
        return _showGenerateResetLinkDialog(
          context,
          companyId: companyId,
          user: user,
        );
      case _UserAction.toggleActive:
        return _toggleUserStatus(context);
    }
  }

  Future<void> _toggleUserStatus(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final l = AppLocalizations.of(dialogContext)!;
        return AlertDialog(
          title: Text(user.isActive ? l.deactivateUser : l.activateUser),
          content: Text(user.email),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l.cancel),
            ),
            AppButton(
              label: l.save,
              variant: user.isActive
                  ? AppButtonVariant.danger
                  : AppButtonVariant.secondary,
              onPressed: () => Navigator.of(dialogContext).pop(true),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !context.mounted) {
      return;
    }

    final success = await context
        .read<PlatformCubit>()
        .setCompanyUserActiveStatus(
          companyId: companyId,
          uid: user.uid,
          isActive: !user.isActive,
        );
    if (context.mounted && success) {
      AppFeedback.success(
        context,
        AppLocalizations.of(context)!.savedSuccessfully,
      );
    }
  }
}

enum _UserAction { changeEmail, setPassword, resetLink, toggleActive }

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.label,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger
        ? AppColors.errorColor(context)
        : AppColors.textPrimaryColor(context);
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: color,
                  fontWeight: danger ? FontWeight.w700 : FontWeight.w500,
                ),
          ),
        ),
      ],
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
          LayoutBuilder(
            builder: (context, constraints) {
              final heading = Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              );
              if (action == null) {
                return heading;
              }
              if (constraints.maxWidth < 620) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    heading,
                    const SizedBox(height: AppSpacing.sm),
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: action,
                    ),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: heading),
                  const SizedBox(width: AppSpacing.sm),
                  action!,
                ],
              );
            },
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

class _PlatformInvitationsPanel extends StatelessWidget {
  const _PlatformInvitationsPanel();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return BlocBuilder<PlatformInvitationsCubit, PlatformInvitationsState>(
      builder: (context, state) {
        final saving = state.status == PlatformInvitationsStatus.saving;
        return _Panel(
          title: l.invitations,
          action: Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              AppButton(
                label: l.createInvitation,
                icon: Icons.mark_email_unread_outlined,
                isLoading: saving && state.activeActionId == null,
                onPressed:
                    saving ? null : () => _showCreateInvitationDialog(context),
              ),
              AppButton(
                label: l.manualSupportSetup,
                icon: Icons.support_agent_outlined,
                variant: AppButtonVariant.secondary,
                onPressed: () => _showCreateCompanyDialog(context),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l.invitationOnboardingNote,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondaryColor(context),
                ),
              ),
              if (state.message != null) ...[
                const SizedBox(height: AppSpacing.md),
                AppErrorView(message: state.message!),
              ],
              if (state.createdInvitation != null) ...[
                const SizedBox(height: AppSpacing.md),
                _CreatedInvitationBox(invitation: state.createdInvitation!),
              ],
              const SizedBox(height: AppSpacing.md),
              _InvitationFilters(
                selected: state.filter,
                onSelected:
                    context.read<PlatformInvitationsCubit>().updateFilter,
              ),
              const SizedBox(height: AppSpacing.md),
              if (state.status == PlatformInvitationsStatus.loading)
                const AppLoading()
              else if (state.filteredInvitations.isEmpty)
                AppEmptyState(
                  icon: Icons.mark_email_unread_outlined,
                  title: l.noInvitationsYet,
                  message: l.noInvitationsYetMessage,
                )
              else
                Column(
                  children: [
                    for (final invitation in state.filteredInvitations) ...[
                      _InvitationCard(
                        invitation: invitation,
                        isBusy: state.activeActionId == invitation.id,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}

class _CreatedInvitationBox extends StatelessWidget {
  const _CreatedInvitationBox({required this.invitation});

  final CreatedCompanyInvitation invitation;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.successColor(context).withValues(alpha: 0.08),
        border: Border.all(
          color: AppColors.successColor(context).withValues(alpha: 0.28),
        ),
        borderRadius: AppRadius.large,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.invitationCreated,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SelectableText(_directionalIsolate(invitation.invitationCode)),
          const SizedBox(height: AppSpacing.xs),
          SelectableText(_directionalIsolate(invitation.invitationLink)),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              AppButton(
                label: l.copyCode,
                icon: Icons.copy,
                variant: AppButtonVariant.secondary,
                onPressed: () async {
                  await Clipboard.setData(
                    ClipboardData(text: invitation.invitationCode),
                  );
                  if (context.mounted) {
                    AppFeedback.success(context, l.invitationCodeCopied);
                  }
                },
              ),
              AppButton(
                label: l.copyLink,
                icon: Icons.link,
                variant: AppButtonVariant.secondary,
                onPressed: () async {
                  await Clipboard.setData(
                    ClipboardData(text: invitation.invitationLink),
                  );
                  if (context.mounted) {
                    AppFeedback.success(context, l.invitationLinkCopied);
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InvitationFilters extends StatelessWidget {
  const _InvitationFilters({required this.selected, required this.onSelected});

  final PlatformInvitationFilter selected;
  final ValueChanged<PlatformInvitationFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Wrap(
      spacing: AppSpacing.xs,
      children: [
        for (final filter in PlatformInvitationFilter.values)
          ChoiceChip(
            label: Text(_invitationFilterLabel(l, filter)),
            selected: selected == filter,
            onSelected: (_) => onSelected(filter),
          ),
      ],
    );
  }
}

class _InvitationCard extends StatelessWidget {
  const _InvitationCard({required this.invitation, required this.isBusy});

  final PlatformInvitation invitation;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final features = invitation.features.entries
        .where((entry) => entry.value)
        .map((entry) => _featureLabel(l, entry.key))
        .join(', ');
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.borderColor(context)),
        borderRadius: AppRadius.large,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _directionalIsolate(invitation.codePreview),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              AppStatusBadge(
                label: _invitationStatusLabel(l, invitation.status),
                tone: _invitationStatusTone(invitation.status),
              ),
              PopupMenuButton<String>(
                tooltip: l.actions,
                onSelected: (value) async {
                  if (value == 'revoke') {
                    final success = await context
                        .read<PlatformInvitationsCubit>()
                        .revokeInvitation(invitation.id);
                    if (context.mounted && success) {
                      AppFeedback.success(context, l.savedSuccessfully);
                    }
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'revoke',
                    enabled: invitation.status == 'active' && !isBusy,
                    child: Text(l.revokeInvitation),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _InfoChip(label: l.plan, value: invitation.planName),
              _InfoChip(label: l.userLimit, value: '${invitation.userLimit}'),
              _InfoChip(
                label: l.storageLimitMb,
                value: '${invitation.storageLimitMb}',
              ),
              _InfoChip(
                label: l.expiresAt,
                value: invitation.expiresAt == null
                    ? l.notAvailable
                    : _formatDate(context, invitation.expiresAt!),
              ),
              if (invitation.allowedAdminEmailHint.isNotEmpty)
                _InfoChip(
                  label: l.allowedAdminEmail,
                  value: _directionalIsolate(invitation.allowedAdminEmailHint),
                ),
              if (invitation.companyId.isNotEmpty)
                _InfoChip(
                  label: l.companyIdSlug,
                  value: _directionalIsolate(invitation.companyId),
                ),
            ],
          ),
          if (features.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              '${l.features}: $features',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondaryColor(context),
              ),
            ),
          ],
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

Future<void> _showCreateInvitationDialog(BuildContext context) {
  final cubit = context.read<PlatformInvitationsCubit>();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      final bottomInset = MediaQuery.viewInsetsOf(sheetContext).bottom;
      final maxHeight = MediaQuery.sizeOf(sheetContext).height * 0.92;
      return Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Align(
          alignment: AlignmentDirectional.bottomCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 720, maxHeight: maxHeight),
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              child: Material(
                color: AppColors.cardSurface(sheetContext),
                child: _CreateInvitationDialog(cubit: cubit),
              ),
            ),
          ),
        ),
      );
    },
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

Future<void> _showPlatformChangeEmailDialog(
  BuildContext context, {
  required String companyId,
  required PlatformCompanyUser user,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) => _PlatformChangeEmailDialog(
      cubit: context.read<PlatformCubit>(),
      companyId: companyId,
      user: user,
    ),
  );
}

Future<void> _showPlatformChangePasswordDialog(
  BuildContext context, {
  required String companyId,
  required PlatformCompanyUser user,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) => _PlatformChangePasswordDialog(
      cubit: context.read<PlatformCubit>(),
      companyId: companyId,
      user: user,
    ),
  );
}

Future<void> _showGenerateResetLinkDialog(
  BuildContext context, {
  required String companyId,
  required PlatformCompanyUser user,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) => _GenerateResetLinkDialog(
      cubit: context.read<PlatformCubit>(),
      companyId: companyId,
      user: user,
    ),
  );
}

Future<void> _showEditCompanySettingsDialog(
  BuildContext context,
  CompanyMetadata company, {
  bool limitsOnly = false,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) => _EditCompanySettingsDialog(
      cubit: context.read<PlatformCubit>(),
      company: company,
      limitsOnly: limitsOnly,
    ),
  );
}

class _EditCompanySettingsDialog extends StatefulWidget {
  const _EditCompanySettingsDialog({
    required this.cubit,
    required this.company,
    required this.limitsOnly,
  });

  final PlatformCubit cubit;
  final CompanyMetadata company;
  final bool limitsOnly;

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
      title: Text(widget.limitsOnly ? l.companyLimits : l.editCompanySettings),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!widget.limitsOnly) ...[
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
                ] else
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
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _saving = true);
    final success = await widget.cubit.updateCompanyPlatformSettings(
      companyId: widget.company.id,
      name: widget.limitsOnly ? null : _companyName.text.trim(),
      displayName: widget.limitsOnly ? null : _displayName.text.trim(),
      status: widget.limitsOnly ? null : _status,
      isActive: widget.limitsOnly ? null : _status != 'inactive',
      settings: widget.limitsOnly
          ? null
          : {
              'locale': _locale,
              'timezone': _timezone.text.trim(),
            },
      limits: widget.limitsOnly
          ? {
              'users': int.parse(_userLimit.text.trim()),
              'storageMb': int.parse(_storageLimit.text.trim()),
            }
          : null,
      actionId: widget.limitsOnly ? 'limits' : 'settings',
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

class _CreateInvitationDialog extends StatefulWidget {
  const _CreateInvitationDialog({required this.cubit});

  final PlatformInvitationsCubit cubit;

  @override
  State<_CreateInvitationDialog> createState() => _CreateInvitationDialogState();
}

class _CreateInvitationDialogState extends State<_CreateInvitationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _planName = TextEditingController(text: 'Professional');
  final _planId = TextEditingController(text: 'professional');
  final _userLimit = TextEditingController(text: '25');
  final _storageLimit = TextEditingController(text: '1024');
  final _expiresInDays = TextEditingController(text: '14');
  final _timezone = TextEditingController(text: 'Africa/Cairo');
  final _notes = TextEditingController();
  var _locale = 'en';
  var _saving = false;
  final Map<String, bool> _features = {
    for (final feature in _featureKeys) feature: true,
  };

  @override
  void dispose() {
    _planName.dispose();
    _planId.dispose();
    _userLimit.dispose();
    _storageLimit.dispose();
    _expiresInDays.dispose();
    _timezone.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l.createInvitation),
      content: SizedBox(
        width: 620,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppTextField(
                  controller: _planName,
                  label: l.plan,
                  enabled: !_saving,
                  validator: (value) => _required(value, l),
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: _planId,
                  label: l.planId,
                  enabled: !_saving,
                  validator: (value) => _required(value, l),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        controller: _userLimit,
                        label: l.userLimit,
                        keyboardType: TextInputType.number,
                        enabled: !_saving,
                        validator: (value) => _positiveInteger(value, l),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: AppTextField(
                        controller: _storageLimit,
                        label: l.storageLimitMb,
                        keyboardType: TextInputType.number,
                        enabled: !_saving,
                        validator: (value) => _positiveInteger(value, l),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        controller: _expiresInDays,
                        label: l.expiresInDays,
                        keyboardType: TextInputType.number,
                        enabled: !_saving,
                        validator: (value) => _positiveInteger(value, l),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: AppDropdown<String>(
                        label: l.locale,
                        value: _locale,
                        items: const ['en', 'ar'],
                        itemLabelBuilder: (value) =>
                            value == 'ar' ? l.arabic : l.english,
                        enabled: !_saving,
                        onChanged: (value) => setState(() => _locale = value),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: _timezone,
                  label: l.timezone,
                  enabled: !_saving,
                  validator: (value) => _required(value, l),
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: _notes,
                  label: l.notes,
                  enabled: !_saving,
                  maxLines: 3,
                ),
                const SizedBox(height: AppSpacing.md),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    l.features,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  children: [
                    for (final feature in _featureKeys)
                      FilterChip(
                        label: Text(_featureLabel(l, feature)),
                        selected: _features[feature] == true,
                        onSelected: _saving
                            ? null
                            : (selected) {
                                setState(() => _features[feature] = selected);
                              },
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
          label: l.createInvitation,
          isLoading: _saving,
          onPressed: _saving ? null : _submit,
        ),
      ],
    );
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _saving = true);
    final expiresAt = DateTime.now().add(
      Duration(days: int.parse(_expiresInDays.text.trim())),
    );
    final success = await widget.cubit.createInvitation(
      planId: _planId.text.trim(),
      planName: _planName.text.trim(),
      userLimit: int.parse(_userLimit.text.trim()),
      storageLimitMb: int.parse(_storageLimit.text.trim()),
      features: Map<String, bool>.from(_features),
      locale: _locale,
      timezone: _timezone.text.trim(),
      expiresAt: expiresAt,
      notes: _notes.text.trim(),
    );
    if (!mounted) {
      return;
    }
    setState(() => _saving = false);
    if (success) {
      AppFeedback.success(context, AppLocalizations.of(context)!.invitationCreated);
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
                  validator: (value) => AppValidators.companyName(value, l),
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: _companyId,
                  label: l.companyIdSlug,
                  enabled: !_saving,
                  validator: (value) => AppValidators.companyId(value, l),
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: _adminName,
                  label: l.firstAdminFullName,
                  enabled: !_saving,
                  validator: (value) => AppValidators.personName(value, l),
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: _adminEmail,
                  label: l.firstAdminEmail,
                  keyboardType: TextInputType.emailAddress,
                  enabled: !_saving,
                  validator: (value) => AppValidators.email(value, l),
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: _adminPhone,
                  label: l.firstAdminPhone,
                  keyboardType: TextInputType.phone,
                  enabled: !_saving,
                  validator: (value) => AppValidators.phone(value, l),
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
                        validator: (value) => AppValidators.requiredText(value, l),
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
    FocusScope.of(context).unfocus();
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

class _PlatformChangeEmailDialog extends StatefulWidget {
  const _PlatformChangeEmailDialog({
    required this.cubit,
    required this.companyId,
    required this.user,
  });

  final PlatformCubit cubit;
  final String companyId;
  final PlatformCompanyUser user;

  @override
  State<_PlatformChangeEmailDialog> createState() =>
      _PlatformChangeEmailDialogState();
}

class _PlatformChangeEmailDialogState
    extends State<_PlatformChangeEmailDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _email;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    _email = TextEditingController(text: widget.user.email);
  }

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l.changeEmail),
      content: SizedBox(
        width: 440,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.user.fullName,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondaryColor(context),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _email,
                label: l.email,
                keyboardType: TextInputType.emailAddress,
                enabled: !_saving,
                validator: (value) {
                  final email = (value ?? '').trim();
                  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
                    return l.invalidEmail;
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: Text(l.cancel),
        ),
        AppButton(
          label: l.save,
          isLoading: _saving,
          onPressed: _saving ? null : _submit,
        ),
      ],
    );
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _saving = true);
    final success = await widget.cubit.setCompanyUserEmail(
      companyId: widget.companyId,
      uid: widget.user.uid,
      newEmail: _email.text.trim(),
    );
    if (!mounted) {
      return;
    }
    setState(() => _saving = false);
    if (success) {
      AppFeedback.success(
        context,
        AppLocalizations.of(context)!.platformEmailChanged,
      );
      Navigator.of(context).pop();
    }
  }
}

class _PlatformChangePasswordDialog extends StatefulWidget {
  const _PlatformChangePasswordDialog({
    required this.cubit,
    required this.companyId,
    required this.user,
  });

  final PlatformCubit cubit;
  final String companyId;
  final PlatformCompanyUser user;

  @override
  State<_PlatformChangePasswordDialog> createState() =>
      _PlatformChangePasswordDialogState();
}

class _PlatformChangePasswordDialogState
    extends State<_PlatformChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();
  var _saving = false;

  @override
  void dispose() {
    _newPassword.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l.changePassword),
      content: SizedBox(
        width: 440,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.user.email,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondaryColor(context),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _newPassword,
                label: l.newPassword,
                obscureText: true,
                enabled: !_saving,
                validator: (value) => _password(value, l),
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _confirmPassword,
                label: l.confirmPassword,
                obscureText: true,
                enabled: !_saving,
                validator: (value) {
                  if ((value ?? '') != _newPassword.text) {
                    return l.passwordsDoNotMatch;
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: Text(l.cancel),
        ),
        AppButton(
          label: l.save,
          isLoading: _saving,
          onPressed: _saving ? null : _submit,
        ),
      ],
    );
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _saving = true);
    final success = await widget.cubit.setCompanyUserPassword(
      companyId: widget.companyId,
      uid: widget.user.uid,
      newPassword: _newPassword.text,
    );
    if (!mounted) {
      return;
    }
    setState(() => _saving = false);
    if (success) {
      AppFeedback.success(
        context,
        AppLocalizations.of(context)!.platformPasswordChanged,
      );
      Navigator.of(context).pop();
    }
  }
}

class _GenerateResetLinkDialog extends StatefulWidget {
  const _GenerateResetLinkDialog({
    required this.cubit,
    required this.companyId,
    required this.user,
  });

  final PlatformCubit cubit;
  final String companyId;
  final PlatformCompanyUser user;

  @override
  State<_GenerateResetLinkDialog> createState() =>
      _GenerateResetLinkDialogState();
}

class _GenerateResetLinkDialogState extends State<_GenerateResetLinkDialog> {
  var _loading = true;
  String? _link;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l.generateResetLink),
      content: SizedBox(
        width: 560,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _InfoChip(label: l.email, value: widget.user.email),
            const SizedBox(height: AppSpacing.md),
            Text(
              l.sendThisLinkManuallyToTheUser,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondaryColor(context),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else if ((_link ?? '').isNotEmpty)
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.appBackground(context),
                  border: Border.all(color: AppColors.borderColor(context)),
                  borderRadius: AppRadius.large,
                ),
                child: SelectableText(_link!),
              )
            else
              Text(l.passwordChangeFailed),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.of(context).pop(),
          child: Text(l.close),
        ),
        AppButton(
          label: l.copyResetLink,
          icon: Icons.copy,
          isLoading: _loading,
          onPressed: _loading || (_link ?? '').isEmpty
              ? null
              : () async {
                  await Clipboard.setData(ClipboardData(text: _link!));
                  if (context.mounted) {
                    AppFeedback.success(context, l.resetLinkCopied);
                  }
                },
        ),
      ],
    );
  }

  Future<void> _load() async {
    final link = await widget.cubit.generateCompanyUserPasswordResetLink(
      companyId: widget.companyId,
      uid: widget.user.uid,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _link = link;
      _loading = false;
    });
    if (link != null && context.mounted) {
      AppFeedback.success(
        context,
        AppLocalizations.of(context)!.resetLinkGenerated,
      );
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
                  validator: (value) => AppValidators.personName(value, l),
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: _email,
                  label: l.email,
                  keyboardType: TextInputType.emailAddress,
                  enabled: !_saving,
                  validator: (value) => AppValidators.email(value, l),
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: _phone,
                  label: l.phone,
                  keyboardType: TextInputType.phone,
                  enabled: !_saving,
                  validator: (value) => AppValidators.phone(value, l),
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
    FocusScope.of(context).unfocus();
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
    _PlatformSection.notifications => l.platformNotifications,
    _PlatformSection.invitations => l.invitations,
    _PlatformSection.companies => l.platformCompanies,
    _PlatformSection.workspace => l.workspace,
    _PlatformSection.support => l.platformSupportInbox,
    _PlatformSection.activity => l.recentLoginActivity,
  };
}

String _invitationFilterLabel(
  AppLocalizations l,
  PlatformInvitationFilter filter,
) {
  return switch (filter) {
    PlatformInvitationFilter.all => l.allStatuses,
    PlatformInvitationFilter.active => l.invitationActive,
    PlatformInvitationFilter.used => l.invitationUsed,
    PlatformInvitationFilter.expired => l.invitationExpired,
    PlatformInvitationFilter.revoked => l.invitationRevoked,
  };
}

String _invitationStatusLabel(AppLocalizations l, String status) {
  return switch (status) {
    'active' => l.invitationActive,
    'used' => l.invitationUsed,
    'expired' => l.invitationExpired,
    'revoked' => l.invitationRevoked,
    _ => status,
  };
}

AppStatusTone _invitationStatusTone(String status) {
  return switch (status) {
    'active' => AppStatusTone.success,
    'used' => AppStatusTone.info,
    'expired' => AppStatusTone.warning,
    'revoked' => AppStatusTone.error,
    _ => AppStatusTone.neutral,
  };
}

IconData _sectionIcon(_PlatformSection section) {
  return switch (section) {
    _PlatformSection.overview => Icons.space_dashboard_outlined,
    _PlatformSection.notifications => Icons.notifications_active_outlined,
    _PlatformSection.invitations => Icons.mark_email_unread_outlined,
    _PlatformSection.companies => Icons.apartment_outlined,
    _PlatformSection.workspace => Icons.view_quilt_outlined,
    _PlatformSection.support => Icons.support_agent_outlined,
    _PlatformSection.activity => Icons.manage_history_outlined,
  };
}

String _workspaceTabLabel(AppLocalizations l, _WorkspaceTab tab) {
  return switch (tab) {
    _WorkspaceTab.summary => l.companyDetails,
    _WorkspaceTab.users => l.companyUsers,
    _WorkspaceTab.features => l.companyFeatures,
    _WorkspaceTab.limits => l.companyLimits,
    _WorkspaceTab.settings => l.companySettings,
    _WorkspaceTab.maintenance => l.dataHealth,
    _WorkspaceTab.preview => l.companyDashboardPreview,
  };
}

String _moduleLabel(AppLocalizations l, String module) {
  return switch (module) {
    'leads' => l.leads,
    'clients' => l.clients,
    'properties' => l.properties,
    'tasks' => l.tasks,
    'appointments' => l.appointments,
    'deals' => l.deals,
    _ => module,
  };
}

String _issueLabel(AppLocalizations l, String issueType) {
  return switch (issueType) {
    'missingSnapshots' => l.missingSnapshots,
    'missingAssignee' => l.missingAssignee,
    'inactiveAssignee' => l.inactiveAssignees,
    'ineligibleAssignee' => l.invalidAssignees,
    'staleSnapshots' => l.staleTeamSnapshots,
    _ => issueType,
  };
}

String _dataHealthAssigneeLabel(AppLocalizations l, DataHealthIssue issue) {
  if (issue.issueType == 'missingAssignee') {
    return l.missingAssignee;
  }
  final name = issue.assignedToName.trim();
  if (name.isNotEmpty && !_looksLikeUid(name)) {
    return name;
  }
  return switch (issue.issueType) {
    'inactiveAssignee' => l.inactiveAssignees,
    'ineligibleAssignee' => l.invalidAssignees,
    _ => l.manualReview,
  };
}

bool _looksLikeUid(String value) {
  final clean = value.trim();
  if (clean.contains(' ') || clean.length < 16) {
    return false;
  }
  return RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(clean);
}

String _dataHealthSuggestedAction(AppLocalizations l, DataHealthIssue issue) {
  if (issue.canBackfill) {
    return l.safeBackfillAvailable;
  }
  return l.manualReview;
}

IconData _workspaceTabIcon(_WorkspaceTab tab) {
  return switch (tab) {
    _WorkspaceTab.summary => Icons.summarize_outlined,
    _WorkspaceTab.users => Icons.people_outline,
    _WorkspaceTab.features => Icons.extension_outlined,
    _WorkspaceTab.limits => Icons.speed_outlined,
    _WorkspaceTab.settings => Icons.tune,
    _WorkspaceTab.maintenance => Icons.health_and_safety_outlined,
    _WorkspaceTab.preview => Icons.dashboard_customize_outlined,
  };
}

const _featureKeys = [
  'leads',
  'clients',
  'properties',
  'tasks',
  'appointments',
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
    'appointments' => l.appointments,
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

int _enabledFeaturesCount(CompanyMetadata company) {
  return _featureKeys.where((feature) => _featureEnabled(company, feature)).length;
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

String _formatStorageMb(int value) {
  if (value >= 1024) {
    final gb = value / 1024;
    final text = gb >= 10 ? gb.toStringAsFixed(0) : gb.toStringAsFixed(1);
    return '$text GB';
  }
  return '$value MB';
}

String _storageUsageLabel(
  BuildContext context,
  CompanyMetadata company,
  int? storageLimitMb,
) {
  final l = AppLocalizations.of(context)!;
  final usedBytes = company.storageUsedBytes;
  if (usedBytes == null) {
    return l.storageUsageUnavailable;
  }
  final limitText = storageLimitMb == null
      ? l.notAvailable
      : _formatStorageMb(storageLimitMb);
  return '${_formatStorageBytes(usedBytes)} / $limitText';
}

String _formatStorageBytes(int bytes) {
  if (bytes < 1024) {
    return '$bytes B';
  }
  final kb = bytes / 1024;
  if (kb < 1024) {
    return '${kb.toStringAsFixed(kb >= 10 ? 0 : 1)} KB';
  }
  final mb = kb / 1024;
  if (mb < 1024) {
    return '${mb.toStringAsFixed(mb >= 10 ? 0 : 1)} MB';
  }
  final gb = mb / 1024;
  return '${gb.toStringAsFixed(gb >= 10 ? 0 : 1)} GB';
}

String _formatNullableDate(BuildContext context, DateTime? value) {
  if (value == null) {
    return AppLocalizations.of(context)!.notAvailable;
  }
  return _formatDate(context, value);
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

String _loginDeviceLabel(AppLocalizations l, PlatformCompanyUser user) {
  final device = [
    user.lastLoginDeviceType,
    user.lastLoginBrowser,
    user.lastLoginPlatform,
  ].where((value) => value.trim().isNotEmpty).join(' / ');
  return _loginValue(l, device);
}

String _loginValue(AppLocalizations l, String value) {
  final clean = value.trim();
  return clean.isEmpty ? l.notAvailable : clean;
}

String _directionalIsolate(String value) {
  final clean = value.trim();
  return clean.isEmpty ? clean : '\u2068$clean\u2069';
}

String? _required(String? value, AppLocalizations l) {
  return (value ?? '').trim().isEmpty ? l.requiredField : null;
}

String? _email(String? value, AppLocalizations l) {
  final email = (value ?? '').trim();
  if (email.isEmpty) {
    return l.requiredField;
  }
  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
    return l.invalidEmail;
  }
  return null;
}

String? _password(String? value, AppLocalizations l) {
  final text = value ?? '';
  if (text.isEmpty) {
    return l.newPasswordRequired;
  }
  if (text.length < 8) {
    return l.newPasswordTooShort;
  }
  return null;
}

String? _positiveInteger(String? value, AppLocalizations l) {
  final parsed = int.tryParse((value ?? '').trim());
  return parsed == null || parsed <= 0 ? l.enterValidNumber : null;
}
