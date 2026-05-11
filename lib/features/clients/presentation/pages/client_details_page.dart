import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

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
import '../../domain/entities/client.dart';
import '../cubit/clients_cubit.dart';
import '../cubit/clients_state.dart';
import '../widgets/clients_scope.dart';

class ClientDetailsPage extends StatelessWidget {
  const ClientDetailsPage({super.key, required this.clientId});

  final String clientId;

  @override
  Widget build(BuildContext context) {
    return ClientsScope(child: _ClientDetailsView(clientId: clientId));
  }
}

class _ClientDetailsView extends StatefulWidget {
  const _ClientDetailsView({required this.clientId});

  final String clientId;

  @override
  State<_ClientDetailsView> createState() => _ClientDetailsViewState();
}

class _ClientDetailsViewState extends State<_ClientDetailsView> {
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
    final uid = authState.user?.uid ?? '';
    final companyId = _companyId(context);
    final canView =
        role != null && PermissionService.can(role, AppPermission.viewClients);
    final canEdit =
        role != null && PermissionService.can(role, AppPermission.editClient);

    return CrmAppShell(
      selectedItem: CrmNavigationItem.clients,
      title: l.clientDetails,
      child: !canView || companyId.isEmpty || widget.clientId.isEmpty
          ? AppErrorView(message: l.permissionDenied)
          : BlocBuilder<ClientsCubit, ClientsState>(
              builder: (context, state) {
                if (state.status == ClientsStatus.initial ||
                    (state.status == ClientsStatus.loading &&
                        state.selectedClient == null)) {
                  return const AppLoading();
                }

                if (state.status == ClientsStatus.failure &&
                    state.selectedClient == null) {
                  return AppErrorView(
                    message: localizeErrorMessage(l, state.message),
                    onRetry: () {
                      context.read<ClientsCubit>().watchClient(
                        companyId: companyId,
                        clientId: widget.clientId,
                      );
                    },
                  );
                }

                final client = state.selectedClient;
                if (client == null) {
                  return AppErrorView(
                    message: l.clientNotFoundMessage,
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

                return Stack(
                  children: [
                    ListView(
                      primary: true,
                      physics: const ClampingScrollPhysics(),
                      padding: const EdgeInsetsDirectional.only(
                        bottom: AppSpacing.lg,
                      ),
                      children: [
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 900),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _valueOrNotAvailable(l, client.fullName),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Wrap(
                                spacing: AppSpacing.sm,
                                runSpacing: AppSpacing.sm,
                                children: [
                                  AppButton(
                                    label: l.backToClients,
                                    variant: AppButtonVariant.secondary,
                                    onPressed: () =>
                                        context.go(RouteNames.clients),
                                  ),
                                  if (canEdit)
                                    AppButton(
                                      label: l.editClient,
                                      onPressed: () => context.go(
                                        RouteNames.clientEdit(client.id),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              _DetailsSection(
                                title: l.contactInformation,
                                children: [
                                  _detail(
                                    context,
                                    l.fullNameUpdated,
                                    _valueOrNotAvailable(l, client.fullName),
                                  ),
                                  _detail(
                                    context,
                                    l.phone,
                                    _valueOrNotAvailable(l, client.phone),
                                  ),
                                  _detail(
                                    context,
                                    l.email,
                                    _valueOrNotAvailable(l, client.email),
                                  ),
                                  _detail(
                                    context,
                                    l.assignedToLabel,
                                    _assigneeDisplayLabel(l, client),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.md),
                              _DetailsSection(
                                title: l.clientPreferences,
                                children: [
                                  _detail(
                                    context,
                                    l.budgetMin,
                                    _formatOptionalNumber(
                                      context,
                                      l,
                                      client.budgetMin,
                                    ),
                                  ),
                                  _detail(
                                    context,
                                    l.budgetMax,
                                    _formatOptionalNumber(
                                      context,
                                      l,
                                      client.budgetMax,
                                    ),
                                  ),
                                  _detail(
                                    context,
                                    l.preferredLocation,
                                    _valueOrNotAvailable(
                                      l,
                                      client.preferredLocation,
                                    ),
                                  ),
                                  _detail(
                                    context,
                                    l.preferredPropertyType,
                                    _valueOrNotAvailable(
                                      l,
                                      client.preferredPropertyType,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.md),
                              _DetailsSection(
                                title: l.notes,
                                children: [
                                  _detail(
                                    context,
                                    l.notes,
                                    _valueOrNotAvailable(l, client.notes),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.md),
                              _DetailsSection(
                                title: l.auditInfo,
                                children: [
                                  _detail(
                                    context,
                                    l.createdAt,
                                    _formatOptionalDate(
                                      context,
                                      l,
                                      client.createdAt,
                                    ),
                                  ),
                                  _detail(
                                    context,
                                    l.updatedAt,
                                    _formatOptionalDate(
                                      context,
                                      l,
                                      client.updatedAt,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (state.status == ClientsStatus.loading)
                      Positioned.fill(
                        child: AbsorbPointer(
                          child: Container(
                            color: AppColors.appBackground(
                              context,
                            ).withValues(alpha: 0.55),
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

class _DetailsSection extends StatelessWidget {
  const _DetailsSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.cardSurface(context),
        border: Border.all(color: AppColors.borderColor(context)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.md),
          ...children,
        ],
      ),
    );
  }
}

Widget _detail(BuildContext context, String label, String value) {
  return Padding(
    padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.md),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          maxLines: 4,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.start,
        ),
      ],
    ),
  );
}

String _companyId(BuildContext context) {
  final authState = context.read<AuthBloc>().state;
  return authState.userProfile?.companyId ?? authState.user?.companyId ?? '';
}

String _valueOrNotAvailable(AppLocalizations l, String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? l.notAvailable : trimmed;
}

String _assigneeDisplayLabel(AppLocalizations l, Client client) {
  final assignedTo = client.assignedTo.trim();
  if (assignedTo.isEmpty) {
    return l.unassigned;
  }
  final name = client.assignedToName.trim();
  if (name.isNotEmpty) {
    return name;
  }
  final email = client.assignedToEmail.trim();
  if (email.isNotEmpty) {
    return email;
  }
  return l.assignedUserUnavailable;
}

String _formatOptionalDate(
  BuildContext context,
  AppLocalizations l,
  DateTime? value,
) {
  if (value == null) {
    return l.notAvailable;
  }
  final localeName = Localizations.localeOf(context).toString();
  return DateFormat.yMd(localeName).add_jm().format(value.toLocal());
}

String _formatOptionalNumber(
  BuildContext context,
  AppLocalizations l,
  num? value,
) {
  if (value == null) {
    return l.notAvailable;
  }
  final localeName = Localizations.localeOf(context).toString();
  return NumberFormat.decimalPattern(localeName).format(value);
}
