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
import '../cubit/deals_cubit.dart';
import '../cubit/deals_state.dart';
import '../widgets/deal_form.dart';
import '../widgets/deal_form_data_loader.dart';
import '../widgets/deals_scope.dart';

class CreateDealPage extends StatelessWidget {
  const CreateDealPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const DealsScope(child: _CreateDealView());
  }
}

class _CreateDealView extends StatefulWidget {
  const _CreateDealView();

  @override
  State<_CreateDealView> createState() => _CreateDealViewState();
}

class _CreateDealViewState extends State<_CreateDealView> {
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final authState = context.read<AuthBloc>().state;
    final userProfile = authState.userProfile;
    final user = authState.user;

    if (userProfile == null || user == null) {
      return CrmAppShell(
        selectedItem: CrmNavigationItem.deals,
        title: l.createDeal,
        child: AppErrorView(message: l.missingCompanyProfile),
      );
    }

    final role = userProfile.role;
    final canCreate = PermissionService.can(role, AppPermission.createDeal);
    final canEditAssignment = role == UserRole.admin || role == UserRole.manager;
    final assignedTo = canEditAssignment ? '' : user.uid;
    final assignedToName = canEditAssignment ? '' : userProfile.fullName;
    final assignedToEmail = canEditAssignment ? '' : userProfile.email;
    final assignedTeamId = canEditAssignment ? '' : userProfile.teamId;
    final assignedTeamName = canEditAssignment ? '' : userProfile.teamName;
    final assignedManagerId = canEditAssignment ? '' : userProfile.managerId;
    final assignedManagerName = canEditAssignment ? '' : userProfile.managerName;

    return CrmAppShell(
      selectedItem: CrmNavigationItem.deals,
      title: l.createDeal,
      child: !canCreate
          ? AppErrorView(message: l.permissionDenied)
          : BlocBuilder<DealsCubit, DealsState>(
              builder: (context, state) {
                final isSaving = _isSubmitting || state.status == DealsStatus.saving;
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
                                    : () => context.go(RouteNames.deals),
                                icon: const Icon(Icons.arrow_back),
                                label: Text(l.back),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            DealFormDataLoader(
                              companyId: userProfile.companyId,
                              assignedTo: canEditAssignment ? null : user.uid,
                              managerId: role == UserRole.manager ? user.uid : null,
                              teamId: role == UserRole.manager
                                  ? userProfile.teamId
                                  : null,
                              builder: (context, data) {
                                final eligibleDealUsers = eligibleDealAssigneesForRole(
                                  users: data.users,
                                  role: role,
                                  currentUserId: user.uid,
                                  currentTeamId: userProfile.teamId,
                                );
                                return DealForm(
                                  companyId: userProfile.companyId,
                                  actorUid: user.uid,
                                  clients: data.clients,
                                  leads: data.leads,
                                  properties: data.properties,
                                  users: eligibleDealUsers,
                                  canEditAssignment: canEditAssignment,
                                  assignedTo: assignedTo,
                                  assignedToName: assignedToName,
                                  assignedToEmail: assignedToEmail,
                                  assignedTeamId: assignedTeamId,
                                  assignedTeamName: assignedTeamName,
                                  assignedManagerId: assignedManagerId,
                                  assignedManagerName: assignedManagerName,
                                  isSaving: isSaving,
                                  submitLabel: l.createDeal,
                                  onSubmit: (deal) async {
                                    if (_isSubmitting) {
                                      return;
                                    }
                                    if (role == UserRole.manager &&
                                        deal.managerId.trim() != user.uid) {
                                      AppFeedback.warning(
                                        context,
                                        l.canOnlyAssignRecordsToYourTeam,
                                      );
                                      return;
                                    }
                                    setState(() => _isSubmitting = true);
                                    final cubit = context.read<DealsCubit>();
                                    final success = await cubit.createDeal(
                                      companyId: userProfile.companyId,
                                      deal: deal,
                                    );
                                    if (!mounted) {
                                      return;
                                    }
                                    setState(() => _isSubmitting = false);
                                    if (success) {
                                      AppFeedback.success(
                                        context,
                                        l.dealCreatedSuccessfully,
                                      );
                                      context.go(RouteNames.deals);
                                      return;
                                    }
                                    AppFeedback.error(
                                      context,
                                      localizeDealFormError(l, cubit.state.message),
                                    );
                                  },
                                );
                              },
                            ),
                            const SizedBox(height: AppSpacing.md),
                            AppButton(
                              label: l.cancel,
                              variant: AppButtonVariant.secondary,
                              onPressed: isSaving
                                  ? null
                                  : () => context.go(RouteNames.deals),
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


List<UserProfile> eligibleDealAssigneesForRole({
  required List<UserProfile> users,
  required UserRole role,
  required String currentUserId,
  required String currentTeamId,
}) {
  final normalizedTeamId = currentTeamId.trim();
  return users.where((candidate) {
    if (!candidate.isActive || candidate.role != UserRole.salesAgent) {
      return false;
    }
    if (role == UserRole.manager) {
      final sameManager = candidate.managerId.trim() == currentUserId;
      final sameTeam = normalizedTeamId.isNotEmpty &&
          candidate.teamId.trim() == normalizedTeamId;
      return sameManager || sameTeam;
    }
    if (role == UserRole.admin) {
      return true;
    }
    return candidate.uid == currentUserId;
  }).toList()
    ..sort((a, b) {
      final aLabel = a.fullName.trim().isEmpty ? a.email : a.fullName;
      final bLabel = b.fullName.trim().isEmpty ? b.email : b.fullName;
      return aLabel.compareTo(bLabel);
    });
}

String localizeDealFormError(AppLocalizations l, String? message) {
  switch (message) {
    case 'lostReasonRequired':
      return l.lostReasonRequired;
    case 'lostReasonControlledRequired':
      return l.lostReasonControlledRequired;
    case 'dealWonClientRequired':
      return l.dealWonRequiresClient;
    case 'dealWonPropertyRequired':
      return l.dealWonRequiresProperty;
    case 'dealWonValueRequired':
      return l.dealWonRequiresExpectedValue;
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
