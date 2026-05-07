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
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/crm_app_shell.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../domain/entities/crm_task.dart';
import '../cubit/tasks_cubit.dart';
import '../cubit/tasks_state.dart';
import '../widgets/tasks_scope.dart';

class TasksPage extends StatelessWidget {
  const TasksPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return CrmAppShell(
      selectedItem: CrmNavigationItem.tasks,
      title: l.tasks,
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          if (authState.status == AuthStatus.initial ||
              authState.status == AuthStatus.loading) {
            return const AppLoading();
          }

          final companyId =
              authState.userProfile?.companyId ?? authState.user?.companyId ?? '';
          if (companyId.isEmpty) {
            return AppErrorView(message: l.missingCompanyProfile);
          }

          final role = authState.userProfile?.role ?? authState.user?.role;
          final canView = role != null
              ? PermissionService.can(role, AppPermission.viewTasks)
              : false;
          if (!canView) {
            return AppErrorView(message: l.permissionDenied);
          }

          if (role == UserRole.salesAgent && (authState.user?.uid.isEmpty ?? true)) {
            return AppErrorView(message: l.permissionDenied);
          }

          final assignedTo = role == UserRole.salesAgent ? authState.user!.uid : null;
          final canCreate =
              PermissionService.can(role, AppPermission.createTask) &&
                  (role == UserRole.admin || role == UserRole.manager);

          return TasksScope(
            child: _TasksListContent(
              companyId: companyId,
              assignedTo: assignedTo,
              canCreate: canCreate,
            ),
          );
        },
      ),
    );
  }
}

class _TasksListContent extends StatefulWidget {
  const _TasksListContent({
    required this.companyId,
    required this.canCreate,
    this.assignedTo,
  });

  final String companyId;
  final String? assignedTo;
  final bool canCreate;

  @override
  State<_TasksListContent> createState() => _TasksListContentState();
}

class _TasksListContentState extends State<_TasksListContent> {
  @override
  void initState() {
    super.initState();
    context.read<TasksCubit>().watchTasks(
      companyId: widget.companyId,
      assignedTo: widget.assignedTo,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return BlocBuilder<TasksCubit, TasksState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l.tasksSubtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondaryColor(context),
              ),
            ),
            if (widget.canCreate) ...[
              const SizedBox(height: AppSpacing.md),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: AppButton(
                  label: l.createTask,
                  onPressed: () => context.go(RouteNames.tasksCreate),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            _TasksFilters(state: state),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: _TasksBody(
                companyId: widget.companyId,
                assignedTo: widget.assignedTo,
                state: state,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TasksFilters extends StatelessWidget {
  const _TasksFilters({required this.state});

  final TasksState state;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cubit = context.read<TasksCubit>();
    final hasFilters = state.statusFilter != null || state.priorityFilter != null;

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
                    ),
                  ),
                ],
              ),
              if (hasFilters) ...[
                const SizedBox(height: AppSpacing.sm),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: AppButton(
                    label: l.clearFilters,
                    variant: AppButtonVariant.secondary,
                    onPressed: () {
                      cubit.setSearchQuery('');
                      cubit.setStatusFilter(null);
                      cubit.setPriorityFilter(null);
                    },
                  ),
                ),
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
                const SizedBox(width: AppSpacing.md),
                AppButton(
                  label: l.clearFilters,
                  icon: Icons.filter_alt_off_outlined,
                  variant: AppButtonVariant.secondary,
                  onPressed: hasFilters
                      ? () {
                          cubit.setSearchQuery('');
                          cubit.setStatusFilter(null);
                          cubit.setPriorityFilter(null);
                        }
                      : null,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _TasksFilterControls(state: state),
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
        labelText: l.searchCrm,
        prefixIcon: const Icon(Icons.search),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

class _TasksFilterControls extends StatelessWidget {
  const _TasksFilterControls({required this.state});

  final TasksState state;

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
      ],
    );
  }
}

Future<void> _showTasksFiltersSheet(
  BuildContext context, {
  required TasksState state,
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
                _TasksFilterControls(state: state),
                const SizedBox(height: AppSpacing.md),
                AppButton(
                  label: l.clearFilters,
                  variant: AppButtonVariant.secondary,
                  onPressed: () {
                    cubit.setSearchQuery('');
                    cubit.setStatusFilter(null);
                    cubit.setPriorityFilter(null);
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
    this.assignedTo,
  });

  final String companyId;
  final String? assignedTo;
  final TasksState state;

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
          return ListView.separated(
            itemCount: state.filteredTasks.length,
            separatorBuilder: (context, index) =>
                const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              return _TaskCard(task: state.filteredTasks[index]);
            },
          );
        }

        return _TasksTable(tasks: state.filteredTasks);
      },
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({required this.task});

  final CrmTask task;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
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
                _Badge(label: _priorityLabel(l, task.priority)),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _fallback(task.description, l.notAvailable),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondaryColor(context),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                _Badge(label: _statusLabel(l, task.status)),
                _Badge(label: _relatedTypeLabel(l, task.relatedType)),
                _Badge(label: _dueDateLabel(context, l, task.dueDate)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TasksTable extends StatelessWidget {
  const _TasksTable({required this.tasks});

  final List<CrmTask> tasks;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.cardSurface(context),
        border: Border.all(color: AppColors.borderColor(context)),
        borderRadius: BorderRadius.circular(8),
      ),
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
                _TableHeaderText(l.relatedType, flex: 2),
                _TableHeaderText(l.dueDate, flex: 2),
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
                      _TableBodyText(_statusLabel(l, task.status), flex: 2),
                      _TableBodyText(_priorityLabel(l, task.priority), flex: 2),
                      _TableBodyText(
                        _relatedTypeLabel(l, task.relatedType),
                        flex: 2,
                      ),
                      _TableBodyText(
                        _dueDateLabel(context, l, task.dueDate),
                        flex: 2,
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

String _dueDateLabel(BuildContext context, AppLocalizations l, DateTime? value) {
  if (value == null) {
    return l.notAvailable;
  }
  return MaterialLocalizations.of(context).formatMediumDate(value);
}

String _fallback(String value, String fallback) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? fallback : trimmed;
}
