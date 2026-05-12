import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/role_constants.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/crm_app_shell.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../users/data/datasources/user_profile_remote_data_source.dart';
import '../../../users/data/repositories/user_profile_repository_impl.dart';
import '../../../users/domain/entities/user_profile.dart';
import '../../../users/domain/usecases/watch_active_users_usecase.dart';
import '../cubit/tasks_cubit.dart';
import '../cubit/tasks_state.dart';
import '../widgets/task_form.dart';
import '../widgets/tasks_scope.dart';

class EditTaskPage extends StatelessWidget {
  const EditTaskPage({super.key, required this.taskId});

  final String taskId;

  @override
  Widget build(BuildContext context) {
    return TasksScope(child: _EditTaskView(taskId: taskId));
  }
}

class _EditTaskView extends StatefulWidget {
  const _EditTaskView({required this.taskId});

  final String taskId;

  @override
  State<_EditTaskView> createState() => _EditTaskViewState();
}

class _EditTaskViewState extends State<_EditTaskView> {
  bool _isSubmitting = false;
  @override
  void initState() {
    super.initState();
    final companyId = _companyId(context);
    if (companyId.isNotEmpty && widget.taskId.isNotEmpty) {
      context.read<TasksCubit>().watchTask(
        companyId: companyId,
        taskId: widget.taskId,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final authState = context.read<AuthBloc>().state;
    final role = authState.userProfile?.role ?? authState.user?.role;
    final companyId = _companyId(context);
    final uid = authState.user?.uid ?? '';
    final canEditRole =
        role == UserRole.admin ||
        role == UserRole.manager ||
        role == UserRole.salesAgent;

    return CrmAppShell(
      selectedItem: CrmNavigationItem.tasks,
      title: l.editTask,
      child: !canEditRole || companyId.isEmpty || uid.isEmpty
          ? AppErrorView(message: l.permissionDenied)
          : BlocConsumer<TasksCubit, TasksState>(
              listenWhen: (previous, current) =>
                  previous.status != current.status &&
                  (current.status == TasksStatus.saved ||
                      current.status == TasksStatus.failure),
              listener: (context, state) {
                if (state.status == TasksStatus.failure) {
                  setState(() => _isSubmitting = false);
                  AppFeedback.error(
                    context,
                    localizeErrorMessage(l, state.message),
                  );
                  return;
                }
                setState(() => _isSubmitting = false);
                AppFeedback.success(
                  context,
                  l.taskUpdatedSuccessfully,
                );
                context.go(RouteNames.tasks);
              },
              builder: (context, state) {
                if (state.status == TasksStatus.initial ||
                    (state.status == TasksStatus.loading &&
                        state.selectedTask == null)) {
                  return const AppLoading();
                }

                final task = state.selectedTask;
                if (task == null) {
                  return AppErrorView(
                    message: localizeErrorMessage(
                      l,
                      state.message ?? l.taskNotFound,
                    ),
                    onRetry: () {
                      context.read<TasksCubit>().watchTask(
                        companyId: companyId,
                        taskId: widget.taskId,
                      );
                    },
                  );
                }

                if (role == UserRole.salesAgent && task.assignedTo != uid) {
                  return AppErrorView(message: l.permissionDenied);
                }

                final isSaving = _isSubmitting || state.status == TasksStatus.saving;
                final canEditAssignment =
                    role == UserRole.admin || role == UserRole.manager;
                final form = canEditAssignment
                    ? StreamBuilder<List<UserProfile>>(
                        stream: _watchActiveUsers(companyId),
                        builder: (context, usersSnapshot) {
                          if (usersSnapshot.hasError) {
                            return AppErrorView(message: l.unableToConnect);
                          }
                          final users = usersSnapshot.data ?? const [];
                          return TaskForm(
                            companyId: companyId,
                            actorUid: uid,
                            task: task,
                            users: users,
                            canEditAssignment: true,
                            canEditStatus: true,
                            relatedRecordsAssignedTo:
                                role == UserRole.salesAgent ? uid : null,
                            isSaving: isSaving,
                            submitLabel: l.updateTask,
                            onSubmit: (updatedTask) {
                              if (_isSubmitting) {
                                return;
                              }
                              setState(() => _isSubmitting = true);
                              context.read<TasksCubit>().updateTask(
                                companyId: companyId,
                                task: updatedTask,
                              );
                            },
                          );
                        },
                      )
                    : TaskForm(
                        companyId: companyId,
                        actorUid: uid,
                        task: task,
                        canEditStatus: true,
                        relatedRecordsAssignedTo:
                            role == UserRole.salesAgent ? uid : null,
                        isSaving: isSaving,
                        submitLabel: l.updateTask,
                        onSubmit: (updatedTask) {
                          context.read<TasksCubit>().updateTask(
                            companyId: companyId,
                            task: updatedTask,
                          );
                        },
                      );

                return ListView(
                      primary: true,
                      physics: const ClampingScrollPhysics(),
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsetsDirectional.only(
                        bottom: AppSpacing.lg,
                      ),
                      children: [
                        Align(
                          alignment: AlignmentDirectional.topCenter,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 860),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                form,
                                const SizedBox(height: AppSpacing.md),
                                AppButton(
                                  label: l.cancel,
                                  onPressed: isSaving
                                      ? null
                                      : () => context.go(RouteNames.tasks),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                );
              },
            ),
    );
  }
}

String _companyId(BuildContext context) {
  final authState = context.read<AuthBloc>().state;
  return authState.userProfile?.companyId ?? authState.user?.companyId ?? '';
}

Stream<List<UserProfile>> _watchActiveUsers(String companyId) {
  final repository = UserProfileRepositoryImpl(
    remoteDataSource: FirestoreUserProfileRemoteDataSource(),
  );
  return WatchActiveUsersUseCase(repository)(companyId: companyId);
}
