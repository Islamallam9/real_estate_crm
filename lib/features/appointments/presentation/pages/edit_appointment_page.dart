import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/protected_company_session.dart';
import '../../../../core/constants/role_constants.dart';
import '../../../../core/errors/error_mapper.dart';
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
import '../../../users/data/datasources/user_profile_remote_data_source.dart';
import '../../../users/data/repositories/user_profile_repository_impl.dart';
import '../../../users/domain/entities/user_profile.dart';
import '../../../users/domain/usecases/watch_active_users_usecase.dart';
import '../../domain/entities/appointment.dart';
import '../cubit/appointments_cubit.dart';
import '../cubit/appointments_state.dart';
import '../widgets/appointment_form.dart';
import '../widgets/appointments_scope.dart';

class EditAppointmentPage extends StatelessWidget {
  const EditAppointmentPage({super.key, required this.appointmentId});

  final String appointmentId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final session = authState.protectedCompanySession;
        return AppointmentsScope(
          key: ValueKey(
            session?.scopeKey('edit-appointment-scope') ??
                'edit-appointment-scope:loading',
          ),
          child: _EditAppointmentView(appointmentId: appointmentId),
        );
      },
    );
  }
}

class _EditAppointmentView extends StatefulWidget {
  const _EditAppointmentView({required this.appointmentId});

  final String appointmentId;

  @override
  State<_EditAppointmentView> createState() => _EditAppointmentViewState();
}

class _EditAppointmentViewState extends State<_EditAppointmentView> {
  bool _isSubmitting = false;
  String? _watchKey;

  void _watchAppointmentWhenReady(ProtectedCompanySession session) {
    if (widget.appointmentId.isEmpty) {
      return;
    }
    final key =
        '${session.scopeKey('edit-appointment-watch')}:${widget.appointmentId}';
    if (_watchKey == key) {
      return;
    }
    _watchKey = key;
    context.read<AppointmentsCubit>().watchAppointment(
          companyId: session.companyId,
          appointmentId: widget.appointmentId,
        );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final authState = context.watch<AuthBloc>().state;
    final session = authState.protectedCompanySession;

    if (authState.isWaitingForProtectedCompanySession) {
      return CrmAppShell(
        selectedItem: CrmNavigationItem.appointments,
        title: l.editAppointment,
        child: const AppLoading(),
      );
    }

    final role = session?.profile.role;
    final companyId = session?.companyId ?? '';
    final uid = session?.uid ?? '';
    final canEditRole = role != null && role != UserRole.viewer;
    if (session != null && canEditRole) {
      _watchAppointmentWhenReady(session);
    }

    return CrmAppShell(
      selectedItem: CrmNavigationItem.appointments,
      title: l.editAppointment,
      child: !canEditRole || companyId.isEmpty || uid.isEmpty
          ? AppErrorView(message: l.permissionDenied)
          : BlocConsumer<AppointmentsCubit, AppointmentsState>(
              listenWhen: (previous, current) =>
                  previous.status != current.status &&
                  (current.status == AppointmentsStatus.saved ||
                      current.status == AppointmentsStatus.failure),
              listener: (context, state) {
                if (state.status == AppointmentsStatus.failure) {
                  setState(() => _isSubmitting = false);
                  AppFeedback.error(
                    context,
                    localizeErrorMessage(l, state.message),
                  );
                  return;
                }
                setState(() => _isSubmitting = false);
                AppFeedback.success(context, l.appointmentUpdated);
                context.go(RouteNames.appointments);
              },
              builder: (context, state) {
                if (state.status == AppointmentsStatus.initial ||
                    (state.status == AppointmentsStatus.loading &&
                        state.selectedAppointment == null)) {
                  return const AppLoading();
                }
                final appointment = state.selectedAppointment;
                if (appointment == null) {
                  return AppErrorView(
                    message: localizeErrorMessage(
                      l,
                      state.message ?? l.appointmentNotFound,
                    ),
                    onRetry: () => context
                        .read<AppointmentsCubit>()
                        .watchAppointment(
                          companyId: companyId,
                          appointmentId: widget.appointmentId,
                        ),
                  );
                }
                if ((role == UserRole.salesAgent ||
                        role == UserRole.marketing) &&
                    appointment.assignedTo != uid) {
                  return AppErrorView(message: l.permissionDenied);
                }
                final managerTeamId = session?.profile.teamId.trim() ?? '';
                if (role == UserRole.manager &&
                    appointment.assignedTo != uid &&
                    appointment.managerId != uid &&
                    (managerTeamId.isEmpty ||
                        appointment.teamId != managerTeamId)) {
                  return AppErrorView(message: l.permissionDenied);
                }

                final isSaving =
                    _isSubmitting || state.status == AppointmentsStatus.saving;
                final canEditAssignment =
                    role == UserRole.admin || role == UserRole.manager;
                return ListView(
                  primary: true,
                  physics: const ClampingScrollPhysics(),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsetsDirectional.only(
                    bottom: AppSpacing.lg,
                  ),
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
                            if (canEditAssignment)
                              StreamBuilder<List<UserProfile>>(
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
                                  return _AppointmentEditorForm(
                                    companyId: companyId,
                                    uid: uid,
                                    role: role,
                                    teamId: session?.profile.teamId ?? '',
                                    appointment: appointment,
                                    users: users,
                                    canEditAssignment: true,
                                    isSaving: isSaving,
                                    onSubmittingChanged: (value) {
                                      setState(() => _isSubmitting = value);
                                    },
                                  );
                                },
                              )
                            else
                              _AppointmentEditorForm(
                                companyId: companyId,
                                uid: uid,
                                role: role,
                                teamId: session?.profile.teamId ?? '',
                                appointment: appointment,
                                users: const [],
                                canEditAssignment: false,
                                isSaving: isSaving,
                                onSubmittingChanged: (value) {
                                  setState(() => _isSubmitting = value);
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

class _AppointmentEditorForm extends StatelessWidget {
  const _AppointmentEditorForm({
    required this.companyId,
    required this.uid,
    required this.role,
    required this.teamId,
    required this.appointment,
    required this.users,
    required this.canEditAssignment,
    required this.isSaving,
    required this.onSubmittingChanged,
  });

  final String companyId;
  final String uid;
  final UserRole? role;
  final String teamId;
  final Appointment appointment;
  final List<UserProfile> users;
  final bool canEditAssignment;
  final bool isSaving;
  final ValueChanged<bool> onSubmittingChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return AppointmentForm(
      companyId: companyId,
      actorUid: uid,
      appointment: appointment,
      users: users,
      canEditAssignment: canEditAssignment,
      canEditStatus: true,
      relatedRecordsAssignedTo:
          role == UserRole.salesAgent || role == UserRole.marketing ? uid : null,
      relatedRecordsManagerId: role == UserRole.manager ? uid : null,
      relatedRecordsTeamId: role == UserRole.manager ? teamId : null,
      isSaving: isSaving,
      submitLabel: l.updateAppointment,
      onSubmit: (updatedAppointment) {
        if (isSaving) {
          return;
        }
        final managerTeamId = teamId.trim();
        if (role == UserRole.manager &&
            updatedAppointment.assignedTo != uid &&
            updatedAppointment.managerId != uid &&
            (managerTeamId.isEmpty ||
                updatedAppointment.teamId != managerTeamId)) {
          AppFeedback.warning(context, l.canOnlyAssignRecordsToYourTeam);
          return;
        }
        onSubmittingChanged(true);
        context.read<AppointmentsCubit>().saveAppointment(
              companyId: companyId,
              operation: 'update',
              appointment: updatedAppointment,
              action: updatedAppointment.scheduledAt != appointment.scheduledAt
                  ? AppointmentAction.reschedule
                  : AppointmentAction.update,
            );
      },
    );
  }
}

Stream<List<UserProfile>> _watchActiveUsers(String companyId) {
  final repository = UserProfileRepositoryImpl(
    remoteDataSource: FirestoreUserProfileRemoteDataSource(),
  );
  return WatchActiveUsersUseCase(repository)(companyId: companyId);
}
