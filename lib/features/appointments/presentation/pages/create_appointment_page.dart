import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/role_constants.dart';
import '../../../../core/errors/error_mapper.dart';
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
import '../../domain/entities/appointment.dart';
import '../cubit/appointments_cubit.dart';
import '../cubit/appointments_state.dart';
import '../widgets/appointment_form.dart';
import '../widgets/appointments_scope.dart';

class CreateAppointmentPage extends StatelessWidget {
  const CreateAppointmentPage({super.key, this.initialValues = const {}});

  final Map<String, String> initialValues;

  @override
  Widget build(BuildContext context) {
    return AppointmentsScope(
      child: _CreateAppointmentView(initialValues: initialValues),
    );
  }
}

class _CreateAppointmentView extends StatelessWidget {
  const _CreateAppointmentView({required this.initialValues});

  final Map<String, String> initialValues;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final authState = context.read<AuthBloc>().state;
    final userProfile = authState.userProfile;
    final user = authState.user;
    if (userProfile == null || user == null) {
      return CrmAppShell(
        selectedItem: CrmNavigationItem.appointments,
        title: l.newAppointment,
        child: AppErrorView(message: l.missingCompanyProfile),
      );
    }
    final role = userProfile.role;
    final canCreate = role != UserRole.viewer;
    return CrmAppShell(
      selectedItem: CrmNavigationItem.appointments,
      title: l.newAppointment,
      child: !canCreate
          ? AppErrorView(message: l.permissionDenied)
          : BlocConsumer<AppointmentsCubit, AppointmentsState>(
              listenWhen: (previous, current) =>
                  previous.status != current.status &&
                  (current.status == AppointmentsStatus.saved ||
                      current.status == AppointmentsStatus.failure),
              listener: (context, state) {
                if (state.status == AppointmentsStatus.failure) {
                  AppFeedback.error(
                    context,
                    localizeErrorMessage(l, state.message),
                  );
                  return;
                }
                AppFeedback.success(context, l.appointmentSaved);
                context.go(RouteNames.appointments);
              },
              builder: (context, state) {
                final isSaving = state.status == AppointmentsStatus.saving;
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
                        constraints: const BoxConstraints(maxWidth: 900),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: TextButton.icon(
                                onPressed: isSaving
                                    ? null
                                    : () => context.go(RouteNames.appointments),
                                icon: const Icon(Icons.arrow_back),
                                label: Text(l.back),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            if (role == UserRole.admin ||
                                role == UserRole.manager)
                              ActiveUsersStreamBuilder(
                                companyId: userProfile.companyId,
                                errorBuilder: (context, error) {
                                  return AppErrorView(
                                    message: localizeThrownErrorMessage(l, error),
                                  );
                                },
                                builder: (context, users) {
                                  return AppointmentForm(
                                    companyId: userProfile.companyId,
                                    actorUid: user.uid,
                                    users: users,
                                    canEditAssignment: true,
                                    assignedTo:
                                        initialValues['assignedTo']?.trim() ??
                                            '',
                                    relatedRecordsManagerId:
                                        role == UserRole.manager ? user.uid : null,
                                    relatedRecordsTeamId:
                                        role == UserRole.manager
                                            ? userProfile.teamId
                                            : null,
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
                                    submitLabel: l.saveAppointment,
                                    onSubmit: (appointment) {
                                      final managerTeamId =
                                          userProfile.teamId.trim();
                                      if (role == UserRole.manager &&
                                          appointment.assignedTo.trim() !=
                                              user.uid &&
                                          appointment.managerId.trim() !=
                                              user.uid &&
                                          (managerTeamId.isEmpty ||
                                              appointment.teamId.trim() !=
                                                  managerTeamId)) {
                                        AppFeedback.warning(
                                          context,
                                          l.canOnlyAssignRecordsToYourTeam,
                                        );
                                        return;
                                      }
                                      context
                                          .read<AppointmentsCubit>()
                                          .saveAppointment(
                                            companyId: userProfile.companyId,
                                            operation: 'create',
                                            appointment: appointment,
                                            action: AppointmentAction.create,
                                          );
                                    },
                                  );
                                },
                              )
                            else
                              AppointmentForm(
                                companyId: userProfile.companyId,
                                actorUid: user.uid,
                                assignedTo: user.uid,
                                canEditAssignment: false,
                                relatedRecordsAssignedTo:
                                    role == UserRole.salesAgent ||
                                            role == UserRole.marketing
                                        ? user.uid
                                        : null,
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
                                submitLabel: l.saveAppointment,
                                onSubmit: (appointment) {
                                  context
                                      .read<AppointmentsCubit>()
                                      .saveAppointment(
                                        companyId: userProfile.companyId,
                                        operation: 'create',
                                        appointment: appointment,
                                        action: AppointmentAction.create,
                                      );
                                },
                              ),
                            const SizedBox(height: AppSpacing.md),
                            AppButton(
                              label: l.cancel,
                              variant: AppButtonVariant.secondary,
                              onPressed: isSaving
                                  ? null
                                  : () => context.go(RouteNames.appointments),
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


AppointmentRelatedType? _initialRelatedType(
  Map<String, String> initialValues,
) {
  final value = initialValues['relatedType']?.trim();
  if (value == null || value.isEmpty) {
    return null;
  }
  for (final type in AppointmentRelatedType.values) {
    if (type.name == value) {
      return type;
    }
  }
  return null;
}

String _initialTitle(AppLocalizations l, String? relatedTitle) {
  final title = relatedTitle?.trim() ?? '';
  return title.isEmpty ? '' : '${l.newAppointment}: $title';
}
