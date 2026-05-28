import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/protected_company_session.dart';
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
import '../../../../core/widgets/app_dropdown.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_status_badge.dart';
import '../../../../core/widgets/crm_app_shell.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../users/data/datasources/user_profile_remote_data_source.dart';
import '../../../users/data/repositories/user_profile_repository_impl.dart';
import '../../../users/domain/entities/user_profile.dart';
import '../../../users/domain/usecases/watch_active_users_usecase.dart';
import '../../domain/entities/crm_task.dart';
import '../cubit/tasks_cubit.dart';
import '../cubit/tasks_state.dart';
import '../widgets/tasks_scope.dart';

class TasksPage extends StatelessWidget {
  const TasksPage({super.key, this.initialFilters = const {}});

  final Map<String, String> initialFilters;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return CrmAppShell(
      selectedItem: CrmNavigationItem.tasks,
      title: l.tasks,
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
            return AppErrorView(message: l.missingCompanyProfile);
          }

          final canView = PermissionService.can(role, AppPermission.viewTasks);
          if (!canView) {
            return AppErrorView(message: l.permissionDenied);
          }

          String? assignedTo;
          String? managerId;

          if (role == UserRole.manager) {
            managerId = profile.uid;
          } else if (role == UserRole.salesAgent ||
              role == UserRole.marketing ||
              role == UserRole.viewer) {
            assignedTo = profile.uid;
          }
          final canCreate =
              PermissionService.can(role, AppPermission.createTask) &&
                  (role == UserRole.admin || role == UserRole.manager);
          final canManageTasks =
              role == UserRole.admin ||
              role == UserRole.manager ||
              role == UserRole.salesAgent;
          final scopeKey = ValueKey(session.scopeKey('tasks-scope'));

          return TasksScope(
            key: scopeKey,
            child: _TasksListContent(
              key: ValueKey(session.scopeKey('tasks-content')),
              companyId: companyId,
              assignedTo: assignedTo,
              managerId: managerId,
              canCreate: canCreate,
              canManageTasks: canManageTasks,
              canFilterAssignee: role == UserRole.admin || role == UserRole.manager,
              uid: profile.uid,
              initialFilters: initialFilters,
            ),
          );
        },
      ),
    );
  }
}

class _TasksListContent extends StatefulWidget {
  const _TasksListContent({
    super.key,
    required this.companyId,
    required this.canCreate,
    required this.canManageTasks,
    required this.canFilterAssignee,
    required this.uid,
    required this.initialFilters,
    this.assignedTo,
    this.managerId,
  });

  final String companyId;
  final String? assignedTo;
  final String? managerId;
  final bool canCreate;
  final bool canManageTasks;
  final bool canFilterAssignee;
  final String uid;
  final Map<String, String> initialFilters;

  @override
  State<_TasksListContent> createState() => _TasksListContentState();
}

class _TasksListContentState extends State<_TasksListContent> {
  String? _appliedFilterSignature;

  @override
  void initState() {
    super.initState();
    _watchScopedTasks();
  }

  @override
  void didUpdateWidget(covariant _TasksListContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.companyId != widget.companyId ||
        oldWidget.assignedTo != widget.assignedTo ||
        oldWidget.managerId != widget.managerId) {
      _watchScopedTasks();
    } else if (_filterSignature(oldWidget.initialFilters) !=
        _filterSignature(widget.initialFilters)) {
      _applyInitialFiltersIfNeeded();
    }
  }

  void _watchScopedTasks() {
    context.read<TasksCubit>().watchTasks(
      companyId: widget.companyId,
      assignedTo: widget.assignedTo,
      managerId: widget.managerId,
    );
    _applyInitialFiltersIfNeeded();
  }

  void _applyInitialFiltersIfNeeded() {
    final signature = _filterSignature(widget.initialFilters);
    if (signature.isEmpty || _appliedFilterSignature == signature) {
      return;
    }
    _appliedFilterSignature = signature;
    final filters = widget.initialFilters;
    final cubit = context.read<TasksCubit>();
    cubit.setDueDateFilter(_taskDueDateFilter(filters['due']));
    cubit.setStatusFilter(_enumByName(TaskStatus.values, filters['status']));
    if (filters.containsKey('assignedTo')) {
      cubit.setAssignedToFilter(filters['assignedTo'] ?? '');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return StreamBuilder<List<UserProfile>>(
      stream: _watchActiveUsers(widget.companyId),
      builder: (context, usersSnapshot) {
        final users = usersSnapshot.data ?? const [];

        return BlocConsumer<TasksCubit, TasksState>(
      listenWhen: (previous, current) =>
          previous.status != current.status ||
          previous.lastAction != current.lastAction ||
          previous.message != current.message,
      listener: (context, state) {
        if (state.status == TasksStatus.saved &&
            state.lastAction == TasksAction.markCompleted) {
          AppFeedback.success(
            context,
            l.taskCompletedSuccessfully,
          );
          context.read<TasksCubit>().clearAction();
          return;
        }
        if (state.status == TasksStatus.saved &&
            state.lastAction == TasksAction.cancelTask) {
          AppFeedback.success(
            context,
            l.taskCancelledSuccessfully,
          );
          context.read<TasksCubit>().clearAction();
          return;
        }
        if (state.status == TasksStatus.failure &&
            (state.lastAction == TasksAction.markCompleted ||
                state.lastAction == TasksAction.cancelTask) &&
            (state.message?.isNotEmpty ?? false)) {
          AppFeedback.error(
            context,
            localizeErrorMessage(l, state.message),
          );
          context.read<TasksCubit>().clearAction();
        }
      },
      builder: (context, state) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 720;

            final header = Row(
              children: [
                Expanded(
                  child: Text(
                    l.tasksSubtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondaryColor(context),
                    ),
                  ),
                ),
                if (widget.canCreate) ...[
                  const SizedBox(width: AppSpacing.md),
                  AppButton(
                    label: l.createTask,
                    onPressed: () => context.go(RouteNames.tasksCreate),
                  ),
                ],
              ],
            );

            final filters = _TasksFilters(
              state: state,
              users: users,
              showAssigneeFilter: widget.canFilterAssignee,
            );

            final body = _TasksBody(
              companyId: widget.companyId,
              assignedTo: widget.assignedTo,
              managerId: widget.managerId,
              state: state,
              canManageTasks: widget.canManageTasks,
              uid: widget.uid,
              users: users,
            );

            if (isMobile) {
              return SingleChildScrollView(
                physics: const MasarRefreshPhysics(parent: BouncingScrollPhysics()),
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
        );
      },
    );
  }
}

class _TasksFilters extends StatelessWidget {
  const _TasksFilters({
    required this.state,
    required this.users,
    required this.showAssigneeFilter,
  });

  final TasksState state;
  final List<UserProfile> users;
  final bool showAssigneeFilter;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cubit = context.read<TasksCubit>();
    final hasFilters = state.statusFilter != null ||
        state.priorityFilter != null ||
        state.dueDateFilter != null ||
        state.assignedToFilter.trim().isNotEmpty;

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 720;

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(child: _TasksSearchField(onChanged: cubit.setSearchQuery)),
                  const SizedBox(width: AppSpacing.sm),
                  AppButton(
                    label: l.filters,
                    icon: Icons.tune,
                    variant: AppButtonVariant.secondary,
                    onPressed: () => _showTasksFiltersSheet(
                      context,
                      state: state,
                      users: users,
                      showAssigneeFilter: showAssigneeFilter,
                    ),
                  ),
                ],
              ),
              if (hasFilters) ...[
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    AppButton(
                      label: l.clearFilters,
                      variant: AppButtonVariant.secondary,
                      onPressed: () {
                        cubit.clearFilters();
                      },
                    ),
                  ],
                ),
                _TasksActiveFilterChips(state: state, users: users),
              ],
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: _TasksSearchField(onChanged: cubit.setSearchQuery)),
                const SizedBox(width: AppSpacing.sm),
                AppButton(
                  label: l.filters,
                  icon: Icons.tune,
                  variant: AppButtonVariant.secondary,
                  onPressed: () => _showTasksFiltersSheet(
                    context,
                    state: state,
                    users: users,
                    showAssigneeFilter: showAssigneeFilter,
                  ),
                ),
                if (hasFilters) ...[
                  const SizedBox(width: AppSpacing.sm),
                  AppButton(
                    label: l.clearFilters,
                    icon: Icons.filter_alt_off_outlined,
                    variant: AppButtonVariant.secondary,
                    onPressed: () {
                      cubit.clearFilters();
                    },
                  ),
                ],
              ],
            ),
            if (hasFilters) _TasksActiveFilterChips(state: state, users: users),
          ],
        );
      },
    );
  }
}

class _TasksSearchField extends StatelessWidget {
  const _TasksSearchField({required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return TextField(
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: l.searchTasks,
        prefixIcon: const Icon(Icons.search),
      ),
    );
  }
}

class _TasksActiveFilterChips extends StatelessWidget {
  const _TasksActiveFilterChips({required this.state, required this.users});

  final TasksState state;
  final List<UserProfile> users;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cubit = context.read<TasksCubit>();
    final chips = <Widget>[
      if (state.statusFilter != null)
        _TasksFilterChip(
          label: _statusLabel(l, state.statusFilter!),
          onDeleted: () => cubit.setStatusFilter(null),
        ),
      if (state.priorityFilter != null)
        _TasksFilterChip(
          label: _priorityLabel(l, state.priorityFilter!),
          onDeleted: () => cubit.setPriorityFilter(null),
        ),
      if (state.dueDateFilter != null)
        _TasksFilterChip(
          label: _dueDateFilterLabel(l, state.dueDateFilter!),
          onDeleted: () => cubit.setDueDateFilter(null),
        ),
      if (state.assignedToFilter.trim().isNotEmpty)
        _TasksFilterChip(
          label: _assigneeLabel(l, users, state.assignedToFilter),
          onDeleted: () => cubit.setAssignedToFilter(''),
        ),
    ];

    if (chips.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Wrap(
        spacing: AppSpacing.xs,
        runSpacing: AppSpacing.xs,
        children: chips,
      ),
    );
  }
}

class _TasksFilterChip extends StatelessWidget {
  const _TasksFilterChip({required this.label, required this.onDeleted});

  final String label;
  final VoidCallback onDeleted;

  @override
  Widget build(BuildContext context) {
    final primary = AppColors.primaryColor(context);

    return InputChip(
      label: Text(label),
      onDeleted: onDeleted,
      deleteIcon: const Icon(Icons.close, size: 16),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      backgroundColor: primary.withValues(alpha: 0.08),
      side: BorderSide(color: primary.withValues(alpha: 0.18)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: AppColors.textPrimaryColor(context),
            fontWeight: FontWeight.w700,
          ),
    );
  }
}

class _TasksFilterControls extends StatelessWidget {
  const _TasksFilterControls({
    required this.state,
    required this.users,
    required this.showAssigneeFilter,
  });

  final TasksState state;
  final List<UserProfile> users;
  final bool showAssigneeFilter;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cubit = context.read<TasksCubit>();

    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.md,
      children: [
        SizedBox(
          width: 210,
          child: AppDropdown<_TaskFilterOption<TaskStatus>>(
            label: l.status,
            value: _TaskFilterOption.fromValue(state.statusFilter),
            items: _taskFilterOptions(TaskStatus.values),
            itemLabelBuilder: (option) =>
                option.isAll ? l.allStatuses : _statusLabel(l, option.value!),
            onChanged: (option) => cubit.setStatusFilter(option.value),
          ),
        ),
        SizedBox(
          width: 210,
          child: AppDropdown<_TaskFilterOption<TaskPriority>>(
            label: l.priority,
            value: _TaskFilterOption.fromValue(state.priorityFilter),
            items: _taskFilterOptions(TaskPriority.values),
            itemLabelBuilder: (option) => option.isAll
                ? l.allPriorities
                : _priorityLabel(l, option.value!),
            onChanged: (option) => cubit.setPriorityFilter(option.value),
          ),
        ),
        SizedBox(
          width: 210,
          child: AppDropdown<_TaskFilterOption<TaskDueDateFilter>>(
            label: l.dueDateFilter,
            value: _TaskFilterOption.fromValue(state.dueDateFilter),
            items: _taskFilterOptions(TaskDueDateFilter.values),
            itemLabelBuilder: (option) => option.isAll
                ? l.allDueDates
                : _dueDateFilterLabel(l, option.value!),
            onChanged: (option) => cubit.setDueDateFilter(option.value),
          ),
        ),
        if (showAssigneeFilter)
          SizedBox(
            width: 210,
            child: AppDropdown<_TaskAssigneeFilterOption>(
              label: l.assignedTo,
              value: _TaskAssigneeFilterOption.fromValue(
                state.assignedToFilter,
              ),
              items: _taskAssigneeFilterOptions(users),
              itemLabelBuilder: (option) => option.isAll
                  ? l.allAssignees
                  : _assigneeLabel(l, users, option.value),
              onChanged: (option) =>
                  cubit.setAssignedToFilter(option.value ?? ''),
            ),
          ),
      ],
    );
  }
}

Future<void> _showTasksFiltersSheet(
  BuildContext context, {
  required TasksState state,
  required List<UserProfile> users,
  required bool showAssigneeFilter,
}) async {
  final l = AppLocalizations.of(context)!;
  final cubit = context.read<TasksCubit>();

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
                _TasksFilterControls(
                  state: state,
                  users: users,
                  showAssigneeFilter: showAssigneeFilter,
                ),
                const SizedBox(height: AppSpacing.md),
                AppButton(
                  label: l.clearFilters,
                  variant: AppButtonVariant.secondary,
                  onPressed: () {
                    cubit.clearFilters();
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

class _TasksBody extends StatelessWidget {
  const _TasksBody({
    required this.companyId,
    required this.state,
    required this.canManageTasks,
    required this.uid,
    required this.users,
    this.assignedTo,
    this.managerId,
  });

  final String companyId;
  final String? assignedTo;
  final String? managerId;
  final TasksState state;
  final bool canManageTasks;
  final String uid;
  final List<UserProfile> users;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    if ((state.status == TasksStatus.initial ||
            state.status == TasksStatus.loading) &&
        state.tasks.isEmpty) {
      return const AppLoading();
    }

    if (state.status == TasksStatus.failure && state.tasks.isEmpty) {
      return AppErrorView(
        message: localizeErrorMessage(l, state.message),
        onRetry: () {
          context.read<TasksCubit>().watchTasks(
            companyId: companyId,
            assignedTo: assignedTo,
            managerId: managerId,
          );
        },
      );
    }

    if (state.tasks.isEmpty) {
      return AppEmptyState(
        title: l.noData,
        message: l.noTasksYet,
        icon: Icons.checklist_outlined,
      );
    }

    if (state.filteredTasks.isEmpty) {
      return AppEmptyState(
        title: l.noData,
        message: l.noTasksMatchFilters,
        icon: Icons.search_off_outlined,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 720) {
          return Column(
            children: [
              for (var index = 0; index < state.filteredTasks.length; index++) ...[
                _TaskCard(
                  task: state.filteredTasks[index],
                  companyId: companyId,
                  canManageTasks: canManageTasks,
                  uid: uid,
                  users: users,
                ),
                if (index != state.filteredTasks.length - 1)
                  const SizedBox(height: AppSpacing.sm),
              ],
            ],
          );
        }
        return Align(
          alignment: AlignmentDirectional.topStart,
          child: SizedBox(
            height: _tableHeightForRows(state.filteredTasks.length),
            child: _TasksTable(
              tasks: state.filteredTasks,
              companyId: companyId,
              canManageTasks: canManageTasks,
              uid: uid,
              users: users,
            ),
          ),
        );
      },
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.task,
    required this.companyId,
    required this.canManageTasks,
    required this.uid,
    required this.users,
  });

  final CrmTask task;
  final String companyId;
  final bool canManageTasks;
  final String uid;
  final List<UserProfile> users;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final statusLabel = _statusLabel(l, task.status);
    final dueLabel = _dueStateLabel(l, task);
    final description = task.description.trim();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.cardSurface(context),
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
                  task.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              AppStatusBadge(
                label: _priorityLabel(l, task.priority),
                tone: _priorityTone(task.priority),
              ),
            ],
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondaryColor(context),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              AppStatusBadge(label: statusLabel, tone: _statusTone(task.status)),
              if (dueLabel != statusLabel)
                AppStatusBadge(label: dueLabel, tone: _dueTone(task)),
              _TaskInfoChip(
                icon: Icons.link_outlined,
                label: _relatedRecordDisplayLabel(l, task),
              ),
              _TaskInfoChip(
                icon: Icons.person_outline,
                label: _assigneeDisplayLabel(l, task, users),
              ),
            ],
          ),
          if (canManageTasks) ...[
            const SizedBox(height: AppSpacing.xs),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: _TaskActions(
                task: task,
                companyId: companyId,
                updatedBy: uid,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TaskInfoChip extends StatelessWidget {
  const _TaskInfoChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.inputSurface(context),
        border: Border.all(color: AppColors.borderColor(context)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(8, 5, 9, 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: AppColors.textSecondaryColor(context),
            ),
            const SizedBox(width: 4),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 220),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.textSecondaryColor(context),
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TasksTable extends StatelessWidget {
  const _TasksTable({
    required this.tasks,
    required this.companyId,
    required this.canManageTasks,
    required this.uid,
    required this.users,
  });

  final List<CrmTask> tasks;
  final String companyId;
  final bool canManageTasks;
  final String uid;
  final List<UserProfile> users;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return Container(
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
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: Row(
              children: [
                _TableHeaderText(l.taskTitle, flex: 3),
                _TableHeaderText(l.status, flex: 2),
                _TableHeaderText(l.priority, flex: 2),
                _TableHeaderText(l.relatedRecord, flex: 2),
                _TableHeaderText(l.assignedTo, flex: 2),
                _TableHeaderText(l.dueDate, flex: 2),
                _TableHeaderText(l.actions, flex: canManageTasks ? 2 : 1),
              ],
            ),
          ),
          Divider(height: 1, color: AppColors.borderColor(context)),
          Expanded(
            child: ListView.separated(
              itemCount: tasks.length,
              separatorBuilder: (context, index) =>
                  Divider(height: 1, color: AppColors.borderColor(context)),
              itemBuilder: (context, index) {
                final task = tasks[index];
                return Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(
                    AppSpacing.md,
                    AppSpacing.sm,
                    AppSpacing.md,
                    AppSpacing.sm,
                  ),
                  child: Row(
                    children: [
                      _TableBodyText(task.title, flex: 3),
                      _TaskTableBadge(
                        label: _statusLabel(l, task.status),
                        tone: _statusTone(task.status),
                        flex: 2,
                      ),
                      _TaskTableBadge(
                        label: _priorityLabel(l, task.priority),
                        tone: _priorityTone(task.priority),
                        flex: 2,
                      ),
                      _TableBodyText(
                        _relatedRecordDisplayLabel(l, task),
                        flex: 2,
                      ),
                      _TableBodyText(
                        _assigneeDisplayLabel(l, task, users),
                        flex: 2,
                      ),
                      _TaskTableBadge(
                        label: _dueStateLabel(l, task),
                        tone: _dueTone(task),
                        flex: 2,
                      ),
                      Expanded(
                        flex: canManageTasks ? 2 : 1,
                        child: canManageTasks
                            ? _TaskActions(
                                task: task,
                                companyId: companyId,
                                updatedBy: uid,
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

enum _TaskActionKind { complete, cancel }

class _TaskActions extends StatefulWidget {
  const _TaskActions({
    required this.task,
    required this.companyId,
    required this.updatedBy,
  });

  final CrmTask task;
  final String companyId;
  final String updatedBy;

  @override
  State<_TaskActions> createState() => _TaskActionsState();
}

class _TaskActionsState extends State<_TaskActions> {
  _TaskActionKind? _busyAction;

  Future<void> _markCompleted() async {
    setState(() => _busyAction = _TaskActionKind.complete);
    try {
      await context.read<TasksCubit>().markCompleted(
        companyId: widget.companyId,
        task: widget.task,
        updatedBy: widget.updatedBy,
      );
    } finally {
      if (mounted) {
        setState(() => _busyAction = null);
      }
    }
  }

  Future<void> _cancelTask() async {
    setState(() => _busyAction = _TaskActionKind.cancel);
    try {
      await _confirmCancelTask(
        context,
        companyId: widget.companyId,
        task: widget.task,
        updatedBy: widget.updatedBy,
      );
    } finally {
      if (mounted) {
        setState(() => _busyAction = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final canComplete = widget.task.status != TaskStatus.completed;
    final canCancel = widget.task.status != TaskStatus.cancelled;
    final isBusy = _busyAction != null;

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        IconButton(
          tooltip: l.editTask,
          visualDensity: VisualDensity.compact,
          constraints: const BoxConstraints.tightFor(width: 36, height: 36),
          style: _taskActionButtonStyle(context),
          onPressed: isBusy
              ? null
              : () => context.go(RouteNames.taskEdit(widget.task.id)),
          icon: const Icon(Icons.edit_outlined, size: 18),
        ),
        if (canComplete)
          IconButton(
            tooltip: l.markTaskCompleted,
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints.tightFor(width: 36, height: 36),
            style: _taskActionButtonStyle(context),
            onPressed: isBusy ? null : _markCompleted,
            icon: _busyAction == _TaskActionKind.complete
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check_circle_outline, size: 18),
          ),
        if (canCancel)
          IconButton(
            tooltip: l.cancelTask,
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints.tightFor(width: 36, height: 36),
            style: _taskActionButtonStyle(context),
            onPressed: isBusy ? null : _cancelTask,
            icon: _busyAction == _TaskActionKind.cancel
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.cancel_outlined, size: 18),
          ),
      ],
    );
  }
}

Future<void> _confirmCancelTask(
  BuildContext context, {
  required String companyId,
  required CrmTask task,
  required String updatedBy,
}) async {
  final l = AppLocalizations.of(context)!;
  final cubit = context.read<TasksCubit>();
  var isSubmitting = false;

  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(l.cancelTask),
            content: Text(l.cancelTaskConfirmation),
            actions: [
              TextButton(
                onPressed: isSubmitting
                    ? null
                    : () => Navigator.of(dialogContext).pop(),
                child: Text(l.cancel),
              ),
              AppButton(
                label: l.cancelTask,
                isLoading: isSubmitting,
                onPressed: () async {
                  setDialogState(() => isSubmitting = true);
                  final success = await cubit.cancelTask(
                    companyId: companyId,
                    task: task,
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

ButtonStyle _taskActionButtonStyle(BuildContext context) {
  return IconButton.styleFrom(
    backgroundColor: AppColors.inputSurface(context),
    foregroundColor: AppColors.textPrimaryColor(context),
    side: BorderSide(color: AppColors.borderColor(context)),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  );
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.inputSurface(context),
        border: Border.all(color: AppColors.borderColor(context)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 6,
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelMedium,
        ),
      ),
    );
  }
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
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
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
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}

class _TaskTableBadge extends StatelessWidget {
  const _TaskTableBadge({
    required this.label,
    required this.tone,
    required this.flex,
  });

  final String label;
  final AppStatusTone tone;
  final int flex;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsetsDirectional.only(end: AppSpacing.sm),
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: AppStatusBadge(label: label, tone: tone),
        ),
      ),
    );
  }
}



class _TaskFilterOption<T> {
  const _TaskFilterOption._({required this.value, required this.isAll});

  const _TaskFilterOption.all() : this._(value: null, isAll: true);

  const _TaskFilterOption.value(T value) : this._(value: value, isAll: false);

  factory _TaskFilterOption.fromValue(T? value) {
    return value == null
        ? _TaskFilterOption<T>.all()
        : _TaskFilterOption<T>.value(value);
  }

  final T? value;
  final bool isAll;

  @override
  bool operator ==(Object other) {
    return other is _TaskFilterOption<T> &&
        other.isAll == isAll &&
        other.value == value;
  }

  @override
  int get hashCode => Object.hash(value, isAll);
}

List<_TaskFilterOption<T>> _taskFilterOptions<T>(List<T> values) {
  return [
      _TaskFilterOption<T>.all(),
    for (final value in values) _TaskFilterOption<T>.value(value),
  ];
}

class _TaskAssigneeFilterOption {
  const _TaskAssigneeFilterOption._({
    required this.value,
    required this.isAll,
  });

  const _TaskAssigneeFilterOption.all()
      : this._(value: null, isAll: true);

  const _TaskAssigneeFilterOption.value(String value)
      : this._(value: value, isAll: false);

  factory _TaskAssigneeFilterOption.fromValue(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty
        ? const _TaskAssigneeFilterOption.all()
        : _TaskAssigneeFilterOption.value(trimmed);
  }

  final String? value;
  final bool isAll;

  @override
  bool operator ==(Object other) {
    return other is _TaskAssigneeFilterOption &&
        other.isAll == isAll &&
        other.value == value;
  }

  @override
  int get hashCode => Object.hash(value, isAll);
}

List<_TaskAssigneeFilterOption> _taskAssigneeFilterOptions(
  List<UserProfile> users,
) {
  final activeUsers = users.where((user) => user.isActive).toList()
    ..sort((a, b) => a.fullName.compareTo(b.fullName));
  return [
    const _TaskAssigneeFilterOption.all(),
    for (final user in activeUsers) _TaskAssigneeFilterOption.value(user.uid),
  ];
}

String _assigneeLabel(
  AppLocalizations l,
  List<UserProfile> users,
  String? uid,
) {
  final value = uid?.trim() ?? '';
  if (value.isEmpty) {
    return l.unassigned;
  }
  for (final user in users) {
    if (user.uid == value) {
      return user.fullName.trim().isEmpty ? user.email : user.fullName;
    }
  }
  return l.assignedUserUnavailable;
}

String _statusLabel(AppLocalizations l, TaskStatus status) {
  switch (status) {
    case TaskStatus.pending:
      return l.pending;
    case TaskStatus.inProgress:
      return l.inProgress;
    case TaskStatus.completed:
      return l.completed;
    case TaskStatus.cancelled:
      return l.cancelled;
  }
}

String _priorityLabel(AppLocalizations l, TaskPriority priority) {
  switch (priority) {
    case TaskPriority.low:
      return l.low;
    case TaskPriority.medium:
      return l.medium;
    case TaskPriority.high:
      return l.high;
  }
}

String _dueDateFilterLabel(AppLocalizations l, TaskDueDateFilter filter) {
  switch (filter) {
    case TaskDueDateFilter.overdue:
      return l.overdue;
    case TaskDueDateFilter.today:
      return l.dueToday;
    case TaskDueDateFilter.upcoming:
      return l.upcoming;
  }
}

AppStatusTone _statusTone(TaskStatus status) {
  return switch (status) {
    TaskStatus.completed => AppStatusTone.success,
    TaskStatus.inProgress => AppStatusTone.info,
    TaskStatus.cancelled => AppStatusTone.neutral,
    TaskStatus.pending => AppStatusTone.warning,
  };
}

AppStatusTone _priorityTone(TaskPriority priority) {
  return switch (priority) {
    TaskPriority.high => AppStatusTone.error,
    TaskPriority.medium => AppStatusTone.warning,
    TaskPriority.low => AppStatusTone.neutral,
  };
}

String _relatedTypeLabel(AppLocalizations l, TaskRelatedType type) {
  switch (type) {
    case TaskRelatedType.lead:
      return l.lead;
    case TaskRelatedType.client:
      return l.client;
    case TaskRelatedType.property:
      return l.property;
    case TaskRelatedType.deal:
      return l.deal;
    case TaskRelatedType.general:
      return l.general;
  }
}

String _relatedRecordDisplayLabel(AppLocalizations l, CrmTask task) {
  final typeLabel = _relatedTypeLabel(l, task.relatedType);
  final title = task.relatedTitle.trim();
  if (task.relatedType == TaskRelatedType.general || title.isEmpty) {
    return typeLabel;
  }
  return '$typeLabel: $title';
}

String _dueStateLabel(AppLocalizations l, CrmTask task) {
  if (task.status == TaskStatus.completed) {
    return l.completed;
  }
  if (task.status == TaskStatus.cancelled) {
    return l.cancelled;
  }
  final dueDate = task.dueDate;
  if (dueDate == null) {
    return l.notAvailable;
  }
  final today = _dateOnly(DateTime.now());
  final dueDay = _dateOnly(dueDate);
  if (dueDay.isBefore(today)) {
    return l.overdue;
  }
  if (dueDay == today) {
    return l.dueToday;
  }
  return l.upcoming;
}

AppStatusTone _dueTone(CrmTask task) {
  if (task.status == TaskStatus.completed) {
    return AppStatusTone.success;
  }
  if (task.status == TaskStatus.cancelled) {
    return AppStatusTone.neutral;
  }
  final dueDate = task.dueDate;
  if (dueDate == null) {
    return AppStatusTone.neutral;
  }
  final today = _dateOnly(DateTime.now());
  final dueDay = _dateOnly(dueDate);
  if (dueDay.isBefore(today)) {
    return AppStatusTone.error;
  }
  if (dueDay == today) {
    return AppStatusTone.warning;
  }
  return AppStatusTone.info;
}

String _assigneeDisplayLabel(
  AppLocalizations l,
  CrmTask task,
  List<UserProfile> users,
) {
  if (task.assignedTo.trim().isEmpty) {
    return l.unassigned;
  }
  final snapshotName = task.assignedToName.trim();
  if (snapshotName.isNotEmpty) {
    return snapshotName;
  }
  final snapshotEmail = task.assignedToEmail.trim();
  if (snapshotEmail.isNotEmpty) {
    return snapshotEmail;
  }
  for (final user in users) {
    if (user.uid == task.assignedTo) {
      return user.fullName.trim().isEmpty ? user.email : user.fullName;
    }
  }
  return l.assignedUserUnavailable;
}

DateTime _dateOnly(DateTime value) {
  return DateTime(value.year, value.month, value.day);
}

String _fallback(String value, String fallback) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? fallback : trimmed;
}

double _tableHeightForRows(int rowCount) {
  final ideal = 54.0 * (rowCount + 1) + 2;
  return ideal.clamp(180.0, 520.0).toDouble();
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

TaskDueDateFilter? _taskDueDateFilter(String? value) {
  return switch (value?.trim()) {
    'overdue' => TaskDueDateFilter.overdue,
    'dueToday' || 'today' => TaskDueDateFilter.today,
    'upcoming' => TaskDueDateFilter.upcoming,
    _ => null,
  };
}

Stream<List<UserProfile>> _watchActiveUsers(String companyId) {
  final repository = UserProfileRepositoryImpl(
    remoteDataSource: FirestoreUserProfileRemoteDataSource(),
  );
  return WatchActiveUsersUseCase(repository)(companyId: companyId);
}
