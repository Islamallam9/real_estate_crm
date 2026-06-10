import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/protected_company_session.dart';
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
import '../../../auth/presentation/bloc/auth_state.dart';
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
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final session = authState.protectedCompanySession;
        return TasksScope(
          key: ValueKey(
            session?.scopeKey('edit-task-scope') ?? 'edit-task-scope:loading',
          ),
          child: _EditTaskView(taskId: taskId),
        );
      },
    );
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
  String? _watchKey;

  void _watchTaskWhenReady(ProtectedCompanySession session) {
    if (widget.taskId.isEmpty) {
      return;
    }
    final key = '${session.scopeKey('edit-task-watch')}:${widget.taskId}';
    if (_watchKey == key) {
      return;
    }
    _watchKey = key;
    context.read<TasksCubit>().watchTask(
      companyId: session.companyId,
      taskId: widget.taskId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final authState = context.watch<AuthBloc>().state;
    final session = authState.protectedCompanySession;

    if (authState.isWaitingForProtectedCompanySession) {
      return CrmAppShell(
        selectedItem: CrmNavigationItem.tasks,
        title: l.editTask,
        child: const AppLoading(),
      );
    }

    final role = session?.profile.role;
    final companyId = session?.companyId ?? '';
    final uid = session?.uid ?? '';
    final canEditRole =
        role == UserRole.admin ||
        role == UserRole.manager ||
        role == UserRole.salesAgent ||
        role == UserRole.marketing;
    if (session != null && canEditRole) {
      _watchTaskWhenReady(session);
    }

    return CrmAppShell(
      selectedItem: CrmNavigationItem.tasks,
      title: l.editTask,
      child: !canEditRole || companyId.isEmpty || uid.isEmpty
          ? AppErrorView(message: l.permissionDenied)
          : BlocBuilder<TasksCubit, TasksState>(
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

                if ((role == UserRole.salesAgent ||
                        role == UserRole.marketing) &&
                    task.assignedTo != uid) {
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
                            return AppErrorView(
                              message: localizeThrownErrorMessage(
                                l,
                                usersSnapshot.error,
                              ),
                            );
                          }
                          final users = _includeCurrentUserProfile(
                            usersSnapshot.data ?? const [],
                            session?.profile,
                          );
                          final taskAssignees = eligibleTaskAssigneesForRole(
                            users: users,
                            role: role!,
                            currentUserId: uid,
                            currentTeamId: session?.profile.teamId ?? '',
                          );
                          return TaskForm(
                            companyId: companyId,
                            actorUid: uid,
                            actorProfile: session?.profile,
                            task: task,
                            users: taskAssignees,
                            canEditAssignment: true,
                            canEditStatus: true,
                            relatedRecordsAssignedTo:
                                role == UserRole.salesAgent ||
                                        role == UserRole.marketing
                                    ? uid
                                    : null,
                            relatedRecordsManagerId:
                                role == UserRole.manager ? uid : null,
                            relatedRecordsTeamId: role == UserRole.manager
                                ? session?.profile.teamId
                                : null,
                            isSaving: isSaving,
                            submitLabel: l.updateTask,
                            onSubmit: (updatedTask) async {
                              if (_isSubmitting) {
                                return;
                              }
                              if (role == UserRole.manager) {
                                final managerTeamId = session?.profile.teamId.trim() ?? '';
                                final inManagerScope =
                                    updatedTask.assignedTo.trim() == uid ||
                                    updatedTask.managerId.trim() == uid ||
                                    (managerTeamId.isNotEmpty &&
                                        updatedTask.teamId.trim() == managerTeamId);
                                if (!inManagerScope) {
                                  AppFeedback.warning(
                                    context,
                                    l.canOnlyAssignRecordsToYourTeam,
                                  );
                                  return;
                                }
                              }
                              setState(() => _isSubmitting = true);
                              final cubit = context.read<TasksCubit>();
                              final success = await cubit.updateTask(
                                companyId: companyId,
                                task: updatedTask,
                              );
                              if (!mounted) {
                                return;
                              }
                              setState(() => _isSubmitting = false);
                              if (success) {
                                AppFeedback.success(
                                  context,
                                  l.taskUpdatedSuccessfully,
                                );
                                context.go(RouteNames.tasks);
                                return;
                              }
                              AppFeedback.error(
                                context,
                                localizeErrorMessage(l, cubit.state.message),
                              );
                            },
                          );
                        },
                      )
                    : TaskForm(
                        companyId: companyId,
                        actorUid: uid,
                        actorProfile: session?.profile,
                        task: task,
                        users: _includeCurrentUserProfile(
                          const <UserProfile>[],
                          session?.profile,
                        ),
                        canEditStatus: true,
                        relatedRecordsAssignedTo:
                            role == UserRole.salesAgent ||
                                    role == UserRole.marketing
                                ? uid
                                : null,
                        relatedRecordsManagerId:
                            role == UserRole.manager ? uid : null,
                        relatedRecordsTeamId: role == UserRole.manager
                            ? session?.profile.teamId
                            : null,
                        isSaving: isSaving,
                        submitLabel: l.updateTask,
                        onSubmit: (updatedTask) async {
                          if (_isSubmitting) {
                            return;
                          }
                          setState(() => _isSubmitting = true);
                          final cubit = context.read<TasksCubit>();
                          final success = await cubit.updateTask(
                            companyId: companyId,
                            task: updatedTask,
                          );
                          if (!mounted) {
                            return;
                          }
                          setState(() => _isSubmitting = false);
                          if (success) {
                            AppFeedback.success(
                              context,
                              l.taskUpdatedSuccessfully,
                            );
                            context.go(RouteNames.tasks);
                            return;
                          }
                          AppFeedback.error(
                            context,
                            localizeErrorMessage(l, cubit.state.message),
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

List<UserProfile> _includeCurrentUserProfile(
  List<UserProfile> users,
  UserProfile? currentUser,
) {
  if (currentUser == null) {
    return users;
  }
  var foundCurrentUser = false;
  final mergedUsers = users.map((user) {
    if (user.uid != currentUser.uid) {
      return user;
    }
    foundCurrentUser = true;
    return _preferCurrentUserAssignmentSnapshot(user, currentUser);
  }).toList();
  if (foundCurrentUser) {
    return mergedUsers;
  }
  return <UserProfile>[currentUser, ...users];
}

UserProfile _preferCurrentUserAssignmentSnapshot(
  UserProfile user,
  UserProfile currentUser,
) {
  return user.copyWith(
    fullName: _firstNonEmptyText([currentUser.fullName, user.fullName]),
    email: _firstNonEmptyText([currentUser.email, user.email]),
    teamId: _firstNonEmptyText([currentUser.teamId, user.teamId]),
    teamName: _firstNonEmptyText([currentUser.teamName, user.teamName]),
    managerId: _firstNonEmptyText([currentUser.managerId, user.managerId]),
    managerName: _firstNonEmptyText([
      currentUser.managerName,
      user.managerName,
    ]),
  );
}

Stream<List<UserProfile>> _watchActiveUsers(String companyId) {
  final repository = UserProfileRepositoryImpl(
    remoteDataSource: FirestoreUserProfileRemoteDataSource(),
  );
  return WatchActiveUsersUseCase(repository)(companyId: companyId);
}

String _firstNonEmptyText(List<String> values) {
  for (final value in values) {
    final trimmed = value.trim();
    if (trimmed.isNotEmpty) {
      return trimmed;
    }
  }
  return '';
}


List<UserProfile> eligibleTaskAssigneesForRole({
  required List<UserProfile> users,
  required UserRole role,
  required String currentUserId,
  required String currentTeamId,
}) {
  final normalizedTeamId = currentTeamId.trim();
  return users.where((candidate) {
    if (!candidate.isActive) {
      return false;
    }
    final canOwnTask = candidate.role == UserRole.admin ||
        candidate.role == UserRole.manager ||
        candidate.role == UserRole.salesAgent ||
        candidate.role == UserRole.marketing;
    if (!canOwnTask) {
      return false;
    }
    if (role == UserRole.admin) {
      return true;
    }
    if (role == UserRole.manager) {
      final isSelf = candidate.uid == currentUserId;
      final sameManager = candidate.managerId.trim() == currentUserId;
      final sameTeam = normalizedTeamId.isNotEmpty &&
          candidate.teamId.trim() == normalizedTeamId;
      return isSelf || sameManager || sameTeam;
    }
    return candidate.uid == currentUserId;
  }).toList()
    ..sort((a, b) {
      final aLabel = a.fullName.trim().isEmpty ? a.email : a.fullName;
      final bLabel = b.fullName.trim().isEmpty ? b.email : b.fullName;
      return aLabel.compareTo(bLabel);
    });
}
