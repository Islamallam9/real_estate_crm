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
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/crm_app_shell.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../cubit/tasks_cubit.dart';
import '../cubit/tasks_state.dart';
import '../widgets/task_form.dart';
import '../widgets/tasks_scope.dart';

class CreateTaskPage extends StatelessWidget {
  const CreateTaskPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const TasksScope(child: _CreateTaskView());
  }
}

class _CreateTaskView extends StatelessWidget {
  const _CreateTaskView();

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
    final canCreate = PermissionService.can(role, AppPermission.createTask) &&
        (role == UserRole.admin || role == UserRole.manager);

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
                final messenger = ScaffoldMessenger.of(context);
                messenger.hideCurrentSnackBar();
                if (state.status == TasksStatus.failure) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(localizeErrorMessage(l, state.message)),
                      backgroundColor: AppColors.error,
                    ),
                  );
                  return;
                }

                messenger.showSnackBar(
                  SnackBar(content: Text(l.taskCreatedSuccessfully)),
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
                      alignment: AlignmentDirectional.topStart,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 760),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: TextButton.icon(
                                onPressed: () => context.go(RouteNames.tasks),
                                icon: const Icon(Icons.arrow_back),
                                label: Text(l.back),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            TaskForm(
                              companyId: userProfile.companyId,
                              actorUid: user.uid,
                              isSaving: isSaving,
                              submitLabel: l.createTask,
                              onSubmit: (task) {
                                context.read<TasksCubit>().createTask(
                                  companyId: userProfile.companyId,
                                  task: task,
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
