import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/role_constants.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/permissions/app_permission.dart';
import '../../../../core/permissions/permission_service.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_dropdown.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_search_field.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/crm_app_shell.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
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
  const DealsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const DealsScope(child: _DealsView());
  }
}

class _DealsView extends StatefulWidget {
  const _DealsView();

  @override
  State<_DealsView> createState() => _DealsViewState();
}

class _DealsViewState extends State<_DealsView> {
  final _searchController = TextEditingController();
  String? _watchKey;

  @override
  void initState() {
    super.initState();
  }

  void _watchScopedDeals({
    required String companyId,
    required UserRole role,
    required String uid,
  }) {
    final key = '$companyId:${role.name}:$uid';
    if (_watchKey == key) {
      return;
    }
    _watchKey = key;
    context.read<DealsCubit>().watchDeals(
      companyId: companyId,
      role: role,
      currentUserId: uid,
    );
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
    final user = authState.user;
    final userProfile = authState.userProfile;
    final companyId = userProfile?.companyId ?? user?.companyId ?? '';
    final role = userProfile?.role ?? user?.role;

    if (authState.status == AuthStatus.initial ||
        authState.status == AuthStatus.loading) {
      return CrmAppShell(
        selectedItem: CrmNavigationItem.deals,
        title: l.deals,
        child: const AppLoading(),
      );
    }

    if (companyId.isEmpty || role == null || user == null) {
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
        uid: user.uid,
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
              stream: canFilterAssignee ? _watchActiveUsers(companyId) : null,
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

                          final filters = _DealsFilters(
                            state: state,
                            searchController: _searchController,
                            canFilterAssignee: canFilterAssignee,
                            users: users,
                          );

                          final body = _DealsBody(
                            companyId: companyId,
                            uid: user.uid,
                            state: state,
                            canEdit: canEdit,
                            canArchive: canArchive,
                            canUpdateStage: canUpdateStage,
                          );

                          if (isMobile) {
                            return SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  header,
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

class _DealsFilters extends StatelessWidget {
  const _DealsFilters({
    required this.state,
    required this.searchController,
    required this.canFilterAssignee,
    required this.users,
  });

  final DealsState state;
  final TextEditingController searchController;
  final bool canFilterAssignee;
  final List<UserProfile> users;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final compact = MediaQuery.sizeOf(context).width < 720;
    final cubit = context.read<DealsCubit>();

    final hasFilters = state.searchQuery.trim().isNotEmpty ||
        state.stageFilter != null ||
        state.closingDateFilter != null ||
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
      ],
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
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
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
    required this.state,
    required this.canEdit,
    required this.canArchive,
    required this.canUpdateStage,
  });

  final String companyId;
  final String uid;
  final DealsState state;
  final bool canEdit;
  final bool canArchive;
  final bool canUpdateStage;

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
          final authState = context.read<AuthBloc>().state;
          final role = authState.userProfile?.role ?? authState.user?.role;
          if (role == null) {
            return;
          }
          context.read<DealsCubit>().watchDeals(
            companyId: companyId,
            role: role,
            currentUserId: uid,
          );
        },
      );
    }

    if (state.deals.isEmpty) {
      return AppEmptyState(
        title: l.noDeals,
        message: l.dealsSubtitle,
        icon: Icons.handshake_outlined,
      );
    }

    if (state.filteredDeals.isEmpty) {
      return AppEmptyState(
        title: l.noData,
        message: l.noDealsMatchFilters,
        icon: Icons.search_off_outlined,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 720) {
          return Column(
            children: [
              for (var index = 0; index < state.filteredDeals.length; index++) ...[
                DealCard(
                  deal: state.filteredDeals[index],
                  onTap: () => context.go(
                    RouteNames.dealDetails(state.filteredDeals[index].id),
                  ),
                  onEdit: canEdit
                      ? () => context.go(
                    RouteNames.dealEdit(state.filteredDeals[index].id),
                  )
                      : null,
                  onUpdateStage: canUpdateStage
                      ? () => showDealStageDialog(
                    context,
                    companyId: companyId,
                    deal: state.filteredDeals[index],
                    updatedBy: uid,
                  )
                      : null,
                  onArchive: canArchive
                      ? () => showArchiveDealDialog(
                    context,
                    companyId: companyId,
                    deal: state.filteredDeals[index],
                    updatedBy: uid,
                  )
                      : null,
                ),
                if (index != state.filteredDeals.length - 1)
                  const SizedBox(height: AppSpacing.sm),
              ],
            ],
          );
        }

        return Align(
          alignment: AlignmentDirectional.topStart,
          child: SizedBox(
            height: _tableHeightForRows(state.filteredDeals.length),
            child: DealListTable(
              deals: state.filteredDeals,
              onOpen: (deal) => context.go(RouteNames.dealDetails(deal.id)),
              onEdit: canEdit
                  ? (deal) => context.go(RouteNames.dealEdit(deal.id))
                  : null,
              onUpdateStage: canUpdateStage
                  ? (deal) => showDealStageDialog(
                        context,
                        companyId: companyId,
                        deal: deal,
                        updatedBy: uid,
                      )
                  : null,
              onArchive: canArchive
                  ? (deal) => showArchiveDealDialog(
                        context,
                        companyId: companyId,
                        deal: deal,
                        updatedBy: uid,
                      )
                  : null,
            ),
          ),
        );
      },
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
  var isSubmitting = false;

  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(l.archiveDeal),
            content: Text(l.archiveDealConfirmation),
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

double _tableHeightForRows(int count) {
  final rows = count.clamp(1, 8);
  return 49 + (rows * 58);
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
