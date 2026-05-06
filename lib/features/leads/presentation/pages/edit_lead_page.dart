import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/error_mapper.dart';
import '../../../../core/permissions/app_permission.dart';
import '../../../../core/permissions/permission_service.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loading.dart';
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

class EditLeadPage extends StatelessWidget {
  const EditLeadPage({super.key, required this.leadId});

  final String leadId;

  @override
  Widget build(BuildContext context) {
    return LeadsScope(child: _EditLeadView(leadId: leadId));
  }
}

class _EditLeadView extends StatefulWidget {
  const _EditLeadView({required this.leadId});

  final String leadId;

  @override
  State<_EditLeadView> createState() => _EditLeadViewState();
}

class _EditLeadViewState extends State<_EditLeadView> {
  @override
  void initState() {
    super.initState();
    final companyId = _companyId(context);
    if (companyId.isNotEmpty) {
      context.read<LeadsCubit>().loadLead(
        companyId: companyId,
        leadId: widget.leadId,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final authState = context.read<AuthBloc>().state;
    final role = authState.userProfile?.role ?? authState.user?.role;
    final canEdit =
        role != null && PermissionService.can(role, AppPermission.editLead);
    final canAssign =
        role != null && PermissionService.can(role, AppPermission.assignLead);
    final companyId = _companyId(context);
    final uid = authState.user?.uid ?? '';
    final actorName =
        authState.userProfile?.fullName ?? authState.user?.fullName ?? '';

    return CrmAppShell(
      selectedItem: CrmNavigationItem.leads,
      title: localizations.editLead,
      child: !canEdit
          ? AppErrorView(message: localizations.permissionDenied)
          : BlocConsumer<LeadsCubit, LeadsState>(
              listenWhen: (previous, current) {
                return previous.status != current.status &&
                    (current.status == LeadsStatus.saved ||
                        current.status == LeadsStatus.failure);
              },
              listener: (context, state) {
                if (state.status == LeadsStatus.failure) {
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                      SnackBar(
                        content: Text(
                          localizeErrorMessage(localizations, state.message),
                        ),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  return;
                }
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    SnackBar(
                      content: Text(
                        _successMessageForAction(
                          localizations,
                          state.lastAction,
                        ),
                      ),
                    ),
                  );
                context.go(RouteNames.leadDetails(widget.leadId));
              },
              builder: (context, state) {
                if (state.status == LeadsStatus.loading ||
                    state.status == LeadsStatus.initial) {
                  return const AppLoading();
                }

                final lead = state.selectedLead;
                if (lead == null || companyId.isEmpty || uid.isEmpty) {
                  return AppErrorView(
                    message: localizeErrorMessage(
                      localizations,
                      state.message ?? localizations.unableToLoadLeads,
                    ),
                    onRetry: () {
                      context.read<LeadsCubit>().loadLead(
                        companyId: companyId,
                        leadId: widget.leadId,
                      );
                    },
                  );
                }

                return StreamBuilder<List<UserProfile>>(
                  stream: _watchActiveUsers(companyId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return AppErrorView(
                        message: localizations.unableToConnect,
                        onRetry: () {
                          context.read<LeadsCubit>().loadLead(
                            companyId: companyId,
                            leadId: widget.leadId,
                          );
                        },
                      );
                    }
                    final users = snapshot.data ?? const <UserProfile>[];
                    final isSaving = state.status == LeadsStatus.saving;

                    return Stack(
                      children: [
                        ListView(
                          primary: true,
                          physics: const ClampingScrollPhysics(),
                          padding: const EdgeInsets.only(
                            bottom: AppSpacing.lg,
                          ),
                          children: [
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 720),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  LeadForm(
                                    companyId: companyId,
                                    createdBy: uid,
                                    lead: lead,
                                    submitLabel: localizations.updateLead,
                                    isSaving: isSaving,
                                    canAssign: canAssign,
                                    assignmentUsers: users,
                                    onSubmit: (updatedLead) {
                                      context.read<LeadsCubit>().updateLead(
                                        companyId: companyId,
                                        lead: updatedLead,
                                        actorName: actorName,
                                      );
                                    },
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  AppButton(
                                    label: localizations.cancel,
                                    onPressed: isSaving
                                        ? null
                                        : () => context.go(
                                            RouteNames.leadDetails(
                                              widget.leadId,
                                            ),
                                          ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (isSaving)
                          Positioned.fill(
                            child: AbsorbPointer(
                              child: Container(
                                color: AppColors.appBackground(
                                  context,
                                ).withValues(alpha: 0.70),
                                child: const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                );
              },
            ),
    );
  }
}

String _successMessageForAction(AppLocalizations l, LeadsAction action) {
  switch (action) {
    case LeadsAction.assignLead:
      return l.leadAssignedSuccessfully;
    case LeadsAction.updateLead:
      return l.leadUpdatedSuccessfully;
    case LeadsAction.updateStatus:
      return l.leadStatusUpdatedSuccessfully;
    case LeadsAction.createLead:
      return l.leadCreatedSuccessfully;
    case LeadsAction.archiveLead:
      return l.leadArchivedSuccessfully;
    case LeadsAction.addNote:
      return l.noteAddedSuccessfully;
    case LeadsAction.none:
      return l.leadUpdatedSuccessfully;
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
