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
import '../../../users/data/datasources/user_profile_remote_data_source.dart';
import '../../../users/data/repositories/user_profile_repository_impl.dart';
import '../../../users/domain/entities/user_profile.dart';
import '../../../users/domain/usecases/watch_active_users_usecase.dart';
import '../cubit/clients_cubit.dart';
import '../cubit/clients_state.dart';
import '../widgets/client_form.dart';
import '../widgets/clients_scope.dart';

class CreateClientPage extends StatelessWidget {
  const CreateClientPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ClientsScope(child: _CreateClientView());
  }
}

class _CreateClientView extends StatelessWidget {
  const _CreateClientView();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final authState = context.read<AuthBloc>().state;
    final userProfile = authState.userProfile;
    final user = authState.user;

    if (userProfile == null || user == null) {
      return CrmAppShell(
        selectedItem: CrmNavigationItem.clients,
        title: l.createClient,
        child: AppErrorView(message: l.missingCompanyProfile),
      );
    }

    final companyId = userProfile.companyId;
    final uid = user.uid;
    final role = userProfile.role;
    final canCreate = PermissionService.can(role, AppPermission.createClient);
    final canEditAssignment = role == UserRole.admin || role == UserRole.manager;
    final defaultAssignedTo = role == UserRole.salesAgent ? uid : '';

    return CrmAppShell(
      selectedItem: CrmNavigationItem.clients,
      title: l.createClient,
      child: !canCreate
          ? AppErrorView(message: l.permissionDenied)
          : BlocConsumer<ClientsCubit, ClientsState>(
              listenWhen: (previous, current) =>
                  previous.status != current.status &&
                  (current.status == ClientsStatus.saved ||
                      current.status == ClientsStatus.failure),
              listener: (context, state) {
                if (state.status == ClientsStatus.failure) {
                  AppFeedback.error(
                    context,
                    localizeErrorMessage(l, state.message),
                  );
                  return;
                }

                AppFeedback.success(
                  context,
                  l.clientCreatedSuccessfully,
                );
                context.go(RouteNames.clients);
              },
              builder: (context, state) {
                final isSaving = state.status == ClientsStatus.saving;
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
                          final users = usersSnapshot.data ?? const [];
                          return ClientForm(
                            companyId: companyId,
                            actorUid: uid,
                            assignedTo: defaultAssignedTo,
                            users: users,
                            canEditAssignment: true,
                            isSaving: isSaving,
                            submitLabel: l.createClient,
                            onSubmit: (client) {
                              if (role == UserRole.manager &&
                                  client.assignedTo.trim().isEmpty) {
                                AppFeedback.warning(
                                  context,
                                  l.recordMustBeAssignedBeforeSaving,
                                );
                                return;
                              }
                              if (role == UserRole.manager &&
                                  client.managerId.trim() != uid) {
                                AppFeedback.warning(
                                  context,
                                  l.canOnlyAssignRecordsToYourTeam,
                                );
                                return;
                              }
                              context.read<ClientsCubit>().createClient(
                                companyId: companyId,
                                client: client,
                              );
                            },
                          );
                        },
                      )
                    : ClientForm(
                        companyId: companyId,
                        actorUid: uid,
                        assignedTo: defaultAssignedTo,
                        assignedToName: userProfile.fullName,
                        assignedToEmail: userProfile.email,
                        assignedTeamId: userProfile.teamId,
                        assignedTeamName: userProfile.teamName,
                        assignedManagerId: userProfile.managerId,
                        assignedManagerName: userProfile.managerName,
                        isSaving: isSaving,
                        submitLabel: l.createClient,
                        onSubmit: (client) {
                          context.read<ClientsCubit>().createClient(
                            companyId: companyId,
                            client: client,
                          );
                        },
                      );
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
                                    : () => context.go(RouteNames.clients),
                                icon: const Icon(Icons.arrow_back),
                                label: Text(l.back),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            form,
                            const SizedBox(height: AppSpacing.md),
                            AppButton(
                              label: l.cancel,
                              onPressed: isSaving
                                  ? null
                                  : () => context.go(RouteNames.clients),
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

Stream<List<UserProfile>> _watchActiveUsers(String companyId) {
  final repository = UserProfileRepositoryImpl(
    remoteDataSource: FirestoreUserProfileRemoteDataSource(),
  );
  return WatchActiveUsersUseCase(repository)(companyId: companyId);
}
