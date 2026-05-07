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
import '../../../../core/widgets/app_loading.dart';
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

class EditClientPage extends StatelessWidget {
  const EditClientPage({super.key, required this.clientId});

  final String clientId;

  @override
  Widget build(BuildContext context) {
    return ClientsScope(child: _EditClientView(clientId: clientId));
  }
}

class _EditClientView extends StatefulWidget {
  const _EditClientView({required this.clientId});

  final String clientId;

  @override
  State<_EditClientView> createState() => _EditClientViewState();
}

class _EditClientViewState extends State<_EditClientView> {
  @override
  void initState() {
    super.initState();
    final companyId = _companyId(context);
    if (companyId.isNotEmpty && widget.clientId.isNotEmpty) {
      context.read<ClientsCubit>().watchClient(
        companyId: companyId,
        clientId: widget.clientId,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final authState = context.read<AuthBloc>().state;
    final role = authState.userProfile?.role ?? authState.user?.role;
    final companyId = _companyId(context);
    final uid = authState.user?.uid ?? '';
    final canEdit =
        role != null && PermissionService.can(role, AppPermission.editClient);

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
                final messenger = ScaffoldMessenger.of(context);
                messenger.hideCurrentSnackBar();
                if (state.status == ClientsStatus.failure) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(localizeErrorMessage(l, state.message)),
                      backgroundColor: AppColors.error,
                    ),
                  );
                  return;
                }
                messenger.showSnackBar(
                  SnackBar(content: Text(l.clientUpdatedSuccessfully)),
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

                final isSaving = state.status == ClientsStatus.saving;
                final canEditAssignment =
                    role == UserRole.admin || role == UserRole.manager;
                final form = canEditAssignment
                    ? StreamBuilder<List<UserProfile>>(
                        stream: _watchActiveUsers(companyId),
                        builder: (context, usersSnapshot) {
                          if (usersSnapshot.hasError) {
                            return AppErrorView(message: l.unableToConnect);
                          }
                          final users = usersSnapshot.data ?? const [];
                          return ClientForm(
                            companyId: companyId,
                            actorUid: uid,
                            client: client,
                            users: users,
                            canEditAssignment: true,
                            isSaving: isSaving,
                            submitLabel: l.updateClient,
                            onSubmit: (updatedClient) {
                              context.read<ClientsCubit>().updateClient(
                                companyId: companyId,
                                client: updatedClient,
                              );
                            },
                          );
                        },
                      )
                    : ClientForm(
                        companyId: companyId,
                        actorUid: uid,
                        client: client,
                        isSaving: isSaving,
                        submitLabel: l.updateClient,
                        onSubmit: (updatedClient) {
                          context.read<ClientsCubit>().updateClient(
                            companyId: companyId,
                            client: updatedClient,
                          );
                        },
                      );
                return Stack(
                  children: [
                    ListView(
                      primary: true,
                      physics: const ClampingScrollPhysics(),
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsetsDirectional.only(
                        bottom: AppSpacing.lg,
                      ),
                      children: [
                        Align(
                          alignment: AlignmentDirectional.topStart,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 760),
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

String _companyId(BuildContext context) {
  final authState = context.read<AuthBloc>().state;
  return authState.userProfile?.companyId ?? authState.user?.companyId ?? '';
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
