import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart' as intl;

import '../../../../core/constants/role_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/utils/external_link_opener.dart';
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
import '../../../../core/widgets/crm_app_shell.dart';
import '../../../../core/widgets/module_kpi_card.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../data/datasources/company_users_remote_data_source.dart';
import '../../domain/entities/company_user_login_activity.dart';
import '../../domain/entities/company_crm_user.dart';
import '../cubit/company_user_login_activity_cubit.dart';
import '../cubit/company_user_login_activity_state.dart';
import '../cubit/company_users_cubit.dart';
import '../cubit/company_users_state.dart';
import '../../../../core/widgets/masar_loading_view.dart';
import '../../../../core/widgets/masar_user_avatar.dart';

class CompanyUsersPage extends StatelessWidget {
  const CompanyUsersPage({super.key});

  static Widget withDependencies() {
    return BlocProvider(
      create: (_) => CompanyUsersCubit(
        remoteDataSource: FirebaseCompanyUsersRemoteDataSource(),
      ),
      child: const CompanyUsersPage(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final authState = context.watch<AuthBloc>().state;
    final profile = authState.userProfile;
    if (profile == null || profile.role != UserRole.admin) {
      return CrmAppShell(
        selectedItem: CrmNavigationItem.users,
        title: l.userManagement,
        child: AppErrorView(
          title: l.permissionDenied,
          message: l.permissionDenied,
        ),
      );
    }

    return _CompanyUsersScope(
      companyId: profile.companyId,
      currentUserId: authState.user?.uid ?? '',
    );
  }
}

class _CompanyUsersScope extends StatefulWidget {
  const _CompanyUsersScope({
    required this.companyId,
    required this.currentUserId,
  });

  final String companyId;
  final String currentUserId;

  @override
  State<_CompanyUsersScope> createState() => _CompanyUsersScopeState();
}

class _CompanyUsersScopeState extends State<_CompanyUsersScope> {
  @override
  void initState() {
    super.initState();
    context.read<CompanyUsersCubit>().watch(widget.companyId);
  }

  @override
  void didUpdateWidget(covariant _CompanyUsersScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.companyId != widget.companyId) {
      context.read<CompanyUsersCubit>().watch(widget.companyId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return CrmAppShell(
      selectedItem: CrmNavigationItem.users,
      title: l.userManagement,
      child: BlocBuilder<CompanyUsersCubit, CompanyUsersState>(
        builder: (context, state) {
          final saving = state.status == CompanyUsersStatus.saving;
          final controls = _UsersControls(
            companyId: widget.companyId,
            saving: saving,
          );
          final content = _UsersListContent(
            companyId: widget.companyId,
            currentUserId: widget.currentUserId,
            state: state,
            saving: saving,
          );

          return LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 720;
              final bottomPadding = isNarrow ? 112.0 : AppSpacing.md;
              final body = Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _UsersHeader(
                    companyId: widget.companyId,
                    saving: saving,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _UsersSummaryCards(state: state),
                  const SizedBox(height: AppSpacing.sm),
                  controls,
                  const SizedBox(height: AppSpacing.sm),
                  content,
                  SizedBox(height: bottomPadding),
                ],
              );

              return SingleChildScrollView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: constraints.maxWidth.isFinite
                        ? constraints.maxWidth
                        : 0,
                    minHeight: constraints.maxHeight.isFinite
                        ? constraints.maxHeight
                        : 0,
                  ),
                  child: body,
                ),
              );
            },
          );
        },
      ),
    );
  }
}


class _UsersSummaryCards extends StatelessWidget {
  const _UsersSummaryCards({required this.state});

  final CompanyUsersState state;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cubit = context.read<CompanyUsersCubit>();
    final users = state.users;
    final activeUsers = users.where((user) => user.isActive).length;
    final inactiveUsers = users.where((user) => !user.isActive).length;
    final managers = users.where((user) => user.role == 'manager').length;
    final salesUsers = users.where((user) => user.role == 'salesAgent').length;
    final admins = users.where((user) => user.role == 'admin').length;

    final cards = <ModuleKpiCardData>[
      ModuleKpiCardData(
        label: l.companyUsers,
        value: users.length.toString(),
        icon: Icons.groups_2_outlined,
        tone: AppStatusTone.info,
        selected: state.roleFilter.trim().isEmpty && state.activeFilter == null,
        onTap: () {
          cubit.applyRoleFilter(null);
          cubit.applyActiveFilter(null);
        },
      ),
      ModuleKpiCardData(
        label: l.active,
        value: activeUsers.toString(),
        icon: Icons.verified_user_outlined,
        tone: AppStatusTone.success,
        selected: state.activeFilter == true,
        onTap: () => cubit.applyActiveFilter(true),
      ),
      ModuleKpiCardData(
        label: l.inactive,
        value: inactiveUsers.toString(),
        icon: Icons.person_off_outlined,
        tone: AppStatusTone.error,
        selected: state.activeFilter == false,
        onTap: () => cubit.applyActiveFilter(false),
      ),
      ModuleKpiCardData(
        label: l.manager,
        value: managers.toString(),
        icon: Icons.supervisor_account_outlined,
        tone: AppStatusTone.info,
        selected: state.roleFilter == 'manager',
        onTap: () => cubit.applyRoleFilter('manager'),
      ),
      ModuleKpiCardData(
        label: l.salesAgent,
        value: salesUsers.toString(),
        icon: Icons.badge_outlined,
        tone: AppStatusTone.warning,
        selected: state.roleFilter == 'salesAgent',
        onTap: () => cubit.applyRoleFilter('salesAgent'),
      ),
      ModuleKpiCardData(
        label: l.admin,
        value: admins.toString(),
        icon: Icons.admin_panel_settings_outlined,
        tone: AppStatusTone.neutral,
        selected: state.roleFilter == 'admin',
        onTap: () => cubit.applyRoleFilter('admin'),
      ),
    ];

    return ModuleKpiStrip(cards: cards);
  }
}


class _UsersControls extends StatelessWidget {
  const _UsersControls({required this.companyId, required this.saving});

  final String companyId;
  final bool saving;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final isNarrow = MediaQuery.sizeOf(context).width < 720;
    final search = AppSearchField(
      hint: l.searchUsers,
      onChanged: context.read<CompanyUsersCubit>().updateQuery,
    );
    final createButton = AppButton(
      label: l.createUser,
      icon: Icons.person_add_alt_1_outlined,
      isLoading: saving,
      isExpanded: isNarrow,
      onPressed: saving
          ? null
          : () async {
              final result = await _showAddUserDialog(context, companyId);
              if (context.mounted && result != null) {
                if (result.usedTemporaryPassword) {
                  _showTemporaryPasswordCreatedDialog(context);
                } else {
                  _showSetupLinkDialog(context, result.resetLink);
                }
              }
            },
    );

    if (isNarrow) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          search,
          const SizedBox(height: AppSpacing.sm),
          createButton,
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: search),
        const SizedBox(width: AppSpacing.sm),
        createButton,
      ],
    );
  }
}

class _UsersListContent extends StatelessWidget {
  const _UsersListContent({
    required this.companyId,
    required this.currentUserId,
    required this.state,
    required this.saving,
  });

  final String companyId;
  final String currentUserId;
  final CompanyUsersState state;
  final bool saving;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    if (state.status == CompanyUsersStatus.loading) {
      return const Center(child: AppLoading());
    }

    if (state.status == CompanyUsersStatus.failure) {
      return AppErrorView(
        title: l.errorOccurred,
        message: _companyUserErrorMessage(l, state.message),
        onRetry: () => context.read<CompanyUsersCubit>().watch(companyId),
      );
    }

    if (state.filteredUsers.isEmpty) {
      return AppEmptyState(
        icon: Icons.people_outline,
        title: l.noCompanyUsers,
        message: l.companyUsersEmptyMessage,
      );
    }

    final sortedUsers = _sortCompanyUsersByRole(state.filteredUsers);
    final isNarrow = MediaQuery.sizeOf(context).width < 720;
    if (isNarrow) {
      return Column(
        children: [
          for (var index = 0; index < sortedUsers.length; index++) ...[
            _UserRow(
              companyId: companyId,
              user: sortedUsers[index],
              currentUserId: currentUserId,
              saving: saving,
            ),
            if (index != sortedUsers.length - 1)
              const SizedBox(height: AppSpacing.xs),
          ],
        ],
      );
    }

    return Column(
      children: [
        for (var index = 0; index < sortedUsers.length; index++) ...[
          _UserRow(
            companyId: companyId,
            user: sortedUsers[index],
            currentUserId: currentUserId,
            saving: saving,
          ),
          if (index != sortedUsers.length - 1)
            const SizedBox(height: AppSpacing.xs),
        ],
      ],
    );
  }
}

List<CompanyCrmUser> _sortCompanyUsersByRole(List<CompanyCrmUser> users) {
  final sorted = [...users];
  sorted.sort((a, b) {
    final roleCompare = _companyUserRoleRank(a.role).compareTo(
      _companyUserRoleRank(b.role),
    );
    if (roleCompare != 0) {
      return roleCompare;
    }
    final activeCompare = (b.isActive ? 1 : 0).compareTo(a.isActive ? 1 : 0);
    if (activeCompare != 0) {
      return activeCompare;
    }
    return _companyUserSortName(a).compareTo(_companyUserSortName(b));
  });
  return sorted;
}

int _companyUserRoleRank(String role) {
  return switch (role) {
    RoleConstants.admin => 0,
    RoleConstants.manager => 1,
    RoleConstants.salesAgent => 2,
    RoleConstants.marketing => 3,
    RoleConstants.viewer => 4,
    _ => 5,
  };
}

String _companyUserSortName(CompanyCrmUser user) {
  final name = user.fullName.trim();
  if (name.isNotEmpty) {
    return name.toLowerCase();
  }
  final email = user.email.trim();
  if (email.isNotEmpty) {
    return email.toLowerCase();
  }
  return user.uid.toLowerCase();
}

class _UsersHeader extends StatelessWidget {
  const _UsersHeader({required this.companyId, required this.saving});

  final String companyId;
  final bool saving;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.cardSurface(context),
        border: Border.all(color: AppColors.borderColor(context)),
        borderRadius: AppRadius.xLarge,
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primaryColor(context).withValues(alpha: 0.10),
              borderRadius: AppRadius.large,
            ),
            child: Icon(
              Icons.manage_accounts_outlined,
              color: AppColors.primaryColor(context),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.userManagement,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  l.userManagementSubtitle,
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
    );
  }
}

class _UserRow extends StatelessWidget {
  const _UserRow({
    required this.companyId,
    required this.user,
    required this.currentUserId,
    required this.saving,
  });

  final String companyId;
  final CompanyCrmUser user;
  final String currentUserId;
  final bool saving;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final isNarrow = MediaQuery.sizeOf(context).width < 720;
    final avatar = MasarUserAvatar(
      name: user.fullName,
      photoUrl: user.photoUrl,
      cacheKey: user.photoStoragePath.trim().isNotEmpty
          ? user.photoStoragePath
          : (user.updatedAt?.millisecondsSinceEpoch.toString() ?? ''),
      radius: isNarrow ? 14 : 15,
    );
    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          user.fullName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
        Text(
          _isolate(user.email),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (user.teamName.trim().isNotEmpty)
          Text(
            _isolate(user.teamName),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: AppColors.textSecondaryColor(context)),
          ),
      ],
    );
    final badges = Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: [
        AppStatusBadge(label: _roleLabel(l, user.role), tone: AppStatusTone.info),
        AppStatusBadge(
          label: user.isActive ? l.active : l.inactive,
          tone: user.isActive ? AppStatusTone.success : AppStatusTone.error,
        ),
        if (user.mustChangePassword)
          AppStatusBadge(label: l.mustChangePassword, tone: AppStatusTone.warning),
      ],
    );
    final actions = PopupMenuButton<_CompanyUserAction>(
      enabled: !saving,
      tooltip: l.actions,
      onSelected: (action) => _handleUserAction(
        context,
        action: action,
        companyId: companyId,
        user: user,
        currentUserId: currentUserId,
      ),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: _CompanyUserAction.generateSetupLink,
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.link_outlined),
            title: Text(l.generateSetupLink),
          ),
        ),
        PopupMenuItem(
          value: _CompanyUserAction.loginActivity,
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.manage_history_outlined),
            title: Text(l.loginActivity),
          ),
        ),
        if (user.role != 'admin' && user.uid != currentUserId)
          PopupMenuItem(
            value: user.isActive
                ? _CompanyUserAction.deactivate
                : _CompanyUserAction.activate,
            child: ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                user.isActive
                    ? Icons.person_off_outlined
                    : Icons.person_add_alt_1_outlined,
              ),
              title: Text(user.isActive ? l.deactivateUser : l.activateUser),
            ),
          ),
      ],
      icon: const Icon(Icons.more_vert),
    );

    return Container(
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: isNarrow ? AppSpacing.sm : AppSpacing.sm,
        vertical: isNarrow ? 6 : 7,
      ),
      decoration: BoxDecoration(
        color: AppColors.cardSurface(context),
        border: Border.all(color: AppColors.borderColor(context)),
        borderRadius: AppRadius.large,
      ),
      child: isNarrow
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    avatar,
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(child: details),
                    actions,
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                badges,
              ],
            )
          : Row(
              children: [
                avatar,
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: details),
                badges,
                const SizedBox(width: AppSpacing.xs),
                actions,
              ],
            ),
    );
  }
}


enum _CompanyUserAction {
  generateSetupLink,
  loginActivity,
  activate,
  deactivate,
}

Future<void> _handleUserAction(
  BuildContext context, {
  required _CompanyUserAction action,
  required String companyId,
  required CompanyCrmUser user,
  required String currentUserId,
}) async {
  final l = AppLocalizations.of(context)!;
  switch (action) {
    case _CompanyUserAction.generateSetupLink:
      await _showGenerateSetupLinkDialog(
        context,
        companyId: companyId,
        user: user,
      );
      return;
    case _CompanyUserAction.loginActivity:
      await _showUserLoginActivityDialog(
        context,
        companyId: companyId,
        user: user,
      );
      return;
    case _CompanyUserAction.activate:
      await _confirmAndSetUserActiveStatus(
        context,
        companyId: companyId,
        user: user,
        isActive: true,
      );
      return;
    case _CompanyUserAction.deactivate:
      if (user.uid == currentUserId) {
        AppFeedback.error(context, l.permissionDenied);
        return;
      }
      await _confirmAndSetUserActiveStatus(
        context,
        companyId: companyId,
        user: user,
        isActive: false,
      );
  }
}

Future<void> _confirmAndSetUserActiveStatus(
  BuildContext context, {
  required String companyId,
  required CompanyCrmUser user,
  required bool isActive,
}) async {
  final l = AppLocalizations.of(context)!;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(isActive ? l.activateUser : l.deactivateUser),
      content: Text(
        isActive
            ? l.activateUserConfirmation
            : l.deactivateUserConfirmation,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(l.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(isActive ? l.activateUser : l.deactivateUser),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) {
    return;
  }
  final success = await context.read<CompanyUsersCubit>().setUserActiveStatus(
        companyId: companyId,
        uid: user.uid,
        isActive: isActive,
      );
  if (context.mounted && success) {
    AppFeedback.success(context, l.settingsSaved);
  }
}

Future<void> _showUserLoginActivityDialog(
  BuildContext context, {
  required String companyId,
  required CompanyCrmUser user,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) => BlocProvider(
      create: (_) => CompanyUserLoginActivityCubit(
        remoteDataSource: FirebaseCompanyUsersRemoteDataSource(),
      )..watch(companyId: companyId, uid: user.uid),
      child: _UserLoginActivityDialog(user: user),
    ),
  );
}

class _UserLoginActivityDialog extends StatelessWidget {
  const _UserLoginActivityDialog({required this.user});

  final CompanyCrmUser user;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.62;
    return AlertDialog(
      title: Text(l.recentLoginActivity),
      content: SizedBox(
        width: 560,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _LoginActivityUserHeader(user: user),
            const SizedBox(height: AppSpacing.md),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxHeight),
              child: BlocBuilder<CompanyUserLoginActivityCubit,
                  CompanyUserLoginActivityState>(
                builder: (context, state) {
                  if (state.status == CompanyUserLoginActivityStatus.loading ||
                      state.status == CompanyUserLoginActivityStatus.initial) {
                    return const SizedBox(
                      height: 160,
                      child: Center(child: MasarLogoLoader(size: 38)),
                    );
                  }

                  if (state.status == CompanyUserLoginActivityStatus.failure) {
                    return AppEmptyState(
                      icon: Icons.manage_history_outlined,
                      title: l.somethingWentWrong,
                      message: _companyUserErrorMessage(l, state.message),
                    );
                  }

                  if (state.activities.isEmpty) {
                    return AppEmptyState(
                      icon: Icons.manage_history_outlined,
                      title: l.noLoginActivityYet,
                      message: l.noData,
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    itemCount: state.activities.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.xs),
                    itemBuilder: (context, index) {
                      return _LoginActivityCard(
                        activity: state.activities[index],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l.close),
        ),
      ],
    );
  }
}

class _LoginActivityUserHeader extends StatelessWidget {
  const _LoginActivityUserHeader({required this.user});

  final CompanyCrmUser user;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.appBackground(context),
        border: Border.all(color: AppColors.borderColor(context)),
        borderRadius: AppRadius.large,
      ),
      child: Row(
        children: [
          MasarUserAvatar(
            name: user.fullName,
            photoUrl: user.photoUrl,
            cacheKey: user.photoStoragePath.trim().isNotEmpty
                ? user.photoStoragePath
                : (user.updatedAt?.millisecondsSinceEpoch.toString() ?? ''),
            radius: 18,
          ),
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
                        fontWeight: FontWeight.w900,
                      ),
                ),
                Text(
                  _isolate(user.email),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textSecondaryColor(context),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          AppStatusBadge(
            label: _roleLabel(l, user.role),
            tone: AppStatusTone.info,
          ),
        ],
      ),
    );
  }
}

class _LoginActivityCard extends StatelessWidget {
  const _LoginActivityCard({required this.activity});

  final CompanyUserLoginActivity activity;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.cardSurface(context),
        border: Border.all(color: AppColors.borderColor(context)),
        borderRadius: AppRadius.large,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.login_outlined,
                size: 18,
                color: AppColors.primaryColor(context),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  _loginActivityDateLabel(context, activity.createdAt),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String _loginActivityDateLabel(BuildContext context, DateTime? value) {
  if (value == null) {
    return AppLocalizations.of(context)!.notAvailable;
  }
  final localeName = Localizations.localeOf(context).toString();
  return intl.DateFormat.yMMMd(localeName).add_jm().format(value.toLocal());
}

Future<CreatedCompanyUserResult?> _showAddUserDialog(BuildContext context, String companyId) {
  final cubit = context.read<CompanyUsersCubit>();
  return showDialog<CreatedCompanyUserResult?>(
    context: context,
    builder: (_) => BlocProvider<CompanyUsersCubit>.value(
      value: cubit,
      child: _AddUserDialog(companyId: companyId),
    ),
  );
}

class _AddUserDialog extends StatefulWidget {
  const _AddUserDialog({required this.companyId});

  final String companyId;

  @override
  State<_AddUserDialog> createState() => _AddUserDialogState();
}

class _AddUserDialogState extends State<_AddUserDialog> {
  final _formKey = GlobalKey<FormState>();
  final _fullName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _temporaryPassword = TextEditingController();
  final _confirmTemporaryPassword = TextEditingController();
  var _role = 'salesAgent';
  var _useTemporaryPassword = false;
  var _saving = false;

  @override
  void dispose() {
    _fullName.dispose();
    _email.dispose();
    _phone.dispose();
    _temporaryPassword.dispose();
    _confirmTemporaryPassword.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l.createUser),
      content: SizedBox(
        width: 560,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
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
                AppDropdown<String>(
                  label: l.role,
                  value: _role,
                  enabled: !_saving,
                  items: const ['manager', 'salesAgent', 'marketing', 'viewer'],
                  itemLabelBuilder: (role) => _roleLabel(l, role),
                  onChanged: (value) => setState(() => _role = value),
                ),
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.appBackground(context),
                    border: Border.all(color: AppColors.borderColor(context)),
                    borderRadius: AppRadius.large,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        value: _useTemporaryPassword,
                        onChanged: _saving
                            ? null
                            : (value) {
                                setState(() => _useTemporaryPassword = value);
                              },
                        title: Text(
                          l.setTemporaryPassword,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        subtitle: Text(
                          l.temporaryPasswordHelp,
                          style: TextStyle(
                            color: AppColors.textSecondaryColor(context),
                          ),
                        ),
                      ),
                      if (_useTemporaryPassword) ...[
                        const SizedBox(height: AppSpacing.md),
                        AppTextField(
                          controller: _temporaryPassword,
                          label: l.temporaryPassword,
                          obscureText: true,
                          enabled: !_saving,
                          validator: (value) => AppValidators.password(value, l),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AppTextField(
                          controller: _confirmTemporaryPassword,
                          label: l.confirmTemporaryPassword,
                          obscureText: true,
                          enabled: !_saving,
                          validator: (value) => AppValidators.confirmPassword(
                            value,
                            _temporaryPassword.text,
                            l,
                          ),
                        ),
                      ],
                    ],
                  ),
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
          label: l.createUser,
          isLoading: _saving,
          onPressed: _saving ? null : _submit,
        ),
      ],
    );
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final success = await context.read<CompanyUsersCubit>().addUser(
          companyId: widget.companyId,
          fullName: _fullName.text.trim(),
          email: _email.text.trim(),
          phone: _phone.text.trim(),
          role: _role,
          temporaryPassword: _useTemporaryPassword
              ? _temporaryPassword.text
              : null,
        );
    if (!mounted) return;
    setState(() => _saving = false);
    if (success) {
      final result = context.read<CompanyUsersCubit>().state.createdResult;
      context.read<CompanyUsersCubit>().clearCreatedResult();
      Navigator.of(context).pop(result);
    }
  }
}

Future<void> _showGenerateSetupLinkDialog(
  BuildContext context, {
  required String companyId,
  required CompanyCrmUser user,
}) {
  final cubit = context.read<CompanyUsersCubit>();
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => _GenerateSetupLinkDialog(
      companyId: companyId,
      user: user,
      cubit: cubit,
    ),
  );
}

class _GenerateSetupLinkDialog extends StatefulWidget {
  const _GenerateSetupLinkDialog({
    required this.companyId,
    required this.user,
    required this.cubit,
  });

  final String companyId;
  final CompanyCrmUser user;
  final CompanyUsersCubit cubit;

  @override
  State<_GenerateSetupLinkDialog> createState() =>
      _GenerateSetupLinkDialogState();
}

class _GenerateSetupLinkDialogState extends State<_GenerateSetupLinkDialog> {
  var _loading = true;
  String _link = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final link = await widget.cubit.generateSetupLink(
      companyId: widget.companyId,
      uid: widget.user.uid,
    );
    if (!mounted) return;
    setState(() {
      _link = link ?? '';
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    if (_loading) {
      return AlertDialog(
        title: Text(l.generateSetupLink),
        content: const SizedBox(
          width: 420,
          child: Center(child: MasarLogoLoader(size: 38)),
        ),
      );
    }
    return _SetupLinkDialogContent(
      title: l.generateSetupLink,
      resetLink: _link,
    );
  }
}

Future<void> _showTemporaryPasswordCreatedDialog(BuildContext context) {
  final l = AppLocalizations.of(context)!;
  return showDialog<void>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(l.userCreatedSuccessfully),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              Icons.lock_clock_outlined,
              size: 42,
              color: AppColors.primaryColor(context),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              l.temporaryPasswordCreatedMessage,
              style: TextStyle(color: AppColors.textSecondaryColor(context)),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l.done),
        ),
      ],
    ),
  );
}

Future<void> _showSetupLinkDialog(BuildContext context, String resetLink) {
  final l = AppLocalizations.of(context)!;
  return showDialog<void>(
    context: context,
    builder: (_) => _SetupLinkDialogContent(
      title: l.userCreatedSuccessfully,
      resetLink: resetLink,
    ),
  );
}

class _SetupLinkDialogContent extends StatelessWidget {
  const _SetupLinkDialogContent({
    required this.title,
    required this.resetLink,
  });

  final String title;
  final String resetLink;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cleanLink = resetLink.trim();
    final hasLink = cleanLink.isNotEmpty;
    return AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              hasLink ? l.sendSetupLinkToUser : l.userCreatedNoResetLinkMessage,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondaryColor(context),
                  ),
            ),
            if (hasLink) ...[
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.appBackground(context),
                  border: Border.all(color: AppColors.borderColor(context)),
                  borderRadius: AppRadius.large,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.link_outlined, size: 18),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        _shortSetupLink(cleanLink),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textDirection: TextDirection.ltr,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        if (hasLink) ...[
          TextButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: cleanLink));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l.linkCopied)),
                );
              }
            },
            icon: const Icon(Icons.copy),
            label: Text(l.copySetupLink),
          ),
          TextButton.icon(
            onPressed: () async {
              final opened = await openExternalLink(cleanLink);
              if (!opened && context.mounted) {
                await Clipboard.setData(ClipboardData(text: cleanLink));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l.linkCopied)),
                  );
                }
              }
            },
            icon: const Icon(Icons.open_in_new),
            label: Text(l.openSetupLink),
          ),
        ],
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l.done),
        ),
      ],
    );
  }
}

String _roleLabel(AppLocalizations l, String role) {
  return switch (role) {
    'admin' => l.admin,
    'manager' => l.manager,
    'salesAgent' => l.salesAgent,
    'marketing' => l.marketing,
    'viewer' => l.viewer,
    _ => role,
  };
}

String _shortSetupLink(String link) {
  final uri = Uri.tryParse(link);
  final host = uri?.host ?? '';
  if (host.isEmpty) {
    return 'masarcrm.web.app/.../reset';
  }
  return '$host/.../reset';
}

String _companyUserErrorMessage(AppLocalizations l, String? message) {
  if (message == 'weak-password' || message == 'Password is too weak.') {
    return l.weakPassword;
  }
  return switch (message) {
    'company-user-already-exists' => l.companyUserAlreadyExists,
    'company-user-limit-reached' => l.userLimitReached,
    AppErrorMessages.unableToConnect => l.unableToConnect,
    AppErrorMessages.permissionDenied => l.permissionDenied,
    AppErrorMessages.unauthenticated => l.authErrorProfileMissing,
    AppErrorMessages.notFound => l.noData,
    AppErrorMessages.unknown => l.somethingWentWrong,
    'user-management-disabled' => l.featureNotEnabledForWorkspace,
    null => l.unableToConnect,
    _ => localizeErrorMessage(l, message),
  };
}

String _isolate(String value) {
  final clean = value.trim();
  return clean.isEmpty ? clean : '\u2068$clean\u2069';
}
