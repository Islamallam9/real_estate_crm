import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/role_constants.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/permissions/app_permission.dart';
import '../../../../core/permissions/permission_service.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/crm_app_shell.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../users/domain/entities/user_profile.dart';
import '../../../users/presentation/widgets/active_users_stream_builder.dart';
import '../../domain/entities/crm_task.dart';
import '../cubit/tasks_cubit.dart';
import '../cubit/tasks_state.dart';
import '../widgets/task_form.dart';
import '../widgets/tasks_scope.dart';

class CreateTaskPage extends StatelessWidget {
  const CreateTaskPage({super.key, this.initialValues = const {}});

  final Map<String, String> initialValues;

  @override
  Widget build(BuildContext context) {
    return TasksScope(child: _CreateTaskView(initialValues: initialValues));
  }
}

class _CreateTaskView extends StatelessWidget {
  const _CreateTaskView({required this.initialValues});

  final Map<String, String> initialValues;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final authState = context.read<AuthBloc>().state;
    final userProfile = authState.userProfile;
    final user = authState.user;

    if (userProfile == null || user == null) {
      return CrmAppShell(
        selectedItem: CrmNavigationItem.tasks,
        title: l.createTask,
        child: AppErrorView(message: l.missingCompanyProfile),
      );
    }

    final role = userProfile.role;
    final canCreate = PermissionService.can(role, AppPermission.createTask);

    return CrmAppShell(
      selectedItem: CrmNavigationItem.tasks,
      title: l.createTask,
      child: !canCreate
          ? AppErrorView(message: l.permissionDenied)
          : BlocConsumer<TasksCubit, TasksState>(
              listenWhen: (previous, current) =>
                  previous.status != current.status &&
                  (current.status == TasksStatus.saved ||
                      current.status == TasksStatus.failure),
              listener: (context, state) {
                if (state.status == TasksStatus.failure) {
                  AppFeedback.error(
                    context,
                    localizeErrorMessage(l, state.message),
                  );
                  return;
                }

                AppFeedback.success(
                  context,
                  l.taskCreatedSuccessfully,
                );
                context.go(RouteNames.tasks);
              },
              builder: (context, state) {
                final isSaving = state.status == TasksStatus.saving;
                return ListView(
                  primary: true,
                  physics: const ClampingScrollPhysics(),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                  children: [
                    Align(
                      alignment: AlignmentDirectional.topCenter,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 860),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: TextButton.icon(
                                onPressed: isSaving
                                    ? null
                                    : () => context.go(RouteNames.tasks),
                                icon: const Icon(Icons.arrow_back),
                                label: Text(l.back),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            ActiveUsersStreamBuilder(
                              companyId: userProfile.companyId,
                              enabled: role == UserRole.admin ||
                                  role == UserRole.manager,
                              errorBuilder: (context, error) {
                                return AppErrorView(
                                  message: localizeThrownErrorMessage(l, error),
                                );
                              },
                              builder: (context, users) {
                                final effectiveUsers = users.isEmpty &&
                                        (role == UserRole.salesAgent ||
                                            role == UserRole.marketing)
                                    ? <UserProfile>[userProfile]
                                    : users;
                                final taskAssignees = eligibleTaskAssigneesForRole(
                                  users: effectiveUsers,
                                  role: role,
                                  currentUserId: user.uid,
                                  currentTeamId: userProfile.teamId,
                                );
                                return TaskForm(
                                  companyId: userProfile.companyId,
                                  actorUid: user.uid,
                                  users: taskAssignees,
                                  canEditAssignment:
                                      role == UserRole.admin ||
                                      role == UserRole.manager,
                                  relatedRecordsAssignedTo:
                                      role == UserRole.salesAgent ||
                                              role == UserRole.marketing
                                          ? user.uid
                                          : null,
                                  relatedRecordsManagerId:
                                      role == UserRole.manager ? user.uid : null,
                                  relatedRecordsTeamId:
                                      role == UserRole.manager
                                          ? userProfile.teamId
                                          : null,
                                  assignedTo: _initialAssignee(
                                    role: role,
                                    currentUserId: user.uid,
                                    initialValues: initialValues,
                                  ),
                                  initialRelatedType:
                                      _initialRelatedType(initialValues),
                                  initialRelatedId:
                                      initialValues['relatedId'] ?? '',
                                  initialRelatedTitle:
                                      initialValues['relatedTitle'] ?? '',
                                  initialRelatedSubtitle:
                                      initialValues['relatedSubtitle'] ?? '',
                                  initialTitle: _initialTitle(
                                    l,
                                    initialValues['relatedTitle'],
                                  ),
                                  isSaving: isSaving,
                                  submitLabel: l.createTask,
                                  onSubmit: (task) {
                                    if (role == UserRole.manager &&
                                        task.assignedTo.trim().isEmpty) {
                                      AppFeedback.warning(
                                        context,
                                        l.recordMustBeAssignedBeforeSaving,
                                      );
                                      return;
                                    }
                                    if (role == UserRole.manager) {
                                      final managerTeamId = userProfile.teamId.trim();
                                      final inManagerScope =
                                          task.assignedTo.trim() == user.uid ||
                                          task.managerId.trim() == user.uid ||
                                          (managerTeamId.isNotEmpty &&
                                              task.teamId.trim() == managerTeamId);
                                      if (!inManagerScope) {
                                        AppFeedback.warning(
                                          context,
                                          l.canOnlyAssignRecordsToYourTeam,
                                        );
                                        return;
                                      }
                                    }
                                    context.read<TasksCubit>().createTask(
                                      companyId: userProfile.companyId,
                                      task: task,
                                    );
                                  },
                                );
                              },
                            ),
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


TaskRelatedType? _initialRelatedType(Map<String, String> initialValues) {
  final value = initialValues['relatedType']?.trim();
  if (value == null || value.isEmpty) {
    return null;
  }
  for (final type in TaskRelatedType.values) {
    if (type.name == value) {
      return type;
    }
  }
  return null;
}

String _initialAssignee({
  required UserRole role,
  required String currentUserId,
  required Map<String, String> initialValues,
}) {
  if (role == UserRole.salesAgent || role == UserRole.marketing) {
    return currentUserId;
  }
  return initialValues['assignedTo']?.trim() ?? '';
}

String _initialTitle(AppLocalizations l, String? relatedTitle) {
  final title = relatedTitle?.trim() ?? '';
  return title.isEmpty ? '' : '${l.followUps}: $title';
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
