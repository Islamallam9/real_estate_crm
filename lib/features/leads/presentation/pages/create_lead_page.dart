import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

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
import '../cubit/leads_cubit.dart';
import '../cubit/leads_state.dart';
import '../widgets/lead_form.dart';
import '../widgets/leads_scope.dart';
import '../../../../core/widgets/masar_loading_view.dart';

class CreateLeadPage extends StatelessWidget {
  const CreateLeadPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const LeadsScope(child: _CreateLeadView());
  }
}

class _CreateLeadView extends StatelessWidget {
  const _CreateLeadView();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final authState = context.read<AuthBloc>().state;
    final userProfile = authState.userProfile;
    final user = authState.user;

    if (userProfile == null || user == null) {
      return CrmAppShell(
        selectedItem: CrmNavigationItem.leads,
        title: l.createLead,
        child: AppErrorView(message: l.missingCompanyProfile),
      );
    }

    final companyId = userProfile.companyId;
    final uid = user.uid;
    final role = userProfile.role;
    final actorName = userProfile.fullName.isEmpty
        ? l.unknownUser
        : userProfile.fullName;
    final canCreate = PermissionService.can(role, AppPermission.createLead);
    final canAssign = PermissionService.can(role, AppPermission.assignLead);

    return CrmAppShell(
      selectedItem: CrmNavigationItem.leads,
      title: l.createLead,
      child: !canCreate
          ? AppErrorView(message: l.permissionDenied)
          : BlocConsumer<LeadsCubit, LeadsState>(
              listenWhen: (previous, current) =>
                  previous.status != current.status &&
                  (current.status == LeadsStatus.saved ||
                      current.status == LeadsStatus.failure),
              listener: (context, state) {
                if (state.status == LeadsStatus.failure) {
                  AppFeedback.error(
                    context,
                    localizeErrorMessage(l, state.message),
                  );
                  return;
                }
                AppFeedback.success(
                  context,
                  _successMessageForAction(l, state.lastAction),
                );
                context.go(RouteNames.leads);
              },
              builder: (context, state) {
                return _CreateLeadFormContent(
                  companyId: companyId,
                  uid: uid,
                  canAssign: canAssign,
                  roleName: role.name,
                  actorName: actorName,
                  userProfile: userProfile,
                );
              },
            ),
    );
  }
}

class _CreateLeadFormContent extends StatelessWidget {
  const _CreateLeadFormContent({
    required this.companyId,
    required this.uid,
    required this.canAssign,
    required this.roleName,
    required this.actorName,
    required this.userProfile,
  });

  final String companyId;
  final String uid;
  final bool canAssign;
  final String roleName;
  final String actorName;
  final UserProfile userProfile;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return ListView(
      primary: true,
      physics: const ClampingScrollPhysics(),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
                  child: BlocSelector<LeadsCubit, LeadsState, bool>(
                    selector: (state) => state.status == LeadsStatus.saving,
                    builder: (context, isSaving) {
                      return TextButton.icon(
                        onPressed: isSaving
                            ? null
                            : () => context.go(RouteNames.leads),
                        icon: const Icon(Icons.arrow_back),
                        label: Text(l.back),
                      );
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                StreamBuilder<List<UserProfile>>(
                  stream: canAssign ? _watchActiveUsers(companyId) : null,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting &&
                        canAssign) {
                      return const Center(child: MasarLogoLoader(size: 40));
                    }
                    if (snapshot.hasError) {
                      return AppErrorView(
                        message: localizeThrownErrorMessage(
                          l,
                          snapshot.error,
                        ),
                        onRetry: () {
                          context.read<LeadsCubit>().watchLeads(
                            companyId: companyId,
                          );
                        },
                      );
                    }
                    final users = snapshot.data ?? const <UserProfile>[];
                    return BlocSelector<LeadsCubit, LeadsState, bool>(
                      selector: (state) => state.status == LeadsStatus.saving,
                      builder: (context, isSaving) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            LeadForm(
                              companyId: companyId,
                              createdBy: uid,
                              isSaving: isSaving,
                              canAssign: canAssign,
                              assignmentUsers: users,
                              lead: null,
                              onSubmit: (lead) {
                                if (roleName == 'manager' &&
                                    lead.assignedTo.trim().isEmpty) {
                                  AppFeedback.warning(
                                    context,
                                    l.recordMustBeAssignedBeforeSaving,
                                  );
                                  return;
                                }
                                if (roleName == 'manager' &&
                                    lead.managerId.trim() != uid) {
                                  AppFeedback.warning(
                                    context,
                                    l.canOnlyAssignRecordsToYourTeam,
                                  );
                                  return;
                                }
                                final isAssignedOnlyRole =
                                    roleName == 'salesAgent' ||
                                    roleName == 'marketing';
                                final leadToCreate = isAssignedOnlyRole
                                    ? lead.copyWith(
                                        assignedTo: uid,
                                        assignedToName: userProfile.fullName,
                                        teamId: userProfile.teamId,
                                        teamName: userProfile.teamName,
                                        managerId: userProfile.managerId,
                                        managerName: userProfile.managerName,
                                      )
                                    : lead;
                                context.read<LeadsCubit>().createLead(
                                  companyId: companyId,
                                  lead: leadToCreate,
                                  actorName: actorName,
                                );
                              },
                            ),
                            const SizedBox(height: AppSpacing.md),
                            AppButton(
                              label: l.cancel,
                              onPressed: isSaving
                                  ? null
                                  : () => context.go(RouteNames.leads),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

String _successMessageForAction(AppLocalizations l, LeadsAction action) {
  switch (action) {
    case LeadsAction.assignLead:
      return l.leadAssignedSuccessfully;
    case LeadsAction.createLead:
      return l.leadCreatedSuccessfully;
    case LeadsAction.updateLead:
      return l.leadUpdatedSuccessfully;
    case LeadsAction.updateStatus:
      return l.leadStatusUpdatedSuccessfully;
    case LeadsAction.archiveLead:
      return l.leadArchivedSuccessfully;
    case LeadsAction.restoreLead:
      return l.recordRestoredSuccessfully;
    case LeadsAction.addNote:
      return l.noteAddedSuccessfully;
    case LeadsAction.markContactedToday:
      return l.leadMarkedContactedToday;
    case LeadsAction.none:
      return l.leadCreatedSuccessfully;
  }
}

Stream<List<UserProfile>> _watchActiveUsers(String companyId) {
  final repository = UserProfileRepositoryImpl(
    remoteDataSource: FirestoreUserProfileRemoteDataSource(),
  );
  return WatchActiveUsersUseCase(repository)(companyId: companyId);
}
