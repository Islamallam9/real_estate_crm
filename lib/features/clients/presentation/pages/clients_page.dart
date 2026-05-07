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
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/crm_app_shell.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../domain/entities/client.dart';
import '../cubit/clients_cubit.dart';
import '../cubit/clients_state.dart';
import '../widgets/clients_scope.dart';

class ClientsPage extends StatelessWidget {
  const ClientsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    if (localizations == null) {
      return const SizedBox.shrink();
    }

    return CrmAppShell(
      selectedItem: CrmNavigationItem.clients,
      title: localizations.clients,
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          if (authState.status == AuthStatus.initial ||
              authState.status == AuthStatus.loading) {
            return const AppLoading();
          }

          final companyId =
              authState.userProfile?.companyId ??
              authState.user?.companyId ??
              '';
          if (companyId.isEmpty) {
            return AppErrorView(message: localizations.missingCompanyProfile);
          }

          final role = authState.userProfile?.role ?? authState.user?.role;
          final canView = role != null
              ? PermissionService.can(role, AppPermission.viewClients)
              : false;
          if (!canView) {
            return AppErrorView(message: localizations.permissionDenied);
          }
          final canCreate = PermissionService.can(
            role,
            AppPermission.createClient,
          );

          final canEdit = PermissionService.can(
            role,
            AppPermission.editClient,
          );

          final canArchive = PermissionService.can(
            role,
            AppPermission.archiveClient,
          );

          if (role == UserRole.salesAgent && (authState.user?.uid.isEmpty ?? true)) {
            return AppErrorView(message: localizations.permissionDenied);
          }

          final assignedTo = role == UserRole.salesAgent
              ? authState.user!.uid
              : null;

          return ClientsScope(
            child: _ClientsListContent(
              companyId: companyId,
              assignedTo: assignedTo,
              canCreate: canCreate,
              canEdit: canEdit,
              canArchive: canArchive,
              uid: authState.user?.uid ?? '',
            ),
          );
        },
      ),
    );
  }
}

class _ClientsListContent extends StatefulWidget {
  const _ClientsListContent({
    required this.companyId,
    required this.canCreate,
    required this.canEdit,
    required this.canArchive,
    required this.uid,
    this.assignedTo,
  });

  final String companyId;
  final String? assignedTo;
  final bool canCreate;
  final bool canEdit;
  final bool canArchive;
  final String uid;

  @override
  State<_ClientsListContent> createState() => _ClientsListContentState();
}

class _ClientsListContentState extends State<_ClientsListContent> {
  @override
  void initState() {
    super.initState();
    context.read<ClientsCubit>().watchClients(
      companyId: widget.companyId,
      assignedTo: widget.assignedTo,
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    if (localizations == null) {
      return const SizedBox.shrink();
    }

    return BlocListener<ClientsCubit, ClientsState>(
      listenWhen: (previous, current) =>
          previous.status != current.status ||
          previous.lastAction != current.lastAction ||
          previous.message != current.message,
      listener: (context, state) {
        if (state.status == ClientsStatus.saved &&
            state.lastAction == ClientsAction.archiveClient) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(localizations.clientArchivedSuccessfully)),
          );
          context.read<ClientsCubit>().clearAction();
          return;
        }
        if (state.status == ClientsStatus.failure &&
            state.lastAction == ClientsAction.archiveClient &&
            (state.message?.isNotEmpty ?? false)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(localizeErrorMessage(localizations, state.message)),
            ),
          );
          context.read<ClientsCubit>().clearAction();
        }
      },
      child: BlocBuilder<ClientsCubit, ClientsState>(
        builder: (context, state) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                localizations.clients,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondaryColor(context),
                ),
              ),
              if (widget.canCreate) ...[
                const SizedBox(height: AppSpacing.md),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: AppButton(
                    label: localizations.createClient,
                    onPressed: () => context.go(RouteNames.clientsCreate),
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              TextField(
                onChanged: context.read<ClientsCubit>().setSearchQuery,
                decoration: InputDecoration(
                  labelText: localizations.searchCrm,
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: _ClientsBody(
                  companyId: widget.companyId,
                  assignedTo: widget.assignedTo,
                  state: state,
                  canEdit: widget.canEdit,
                  canArchive: widget.canArchive,
                  uid: widget.uid,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ClientsBody extends StatelessWidget {
  const _ClientsBody({
    required this.companyId,
    required this.state,
    required this.canEdit,
    required this.canArchive,
    required this.uid,
    this.assignedTo,
  });

  final String companyId;
  final String? assignedTo;
  final ClientsState state;
  final bool canEdit;
  final bool canArchive;
  final String uid;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    if ((state.status == ClientsStatus.initial ||
            state.status == ClientsStatus.loading) &&
        state.clients.isEmpty) {
      return const AppLoading();
    }

    if (state.status == ClientsStatus.failure && state.clients.isEmpty) {
      return AppErrorView(
        message: localizeErrorMessage(localizations, state.message),
        onRetry: () {
          context.read<ClientsCubit>().watchClients(
            companyId: companyId,
            assignedTo: assignedTo,
          );
        },
      );
    }

    if (state.clients.isEmpty) {
      return AppEmptyState(
        title: localizations.noData,
        message: localizations.noData,
        icon: Icons.person_outline,
      );
    }

    if (state.filteredClients.isEmpty) {
      return AppEmptyState(
        title: localizations.noData,
        message: localizations.noData,
        icon: Icons.search_off_outlined,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 720) {
          return ListView.separated(
            itemCount: state.filteredClients.length,
            separatorBuilder: (context, index) =>
                const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              return _ClientCard(
                client: state.filteredClients[index],
                canEdit: canEdit,
                canArchive: canArchive,
                onArchive: (client) => _confirmArchive(
                  context,
                  client: client,
                  companyId: companyId,
                  updatedBy: uid,
                ),
              );
            },
          );
        }

        return _ClientsTable(
          clients: state.filteredClients,
          canEdit: canEdit,
          canArchive: canArchive,
          onArchive: (client) => _confirmArchive(
            context,
            client: client,
            companyId: companyId,
            updatedBy: uid,
          ),
        );
      },
    );
  }
}

class _ClientCard extends StatelessWidget {
  const _ClientCard({
    required this.client,
    required this.canEdit,
    required this.canArchive,
    required this.onArchive,
  });

  final Client client;
  final bool canEdit;
  final bool canArchive;
  final ValueChanged<Client> onArchive;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _fallback(client.fullName, l.notAvailable),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            _ClientInfoLine(icon: Icons.phone_outlined, text: client.phone),
            const SizedBox(height: AppSpacing.xs),
            _ClientInfoLine(icon: Icons.email_outlined, text: client.email),
            const SizedBox(height: AppSpacing.xs),
            _ClientInfoLine(
              icon: Icons.location_on_outlined,
              text: client.preferredLocation,
            ),
            if (canEdit || canArchive) ...[
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  if (canEdit)
                    IconButton(
                      tooltip: l.editClient,
                      onPressed: () =>
                          context.go(RouteNames.clientEdit(client.id)),
                      icon: const Icon(Icons.edit_outlined, size: 18),
                    ),
                  if (canArchive)
                    IconButton(
                      tooltip: l.archiveClient,
                      onPressed: () => onArchive(client),
                      icon: const Icon(Icons.archive_outlined, size: 18),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ClientInfoLine extends StatelessWidget {
  const _ClientInfoLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: AppColors.textSecondaryColor(context),
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            _fallback(text, l.notAvailable),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondaryColor(context),
            ),
          ),
        ),
      ],
    );
  }
}

class _ClientsTable extends StatelessWidget {
  const _ClientsTable({
    required this.clients,
    required this.canEdit,
    required this.canArchive,
    required this.onArchive,
  });

  final List<Client> clients;
  final bool canEdit;
  final bool canArchive;
  final ValueChanged<Client> onArchive;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.cardSurface(context),
        border: Border.all(color: AppColors.borderColor(context)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          _ClientsTableHeader(
            localizations: l,
            canEdit: canEdit,
            canArchive: canArchive,
          ),
          Divider(height: 1, color: AppColors.borderColor(context)),
          Expanded(
            child: ListView.separated(
              itemCount: clients.length,
              separatorBuilder: (context, index) =>
                  Divider(height: 1, color: AppColors.borderColor(context)),
              itemBuilder: (context, index) {
                return _ClientsTableRow(
                  client: clients[index],
                  canEdit: canEdit,
                  canArchive: canArchive,
                  onArchive: onArchive,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ClientsTableHeader extends StatelessWidget {
  const _ClientsTableHeader({
    required this.localizations,
    required this.canEdit,
    required this.canArchive,
  });

  final AppLocalizations localizations;
  final bool canEdit;
  final bool canArchive;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          _TableHeaderText(localizations.fullNameUpdated, flex: 3),
          _TableHeaderText(localizations.phone, flex: 2),
          _TableHeaderText(localizations.email, flex: 3),
          _TableHeaderText(localizations.preferredLocation, flex: 3),
          _TableHeaderText(localizations.preferredPropertyType, flex: 3),
          _TableHeaderText(
            localizations.actions,
            flex: (canEdit || canArchive) ? 2 : 1,
          ),
        ],
      ),
    );
  }
}

class _ClientsTableRow extends StatelessWidget {
  const _ClientsTableRow({
    required this.client,
    required this.canEdit,
    required this.canArchive,
    required this.onArchive,
  });

  final Client client;
  final bool canEdit;
  final bool canArchive;
  final ValueChanged<Client> onArchive;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          _TableBodyText(_fallback(client.fullName, l.notAvailable), flex: 3),
          _TableBodyText(_fallback(client.phone, l.notAvailable), flex: 2),
          _TableBodyText(_fallback(client.email, l.notAvailable), flex: 3),
          _TableBodyText(
            _fallback(client.preferredLocation, l.notAvailable),
            flex: 3,
          ),
          _TableBodyText(
            _fallback(client.preferredPropertyType, l.notAvailable),
            flex: 3,
          ),
          Expanded(
            flex: (canEdit || canArchive) ? 2 : 1,
            child: Wrap(
              spacing: 4,
              children: [
                if (canEdit)
                  IconButton(
                    tooltip: l.editClient,
                    onPressed: () => context.go(RouteNames.clientEdit(client.id)),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                  ),
                if (canArchive)
                  IconButton(
                    tooltip: l.archiveClient,
                    onPressed: () => onArchive(client),
                    icon: const Icon(Icons.archive_outlined, size: 18),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _confirmArchive(
  BuildContext context, {
  required Client client,
  required String companyId,
  required String updatedBy,
}) async {
  final l = AppLocalizations.of(context)!;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(l.archiveClient),
        content: Text(l.archiveClientConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l.cancel),
          ),
          AppButton(
            label: l.archive,
            onPressed: () => Navigator.of(dialogContext).pop(true),
          ),
        ],
      );
    },
  );
  if (confirmed != true) {
    return;
  }
  if (!context.mounted) {
    return;
  }
  await context.read<ClientsCubit>().archiveClient(
    companyId: companyId,
    clientId: client.id,
    updatedBy: updatedBy,
  );
}

class _TableHeaderText extends StatelessWidget {
  const _TableHeaderText(this.value, {required this.flex});

  final String value;
  final int flex;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsetsDirectional.only(end: AppSpacing.sm),
        child: Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          softWrap: false,
          textAlign: TextAlign.start,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: AppColors.textSecondaryColor(context),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _TableBodyText extends StatelessWidget {
  const _TableBodyText(this.value, {required this.flex});

  final String value;
  final int flex;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsetsDirectional.only(end: AppSpacing.sm),
        child: Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          softWrap: false,
          textAlign: TextAlign.start,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}

String _fallback(String value, String fallback) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? fallback : trimmed;
}
