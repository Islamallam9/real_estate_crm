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

class _CreateTaskView extends StatefulWidget {
  const _CreateTaskView({required this.initialValues});

  final Map<String, String> initialValues;

  @override
  State<_CreateTaskView> createState() => _CreateTaskViewState();
}

class _CreateTaskViewState extends State<_CreateTaskView> {
  bool _isSubmitting = false;

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
          : BlocBuilder<TasksCubit, TasksState>(
              builder: (context, state) {
                final isSaving =
                    _isSubmitting || state.status == TasksStatus.saving;
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
                                final effectiveUsers = _includeCurrentUserProfile(
                                  users.isEmpty &&
                                          (role == UserRole.salesAgent ||
                                              role == UserRole.marketing)
                                      ? <UserProfile>[userProfile]
                                      : users,
                                  userProfile,
                                );
                                final taskAssignees = eligibleTaskAssigneesForRole(
                                  users: effectiveUsers,
                                  role: role,
                                  currentUserId: user.uid,
                                  currentTeamId: userProfile.teamId,
                                );
                                return TaskForm(
                                  companyId: userProfile.companyId,
                                  actorUid: user.uid,
                                  actorProfile: userProfile,
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
                                    initialValues: widget.initialValues,
                                  ),
                                  initialRelatedType:
                                      _initialRelatedType(widget.initialValues),
                                  initialRelatedId:
                                      widget.initialValues['relatedId'] ?? '',
                                  initialRelatedTitle:
                                      widget.initialValues['relatedTitle'] ?? '',
                                  initialRelatedSubtitle:
                                      widget.initialValues['relatedSubtitle'] ?? '',
                                  initialTitle: _initialTitle(
                                    l,
                                    widget.initialValues['relatedTitle'],
                                  ),
                                  isSaving: isSaving,
                                  submitLabel: l.createTask,
                                  onSubmit: (task) async {
                                    if (_isSubmitting) {
                                      return;
                                    }
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
                                    setState(() => _isSubmitting = true);
                                    final cubit = context.read<TasksCubit>();
                                    final success = await cubit.createTask(
                                      companyId: userProfile.companyId,
                                      task: task,
                                    );
                                    if (!mounted) {
                                      return;
                                    }
                                    setState(() => _isSubmitting = false);
                                    if (success) {
                                      AppFeedback.success(
                                        context,
                                        l.taskCreatedSuccessfully,
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


List<UserProfile> _includeCurrentUserProfile(
  List<UserProfile> users,
  UserProfile currentUser,
) {
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

String _firstNonEmptyText(List<String> values) {
  for (final value in values) {
    final trimmed = value.trim();
    if (trimmed.isNotEmpty) {
      return trimmed;
    }
  }
  return '';
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
