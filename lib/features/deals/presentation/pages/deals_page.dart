import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/auth/protected_company_session.dart';
import '../../../../core/archive/archive_filter.dart';
import '../../../../core/constants/role_constants.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/permissions/app_permission.dart';
import '../../../../core/permissions/permission_service.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_pagination_footer.dart';
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
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../dashboard/domain/services/dashboard_truth_rules.dart';
import '../../../users/data/datasources/user_profile_remote_data_source.dart';
import '../../../users/data/repositories/user_profile_repository_impl.dart';
import '../../../users/domain/entities/assignment_user_policy.dart';
import '../../../users/domain/entities/user_profile.dart';
import '../../../users/domain/usecases/watch_active_users_usecase.dart';
import '../../domain/entities/deal.dart';
import '../cubit/deals_cubit.dart';
import '../cubit/deals_state.dart';
import '../widgets/deal_card.dart';
import '../widgets/deal_list_table.dart';
import '../widgets/deals_scope.dart';

class DealsPage extends StatelessWidget {
  const DealsPage({super.key, this.initialFilters = const {}});

  final Map<String, String> initialFilters;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final session = authState.protectedCompanySession;
        final scopeKey = session == null
            ? const ValueKey('deals-scope:loading')
            : ValueKey(session.scopeKey('deals-scope'));

        return DealsScope(
          key: scopeKey,
          child: _DealsView(initialFilters: initialFilters),
        );
      },
    );
  }
}

class _DealsView extends StatefulWidget {
  const _DealsView({required this.initialFilters});

  final Map<String, String> initialFilters;

  @override
  State<_DealsView> createState() => _DealsViewState();
}

class _DealsViewState extends State<_DealsView> {
  final _searchController = TextEditingController();
  String? _watchKey;
  String? _appliedFilterSignature;
  String? _activeUsersCompanyId;
  Stream<List<UserProfile>>? _activeUsersStream;

  @override
  void initState() {
    super.initState();
  }

  Stream<List<UserProfile>> _activeUsersStreamFor(String companyId) {
    if (_activeUsersCompanyId == companyId && _activeUsersStream != null) {
      return _activeUsersStream!;
    }

    _activeUsersCompanyId = companyId;
    _activeUsersStream = _watchActiveUsers(companyId).asBroadcastStream();
    return _activeUsersStream!;
  }

  void _watchScopedDeals({
    required String companyId,
    required UserRole role,
    required String uid,
    String? teamId,
    required ArchiveFilter archiveFilter,
  }) {
    final key = '$companyId:${role.name}:$uid:${teamId ?? ''}:${archiveFilter.name}';
    if (_watchKey == key) {
      return;
    }
    _watchKey = key;
    context.read<DealsCubit>().watchDeals(
      companyId: companyId,
      role: role,
      currentUserId: uid,
      teamId: teamId,
      archiveFilter: archiveFilter,
    );
    _applyInitialFiltersIfNeeded();
  }

  @override
  void didUpdateWidget(covariant _DealsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_filterSignature(oldWidget.initialFilters) !=
        _filterSignature(widget.initialFilters)) {
      _applyInitialFiltersIfNeeded();
    }
  }

  void _applyInitialFiltersIfNeeded() {
    final signature = _filterSignature(widget.initialFilters);
    if (signature.isEmpty || _appliedFilterSignature == signature) {
      return;
    }
    _appliedFilterSignature = signature;
    final filters = widget.initialFilters;
    final cubit = context.read<DealsCubit>();
    cubit.setWorkQueueFilter(
      _enumByName(DealWorkQueueFilter.values, filters['queue']),
    );
    cubit.setStageFilter(_enumByName(DealStage.values, filters['stage']));
    cubit.setClosingDateFilter(
      _enumByName(DealClosingDateFilter.values, filters['closing']),
    );
    if (filters.containsKey('assignedTo')) {
      cubit.setAssignedToFilter(filters['assignedTo'] ?? '');
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
    final authState = context.watch<AuthBloc>().state;
    final session = authState.protectedCompanySession;
    final companyId = session?.companyId ?? '';
    final role = session?.profile.role;
    final uid = session?.uid ?? '';
    final teamId = session?.profile.teamId;
    final archiveFilter = context.select(
      (DealsCubit cubit) => cubit.state.archiveFilter,
    );

    if (authState.isWaitingForProtectedCompanySession) {
      return CrmAppShell(
        selectedItem: CrmNavigationItem.deals,
        title: l.deals,
        child: const AppLoading(),
      );
    }

    if (companyId.isEmpty || role == null || uid.isEmpty) {
      return CrmAppShell(
        selectedItem: CrmNavigationItem.deals,
        title: l.deals,
        child: AppErrorView(message: l.missingCompanyProfile),
      );
    }

    final canView = PermissionService.can(role, AppPermission.viewDeals);
    if (canView) {
      _watchScopedDeals(
        companyId: companyId,
        role: role,
        uid: uid,
        teamId: teamId,
        archiveFilter: archiveFilter,
      );
    }
    final canCreate = PermissionService.can(role, AppPermission.createDeal);
    final canEdit = PermissionService.can(role, AppPermission.editDeal);
    final canArchive = PermissionService.can(role, AppPermission.archiveDeal);
    final canUpdateStage = role != UserRole.viewer && canView;
    final canFilterAssignee = role == UserRole.admin;

    return CrmAppShell(
      selectedItem: CrmNavigationItem.deals,
      title: l.deals,
      child: !canView
          ? AppErrorView(message: l.permissionDenied)
          : StreamBuilder<List<UserProfile>>(
              stream: canFilterAssignee ? _activeUsersStreamFor(companyId) : null,
              builder: (context, usersSnapshot) {
                final users = usersSnapshot.data ?? const <UserProfile>[];
                return BlocListener<DealsCubit, DealsState>(
                  listenWhen: (previous, current) =>
                      previous.status != current.status ||
                      previous.lastAction != current.lastAction ||
                      previous.message != current.message,
                  listener: (context, state) {
                    if (state.status == DealsStatus.saved &&
                        state.lastAction == DealsAction.archiveDeal) {
                      AppFeedback.success(context, l.dealArchivedSuccessfully);
                      context.read<DealsCubit>().clearAction();
                    } else if (state.status == DealsStatus.saved &&
                        state.lastAction == DealsAction.restoreDeal) {
                      AppFeedback.success(context, l.recordRestoredSuccessfully);
                      context.read<DealsCubit>().clearAction();
                    } else if (state.status == DealsStatus.saved &&
                        state.lastAction == DealsAction.updateStage) {
                      AppFeedback.success(
                        context,
                        l.dealStageUpdatedSuccessfully,
                      );
                      context.read<DealsCubit>().clearAction();
                    } else if (state.status == DealsStatus.failure &&
                        state.lastAction != DealsAction.none) {
                      AppFeedback.error(
                        context,
                        localizeDealError(l, state.message),
                      );
                      context.read<DealsCubit>().clearAction();
                    }
                  },
                  child: BlocBuilder<DealsCubit, DealsState>(
                    builder: (context, state) {
                      return LayoutBuilder(
                        builder: (context, constraints) {
                          final isMobile = constraints.maxWidth < 720;

                          final header = Row(
                            children: [
                              Expanded(
                                child: Text(
                                  l.dealsSubtitle,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textSecondaryColor(context),
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              AppButton(
                                label: l.createDeal,
                                icon: Icons.add,
                                onPressed: canCreate
                                    ? () => context.go(RouteNames.dealsCreate)
                                    : null,
                              ),
                            ],
                          );

                          final kpis = _DealsKpiCards(state: state);

                          final filters = _DealsFilters(
                            state: state,
                            searchController: _searchController,
                            canFilterAssignee: canFilterAssignee,
                            showArchiveFilter: canArchive,
                            companyId: companyId,
                            role: role,
                            currentUserId: uid,
                            teamId: teamId,
                            users: users,
                          );

                          final body = _DealsBody(
                            companyId: companyId,
                            uid: uid,
                            teamId: teamId,
                            role: role,
                            state: state,
                            canEdit: canEdit,
                            canArchive: canArchive,
                            canUpdateStage: canUpdateStage,
                            onLoadMore: () => context.read<DealsCubit>().loadMoreDeals(),
                            isArchivedView:
                                state.archiveFilter == ArchiveFilter.archived,
                          );

                          if (isMobile) {
                            return RefreshIndicator(
                              displacement: 28,
                              edgeOffset: 0,
                              notificationPredicate: (notification) =>
                                  notification.depth == 0,
                              onRefresh: () async {
                                if (!context.mounted) {
                                  return;
                                }

                                context.read<DealsCubit>().watchDeals(
                                      companyId: companyId,
                                      role: role,
                                      currentUserId: uid,
                                      teamId: teamId,
                                      archiveFilter: state.archiveFilter,
                                      limit: state.pageLimit,
                                      resetPage: false,
                                    );

                                // Keep current stream content visible while Firestore
                                // re-subscribes. This restores pull-to-refresh without
                                // using the previous custom overscroll wrapper that could
                                // leave mobile/web in a blank layer.
                                await Future<void>.delayed(
                                  const Duration(milliseconds: 420),
                                );
                              },
                              child: SingleChildScrollView(
                                physics: const AlwaysScrollableScrollPhysics(
                                  parent: ClampingScrollPhysics(),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    header,
                                    const SizedBox(height: AppSpacing.sm),
                                    kpis,
                                    const SizedBox(height: AppSpacing.sm),
                                    filters,
                                    const SizedBox(height: AppSpacing.sm),
                                    body,
                                    const SizedBox(height: 96),
                                  ],
                                ),
                              ),
                            );
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              header,
                              const SizedBox(height: AppSpacing.sm),
                              kpis,
                              const SizedBox(height: AppSpacing.sm),
                              filters,
                              const SizedBox(height: AppSpacing.sm),
                              Expanded(child: body),
                            ],
                          );
                        },
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}


class _DealsKpiCards extends StatelessWidget {
  const _DealsKpiCards({required this.state});

  final DealsState state;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cubit = context.read<DealsCubit>();
    final openDeals = state.deals.where(DashboardTruthRules.isOpenDeal).toList();
    final pipelineValue = openDeals.fold<num>(
      0,
      (sum, deal) => sum + deal.expectedValue,
    );
    final expectedCommission = openDeals.fold<num>(
      0,
      (sum, deal) => sum + deal.commission,
    );

    void clearThen(void Function() apply) {
      cubit.clearFilters();
      apply();
    }

    final cards = [
      ModuleKpiCardData(
        label: l.totalDeals,
        value: state.kpiCounts.display(
          'total',
          unavailableLabel: l.notAvailable,
          failureLabel: l.errorOccurred,
        ),
        icon: Icons.handshake_outlined,
        tone: AppStatusTone.info,
        selected: !_hasActiveDealFilter(state),
        onTap: cubit.clearFilters,
      ),
      ModuleKpiCardData(
        label: l.openDeals,
        value: state.kpiCounts.display(
          'open',
          unavailableLabel: l.notAvailable,
          failureLabel: l.errorOccurred,
        ),
        icon: Icons.trending_up_outlined,
        tone: AppStatusTone.warning,
        selected: state.workQueueFilter == DealWorkQueueFilter.open,
        onTap: () => clearThen(
          () => cubit.setWorkQueueFilter(DealWorkQueueFilter.open),
        ),
      ),
      ModuleKpiCardData(
        label: l.salesCommandMetricRisk,
        value: state.kpiCounts.display(
          'atRisk',
          unavailableLabel: l.notAvailable,
          failureLabel: l.errorOccurred,
        ),
        icon: Icons.warning_amber_rounded,
        tone: AppStatusTone.error,
        selected: state.workQueueFilter == DealWorkQueueFilter.atRisk,
        onTap: () => clearThen(
          () => cubit.setWorkQueueFilter(DealWorkQueueFilter.atRisk),
        ),
      ),
      ModuleKpiCardData(
        label: l.loadedExpectedValueTotal,
        value: _formatDealMoney(context, pipelineValue),
        icon: Icons.account_balance_wallet_outlined,
        tone: AppStatusTone.info,
        onTap: () => clearThen(
          () => cubit.setWorkQueueFilter(DealWorkQueueFilter.open),
        ),
      ),
      ModuleKpiCardData(
        label: l.loadedCommissionTotal,
        value: _formatDealMoney(context, expectedCommission),
        icon: Icons.payments_outlined,
        tone: AppStatusTone.success,
        onTap: () => clearThen(
          () => cubit.setWorkQueueFilter(DealWorkQueueFilter.open),
        ),
      ),
      ModuleKpiCardData(
        label: l.wonDealsThisMonth,
        value: state.kpiCounts.display(
          'wonThisMonth',
          unavailableLabel: l.notAvailable,
          failureLabel: l.errorOccurred,
        ),
        icon: Icons.verified_outlined,
        tone: AppStatusTone.success,
        selected: state.workQueueFilter == DealWorkQueueFilter.wonThisMonth,
        onTap: () => clearThen(
          () => cubit.setWorkQueueFilter(DealWorkQueueFilter.wonThisMonth),
        ),
      ),
      ModuleKpiCardData(
        label: l.lostDeals,
        value: state.kpiCounts.display(
          'lost',
          unavailableLabel: l.notAvailable,
          failureLabel: l.errorOccurred,
        ),
        icon: Icons.trending_down_outlined,
        tone: AppStatusTone.error,
        selected: state.stageFilter == DealStage.lost,
        onTap: () => clearThen(() => cubit.setStageFilter(DealStage.lost)),
      ),
    ];

    return ModuleKpiStrip(cards: cards);
  }
}


bool _hasActiveDealFilter(DealsState state) {
  return state.searchQuery.trim().isNotEmpty ||
      state.stageFilter != null ||
      state.assignedToFilter.trim().isNotEmpty ||
      state.closingDateFilter != null ||
      state.workQueueFilter != null;
}

Color _toneColor(BuildContext context, AppStatusTone tone) {
  return switch (tone) {
    AppStatusTone.success => AppColors.successColor(context),
    AppStatusTone.warning => AppColors.warningColor(context),
    AppStatusTone.error => AppColors.errorColor(context),
    AppStatusTone.info => AppColors.primaryColor(context),
    AppStatusTone.neutral => AppColors.textSecondaryColor(context),
  };
}

class _DealsFilters extends StatelessWidget {
  const _DealsFilters({
    required this.state,
    required this.searchController,
    required this.canFilterAssignee,
    required this.showArchiveFilter,
    required this.companyId,
    required this.role,
    required this.currentUserId,
    this.teamId,
    required this.users,
  });

  final DealsState state;
  final TextEditingController searchController;
  final bool canFilterAssignee;
  final bool showArchiveFilter;
  final String companyId;
  final UserRole role;
  final String currentUserId;
  final String? teamId;
  final List<UserProfile> users;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final compact = MediaQuery.sizeOf(context).width < 720;
    final cubit = context.read<DealsCubit>();

    final hasFilters = state.searchQuery.trim().isNotEmpty ||
        state.stageFilter != null ||
        state.closingDateFilter != null ||
        state.workQueueFilter != null ||
        state.assignedToFilter.trim().isNotEmpty;

    void clearFilters() {
      searchController.clear();
      cubit.clearFilters();
    }

    void openFilters() {
      _showDealsFiltersSheet(
        context,
        state: state,
        canFilterAssignee: canFilterAssignee,
        users: users,
        onClear: clearFilters,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: AppSearchField(
                controller: searchController,
                hint: l.searchDeals,
                onChanged: cubit.setSearchQuery,
                onClear: state.searchQuery.trim().isNotEmpty
                    ? () {
                  searchController.clear();
                  cubit.setSearchQuery('');
                }
                    : null,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            AppButton(
              label: l.filters,
              icon: Icons.tune,
              variant: AppButtonVariant.secondary,
              onPressed: openFilters,
            ),
            if (!compact && hasFilters) ...[
              const SizedBox(width: AppSpacing.sm),
              AppButton(
                label: l.clearFilters,
                variant: AppButtonVariant.secondary,
                onPressed: clearFilters,
              ),
            ],
          ],
        ),
        if (!compact && hasFilters) ...[
          const SizedBox(height: AppSpacing.sm),
          _DealsActiveFilterChips(
            state: state,
            canFilterAssignee: canFilterAssignee,
            users: users,
          ),
        ],
        if (showArchiveFilter) ...[
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: _DealsArchiveSegmentedFilter(
              value: state.archiveFilter,
              onChanged: (value) => cubit.setArchiveFilter(
                value,
                companyId: companyId,
                role: role,
                currentUserId: currentUserId,
                teamId: teamId,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _DealsArchiveSegmentedFilter extends StatelessWidget {
  const _DealsArchiveSegmentedFilter({
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

class _DealsActiveFilterChips extends StatelessWidget {
  const _DealsActiveFilterChips({
    required this.state,
    required this.canFilterAssignee,
    required this.users,
  });

  final DealsState state;
  final bool canFilterAssignee;
  final List<UserProfile> users;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    final chips = <Widget>[
      if (state.stageFilter != null)
        _DealFilterChipPill(label: dealStageLabel(l, state.stageFilter!)),
      if (state.closingDateFilter != null)
        _DealFilterChipPill(
          label: _closingFilterLabel(l, state.closingDateFilter!),
        ),
      if (state.workQueueFilter != null)
        _DealFilterChipPill(
          label: _workQueueFilterLabel(l, state.workQueueFilter!),
        ),
      if (canFilterAssignee && state.assignedToFilter.trim().isNotEmpty)
        _DealFilterChipPill(
          label: _assigneeLabel(l, users, state.assignedToFilter),
        ),
    ];

    if (chips.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: chips,
    );
  }
}

class _DealFilterChipPill extends StatelessWidget {
  const _DealFilterChipPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.selectedSurface(context),
        border: Border.all(color: AppColors.borderColor(context)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 5,
        ),
        child: Text(
          label,
          maxLines: 2,
          softWrap: true,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: AppColors.primaryColor(context),
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _DealsFilterControls extends StatelessWidget {
  const _DealsFilterControls({
    required this.state,
    required this.canFilterAssignee,
    required this.users,
    this.onClear,
  });

  final DealsState state;
  final bool canFilterAssignee;
  final List<UserProfile> users;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cubit = context.read<DealsCubit>();
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.md,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 210,
          child: AppDropdown<_DealFilterOption<DealStage>>(
            label: l.dealStage,
            value: _DealFilterOption.fromValue(state.stageFilter),
            items: _filterOptions(DealStage.values),
            itemLabelBuilder: (option) =>
                option.isAll ? l.allStatuses : dealStageLabel(l, option.value!),
            onChanged: (option) => cubit.setStageFilter(option.value),
          ),
        ),
        SizedBox(
          width: 210,
          child: AppDropdown<_DealFilterOption<DealClosingDateFilter>>(
            label: l.closingDate,
            value: _DealFilterOption.fromValue(state.closingDateFilter),
            items: _filterOptions(DealClosingDateFilter.values),
            itemLabelBuilder: (option) => option.isAll
                ? l.allClosingDates
                : _closingFilterLabel(l, option.value!),
            onChanged: (option) => cubit.setClosingDateFilter(option.value),
          ),
        ),
        SizedBox(
          width: 210,
          child: AppDropdown<_DealFilterOption<DealWorkQueueFilter>>(
            label: l.dashboardWorkQueue,
            value: _DealFilterOption.fromValue(state.workQueueFilter),
            items: _filterOptions(DealWorkQueueFilter.values),
            itemLabelBuilder: (option) => option.isAll
                ? l.viewAll
                : _workQueueFilterLabel(l, option.value!),
            onChanged: (option) => cubit.setWorkQueueFilter(option.value),
          ),
        ),
        if (canFilterAssignee)
          SizedBox(
            width: 230,
            child: AppDropdown<_DealAssigneeFilterOption>(
              label: l.assignedAgent,
              value: _DealAssigneeFilterOption.fromValue(
                state.assignedToFilter,
              ),
              items: _assigneeOptions(users),
              itemLabelBuilder: (option) => option.isAll
                  ? l.allAgents
                  : _assigneeLabel(l, users, option.value),
              onChanged: (option) => cubit.setAssignedToFilter(option.value),
            ),
          ),
        if (state.searchQuery.trim().isNotEmpty ||
            state.stageFilter != null ||
            state.closingDateFilter != null ||
            state.workQueueFilter != null ||
            state.assignedToFilter.trim().isNotEmpty)
          AppButton(
            label: l.clearFilters,
            variant: AppButtonVariant.secondary,
            onPressed: onClear ?? cubit.clearFilters,
          ),
      ],
    );
  }
}

class _DealsBody extends StatelessWidget {
  const _DealsBody({
    required this.companyId,
    required this.uid,
    this.teamId,
    required this.role,
    required this.state,
    required this.canEdit,
    required this.canArchive,
    required this.canUpdateStage,
    required this.onLoadMore,
    required this.isArchivedView,
  });

  final String companyId;
  final String uid;
  final String? teamId;
  final UserRole role;
  final DealsState state;
  final bool canEdit;
  final bool canArchive;
  final bool canUpdateStage;
  final VoidCallback onLoadMore;
  final bool isArchivedView;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    if ((state.status == DealsStatus.initial ||
            state.status == DealsStatus.loading) &&
        state.deals.isEmpty) {
      return const AppLoading();
    }

    if (state.status == DealsStatus.failure && state.deals.isEmpty) {
      return AppErrorView(
        message: localizeDealError(l, state.message),
        onRetry: () {
          context.read<DealsCubit>().watchDeals(
            companyId: companyId,
            role: role,
            currentUserId: uid,
            teamId: teamId,
            archiveFilter: state.archiveFilter,
            limit: state.pageLimit,
            resetPage: false,
          );
        },
      );
    }

    if (state.deals.isEmpty) {
      return AppEmptyState(
        title: isArchivedView ? l.noArchivedRecords : l.noDeals,
        message: isArchivedView
            ? l.archivedRecordsHiddenFromActiveLists
            : l.dealsSubtitle,
        icon: isArchivedView ? Icons.archive_outlined : Icons.handshake_outlined,
      );
    }

    if (state.filteredDeals.isEmpty) {
      return _withLoadMoreFooter(
        context,
        AppEmptyState(
          title: l.noData,
          message: l.noDealsMatchFilters,
          icon: Icons.search_off_outlined,
        ),
      );
    }

    final visibleDeals = _visiblePagedDeals(state);

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 720) {
          return _withLoadMoreFooter(
            context,
            Column(
              children: [
                for (var index = 0; index < visibleDeals.length; index++) ...[
                  DealCard(
                  deal: visibleDeals[index],
                  onTap: () => context.go(
                    RouteNames.dealDetails(visibleDeals[index].id),
                  ),
                  onEdit: canEdit
                          && !isArchivedView
                      ? () => context.go(
                    RouteNames.dealEdit(visibleDeals[index].id),
                  )
                      : null,
                  onUpdateStage: canUpdateStage
                          && !isArchivedView
                      ? () => showDealStageDialog(
                    context,
                    companyId: companyId,
                    deal: visibleDeals[index],
                    updatedBy: uid,
                  )
                      : null,
                  onArchive: canArchive
                          && !isArchivedView
                      ? () => showArchiveDealDialog(
                    context,
                    companyId: companyId,
                    deal: visibleDeals[index],
                    updatedBy: uid,
                  )
                      : null,
                  onRestore: canArchive && isArchivedView
                      ? () => showRestoreDealDialog(
                            context,
                            companyId: companyId,
                            deal: visibleDeals[index],
                            updatedBy: uid,
                          )
                      : null,
                  isArchivedView: isArchivedView,
                ),
                if (index != visibleDeals.length - 1)
                  const SizedBox(height: AppSpacing.sm),
                ],
              ],
            ),
            visibleCount: visibleDeals.length,
            totalCountOverride: state.hasLocalFilters
                ? state.filteredDeals.length
                : state.filteredTotalCount,
          );
        }

        return _withLoadMoreFooter(
          context,
          Align(
            alignment: AlignmentDirectional.topStart,
            child: SizedBox(
              height: _tableHeightForRows(visibleDeals.length),
              child: DealListTable(
                deals: visibleDeals,
                onOpen: (deal) => context.go(RouteNames.dealDetails(deal.id)),
                onEdit: canEdit && !isArchivedView
                    ? (deal) => context.go(RouteNames.dealEdit(deal.id))
                    : null,
                onUpdateStage: canUpdateStage && !isArchivedView
                    ? (deal) => showDealStageDialog(
                          context,
                          companyId: companyId,
                          deal: deal,
                          updatedBy: uid,
                        )
                    : null,
                onArchive: canArchive && !isArchivedView
                    ? (deal) => showArchiveDealDialog(
                          context,
                          companyId: companyId,
                          deal: deal,
                          updatedBy: uid,
                        )
                    : null,
                onRestore: canArchive && isArchivedView
                    ? (deal) => showRestoreDealDialog(
                          context,
                          companyId: companyId,
                          deal: deal,
                          updatedBy: uid,
                        )
                    : null,
                isArchivedView: isArchivedView,
              ),
            ),
          ),
          visibleCount: visibleDeals.length,
          totalCountOverride: state.hasLocalFilters
              ? state.filteredDeals.length
              : state.filteredTotalCount,
        );
      },
    );
  }

  Widget _withLoadMoreFooter(
    BuildContext context,
    Widget child, {
    int? visibleCount,
    int? totalCountOverride,
  }) {
    if (!state.canLoadMore) {
      return child;
    }

    final footer = Padding(
      padding: const EdgeInsetsDirectional.only(top: AppSpacing.sm),
      child: Align(
        alignment: AlignmentDirectional.center,
        child: _LoadMoreDealsButton(
          loadedCount: visibleCount ?? state.filteredDeals.length,
          totalCount: totalCountOverride ?? state.filteredTotalCount,
          pageSize: 15,
          isLoading: state.status == DealsStatus.loadingMore,
          onPressed: onLoadMore,
        ),
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.hasBoundedHeight) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: child),
              footer,
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            child,
            footer,
          ],
        );
      },
    );
  }
}


List<Deal> _visiblePagedDeals(DealsState state) {
  final limit = state.pageLimit < 1 ? 15 : state.pageLimit;
  if (state.filteredDeals.length <= limit) {
    return state.filteredDeals;
  }
  return state.filteredDeals.take(limit).toList(growable: false);
}

class _LoadMoreDealsButton extends StatelessWidget {
  const _LoadMoreDealsButton({
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

Future<void> showDealStageDialog(
  BuildContext context, {
  required String companyId,
  required Deal deal,
  required String updatedBy,
}) async {
  final l = AppLocalizations.of(context)!;
  final cubit = context.read<DealsCubit>();
  final lostReasonController = TextEditingController(text: deal.lostReason);
  var selectedStage = deal.stage;
  var isSubmitting = false;

  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(l.updateStage),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppDropdown<DealStage>(
                  label: l.dealStage,
                  value: selectedStage,
                  items: DealStage.values,
                  itemLabelBuilder: (stage) => dealStageLabel(l, stage),
                  enabled: !isSubmitting,
                  onChanged: (stage) =>
                      setDialogState(() => selectedStage = stage),
                ),
                if (selectedStage == DealStage.lost) ...[
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    controller: lostReasonController,
                    enabled: !isSubmitting,
                    maxLines: 2,
                    label: l.lostReason,
                  ),
                ],
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
                label: l.updateStage,
                isLoading: isSubmitting,
                onPressed: () async {
                  if (selectedStage == DealStage.lost &&
                      lostReasonController.text.trim().isEmpty) {
                    AppFeedback.warning(context, l.lostReasonRequired);
                    return;
                  }
                  setDialogState(() => isSubmitting = true);
                  final success = await cubit.updateDealStage(
                    companyId: companyId,
                    dealId: deal.id,
                    stage: selectedStage,
                    lostReason: lostReasonController.text.trim(),
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
  lostReasonController.dispose();
}

Future<void> showArchiveDealDialog(
  BuildContext context, {
  required String companyId,
  required Deal deal,
  required String updatedBy,
}) async {
  final l = AppLocalizations.of(context)!;
  final cubit = context.read<DealsCubit>();
  final reasonController = TextEditingController();
  var isSubmitting = false;

  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(l.archiveDeal),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l.archiveDealConfirmation),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: reasonController,
                  enabled: !isSubmitting,
                  maxLines: 2,
                  label: l.archiveReason,
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
                  final success = await cubit.archiveDeal(
                    companyId: companyId,
                    dealId: deal.id,
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

Future<void> showRestoreDealDialog(
  BuildContext context, {
  required String companyId,
  required Deal deal,
  required String updatedBy,
}) async {
  final l = AppLocalizations.of(context)!;
  final cubit = context.read<DealsCubit>();
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
                  final success = await cubit.restoreDeal(
                    companyId: companyId,
                    dealId: deal.id,
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

Future<void> _showDealsFiltersSheet(
  BuildContext context, {
  required DealsState state,
  required bool canFilterAssignee,
  required List<UserProfile> users,
  required VoidCallback onClear,
}) async {
  final l = AppLocalizations.of(context)!;
  final cubit = context.read<DealsCubit>();

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
                        style: Theme.of(sheetContext)
                            .textTheme
                            .titleMedium
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
                _DealsFilterControls(
                  state: state,
                  canFilterAssignee: canFilterAssignee,
                  users: users,
                  onClear: onClear,
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _DealFilterOption<T> {
  const _DealFilterOption._({required this.value, required this.isAll});

  const _DealFilterOption.all() : this._(value: null, isAll: true);

  const _DealFilterOption.value(T value) : this._(value: value, isAll: false);

  factory _DealFilterOption.fromValue(T? value) {
    return value == null
        ? const _DealFilterOption.all()
        : _DealFilterOption.value(value);
  }

  final T? value;
  final bool isAll;

  @override
  bool operator ==(Object other) {
    return other is _DealFilterOption<T> &&
        other.value == value &&
        other.isAll == isAll;
  }

  @override
  int get hashCode => Object.hash(value, isAll);
}

class _DealAssigneeFilterOption {
  const _DealAssigneeFilterOption._({
    required this.value,
    required this.isAll,
  });

  const _DealAssigneeFilterOption.all() : this._(value: '', isAll: true);

  const _DealAssigneeFilterOption.value(String value)
    : this._(value: value, isAll: false);

  factory _DealAssigneeFilterOption.fromValue(String value) {
    return value.trim().isEmpty
        ? const _DealAssigneeFilterOption.all()
        : _DealAssigneeFilterOption.value(value);
  }

  final String value;
  final bool isAll;

  @override
  bool operator ==(Object other) {
    return other is _DealAssigneeFilterOption &&
        other.value == value &&
        other.isAll == isAll;
  }

  @override
  int get hashCode => Object.hash(value, isAll);
}

List<_DealFilterOption<T>> _filterOptions<T>(List<T> values) {
  return [
    const _DealFilterOption.all(),
    for (final value in values) _DealFilterOption.value(value),
  ];
}

List<_DealAssigneeFilterOption> _assigneeOptions(List<UserProfile> users) {
  final assignableUsers = AssignmentUserPolicy.assignableUsersFor(
    AssignableWorkType.deal,
    users,
  );
  return [
    const _DealAssigneeFilterOption.all(),
    for (final user in assignableUsers)
      _DealAssigneeFilterOption.value(user.uid),
  ];
}

String _formatDealMoney(BuildContext context, num value) {
  final localeName = Localizations.localeOf(context).toLanguageTag();
  if (value.abs() >= 1000000) {
    return NumberFormat.compact(locale: localeName).format(value);
  }
  return NumberFormat.decimalPattern(localeName).format(value);
}

String _assigneeLabel(AppLocalizations l, List<UserProfile> users, String uid) {
  for (final user in users) {
    if (user.uid == uid) {
      return user.fullName.trim().isEmpty ? user.email : user.fullName;
    }
  }
  return l.assignedUserUnavailable;
}

String _closingFilterLabel(AppLocalizations l, DealClosingDateFilter filter) {
  switch (filter) {
    case DealClosingDateFilter.past:
      return l.pastClosing;
    case DealClosingDateFilter.thisWeek:
      return l.thisWeek;
    case DealClosingDateFilter.thisMonth:
      return l.thisMonth;
  }
}

String _workQueueFilterLabel(AppLocalizations l, DealWorkQueueFilter filter) {
  return switch (filter) {
    DealWorkQueueFilter.open => l.openDeals,
    DealWorkQueueFilter.atRisk => l.salesCommandMetricRisk,
    DealWorkQueueFilter.wonThisMonth => l.wonDealsThisMonth,
  };
}

double _tableHeightForRows(int count) {
  final rows = count.clamp(1, 8);
  return 49 + (rows * 58);
}

String _filterSignature(Map<String, String> filters) {
  final entries = filters.entries
      .where((entry) => entry.value.trim().isNotEmpty)
      .toList()
    ..sort((a, b) => a.key.compareTo(b.key));
  return entries.map((entry) => '${entry.key}=${entry.value}').join('&');
}

T? _enumByName<T extends Enum>(List<T> values, String? name) {
  final clean = name?.trim();
  if (clean == null || clean.isEmpty) {
    return null;
  }
  for (final value in values) {
    if (value.name == clean) {
      return value;
    }
  }
  return null;
}

Stream<List<UserProfile>> _watchActiveUsers(String companyId) {
  final repository = UserProfileRepositoryImpl(
    remoteDataSource: FirestoreUserProfileRemoteDataSource(),
  );
  return WatchActiveUsersUseCase(repository)(companyId: companyId);
}

String localizeDealError(AppLocalizations l, String? message) {
  switch (message) {
    case 'lostReasonRequired':
      return l.lostReasonRequired;
    case AppErrorMessages.permissionDenied:
      return l.permissionDenied;
    case AppErrorMessages.unableToConnect:
      return l.unableToConnect;
    case AppErrorMessages.connectionTimeout:
      return l.connectionTimeout;
    default:
      return l.unableToSaveDeal;
  }
}
