import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/protected_company_session.dart';
import '../../../../core/constants/role_constants.dart';
import '../../../../core/errors/error_mapper.dart';
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
import '../../domain/entities/client.dart';
import '../cubit/clients_cubit.dart';
import '../cubit/clients_state.dart';
import '../widgets/client_form.dart';
import '../widgets/clients_scope.dart';

class EditClientPage extends StatelessWidget {
  const EditClientPage({super.key, required this.clientId});

  final String clientId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final session = authState.protectedCompanySession;
        return ClientsScope(
          key: ValueKey(
            session?.scopeKey('edit-client-scope') ??
                'edit-client-scope:loading',
          ),
          child: _EditClientView(clientId: clientId),
        );
      },
    );
  }
}

class _EditClientView extends StatefulWidget {
  const _EditClientView({required this.clientId});

  final String clientId;

  @override
  State<_EditClientView> createState() => _EditClientViewState();
}

class _EditClientViewState extends State<_EditClientView> {
  bool _isSubmitting = false;
  String? _watchKey;

  void _watchClientWhenReady(ProtectedCompanySession session) {
    if (widget.clientId.isEmpty) {
      return;
    }
    final key = '${session.scopeKey('edit-client-watch')}:${widget.clientId}';
    if (_watchKey == key) {
      return;
    }
    _watchKey = key;
    context.read<ClientsCubit>().watchClient(
      companyId: session.companyId,
      clientId: widget.clientId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final authState = context.watch<AuthBloc>().state;
    final session = authState.protectedCompanySession;

    if (authState.isWaitingForProtectedCompanySession) {
      return CrmAppShell(
        selectedItem: CrmNavigationItem.clients,
        title: l.editClient,
        child: const AppLoading(),
      );
    }

    final role = session?.profile.role;
    final companyId = session?.companyId ?? '';
    final uid = session?.uid ?? '';
    final canEdit =
        role != null && PermissionService.can(role, AppPermission.editClient);
    if (session != null && canEdit) {
      _watchClientWhenReady(session);
    }

    return CrmAppShell(
      selectedItem: CrmNavigationItem.clients,
      title: l.editClient,
      child: !canEdit || companyId.isEmpty || uid.isEmpty
          ? AppErrorView(message: l.permissionDenied)
          : BlocConsumer<ClientsCubit, ClientsState>(
              listenWhen: (previous, current) =>
                  previous.status != current.status &&
                  (current.status == ClientsStatus.saved ||
                      current.status == ClientsStatus.failure),
              listener: (context, state) {
          if (state.status == ClientsStatus.failure) {
            setState(() => _isSubmitting = false);
            AppFeedback.error(
              context,
              localizeErrorMessage(l, state.message),
            );
            return;
          }

          setState(() => _isSubmitting = false);
          AppFeedback.success(
            context,
            l.clientUpdatedSuccessfully,
          );
          context.go(RouteNames.clientDetails(widget.clientId));
        },
              builder: (context, state) {
                if (state.status == ClientsStatus.initial ||
                    (state.status == ClientsStatus.loading &&
                        state.selectedClient == null)) {
                  return const AppLoading();
                }

                final client = state.selectedClient;
                if (client == null) {
                  return AppErrorView(
                    message: localizationsErrorFallback(
                      l,
                      state.message,
                      l.clientNotFoundMessage,
                    ),
                    onRetry: () {
                      context.read<ClientsCubit>().watchClient(
                        companyId: companyId,
                        clientId: widget.clientId,
                      );
                    },
                  );
                }

                if (role == UserRole.salesAgent && client.assignedTo != uid) {
                  return AppErrorView(message: l.permissionDenied);
                }
                final managerTeamId = session?.profile.teamId ?? '';
                if (role == UserRole.manager &&
                    !_clientInManagerScope(
                      client,
                      currentUserId: uid,
                      currentTeamId: managerTeamId,
                    )) {
                  return AppErrorView(message: l.permissionDenied);
                }

                final isSaving = _isSubmitting || state.status == ClientsStatus.saving;
                final form = ClientForm(
                  companyId: companyId,
                  actorUid: uid,
                  client: client,
                  isSaving: isSaving,
                  submitLabel: l.updateClient,
                  onSubmit: (updatedClient) {
                    if (_isSubmitting) {
                      return;
                    }
                    final scopeLabel = _safeEditScopeLabel(
                      client,
                      currentUserId: uid,
                      currentTeamId: managerTeamId,
                    );
                    debugPrint(
                      'MasarDebug feature=clients operation=updateClient '
                      'role=${RoleConstants.toValue(role!)} '
                      'scope=$scopeLabel '
                      'fields=detailsOnly',
                    );
                    setState(() => _isSubmitting = true);
                    context.read<ClientsCubit>().updateClient(
                      companyId: companyId,
                      client: updatedClient,
                    );
                  },
                );
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
                            constraints: const BoxConstraints(maxWidth: 860),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                form,
                                const SizedBox(height: AppSpacing.md),
                                AppButton(
                                  label: l.cancel,
                                  onPressed: isSaving
                                      ? null
                                      : () => context.go(
                                          RouteNames.clientDetails(client.id),
                                        ),
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

bool _clientInManagerScope(
  Client client, {
  required String currentUserId,
  required String currentTeamId,
}) {
  final normalizedTeamId = currentTeamId.trim();
  return client.assignedTo.trim() == currentUserId ||
      client.managerId.trim() == currentUserId ||
      (normalizedTeamId.isNotEmpty &&
          client.teamId.trim() == normalizedTeamId);
}

String _safeEditScopeLabel(
  Client client, {
  required String currentUserId,
  required String currentTeamId,
}) {
  final normalizedTeamId = currentTeamId.trim();
  if (client.assignedTo.trim() == currentUserId) {
    return 'self-assigned';
  }
  if (client.managerId.trim() == currentUserId) {
    return 'manager';
  }
  if (normalizedTeamId.isNotEmpty && client.teamId.trim() == normalizedTeamId) {
    return 'team';
  }
  return 'out-of-scope';
}

String localizationsErrorFallback(
  AppLocalizations localizations,
  String? message,
  String fallback,
) {
  if (message == null || message.trim().isEmpty) {
    return fallback;
  }
  return localizeErrorMessage(localizations, message);
}
