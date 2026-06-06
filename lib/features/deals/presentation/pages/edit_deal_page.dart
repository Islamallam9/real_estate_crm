import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/protected_company_session.dart';
import '../../../../core/constants/role_constants.dart';
import '../../../../core/permissions/app_permission.dart';
import '../../../../core/permissions/permission_service.dart';
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
import '../../domain/entities/deal.dart';
import '../cubit/deals_cubit.dart';
import '../cubit/deals_state.dart';
import '../widgets/deal_form.dart';
import '../widgets/deal_form_data_loader.dart';
import '../widgets/deals_scope.dart';
import 'create_deal_page.dart';

class EditDealPage extends StatelessWidget {
  const EditDealPage({super.key, required this.dealId});

  final String dealId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final session = authState.protectedCompanySession;
        return DealsScope(
          key: ValueKey(
            session?.scopeKey('edit-deal-scope') ?? 'edit-deal-scope:loading',
          ),
          child: _EditDealView(dealId: dealId),
        );
      },
    );
  }
}

class _EditDealView extends StatefulWidget {
  const _EditDealView({required this.dealId});

  final String dealId;

  @override
  State<_EditDealView> createState() => _EditDealViewState();
}

class _EditDealViewState extends State<_EditDealView> {
  bool _isSubmitting = false;
  String? _watchKey;

  void _watchDealWhenAllowed(ProtectedCompanySession session) {
    final role = session.profile.role;
    if (!PermissionService.can(role, AppPermission.editDeal)) {
      return;
    }
    final key = session.scopeKey('edit-deal-watch');
    if (_watchKey == key) {
      return;
    }
    _watchKey = key;
    context.read<DealsCubit>().watchDeal(
      companyId: session.companyId,
      dealId: widget.dealId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final authState = context.watch<AuthBloc>().state;
    final session = authState.protectedCompanySession;

    if (authState.isWaitingForProtectedCompanySession) {
      return CrmAppShell(
        selectedItem: CrmNavigationItem.deals,
        title: l.editDeal,
        child: const AppLoading(),
      );
    }

    final userProfile = session?.profile;
    final user = session?.user;
    final role = userProfile?.role;
    final canEdit = role != null && PermissionService.can(role, AppPermission.editDeal);
    final canEditAssignment = role == UserRole.admin || role == UserRole.manager;
    if (session != null && canEdit) {
      _watchDealWhenAllowed(session);
    }

    return CrmAppShell(
      selectedItem: CrmNavigationItem.deals,
      title: l.editDeal,
      child: userProfile == null || user == null
          ? AppErrorView(message: l.missingCompanyProfile)
          : !canEdit
              ? AppErrorView(message: l.permissionDenied)
              : BlocConsumer<DealsCubit, DealsState>(
                  listenWhen: (previous, current) =>
                      previous.status != current.status &&
                      (current.status == DealsStatus.saved ||
                          current.status == DealsStatus.failure),
                  listener: (context, state) {
                    if (state.status == DealsStatus.failure) {
                      setState(() => _isSubmitting = false);
                      AppFeedback.error(
                        context,
                        localizeDealFormError(l, state.message),
                      );
                      return;
                    }
                    setState(() => _isSubmitting = false);
                    AppFeedback.success(context, l.dealUpdatedSuccessfully);
                    context.go(RouteNames.deals);
                  },
                  builder: (context, state) {
                    if ((state.status == DealsStatus.initial ||
                            state.status == DealsStatus.loading) &&
                        state.deals.isEmpty) {
                      return const AppLoading();
                    }
                    final deal = _findDeal(state.deals, widget.dealId);
                    if (deal == null) {
                      return AppErrorView(message: l.dealNotFoundMessage);
                    }
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
                                DealFormDataLoader(
                                  companyId: userProfile.companyId,
                                  managerId: userProfile.role == UserRole.manager
                                      ? user.uid
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
                                      deal: deal,
                                      clients: data.clients,
                                      leads: data.leads,
                                      properties: data.properties,
                                      users: eligibleDealUsers,
                                      canEditAssignment: canEditAssignment,
                                      assignedTo: deal.assignedTo,
                                      assignedToName: deal.assignedToName,
                                      assignedToEmail: deal.assignedToEmail,
                                      assignedTeamId: deal.teamId,
                                      assignedTeamName: deal.teamName,
                                      assignedManagerId: deal.managerId,
                                      assignedManagerName: deal.managerName,
                                      isSaving: isSaving,
                                      submitLabel: l.updateDeal,
                                      onSubmit: (updatedDeal) {
                                        if (_isSubmitting) {
                                          return;
                                        }
                                        if (role == UserRole.manager &&
                                            updatedDeal.managerId.trim() !=
                                                user.uid) {
                                          AppFeedback.warning(
                                            context,
                                            l.canOnlyAssignRecordsToYourTeam,
                                          );
                                          return;
                                        }
                                        setState(() => _isSubmitting = true);
                                        context.read<DealsCubit>().updateDeal(
                                          companyId: userProfile.companyId,
                                          deal: updatedDeal,
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

Deal? _findDeal(List<Deal> deals, String dealId) {
  for (final deal in deals) {
    if (deal.id == dealId) {
      return deal;
    }
  }
  return null;
}
