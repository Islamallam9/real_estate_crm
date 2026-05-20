import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/role_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
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
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../users/domain/entities/user_profile.dart';
import '../../data/datasources/team_remote_data_source.dart';
import '../../data/repositories/team_repository_impl.dart';
import '../../domain/entities/team.dart';
import '../../domain/errors/team_exception.dart';
import '../../domain/usecases/team_usecases.dart';
import '../cubit/teams_cubit.dart';
import '../cubit/teams_state.dart';

class TeamsPage extends StatelessWidget {
  const TeamsPage({super.key});

  static Widget withDependencies() {
    final remoteDataSource = FirestoreTeamRemoteDataSource();
    final repository = TeamRepositoryImpl(remoteDataSource: remoteDataSource);

    return BlocProvider(
      create: (_) => TeamsCubit(
        watchTeamsUseCase: WatchTeamsUseCase(repository),
        watchTeamUsersUseCase: WatchTeamUsersUseCase(repository),
        createTeamUseCase: CreateTeamUseCase(repository),
        updateTeamUseCase: UpdateTeamUseCase(repository),
        setTeamActiveStatusUseCase: SetTeamActiveStatusUseCase(repository),
        addUserToTeamUseCase: AddUserToTeamUseCase(repository),
        removeUserFromTeamUseCase: RemoveUserFromTeamUseCase(repository),
      ),
      child: const TeamsPage(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return CrmAppShell(
      selectedItem: CrmNavigationItem.teams,
      title: l.teamManagement,
      child: const _TeamsBody(),
    );
  }
}

class _TeamsBody extends StatefulWidget {
  const _TeamsBody();

  @override
  State<_TeamsBody> createState() => _TeamsBodyState();
}

class _TeamsBodyState extends State<_TeamsBody> {
  String? _watchKey;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final authState = context.read<AuthBloc>().state;
    final profile = authState.userProfile;
    final user = authState.user;
    if (profile == null || user == null) {
      return;
    }
    final key = '${profile.companyId}:${user.uid}:${profile.role}';
    if (_watchKey == key) {
      return;
    }
    _watchKey = key;
    context.read<TeamsCubit>().watch(
      companyId: profile.companyId,
      role: profile.role,
      currentUserId: user.uid,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final authState = context.watch<AuthBloc>().state;
    final profile = authState.userProfile;
    final user = authState.user;

    if (profile == null || user == null) {
      return AppErrorView(message: l.missingCompanyProfile);
    }

    final isAdmin = profile.role == UserRole.admin;
    final isManager = profile.role == UserRole.manager;
    if (!isAdmin && !isManager) {
      return AppErrorView(
        title: l.teamManagement,
        message: l.permissionDenied,
      );
    }

    return BlocListener<TeamsCubit, TeamsState>(
      listenWhen: (previous, current) =>
          previous.status != current.status &&
          current.status == TeamsStatus.failure,
      listener: (context, state) {
        AppFeedback.error(context, _localizedTeamError(l, state.message));
      },
      child: BlocBuilder<TeamsCubit, TeamsState>(
        builder: (context, state) {
          if (state.status == TeamsStatus.loading &&
              state.teams.isEmpty &&
              state.users.isEmpty) {
            return const AppLoading();
          }

          return _TeamsContent(
            state: state,
            profile: profile,
            actorUid: user.uid,
            isAdmin: isAdmin,
          );
        },
      ),
    );
  }
}

class _TeamsContent extends StatelessWidget {
  const _TeamsContent({
    required this.state,
    required this.profile,
    required this.actorUid,
    required this.isAdmin,
  });

  final TeamsState state;
  final UserProfile profile;
  final String actorUid;
  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final tabs = isAdmin
        ? <_TeamTab>[
            _TeamTab(label: l.platformOverview, icon: Icons.insights_outlined),
            _TeamTab(label: l.teams, icon: Icons.groups_outlined),
          ]
        : <_TeamTab>[
            _TeamTab(label: l.myTeam, icon: Icons.groups_outlined),
          ];

    final toolbar = _TeamsToolbar(
      title: isAdmin ? l.teamManagement : l.myTeam,
      subtitle: isAdmin ? l.teamManagementSubtitle : l.myTeamSubtitle,
      showSearch: isAdmin,
      onSearchChanged: context.read<TeamsCubit>().updateSearchQuery,
      onSearchClear: () => context.read<TeamsCubit>().updateSearchQuery(''),
      action: isAdmin
          ? AppButton(
              label: l.createTeam,
              icon: Icons.group_add_outlined,
              onPressed: state.status == TeamsStatus.saving
                  ? null
                  : () => _showTeamFormDialog(
                        context,
                        companyId: profile.companyId,
                        managers: state.managers,
                        actorUid: actorUid,
                      ),
            )
          : null,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final useTabs = constraints.maxWidth < 760;
        if (!useTabs) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              toolbar,
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (isAdmin) ...[
                        _OverviewGrid(state: state),
                        const SizedBox(height: AppSpacing.md),
                      ],
                      _TeamsMasterDetail(
                        state: state,
                        isAdmin: isAdmin,
                        actorUid: actorUid,
                      ),
                      if (isAdmin) ...[
                        const SizedBox(height: AppSpacing.md),
                        _UnassignedUsersPanel(state: state),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        }

        return DefaultTabController(
          length: tabs.length,
          child: Column(
            children: [
              toolbar,
              const SizedBox(height: AppSpacing.sm),
              _TeamTabBar(tabs: tabs),
              const SizedBox(height: AppSpacing.sm),
              Expanded(
                child: TabBarView(
                  children: isAdmin
                      ? [
                          _TeamTabScroll(child: _OverviewGrid(state: state)),
                          _TeamTabScroll(
                            child: Column(
                              children: [
                                _TeamsMasterDetail(
                                  state: state,
                                  isAdmin: isAdmin,
                                  actorUid: actorUid,
                                ),
                                const SizedBox(height: AppSpacing.md),
                                _UnassignedUsersPanel(state: state),
                              ],
                            ),
                          ),
                        ]
                      : [
                          _TeamTabScroll(
                            child: _TeamsMasterDetail(
                              state: state,
                              isAdmin: isAdmin,
                              actorUid: actorUid,
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

class _TeamTab {
  const _TeamTab({required this.label, required this.icon});

  final String label;
  final IconData icon;
}

class _TeamTabBar extends StatelessWidget {
  const _TeamTabBar({required this.tabs});

  final List<_TeamTab> tabs;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      padding: const EdgeInsets.all(AppSpacing.xs),
      child: TabBar(
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        labelColor: AppColors.primaryColor(context),
        unselectedLabelColor: AppColors.textSecondaryColor(context),
        indicator: BoxDecoration(
          color: AppColors.selectedSurface(context),
          borderRadius: AppRadius.large,
        ),
        dividerColor: Colors.transparent,
        tabs: [
          for (final tab in tabs)
            Tab(
              height: 40,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(tab.icon, size: 18),
                  const SizedBox(width: AppSpacing.xs),
                  Text(tab.label),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _TeamTabScroll extends StatelessWidget {
  const _TeamTabScroll({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ListView(
      primary: false,
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      children: [child],
    );
  }
}

class _TeamsMasterDetail extends StatelessWidget {
  const _TeamsMasterDetail({
    required this.state,
    required this.isAdmin,
    required this.actorUid,
  });

  final TeamsState state;
  final bool isAdmin;
  final String actorUid;

  @override
  Widget build(BuildContext context) {
    final selectedTeam = state.selectedTeam;
    final list = _TeamsListPanel(state: state, isAdmin: isAdmin);
    final details = selectedTeam == null
        ? _NoTeamPanel(isAdmin: isAdmin)
        : _TeamDetailsPanel(
            team: selectedTeam,
            members: state.membersFor(selectedTeam.id),
            users: state.users,
            managers: state.managers,
            isAdmin: isAdmin,
            isSaving: state.status == TeamsStatus.saving,
            actorUid: actorUid,
          );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 920) {
          return Column(
            children: [
              list,
              const SizedBox(height: AppSpacing.md),
              details,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 360, child: list),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: details),
          ],
        );
      },
    );
  }
}

class _UnassignedUsersPanel extends StatelessWidget {
  const _UnassignedUsersPanel({required this.state});

  final TeamsState state;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final unassigned = state.users.where((user) {
      return _isOperationalTeamMember(user) && user.teamId.trim().isEmpty;
    }).toList();

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l.usersWithoutTeam,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              AppStatusBadge(label: unassigned.length.toString()),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (unassigned.isEmpty)
            AppEmptyState(
              icon: Icons.person_search_outlined,
              title: l.noUnassignedUsers,
              message: l.noUnassignedUsersMessage,
            )
          else
            Column(
              children: [
                for (final user in unassigned) ...[
                  _CompactUserRow(user: user, showTeam: false),
                  if (user != unassigned.last)
                    const SizedBox(height: AppSpacing.xs),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

class _TeamsToolbar extends StatelessWidget {
  const _TeamsToolbar({
    required this.title,
    required this.subtitle,
    required this.showSearch,
    required this.onSearchChanged,
    required this.onSearchClear,
    this.action,
  });

  final String title;
  final String subtitle;
  final bool showSearch;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onSearchClear;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return _Panel(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 760;
          final titleBlock = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondaryColor(context),
                ),
              ),
            ],
          );
          final search = showSearch
              ? ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: compact ? double.infinity : 360,
                  ),
                  child: AppSearchField(
                    hint: l.searchTeams,
                    onChanged: onSearchChanged,
                    onClear: onSearchClear,
                  ),
                )
              : const SizedBox.shrink();

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                titleBlock,
                if (showSearch || action != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  if (showSearch) search,
                  if (showSearch && action != null)
                    const SizedBox(height: AppSpacing.sm),
                  if (action != null) action!,
                ],
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: titleBlock),
              if (showSearch) ...[
                const SizedBox(width: AppSpacing.md),
                search,
              ],
              if (action != null) ...[
                const SizedBox(width: AppSpacing.sm),
                action!,
              ],
            ],
          );
        },
      ),
    );
  }
}

class _OverviewGrid extends StatelessWidget {
  const _OverviewGrid({required this.state});

  final TeamsState state;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final activeTeams = state.teams.where((team) => team.isActive).length;
    final managersWithTeams = state.teams
        .where((team) => team.isActive && team.managerId.isNotEmpty)
        .map((team) => team.managerId)
        .toSet()
        .length;
    final teamMembers = state.users.where(_isOperationalTeamMember).length;
    final usersWithoutTeam = state.users.where((user) {
      return _isOperationalTeamMember(user) && user.teamId.trim().isEmpty;
    }).length;

    final cards = [
      _Metric(l.teams, state.teams.length, Icons.groups_outlined),
      _Metric(l.activeTeams, activeTeams, Icons.verified_outlined),
      _Metric(l.managersWithTeams, managersWithTeams, Icons.manage_accounts),
      _Metric(l.usersWithoutTeam, usersWithoutTeam, Icons.person_off_outlined),
      _Metric(l.teamMembers, teamMembers, Icons.badge_outlined),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1050
            ? 5
            : constraints.maxWidth >= 720
                ? 3
                : 2;
        final gap = AppSpacing.sm;
        final width = (constraints.maxWidth - (columns - 1) * gap) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final card in cards)
              SizedBox(
                width: width,
                child: _Panel(
                  child: Row(
                    children: [
                      Icon(card.icon, color: AppColors.primaryColor(context)),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              card.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            Text(
                              card.value.toString(),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _TeamsListPanel extends StatelessWidget {
  const _TeamsListPanel({required this.state, required this.isAdmin});

  final TeamsState state;
  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final teams = state.filteredTeams;

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            isAdmin ? l.teams : l.myTeam,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (teams.isEmpty)
            AppEmptyState(
              icon: Icons.groups_outlined,
              title: l.noTeamsYet,
              message: isAdmin ? l.noTeamsYetMessage : l.noTeamAssigned,
            )
          else
            Column(
              children: [
                for (final team in teams)
                  _TeamListTile(
                    team: team,
                    selected: state.selectedTeam?.id == team.id,
                    memberCount: state.membersFor(team.id).length,
                    onTap: () => context.read<TeamsCubit>().selectTeam(team.id),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _TeamListTile extends StatelessWidget {
  const _TeamListTile({
    required this.team,
    required this.selected,
    required this.memberCount,
    required this.onTap,
  });

  final Team team;
  final bool selected;
  final int memberCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: selected
            ? AppColors.selectedSurface(context)
            : AppColors.inputSurface(context),
        borderRadius: AppRadius.large,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.large,
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        team.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        team.managerName.trim().isEmpty
                            ? l.notAvailable
                            : team.managerName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondaryColor(context),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    AppStatusBadge(
                      label: team.isActive ? l.active : l.inactive,
                      tone: team.isActive
                          ? AppStatusTone.success
                          : AppStatusTone.neutral,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      l.teamMembersCount(memberCount),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textSecondaryColor(context),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TeamDetailsPanel extends StatelessWidget {
  const _TeamDetailsPanel({
    required this.team,
    required this.members,
    required this.users,
    required this.managers,
    required this.isAdmin,
    required this.isSaving,
    required this.actorUid,
  });

  final Team team;
  final List<UserProfile> members;
  final List<UserProfile> users;
  final List<UserProfile> managers;
  final bool isAdmin;
  final bool isSaving;
  final String actorUid;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      team.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      team.description.trim().isEmpty
                          ? l.teamDetails
                          : team.description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondaryColor(context),
                      ),
                    ),
                  ],
                ),
              ),
              AppStatusBadge(
                label: team.isActive ? l.active : l.inactive,
                tone: team.isActive
                    ? AppStatusTone.success
                    : AppStatusTone.neutral,
              ),
              if (isAdmin)
                _TeamActionsMenu(
                  team: team,
                  users: users,
                  managers: managers,
                  members: members,
                  actorUid: actorUid,
                  isSaving: isSaving,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _InfoChip(label: l.teamManager, value: team.managerName),
              _InfoChip(label: l.email, value: team.managerEmail),
              _InfoChip(label: l.members, value: members.length.toString()),
              _InfoChip(label: l.updatedAt, value: _formatDate(context, team.updatedAt)),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            l.teamMembers,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (members.isEmpty)
            AppEmptyState(
              icon: Icons.people_outline,
              title: l.noTeamMembersYet,
              message: l.noTeamMembersYetMessage,
            )
          else
            Column(
              children: [
                for (final member in members) ...[
                  _CompactUserRow(
                    user: member,
                    trailing: isAdmin
                        ? _MemberActionsMenu(
                            user: member,
                            actorUid: actorUid,
                            isSaving: isSaving,
                          )
                        : null,
                  ),
                  if (member != members.last)
                    const SizedBox(height: AppSpacing.xs),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

class _NoTeamPanel extends StatelessWidget {
  const _NoTeamPanel({required this.isAdmin});

  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return _Panel(
      child: AppEmptyState(
        icon: Icons.groups_outlined,
        title: isAdmin ? l.noTeamsYet : l.noTeamAssigned,
        message: isAdmin ? l.noTeamsYetMessage : l.noTeamAssignedMessage,
      ),
    );
  }
}

enum _TeamAction { edit, members, toggleActive }

class _TeamActionsMenu extends StatelessWidget {
  const _TeamActionsMenu({
    required this.team,
    required this.users,
    required this.managers,
    required this.members,
    required this.actorUid,
    required this.isSaving,
  });

  final Team team;
  final List<UserProfile> users;
  final List<UserProfile> managers;
  final List<UserProfile> members;
  final String actorUid;
  final bool isSaving;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return PopupMenuButton<_TeamAction>(
      tooltip: l.actions,
      enabled: !isSaving,
      icon: isSaving
          ? const SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.more_horiz),
      onSelected: (action) => _handleAction(context, action),
      itemBuilder: (context) => [
        PopupMenuItem<_TeamAction>(
          value: _TeamAction.edit,
          child: _PopupMenuRow(icon: Icons.edit_outlined, label: l.editTeam),
        ),
        PopupMenuItem<_TeamAction>(
          value: _TeamAction.members,
          child: _PopupMenuRow(
            icon: Icons.group_add_outlined,
            label: l.manageMembers,
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<_TeamAction>(
          value: _TeamAction.toggleActive,
          child: _PopupMenuRow(
            icon: team.isActive
                ? Icons.block_outlined
                : Icons.check_circle_outline,
            label: team.isActive ? l.deactivateTeam : l.activateTeam,
            danger: team.isActive,
          ),
        ),
      ],
    );
  }

  Future<void> _handleAction(BuildContext context, _TeamAction action) async {
    switch (action) {
      case _TeamAction.edit:
        return _showTeamFormDialog(
          context,
          companyId: team.companyId,
          managers: managers,
          actorUid: actorUid,
          team: team,
        );
      case _TeamAction.members:
        return _showManageMembersDialog(
          context,
          team: team,
          users: users,
          members: members,
          actorUid: actorUid,
        );
      case _TeamAction.toggleActive:
        final success = await context.read<TeamsCubit>().setTeamActiveStatus(
              team: team,
              isActive: !team.isActive,
              actorUid: actorUid,
            );
        if (context.mounted && success) {
          AppFeedback.success(context, AppLocalizations.of(context)!.teamSavedSuccessfully);
        }
        return;
    }
  }
}

class _MemberActionsMenu extends StatelessWidget {
  const _MemberActionsMenu({
    required this.user,
    required this.actorUid,
    required this.isSaving,
  });

  final UserProfile user;
  final String actorUid;
  final bool isSaving;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return PopupMenuButton<_MemberAction>(
      tooltip: l.actions,
      enabled: !isSaving,
      icon: isSaving
          ? const SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.more_horiz),
      onSelected: (_) => _removeMember(context),
      itemBuilder: (context) => [
        PopupMenuItem<_MemberAction>(
          value: _MemberAction.remove,
          child: _PopupMenuRow(
            icon: Icons.person_remove_outlined,
            label: l.removeMember,
            danger: true,
          ),
        ),
      ],
    );
  }

  Future<void> _removeMember(BuildContext context) async {
    final success = await context.read<TeamsCubit>().removeUserFromTeam(
          user: user,
          actorUid: actorUid,
        );
    if (context.mounted && success) {
      AppFeedback.success(context, AppLocalizations.of(context)!.userRemovedFromTeam);
    }
  }
}

enum _MemberAction { remove }

class _PopupMenuRow extends StatelessWidget {
  const _PopupMenuRow({
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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: color, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class _CompactUserRow extends StatelessWidget {
  const _CompactUserRow({
    required this.user,
    this.trailing,
    this.showTeam = true,
  });

  final UserProfile user;
  final Widget? trailing;
  final bool showTeam;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.inputSurface(context),
        border: Border.all(color: AppColors.borderColor(context)),
        borderRadius: AppRadius.large,
      ),
      child: Row(
        children: [
          _TeamUserAvatar(name: user.fullName, photoUrl: user.photoUrl),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            flex: 2,
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
          if (showTeam && user.teamName.trim().isNotEmpty)
            Expanded(
              child: Text(
                user.teamName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondaryColor(context),
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          AppStatusBadge(label: _roleLabel(l, user.role), tone: AppStatusTone.info),
          const SizedBox(width: AppSpacing.xs),
          AppStatusBadge(
            label: user.isActive ? l.active : l.inactive,
            tone: user.isActive ? AppStatusTone.success : AppStatusTone.neutral,
          ),
          if (trailing != null) ...[
            const SizedBox(width: AppSpacing.xs),
            trailing!,
          ],
        ],
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({required this.user, this.trailing});

  final UserProfile user;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.inputSurface(context),
        border: Border.all(color: AppColors.borderColor(context)),
        borderRadius: AppRadius.large,
      ),
      child: Row(
        children: [
          _TeamUserAvatar(name: user.fullName, photoUrl: user.photoUrl),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.fullName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                Text(
                  _roleLabel(l, user.role),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondaryColor(context),
                  ),
                ),
                if (user.teamName.trim().isNotEmpty)
                  Text(
                    user.teamName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textSecondaryColor(context),
                    ),
                  ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _TeamUserAvatar extends StatelessWidget {
  const _TeamUserAvatar({required this.name, required this.photoUrl});

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
          errorBuilder: (_, __, ___) => fallback,
        ),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.cardSurface(context),
        border: Border.all(color: AppColors.borderColor(context)),
        borderRadius: AppRadius.xLarge,
      ),
      child: child,
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cleanValue = value.trim().isEmpty ? l.notAvailable : value.trim();
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.inputSurface(context),
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
            constraints: const BoxConstraints(maxWidth: 230),
            child: Text(
              cleanValue,
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

class _Metric {
  const _Metric(this.label, this.value, this.icon);

  final String label;
  final int value;
  final IconData icon;
}

Future<void> _showTeamFormDialog(
  BuildContext context, {
  required String companyId,
  required List<UserProfile> managers,
  required String actorUid,
  Team? team,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) => _TeamFormDialog(
      cubit: context.read<TeamsCubit>(),
      companyId: companyId,
      managers: managers,
      actorUid: actorUid,
      team: team,
    ),
  );
}

class _TeamFormDialog extends StatefulWidget {
  const _TeamFormDialog({
    required this.cubit,
    required this.companyId,
    required this.managers,
    required this.actorUid,
    this.team,
  });

  final TeamsCubit cubit;
  final String companyId;
  final List<UserProfile> managers;
  final String actorUid;
  final Team? team;

  @override
  State<_TeamFormDialog> createState() => _TeamFormDialogState();
}

class _TeamFormDialogState extends State<_TeamFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _description;
  UserProfile? _manager;
  late bool _isActive;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    final team = widget.team;
    _name = TextEditingController(text: team?.name ?? '');
    _description = TextEditingController(text: team?.description ?? '');
    for (final manager in widget.managers) {
      if (manager.uid == team?.managerId) {
        _manager = manager;
        break;
      }
    }
    _manager ??= widget.managers.isEmpty ? null : widget.managers.first;
    _isActive = team?.isActive ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final editing = widget.team != null;

    return AlertDialog(
      title: Text(editing ? l.editTeam : l.createTeam),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppTextField(
                  controller: _name,
                  label: l.teamName,
                  enabled: !_saving,
                  validator: (value) => _required(value, l),
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: _description,
                  label: l.teamDescription,
                  enabled: !_saving,
                  maxLines: 3,
                ),
                const SizedBox(height: AppSpacing.md),
                if (widget.managers.isEmpty)
                  AppEmptyState(
                    icon: Icons.manage_accounts_outlined,
                    title: l.noManagersAvailable,
                    message: l.noManagersAvailableMessage,
                  )
                else
                  AppDropdown<UserProfile>(
                    label: l.teamManager,
                    value: _manager ?? widget.managers.first,
                    items: widget.managers,
                    itemLabelBuilder: (manager) =>
                        '${manager.fullName} - ${manager.email}',
                    enabled: !_saving,
                    onChanged: (manager) => setState(() => _manager = manager),
                  ),
                if (editing) ...[
                  const SizedBox(height: AppSpacing.sm),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l.active),
                    value: _isActive,
                    onChanged: _saving
                        ? null
                        : (value) => setState(() => _isActive = value),
                  ),
                ],
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
          onPressed: _saving || widget.managers.isEmpty ? null : _submit,
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _manager == null) {
      return;
    }

    setState(() => _saving = true);
    final team = widget.team;
    final success = team == null
        ? await widget.cubit.createTeam(
            companyId: widget.companyId,
            name: _name.text.trim(),
            description: _description.text.trim(),
            manager: _manager!,
            actorUid: widget.actorUid,
          )
        : await widget.cubit.updateTeam(
            team: team,
            name: _name.text.trim(),
            description: _description.text.trim(),
            manager: _manager!,
            isActive: _isActive,
            actorUid: widget.actorUid,
          );
    if (!mounted) {
      return;
    }
    setState(() => _saving = false);
    if (success) {
      AppFeedback.success(context, AppLocalizations.of(context)!.teamSavedSuccessfully);
      Navigator.of(context).pop();
    }
  }
}

Future<void> _showManageMembersDialog(
  BuildContext context, {
  required Team team,
  required List<UserProfile> users,
  required List<UserProfile> members,
  required String actorUid,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) => _ManageMembersDialog(
      cubit: context.read<TeamsCubit>(),
      team: team,
      users: users,
      members: members,
      actorUid: actorUid,
    ),
  );
}

class _ManageMembersDialog extends StatefulWidget {
  const _ManageMembersDialog({
    required this.cubit,
    required this.team,
    required this.users,
    required this.members,
    required this.actorUid,
  });

  final TeamsCubit cubit;
  final Team team;
  final List<UserProfile> users;
  final List<UserProfile> members;
  final String actorUid;

  @override
  State<_ManageMembersDialog> createState() => _ManageMembersDialogState();
}

class _ManageMembersDialogState extends State<_ManageMembersDialog> {
  UserProfile? _selectedUser;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    final eligible = _eligibleUsers;
    _selectedUser = eligible.isEmpty ? null : eligible.first;
  }

  List<UserProfile> get _eligibleUsers {
    return widget.users.where((user) {
      return _isOperationalTeamMember(user) && user.teamId != widget.team.id;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final eligible = _eligibleUsers;

    if (_selectedUser != null && !eligible.contains(_selectedUser)) {
      _selectedUser = eligible.isEmpty ? null : eligible.first;
    }

    return AlertDialog(
      title: Text(l.manageMembers),
      content: SizedBox(
        width: 620,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.team.name,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: AppSpacing.md),
              if (eligible.isNotEmpty)
                Row(
                  children: [
                    Expanded(
                      child: AppDropdown<UserProfile>(
                        label: l.addMembers,
                        value: _selectedUser ?? eligible.first,
                        items: eligible,
                        itemLabelBuilder: _userOptionLabel,
                        enabled: !_saving,
                        onChanged: (user) =>
                            setState(() => _selectedUser = user),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    AppButton(
                      label: l.addMembers,
                      icon: Icons.person_add_alt_1,
                      isLoading: _saving,
                      onPressed: _saving || _selectedUser == null
                          ? null
                          : _addSelected,
                    ),
                  ],
                )
              else
                AppEmptyState(
                  icon: Icons.person_search_outlined,
                  title: l.noUnassignedUsers,
                  message: l.noUnassignedUsersMessage,
                ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                l.teamMembers,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: AppSpacing.sm),
              if (widget.members.isEmpty)
                AppEmptyState(
                  icon: Icons.people_outline,
                  title: l.noTeamMembersYet,
                  message: l.noTeamMembersYetMessage,
                )
              else
                Column(
                  children: [
                    for (final member in widget.members) ...[
                      _UserCard(
                        user: member,
                        trailing: IconButton(
                          tooltip: l.removeMember,
                          onPressed: _saving
                              ? null
                              : () => _removeMember(member),
                          icon: const Icon(Icons.person_remove_outlined),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                  ],
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: Text(l.close),
        ),
      ],
    );
  }

  Future<void> _addSelected() async {
    final selected = _selectedUser;
    if (selected == null) {
      return;
    }
    setState(() => _saving = true);
    final success = await widget.cubit.addUserToTeam(
      team: widget.team,
      user: selected,
      actorUid: widget.actorUid,
    );
    if (!mounted) {
      return;
    }
    setState(() => _saving = false);
    if (success) {
      AppFeedback.success(context, AppLocalizations.of(context)!.userAddedToTeam);
      Navigator.of(context).pop();
    }
  }

  Future<void> _removeMember(UserProfile member) async {
    setState(() => _saving = true);
    final success = await widget.cubit.removeUserFromTeam(
      user: member,
      actorUid: widget.actorUid,
    );
    if (!mounted) {
      return;
    }
    setState(() => _saving = false);
    if (success) {
      AppFeedback.success(
        context,
        AppLocalizations.of(context)!.userRemovedFromTeam,
      );
      Navigator.of(context).pop();
    }
  }
}

bool _isOperationalTeamMember(UserProfile user) {
  return user.role == UserRole.salesAgent || user.role == UserRole.marketing;
}

String _userOptionLabel(UserProfile user) {
  final team = user.teamName.trim();
  if (team.isEmpty) {
    return '${user.fullName} - ${user.email}';
  }
  return '${user.fullName} - $team';
}

String _initialFor(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return 'U';
  }
  return trimmed.substring(0, 1).toUpperCase();
}

String _roleLabel(AppLocalizations l, UserRole role) {
  return switch (role) {
    UserRole.admin => l.admin,
    UserRole.manager => l.manager,
    UserRole.salesAgent => l.salesAgent,
    UserRole.marketing => l.marketing,
    UserRole.viewer => l.viewer,
  };
}

String _formatDate(BuildContext context, DateTime value) {
  final localeName = Localizations.localeOf(context).toString();
  return DateFormat.yMd(localeName).add_jm().format(value.toLocal());
}

String? _required(String? value, AppLocalizations l) {
  return (value ?? '').trim().isEmpty ? l.requiredField : null;
}

String _localizedTeamError(AppLocalizations l, String? message) {
  return switch (message) {
    TeamErrorMessages.permissionDenied => l.teamPermissionDenied,
    TeamErrorMessages.unauthenticated => l.teamSessionExpired,
    TeamErrorMessages.inactiveUser => l.teamUserInactive,
    TeamErrorMessages.inactiveTeam => l.teamInactive,
    TeamErrorMessages.ineligibleMember => l.teamMemberIneligible,
    TeamErrorMessages.managerUnavailable => l.teamManagerUnavailable,
    TeamErrorMessages.managerAlreadyHasTeam => l.teamManagerAlreadyHasTeam,
    TeamErrorMessages.userNotFound => l.teamUserNotFound,
    TeamErrorMessages.teamNotFound => l.teamNotFound,
    TeamErrorMessages.companyInactive => l.teamCompanyInactive,
    TeamErrorMessages.companyMismatch => l.teamCompanyMismatch,
    TeamErrorMessages.connection => l.teamConnectionInterrupted,
    TeamErrorMessages.changed => l.teamRecordChanged,
    TeamErrorMessages.invalidInput => l.teamInvalidInput,
    _ => l.teamUpdateFailed,
  };
}
