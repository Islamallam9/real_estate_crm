import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/role_constants.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/permissions/app_permission.dart';
import '../../../../core/permissions/permission_service.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_empty_state.dart';
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
import '../../domain/entities/client.dart';
import '../cubit/clients_cubit.dart';
import '../cubit/clients_state.dart';
import '../widgets/client_assignment_dropdown.dart';
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

          if ((role == UserRole.manager ||
                  role == UserRole.salesAgent ||
                  role == UserRole.viewer) &&
              (authState.user?.uid.isEmpty ?? true)) {
            return AppErrorView(message: localizations.permissionDenied);
          }

          final assignedTo = role == UserRole.salesAgent ||
                  role == UserRole.viewer
              ? authState.user!.uid
              : null;
          final managerId = role == UserRole.manager
              ? authState.user!.uid
              : null;

          return ClientsScope(
            child: _ClientsListContent(
              companyId: companyId,
              assignedTo: assignedTo,
              managerId: managerId,
              canCreate: canCreate,
              canEdit: canEdit,
              canArchive: canArchive,
              canAssign: role == UserRole.admin || role == UserRole.manager,
              showAssigneeFilter: role == UserRole.admin,
              uid: authState.user?.uid ?? '',
              isSalesAgentView: role == UserRole.salesAgent,
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
    required this.canAssign,
    required this.showAssigneeFilter,
    required this.uid,
    required this.isSalesAgentView,
    this.assignedTo,
    this.managerId,
  });

  final String companyId;
  final String? assignedTo;
  final String? managerId;
  final bool canCreate;
  final bool canEdit;
  final bool canArchive;
  final bool canAssign;
  final bool showAssigneeFilter;
  final String uid;
  final bool isSalesAgentView;

  @override
  State<_ClientsListContent> createState() => _ClientsListContentState();
}

class _ClientsListContentState extends State<_ClientsListContent> {
  @override
  void initState() {
    super.initState();
    _watchScopedClients();
  }

  @override
  void didUpdateWidget(covariant _ClientsListContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.companyId != widget.companyId ||
        oldWidget.assignedTo != widget.assignedTo ||
        oldWidget.managerId != widget.managerId) {
      _watchScopedClients();
    }
  }

  void _watchScopedClients() {
    context.read<ClientsCubit>().watchClients(
      companyId: widget.companyId,
      assignedTo: widget.assignedTo,
      managerId: widget.managerId,
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
            state.lastAction == ClientsAction.assignClient) {
          AppFeedback.success(
            context,
            localizations.clientAssignedSuccessfully,
          );
          context.read<ClientsCubit>().clearAction();
          return;
        }
        if (state.status == ClientsStatus.saved &&
            state.lastAction == ClientsAction.archiveClient) {
          AppFeedback.success(
            context,
            localizations.clientArchivedSuccessfully,
          );
          context.read<ClientsCubit>().clearAction();
          return;
        }
        if (state.status == ClientsStatus.failure &&
            (state.lastAction == ClientsAction.archiveClient ||
                state.lastAction == ClientsAction.assignClient) &&
            (state.message?.isNotEmpty ?? false)) {
          AppFeedback.error(
            context,
            localizeErrorMessage(localizations, state.message),
          );
          context.read<ClientsCubit>().clearAction();
        }
      },
      child: BlocBuilder<ClientsCubit, ClientsState>(
        builder: (context, state) {
          return StreamBuilder<List<UserProfile>>(
            stream: (widget.canAssign || widget.showAssigneeFilter)
                ? _watchActiveUsers(widget.companyId)
                : null,
            builder: (context, usersSnapshot) {
              if (usersSnapshot.hasError) {
                return AppErrorView(
                  message: localizeThrownErrorMessage(
                    localizations,
                    usersSnapshot.error,
                  ),
                );
              }
              final users = usersSnapshot.data ?? const [];

              return LayoutBuilder(
                builder: (context, constraints) {
                  final isMobile = constraints.maxWidth < 720;

                  final header = Row(
                    children: [
                      Expanded(
                        child: Text(
                          localizations.clientsSubtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondaryColor(context),
                          ),
                        ),
                      ),
                      if (widget.canCreate) ...[
                        const SizedBox(width: AppSpacing.md),
                        AppButton(
                          label: localizations.createClient,
                          onPressed: () => context.go(RouteNames.clientsCreate),
                        ),
                      ],
                    ],
                  );

                  final filters = _ClientsFilters(
                    state: state,
                    users: users,
                    showAssigneeFilter: widget.showAssigneeFilter,
                  );

                  final body = _ClientsBody(
                    companyId: widget.companyId,
                    assignedTo: widget.assignedTo,
                    managerId: widget.managerId,
                    state: state,
                    canEdit: widget.canEdit,
                    canArchive: widget.canArchive,
                    canAssign: widget.canAssign,
                    uid: widget.uid,
                    users: users,
                    isSalesAgentView: widget.isSalesAgentView,
                  );

                  if (isMobile) {
                    return SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          header,
                          const SizedBox(height: AppSpacing.sm),
                          filters,
                          const SizedBox(height: AppSpacing.sm),
                          body,
                          const SizedBox(height: 96),
                        ],
                      ),
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      header,
                      const SizedBox(height: AppSpacing.sm),
                      filters,
                      const SizedBox(height: AppSpacing.sm),
                      Expanded(child: body),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _ClientsFilters extends StatelessWidget {
  const _ClientsFilters({
    required this.state,
    required this.users,
    required this.showAssigneeFilter,
  });

  final ClientsState state;
  final List<UserProfile> users;
  final bool showAssigneeFilter;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cubit = context.read<ClientsCubit>();
    final hasFilters = state.assignedToFilter != null;

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 720) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _ClientsSearchField(onChanged: cubit.setSearchQuery),
                  ),
                  if (showAssigneeFilter) ...[
                    const SizedBox(width: AppSpacing.sm),
                    AppButton(
                      label: l.filters,
                      icon: Icons.tune,
                      variant: AppButtonVariant.secondary,
                      onPressed: () => _showClientsFiltersSheet(
                        context,
                        state: state,
                        users: users,
                      ),
                    ),
                  ],
                ],
              ),
              _ClientsActiveFilterChips(state: state, users: users),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: _ClientsSearchField(onChanged: cubit.setSearchQuery),
                ),
                if (showAssigneeFilter) ...[
                  const SizedBox(width: AppSpacing.sm),
                  AppButton(
                    label: l.filters,
                    icon: Icons.tune,
                    variant: AppButtonVariant.secondary,
                    onPressed: () => _showClientsFiltersSheet(
                      context,
                      state: state,
                      users: users,
                    ),
                  ),
                ],
                if (hasFilters) ...[
                  const SizedBox(width: AppSpacing.sm),
                  AppButton(
                    label: l.clearFilters,
                    icon: Icons.filter_alt_off_outlined,
                    variant: AppButtonVariant.secondary,
                    onPressed: () => cubit.setAssignedToFilter(null),
                  ),
                ],
              ],
            ),
            _ClientsActiveFilterChips(state: state, users: users),
          ],
        );
      },
    );
  }
}

class _ClientsSearchField extends StatelessWidget {
  const _ClientsSearchField({required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return TextField(
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: l.searchClients,
        prefixIcon: const Icon(Icons.search),
      ),
    );
  }
}

class _ClientsActiveFilterChips extends StatelessWidget {
  const _ClientsActiveFilterChips({required this.state, required this.users});

  final ClientsState state;
  final List<UserProfile> users;

  @override
  Widget build(BuildContext context) {
    final assignedTo = state.assignedToFilter;
    if (assignedTo == null) {
      return const SizedBox.shrink();
    }

    final l = AppLocalizations.of(context)!;
    final user = _userById(users, assignedTo);
    final name = user?.fullName.trim() ?? '';
    final email = user?.email.trim() ?? '';
    final label = name.isNotEmpty
        ? name
        : email.isNotEmpty
            ? email
            : l.assignee;

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Wrap(
        spacing: AppSpacing.xs,
        runSpacing: AppSpacing.xs,
        children: [
          _ActiveFilterChip(
            label: label,
            onDeleted: () => context.read<ClientsCubit>().setAssignedToFilter(null),
          ),
        ],
      ),
    );
  }
}

class _ActiveFilterChip extends StatelessWidget {
  const _ActiveFilterChip({required this.label, required this.onDeleted});

  final String label;
  final VoidCallback onDeleted;

  @override
  Widget build(BuildContext context) {
    return InputChip(
      label: Text(label),
      onDeleted: onDeleted,
      deleteIcon: const Icon(Icons.close, size: 16),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: AppColors.textPrimaryColor(context),
            fontWeight: FontWeight.w700,
          ),
      backgroundColor: AppColors.primaryColor(context).withValues(alpha: 0.08),
      side: BorderSide(
        color: AppColors.primaryColor(context).withValues(alpha: 0.18),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
    );
  }
}

Future<void> _showClientsFiltersSheet(
  BuildContext context, {
  required ClientsState state,
  required List<UserProfile> users,
}) async {
  final l = AppLocalizations.of(context)!;
  final cubit = context.read<ClientsCubit>();

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) {
      return BlocProvider.value(
        value: cubit,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.lg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l.filters,
                        style: Theme.of(sheetContext).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(sheetContext).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                ClientAssignmentDropdown(
                  label: l.assignee,
                  users: users,
                  value: state.assignedToFilter,
                  includeAllOption: true,
                  onChanged: cubit.setAssignedToFilter,
                ),
                const SizedBox(height: AppSpacing.md),
                AppButton(
                  label: l.clearFilters,
                  variant: AppButtonVariant.secondary,
                  onPressed: () {
                    cubit.setAssignedToFilter(null);
                    Navigator.of(sheetContext).pop();
                  },
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _ClientsBody extends StatelessWidget {
  const _ClientsBody({
    required this.companyId,
    required this.state,
    required this.canEdit,
    required this.canArchive,
    required this.canAssign,
    required this.uid,
    required this.users,
    required this.isSalesAgentView,
    this.assignedTo,
    this.managerId,
  });

  final String companyId;
  final String? assignedTo;
  final String? managerId;
  final ClientsState state;
  final bool canEdit;
  final bool canArchive;
  final bool canAssign;
  final String uid;
  final List<UserProfile> users;
  final bool isSalesAgentView;

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
            managerId: managerId,
          );
        },
      );
    }

    if (state.clients.isEmpty) {
      return AppEmptyState(
        title: isSalesAgentView
            ? localizations.noAssignedClientsFound
            : localizations.noClientsFound,
        message: isSalesAgentView
            ? localizations.noAssignedClientsFound
            : localizations.noClientsFound,
        icon: Icons.person_outline,
      );
    }

    if (state.filteredClients.isEmpty) {
      return AppEmptyState(
        title: localizations.noClientsFound,
        message: localizations.noClientsFound,
        icon: Icons.search_off_outlined,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 720) {
          return Column(
            children: [
              for (var index = 0; index < state.filteredClients.length; index++) ...[
                _ClientCard(
                  client: state.filteredClients[index],
                  canEdit: canEdit,
                  canArchive: canArchive,
                  canAssign: canAssign,
                  users: users,
                  companyId: companyId,
                  updatedBy: uid,
                  onArchive: (client) => _confirmArchive(
                    context,
                    client: client,
                    companyId: companyId,
                    updatedBy: uid,
                  ),
                ),
                if (index != state.filteredClients.length - 1)
                  const SizedBox(height: AppSpacing.sm),
              ],
            ],
          );
        }

        return Align(
          alignment: AlignmentDirectional.topStart,
          child: SizedBox(
            height: _tableHeightForRows(state.filteredClients.length),
            child: _ClientsTable(
              clients: state.filteredClients,
              canEdit: canEdit,
              canArchive: canArchive,
              canAssign: canAssign,
              users: users,
              companyId: companyId,
              updatedBy: uid,
              onArchive: (client) => _confirmArchive(
                context,
                client: client,
                companyId: companyId,
                updatedBy: uid,
              ),
            ),
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
    required this.canAssign,
    required this.users,
    required this.companyId,
    required this.updatedBy,
    required this.onArchive,
  });

  final Client client;
  final bool canEdit;
  final bool canArchive;
  final bool canAssign;
  final List<UserProfile> users;
  final String companyId;
  final String updatedBy;
  final ValueChanged<Client> onArchive;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Material(
      color: AppColors.cardSurface(context),
      borderRadius: AppRadius.large,
      child: InkWell(
        onTap: () => context.go(RouteNames.clientDetails(client.id)),
        borderRadius: AppRadius.large,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.borderColor(context)),
            borderRadius: AppRadius.large,
            boxShadow: Theme.of(context).brightness == Brightness.dark
                ? null
                : AppShadows.card,
          ),
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
              if (canEdit || canAssign || canArchive) ...[
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
                    if (canAssign)
                      IconButton(
                        tooltip: l.assignClient,
                        onPressed: () => _showAssignClientSheet(
                          context,
                          client: client,
                          companyId: companyId,
                          updatedBy: updatedBy,
                          users: users,
                        ),
                        icon: const Icon(Icons.person_add_alt_outlined, size: 18),
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
    required this.canAssign,
    required this.users,
    required this.companyId,
    required this.updatedBy,
    required this.onArchive,
  });

  final List<Client> clients;
  final bool canEdit;
  final bool canArchive;
  final bool canAssign;
  final List<UserProfile> users;
  final String companyId;
  final String updatedBy;
  final ValueChanged<Client> onArchive;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.cardSurface(context),
        border: Border.all(color: AppColors.borderColor(context)),
        borderRadius: AppRadius.large,
        boxShadow: Theme.of(context).brightness == Brightness.dark
            ? null
            : AppShadows.card,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _ClientsTableHeader(
            localizations: l,
            canEdit: canEdit,
            canArchive: canArchive,
            canAssign: canAssign,
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
                  canAssign: canAssign,
                  users: users,
                  companyId: companyId,
                  updatedBy: updatedBy,
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
    required this.canAssign,
  });

  final AppLocalizations localizations;
  final bool canEdit;
  final bool canArchive;
  final bool canAssign;

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
            flex: (canEdit || canAssign || canArchive) ? 2 : 1,
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
    required this.canAssign,
    required this.users,
    required this.companyId,
    required this.updatedBy,
    required this.onArchive,
  });

  final Client client;
  final bool canEdit;
  final bool canArchive;
  final bool canAssign;
  final List<UserProfile> users;
  final String companyId;
  final String updatedBy;
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
            flex: (canEdit || canAssign || canArchive) ? 2 : 1,
            child: Wrap(
              spacing: 4,
              children: [
                if (canEdit)
                  IconButton(
                    tooltip: l.editClient,
                    onPressed: () => context.go(RouteNames.clientEdit(client.id)),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                  ),
                if (canAssign)
                  IconButton(
                    tooltip: l.assignClient,
                    onPressed: () => _showAssignClientSheet(
                      context,
                      client: client,
                      companyId: companyId,
                      updatedBy: updatedBy,
                      users: users,
                    ),
                    icon: const Icon(Icons.person_add_alt_outlined, size: 18),
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
  final cubit = context.read<ClientsCubit>();
  var isSubmitting = false;

  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(l.archiveClient),
            content: Text(l.archiveClientConfirmation),
            actions: [
              TextButton(
                onPressed: isSubmitting
                    ? null
                    : () => Navigator.of(dialogContext).pop(),
                child: Text(l.cancel),
              ),
              AppButton(
                label: l.archive,
                isLoading: isSubmitting,
                onPressed: () async {
                  setDialogState(() => isSubmitting = true);
                  await cubit.archiveClient(
                    companyId: companyId,
                    clientId: client.id,
                    updatedBy: updatedBy,
                  );
                  final completed =
                      cubit.state.status == ClientsStatus.saved &&
                      cubit.state.lastAction == ClientsAction.archiveClient;
                  if (completed && dialogContext.mounted) {
                    Navigator.of(dialogContext).pop();
                    return;
                  }
                  if (dialogContext.mounted) {
                    setDialogState(() => isSubmitting = false);
                  }
                },
              ),
            ],
          );
        },
      );
    },
  );
}

Future<void> _showAssignClientSheet(
  BuildContext context, {
  required Client client,
  required String companyId,
  required String updatedBy,
  required List<UserProfile> users,
}) async {
  final l = AppLocalizations.of(context)!;
  final cubit = context.read<ClientsCubit>();
  var selectedUserId = client.assignedTo;
  var isSubmitting = false;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) {
      return StatefulBuilder(
        builder: (context, setSheetState) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.lg,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l.assignClient,
                          style: Theme.of(sheetContext).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      IconButton(
                        onPressed: isSubmitting
                            ? null
                            : () => Navigator.of(sheetContext).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ClientAssignmentField(
                    users: users,
                    value: selectedUserId,
                    onChanged: (uid) {
                      setSheetState(() => selectedUserId = uid);
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppButton(
                    label: l.assignClient,
                    isLoading: isSubmitting,
                    onPressed: () async {
                      setSheetState(() => isSubmitting = true);
                      final selectedUser = _userById(users, selectedUserId);
                      await cubit.assignClient(
                        companyId: companyId,
                        clientId: client.id,
                        assignedTo: selectedUserId,
                        assignedToName: selectedUser?.fullName ?? '',
                        assignedToEmail: selectedUser?.email ?? '',
                        teamId: selectedUser?.teamId ?? '',
                        teamName: selectedUser?.teamName ?? '',
                        managerId: selectedUser?.managerId ?? '',
                        managerName: selectedUser?.managerName ?? '',
                        updatedBy: updatedBy,
                      );
                      final completed =
                          cubit.state.status == ClientsStatus.saved &&
                          cubit.state.lastAction == ClientsAction.assignClient;
                      if (completed && sheetContext.mounted) {
                        Navigator.of(sheetContext).pop();
                        return;
                      }
                      if (sheetContext.mounted) {
                        setSheetState(() => isSubmitting = false);
                      }
                    },
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
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

UserProfile? _userById(List<UserProfile> users, String uid) {
  final value = uid.trim();
  if (value.isEmpty) {
    return null;
  }
  for (final user in users) {
    if (user.uid == value) {
      return user;
    }
  }
  return null;
}

double _tableHeightForRows(int rowCount) {
  final ideal = 54.0 * (rowCount + 1) + 2;
  return ideal.clamp(180.0, 520.0).toDouble();
}

Stream<List<UserProfile>> _watchActiveUsers(String companyId) {
  final repository = UserProfileRepositoryImpl(
    remoteDataSource: FirestoreUserProfileRemoteDataSource(),
  );
  return WatchActiveUsersUseCase(repository)(companyId: companyId);
}
