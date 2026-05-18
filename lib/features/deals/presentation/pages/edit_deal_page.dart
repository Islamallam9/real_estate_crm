import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

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
    return DealsScope(child: _EditDealView(dealId: dealId));
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
  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    final companyId = authState.userProfile?.companyId ?? authState.user?.companyId ?? '';
    final role = authState.userProfile?.role ?? authState.user?.role;
    final uid = authState.user?.uid ?? '';
    if (companyId.isNotEmpty &&
        role != null &&
        uid.isNotEmpty &&
        PermissionService.can(role, AppPermission.editDeal)) {
      context.read<DealsCubit>().watchDeals(
        companyId: companyId,
        role: role,
        currentUserId: uid,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final authState = context.read<AuthBloc>().state;
    final userProfile = authState.userProfile;
    final user = authState.user;
    final role = userProfile?.role ?? user?.role;
    final canEdit = role != null && PermissionService.can(role, AppPermission.editDeal);
    final canEditAssignment = role == UserRole.admin || role == UserRole.manager;

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
                                    return DealForm(
                                      companyId: userProfile.companyId,
                                      actorUid: user.uid,
                                      deal: deal,
                                      clients: data.clients,
                                      leads: data.leads,
                                      properties: data.properties,
                                      users: data.users,
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
