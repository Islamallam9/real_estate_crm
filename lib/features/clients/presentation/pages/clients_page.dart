import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/protected_company_session.dart';
import '../../../../core/archive/archive_filter.dart';
import '../../../../core/constants/role_constants.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/permissions/app_permission.dart';
import '../../../../core/permissions/permission_service.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/masar_refresh_indicator.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_pagination_footer.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_status_badge.dart';
import '../../../../core/widgets/app_scroll_surface.dart';
import '../../../../core/widgets/crm_app_shell.dart';
import '../../../../core/widgets/module_kpi_card.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../users/data/datasources/user_profile_remote_data_source.dart';
import '../../../users/data/repositories/user_profile_repository_impl.dart';
import '../../../users/domain/entities/user_profile.dart';
import '../../../users/domain/usecases/watch_active_users_usecase.dart';
import '../../domain/entities/client.dart';
import '../cubit/clients_cubit.dart';
import '../cubit/clients_state.dart';
import '../widgets/client_assignment_dropdown.dart';
import '../widgets/clients_scope.dart';

class ClientsPage extends StatelessWidget {
  const ClientsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    if (localizations == null) {
      return const SizedBox.shrink();
    }

    return CrmAppShell(
      selectedItem: CrmNavigationItem.clients,
      title: localizations.clients,
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          if (authState.isWaitingForProtectedCompanySession) {
            return const AppLoading();
          }

          final session = authState.protectedCompanySession;
          if (session == null) {
            return const AppLoading();
          }

          final profile = session.profile;
          final companyId = session.companyId;
          final role = profile.role;
          if (companyId.isEmpty) {
            return AppErrorView(message: localizations.missingCompanyProfile);
          }

          final canView = PermissionService.can(role, AppPermission.viewClients);
          if (!canView) {
            return AppErrorView(message: localizations.permissionDenied);
          }
          final canCreate = PermissionService.can(
            role,
            AppPermission.createClient,
          );

          final canEdit = PermissionService.can(
            role,
            AppPermission.editClient,
          );

          final canArchive = PermissionService.can(
            role,
            AppPermission.archiveClient,
          );

          final assignedTo = role == UserRole.salesAgent || role == UserRole.viewer
              ? profile.uid
              : null;
          final managerId = role == UserRole.manager ? profile.uid : null;
          final teamId = role == UserRole.manager ? profile.teamId : null;
          final scopeKey = ValueKey(session.scopeKey('clients-scope'));

          return ClientsScope(
            key: scopeKey,
            child: _ClientsListContent(
              key: ValueKey(session.scopeKey('clients-content')),
              companyId: companyId,
              assignedTo: assignedTo,
              managerId: managerId,
              teamId: teamId,
              canCreate: canCreate,
              canEdit: canEdit,
              canArchive: canArchive,
              canAssign: role == UserRole.admin || role == UserRole.manager,
              showAssigneeFilter: role == UserRole.admin,
              uid: profile.uid,
              isSalesAgentView: role == UserRole.salesAgent,
            ),
          );
        },
      ),
    );
  }
}

class _ClientsListContent extends StatefulWidget {
  const _ClientsListContent({
    super.key,
    required this.companyId,
    required this.canCreate,
    required this.canEdit,
    required this.canArchive,
    required this.canAssign,
    required this.showAssigneeFilter,
    required this.uid,
    required this.isSalesAgentView,
    this.assignedTo,
    this.managerId,
    this.teamId,
  });

  final String companyId;
  final String? assignedTo;
  final String? managerId;
  final String? teamId;
  final bool canCreate;
  final bool canEdit;
  final bool canArchive;
  final bool canAssign;
  final bool showAssigneeFilter;
  final String uid;
  final bool isSalesAgentView;

  @override
  State<_ClientsListContent> createState() => _ClientsListContentState();
}

class _ClientsListContentState extends State<_ClientsListContent> {
  @override
  void initState() {
    super.initState();
    _watchScopedClients();
  }

  @override
  void didUpdateWidget(covariant _ClientsListContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.companyId != widget.companyId ||
        oldWidget.assignedTo != widget.assignedTo ||
        oldWidget.managerId != widget.managerId ||
        oldWidget.teamId != widget.teamId) {
      _watchScopedClients();
    }
  }

  void _watchScopedClients() {
    context.read<ClientsCubit>().watchClients(
      companyId: widget.companyId,
      assignedTo: widget.assignedTo,
      managerId: widget.managerId,
      teamId: widget.teamId,
      archiveFilter: context.read<ClientsCubit>().state.archiveFilter,
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    if (localizations == null) {
      return const SizedBox.shrink();
    }

    return BlocListener<ClientsCubit, ClientsState>(
      listenWhen: (previous, current) =>
          previous.status != current.status ||
          previous.lastAction != current.lastAction ||
          previous.message != current.message,
      listener: (context, state) {
        if (state.status == ClientsStatus.saved &&
            state.lastAction == ClientsAction.assignClient) {
          AppFeedback.success(
            context,
            localizations.clientAssignedSuccessfully,
          );
          context.read<ClientsCubit>().clearAction();
          return;
        }
        if (state.status == ClientsStatus.saved &&
            state.lastAction == ClientsAction.archiveClient) {
          AppFeedback.success(
            context,
            localizations.clientArchivedSuccessfully,
          );
          context.read<ClientsCubit>().clearAction();
          return;
        }
        if (state.status == ClientsStatus.saved &&
            state.lastAction == ClientsAction.restoreClient) {
          AppFeedback.success(context, localizations.recordRestoredSuccessfully);
          context.read<ClientsCubit>().clearAction();
          return;
        }
        if (state.status == ClientsStatus.failure &&
            (state.lastAction == ClientsAction.archiveClient ||
                state.lastAction == ClientsAction.restoreClient ||
                state.lastAction == ClientsAction.assignClient) &&
            (state.message?.isNotEmpty ?? false)) {
          AppFeedback.error(
            context,
            localizeErrorMessage(localizations, state.message),
          );
          context.read<ClientsCubit>().clearAction();
        }
      },
      child: BlocBuilder<ClientsCubit, ClientsState>(
        builder: (context, state) {
          return StreamBuilder<List<UserProfile>>(
            stream: (widget.canAssign || widget.showAssigneeFilter)
                ? _watchActiveUsers(widget.companyId)
                : null,
            builder: (context, usersSnapshot) {
              if (usersSnapshot.hasError) {
                return AppErrorView(
                  message: localizeThrownErrorMessage(
                    localizations,
                    usersSnapshot.error,
                  ),
                );
              }
              final users = usersSnapshot.data ?? const [];

              return LayoutBuilder(
                builder: (context, constraints) {
                  final isMobile = constraints.maxWidth < 720;

                  final header = Row(
                    children: [
                      Expanded(
                        child: Text(
                          localizations.clientsSubtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondaryColor(context),
                          ),
                        ),
                      ),
                      if (widget.canCreate) ...[
                        const SizedBox(width: AppSpacing.md),
                        AppButton(
                          label: localizations.createClient,
                          onPressed: () => context.go(RouteNames.clientsCreate),
                        ),
                      ],
                    ],
                  );

                  final summary = _ClientsSummaryCards(
                    state: state,
                    companyId: widget.companyId,
                    assignedTo: widget.assignedTo,
                    managerId: widget.managerId,
                    teamId: widget.teamId,
                    showArchiveFilter: widget.canArchive,
                  );

                  final filters = _ClientsFilters(
                    state: state,
                    users: users,
                    showAssigneeFilter: widget.showAssigneeFilter,
                    showArchiveFilter: widget.canArchive,
                    companyId: widget.companyId,
                    assignedTo: widget.assignedTo,
                    managerId: widget.managerId,
                    teamId: widget.teamId,
                  );

                  final body = _ClientsBody(
                    companyId: widget.companyId,
                    assignedTo: widget.assignedTo,
                    managerId: widget.managerId,
                    teamId: widget.teamId,
                    state: state,
                    canEdit: widget.canEdit,
                    canArchive: widget.canArchive,
                    canAssign: widget.canAssign,
                    uid: widget.uid,
                    users: users,
                    isSalesAgentView: widget.isSalesAgentView,
                    isArchivedView:
                        state.archiveFilter == ArchiveFilter.archived,
                    onLoadMore: () =>
                        context.read<ClientsCubit>().loadMoreClients(),
                  );

                  if (isMobile) {
                    return SingleChildScrollView(
                      physics: const MasarRefreshPhysics(parent: BouncingScrollPhysics()),
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          header,
                          const SizedBox(height: AppSpacing.sm),
                          summary,
                          const SizedBox(height: AppSpacing.sm),
                          filters,
                          const SizedBox(height: AppSpacing.sm),
                          body,
                          const SizedBox(height: 96),
                        ],
                      ),
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      header,
                      const SizedBox(height: AppSpacing.sm),
                      summary,
                      const SizedBox(height: AppSpacing.sm),
                      filters,
                      const SizedBox(height: AppSpacing.sm),
                      Expanded(child: body),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}


const _clientFilterAssigned = '__assigned__';
const _clientFilterUnassigned = '__unassigned__';

class _ClientsSummaryCards extends StatelessWidget {
  const _ClientsSummaryCards({
    required this.state,
    required this.companyId,
    required this.showArchiveFilter,
    this.assignedTo,
    this.managerId,
    this.teamId,
  });

  final ClientsState state;
  final String companyId;
  final String? assignedTo;
  final String? managerId;
  final String? teamId;
  final bool showArchiveFilter;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cubit = context.read<ClientsCubit>();
    final cards = <ModuleKpiCardData>[
      ModuleKpiCardData(
        label: l.clients,
        value: state.kpiCounts.display(
          'total',
          unavailableLabel: l.notAvailable,
          failureLabel: l.errorOccurred,
        ),
        icon: Icons.people_outline,
        tone: AppStatusTone.info,
        selected: !_hasActiveClientFilter(state),
        onTap: () => cubit.applyKpiFilter(null),
      ),
      ModuleKpiCardData(
        label: l.assignedTo,
        value: state.kpiCounts.display(
          'assigned',
          unavailableLabel: l.notAvailable,
          failureLabel: l.errorOccurred,
        ),
        icon: Icons.assignment_ind_outlined,
        tone: AppStatusTone.success,
        selected: state.assignedToFilter == _clientFilterAssigned,
        onTap: () => cubit.applyKpiFilter(_clientFilterAssigned),
      ),
      ModuleKpiCardData(
        label: l.unassigned,
        value: state.kpiCounts.display(
          'unassigned',
          unavailableLabel: l.notAvailable,
          failureLabel: l.errorOccurred,
        ),
        icon: Icons.person_off_outlined,
        tone: AppStatusTone.warning,
        selected: state.assignedToFilter == _clientFilterUnassigned,
        onTap: () => cubit.applyKpiFilter(_clientFilterUnassigned),
      ),
      if (showArchiveFilter)
        ModuleKpiCardData(
          label: state.archiveFilter == ArchiveFilter.archived
              ? l.active
              : l.archived,
          value: '',
          icon: state.archiveFilter == ArchiveFilter.archived
              ? Icons.inventory_2_outlined
              : Icons.archive_outlined,
          tone: AppStatusTone.neutral,
          onTap: () {
            cubit.setAssignedToFilter(null);
            cubit.setArchiveFilter(
              state.archiveFilter == ArchiveFilter.archived
                  ? ArchiveFilter.active
                  : ArchiveFilter.archived,
              companyId: companyId,
              assignedTo: assignedTo,
              managerId: managerId,
              teamId: teamId,
            );
          },
        ),
    ];

    return ModuleKpiStrip(cards: cards);
  }
}


bool _hasActiveClientFilter(ClientsState state) {
  return state.searchQuery.trim().isNotEmpty ||
      (state.assignedToFilter ?? '').trim().isNotEmpty;
}

class _ClientsFilters extends StatelessWidget {
  const _ClientsFilters({
    required this.state,
    required this.users,
    required this.showAssigneeFilter,
    required this.showArchiveFilter,
    required this.companyId,
    this.assignedTo,
    this.managerId,
    this.teamId,
  });

  final ClientsState state;
  final List<UserProfile> users;
  final bool showAssigneeFilter;
  final bool showArchiveFilter;
  final String companyId;
  final String? assignedTo;
  final String? managerId;
  final String? teamId;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cubit = context.read<ClientsCubit>();
    final hasFilters = state.assignedToFilter != null;

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 720) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _ClientsSearchField(onChanged: cubit.setSearchQuery),
                  ),
                  if (showAssigneeFilter) ...[
                    const SizedBox(width: AppSpacing.sm),
                    AppButton(
                      label: l.filters,
                      icon: Icons.tune,
                      variant: AppButtonVariant.secondary,
                      onPressed: () => _showClientsFiltersSheet(
                        context,
                        state: state,
                        users: users,
                      ),
                    ),
                  ],
                ],
              ),
              if (showArchiveFilter) ...[
                const SizedBox(height: AppSpacing.sm),
                _ArchiveSegmentedFilter(
                  value: state.archiveFilter,
                  onChanged: (value) => cubit.setArchiveFilter(
                    value,
                    companyId: companyId,
                    assignedTo: assignedTo,
                    managerId: managerId,
                    teamId: teamId,
                  ),
                ),
              ],
              _ClientsActiveFilterChips(state: state, users: users),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: _ClientsSearchField(onChanged: cubit.setSearchQuery),
                ),
                if (showAssigneeFilter) ...[
                  const SizedBox(width: AppSpacing.sm),
                  AppButton(
                    label: l.filters,
                    icon: Icons.tune,
                    variant: AppButtonVariant.secondary,
                    onPressed: () => _showClientsFiltersSheet(
                      context,
                      state: state,
                      users: users,
                    ),
                  ),
                ],
                if (hasFilters) ...[
                  const SizedBox(width: AppSpacing.sm),
                  AppButton(
                    label: l.clearFilters,
                    icon: Icons.filter_alt_off_outlined,
                    variant: AppButtonVariant.secondary,
                    onPressed: () => cubit.setAssignedToFilter(null),
                  ),
                ],
              ],
            ),
            if (showArchiveFilter) ...[
              const SizedBox(height: AppSpacing.sm),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: _ArchiveSegmentedFilter(
                  value: state.archiveFilter,
                  onChanged: (value) => cubit.setArchiveFilter(
                    value,
                    companyId: companyId,
                    assignedTo: assignedTo,
                    managerId: managerId,
                    teamId: teamId,
                  ),
                ),
              ),
            ],
            _ClientsActiveFilterChips(state: state, users: users),
          ],
        );
      },
    );
  }
}

class _ArchiveSegmentedFilter extends StatelessWidget {
  const _ArchiveSegmentedFilter({
    required this.value,
    required this.onChanged,
  });

  final ArchiveFilter value;
  final ValueChanged<ArchiveFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return SegmentedButton<ArchiveFilter>(
      showSelectedIcon: false,
      selected: {value == ArchiveFilter.archived ? value : ArchiveFilter.active},
      segments: [
        ButtonSegment(
          value: ArchiveFilter.active,
          icon: const Icon(Icons.inventory_2_outlined, size: 16),
          label: Text(l.active),
        ),
        ButtonSegment(
          value: ArchiveFilter.archived,
          icon: const Icon(Icons.archive_outlined, size: 16),
          label: Text(l.archived),
        ),
      ],
      onSelectionChanged: (selected) => onChanged(selected.first),
      style: const ButtonStyle(
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}

class _ClientsSearchField extends StatelessWidget {
  const _ClientsSearchField({required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return TextField(
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: l.searchClients,
        prefixIcon: const Icon(Icons.search),
      ),
    );
  }
}

class _ClientsActiveFilterChips extends StatelessWidget {
  const _ClientsActiveFilterChips({required this.state, required this.users});

  final ClientsState state;
  final List<UserProfile> users;

  @override
  Widget build(BuildContext context) {
    final assignedTo = state.assignedToFilter;
    if (assignedTo == null) {
      return const SizedBox.shrink();
    }

    final l = AppLocalizations.of(context)!;
    final label = _clientFilterLabel(l, users, assignedTo);

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Wrap(
        spacing: AppSpacing.xs,
        runSpacing: AppSpacing.xs,
        children: [
          _ActiveFilterChip(
            label: label,
            onDeleted: () => context.read<ClientsCubit>().setAssignedToFilter(null),
          ),
        ],
      ),
    );
  }
}


bool _isSpecialClientFilter(String? value) {
  return value == _clientFilterAssigned ||
      value == _clientFilterUnassigned;
}

String _clientFilterLabel(
  AppLocalizations l,
  List<UserProfile> users,
  String assignedTo,
) {
  if (assignedTo == _clientFilterAssigned) {
    return l.assignedTo;
  }
  if (assignedTo == _clientFilterUnassigned) {
    return l.unassigned;
  }
  final user = _userById(users, assignedTo);
  final name = user?.fullName.trim() ?? '';
  final email = user?.email.trim() ?? '';
  if (name.isNotEmpty) {
    return name;
  }
  if (email.isNotEmpty) {
    return email;
  }
  return l.assignee;
}

class _ActiveFilterChip extends StatelessWidget {
  const _ActiveFilterChip({required this.label, required this.onDeleted});

  final String label;
  final VoidCallback onDeleted;

  @override
  Widget build(BuildContext context) {
    return InputChip(
      label: Text(label),
      onDeleted: onDeleted,
      deleteIcon: const Icon(Icons.close, size: 16),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: AppColors.textPrimaryColor(context),
            fontWeight: FontWeight.w700,
          ),
      backgroundColor: AppColors.primaryColor(context).withValues(alpha: 0.08),
      side: BorderSide(
        color: AppColors.primaryColor(context).withValues(alpha: 0.18),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
    );
  }
}

Future<void> _showClientsFiltersSheet(
  BuildContext context, {
  required ClientsState state,
  required List<UserProfile> users,
}) async {
  final l = AppLocalizations.of(context)!;
  final cubit = context.read<ClientsCubit>();

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) {
      return BlocProvider.value(
        value: cubit,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.lg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l.filters,
                        style: Theme.of(sheetContext).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(sheetContext).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                ClientAssignmentDropdown(
                  label: l.assignee,
                  users: users,
                  value: _isSpecialClientFilter(state.assignedToFilter)
                      ? null
                      : state.assignedToFilter,
                  includeAllOption: true,
                  onChanged: cubit.setAssignedToFilter,
                ),
                const SizedBox(height: AppSpacing.md),
                AppButton(
                  label: l.clearFilters,
                  variant: AppButtonVariant.secondary,
                  onPressed: () {
                    cubit.setAssignedToFilter(null);
                    Navigator.of(sheetContext).pop();
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

class _ClientsBody extends StatelessWidget {
  const _ClientsBody({
    required this.companyId,
    required this.state,
    required this.canEdit,
    required this.canArchive,
    required this.canAssign,
    required this.uid,
    required this.users,
    required this.isSalesAgentView,
    required this.isArchivedView,
    required this.onLoadMore,
    this.assignedTo,
    this.managerId,
    this.teamId,
  });

  final String companyId;
  final String? assignedTo;
  final String? managerId;
  final String? teamId;
  final ClientsState state;
  final bool canEdit;
  final bool canArchive;
  final bool canAssign;
  final String uid;
  final List<UserProfile> users;
  final bool isSalesAgentView;
  final bool isArchivedView;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    if ((state.status == ClientsStatus.initial ||
            state.status == ClientsStatus.loading) &&
        state.clients.isEmpty) {
      return const AppLoading();
    }

    if (state.status == ClientsStatus.failure && state.clients.isEmpty) {
      return AppErrorView(
        message: localizeErrorMessage(localizations, state.message),
        onRetry: () {
          context.read<ClientsCubit>().watchClients(
            companyId: companyId,
            assignedTo: assignedTo,
            managerId: managerId,
            teamId: teamId,
            archiveFilter: state.archiveFilter,
          );
        },
      );
    }

    if (state.clients.isEmpty) {
      return AppEmptyState(
        title: isArchivedView
            ? localizations.noArchivedRecords
            : isSalesAgentView
            ? localizations.noAssignedClientsFound
            : localizations.noClientsFound,
        message: isArchivedView
            ? localizations.archivedRecordsHiddenFromActiveLists
            : isSalesAgentView
            ? localizations.noAssignedClientsFound
            : localizations.noClientsFound,
        icon: Icons.person_outline,
      );
    }

    if (state.filteredClients.isEmpty) {
      return AppEmptyState(
        title: localizations.noClientsFound,
        message: localizations.noClientsFound,
        icon: Icons.search_off_outlined,
      );
    }

    final visibleClients = _visiblePagedClients(state);
    final paginationTotalCount = state.hasLocalTableFilters
        ? state.filteredClients.length
        : state.filteredTotalCount;

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 720) {
          return Column(
            children: [
              for (var index = 0; index < visibleClients.length; index++) ...[
                _ClientCard(
                  client: visibleClients[index],
                  canEdit: canEdit,
                  canArchive: canArchive,
                  canAssign: canAssign,
                  users: users,
                  companyId: companyId,
                  updatedBy: uid,
                  onArchive: (client) => _confirmArchive(
                    context,
                    client: client,
                    companyId: companyId,
                    updatedBy: uid,
                  ),
                  onRestore: (client) => _confirmRestore(
                    context,
                    client: client,
                    companyId: companyId,
                    updatedBy: uid,
                  ),
                  isArchivedView: isArchivedView,
                ),
                if (index != visibleClients.length - 1)
                  const SizedBox(height: AppSpacing.sm),
              ],
              if (state.canLoadMore) ...[
                const SizedBox(height: AppSpacing.md),
                _LoadMoreClientsButton(
                  loadedCount: visibleClients.length,
                  totalCount: paginationTotalCount,
                  pageSize: 15,
                  isLoading: state.status == ClientsStatus.loadingMore,
                  onPressed: onLoadMore,
                ),
              ],
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Align(
                alignment: AlignmentDirectional.topStart,
                child: SizedBox(
                  height: _tableHeightForRows(visibleClients.length),
                  child: _ClientsTable(
                    clients: visibleClients,
                    canEdit: canEdit,
                    canArchive: canArchive,
                    canAssign: canAssign,
                    users: users,
                    companyId: companyId,
                    updatedBy: uid,
                    onArchive: (client) => _confirmArchive(
                      context,
                      client: client,
                      companyId: companyId,
                      updatedBy: uid,
                    ),
                    onRestore: (client) => _confirmRestore(
                      context,
                      client: client,
                      companyId: companyId,
                      updatedBy: uid,
                    ),
                    isArchivedView: isArchivedView,
                  ),
                ),
              ),
            ),
            if (state.canLoadMore) ...[
              const SizedBox(height: AppSpacing.sm),
              Align(
                alignment: AlignmentDirectional.center,
                child: _LoadMoreClientsButton(
                  loadedCount: visibleClients.length,
                  totalCount: paginationTotalCount,
                  pageSize: 15,
                  isLoading: state.status == ClientsStatus.loadingMore,
                  onPressed: onLoadMore,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}


List<Client> _visiblePagedClients(ClientsState state) {
  final limit = state.pageLimit < 1 ? 15 : state.pageLimit;
  if (state.filteredClients.length <= limit) {
    return state.filteredClients;
  }
  return state.filteredClients.take(limit).toList(growable: false);
}

class _LoadMoreClientsButton extends StatelessWidget {
  const _LoadMoreClientsButton({
    required this.loadedCount,
    required this.pageSize,
    required this.isLoading,
    required this.onPressed,
    this.totalCount,
  });

  final int loadedCount;
  final int pageSize;
  final bool isLoading;
  final VoidCallback onPressed;
  final int? totalCount;

  @override
  Widget build(BuildContext context) {
    return AppPaginationFooter(
      loadedCount: loadedCount,
      pageSize: pageSize,
      isLoading: isLoading,
      onLoadMore: onPressed,
      totalCount: totalCount,
    );
  }
}

class _ClientCard extends StatelessWidget {
  const _ClientCard({
    required this.client,
    required this.canEdit,
    required this.canArchive,
    required this.canAssign,
    required this.users,
    required this.companyId,
    required this.updatedBy,
    required this.onArchive,
    required this.onRestore,
    required this.isArchivedView,
  });

  final Client client;
  final bool canEdit;
  final bool canArchive;
  final bool canAssign;
  final List<UserProfile> users;
  final String companyId;
  final String updatedBy;
  final ValueChanged<Client> onArchive;
  final ValueChanged<Client> onRestore;
  final bool isArchivedView;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isNarrow = MediaQuery.sizeOf(context).width < 720;

    return Material(
      color: AppColors.cardSurface(context),
      borderRadius: AppRadius.large,
      child: InkWell(
        onTap: () => context.go(RouteNames.clientDetails(client.id)),
        borderRadius: AppRadius.large,
        child: Container(
          padding: EdgeInsets.all(isNarrow ? AppSpacing.sm : AppSpacing.md),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.borderColor(context)),
            borderRadius: AppRadius.large,
            boxShadow: Theme.of(context).brightness == Brightness.dark
                ? null
                : AppShadows.card,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _fallback(client.fullName, l.notAvailable),
                      maxLines: 2,
                      softWrap: true,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (client.isArchived || isArchivedView)
                    _CompactStatusChip(label: l.archived),
                ],
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: 4,
                children: [
                  _ClientInfoPill(icon: Icons.phone_outlined, text: client.phone),
                  _ClientInfoPill(
                    icon: Icons.person_outline,
                    text: _clientAssigneeLabel(l, client),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              _ClientInfoLine(icon: Icons.email_outlined, text: client.email),
              if (client.preferredLocation.trim().isNotEmpty ||
                  client.preferredPropertyType.trim().isNotEmpty) ...[
                const SizedBox(height: 4),
                _ClientInfoLine(
                  icon: Icons.location_on_outlined,
                  text: [
                    client.preferredLocation,
                    client.preferredPropertyType,
                  ].where((value) => value.trim().isNotEmpty).join(' - '),
                ),
              ],
              if (client.budgetMin != null || client.budgetMax != null) ...[
                const SizedBox(height: 4),
                _ClientInfoLine(
                  icon: Icons.payments_outlined,
                  text: _budgetLabel(l, client),
                ),
              ],
              const SizedBox(height: 4),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: Wrap(
                  spacing: 2,
                  runSpacing: 2,
                  children: [
                    if (canEdit && !isArchivedView)
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        tooltip: l.editClient,
                        onPressed: () =>
                            context.go(RouteNames.clientEdit(client.id)),
                        icon: const Icon(Icons.edit_outlined, size: 18),
                      ),
                    if (canAssign && !isArchivedView)
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        tooltip: l.assignClient,
                        onPressed: () => _showAssignClientSheet(
                          context,
                          client: client,
                          companyId: companyId,
                          updatedBy: updatedBy,
                          users: users,
                        ),
                        icon: const Icon(Icons.person_add_alt_outlined, size: 18),
                      ),
                    if (canArchive && !isArchivedView)
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        tooltip: l.archiveClient,
                        onPressed: () => onArchive(client),
                        icon: const Icon(Icons.archive_outlined, size: 18),
                      ),
                    if (canArchive && isArchivedView)
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        tooltip: l.restore,
                        onPressed: () => onRestore(client),
                        icon: const Icon(Icons.unarchive_outlined, size: 18),
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

class _CompactStatusChip extends StatelessWidget {
  const _CompactStatusChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.selectedSurface(context),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.primaryColor(context),
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}

class _ClientInfoPill extends StatelessWidget {
  const _ClientInfoPill({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 170),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.textSecondaryColor(context)),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              _fallback(text, l.notAvailable),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondaryColor(context),
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClientInfoLine extends StatelessWidget {
  const _ClientInfoLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: AppColors.textSecondaryColor(context),
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            _fallback(text, l.notAvailable),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondaryColor(context),
            ),
          ),
        ),
      ],
    );
  }
}

class _ClientsTable extends StatelessWidget {
  const _ClientsTable({
    required this.clients,
    required this.canEdit,
    required this.canArchive,
    required this.canAssign,
    required this.users,
    required this.companyId,
    required this.updatedBy,
    required this.onArchive,
    required this.onRestore,
    required this.isArchivedView,
  });

  final List<Client> clients;
  final bool canEdit;
  final bool canArchive;
  final bool canAssign;
  final List<UserProfile> users;
  final String companyId;
  final String updatedBy;
  final ValueChanged<Client> onArchive;
  final ValueChanged<Client> onRestore;
  final bool isArchivedView;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return AppHorizontalScrollView(
      minWidth: 1160,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
        color: AppColors.cardSurface(context),
        border: Border.all(color: AppColors.borderColor(context)),
        borderRadius: AppRadius.large,
        boxShadow: Theme.of(context).brightness == Brightness.dark
            ? null
            : AppShadows.card,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _ClientsTableHeader(
            localizations: l,
            canEdit: canEdit,
            canArchive: canArchive,
            canAssign: canAssign,
          ),
          Divider(height: 1, color: AppColors.borderColor(context)),
          Expanded(
            child: ListView.separated(
              itemCount: clients.length,
              separatorBuilder: (context, index) =>
                  Divider(height: 1, color: AppColors.borderColor(context)),
              itemBuilder: (context, index) {
                return _ClientsTableRow(
                  client: clients[index],
                  canEdit: canEdit,
                  canArchive: canArchive,
                  canAssign: canAssign,
                  users: users,
                  companyId: companyId,
                  updatedBy: updatedBy,
                  onArchive: onArchive,
                  onRestore: onRestore,
                  isArchivedView: isArchivedView,
                );
              },
            ),
          ),
          ],
        ),
      ),
    );
  }
}

class _ClientsTableHeader extends StatelessWidget {
  const _ClientsTableHeader({
    required this.localizations,
    required this.canEdit,
    required this.canArchive,
    required this.canAssign,
  });

  final AppLocalizations localizations;
  final bool canEdit;
  final bool canArchive;
  final bool canAssign;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          _TableHeaderText(localizations.fullNameUpdated, flex: 3),
          _TableHeaderText(localizations.phone, flex: 2),
          _TableHeaderText(localizations.email, flex: 3),
          _TableHeaderText(localizations.assignedTo, flex: 2),
          _TableHeaderText(localizations.preferredLocation, flex: 3),
          _TableHeaderText(localizations.preferredPropertyType, flex: 3),
          _TableHeaderText(
            localizations.actions,
            flex: 3,
          ),
        ],
      ),
    );
  }
}

class _ClientsTableRow extends StatelessWidget {
  const _ClientsTableRow({
    required this.client,
    required this.canEdit,
    required this.canArchive,
    required this.canAssign,
    required this.users,
    required this.companyId,
    required this.updatedBy,
    required this.onArchive,
    required this.onRestore,
    required this.isArchivedView,
  });

  final Client client;
  final bool canEdit;
  final bool canArchive;
  final bool canAssign;
  final List<UserProfile> users;
  final String companyId;
  final String updatedBy;
  final ValueChanged<Client> onArchive;
  final ValueChanged<Client> onRestore;
  final bool isArchivedView;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.go(RouteNames.clientDetails(client.id)),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.sm,
          ),
          child: Row(
            children: [
              _TableBodyText(_fallback(client.fullName, l.notAvailable), flex: 3),
              _TableBodyText(_fallback(client.phone, l.notAvailable), flex: 2),
              _TableBodyText(_fallback(client.email, l.notAvailable), flex: 3),
              _TableBodyText(_clientAssigneeLabel(l, client), flex: 2),
              _TableBodyText(
                _fallback(client.preferredLocation, l.notAvailable),
                flex: 3,
              ),
              _TableBodyText(
                _fallback(client.preferredPropertyType, l.notAvailable),
                flex: 3,
              ),
              Expanded(
                flex: 3,
                child: Wrap(
                  spacing: 4,
                  children: [
                    IconButton(
                      tooltip: l.open,
                      onPressed: () => context.go(RouteNames.clientDetails(client.id)),
                      icon: const Icon(Icons.open_in_new_rounded, size: 18),
                    ),
                    if (canEdit && !isArchivedView)
                      IconButton(
                        tooltip: l.editClient,
                        onPressed: () => context.go(RouteNames.clientEdit(client.id)),
                        icon: const Icon(Icons.edit_outlined, size: 18),
                      ),
                    if (canAssign && !isArchivedView)
                      IconButton(
                        tooltip: l.assignClient,
                        onPressed: () => _showAssignClientSheet(
                          context,
                          client: client,
                          companyId: companyId,
                          updatedBy: updatedBy,
                          users: users,
                        ),
                        icon: const Icon(Icons.person_add_alt_outlined, size: 18),
                      ),
                    if (canArchive && !isArchivedView)
                      IconButton(
                        tooltip: l.archiveClient,
                        onPressed: () => onArchive(client),
                        icon: const Icon(Icons.archive_outlined, size: 18),
                      ),
                    if (canArchive && isArchivedView)
                      IconButton(
                        tooltip: l.restore,
                        onPressed: () => onRestore(client),
                        icon: const Icon(Icons.unarchive_outlined, size: 18),
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

Future<void> _confirmArchive(
  BuildContext context, {
  required Client client,
  required String companyId,
  required String updatedBy,
}) async {
  final l = AppLocalizations.of(context)!;
  final cubit = context.read<ClientsCubit>();
  final reasonController = TextEditingController();
  var isSubmitting = false;

  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(l.archiveClient),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l.archiveClientConfirmation),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: reasonController,
                  enabled: !isSubmitting,
                  maxLines: 2,
                  decoration: InputDecoration(labelText: l.archiveReason),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting
                    ? null
                    : () => Navigator.of(dialogContext).pop(),
                child: Text(l.cancel),
              ),
              AppButton(
                label: l.archive,
                isLoading: isSubmitting,
                onPressed: () async {
                  setDialogState(() => isSubmitting = true);
                  final success = await cubit.archiveClient(
                    companyId: companyId,
                    clientId: client.id,
                    updatedBy: updatedBy,
                    reason: reasonController.text.trim(),
                  );
                  if (success && dialogContext.mounted) {
                    Navigator.of(dialogContext).pop();
                    return;
                  }
                  if (dialogContext.mounted) {
                    setDialogState(() => isSubmitting = false);
                  }
                },
              ),
            ],
          );
        },
      );
    },
  );
  reasonController.dispose();
}

Future<void> _confirmRestore(
  BuildContext context, {
  required Client client,
  required String companyId,
  required String updatedBy,
}) async {
  final l = AppLocalizations.of(context)!;
  final cubit = context.read<ClientsCubit>();
  var isSubmitting = false;

  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(l.restoreRecord),
            content: Text(l.restoreRecordConfirmation),
            actions: [
              TextButton(
                onPressed: isSubmitting
                    ? null
                    : () => Navigator.of(dialogContext).pop(),
                child: Text(l.cancel),
              ),
              AppButton(
                label: l.restore,
                isLoading: isSubmitting,
                onPressed: () async {
                  setDialogState(() => isSubmitting = true);
                  final success = await cubit.restoreClient(
                    companyId: companyId,
                    clientId: client.id,
                    updatedBy: updatedBy,
                  );
                  if (success && dialogContext.mounted) {
                    Navigator.of(dialogContext).pop();
                    return;
                  }
                  if (dialogContext.mounted) {
                    setDialogState(() => isSubmitting = false);
                  }
                },
              ),
            ],
          );
        },
      );
    },
  );
}

Future<void> _showAssignClientSheet(
  BuildContext context, {
  required Client client,
  required String companyId,
  required String updatedBy,
  required List<UserProfile> users,
}) async {
  final l = AppLocalizations.of(context)!;
  final cubit = context.read<ClientsCubit>();
  var selectedUserId = client.assignedTo;
  var isSubmitting = false;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) {
      return StatefulBuilder(
        builder: (context, setSheetState) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.lg,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l.assignClient,
                          style: Theme.of(sheetContext).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      IconButton(
                        onPressed: isSubmitting
                            ? null
                            : () => Navigator.of(sheetContext).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ClientAssignmentField(
                    users: users,
                    value: selectedUserId,
                    enabled: !isSubmitting,
                    onChanged: (uid) {
                      setSheetState(() => selectedUserId = uid);
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppButton(
                    label: l.assignClient,
                    isLoading: isSubmitting,
                    onPressed: () async {
                      setSheetState(() => isSubmitting = true);
                      final selectedUser = _userById(users, selectedUserId);
                      final success = await cubit.assignClient(
                        companyId: companyId,
                        clientId: client.id,
                        assignedTo: selectedUserId,
                        assignedToName: selectedUser?.fullName ?? '',
                        assignedToEmail: selectedUser?.email ?? '',
                        teamId: selectedUser?.teamId ?? '',
                        teamName: selectedUser?.teamName ?? '',
                        managerId: selectedUser?.managerId ?? '',
                        managerName: selectedUser?.managerName ?? '',
                        updatedBy: updatedBy,
                      );
                      if (success && sheetContext.mounted) {
                        Navigator.of(sheetContext).pop();
                        return;
                      }
                      if (sheetContext.mounted) {
                        setSheetState(() => isSubmitting = false);
                      }
                    },
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

class _TableHeaderText extends StatelessWidget {
  const _TableHeaderText(this.value, {required this.flex});

  final String value;
  final int flex;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsetsDirectional.only(end: AppSpacing.sm),
        child: Text(
          value,
          maxLines: 2,
          softWrap: true,
          textAlign: TextAlign.start,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: AppColors.textSecondaryColor(context),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _TableBodyText extends StatelessWidget {
  const _TableBodyText(this.value, {required this.flex});

  final String value;
  final int flex;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsetsDirectional.only(end: AppSpacing.sm),
        child: Text(
          value,
          maxLines: 2,
          softWrap: true,
          textAlign: TextAlign.start,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}

String _fallback(String value, String fallback) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? fallback : trimmed;
}

String _clientAssigneeLabel(AppLocalizations l, Client client) {
  if (client.assignedTo.trim().isEmpty) {
    return l.unassigned;
  }
  final name = client.assignedToName.trim();
  if (name.isNotEmpty) {
    return name;
  }
  final email = client.assignedToEmail.trim();
  if (email.isNotEmpty) {
    return email;
  }
  return l.assignedUserUnavailable;
}

String _budgetLabel(AppLocalizations l, Client client) {
  final min = client.budgetMin;
  final max = client.budgetMax;
  if (min == null && max == null) {
    return l.notAvailable;
  }
  if (min != null && max != null && max > 0) {
    return '$min - $max';
  }
  if (min != null) {
    return min.toString();
  }
  return max.toString();
}

UserProfile? _userById(List<UserProfile> users, String uid) {
  final value = uid.trim();
  if (value.isEmpty) {
    return null;
  }
  for (final user in users) {
    if (user.uid == value) {
      return user;
    }
  }
  return null;
}

double _tableHeightForRows(int rowCount) {
  final ideal = 54.0 * (rowCount + 1) + 2;
  return ideal.clamp(180.0, 520.0).toDouble();
}

Stream<List<UserProfile>> _watchActiveUsers(String companyId) {
  final repository = UserProfileRepositoryImpl(
    remoteDataSource: FirestoreUserProfileRemoteDataSource(),
  );
  return WatchActiveUsersUseCase(repository)(companyId: companyId);
}
