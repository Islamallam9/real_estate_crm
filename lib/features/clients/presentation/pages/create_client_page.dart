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
import '../../../../core/widgets/crm_app_shell.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
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
                  SnackBar(content: Text(l.clientCreatedSuccessfully)),
                );
                context.go(RouteNames.clients);
              },
              builder: (context, state) {
                final isSaving = state.status == ClientsStatus.saving;
                return ListView(
                  primary: true,
                  physics: const ClampingScrollPhysics(),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                  children: [
                    Align(
                      alignment: AlignmentDirectional.topStart,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 760),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: TextButton.icon(
                                onPressed: () => context.go(RouteNames.clients),
                                icon: const Icon(Icons.arrow_back),
                                label: Text(l.back),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            ClientForm(
                              companyId: companyId,
                              actorUid: uid,
                              isSaving: isSaving,
                              submitLabel: l.createClient,
                              onSubmit: (client) {
                                context.read<ClientsCubit>().createClient(
                                  companyId: companyId,
                                  client: client,
                                );
                              },
                            ),
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
