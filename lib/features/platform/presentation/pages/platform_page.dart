import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:archive/archive.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/role_constants.dart';
import '../../../../core/localization/locale_cubit.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../../core/utils/file_downloader.dart';
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
import '../../../../core/widgets/masar_tab_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../auth/presentation/widgets/change_password_dialog.dart';
import '../../../app_update/domain/entities/android_release_policy.dart';
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
import '../../../platform_observability/data/datasources/platform_observability_remote_data_source.dart';
import '../../../platform_observability/data/repositories/platform_observability_repository_impl.dart';
import '../../../platform_observability/domain/usecases/mark_platform_error_resolved_usecase.dart';
import '../../../platform_observability/domain/usecases/watch_platform_error_logs_usecase.dart';
import '../../../platform_observability/presentation/cubit/platform_observability_cubit.dart';
import '../../../platform_observability/presentation/widgets/platform_monitoring_panel.dart';
import '../../../support/presentation/pages/platform_support_inbox_panel.dart';
import '../../domain/entities/android_version_adoption.dart';
import '../../domain/entities/company_data_health_report.dart';
import '../../domain/entities/release_intelligence.dart';
import '../../../users/domain/entities/company_metadata.dart';
import '../../data/datasources/platform_remote_data_source.dart';
import '../../data/repositories/platform_repository_impl.dart';
import '../../domain/entities/platform_company_user.dart';
import '../../domain/entities/platform_login_activity.dart';
import '../../domain/entities/platform_payment_history.dart';
import '../../domain/usecases/add_user_to_company_usecase.dart';
import '../../domain/usecases/backfill_assigned_record_snapshots_usecase.dart';
import '../../domain/usecases/create_company_with_admin_usecase.dart';
import '../../domain/usecases/create_platform_release_record_usecase.dart';
import '../../domain/usecases/export_company_data_usecase.dart';
import '../../domain/usecases/extend_company_payment_due_date_usecase.dart';
import '../../domain/usecases/get_android_release_policy_usecase.dart';
import '../../domain/usecases/get_android_version_adoption_usecase.dart';
import '../../domain/usecases/get_platform_device_list_usecase.dart';
import '../../domain/usecases/get_platform_version_adoption_usecase.dart';
import '../../domain/usecases/get_platform_version_history_usecase.dart';
import '../../domain/usecases/get_release_intelligence_summary_usecase.dart';
import '../../domain/usecases/get_company_data_health_report_usecase.dart';
import '../../domain/usecases/generate_company_user_password_reset_link_usecase.dart';
import '../../domain/usecases/mark_company_payment_paid_usecase.dart';
import '../../domain/usecases/refresh_company_storage_usage_usecase.dart';
import '../../domain/usecases/set_company_active_status_usecase.dart';
import '../../domain/usecases/set_company_user_active_status_usecase.dart';
import '../../domain/usecases/set_company_user_email_usecase.dart';
import '../../domain/usecases/set_company_user_password_usecase.dart';
import '../../domain/usecases/update_company_platform_settings_usecase.dart';
import '../../domain/usecases/update_company_payment_status_usecase.dart';
import '../../domain/usecases/update_android_release_policy_usecase.dart';
import '../../domain/usecases/watch_platform_companies_usecase.dart';
import '../../domain/usecases/watch_platform_company_users_usecase.dart';
import '../../domain/usecases/watch_platform_login_activity_usecase.dart';
import '../../domain/usecases/watch_platform_payment_history_usecase.dart';
import '../cubit/platform_cubit.dart';
import '../cubit/platform_state.dart';
import '../../../../core/widgets/masar_loading_view.dart';

class PlatformPage extends StatelessWidget {
  const PlatformPage({
    super.key,
    this.initialSupportInbox = false,
    this.initialNotifications = false,
    this.initialMonitoring = false,
  });

  final bool initialSupportInbox;
  final bool initialNotifications;
  final bool initialMonitoring;

  static Widget withDependencies({
    bool initialSupportInbox = false,
    bool initialNotifications = false,
    bool initialMonitoring = false,
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
    final observabilityRemoteDataSource =
        FirebasePlatformObservabilityRemoteDataSource();
    final observabilityRepository = PlatformObservabilityRepositoryImpl(
      remoteDataSource: observabilityRemoteDataSource,
    );

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => PlatformCubit(
            watchCompaniesUseCase: WatchPlatformCompaniesUseCase(repository),
            watchCompanyUsersUseCase: WatchPlatformCompanyUsersUseCase(
              repository,
            ),
            watchPaymentHistoryUseCase:
                WatchPlatformPaymentHistoryUseCase(repository),
            watchLoginActivityUseCase:
                WatchPlatformLoginActivityUseCase(repository),
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
            exportCompanyDataUseCase: ExportCompanyDataUseCase(repository),
            markCompanyPaymentPaidUseCase:
                MarkCompanyPaymentPaidUseCase(repository),
            extendCompanyPaymentDueDateUseCase:
                ExtendCompanyPaymentDueDateUseCase(repository),
            updateCompanyPaymentStatusUseCase:
                UpdateCompanyPaymentStatusUseCase(repository),
            updateAndroidReleasePolicyUseCase:
                UpdateAndroidReleasePolicyUseCase(repository),
            getAndroidReleasePolicyUseCase:
                GetAndroidReleasePolicyUseCase(repository),
            getAndroidVersionAdoptionUseCase:
                GetAndroidVersionAdoptionUseCase(repository),
            getReleaseIntelligenceSummaryUseCase:
                GetReleaseIntelligenceSummaryUseCase(repository),
            getPlatformVersionAdoptionUseCase:
                GetPlatformVersionAdoptionUseCase(repository),
            getPlatformDeviceListUseCase:
                GetPlatformDeviceListUseCase(repository),
            getPlatformVersionHistoryUseCase:
                GetPlatformVersionHistoryUseCase(repository),
            createPlatformReleaseRecordUseCase:
                CreatePlatformReleaseRecordUseCase(repository),
          )
            ..watchCompanies()
            ..loadAndroidReleasePolicy(),
        ),
        BlocProvider(
          create: (_) => PlatformInvitationsCubit(
            createCompanyInvitationUseCase:
                CreateCompanyInvitationUseCase(invitationsRepository),
            listCompanyInvitationsUseCase:
                ListCompanyInvitationsUseCase(invitationsRepository),
            revokeCompanyInvitationUseCase:
                RevokeCompanyInvitationUseCase(invitationsRepository),
          ),
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
          )..watchUnreadCount(),
        ),
        BlocProvider(
          create: (_) => PlatformObservabilityCubit(
            watchErrorLogsUseCase:
                WatchPlatformErrorLogsUseCase(observabilityRepository),
            markResolvedUseCase:
                MarkPlatformErrorResolvedUseCase(observabilityRepository),
          ),
        ),
      ],
      child: PlatformPage(
        key: ValueKey(
          'platform-page:$initialSupportInbox:$initialNotifications:$initialMonitoring',
        ),
        initialSupportInbox: initialSupportInbox,
        initialNotifications: initialNotifications,
        initialMonitoring: initialMonitoring,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return MultiBlocListener(
      listeners: [
        BlocListener<AuthBloc, AuthState>(
          listenWhen: (previous, current) {
            return previous.user?.uid != current.user?.uid ||
                current.status == AuthStatus.unauthenticated;
          },
          listener: (context, state) {
            context.read<PlatformCubit>().clearOwnerSessionCache();
          },
        ),
        BlocListener<PlatformCubit, PlatformState>(
          listenWhen: (previous, current) {
            return previous.status != current.status &&
                current.status == PlatformStatus.failure &&
                current.message != null;
          },
          listener: (context, state) {
            if (!context.mounted) {
              return;
            }
            AppFeedback.error(context, _platformErrorMessage(l, state.message));
          },
        ),
      ],
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
                          message: _platformErrorMessage(
                            l,
                            state.message,
                            fallback: l.somethingWentWrong,
                          ),
                          onRetry: context.read<PlatformCubit>().watchCompanies,
                        );
                      }

                      return _PlatformWorkspace(
                        state: state,
                        initialSupportInbox: initialSupportInbox,
                        initialNotifications: initialNotifications,
                        initialMonitoring: initialMonitoring,
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
          final adminName = _platformUserName(authState, l.platformAdmin);
          final greeting = _platformGreeting(l, DateTime.now());
          final adminPhotoUrl = (authState.user?.photoUrl ?? '').trim();

          return LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 900;
              final title = _PlatformHeaderTitle(
                adminName: adminName,
                greeting: greeting,
                photoUrl: adminPhotoUrl,
              );
              final actions = const _PlatformTopActions();

              if (compact) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(child: title),
                        const SizedBox(width: AppSpacing.xs),
                        actions,
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    const _PlatformTopCompanySelector(),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(flex: 4, child: title),
                  const SizedBox(width: AppSpacing.sm),
                  Flexible(
                    flex: 3,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 300),
                      child: AppSearchField(
                        hint: l.platformSearchHint,
                        onChanged:
                            context.read<PlatformCubit>().updateSearchQuery,
                        onClear: () => context
                            .read<PlatformCubit>()
                            .updateSearchQuery(''),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Flexible(
                    flex: 3,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 260),
                      child: const _PlatformTopCompanySelector(),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  actions,
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _PlatformHeaderTitle extends StatelessWidget {
  const _PlatformHeaderTitle({
    required this.adminName,
    required this.greeting,
    required this.photoUrl,
  });

  final String adminName;
  final String greeting;
  final String photoUrl;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Row(
      children: [
        _PlatformAvatar(name: adminName, photoUrl: photoUrl),
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
      ],
    );
  }
}

class _PlatformTopActions extends StatelessWidget {
  const _PlatformTopActions();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        PlatformNotificationsBell(
          onPressed: () => context.go(RouteNames.platformNotifications),
          compact: true,
        ),
        const _PlatformLanguageButton(),
        const _PlatformThemeButton(),
        const SizedBox(width: AppSpacing.xs),
        const _PlatformProfileMenu(),
      ],
    );
  }
}

class _PlatformTopCompanySelector extends StatelessWidget {
  const _PlatformTopCompanySelector({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return BlocBuilder<PlatformCubit, PlatformState>(
      buildWhen: (previous, current) =>
          previous.selectedCompanyId != current.selectedCompanyId ||
          previous.companies != current.companies,
      builder: (context, state) {
        final companies = state.companies;
        final selected = state.selectedCompany;
        if (companies.isEmpty) {
          return const SizedBox.shrink();
        }

        return PopupMenuButton<String>(
          tooltip: l.allCompanies,
          onSelected: (companyId) =>
              context.read<PlatformCubit>().selectCompany(companyId),
          itemBuilder: (context) => [
            for (final company in companies)
              PopupMenuItem<String>(
                value: company.id,
                child: Row(
                  children: [
                    Icon(
                      state.selectedCompanyId == company.id
                          ? Icons.check_circle
                          : Icons.apartment_outlined,
                      size: 18,
                      color: state.selectedCompanyId == company.id
                          ? AppColors.primaryColor(context)
                          : AppColors.textSecondaryColor(context),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _companyTitle(company),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          Text(
                            company.id,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.textSecondaryColor(context),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
          child: Container(
            height: 44,
            padding: EdgeInsets.symmetric(
              horizontal: compact ? AppSpacing.sm : AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: AppColors.inputSurface(context),
              border: Border.all(color: AppColors.borderColor(context)),
              borderRadius: AppRadius.large,
            ),
            child: Row(
              mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
              children: [
                Icon(
                  Icons.apartment_outlined,
                  size: 20,
                  color: AppColors.primaryColor(context),
                ),
                if (!compact) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.allCompanies,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: AppColors.textSecondaryColor(context),
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        Text(
                          selected == null ? l.noCompanySelected : _companyTitle(selected),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(width: AppSpacing.xs),
                Icon(
                  Icons.keyboard_arrow_down,
                  size: 18,
                  color: AppColors.textSecondaryColor(context),
                ),
              ],
            ),
          ),
        );
      },
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
                context.go(RouteNames.settings);
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
                  return Material(
                    color: Colors.transparent,
                    child: SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l.theme),
                      subtitle: Text(isDark ? l.darkMode : l.lightMode),
                      value: isDark,
                      onChanged: (_) => themeCubit.toggle(),
                    ),
                  );
                },
              ),
              BlocBuilder<LocaleCubit, Locale?>(
                bloc: localeCubit,
                builder: (context, locale) {
                  final selected = locale?.languageCode ?? 'en';
                  return Column(
                    children: [
                      Material(
                        color: Colors.transparent,
                        child: RadioListTile<String>(
                          contentPadding: EdgeInsets.zero,
                          title: Text(l.english),
                          value: 'en',
                          groupValue: selected,
                          onChanged: (_) => localeCubit.setEnglish(),
                        ),
                      ),
                      Material(
                        color: Colors.transparent,
                        child: RadioListTile<String>(
                          contentPadding: EdgeInsets.zero,
                          title: Text(l.arabic),
                          value: 'ar',
                          groupValue: selected,
                          onChanged: (_) => localeCubit.setArabic(),
                        ),
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
  monitoring,
  notifications,
  invitations,
  companies,
  workspace,
  releaseManagement,
  support,
  activity,
}

enum _WorkspaceTab {
  summary,
  payments,
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
    required this.initialMonitoring,
  });

  final PlatformState state;
  final bool initialSupportInbox;
  final bool initialNotifications;
  final bool initialMonitoring;

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
        : widget.initialMonitoring
            ? _PlatformSection.monitoring
        : widget.initialSupportInbox
            ? _PlatformSection.support
            : _PlatformSection.overview;
  }

  @override
  void didUpdateWidget(covariant _PlatformWorkspace oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.initialNotifications && widget.initialNotifications) {
      _section = _PlatformSection.notifications;
    } else if (!oldWidget.initialMonitoring && widget.initialMonitoring) {
      _section = _PlatformSection.monitoring;
    } else if (!oldWidget.initialSupportInbox && widget.initialSupportInbox) {
      _section = _PlatformSection.support;
    }
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
      _PlatformSection.monitoring => [
        PlatformMonitoringPanel(companies: state.companies),
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
      _PlatformSection.releaseManagement => [_PlatformReleaseManagementPanel(state: state)],
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

class _PlatformDashboardOverview extends StatefulWidget {
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
  State<_PlatformDashboardOverview> createState() =>
      _PlatformDashboardOverviewState();
}

class _PlatformDashboardOverviewState extends State<_PlatformDashboardOverview> {
  @override
  void initState() {
    super.initState();
    _scheduleOverviewDataLoad();
  }

  @override
  void didUpdateWidget(covariant _PlatformDashboardOverview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.selectedCompanyId != widget.state.selectedCompanyId) {
      _scheduleOverviewDataLoad();
    }
  }

  void _scheduleOverviewDataLoad() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final companyId = widget.state.selectedCompany?.id;
      if (companyId == null) return;
      final cubit = context.read<PlatformCubit>();
      cubit.ensureCompanyUsersLoaded(companyId);
      cubit.ensureLoginActivityLoaded(companyId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PlatformHeroCard(state: state),
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
                  onOpenWorkspace: widget.onOpenWorkspace,
                ),
                const SizedBox(height: AppSpacing.md),
                _DashboardCompaniesPanel(
                  state: state,
                  onOpenCompanies: widget.onOpenCompanies,
                  onOpenWorkspace: widget.onOpenWorkspace,
                ),
              ],
            );
            final side = Column(
              children: [
                _DashboardActivityPanel(
                  state: state,
                  onOpenActivity: widget.onOpenActivity,
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
        PlatformCompanyFilter.trialExpired => company.status == 'trialExpired',
        PlatformCompanyFilter.paid => _paymentStatus(company) == 'paid',
        PlatformCompanyFilter.dueSoon => _paymentStatus(company) == 'dueSoon',
        PlatformCompanyFilter.overdue => _paymentStatus(company) == 'overdue',
        PlatformCompanyFilter.gracePeriod =>
          _paymentStatus(company) == 'gracePeriod',
        PlatformCompanyFilter.suspended => _paymentStatus(company) == 'suspended',
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 520;
        final status = AppStatusBadge(
          label: _statusLabel(l, company),
          tone: _isOperationalCompany(company)
              ? AppStatusTone.success
              : AppStatusTone.neutral,
        );
        final users = Text(
          selected
              ? _usersUsedLabel(context, state, company)
              : _limitLabel(context, company.limits['users']),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondaryColor(context),
                fontWeight: FontWeight.w700,
              ),
        );
        final createdAt = Text(
          _formatDate(context, company.createdAt),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondaryColor(context),
              ),
        );

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
          child: narrow
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.business_outlined,
                          color: AppColors.primaryColor(context),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(child: _DashboardCompanyTitle(company: company)),
                        _CompanyActionsMenu(
                          company: company,
                          onOpenWorkspace: onOpenWorkspace,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [status, users, createdAt],
                    ),
                  ],
                )
              : Row(
                  children: [
                    Icon(
                      Icons.business_outlined,
                      color: AppColors.primaryColor(context),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(child: _DashboardCompanyTitle(company: company)),
                    status,
                    const SizedBox(width: AppSpacing.sm),
                    Flexible(child: users),
                    const SizedBox(width: AppSpacing.sm),
                    Flexible(child: createdAt),
                    _CompanyActionsMenu(
                      company: company,
                      onOpenWorkspace: onOpenWorkspace,
                    ),
                  ],
                ),
        );
      },
    );
  }
}

class _DashboardCompanyTitle extends StatelessWidget {
  const _DashboardCompanyTitle({required this.company});

  final CompanyMetadata company;

  @override
  Widget build(BuildContext context) {
    return Column(
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
    final company = state.selectedCompany;
    final activityLoaded =
        state.hasSelectedCompanyUsers && state.hasSelectedLoginActivities;
    final users = state.companyUsers
        .where((user) =>
            user.lastLoginAt != null ||
            _activitiesForUser(state.loginActivities, user.uid).isNotEmpty)
        .toList(growable: false)
      ..sort((a, b) => _latestLoginAt(state, b).compareTo(_latestLoginAt(state, a)));
    final visible = users.take(5).toList(growable: false);
    final Widget content;
    if (company == null) {
      content = AppEmptyState(
        icon: Icons.apartment_outlined,
        title: l.noCompanySelected,
        message: l.noCompanySelectedMessage,
      );
    } else if (!activityLoaded &&
        (state.companyUsersLoading || state.loginActivitiesLoading)) {
      content = const AppLoading();
    } else if (!activityLoaded) {
      content = AppEmptyState(
        icon: Icons.manage_history_outlined,
        title: l.platformRecentActivity,
        message: l.platformActivityDeferredMessage,
      );
    } else if (visible.isEmpty) {
      content = AppEmptyState(
        icon: Icons.manage_history_outlined,
        title: l.platformNoRecentActivity,
        message: l.noLoginActivityYet,
      );
    } else {
      content = Column(
        children: [
          for (final user in visible) ...[
            _LoginActivityRow(
              user: user,
              activities: _activitiesForUser(state.loginActivities, user.uid),
              onTap: () => _showLoginActivitySheet(
                context,
                user: user,
                activities: _activitiesForUser(state.loginActivities, user.uid),
              ),
            ),
            if (user != visible.last)
              const SizedBox(height: AppSpacing.xs),
          ],
        ],
      );
    }

    return _Panel(
      title: l.platformRecentActivity,
      action: TextButton.icon(
        onPressed: company == null ? null : onOpenActivity,
        icon: const Icon(Icons.history),
        label: Text(l.platformViewAllLogs),
      ),
      child: content,
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
    if (company != null &&
        !state.hasSelectedCompanyUsers &&
        state.companyUsersLoading) {
      return _Panel(
        title: l.platformWorkspaceSummary,
        child: const AppLoading(),
      );
    }
    if (company != null && !state.hasSelectedCompanyUsers) {
      return _Panel(
        title: l.platformWorkspaceSummary,
        child: AppEmptyState(
          icon: Icons.people_outline,
          title: l.platformWorkspaceSummary,
          message: l.platformWorkspaceSummaryDeferredMessage,
        ),
      );
    }
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
  void initState() {
    super.initState();
    _scheduleSelectedTabLoad();
  }

  @override
  void didUpdateWidget(covariant _CompanyWorkspacePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.selectedCompanyId != widget.state.selectedCompanyId) {
      _scheduleSelectedTabLoad();
    }
  }

  void _scheduleSelectedTabLoad() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadSelectedTabData();
    });
  }

  void _loadSelectedTabData() {
    final companyId = widget.state.selectedCompany?.id;
    if (companyId == null) return;
    final cubit = context.read<PlatformCubit>();
    switch (_tab) {
      case _WorkspaceTab.summary:
      case _WorkspaceTab.users:
        cubit.ensureCompanyUsersLoaded(companyId);
        break;
      case _WorkspaceTab.payments:
        cubit.ensurePaymentHistoryLoaded(companyId);
        break;
      case _WorkspaceTab.features:
      case _WorkspaceTab.limits:
      case _WorkspaceTab.settings:
      case _WorkspaceTab.maintenance:
      case _WorkspaceTab.preview:
        break;
    }
  }

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
          onSelected: (tab) {
            setState(() => _tab = tab);
            _scheduleSelectedTabLoad();
          },
        ),
        const SizedBox(height: AppSpacing.md),
        switch (_tab) {
          _WorkspaceTab.summary => _CompanyDetailsPanel(state: widget.state),
          _WorkspaceTab.payments => _CompanyPaymentPanel(state: widget.state),
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
            label: l.exportCompanyData,
            icon: Icons.file_download_outlined,
            variant: AppButtonVariant.secondary,
            isLoading: state.activeCompanyActionId == 'export:${company.id}',
            onPressed: state.activeCompanyActionId == 'export:${company.id}'
                ? null
                : () => _exportCompanyData(context, company),
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
            label: l.paymentStatus,
            value: _paymentStatusLabel(l, _paymentStatus(company)),
          ),
          if (company.nextPaymentDueAt != null)
            _InfoChip(
              label: l.nextPaymentDue,
              value: _formatDate(context, company.nextPaymentDueAt!),
            ),
          _InfoChip(label: l.amount, value: _paymentAmountLabel(company)),
          if (company.trialEndsAt != null)
            _InfoChip(label: l.trialEndsAt, value: _formatDate(context, company.trialEndsAt!)),
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
    return MasarSwitchTabBar(
      selectedIndex: _WorkspaceTab.values.indexOf(selected),
      onChanged: (index) => onSelected(_WorkspaceTab.values[index]),
      compact: true,
      tabs: [
        for (final tab in _WorkspaceTab.values)
          MasarSwitchTabItem(
            label: _workspaceTabLabel(l, tab),
            icon: _workspaceTabIcon(tab),
          ),
      ],
    );
  }
}

class _PlatformActivityPanel extends StatefulWidget {
  const _PlatformActivityPanel({required this.state});

  final PlatformState state;

  @override
  State<_PlatformActivityPanel> createState() => _PlatformActivityPanelState();
}

class _PlatformActivityPanelState extends State<_PlatformActivityPanel> {
  @override
  void initState() {
    super.initState();
    _scheduleActivityLoad();
  }

  @override
  void didUpdateWidget(covariant _PlatformActivityPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.selectedCompanyId != widget.state.selectedCompanyId) {
      _scheduleActivityLoad();
    }
  }

  void _scheduleActivityLoad() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final companyId = widget.state.selectedCompany?.id;
      if (companyId == null) return;
      final cubit = context.read<PlatformCubit>();
      cubit.ensureCompanyUsersLoaded(companyId);
      cubit.ensureLoginActivityLoaded(companyId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final state = widget.state;
    final company = state.selectedCompany;
    final users = state.companyUsers.toList(growable: false)
      ..sort((a, b) {
        final aLatest = _latestLoginAt(state, a);
        final bLatest = _latestLoginAt(state, b);
        final compare = bLatest.compareTo(aLatest);
        if (compare != 0) return compare;
        return a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase());
      });
    final visibleUsers = users;

    return _Panel(
      title: l.recentLoginActivity,
      child: company == null
          ? AppEmptyState(
              icon: Icons.apartment_outlined,
              title: l.noCompanySelected,
              message: l.noCompanySelectedMessage,
            )
          : state.companyUsersLoading ||
                  state.loginActivitiesLoading ||
                  !state.hasSelectedCompanyUsers ||
                  !state.hasSelectedLoginActivities
              ? const AppLoading()
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
                      _LoginActivityRow(
                        user: user,
                        activities: _activitiesForUser(state.loginActivities, user.uid),
                        onTap: () => _showLoginActivitySheet(
                          context,
                          user: user,
                          activities: _activitiesForUser(state.loginActivities, user.uid),
                        ),
                      ),
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
                label: l.paymentStatus,
                value: _paymentStatusLabel(l, _paymentStatus(company)),
              ),
              if (company.nextPaymentDueAt != null)
                _InfoChip(
                  label: l.nextPaymentDue,
                  value: _formatDate(context, company.nextPaymentDueAt!),
                ),
              _InfoChip(label: l.amount, value: _paymentAmountLabel(company)),
              if (company.trialEndsAt != null)
                _InfoChip(label: l.trialEndsAt, value: _formatDate(context, company.trialEndsAt!)),
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

class _CompanyPaymentPanel extends StatelessWidget {
  const _CompanyPaymentPanel({required this.state});

  final PlatformState state;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final company = state.selectedCompany;
    if (company == null) {
      return _Panel(
        title: l.paymentFollowUp,
        child: AppEmptyState(
          icon: Icons.payments_outlined,
          title: l.noCompanySelected,
          message: l.noCompanySelectedMessage,
        ),
      );
    }

    final status = _paymentStatus(company);
    final busy = state.activeSettingsActionId == 'payment:${company.id}';
    return _Panel(
      title: l.paymentFollowUp,
      action: AppStatusBadge(
        label: _paymentStatusLabel(l, status),
        tone: _paymentStatusTone(status),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 900 ? 4 : constraints.maxWidth >= 560 ? 2 : 1;
              return GridView.count(
                crossAxisCount: columns,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: AppSpacing.sm,
                mainAxisSpacing: AppSpacing.sm,
                childAspectRatio: constraints.maxWidth < 560 ? 2.8 : 2.25,
                children: [
                  _KpiCard(
                    label: l.paidCompanies,
                    value: state.companies.where((item) => _paymentStatus(item) == 'paid').length.toString(),
                    icon: Icons.verified_outlined,
                    tone: AppStatusTone.success,
                  ),
                  _KpiCard(
                    label: l.dueSoon,
                    value: state.companies.where((item) => _paymentStatus(item) == 'dueSoon').length.toString(),
                    icon: Icons.schedule_outlined,
                    tone: AppStatusTone.warning,
                  ),
                  _KpiCard(
                    label: l.overdue,
                    value: state.companies.where((item) => _paymentStatus(item) == 'overdue').length.toString(),
                    icon: Icons.warning_amber_outlined,
                    tone: AppStatusTone.error,
                  ),
                  _KpiCard(
                    label: l.expectedThisMonth,
                    value: _expectedThisMonthLabel(state.companies, company.paymentCurrency),
                    icon: Icons.payments_outlined,
                    tone: AppStatusTone.info,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _InfoChip(label: l.paymentStatus, value: _paymentStatusLabel(l, status)),
              _InfoChip(label: l.nextPaymentDue, value: _dateOrEmpty(context, company.nextPaymentDueAt)),
              _InfoChip(label: l.lastPayment, value: _dateOrEmpty(context, company.lastPaymentAt)),
              _InfoChip(label: l.amount, value: _paymentAmountLabel(company)),
              _InfoChip(label: l.paymentCycle, value: _paymentCycleLabel(l, company.paymentCycle)),
              _InfoChip(label: l.daysRemaining, value: _paymentDaysLabel(context, company)),
              if ((company.paymentNotes ?? '').trim().isNotEmpty)
                _InfoChip(label: l.paymentNotes, value: company.paymentNotes!.trim()),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              AppButton(
                label: l.markAsPaid,
                icon: Icons.check_circle_outline,
                isLoading: busy,
                onPressed: busy ? null : () => _showPaymentDialog(context, company, _PaymentAction.markPaid),
              ),
              AppButton(
                label: l.extendDueDate,
                icon: Icons.event_available_outlined,
                variant: AppButtonVariant.secondary,
                isLoading: busy,
                onPressed: busy ? null : () => _showPaymentDialog(context, company, _PaymentAction.extend),
              ),
              AppButton(
                label: l.addNote,
                icon: Icons.note_add_outlined,
                variant: AppButtonVariant.secondary,
                isLoading: busy,
                onPressed: busy ? null : () => _showPaymentDialog(context, company, _PaymentAction.note),
              ),
              AppButton(
                label: l.moveToGracePeriod,
                icon: Icons.hourglass_bottom_outlined,
                variant: AppButtonVariant.secondary,
                isLoading: busy,
                onPressed: busy ? null : () => _showPaymentDialog(context, company, _PaymentAction.grace),
              ),
              AppButton(
                label: l.suspendCompany,
                icon: Icons.block,
                variant: AppButtonVariant.danger,
                isLoading: busy,
                onPressed: busy ? null : () => _showPaymentDialog(context, company, _PaymentAction.suspend),
              ),
              AppButton(
                label: l.reactivateCompany,
                icon: Icons.restart_alt,
                variant: AppButtonVariant.secondary,
                isLoading: busy,
                onPressed: busy ? null : () => _showPaymentDialog(context, company, _PaymentAction.reactivate),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            l.paymentHistory,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (state.paymentHistoryLoading || !state.hasSelectedPaymentHistory)
            const AppLoading()
          else if (state.paymentHistory.isEmpty)
            AppEmptyState(
              icon: Icons.receipt_long_outlined,
              title: l.paymentHistory,
              message: l.noPaymentHistory,
            )
          else
            Column(
              children: [
                for (final item in state.paymentHistory.take(12))
                  _PaymentHistoryRow(item: item),
              ],
            ),
        ],
      ),
    );
  }
}

class _PaymentHistoryRow extends StatelessWidget {
  const _PaymentHistoryRow({required this.item});

  final PlatformPaymentHistory item;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final amount = item.amount <= 0 ? '-' : '${item.amount.toStringAsFixed(item.amount.truncateToDouble() == item.amount ? 0 : 2)} ${item.currency}';
    final subtitle = [
      amount,
      if (item.nextPaymentDueAt != null) '${l.nextPaymentDue}: ${_formatDate(context, item.nextPaymentDueAt!)}',
      if (item.notes.trim().isNotEmpty) item.notes.trim(),
    ].where((value) => value.trim().isNotEmpty).join(' - ');

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.appBackground(context),
          border: Border.all(color: AppColors.borderColor(context)),
          borderRadius: AppRadius.large,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.receipt_long_outlined, color: AppColors.primaryColor(context)),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _paymentActionLabel(l, item.action),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondaryColor(context),
                          ),
                    ),
                  ],
                ],
              ),
            ),
            if (item.createdAt != null)
              Text(
                _shortDate(context, item.createdAt!),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondaryColor(context),
                    ),
              ),
          ],
        ),
      ),
    );
  }
}

enum _PaymentAction { markPaid, extend, note, grace, suspend, reactivate }

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
    final usersLoaded = state.hasSelectedCompanyUsers;
    final userLimitReached =
        usersLoaded && userLimit != null && state.companyUsers.length >= userLimit;
    final filteredUsers = _filteredUsers(state.companyUsers);

    return _Panel(
      title: l.companyUsers,
      action: AppButton(
        label: l.platformSupportAddUser,
        icon: Icons.person_add_alt_1,
        variant: AppButtonVariant.secondary,
        onPressed: state.status == PlatformStatus.saving ||
                userLimitReached ||
                !usersLoaded
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
          if (state.companyUsersLoading || !usersLoaded)
            const AppLoading()
          else if (state.companyUsers.isEmpty)
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


class _PlatformReleaseManagementPanel extends StatefulWidget {
  const _PlatformReleaseManagementPanel({required this.state});

  final PlatformState state;

  @override
  State<_PlatformReleaseManagementPanel> createState() =>
      _PlatformReleaseManagementPanelState();
}

class _PlatformReleaseManagementPanelState
    extends State<_PlatformReleaseManagementPanel> {
  var _tabIndex = 0;

  Widget _buildSelectedTab(PlatformState state) {
    return switch (_tabIndex) {
      0 => _ReleaseOverviewTab(state: state),
      1 => _ReleaseRegistryTab(state: state),
      2 => _ReleaseAdoptionDevicesTab(
          adoptionRows: state.releaseAdoptionRows,
          deviceRows: state.releaseDeviceRows,
        ),
      3 => _ReleasePolicyTab(state: state),
      _ => _ReleaseHistoryTab(rows: state.releaseVersionEvents),
    };
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final state = widget.state;
    final adoptionDevicesLabel = '${l.versionAdoption} / ${l.devices}';
    final tabs = [
      MasarSwitchTabItem(label: l.releaseOverview, icon: Icons.insights_outlined),
      MasarSwitchTabItem(label: l.releases, icon: Icons.inventory_2_outlined),
      MasarSwitchTabItem(
        label: adoptionDevicesLabel,
        icon: Icons.devices_other_outlined,
      ),
      MasarSwitchTabItem(
        label: l.androidReleaseManagement,
        icon: Icons.admin_panel_settings_outlined,
      ),
      MasarSwitchTabItem(label: l.versionHistory, icon: Icons.history_rounded),
    ];
    if (_tabIndex >= tabs.length) {
      _tabIndex = tabs.length - 1;
    }
    return _Panel(
      title: l.releaseCenter,
      action: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          AppButton(
            label: l.tryAgain,
            icon: Icons.refresh_rounded,
            variant: AppButtonVariant.ghost,
            isLoading: state.activeSettingsActionId == 'androidRelease:load',
            onPressed: state.status == PlatformStatus.saving
                ? null
                : context.read<PlatformCubit>().loadAndroidReleasePolicy,
          ),
          AppButton(
            label: l.androidReleaseManagement,
            icon: Icons.tune_outlined,
            variant: AppButtonVariant.secondary,
            isLoading: state.activeSettingsActionId == 'androidRelease',
            onPressed: state.status == PlatformStatus.saving
                ? null
                : () => _showAndroidReleasePolicyDialog(context),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ReleaseCompanyFilter(state: state),
          const SizedBox(height: AppSpacing.md),
          MasarSwitchTabBar(
            tabs: tabs,
            selectedIndex: _tabIndex,
            onChanged: (index) => setState(() => _tabIndex = index),
            compact: true,
          ),
          const SizedBox(height: AppSpacing.md),
          _buildSelectedTab(state),
        ],
      ),
    );
  }
}

class _ReleaseCompanyFilter extends StatelessWidget {
  const _ReleaseCompanyFilter({required this.state});

  final PlatformState state;
  static const _allCompaniesValue = '__all_companies__';

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return LayoutBuilder(
      builder: (context, constraints) {
        final selectedValue = state.releaseCompanyId?.trim().isNotEmpty == true
            ? state.releaseCompanyId!.trim()
            : _allCompaniesValue;
        final dropdown = AppDropdown<String>(
          key: ValueKey('releaseCompany:$selectedValue'),
          label: l.company,
          value: selectedValue,
          items: <String>[
            _allCompaniesValue,
            ...state.companies.map((company) => company.id),
          ],
          itemLabelBuilder: (value) {
            if (value == _allCompaniesValue || value.trim().isEmpty) {
              return l.allCompanies;
            }
            final company = _companyById(state.companies, value);
            return company == null ? value : _companyTitle(company);
          },
          onChanged: (value) {
            final companyId = value == _allCompaniesValue ? null : value;
            context.read<PlatformCubit>().updateReleaseCompanyFilter(companyId);
          },
        );
        if (constraints.maxWidth < 560) {
          return dropdown;
        }
        return Row(
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: dropdown,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                state.releaseCompanyId == null
                    ? l.releaseCenterAllCompaniesHint
                    : l.releaseCenterSelectedCompanyHint,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondaryColor(context),
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ReleaseOverviewTab extends StatelessWidget {
  const _ReleaseOverviewTab({required this.state});

  final PlatformState state;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final summary = state.releaseIntelligenceSummary;
    if (summary == null &&
        state.releaseAdoptionRows.isEmpty &&
        state.releaseDeviceRows.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ReleaseGuidancePanel(
            message: l.releaseOverviewGuidance,
            notes: [
              state.releaseCompanyId == null
                  ? l.releaseCenterAllCompaniesHint
                  : l.releaseOverviewMixedScopeHint,
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          AppEmptyState(
            icon: Icons.insights_outlined,
            title: l.releaseOverview,
            message: l.noAdoptionDataYet,
          ),
        ],
      );
    }
    final latestActiveWeb = _latestActiveVersion(state.releaseAdoptionRows, 'web');
    final latestActiveAndroid =
        _latestActiveVersion(state.releaseAdoptionRows, 'android');
    final policy = state.androidReleasePolicy;
    final stats = _releaseDeviceStats(state.releaseDeviceRows);
    final latestWebBuild = _maxBuild([
      latestActiveWeb?.buildNumber ?? 0,
      _releaseBuild(summary?.latestWebRelease),
    ]);
    final latestAndroidBuild = _maxBuild([
      latestActiveAndroid?.buildNumber ?? 0,
      policy?.latestBuildNumber ?? 0,
      _releaseBuild(summary?.latestAndroidRelease),
    ]);
    final risk = _releaseRiskStats(
      rows: state.releaseDeviceRows,
      latestWebBuild: latestWebBuild,
      latestAndroidBuild: latestAndroidBuild,
      minimumAndroidBuild: policy?.minimumSupportedBuildNumber ?? 0,
    );
    final useSummaryCounts =
        state.releaseCompanyId == null && state.releaseDeviceRows.isEmpty;
    final activeUsers = useSummaryCounts
        ? summary?.activeUsers ?? stats.activeUsers
        : stats.activeUsers;
    final activeDevices = useSummaryCounts
        ? summary?.activeDevices ?? stats.activeDevices
        : stats.activeDevices;
    final activeWebUsers = useSummaryCounts
        ? summary?.activeWebUsers ?? stats.activeWebUsers
        : stats.activeWebUsers;
    final activeWebDevices = useSummaryCounts
        ? summary?.activeWebDevices ?? stats.activeWebDevices
        : stats.activeWebDevices;
    final activeAndroidUsers = useSummaryCounts
        ? summary?.activeAndroidUsers ?? stats.activeAndroidUsers
        : stats.activeAndroidUsers;
    final activeAndroidDevices = useSummaryCounts
        ? summary?.activeAndroidDevices ?? stats.activeAndroidDevices
        : stats.activeAndroidDevices;
    final oldUsers = useSummaryCounts
        ? summary?.usersBelowLatestBuild ?? risk.usersBelowLatest
        : risk.usersBelowLatest;
    final oldDevices = useSummaryCounts
        ? summary?.devicesBelowLatestBuild ?? risk.devicesBelowLatest
        : risk.devicesBelowLatest;
    final belowMinimumUsers = useSummaryCounts
        ? summary?.usersBelowMinimumBuild ?? risk.usersBelowMinimum
        : risk.usersBelowMinimum;
    final belowMinimumDevices = useSummaryCounts
        ? summary?.devicesBelowMinimumBuild ?? risk.devicesBelowMinimum
        : risk.devicesBelowMinimum;
    final latestUsers = _nonNegative(activeUsers - oldUsers);
    final latestDevices = _nonNegative(activeDevices - oldDevices);
    final pushConnected = useSummaryCounts
        ? summary?.pushConnected ?? stats.pushConnected
        : stats.pushConnected;
    final pushBlocked = useSummaryCounts
        ? summary?.pushBlocked ?? stats.pushBlocked
        : stats.pushBlocked;
    final pushMissing = useSummaryCounts
        ? summary?.pushMissing ?? stats.pushMissing
        : stats.pushMissing;
    final pushInvalidFailed = useSummaryCounts
        ? summary?.pushInvalidFailed ?? stats.pushInvalidFailed
        : stats.pushInvalidFailed;
    final pushUnknown = useSummaryCounts
        ? summary?.pushUnknown ?? stats.pushUnknown
        : stats.pushUnknown;
    // Push buckets are notification token/device states; connected devices are notification-ready.
    final pushTotal =
        pushConnected + pushBlocked + pushMissing + pushInvalidFailed + pushUnknown;
    final notificationDeviceTotal = pushTotal == 0 ? activeDevices : pushTotal;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ReleaseGuidancePanel(
          message: l.releaseOverviewGuidance,
          notes: [
            state.releaseCompanyId == null
                ? l.releaseCenterAllCompaniesHint
                : l.releaseOverviewMixedScopeHint,
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        _ReleaseKpiGrid(
          children: [
            _ReleaseKpiCard(
              icon: Icons.language_rounded,
              title: l.latestWebVersion,
              value: _latestPlatformVersionLabel(
                l,
                active: latestActiveWeb,
                release: summary?.latestWebRelease,
              ),
              detail: '${l.webUsersDevices}: $activeWebUsers / $activeWebDevices',
              status: _latestPlatformStatusLabel(
                l,
                active: latestActiveWeb,
                release: summary?.latestWebRelease,
              ),
              tone: _latestPlatformTone(
                active: latestActiveWeb,
                release: summary?.latestWebRelease,
              ),
            ),
            _ReleaseKpiCard(
              icon: Icons.android_rounded,
              title: l.latestAndroidVersion,
              value: _latestPlatformVersionLabel(
                l,
                active: latestActiveAndroid,
                release: summary?.latestAndroidRelease,
                policy: policy,
              ),
              detail:
                  '${l.androidUsersDevices}: $activeAndroidUsers / $activeAndroidDevices',
              status: _latestPlatformStatusLabel(
                l,
                active: latestActiveAndroid,
                release: summary?.latestAndroidRelease,
                policy: policy,
              ),
              tone: _latestPlatformTone(
                active: latestActiveAndroid,
                release: summary?.latestAndroidRelease,
                policy: policy,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        _ReleaseKpiGrid(
          children: [
            _ReleaseKpiCard(
              icon: Icons.admin_panel_settings_outlined,
              title: l.androidReleaseManagement,
              value: policy == null
                  ? l.notAvailable
                  : '${l.enabled}: ${policy.enabled ? l.yes : l.no}',
              detail: policy == null
                  ? l.androidReleasePolicyHint
                  : '${l.releaseReady}: ${policy.releaseReady ? l.yes : l.no}',
              status: policy == null
                  ? null
                  : policy.releaseReady
                      ? l.releaseReady
                      : l.draft,
              tone: policy == null
                  ? AppStatusTone.neutral
                  : policy.enabled && policy.releaseReady
                      ? AppStatusTone.success
                      : AppStatusTone.warning,
            ),
            _ReleaseKpiCard(
              icon: Icons.verified_user_outlined,
              title: l.latest,
              value: '$latestUsers / $latestDevices',
              detail: '${l.activeUsers} / ${l.activeDevices}',
              tone: oldDevices == 0 ? AppStatusTone.success : AppStatusTone.info,
            ),
            _ReleaseKpiCard(
              icon: Icons.warning_amber_rounded,
              title: l.devicesBelowLatestBuild,
              value: oldDevices.toString(),
              detail: l.devicesBelowLatestBuildSummary(oldUsers, oldDevices),
              status: belowMinimumDevices > 0
                  ? l.oldBuild
                  : oldDevices > 0
                      ? l.oldBuild
                      : l.latest,
              tone: belowMinimumDevices > 0
                  ? AppStatusTone.error
                  : oldDevices > 0
                      ? AppStatusTone.warning
                      : AppStatusTone.success,
            ),
            _ReleaseKpiCard(
              icon: Icons.notifications_active_outlined,
              title: l.notificationReadyDevices,
              value: l.notificationReadyDevicesRatio(
                pushConnected,
                notificationDeviceTotal,
              ),
              detail: l.notificationReadyDevicesSummary(
                pushConnected,
                notificationDeviceTotal,
              ),
              status: pushConnected >= notificationDeviceTotal && notificationDeviceTotal > 0
                  ? l.connected
                  : l.requiresReview,
              tone: notificationDeviceTotal == 0
                  ? AppStatusTone.neutral
                  : pushConnected >= notificationDeviceTotal
                      ? AppStatusTone.success
                      : AppStatusTone.warning,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        _ReleaseSectionBlock(
          title: l.health,
          icon: Icons.health_and_safety_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  _ReleaseFieldView(
                    field: _ReleaseField(
                      l.notificationReadyDevices,
                      l.notificationReadyDevicesSummary(
                        pushConnected,
                        notificationDeviceTotal,
                      ),
                    ),
                  ),
                  _ReleaseFieldView(
                    field: _ReleaseField(l.notificationBlockedDevices, pushBlocked.toString()),
                  ),
                  _ReleaseFieldView(
                    field: _ReleaseField(l.notificationMissingDevices, pushMissing.toString()),
                  ),
                  _ReleaseFieldView(
                    field: _ReleaseField(
                      l.notificationInvalidFailedDevices,
                      pushInvalidFailed.toString(),
                    ),
                  ),
                  _ReleaseFieldView(
                    field: _ReleaseField(
                      l.lastUpdated,
                      summary?.lastUpdated == null
                          ? l.notAvailable
                          : _formatDate(context, summary!.lastUpdated!),
                    ),
                  ),
                ],
              ),
              if (policy == null || !policy.releaseReady) ...[
                const SizedBox(height: AppSpacing.sm),
                _ReleaseSignalPanel(
                  message: policy == null
                      ? l.androidReleasePolicyHint
                      : l.androidPolicyNotReadyAction,
                  fields: [
                    _ReleaseField(l.releaseReady, policy?.releaseReady == true ? l.yes : l.no),
                    _ReleaseField(l.belowMinimumBuild, '$belowMinimumUsers / $belowMinimumDevices'),
                    _ReleaseField(
                      l.notificationReadyDevices,
                      l.notificationReadyDevicesSummary(
                        pushConnected,
                        notificationDeviceTotal,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: AppSpacing.sm),
              Text(
                l.currentAdoptionHistoryHint,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondaryColor(context),
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReleaseRegistryTab extends StatelessWidget {
  const _ReleaseRegistryTab({required this.state});

  final PlatformState state;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final policy = state.androidReleasePolicy;
    final releases = state.releaseIntelligenceSummary?.releases ?? const [];
    return _ReleaseSectionBlock(
      title: l.releases,
      icon: Icons.inventory_2_outlined,
      action: policy == null
          ? null
          : AppButton(
              label: l.createReleaseRecordFromAndroidPolicy,
              icon: Icons.add_circle_outline,
              variant: AppButtonVariant.secondary,
              isLoading:
                  state.activeSettingsActionId == 'releaseRecord:androidPolicy',
              onPressed: state.status == PlatformStatus.saving
                  ? null
                  : () => _createReleaseRecordFromPolicy(context),
            ),
      child: releases.isEmpty
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ReleaseGuidancePanel(
                  message: l.releaseRegistryGuidance,
                  notes: [
                    l.releaseSectionPlatformWideNote,
                    l.releaseRegistryAndroidPolicyNote,
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                if (state.releaseCompanyId != null) ...[
                  _ReleaseScopeNote(message: l.releaseSectionPlatformWideNote),
                  const SizedBox(height: AppSpacing.sm),
                ],
                AppEmptyState(
                  icon: Icons.inventory_2_outlined,
                  title: l.releases,
                  message: l.releaseRecordsStartAfterRegistryEnabled,
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ReleaseGuidancePanel(
                  message: l.releaseRegistryGuidance,
                  notes: [
                    l.releaseSectionPlatformWideNote,
                    l.releaseRegistryAndroidPolicyNote,
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                if (state.releaseCompanyId != null) ...[
                  _ReleaseScopeNote(message: l.releaseSectionPlatformWideNote),
                  const SizedBox(height: AppSpacing.sm),
                ],
                _ReleaseRecordList(releases: releases.take(12).toList()),
              ],
            ),
    );
  }

  Future<void> _createReleaseRecordFromPolicy(BuildContext context) async {
    final l = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l.createReleaseRecordFromAndroidPolicy),
        content: Text(l.createReleaseRecordFromAndroidPolicyConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l.createAction),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) {
      return;
    }
    final success =
        await context.read<PlatformCubit>().createReleaseRecordFromAndroidPolicy();
    if (!context.mounted) {
      return;
    }
    if (success) {
      AppFeedback.success(context, l.releaseRecordCreated);
    }
  }
}

CompanyMetadata? _companyById(List<CompanyMetadata> companies, String id) {
  for (final company in companies) {
    if (company.id == id) {
      return company;
    }
  }
  return null;
}

class _ReleaseAdoptionDevicesTab extends StatelessWidget {
  const _ReleaseAdoptionDevicesTab({
    required this.adoptionRows,
    required this.deviceRows,
  });

  final List<VersionAdoptionRow> adoptionRows;
  final List<PlatformDeviceInstallRow> deviceRows;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ReleaseGuidancePanel(
          message: l.releaseAdoptionDevicesGuidance,
          notes: [
            l.currentAdoptionHistoryHint,
            l.notificationAdoptionSeparateNote,
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        _ReleaseSectionBlock(
          title: l.versionAdoption,
          icon: Icons.analytics_outlined,
          child: _ReleaseAdoptionTab(rows: adoptionRows),
        ),
        const SizedBox(height: AppSpacing.md),
        _ReleaseSectionBlock(
          title: l.devices,
          icon: Icons.devices_other_outlined,
          child: _ReleaseDevicesTab(rows: deviceRows),
        ),
      ],
    );
  }
}

class _ReleaseAdoptionTab extends StatelessWidget {
  const _ReleaseAdoptionTab({required this.rows});

  final List<VersionAdoptionRow> rows;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    if (rows.isEmpty) {
      return AppEmptyState(
        icon: Icons.analytics_outlined,
        title: l.versionAdoption,
        message: l.noAdoptionDataYet,
      );
    }
    return _ReleaseStructuredList(
      rows: rows.map((row) {
        return _ReleaseStructuredRow(
          title: _versionLabel(row.appVersion, row.buildNumber, l),
          status: _releaseStatusLabel(l, row.status),
          tone: _releaseStatusTone(row.status),
          fields: [
            _ReleaseField(l.platform, _platformLabel(l, row.platform)),
            _ReleaseField(l.version, _notReported(row.appVersion, l)),
            _ReleaseField(l.latestBuild, row.buildNumber.toString()),
            _ReleaseField(l.activeUsers, row.activeUsers.toString()),
            _ReleaseField(l.activeDevices, row.activeDevices.toString()),
            _ReleaseField(l.activeCompanies, row.activeCompanies.toString()),
            _ReleaseField(
              l.latestSeen,
              row.latestSeenAt == null
                  ? l.notReported
                  : _formatDate(context, row.latestSeenAt!),
            ),
          ],
        );
      }).toList(),
    );
  }
}

class _ReleaseDevicesTab extends StatelessWidget {
  const _ReleaseDevicesTab({required this.rows});

  final List<PlatformDeviceInstallRow> rows;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    if (rows.isEmpty) {
      return AppEmptyState(
        icon: Icons.devices_other_outlined,
        title: l.devices,
        message: l.noDeviceDataYet,
      );
    }
    return _ReleaseStructuredList(
      rows: rows.take(80).map((row) {
        final device = [row.browser, row.os, row.deviceModel]
            .map((value) => value.trim())
            .where((value) => value.isNotEmpty && value.toLowerCase() != 'unknown')
            .take(2)
            .join(' / ');
        return _ReleaseStructuredRow(
          title: _notReported(
            row.fullName.isEmpty ? row.email : row.fullName,
            l,
          ),
          status: _notificationStatusLabel(l, row.notificationTokenStatus),
          tone: _notificationStatusTone(row.notificationTokenStatus),
          fields: [
            _ReleaseField(l.company, _notReported(row.companyName.isEmpty ? row.companyId : row.companyName, l)),
            _ReleaseField(l.role, _notReported(row.role, l)),
            _ReleaseField(l.platform, _platformLabel(l, row.platform)),
            _ReleaseField(l.version, _versionLabel(row.appVersion, row.buildNumber, l)),
            _ReleaseField(
              l.latestSeen,
              row.lastSeenAt == null
                  ? l.notReported
                  : _formatDate(context, row.lastSeenAt!),
            ),
            _ReleaseField(l.notifications, _notificationStatusLabel(l, row.notificationTokenStatus)),
            _ReleaseField(l.deviceBrowser, _notReported(device, l)),
          ],
        );
      }).toList(),
    );
  }
}

class _ReleasePolicyTab extends StatelessWidget {
  const _ReleasePolicyTab({required this.state});

  final PlatformState state;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final policy = state.androidReleasePolicy;
    return _ReleaseSectionBlock(
      title: l.androidReleaseManagement,
      icon: Icons.admin_panel_settings_outlined,
      child: policy == null
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ReleaseGuidancePanel(
                  message: l.releaseAndroidPolicyGuidance,
                  notes: [
                    l.releaseSectionPlatformWideNote,
                    l.androidPolicyBuildComparisonNote,
                    l.suggestedApkUrlNotProof,
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                if (state.releaseCompanyId != null) ...[
                  _ReleaseScopeNote(message: l.releaseSectionPlatformWideNote),
                  const SizedBox(height: AppSpacing.sm),
                ],
                AppEmptyState(
                  icon: Icons.system_update_alt_rounded,
                  title: l.androidReleaseManagement,
                  message: l.androidReleasePolicyHint,
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ReleaseGuidancePanel(
                  message: l.releaseAndroidPolicyGuidance,
                  notes: [
                    l.releaseSectionPlatformWideNote,
                    l.androidPolicyBuildComparisonNote,
                    l.suggestedApkUrlNotProof,
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                if (state.releaseCompanyId != null) ...[
                  _ReleaseScopeNote(message: l.releaseSectionPlatformWideNote),
                  const SizedBox(height: AppSpacing.sm),
                ],
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    _ReleaseFieldView(
                      field: _ReleaseField(
                        l.enabled,
                        policy.enabled ? l.yes : l.no,
                      ),
                    ),
                    _ReleaseFieldView(
                      field: _ReleaseField(
                        l.releaseReady,
                        policy.releaseReady ? l.yes : l.no,
                      ),
                    ),
                    _ReleaseFieldView(
                      field: _ReleaseField(
                        l.latestBuild,
                        _policyVersionLabel(policy, l),
                      ),
                    ),
                    _ReleaseFieldView(
                      field: _ReleaseField(
                        l.minimumSupportedBuild,
                        policy.minimumSupportedBuildNumber.toString(),
                      ),
                    ),
                    _ReleaseFieldView(
                      field: _ReleaseField(
                        l.updateUrl,
                        policy.updateUrl.trim().isEmpty
                            ? l.notAvailable
                            : policy.updateUrl.trim(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                _ReleaseSignalPanel(
                  message: policy.releaseReady
                      ? l.androidPolicyReadyAction
                      : l.androidPolicyNotReadyAction,
                  fields: [
                    _ReleaseField(l.releaseReady, policy.releaseReady ? l.yes : l.no),
                    _ReleaseField(l.latestBuild, policy.latestBuildNumber.toString()),
                    _ReleaseField(
                      l.minimumSupportedBuild,
                      policy.minimumSupportedBuildNumber.toString(),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}

class _ReleaseHistoryTab extends StatelessWidget {
  const _ReleaseHistoryTab({required this.rows, this.compact = false});

  final List<DeviceVersionEventRow> rows;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    if (rows.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ReleaseGuidancePanel(
            message: l.releaseHistoryGuidance,
            notes: [l.releaseHistoryProfileLimitNote],
          ),
          const SizedBox(height: AppSpacing.md),
          AppEmptyState(
            icon: Icons.history_rounded,
            title: l.versionHistory,
            message: l.versionHistoryStartsAfterBuildChange,
          ),
        ],
      );
    }
    final visibleRows = compact ? rows.take(5) : rows.take(80);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ReleaseGuidancePanel(
          message: l.releaseHistoryGuidance,
          notes: [l.releaseHistoryProfileLimitNote],
        ),
        const SizedBox(height: AppSpacing.md),
        _ReleaseStructuredList(
          rows: visibleRows.map((row) {
            final shortUid = _shortTechnicalId(row.uid);
            final hasProfileLabel = _releaseHistoryHasUserProfileLabel(row);
            return _ReleaseStructuredRow(
              title: _releaseHistoryTitle(row, l),
              status: _platformLabel(l, row.platform),
              tone: AppStatusTone.info,
              fields: [
                _ReleaseField(
                  l.company,
                  _notReported(
                    row.companyName.isEmpty ? row.companyId : row.companyName,
                    l,
                  ),
                ),
                _ReleaseField(l.role, _notReported(row.role, l)),
                if (!hasProfileLabel)
                  _ReleaseField(
                    l.userProfileUnavailable,
                    l.releaseEventTechnicalReferenceOnly,
                  ),
                if (shortUid.isNotEmpty)
                  _ReleaseField(l.technicalReference, shortUid),
                _ReleaseField(
                  l.oldBuild,
                  _versionLabel(row.oldVersion, row.oldBuildNumber, l),
                ),
                _ReleaseField(
                  l.latestBuild,
                  _versionLabel(row.newVersion, row.newBuildNumber, l),
                ),
                _ReleaseField(l.source, _notReported(row.source, l)),
                _ReleaseField(
                  l.createdAt,
                  row.createdAt == null
                      ? l.notReported
                      : _formatDate(context, row.createdAt!),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _ReleaseKpiGrid extends StatelessWidget {
  const _ReleaseKpiGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) {
      return const SizedBox.shrink();
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        var columns = width >= 1180
            ? 5
            : width >= 900
                ? 3
                : width >= 560
                    ? 2
                    : 1;
        if (columns > children.length) {
          columns = children.length;
        }
        const spacing = AppSpacing.sm;
        final itemWidth =
            columns == 1 ? width : (width - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final child in children)
              SizedBox(
                width: itemWidth,
                child: child,
              ),
          ],
        );
      },
    );
  }
}

class _ReleaseKpiCard extends StatelessWidget {
  const _ReleaseKpiCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.detail,
    this.status,
    this.tone = AppStatusTone.neutral,
  });

  final IconData icon;
  final String title;
  final String value;
  final String detail;
  final String? status;
  final AppStatusTone tone;

  @override
  Widget build(BuildContext context) {
    final color = _toneColor(context, tone);
    return Container(
      constraints: const BoxConstraints(minHeight: 150),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.inputSurface(context),
        borderRadius: AppRadius.large,
        border: Border.all(color: AppColors.borderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: AppRadius.medium,
                  border: Border.all(color: color.withValues(alpha: 0.24)),
                ),
                child: Icon(icon, color: color, size: 21),
              ),
              if (status != null) ...[
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Align(
                    alignment: AlignmentDirectional.topEnd,
                    child: AppStatusBadge(label: status!, tone: tone),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            title,
            softWrap: true,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppColors.textSecondaryColor(context),
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            softWrap: true,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textPrimaryColor(context),
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            detail,
            softWrap: true,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondaryColor(context),
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _ReleaseSectionBlock extends StatelessWidget {
  const _ReleaseSectionBlock({
    required this.title,
    required this.icon,
    required this.child,
    this.action,
  });

  final String title;
  final IconData icon;
  final Widget child;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.inputSurface(context),
        borderRadius: AppRadius.large,
        border: Border.all(color: AppColors.borderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final heading = Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color:
                          AppColors.primaryColor(context).withValues(alpha: 0.12),
                      borderRadius: AppRadius.medium,
                    ),
                    child: Icon(
                      icon,
                      size: 20,
                      color: AppColors.primaryColor(context),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      title,
                      softWrap: true,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: AppColors.textPrimaryColor(context),
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                  ),
                ],
              );
              if (action == null) {
                return heading;
              }
              if (constraints.maxWidth < 680) {
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
                crossAxisAlignment: CrossAxisAlignment.start,
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

class _ReleaseSignalPanel extends StatelessWidget {
  const _ReleaseSignalPanel({
    required this.message,
    required this.fields,
  });

  final String message;
  final List<_ReleaseField> fields;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.warningColor(context).withValues(alpha: .10),
        borderRadius: AppRadius.large,
        border: Border.all(
          color: AppColors.warningColor(context).withValues(alpha: .28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            message,
            softWrap: true,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.warningColor(context),
                  fontWeight: FontWeight.w800,
                ),
          ),
          if (fields.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final field in fields) _ReleaseFieldView(field: field),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ReleaseGuidancePanel extends StatelessWidget {
  const _ReleaseGuidancePanel({
    required this.message,
    this.notes = const [],
  });

  final String message;
  final List<String> notes;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.infoColor(context).withValues(alpha: 0.08),
        borderRadius: AppRadius.large,
        border: Border.all(
          color: AppColors.infoColor(context).withValues(alpha: 0.22),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: AppColors.infoColor(context),
                size: 18,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  message,
                  softWrap: true,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textPrimaryColor(context),
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
            ],
          ),
          if (notes.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                for (final note in notes)
                  _ReleaseScopeNote(message: note),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ReleaseScopeNote extends StatelessWidget {
  const _ReleaseScopeNote({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.infoColor(context).withValues(alpha: 0.08),
        borderRadius: AppRadius.medium,
        border: Border.all(
          color: AppColors.infoColor(context).withValues(alpha: 0.22),
        ),
      ),
      child: Text(
        message,
        softWrap: true,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.infoColor(context),
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}

class _ReleaseDialogSection extends StatelessWidget {
  const _ReleaseDialogSection({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.inputSurface(context),
        borderRadius: AppRadius.large,
        border: Border.all(color: AppColors.borderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primaryColor(context)),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  title,
                  softWrap: true,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.textPrimaryColor(context),
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ...children,
        ],
      ),
    );
  }
}

class _ReleaseRiskStats {
  const _ReleaseRiskStats({
    required this.usersBelowLatest,
    required this.devicesBelowLatest,
    required this.usersBelowMinimum,
    required this.devicesBelowMinimum,
  });

  final int usersBelowLatest;
  final int devicesBelowLatest;
  final int usersBelowMinimum;
  final int devicesBelowMinimum;
}

class _ReleaseDeviceStats {
  const _ReleaseDeviceStats({
    required this.activeUsers,
    required this.activeDevices,
    required this.activeWebUsers,
    required this.activeWebDevices,
    required this.activeAndroidUsers,
    required this.activeAndroidDevices,
    required this.pushConnected,
    required this.pushBlocked,
    required this.pushMissing,
    required this.pushInvalidFailed,
    required this.pushUnknown,
  });

  final int activeUsers;
  final int activeDevices;
  final int activeWebUsers;
  final int activeWebDevices;
  final int activeAndroidUsers;
  final int activeAndroidDevices;
  final int pushConnected;
  final int pushBlocked;
  final int pushMissing;
  final int pushInvalidFailed;
  final int pushUnknown;
}

_ReleaseDeviceStats _releaseDeviceStats(List<PlatformDeviceInstallRow> rows) {
  final users = <String>{};
  final webUsers = <String>{};
  final androidUsers = <String>{};
  var webDevices = 0;
  var androidDevices = 0;
  var connected = 0;
  var blocked = 0;
  var missing = 0;
  var invalidFailed = 0;
  var unknown = 0;
  for (final row in rows) {
    final userKey = '${row.companyId}:${row.uid}';
    if (row.uid.trim().isNotEmpty) {
      users.add(userKey);
    }
    if (row.platform == 'web') {
      webDevices += 1;
      if (row.uid.trim().isNotEmpty) webUsers.add(userKey);
    }
    if (row.platform == 'android') {
      androidDevices += 1;
      if (row.uid.trim().isNotEmpty) androidUsers.add(userKey);
    }
    final tokenStatus = row.notificationTokenStatus.trim().toLowerCase();
    if (tokenStatus == 'active' || tokenStatus == 'connected') {
      connected += 1;
    } else if (tokenStatus == 'blocked') {
      blocked += 1;
    } else if (tokenStatus == 'missing') {
      missing += 1;
    } else if (tokenStatus == 'invalid' || tokenStatus == 'failed') {
      invalidFailed += 1;
    } else {
      unknown += 1;
    }
  }
  return _ReleaseDeviceStats(
    activeUsers: users.length,
    activeDevices: rows.length,
    activeWebUsers: webUsers.length,
    activeWebDevices: webDevices,
    activeAndroidUsers: androidUsers.length,
    activeAndroidDevices: androidDevices,
    pushConnected: connected,
    pushBlocked: blocked,
    pushMissing: missing,
    pushInvalidFailed: invalidFailed,
    pushUnknown: unknown,
  );
}

_ReleaseRiskStats _releaseRiskStats({
  required List<PlatformDeviceInstallRow> rows,
  required int latestWebBuild,
  required int latestAndroidBuild,
  required int minimumAndroidBuild,
}) {
  final usersBelowLatest = <String>{};
  final usersBelowMinimum = <String>{};
  var devicesBelowLatest = 0;
  var devicesBelowMinimum = 0;
  for (final row in rows) {
    final platform = row.platform.trim().toLowerCase();
    final latestBuild = switch (platform) {
      'web' => latestWebBuild,
      'android' => latestAndroidBuild,
      _ => 0,
    };
    final build = row.buildNumber;
    final userKey = '${row.companyId}:${row.uid}';
    final hasUser = row.uid.trim().isNotEmpty;
    if (latestBuild > 0 && build > 0 && build < latestBuild) {
      devicesBelowLatest += 1;
      if (hasUser) {
        usersBelowLatest.add(userKey);
      }
    }
    if (platform == 'android' &&
        minimumAndroidBuild > 0 &&
        build > 0 &&
        build < minimumAndroidBuild) {
      devicesBelowMinimum += 1;
      if (hasUser) {
        usersBelowMinimum.add(userKey);
      }
    }
  }
  return _ReleaseRiskStats(
    usersBelowLatest: usersBelowLatest.length,
    devicesBelowLatest: devicesBelowLatest,
    usersBelowMinimum: usersBelowMinimum.length,
    devicesBelowMinimum: devicesBelowMinimum,
  );
}

class _ReleaseRecordList extends StatelessWidget {
  const _ReleaseRecordList({required this.releases});

  final List<PlatformReleaseRecord> releases;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return _ReleaseStructuredList(
      rows: releases.map((release) {
        return _ReleaseStructuredRow(
          title: _versionLabel(release.appVersion, release.buildNumber, l),
          status: _releaseStatusLabel(l, release.status),
          tone: _releaseStatusTone(release.status),
          fields: [
            _ReleaseField(l.platform, _platformLabel(l, release.platform)),
            _ReleaseField(l.releaseReady, release.releaseReady ? l.yes : l.no),
            _ReleaseField(l.enabled, release.enabled ? l.yes : l.no),
            _ReleaseField(l.minimumSupportedBuild, release.minimumSupportedBuildNumber.toString()),
            _ReleaseField(l.latestBuild, release.latestBuildNumber.toString()),
            _ReleaseField(
              l.updateUrl,
              release.updateUrl.trim().isEmpty ? l.notReported : release.updateUrl,
            ),
            _ReleaseField(
              l.released,
              release.releasedAt == null
                  ? l.notReported
                  : _formatDate(context, release.releasedAt!),
            ),
            _ReleaseField(l.createdBy, _notReported(release.createdByName, l)),
          ],
        );
      }).toList(),
    );
  }
}

class _ReleaseStructuredList extends StatelessWidget {
  const _ReleaseStructuredList({required this.rows});

  final List<_ReleaseStructuredRow> rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: rows
          .map(
            (row) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: row,
            ),
          )
          .toList(),
    );
  }
}

class _ReleaseStructuredRow extends StatelessWidget {
  const _ReleaseStructuredRow({
    required this.title,
    required this.status,
    required this.fields,
    this.tone = AppStatusTone.neutral,
  });

  final String title;
  final String status;
  final List<_ReleaseField> fields;
  final AppStatusTone tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.inputSurface(context),
        borderRadius: AppRadius.large,
        border: Border.all(color: AppColors.borderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final titleText = Text(
                title,
                softWrap: true,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.textPrimaryColor(context),
                      fontWeight: FontWeight.w900,
                    ),
              );
              final badge = AppStatusBadge(label: status, tone: tone);
              if (constraints.maxWidth < 520) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    titleText,
                    const SizedBox(height: AppSpacing.xs),
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: badge,
                    ),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: titleText),
                  const SizedBox(width: AppSpacing.sm),
                  badge,
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: fields
                .map(
                  (field) => _ReleaseFieldView(field: field),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _ReleaseField {
  const _ReleaseField(this.label, this.value);

  final String label;
  final String value;
}

class _ReleaseFieldView extends StatelessWidget {
  const _ReleaseFieldView({required this.field});

  final _ReleaseField field;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 150, maxWidth: 340),
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.appBackground(context),
        borderRadius: AppRadius.medium,
        border: Border.all(color: AppColors.borderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            field.label,
            softWrap: true,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textSecondaryColor(context),
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            field.value,
            softWrap: true,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textPrimaryColor(context),
                  fontWeight: FontWeight.w900,
                ),
          ),
        ],
      ),
    );
  }
}

int _releaseBuild(PlatformReleaseRecord? release) {
  if (release == null) {
    return 0;
  }
  return release.latestBuildNumber > 0
      ? release.latestBuildNumber
      : release.buildNumber;
}

int _maxBuild(Iterable<int> builds) {
  var max = 0;
  for (final build in builds) {
    if (build > max) {
      max = build;
    }
  }
  return max;
}

int _nonNegative(int value) => value < 0 ? 0 : value;

String _latestPlatformVersionLabel(
  AppLocalizations l, {
  VersionAdoptionRow? active,
  PlatformReleaseRecord? release,
  AndroidReleasePolicy? policy,
}) {
  final activeBuild = active?.buildNumber ?? 0;
  final releaseBuild = _releaseBuild(release);
  final policyBuild = policy?.latestBuildNumber ?? 0;
  final externalBuild = _maxBuild([releaseBuild, policyBuild]);
  if (active != null && activeBuild >= externalBuild) {
    return _versionLabel(active.appVersion, active.buildNumber, l);
  }
  if (policy != null && policyBuild >= releaseBuild && policyBuild > 0) {
    return _policyVersionLabel(policy, l);
  }
  return _releaseVersionLabel(release, l);
}

String? _latestPlatformStatusLabel(
  AppLocalizations l, {
  VersionAdoptionRow? active,
  PlatformReleaseRecord? release,
  AndroidReleasePolicy? policy,
}) {
  final activeBuild = active?.buildNumber ?? 0;
  final releaseBuild = _releaseBuild(release);
  final policyBuild = policy?.latestBuildNumber ?? 0;
  final externalBuild = _maxBuild([releaseBuild, policyBuild]);
  if (active != null && activeBuild >= externalBuild) {
    return _releaseStatusLabel(l, active.status);
  }
  if (policy != null && policyBuild >= releaseBuild && policyBuild > 0) {
    return policy.releaseReady ? l.releaseReady : l.draft;
  }
  if (release != null) {
    return _releaseStatusLabel(l, release.status);
  }
  return null;
}

AppStatusTone _latestPlatformTone({
  VersionAdoptionRow? active,
  PlatformReleaseRecord? release,
  AndroidReleasePolicy? policy,
}) {
  final activeBuild = active?.buildNumber ?? 0;
  final releaseBuild = _releaseBuild(release);
  final policyBuild = policy?.latestBuildNumber ?? 0;
  final externalBuild = _maxBuild([releaseBuild, policyBuild]);
  if (active != null && activeBuild >= externalBuild) {
    return _releaseStatusTone(active.status);
  }
  if (policy != null && policyBuild >= releaseBuild && policyBuild > 0) {
    return policy.releaseReady ? AppStatusTone.success : AppStatusTone.warning;
  }
  if (release != null) {
    return _releaseStatusTone(release.status);
  }
  return AppStatusTone.neutral;
}

String _policyVersionLabel(AndroidReleasePolicy policy, AppLocalizations l) {
  return _versionLabel(
    _versionNameFromUpdateUrl(policy.updateUrl, policy.latestBuildNumber),
    policy.latestBuildNumber,
    l,
  );
}

String _releaseHistoryTitle(
  DeviceVersionEventRow row,
  AppLocalizations l,
) {
  final name = row.userName.trim();
  if (_isUsefulReleaseHistoryLabel(name, row.uid)) {
    return name;
  }
  final company = row.companyName.trim().isNotEmpty
      ? row.companyName.trim()
      : row.companyId.trim();
  final role = row.role.trim();
  if (role.isNotEmpty && company.isNotEmpty) {
    return '${_roleText(l, role)} - $company';
  }
  if (company.isNotEmpty) {
    return company;
  }
  if (role.isNotEmpty) {
    return _roleText(l, role);
  }
  final platform = row.platform.trim();
  if (platform.isNotEmpty) {
    return _platformLabel(l, platform);
  }
  return l.unresolvedUser;
}

bool _releaseHistoryHasUserProfileLabel(DeviceVersionEventRow row) {
  return _isUsefulReleaseHistoryLabel(row.userName.trim(), row.uid);
}

bool _isUsefulReleaseHistoryLabel(String label, String uid) {
  final clean = label.trim();
  if (clean.isEmpty || clean.toLowerCase() == 'unknown') {
    return false;
  }
  return clean != uid.trim();
}

String _shortTechnicalId(String value) {
  final clean = value.trim();
  if (clean.isEmpty || clean.toLowerCase() == 'unknown') {
    return '';
  }
  if (clean.length <= 8) {
    final end = clean.length < 4 ? clean.length : 4;
    return '${clean.substring(0, end)}...';
  }
  return '${clean.substring(0, 4)}...${clean.substring(clean.length - 3)}';
}

String _releaseVersionLabel(PlatformReleaseRecord? release, AppLocalizations l) {
  if (release == null) {
    return l.notAvailable;
  }
  return _versionLabel(
    release.appVersion,
    release.latestBuildNumber > 0 ? release.latestBuildNumber : release.buildNumber,
    l,
  );
}

VersionAdoptionRow? _latestActiveVersion(
  List<VersionAdoptionRow> rows,
  String platform,
) {
  final platformRows = rows
      .where((row) => row.platform == platform && row.activeDevices > 0)
      .toList()
    ..sort((a, b) {
      final buildCompare = b.buildNumber.compareTo(a.buildNumber);
      if (buildCompare != 0) return buildCompare;
      final aSeen = a.latestSeenAt?.millisecondsSinceEpoch ?? 0;
      final bSeen = b.latestSeenAt?.millisecondsSinceEpoch ?? 0;
      return bSeen.compareTo(aSeen);
    });
  return platformRows.isEmpty ? null : platformRows.first;
}

String _versionLabel(String version, int buildNumber, AppLocalizations l) {
  final cleanVersion = version.trim();
  if (cleanVersion.isEmpty && buildNumber <= 0) {
    return l.notAvailable;
  }
  if (cleanVersion.isEmpty) {
    return '${l.buildNumber}: $buildNumber';
  }
  if (buildNumber <= 0) {
    return cleanVersion;
  }
  return '$cleanVersion ($buildNumber)';
}

String _versionNameFromUpdateUrl(String updateUrl, int buildNumber) {
  if (updateUrl.trim().isEmpty || buildNumber <= 0) {
    return '';
  }
  final parsed = Uri.tryParse(updateUrl.trim());
  final path = parsed?.path.trim().isNotEmpty == true
      ? parsed!.path
      : updateUrl.trim();
  final fileName = Uri.decodeFull(path).split('/').last;
  final suffix = '-$buildNumber.apk';
  if (!fileName.toLowerCase().endsWith(suffix)) {
    return '';
  }
  final nameWithoutSuffix =
      fileName.substring(0, fileName.length - suffix.length);
  const prefix = 'masar-crm-';
  if (!nameWithoutSuffix.toLowerCase().startsWith(prefix)) {
    return '';
  }
  return nameWithoutSuffix.substring(prefix.length).trim();
}

String? _androidApkUrlError(
  String updateUrl,
  int latestBuild,
  AppLocalizations l,
) {
  final clean = updateUrl.trim();
  if (clean.isEmpty) {
    return l.requiredField;
  }
  final uri = Uri.tryParse(clean);
  if (uri == null ||
      uri.scheme.toLowerCase() != 'https' ||
      uri.host.trim().isEmpty) {
    return l.invalidUrl;
  }
  final fileName = Uri.decodeFull(uri.path).split('/').last.trim();
  if (!fileName.toLowerCase().endsWith('.apk')) {
    return l.invalidUrl;
  }
  if (latestBuild > 0 && !fileName.endsWith('-$latestBuild.apk')) {
    return l.unableToSave;
  }
  return null;
}

String _platformLabel(AppLocalizations l, String platform) {
  return switch (platform) {
    'web' => l.web,
    'android' => l.androidPlatform,
    _ => platform.trim().isEmpty ? l.notAvailable : platform,
  };
}

String _releaseStatusLabel(AppLocalizations l, String status) {
  return switch (status) {
    'latest' => l.latest,
    'old' => l.oldBuild,
    'belowMinimum' => l.belowMinimumBuild,
    'draft' => l.draft,
    'ready' => l.releaseReady,
    'released' => l.released,
    'disabled' => l.disabled,
    'rolledBack' => l.rolledBack,
    _ => status.trim().isEmpty ? l.notAvailable : status,
  };
}

AppStatusTone _releaseStatusTone(String status) {
  final normalized = status.trim();
  if (normalized == 'latest' ||
      normalized == 'ready' ||
      normalized == 'released') {
    return AppStatusTone.success;
  }
  if (normalized == 'old' || normalized == 'draft') {
    return AppStatusTone.warning;
  }
  if (normalized == 'belowMinimum' ||
      normalized == 'disabled' ||
      normalized == 'rolledBack') {
    return AppStatusTone.error;
  }
  return AppStatusTone.neutral;
}

String _notificationStatusLabel(AppLocalizations l, String status) {
  final normalized = status.trim();
  if (normalized.isEmpty || normalized.toLowerCase() == 'unknown') {
    return l.notReported;
  }
  return switch (normalized) {
    'active' => l.connected,
    'connected' => l.connected,
    'blocked' => l.blocked,
    'missing' => l.missing,
    'failed' => l.failed,
    'invalid' => l.invalid,
    _ => normalized,
  };
}

AppStatusTone _notificationStatusTone(String status) {
  final normalized = status.trim().toLowerCase();
  if (normalized == 'active' || normalized == 'connected') {
    return AppStatusTone.success;
  }
  if (normalized == 'blocked' || normalized == 'missing') {
    return AppStatusTone.warning;
  }
  if (normalized == 'failed' || normalized == 'invalid') {
    return AppStatusTone.error;
  }
  return AppStatusTone.neutral;
}

String _notReported(String value, AppLocalizations l) {
  final clean = value.trim();
  if (clean.isEmpty || clean.toLowerCase() == 'unknown') {
    return l.notReported;
  }
  return clean;
}


class _AndroidVersionAdoptionCard extends StatelessWidget {
  const _AndroidVersionAdoptionCard({required this.summary});

  final AndroidVersionAdoptionSummary? summary;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final data = summary;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.inputSurface(context),
        borderRadius: AppRadius.large,
        border: Border.all(color: AppColors.borderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.analytics_outlined, color: AppColors.primaryColor(context)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.androidVersionAdoption,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l.androidVersionAdoptionSubtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondaryColor(context),
                            height: 1.25,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (data == null || data.versions.isEmpty)
            Text(
              l.noAndroidVersionData,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondaryColor(context),
                    fontWeight: FontWeight.w700,
                  ),
            )
          else ...[
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                _InfoChip(
                  label: l.activeUsers,
                  value: data.totalActiveUsers.toString(),
                ),
                _InfoChip(
                  label: l.activeDevices,
                  value: data.totalActiveDevices.toString(),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            ...data.versions.take(6).map((version) {
              final label = _versionLabel(
                version.appVersion,
                version.buildNumber,
                l,
              );
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    _InfoChip(label: l.version, value: label),
                    _InfoChip(
                      label: l.activeUsers,
                      value: version.userCount.toString(),
                    ),
                    _InfoChip(
                      label: l.activeDevices,
                      value: version.deviceCount.toString(),
                    ),
                    _InfoChip(
                      label: l.activeCompanies,
                      value: version.companyCount.toString(),
                    ),
                    if (version.latestSeenAt != null)
                      _InfoChip(
                        label: l.latestSeen,
                        value: _formatDate(context, version.latestSeenAt!),
                      ),
                  ],
                ),
              );
            }),
          ],
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
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

        ],
      ),
    );
  }
}

class _AndroidReleasePolicyCard extends StatelessWidget {
  const _AndroidReleasePolicyCard({required this.state});

  final PlatformState state;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final busy = state.activeSettingsActionId == 'androidRelease';
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.inputSurface(context),
        borderRadius: AppRadius.large,
        border: Border.all(color: AppColors.borderColor(context)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 560;
          final info = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.system_update_alt_rounded, color: AppColors.primaryColor(context)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.androidReleaseManagement,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l.androidReleaseManagementSubtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondaryColor(context),
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l.androidReleasePolicyHint,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.warningColor(context),
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          );
          final button = AppButton(
            label: l.androidReleaseManagement,
            icon: Icons.tune_outlined,
            variant: AppButtonVariant.secondary,
            isLoading: busy,
            onPressed: state.status == PlatformStatus.saving
                ? null
                : () => _showAndroidReleasePolicyDialog(context),
          );
          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                info,
                const SizedBox(height: AppSpacing.sm),
                button,
              ],
            );
          }
          return Row(
            children: [
              Expanded(child: info),
              const SizedBox(width: AppSpacing.md),
              button,
            ],
          );
        },
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
                    AppStatusBadge(
                      label: _paymentStatusLabel(l, _paymentStatus(company)),
                      tone: _paymentStatusTone(_paymentStatus(company)),
                    ),
                    if (company.nextPaymentDueAt != null)
                      _InfoChip(
                        label: l.nextPaymentDue,
                        value: _shortDate(context, company.nextPaymentDueAt!),
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

enum _CompanyAction { workspace, preview, export }

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
          case _CompanyAction.export:
            _exportCompanyData(context, company);
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
        PopupMenuItem<_CompanyAction>(
          value: _CompanyAction.export,
          child: _MenuItem(
            icon: Icons.file_download_outlined,
            label: l.exportCompanyData,
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



DateTime _latestLoginAt(PlatformState state, PlatformCompanyUser user) {
  final activities = _activitiesForUser(state.loginActivities, user.uid);
  final activityAt = activities.isNotEmpty ? activities.first.createdAt : null;
  return activityAt ?? user.lastLoginAt ?? DateTime.fromMillisecondsSinceEpoch(0);
}

List<PlatformLoginActivity> _activitiesForUser(
  List<PlatformLoginActivity> activities,
  String uid,
) {
  final filtered = activities
      .where((activity) => activity.uid == uid)
      .toList(growable: false);
  return filtered;
}

Future<void> _showLoginActivitySheet(
  BuildContext context, {
  required PlatformCompanyUser user,
  required List<PlatformLoginActivity> activities,
}) async {
  final l = AppLocalizations.of(context)!;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    isDismissible: true,
    enableDrag: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.20),
    builder: (sheetContext) {
      final media = MediaQuery.of(sheetContext);
      final items = activities.toList(growable: false);
      return Align(
        alignment: AlignmentDirectional.bottomCenter,
        child: SizedBox(
          width: media.size.width < 760 ? media.size.width : 760,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: media.size.height * 0.88),
            child: Material(
              color: AppColors.cardSurface(sheetContext),
              borderRadius: const BorderRadiusDirectional.vertical(
                top: Radius.circular(28),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.sm,
                      AppSpacing.sm,
                      AppSpacing.xs,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Container(
                            width: 44,
                            height: 4,
                            margin: const EdgeInsets.only(bottom: AppSpacing.md),
                            decoration: BoxDecoration(
                              color: AppColors.textSecondaryColor(sheetContext)
                                  .withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            _PlatformUserAvatar(
                              name: user.fullName,
                              photoUrl: user.photoUrl,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l.loginActivity,
                                    style: Theme.of(sheetContext)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w900),
                                  ),
                                  Text(
                                    user.fullName.trim().isEmpty
                                        ? user.email
                                        : user.fullName,
                                    style: Theme.of(sheetContext)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: AppColors.textSecondaryColor(sheetContext),
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: MaterialLocalizations.of(sheetContext)
                                  .closeButtonTooltip,
                              onPressed: () => Navigator.of(sheetContext).pop(),
                              icon: const Icon(Icons.close_rounded),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Flexible(
                    child: items.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: AppEmptyState(
                              icon: Icons.manage_history_outlined,
                              title: l.noLoginActivityYet,
                              message: l.noLoginActivityYet,
                            ),
                          )
                        : ListView.separated(
                            padding: EdgeInsets.fromLTRB(
                              AppSpacing.md,
                              AppSpacing.md,
                              AppSpacing.md,
                              AppSpacing.md + media.padding.bottom,
                            ),
                            itemCount: items.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: AppSpacing.xs),
                            itemBuilder: (context, index) {
                              return _LoginActivityEventCard(activity: items[index]);
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _LoginActivityEventCard extends StatelessWidget {
  const _LoginActivityEventCard({required this.activity});

  final PlatformLoginActivity activity;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final at = activity.createdAt;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.inputSurface(context),
        borderRadius: AppRadius.large,
        border: Border.all(color: AppColors.borderColor(context)),
      ),
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.xs,
        children: [
          _LoginInfoLine(
            label: l.lastLogin,
            value: at == null ? l.notAvailable : _formatDate(context, at),
          ),
          _LoginInfoLine(label: l.ipAddress, value: _loginValue(l, activity.ipAddress)),
          _LoginInfoLine(
            label: l.device,
            value: _loginValue(l, _loginActivityDeviceLabel(activity)),
          ),
          if (activity.appVersion.trim().isNotEmpty)
            _LoginInfoLine(label: l.version, value: activity.appVersion),
        ],
      ),
    );
  }
}

String _loginActivityDeviceLabel(PlatformLoginActivity activity) {
  final values = [
    activity.deviceType,
    activity.browser,
    activity.platform,
  ].where((value) => value.trim().isNotEmpty).toSet().join(' / ');
  return values;
}

class _LoginActivityRow extends StatelessWidget {
  const _LoginActivityRow({
    required this.user,
    this.activities = const <PlatformLoginActivity>[],
    this.onTap,
  });

  final PlatformCompanyUser user;
  final List<PlatformLoginActivity> activities;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final latestActivity = activities.isNotEmpty ? activities.first : null;
    return Material(
      color: AppColors.inputSurface(context),
      borderRadius: AppRadius.large,
      child: InkWell(
        borderRadius: AppRadius.large,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
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
              if (activities.length > 1) ...[
                const SizedBox(width: AppSpacing.xs),
                AppStatusBadge(
                  label: activities.length.toString(),
                  tone: AppStatusTone.neutral,
                ),
              ],
            ],
          );
          if (constraints.maxWidth < 640) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                identity,
                const SizedBox(height: AppSpacing.xs),
                _LoginDetails(user: user, latestActivity: latestActivity),
              ],
            );
          }
          return Row(
            children: [
              Expanded(flex: 3, child: identity),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                flex: 2,
                child: _LoginDetails(user: user, latestActivity: latestActivity),
              ),
            ],
          );
        },
          ),
        ),
      ),
    );
  }
}

class _LoginDetails extends StatelessWidget {
  const _LoginDetails({
    required this.user,
    this.latestActivity,
    this.compact = false,
  });

  final PlatformCompanyUser user;
  final PlatformLoginActivity? latestActivity;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final at = latestActivity?.createdAt ?? user.lastLoginAt;
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
      _LoginInfoLine(
        label: l.ipAddress,
        value: _loginValue(l, latestActivity?.ipAddress ?? user.lastLoginIp),
      ),
      _LoginInfoLine(
        label: l.device,
        value: _loginValue(
          l,
          latestActivity == null
              ? _loginDeviceLabel(l, user)
              : _loginActivityDeviceLabel(latestActivity!),
        ),
      ),
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

class _PlatformInvitationsPanel extends StatefulWidget {
  const _PlatformInvitationsPanel();

  @override
  State<_PlatformInvitationsPanel> createState() =>
      _PlatformInvitationsPanelState();
}

class _PlatformInvitationsPanelState extends State<_PlatformInvitationsPanel> {
  @override
  void initState() {
    super.initState();
    context.read<PlatformInvitationsCubit>().loadInvitations();
  }

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
                  _directionalIsolate(invitation.invitationCode),
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
              if (invitation.status == 'used' &&
                  invitation.companyName.isNotEmpty)
                _InfoChip(
                  label: l.companyName,
                  value: _directionalIsolate(invitation.companyName),
                ),
              if (invitation.status == 'used' &&
                  invitation.companyStatus.isNotEmpty)
                _InfoChip(
                  label: l.status,
                  value: _directionalIsolate(invitation.companyStatus),
                ),
              if (invitation.status == 'used' &&
                  invitation.acceptedAdminEmail.isNotEmpty)
                _InfoChip(
                  label: l.adminEmail,
                  value: _directionalIsolate(invitation.acceptedAdminEmail),
                ),
              if (invitation.status == 'used' &&
                  invitation.companyCreatedAt != null)
                _InfoChip(
                  label: l.createdAt,
                  value: _formatDate(context, invitation.companyCreatedAt!),
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


Future<void> _showAndroidReleasePolicyDialog(BuildContext context) async {
  final cubit = context.read<PlatformCubit>();
  final l = AppLocalizations.of(context)!;
  AndroidReleasePolicy? policy = cubit.state.androidReleasePolicy;
  final currentBuild = int.tryParse(AppConstants.appBuildNumber) ?? 1;
  final suggestedUpdateUrl =
      '${AppConstants.publicWebBaseUrl}/downloads/masar-crm-${AppConstants.appVersion}-${AppConstants.appBuildNumber}.apk';
  final minController = TextEditingController(
    text: (policy?.minimumSupportedBuildNumber ?? currentBuild).toString(),
  );
  final latestController = TextEditingController(
    text: (policy?.latestBuildNumber ?? currentBuild).toString(),
  );
  final urlController = TextEditingController(
    text: (policy?.updateUrl.trim().isNotEmpty ?? false)
        ? policy!.updateUrl
        : '',
  );
  final titleEnController = TextEditingController(
    text: (policy?.titleEn.trim().isNotEmpty ?? false)
        ? policy!.titleEn
        : 'Update required',
  );
  final titleArController = TextEditingController(
    text: (policy?.titleAr.trim().isNotEmpty ?? false)
        ? policy!.titleAr
        : 'تحديث مطلوب',
  );
  final bodyEnController = TextEditingController(
    text: (policy?.bodyEn.trim().isNotEmpty ?? false)
        ? policy!.bodyEn
        : 'This Android version is no longer supported. Update Masar CRM to continue safely.',
  );
  final bodyArController = TextEditingController(
    text: (policy?.bodyAr.trim().isNotEmpty ?? false)
        ? policy!.bodyAr
        : 'هذا الإصدار من تطبيق أندرويد لم يعد مدعومًا. حدّث مسار CRM للاستمرار بأمان.',
  );
  var enabled = policy?.enabled ?? true;
  var releaseReady = policy?.releaseReady ?? false;
  var saving = false;

  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          final size = MediaQuery.sizeOf(context);
          final maxDialogWidth = size.width - 32;
          final dialogWidth = maxDialogWidth < 680 ? maxDialogWidth : 680.0;
          final dialogHeight = size.height * 0.88;
          final activeUrl = urlController.text.trim();
          final usingSuggestedUrl = activeUrl == suggestedUpdateUrl;
          final showPolicyWarning = !releaseReady || usingSuggestedUrl;

          return Dialog(
            insetPadding: const EdgeInsets.all(AppSpacing.lg),
            child: SizedBox(
              width: dialogWidth,
              height: dialogHeight,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l.androidReleaseManagement,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _ReleaseDialogSection(
                              title: l.androidReleaseManagement,
                              icon: Icons.admin_panel_settings_outlined,
                              children: [
                                SwitchListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(l.enabled),
                                  value: enabled,
                                  onChanged: saving
                                      ? null
                                      : (value) => setDialogState(
                                            () => enabled = value,
                                          ),
                                ),
                                SwitchListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(l.releaseReady),
                                  subtitle: Text(l.androidReleasePolicyHint),
                                  value: releaseReady,
                                  onChanged: saving
                                      ? null
                                      : (value) => setDialogState(
                                            () => releaseReady = value,
                                          ),
                                ),
                                if (showPolicyWarning) ...[
                                  const SizedBox(height: AppSpacing.xs),
                                  _ReleaseSignalPanel(
                                    message: usingSuggestedUrl
                                        ? l.suggestedApkUrlNotProof
                                        : l.androidPolicyNotReadyAction,
                                    fields: const [],
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            _ReleaseDialogSection(
                              title: l.latestBuild,
                              icon: Icons.tag_outlined,
                              children: [
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    final narrow = constraints.maxWidth < 520;
                                    final minField = AppTextField(
                                      controller: minController,
                                      label: l.minimumSupportedBuild,
                                      keyboardType: TextInputType.number,
                                      enabled: !saving,
                                    );
                                    final latestField = AppTextField(
                                      controller: latestController,
                                      label: l.latestBuild,
                                      keyboardType: TextInputType.number,
                                      enabled: !saving,
                                    );
                                    if (narrow) {
                                      return Column(
                                        children: [
                                          minField,
                                          const SizedBox(height: AppSpacing.sm),
                                          latestField,
                                        ],
                                      );
                                    }
                                    return Row(
                                      children: [
                                        Expanded(child: minField),
                                        const SizedBox(width: AppSpacing.sm),
                                        Expanded(child: latestField),
                                      ],
                                    );
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            _ReleaseDialogSection(
                              title: l.updateUrl,
                              icon: Icons.link_rounded,
                              children: [
                                AppTextField(
                                  controller: urlController,
                                  label: l.updateUrl,
                                  keyboardType: TextInputType.url,
                                  maxLines: 2,
                                  enabled: !saving,
                                  onChanged: (_) => setDialogState(() {}),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Container(
                                  padding: const EdgeInsets.all(AppSpacing.sm),
                                  decoration: BoxDecoration(
                                    color: AppColors.appBackground(context),
                                    borderRadius: AppRadius.large,
                                    border: Border.all(
                                      color: AppColors.borderColor(context),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Text(
                                        l.suggestedUpdateUrl,
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelLarge
                                            ?.copyWith(
                                              fontWeight: FontWeight.w900,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      SelectableText(
                                        suggestedUpdateUrl,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: AppColors.textSecondaryColor(
                                                context,
                                              ),
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                      const SizedBox(height: AppSpacing.xs),
                                      Text(
                                        l.suggestedApkUrlNotProof,
                                        softWrap: true,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: AppColors.warningColor(
                                                context,
                                              ),
                                              fontWeight: FontWeight.w800,
                                            ),
                                      ),
                                      const SizedBox(height: AppSpacing.xs),
                                      Wrap(
                                        spacing: AppSpacing.xs,
                                        runSpacing: AppSpacing.xs,
                                        children: [
                                          AppButton(
                                            label: l.useSuggestedUpdateUrl,
                                            icon: Icons.link_rounded,
                                            variant: AppButtonVariant.secondary,
                                            onPressed: saving
                                                ? null
                                                : () => setDialogState(
                                                      () {
                                                        latestController.text =
                                                            AppConstants.appBuildNumber;
                                                        urlController.text =
                                                            suggestedUpdateUrl;
                                                      },
                                                    ),
                                          ),
                                          AppButton(
                                            label: l.copyLink,
                                            icon: Icons.copy_rounded,
                                            variant: AppButtonVariant.ghost,
                                            onPressed: saving
                                                ? null
                                                : () async {
                                              await Clipboard.setData(
                                                ClipboardData(
                                                  text: suggestedUpdateUrl,
                                                ),
                                              );
                                              if (context.mounted) {
                                                AppFeedback.success(
                                                  context,
                                                  l.linkCopied,
                                                );
                                              }
                                            },
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            _ReleaseDialogSection(
                              title: l.androidUpdateTitle,
                              icon: Icons.message_outlined,
                              children: [
                                AppTextField(
                                  controller: titleEnController,
                                  label: '${l.androidUpdateTitle} EN',
                                  enabled: !saving,
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                AppTextField(
                                  controller: titleArController,
                                  label: '${l.androidUpdateTitle} AR',
                                  enabled: !saving,
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                AppTextField(
                                  controller: bodyEnController,
                                  label: '${l.androidUpdateBody} EN',
                                  maxLines: 3,
                                  enabled: !saving,
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                AppTextField(
                                  controller: bodyArController,
                                  label: '${l.androidUpdateBody} AR',
                                  maxLines: 3,
                                  enabled: !saving,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Wrap(
                      alignment: WrapAlignment.end,
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        TextButton(
                          onPressed: saving
                              ? null
                              : () => Navigator.of(dialogContext).pop(),
                          child: Text(l.cancel),
                        ),
                        AppButton(
                          label: l.saveReleasePolicy,
                          icon: Icons.save_outlined,
                          isLoading: saving,
                          onPressed: saving
                              ? null
                              : () async {
                            final minBuild = int.tryParse(minController.text.trim()) ?? 0;
                            final latestBuild = int.tryParse(latestController.text.trim()) ?? 0;
                            if (minBuild <= 0 || latestBuild <= 0 || latestBuild < minBuild) {
                              AppFeedback.error(context, l.unableToSave);
                              return;
                            }
                            final updateUrl = urlController.text.trim();
                            if (enabled || releaseReady) {
                              final urlError = _androidApkUrlError(
                                updateUrl,
                                latestBuild,
                                l,
                              );
                              if (urlError != null) {
                                AppFeedback.error(context, urlError);
                                return;
                              }
                            } else if (updateUrl.isNotEmpty) {
                              final optionalUrlError = _androidApkUrlError(
                                updateUrl,
                                latestBuild,
                                l,
                              );
                              if (optionalUrlError != null) {
                                AppFeedback.error(context, optionalUrlError);
                                return;
                              }
                            }
                            setDialogState(() => saving = true);
                            final success = await cubit.updateAndroidReleasePolicy(
                              enabled: enabled,
                              releaseReady: releaseReady,
                              minimumSupportedBuildNumber: minBuild,
                              latestBuildNumber: latestBuild,
                              updateUrl: updateUrl,
                              titleEn: titleEnController.text.trim(),
                              titleAr: titleArController.text.trim(),
                              bodyEn: bodyEnController.text.trim(),
                              bodyAr: bodyArController.text.trim(),
                            );
                            if (!context.mounted) {
                              return;
                            }
                            if (success) {
                              Navigator.of(dialogContext).pop();
                              AppFeedback.success(context, l.androidReleasePolicySaved);
                              return;
                            }
                            setDialogState(() => saving = false);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );

  // Do not dispose these controllers immediately after showDialog completes.
  // On Flutter Web the dialog overlay can still finish its route teardown for a
  // frame after pop/hot restart, and disposing here can make TextFormField reuse
  // a disposed controller, crashing /platform with a red screen.
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
  late final TextEditingController _trialDuration;
  var _trialDurationUnit = 'days';
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
    final initialTrial = _trialInputFromCompany(company);
    _trialDuration = TextEditingController(text: initialTrial.value.toString());
    _trialDurationUnit = initialTrial.unit;
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
    _trialDuration.dispose();
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
                  if (_status == 'trial') ...[
                    const SizedBox(height: AppSpacing.md),
                    _TrialOptions(
                      enabled: true,
                      controller: _trialDuration,
                      unit: _trialDurationUnit,
                      saving: _saving,
                      showSwitch: false,
                      onChanged: (_) {},
                      onUnitChanged: (value) => setState(() => _trialDurationUnit = value),
                    ),
                  ],
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
      trialEndsAt: null,
      trialDurationValue: !widget.limitsOnly && _status == 'trial'
          ? int.parse(_trialDuration.text.trim())
          : null,
      trialDurationUnit: !widget.limitsOnly && _status == 'trial'
          ? _trialDurationUnit
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


class _TrialOptions extends StatelessWidget {
  const _TrialOptions({
    required this.enabled,
    required this.controller,
    required this.unit,
    required this.saving,
    required this.onChanged,
    required this.onUnitChanged,
    this.showSwitch = true,
  });

  final bool enabled;
  final TextEditingController controller;
  final String unit;
  final bool saving;
  final ValueChanged<bool> onChanged;
  final ValueChanged<String> onUnitChanged;
  final bool showSwitch;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.appBackground(context),
        border: Border.all(color: AppColors.borderColor(context)),
        borderRadius: AppRadius.large,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showSwitch)
            SwitchListTile.adaptive(
              value: enabled,
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text(
                l.enableTrial,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              subtitle: Text(l.enableTrialSubtitle),
              onChanged: saving ? null : onChanged,
            )
          else
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Text(
                l.enableTrialSubtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondaryColor(context),
                    ),
              ),
            ),
          if (enabled) ...[
            const SizedBox(height: AppSpacing.xs),
            LayoutBuilder(
              builder: (context, constraints) {
                final narrow = constraints.maxWidth < 420;
                final valueField = AppTextField(
                  controller: controller,
                  label: l.trialPeriodDays,
                  keyboardType: TextInputType.number,
                  enabled: !saving,
                  validator: (value) => _positiveInteger(value, l),
                );
                final unitField = AppDropdown<String>(
                  label: l.status,
                  value: unit,
                  items: const ['minutes', 'hours', 'days'],
                  itemLabelBuilder: (value) => _trialUnitLabel(context, value),
                  enabled: !saving,
                  onChanged: onUnitChanged,
                );
                if (narrow) {
                  return Column(
                    children: [
                      valueField,
                      const SizedBox(height: AppSpacing.sm),
                      unitField,
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: valueField),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(child: unitField),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

String _trialUnitLabel(BuildContext context, String unit) {
  final isArabic = Localizations.localeOf(context).languageCode == 'ar';
  return switch (unit) {
    'minutes' => isArabic ? 'دقائق' : 'Minutes',
    'hours' => isArabic ? 'ساعات' : 'Hours',
    _ => isArabic ? 'أيام' : 'Days',
  };
}

_TrialInput _trialInputFromCompany(CompanyMetadata company) {
  final storedValue = company.trialDurationValue;
  final storedUnit = _normalizeTrialDurationUnit(company.trialDurationUnit);
  if (company.status == 'trial' && storedValue != null && storedValue > 0) {
    return _TrialInput(value: storedValue, unit: storedUnit);
  }

  final remaining = company.trialEndsAt?.difference(DateTime.now());
  if (company.status != 'trial' || remaining == null || remaining.inSeconds <= 0) {
    return const _TrialInput(value: 14, unit: 'days');
  }

  if (remaining.inHours < 1) {
    final minutes = (remaining.inSeconds / 60).ceil().clamp(1, 1440).toInt();
    return _TrialInput(value: minutes, unit: 'minutes');
  }
  if (remaining.inDays < 2) {
    final hours = (remaining.inMinutes / 60).ceil().clamp(1, 168).toInt();
    return _TrialInput(value: hours, unit: 'hours');
  }
  final days = (remaining.inHours / 24).ceil().clamp(1, 3650).toInt();
  return _TrialInput(value: days, unit: 'days');
}

String _normalizeTrialDurationUnit(String? unit) {
  return switch (unit) {
    'minutes' || 'hours' || 'days' => unit!,
    _ => 'days',
  };
}

class _TrialInput {
  const _TrialInput({required this.value, required this.unit});

  final int value;
  final String unit;
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
  final _trialDays = TextEditingController(text: '14');
  var _trialDurationUnit = 'days';
  final _timezone = TextEditingController(text: 'Africa/Cairo');
  final _notes = TextEditingController();
  var _locale = 'en';
  var _trialEnabled = false;
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
    _trialDays.dispose();
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
                _TrialOptions(
                  enabled: _trialEnabled,
                  controller: _trialDays,
                  unit: _trialDurationUnit,
                  saving: _saving,
                  onUnitChanged: (value) => setState(() => _trialDurationUnit = value),
                  onChanged: (value) => setState(() => _trialEnabled = value),
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
      trialDays: _trialEnabled ? int.parse(_trialDays.text.trim()) : null,
      trialDurationUnit: _trialDurationUnit,
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
  final _trialDays = TextEditingController(text: '14');
  var _trialDurationUnit = 'days';
  var _locale = 'en';
  var _trialEnabled = false;
  var _saving = false;

  @override
  void dispose() {
    _companyName.dispose();
    _companyId.dispose();
    _adminName.dispose();
    _adminEmail.dispose();
    _adminPhone.dispose();
    _timezone.dispose();
    _trialDays.dispose();
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
                const SizedBox(height: AppSpacing.md),
                _TrialOptions(
                  enabled: _trialEnabled,
                  controller: _trialDays,
                  unit: _trialDurationUnit,
                  saving: _saving,
                  onUnitChanged: (value) => setState(() => _trialDurationUnit = value),
                  onChanged: (value) => setState(() => _trialEnabled = value),
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
      trialDays: _trialEnabled ? int.parse(_trialDays.text.trim()) : null,
      trialDurationUnit: _trialDurationUnit,
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
                validator: (value) => AppValidators.confirmPassword(
                  value,
                  _newPassword.text,
                  l,
                ),
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
              const Center(child: MasarLogoLoader(size: 42))
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

Future<void> _showPaymentDialog(
  BuildContext context,
  CompanyMetadata company,
  _PaymentAction action,
) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return BlocProvider.value(
        value: context.read<PlatformCubit>(),
        child: _PaymentActionDialog(company: company, action: action),
      );
    },
  );
}

class _PaymentActionDialog extends StatefulWidget {
  const _PaymentActionDialog({
    required this.company,
    required this.action,
  });

  final CompanyMetadata company;
  final _PaymentAction action;

  @override
  State<_PaymentActionDialog> createState() => _PaymentActionDialogState();
}

class _PaymentActionDialogState extends State<_PaymentActionDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amount;
  late final TextEditingController _currency;
  late final TextEditingController _paymentDate;
  late final TextEditingController _nextDue;
  late final TextEditingController _graceEnds;
  late final TextEditingController _notes;
  var _cycle = 'monthly';
  var _saving = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _amount = TextEditingController(
      text: widget.company.paymentAmount == null || widget.company.paymentAmount == 0
          ? ''
          : widget.company.paymentAmount!.toStringAsFixed(2),
    );
    _currency = TextEditingController(text: widget.company.paymentCurrency ?? 'EGP');
    _paymentDate = TextEditingController(text: _dateInput(now));
    _nextDue = TextEditingController(
      text: _dateInput(widget.company.nextPaymentDueAt ?? now.add(const Duration(days: 30))),
    );
    _graceEnds = TextEditingController(
      text: _dateInput(widget.company.gracePeriodEndsAt ?? now.add(const Duration(days: 7))),
    );
    _notes = TextEditingController(text: widget.company.paymentNotes ?? '');
    _cycle = widget.company.paymentCycle ?? 'monthly';
  }

  @override
  void dispose() {
    _amount.dispose();
    _currency.dispose();
    _paymentDate.dispose();
    _nextDue.dispose();
    _graceEnds.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(_paymentDialogTitle(l, widget.action)),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.action == _PaymentAction.markPaid) ...[
                  AppTextField(
                    controller: _amount,
                    label: l.amount,
                    keyboardType: TextInputType.number,
                    enabled: !_saving,
                    validator: (value) => _money(value, l),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    controller: _currency,
                    label: l.paymentCurrency,
                    enabled: !_saving,
                    validator: (value) => _currencyValidator(value, l),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    controller: _paymentDate,
                    label: l.lastPayment,
                    hint: 'YYYY-MM-DD',
                    enabled: !_saving,
                    validator: (value) => _dateValidator(value, l, futureOnly: false),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppDropdown<String>(
                    label: l.paymentCycle,
                    value: _cycle,
                    items: const ['monthly', 'quarterly', 'semiAnnual', 'yearly', 'custom'],
                    itemLabelBuilder: (value) => _paymentCycleLabel(l, value),
                    enabled: !_saving,
                    onChanged: (value) => setState(() => _cycle = value),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                if (widget.action == _PaymentAction.markPaid ||
                    widget.action == _PaymentAction.extend ||
                    widget.action == _PaymentAction.reactivate) ...[
                  AppTextField(
                    controller: _nextDue,
                    label: l.nextPaymentDue,
                    hint: 'YYYY-MM-DD',
                    enabled: !_saving,
                    validator: (value) => _dateValidator(value, l),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                if (widget.action == _PaymentAction.grace) ...[
                  AppTextField(
                    controller: _graceEnds,
                    label: l.gracePeriodEndsAt,
                    hint: 'YYYY-MM-DD',
                    enabled: !_saving,
                    validator: (value) => _dateValidator(value, l),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                AppTextField(
                  controller: _notes,
                  label: widget.action == _PaymentAction.suspend
                      ? l.suspendedReason
                      : l.paymentNotes,
                  maxLines: 3,
                  enabled: !_saving,
                  validator: widget.action == _PaymentAction.suspend
                      ? (value) => _required(value, l)
                      : null,
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
    final cubit = context.read<PlatformCubit>();
    final companyId = widget.company.id;
    final notes = _notes.text.trim();
    final success = switch (widget.action) {
      _PaymentAction.markPaid => await cubit.markCompanyPaymentPaid(
          companyId: companyId,
          amount: double.parse(_amount.text.trim()),
          currency: _currency.text.trim(),
          paymentDate: _parseDateInput(_paymentDate.text)!,
          nextPaymentDueAt: _parseDateInput(_nextDue.text)!,
          paymentCycle: _cycle,
          notes: notes,
        ),
      _PaymentAction.extend => await cubit.extendCompanyPaymentDueDate(
          companyId: companyId,
          nextPaymentDueAt: _parseDateInput(_nextDue.text)!,
          notes: notes,
        ),
      _PaymentAction.note => await cubit.updateCompanyPaymentStatus(
          companyId: companyId,
          paymentStatus: _paymentStatus(widget.company),
          notes: notes,
        ),
      _PaymentAction.grace => await cubit.updateCompanyPaymentStatus(
          companyId: companyId,
          paymentStatus: 'gracePeriod',
          gracePeriodEndsAt: _parseDateInput(_graceEnds.text)!,
          notes: notes,
        ),
      _PaymentAction.suspend => await cubit.updateCompanyPaymentStatus(
          companyId: companyId,
          paymentStatus: 'suspended',
          suspendedReason: notes,
          notes: notes,
        ),
      _PaymentAction.reactivate => await cubit.updateCompanyPaymentStatus(
          companyId: companyId,
          paymentStatus: 'paid',
          nextPaymentDueAt: _parseDateInput(_nextDue.text)!,
          notes: notes,
        ),
    };
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

String _statusLabel(AppLocalizations l, CompanyMetadata company) {
  if (company.isTrialExpired || company.status == 'trialExpired') {
    return l.trialEnded;
  }
  if (!company.isActive || company.status == 'inactive') {
    return l.inactive;
  }
  if (company.status == 'trial') {
    return l.trial;
  }
  return l.active;
}

String _paymentStatus(CompanyMetadata company) {
  final status = company.paymentStatus?.trim();
  if (status != null && status.isNotEmpty) {
    return status;
  }
  if (company.status == 'trial') return 'trial';
  if (company.status == 'trialExpired') return 'trialExpired';
  if (!company.isActive || company.status == 'inactive') return 'inactive';
  return 'paid';
}

String _paymentStatusLabel(AppLocalizations l, String status) {
  return switch (status) {
    'paid' => l.paid,
    'dueSoon' => l.dueSoon,
    'overdue' => l.overdue,
    'gracePeriod' => l.gracePeriod,
    'suspended' => l.suspended,
    'trial' => l.trial,
    'trialExpired' => l.trialEnded,
    'inactive' => l.inactive,
    _ => status,
  };
}

AppStatusTone _paymentStatusTone(String status) {
  return switch (status) {
    'paid' => AppStatusTone.success,
    'dueSoon' => AppStatusTone.warning,
    'overdue' => AppStatusTone.error,
    'gracePeriod' => AppStatusTone.warning,
    'suspended' => AppStatusTone.error,
    'trial' => AppStatusTone.info,
    'trialExpired' => AppStatusTone.error,
    'inactive' => AppStatusTone.neutral,
    _ => AppStatusTone.neutral,
  };
}

String _paymentCycleLabel(AppLocalizations l, String? cycle) {
  return switch ((cycle ?? '').trim()) {
    'monthly' => l.monthly,
    'quarterly' => l.quarterly,
    'semiAnnual' => l.semiAnnual,
    'yearly' => l.yearly,
    'custom' => l.custom,
    _ => l.notAvailable,
  };
}

String _paymentActionLabel(AppLocalizations l, String action) {
  return switch (action) {
    'markedPaid' => l.markedPaid,
    'extended' => l.extended,
    'statusChanged' => l.statusChangedEvent,
    'suspended' => l.suspended,
    'reactivated' => l.reactivated,
    'noteAdded' => l.noteAdded,
    _ => action,
  };
}

String _paymentDialogTitle(AppLocalizations l, _PaymentAction action) {
  return switch (action) {
    _PaymentAction.markPaid => l.markAsPaid,
    _PaymentAction.extend => l.extendDueDate,
    _PaymentAction.note => l.addNote,
    _PaymentAction.grace => l.moveToGracePeriod,
    _PaymentAction.suspend => l.suspendCompany,
    _PaymentAction.reactivate => l.reactivateCompany,
  };
}

String _paymentAmountLabel(CompanyMetadata company) {
  final amount = company.paymentAmount;
  final currency = (company.paymentCurrency ?? '').trim();
  if (amount == null || amount <= 0) {
    return '-';
  }
  final text = amount.truncateToDouble() == amount
      ? amount.toStringAsFixed(0)
      : amount.toStringAsFixed(2);
  return currency.isEmpty ? text : '$text $currency';
}

String _expectedThisMonthLabel(
    List<CompanyMetadata> companies,
    String? preferredCurrency,
    ) {
  final now = DateTime.now();
  var total = 0.0;
  String? currency;

  for (final company in companies) {
    final due = company.nextPaymentDueAt;
    final amount = company.paymentAmount;

    if (due == null || amount == null || amount <= 0) {
      continue;
    }

    if (due.year == now.year && due.month == now.month) {
      total += amount;

      final companyCurrency = (company.paymentCurrency ?? '').trim();
      if (currency == null && companyCurrency.isNotEmpty) {
        currency = companyCurrency;
      }
    }
  }

  if (total <= 0) {
    return '-';
  }

  final fallbackCurrency = (preferredCurrency ?? '').trim();
  final safeCurrency = (currency ?? fallbackCurrency).trim();
  final value = total.toStringAsFixed(
    total.truncateToDouble() == total ? 0 : 2,
  );

  return safeCurrency.isEmpty ? value : '$value $safeCurrency';
}
String _paymentDaysLabel(BuildContext context, CompanyMetadata company) {
  final l = AppLocalizations.of(context)!;
  final target = _paymentStatus(company) == 'gracePeriod'
      ? company.gracePeriodEndsAt
      : company.nextPaymentDueAt;
  if (target == null) {
    return l.notAvailable;
  }
  final days = target.difference(DateTime.now()).inDays;
  if (days >= 0) {
    return l.daysRemainingCount(days);
  }
  return l.overdueDaysCount(days.abs());
}

String _dateOrEmpty(BuildContext context, DateTime? value) {
  return value == null ? '-' : _formatDate(context, value);
}

String _shortDate(BuildContext context, DateTime value) {
  final localeName = Localizations.localeOf(context).toString();
  return DateFormat.yMd(localeName).format(value.toLocal());
}

String _dateInput(DateTime value) {
  return DateFormat('yyyy-MM-dd').format(value.toLocal());
}

DateTime? _parseDateInput(String value) {
  final clean = value.trim();
  if (clean.isEmpty) {
    return null;
  }
  return DateTime.tryParse(clean);
}

String? _dateValidator(String? value, AppLocalizations l, {bool futureOnly = true}) {
  final date = _parseDateInput(value ?? '');
  if (date == null) {
    return l.requiredField;
  }
  if (futureOnly && !date.isAfter(DateTime.now())) {
    return l.futureDateRequired;
  }
  return null;
}

String? _money(String? value, AppLocalizations l) {
  final amount = double.tryParse((value ?? '').trim());
  if (amount == null || amount < 0) {
    return l.enterValidNumber;
  }
  return null;
}

String? _currencyValidator(String? value, AppLocalizations l) {
  final clean = (value ?? '').trim();
  if (!RegExp(r'^[A-Za-z]{3}$').hasMatch(clean)) {
    return l.requiredField;
  }
  return null;
}

bool _isOperationalCompany(CompanyMetadata company) {
  return company.isUsable;
}

String _companyFilterLabel(AppLocalizations l, PlatformCompanyFilter filter) {
  return switch (filter) {
    PlatformCompanyFilter.all => l.allCompanies,
    PlatformCompanyFilter.active => l.active,
    PlatformCompanyFilter.inactive => l.inactive,
    PlatformCompanyFilter.trial => l.trial,
    PlatformCompanyFilter.trialExpired => l.trialEnded,
    PlatformCompanyFilter.paid => l.paid,
    PlatformCompanyFilter.dueSoon => l.dueSoon,
    PlatformCompanyFilter.overdue => l.overdue,
    PlatformCompanyFilter.gracePeriod => l.gracePeriod,
    PlatformCompanyFilter.suspended => l.suspended,
  };
}

String _sectionLabel(AppLocalizations l, _PlatformSection section) {
  return switch (section) {
    _PlatformSection.overview => l.platformOverview,
    _PlatformSection.monitoring => l.platformMonitoring,
    _PlatformSection.notifications => l.platformNotifications,
    _PlatformSection.invitations => l.invitations,
    _PlatformSection.companies => l.platformCompanies,
    _PlatformSection.workspace => l.workspace,
    _PlatformSection.releaseManagement => l.releaseCenter,
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
    _PlatformSection.monitoring => Icons.monitor_heart_outlined,
    _PlatformSection.notifications => Icons.notifications_active_outlined,
    _PlatformSection.invitations => Icons.mark_email_unread_outlined,
    _PlatformSection.companies => Icons.apartment_outlined,
    _PlatformSection.workspace => Icons.view_quilt_outlined,
    _PlatformSection.releaseManagement => Icons.system_update_alt_rounded,
    _PlatformSection.support => Icons.support_agent_outlined,
    _PlatformSection.activity => Icons.manage_history_outlined,
  };
}

String _workspaceTabLabel(AppLocalizations l, _WorkspaceTab tab) {
  return switch (tab) {
    _WorkspaceTab.summary => l.companyDetails,
    _WorkspaceTab.payments => l.paymentFollowUp,
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
    _WorkspaceTab.payments => Icons.payments_outlined,
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
  'exports',
  'auditLogs',
  'notifications',
  'userManagement',
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
    'exports' => l.exportCenter,
    'auditLogs' => l.auditLogs,
    'notifications' => l.notifications,
    'userManagement' => l.userManagement,
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


Future<void> _exportCompanyData(BuildContext context, CompanyMetadata company) async {
  final l = AppLocalizations.of(context)!;
  final selectedCollections = await _showPlatformExportPicker(context);
  if (!context.mounted || selectedCollections == null || selectedCollections.isEmpty) {
    return;
  }

  final data = await context.read<PlatformCubit>().exportCompanyData(
        companyId: company.id,
        collections: selectedCollections,
      );
  if (!context.mounted || data == null) {
    return;
  }

  final timestamp = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
  final serverBase64 = (data['base64Data'] ?? '').toString();
  final fileName = (data['fileName'] ?? 'masar_${company.id}_export_$timestamp.xlsx').toString();
  final bytes = serverBase64.trim().isNotEmpty
      ? Uint8List.fromList(base64Decode(serverBase64))
      : _buildPlatformExportWorkbook(
          context: context,
          company: company,
          payload: data,
          collections: selectedCollections,
        );
  final downloaded = await downloadBytes(
    fileName: fileName,
    mimeType: (data['mimeType'] ?? 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet').toString(),
    bytes: bytes,
  );
  if (!context.mounted) {
    return;
  }
  if (downloaded.success) {
    AppFeedback.success(context, l.companyDataExported);
  } else {
    AppFeedback.error(context, l.exportDownloadFailed);
  }
}

Future<List<String>?> _showPlatformExportPicker(BuildContext context) {
  final l = AppLocalizations.of(context)!;
  final options = _platformExportOptions(l);
  final selected = options.map((option) => option.collection).toSet();
  return showModalBottomSheet<List<String>>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    backgroundColor: AppColors.cardSurface(context),
    builder: (sheetContext) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l.exportCompanyData,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      for (final option in options)
                        FilterChip(
                          selected: selected.contains(option.collection),
                          label: Text(option.label),
                          avatar: Icon(option.icon, size: 18),
                          onSelected: (value) {
                            setModalState(() {
                              if (value) {
                                selected.add(option.collection);
                              } else {
                                selected.remove(option.collection);
                              }
                            });
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        child: Text(l.cancel),
                      ),
                      const Spacer(),
                      AppButton(
                        label: l.generateExport,
                        icon: Icons.file_download_outlined,
                        onPressed: selected.isEmpty
                            ? null
                            : () => Navigator.of(sheetContext)
                                .pop(selected.toList(growable: false)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

List<_PlatformExportOption> _platformExportOptions(AppLocalizations l) {
  return [
    _PlatformExportOption('users', l.companyUsers, Icons.people_alt_outlined),
    _PlatformExportOption('leads', l.leads, Icons.group_add_outlined),
    _PlatformExportOption('clients', l.clients, Icons.person_outline),
    _PlatformExportOption('properties', l.properties, Icons.apartment_outlined),
    _PlatformExportOption('tasks', l.tasks, Icons.check_circle_outline),
    _PlatformExportOption('deals', l.deals, Icons.handshake_outlined),
    _PlatformExportOption('appointments', l.appointments, Icons.calendar_today_outlined),
    _PlatformExportOption('notifications', l.notifications, Icons.notifications_none_outlined),
    _PlatformExportOption('audit_logs', l.auditLogs, Icons.history_outlined),
    _PlatformExportOption('teams', l.teams, Icons.groups_outlined),
  ];
}

class _PlatformExportOption {
  const _PlatformExportOption(this.collection, this.label, this.icon);

  final String collection;
  final String label;
  final IconData icon;
}

Uint8List _buildPlatformExportWorkbook({
  required BuildContext context,
  required CompanyMetadata company,
  required Map<String, dynamic> payload,
  required List<String> collections,
}) {
  final l = AppLocalizations.of(context)!;
  final isArabic = Localizations.localeOf(context).languageCode == 'ar';
  final options = {
    for (final option in _platformExportOptions(l)) option.collection: option.label,
  };
  final exportedAt = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());
  final data = payload['data'] is Map
      ? Map<String, dynamic>.from(payload['data'] as Map)
      : <String, dynamic>{};
  final sheets = <_SimpleXlsxSheet>[
    _SimpleXlsxSheet(
      name: l.reportSummary,
      rows: [
        ['Masar CRM'],
        [l.exportCompanyData],
        const <String>[],
        [l.company, _companyTitle(company)],
        [l.companyIdSlug, company.id],
        [l.generatedAt, exportedAt],
        [l.status, _statusLabel(l, company)],
        [l.features, collections.map((key) => options[key] ?? key).join(', ')],
        if (company.trialEndsAt != null)
          [l.trialEndsAt, _formatDate(context, company.trialEndsAt!)],
      ],
      titleRows: const {0, 1},
      rtl: isArabic,
      minVisibleColumns: 8,
    ),
  ];

  for (final collection in collections) {
    final list = data[collection] is List
        ? List<Object?>.from(data[collection] as List)
        : const <Object?>[];
    final maps = [
      for (final item in list)
        if (item is Map) Map<String, dynamic>.from(item),
    ];
    final columns = _platformExportColumns(context, collection);
    final rows = <List<String>>[
      [options[collection] ?? _humanizeExportKey(collection)],
      ['${l.company}: ${_companyTitle(company)}  -  ${l.generatedAt}: $exportedAt'],
      const <String>[],
      [for (final column in columns) column.label],
      for (final row in maps)
        [
          for (final column in columns)
            _exportCellText(
              _platformExportValue(row, column.keys),
              context: context,
              isPhone: column.isPhone,
              isEnum: column.isEnum,
              isDate: column.isDate,
            ),
        ],
    ];
    sheets.add(
      _SimpleXlsxSheet(
        name: options[collection] ?? _humanizeExportKey(collection),
        rows: rows,
        titleRows: const {0},
        subtitleRows: const {1},
        headerRows: const {3},
        freezeRows: 4,
        autoFilterRow: 3,
        rtl: isArabic,
        minVisibleColumns: columns.length,
      ),
    );
  }

  final archive = Archive();
  archive.addFile(ArchiveFile.string('[Content_Types].xml', _simpleContentTypes(sheets.length)));
  archive.addFile(ArchiveFile.string('_rels/.rels', _simpleRootRels()));
  archive.addFile(ArchiveFile.string('xl/workbook.xml', _simpleWorkbook(sheets)));
  archive.addFile(ArchiveFile.string('xl/_rels/workbook.xml.rels', _simpleWorkbookRels(sheets.length)));
  archive.addFile(ArchiveFile.string('xl/styles.xml', _simpleStyles()));
  for (var index = 0; index < sheets.length; index++) {
    archive.addFile(ArchiveFile.string('xl/worksheets/sheet${index + 1}.xml', _simpleWorksheet(sheets[index])));
  }
  return Uint8List.fromList(ZipEncoder().encode(archive));
}

class _PlatformExportColumn {
  const _PlatformExportColumn(
    this.label,
    this.keys, {
    this.isPhone = false,
    this.isDate = false,
    this.isEnum = false,
  });

  final String label;
  final List<String> keys;
  final bool isPhone;
  final bool isDate;
  final bool isEnum;
}

List<_PlatformExportColumn> _platformExportColumns(
  BuildContext context,
  String collection,
) {
  final l = AppLocalizations.of(context)!;
  final ar = Localizations.localeOf(context).languageCode == 'ar';
  String t(String en, String arabic) => ar ? arabic : en;

  switch (collection) {
    case 'users':
      return [
        _PlatformExportColumn(l.fullName, const ['fullName', 'name', 'displayName']),
        _PlatformExportColumn(l.email, const ['email']),
        _PlatformExportColumn(l.phone, const ['phone'], isPhone: true),
        _PlatformExportColumn(l.role, const ['role'], isEnum: true),
        _PlatformExportColumn(l.status, const ['isActive', 'status'], isEnum: true),
        _PlatformExportColumn(l.team, const ['teamName']),
        _PlatformExportColumn(l.manager, const ['managerName']),
        _PlatformExportColumn(t('Last login', 'آخر دخول'), const ['lastLoginAt'], isDate: true),
        _PlatformExportColumn(t('Login platform', 'منصة الدخول'), const ['lastLoginPlatform', 'lastLoginDeviceType']),
        _PlatformExportColumn(l.createdAt, const ['createdAt'], isDate: true),
        _PlatformExportColumn(l.updatedAt, const ['updatedAt'], isDate: true),
      ];
    case 'leads':
      return [
        _PlatformExportColumn(l.fullName, const ['fullName', 'name', 'leadName', 'title']),
        _PlatformExportColumn(l.phone, const ['phone'], isPhone: true),
        _PlatformExportColumn(l.email, const ['email']),
        _PlatformExportColumn(l.status, const ['status'], isEnum: true),
        _PlatformExportColumn(l.priority, const ['priority'], isEnum: true),
        _PlatformExportColumn(l.source, const ['source'], isEnum: true),
        _PlatformExportColumn(l.assignedAgent, const ['assignedToName', 'assignedUserName']),
        _PlatformExportColumn(l.team, const ['teamName']),
        _PlatformExportColumn(l.manager, const ['managerName']),
        _PlatformExportColumn(l.budget, const ['budget', 'budgetMin', 'expectedBudget']),
        _PlatformExportColumn(l.nextFollowUp, const ['nextFollowUpAt', 'nextFollowUpDate', 'nextFollowUp'], isDate: true),
        _PlatformExportColumn(l.createdAt, const ['createdAt'], isDate: true),
      ];
    case 'clients':
      return [
        _PlatformExportColumn(l.fullName, const ['fullName', 'name', 'clientName', 'title']),
        _PlatformExportColumn(l.phone, const ['phone'], isPhone: true),
        _PlatformExportColumn(l.email, const ['email']),
        _PlatformExportColumn(l.status, const ['status'], isEnum: true),
        _PlatformExportColumn(l.assignedAgent, const ['assignedToName', 'assignedUserName']),
        _PlatformExportColumn(l.team, const ['teamName']),
        _PlatformExportColumn(l.manager, const ['managerName']),
        _PlatformExportColumn(l.createdAt, const ['createdAt'], isDate: true),
        _PlatformExportColumn(l.updatedAt, const ['updatedAt'], isDate: true),
      ];
    case 'properties':
      return [
        _PlatformExportColumn(l.title, const ['title', 'name', 'propertyName']),
        _PlatformExportColumn(l.status, const ['status'], isEnum: true),
        _PlatformExportColumn(l.type, const ['type', 'propertyType'], isEnum: true),
        _PlatformExportColumn(t('Listing', 'نوع العرض'), const ['listingType'], isEnum: true),
        _PlatformExportColumn(l.price, const ['price', 'amount', 'value']),
        _PlatformExportColumn(l.location, const ['location', 'address', 'city']),
        _PlatformExportColumn(t('Area', 'المساحة'), const ['area', 'areaSqm', 'size']),
        _PlatformExportColumn(l.createdAt, const ['createdAt'], isDate: true),
        _PlatformExportColumn(l.updatedAt, const ['updatedAt'], isDate: true),
      ];
    case 'tasks':
      return [
        _PlatformExportColumn(l.title, const ['title', 'name']),
        _PlatformExportColumn(l.status, const ['status'], isEnum: true),
        _PlatformExportColumn(l.priority, const ['priority'], isEnum: true),
        _PlatformExportColumn(l.dueDate, const ['dueDate', 'dueAt'], isDate: true),
        _PlatformExportColumn(l.assignedAgent, const ['assignedToName', 'assignedUserName']),
        _PlatformExportColumn(t('Related record', 'السجل المرتبط'), const ['relatedTitle']),
        _PlatformExportColumn(l.createdAt, const ['createdAt'], isDate: true),
        _PlatformExportColumn(l.updatedAt, const ['updatedAt'], isDate: true),
      ];
    case 'deals':
      return [
        _PlatformExportColumn(l.title, const ['title', 'name', 'dealName']),
        _PlatformExportColumn(l.client, const ['clientName', 'clientTitle']),
        _PlatformExportColumn(l.property, const ['propertyTitle', 'propertyName']),
        _PlatformExportColumn(l.stage, const ['stage', 'status'], isEnum: true),
        _PlatformExportColumn(l.value, const ['value', 'amount', 'price']),
        _PlatformExportColumn(l.assignedAgent, const ['assignedToName', 'assignedUserName']),
        _PlatformExportColumn(l.createdAt, const ['createdAt'], isDate: true),
        _PlatformExportColumn(l.updatedAt, const ['updatedAt'], isDate: true),
      ];
    case 'appointments':
      return [
        _PlatformExportColumn(l.title, const ['title', 'name']),
        _PlatformExportColumn(l.status, const ['status'], isEnum: true),
        _PlatformExportColumn(t('Date', 'التاريخ'), const ['startAt', 'startsAt', 'appointmentAt'], isDate: true),
        _PlatformExportColumn(t('End time', 'وقت الانتهاء'), const ['endAt', 'endsAt'], isDate: true),
        _PlatformExportColumn(l.location, const ['location']),
        _PlatformExportColumn(l.assignedAgent, const ['assignedToName', 'assignedUserName']),
        _PlatformExportColumn(t('Related record', 'السجل المرتبط'), const ['relatedTitle']),
      ];
    case 'notifications':
      return [
        _PlatformExportColumn(l.title, const ['title']),
        _PlatformExportColumn(l.message, const ['message']),
        _PlatformExportColumn(l.type, const ['type'], isEnum: true),
        _PlatformExportColumn(l.status, const ['isRead', 'read'], isEnum: true),
        _PlatformExportColumn(l.createdAt, const ['createdAt'], isDate: true),
      ];
    case 'audit_logs':
      return [
        _PlatformExportColumn(t('Actor', 'المنفذ'), const ['actorName']),
        _PlatformExportColumn(l.email, const ['actorEmail']),
        _PlatformExportColumn(l.module, const ['module'], isEnum: true),
        _PlatformExportColumn(l.action, const ['action'], isEnum: true),
        _PlatformExportColumn(t('Record', 'السجل'), const ['recordTitle', 'title']),
        _PlatformExportColumn(l.createdAt, const ['createdAt'], isDate: true),
      ];
    case 'teams':
      return [
        _PlatformExportColumn(l.team, const ['name', 'teamName']),
        _PlatformExportColumn(l.manager, const ['managerName']),
        _PlatformExportColumn(l.status, const ['isActive', 'status'], isEnum: true),
        _PlatformExportColumn(t('Members', 'الأعضاء'), const ['memberCount', 'membersCount']),
        _PlatformExportColumn(l.createdAt, const ['createdAt'], isDate: true),
        _PlatformExportColumn(l.updatedAt, const ['updatedAt'], isDate: true),
      ];
  }
  return [
    _PlatformExportColumn(l.fullName, const ['name', 'title', 'displayName']),
    _PlatformExportColumn(l.status, const ['status'], isEnum: true),
    _PlatformExportColumn(l.createdAt, const ['createdAt'], isDate: true),
    _PlatformExportColumn(l.updatedAt, const ['updatedAt'], isDate: true),
  ];
}

Object? _platformExportValue(Map<String, dynamic> row, List<String> keys) {
  for (final key in keys) {
    if (row.containsKey(key) && row[key] != null) {
      final value = row[key];
      if (value is String && value.trim().isEmpty) {
        continue;
      }
      return value;
    }
  }
  return null;
}

String _exportCellText(
  Object? value, {
  required BuildContext context,
  bool isPhone = false,
  bool isDate = false,
  bool isEnum = false,
}) {
  final l = AppLocalizations.of(context)!;
  if (value == null) return '-';
  if (value is bool) return value ? l.yes : l.no;
  if (value is num) return isPhone ? value.toStringAsFixed(0) : value.toString();
  final text = value.toString().trim();
  if (text.isEmpty) return '-';
  final parsedDate = _parseExportDate(value);
  if (isDate && parsedDate != null) {
    return DateFormat('yyyy-MM-dd HH:mm').format(parsedDate);
  }
  if (value is Map || value is List) {
    return _compactExportObject(value);
  }
  if (isEnum) {
    return _humanizeExportKey(text);
  }
  if (text.startsWith('http://') || text.startsWith('https://')) {
    return '-';
  }
  if (_looksLikeUid(text)) {
    return '-';
  }
  return text;
}

DateTime? _parseExportDate(Object? value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is Map && value.containsKey('_seconds')) {
    final seconds = value['_seconds'];
    if (seconds is num) {
      return DateTime.fromMillisecondsSinceEpoch(seconds.toInt() * 1000);
    }
  }
  if (value is String) {
    return DateTime.tryParse(value);
  }
  return null;
}

String _compactExportObject(Object value) {
  if (value is List) {
    return value.isEmpty ? '-' : '${value.length}';
  }
  if (value is Map) {
    final readable = <String>[];
    for (final entry in value.entries) {
      final key = entry.key.toString();
      final child = entry.value;
      if (child == null || key.startsWith('_')) continue;
      if (child is String && child.trim().isEmpty) continue;
      if (child is Map || child is List) continue;
      readable.add('${_humanizeExportKey(key)}: $child');
      if (readable.length == 3) break;
    }
    return readable.isEmpty ? '-' : readable.join(' | ');
  }
  return value.toString();
}

String _humanizeExportKey(String value) {
  final cleaned = value
      .replaceAll('_', ' ')
      .replaceAll('-', ' ')
      .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m.group(1)} ${m.group(2)}')
      .trim();
  if (cleaned.isEmpty) return '-';
  return cleaned
      .split(RegExp(r'\s+'))
      .map((word) => word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1)}')
      .join(' ');
}

class _SimpleXlsxSheet {
  const _SimpleXlsxSheet({
    required this.name,
    required this.rows,
    this.titleRows = const {},
    this.subtitleRows = const {},
    this.headerRows = const {},
    this.freezeRows = 0,
    this.autoFilterRow,
    this.rtl = false,
    this.minVisibleColumns = 8,
  });

  final String name;
  final List<List<String>> rows;
  final Set<int> titleRows;
  final Set<int> subtitleRows;
  final Set<int> headerRows;
  final int freezeRows;
  final int? autoFilterRow;
  final bool rtl;
  final int minVisibleColumns;
}

String _simpleContentTypes(int sheetCount) => '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"><Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/><Default Extension="xml" ContentType="application/xml"/><Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/><Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>${List.generate(sheetCount, (i) => '<Override PartName="/xl/worksheets/sheet${i + 1}.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>').join()}</Types>''';

String _simpleRootRels() => '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/></Relationships>''';

String _simpleWorkbook(List<_SimpleXlsxSheet> sheets) => '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?><workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"><sheets>${List.generate(sheets.length, (i) => '<sheet name="${_xml(_safeSheetName(sheets[i].name))}" sheetId="${i + 1}" r:id="rId${i + 1}"/>').join()}</sheets></workbook>''';

String _simpleWorkbookRels(int sheetCount) => '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">${List.generate(sheetCount, (i) => '<Relationship Id="rId${i + 1}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet${i + 1}.xml"/>').join()}<Relationship Id="rId${sheetCount + 1}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/></Relationships>''';

String _simpleStyles() => '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?><styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"><fonts count="4"><font><sz val="11"/><name val="Arial"/><color rgb="FF1F2933"/></font><font><b/><sz val="18"/><name val="Arial"/><color rgb="FF111827"/></font><font><b/><sz val="11"/><name val="Arial"/><color rgb="FF111827"/></font><font><sz val="10"/><name val="Arial"/><color rgb="FF6B6256"/></font></fonts><fills count="5"><fill><patternFill patternType="none"/></fill><fill><patternFill patternType="gray125"/></fill><fill><patternFill patternType="solid"><fgColor rgb="FFFFFFFF"/><bgColor indexed="64"/></patternFill></fill><fill><patternFill patternType="solid"><fgColor rgb="FFFFF8EA"/><bgColor indexed="64"/></patternFill></fill><fill><patternFill patternType="solid"><fgColor rgb="FFF4BE45"/><bgColor indexed="64"/></patternFill></fill></fills><borders count="2"><border><left/><right/><top/><bottom/><diagonal/></border><border><left style="thin"><color rgb="FFE6D8C1"/></left><right style="thin"><color rgb="FFE6D8C1"/></right><top style="thin"><color rgb="FFE6D8C1"/></top><bottom style="thin"><color rgb="FFE6D8C1"/></bottom><diagonal/></border></borders><cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="2" borderId="0" applyFill="1"/></cellStyleXfs><cellXfs count="5"><xf numFmtId="0" fontId="0" fillId="2" borderId="0" xfId="0" applyFill="1"/><xf numFmtId="0" fontId="1" fillId="3" borderId="0" xfId="0" applyFont="1" applyFill="1"/><xf numFmtId="0" fontId="2" fillId="4" borderId="1" xfId="0" applyFont="1" applyFill="1" applyBorder="1"><alignment wrapText="1" vertical="center"/></xf><xf numFmtId="0" fontId="0" fillId="2" borderId="1" xfId="0" applyFill="1" applyBorder="1"><alignment wrapText="1" vertical="center"/></xf><xf numFmtId="0" fontId="3" fillId="3" borderId="0" xfId="0" applyFont="1" applyFill="1"><alignment wrapText="1" vertical="center"/></xf></cellXfs><cellStyles count="1"><cellStyle name="Normal" xfId="0" builtinId="0"/></cellStyles></styleSheet>''';

String _simpleWorksheet(_SimpleXlsxSheet sheet) {
  final maxColumns = sheet.rows.fold<int>(
    sheet.minVisibleColumns,
    (value, row) => row.length > value ? row.length : value,
  ).clamp(1, 40).toInt();
  final actualRowCount = sheet.rows.length;
  final minRows = actualRowCount < 30 ? 30 : actualRowCount;
  final rows = <String>[];
  for (var r = 0; r < minRows; r++) {
    final source = r < sheet.rows.length ? sheet.rows[r] : const <String>[];
    final cells = <String>[];
    for (var c = 0; c < maxColumns; c++) {
      final text = c < source.length ? source[c] : '';
      final style = sheet.titleRows.contains(r)
          ? 1
          : sheet.headerRows.contains(r)
              ? 2
              : sheet.subtitleRows.contains(r)
                  ? 4
                  : 3;
      cells.add('<c r="${_col(c)}${r + 1}" t="inlineStr" s="$style"><is><t>${_xml(text)}</t></is></c>');
    }
    rows.add('<row r="${r + 1}">${cells.join()}</row>');
  }
  final cols = '<cols>${List.generate(maxColumns, (i) => '<col min="${i + 1}" max="${i + 1}" width="${i == 0 ? 22 : 18}" customWidth="1"/>').join()}</cols>';
  final freeze = sheet.freezeRows > 0
      ? '<sheetViews><sheetView workbookViewId="0"${sheet.rtl ? ' rightToLeft="1"' : ''}><pane ySplit="${sheet.freezeRows}" topLeftCell="A${sheet.freezeRows + 1}" activePane="bottomLeft" state="frozen"/></sheetView></sheetViews>'
      : '<sheetViews><sheetView workbookViewId="0"${sheet.rtl ? ' rightToLeft="1"' : ''}/></sheetViews>';
  final filterLastRow = actualRowCount < 1 ? 1 : actualRowCount;
  final filter = sheet.autoFilterRow == null
      ? ''
      : '<autoFilter ref="A${sheet.autoFilterRow! + 1}:${_col(maxColumns - 1)}$filterLastRow"/>';
  return '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"><dimension ref="A1:${_col(maxColumns - 1)}$minRows"/>$freeze$cols<sheetData>${rows.join()}</sheetData>$filter</worksheet>';
}

String _col(int index) {
  var n = index + 1;
  var result = '';
  while (n > 0) {
    final r = (n - 1) % 26;
    result = String.fromCharCode(65 + r) + result;
    n = (n - r - 1) ~/ 26;
  }
  return result;
}

String _safeSheetName(String value) {
  final clean = value.replaceAll(RegExp(r'[\/\?\*\[\]:]'), ' ').trim();
  return (clean.isEmpty ? 'Sheet' : clean).characters.take(31).toString();
}

String _xml(Object? value) => (value ?? '').toString().replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;').replaceAll('"', '&quot;').replaceAll("'", '&apos;');


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
  if (!state.hasSelectedCompanyUsers) {
    return AppLocalizations.of(context)!.notAvailable;
  }
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

String _roleText(AppLocalizations l, String role) {
  return switch (role.trim()) {
    RoleConstants.admin => l.admin,
    RoleConstants.manager => l.manager,
    RoleConstants.salesAgent => l.salesAgent,
    RoleConstants.marketing => l.marketing,
    RoleConstants.viewer => l.viewer,
    _ => role.trim().isEmpty ? l.notAvailable : role.trim(),
  };
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
  return AppValidators.password(
    value,
    l,
    requiredMessage: l.newPasswordRequired,
  );
}

String _platformErrorMessage(
  AppLocalizations l,
  String? message, {
  String? fallback,
}) {
  if (message == 'weak-password' || message == 'Password is too weak.') {
    return l.weakPassword;
  }
  return switch (message) {
    null => fallback ?? l.unableToSave,
    _ => message,
  };
}

String? _positiveInteger(String? value, AppLocalizations l) {
  final parsed = int.tryParse((value ?? '').trim());
  return parsed == null || parsed <= 0 ? l.enterValidNumber : null;
}
