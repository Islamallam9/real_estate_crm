import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/permissions/app_permission.dart';
import '../../../../core/permissions/permission_service.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_dropdown.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_status_badge.dart';
import '../../../../core/widgets/crm_app_shell.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../domain/entities/lead.dart';
import '../cubit/leads_cubit.dart';
import '../cubit/leads_state.dart';
import '../widgets/leads_scope.dart';

class LeadsListPage extends StatelessWidget {
  const LeadsListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return CrmAppShell(
      selectedItem: CrmNavigationItem.leads,
      title: localizations.leads,
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

          return LeadsScope(
            child: _LeadsListContent(
              companyId: companyId,
              canCreate: _can(authState, AppPermission.createLead),
            ),
          );
        },
      ),
    );
  }
}

class _LeadsListContent extends StatefulWidget {
  const _LeadsListContent({required this.companyId, required this.canCreate});

  final String companyId;
  final bool canCreate;

  @override
  State<_LeadsListContent> createState() => _LeadsListContentState();
}

class _LeadsListContentState extends State<_LeadsListContent> {
  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    final role = authState.userProfile?.role ?? authState.user?.role;
    final uid = authState.user?.uid ?? '';
    final assignedTo = role?.name == 'salesAgent' ? uid : null;
    context.read<LeadsCubit>().watchLeads(
      companyId: widget.companyId,
      assignedTo: assignedTo,
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return BlocBuilder<LeadsCubit, LeadsState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    localizations.leadsSubtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                AppButton(
                  label: localizations.createLead,
                  onPressed: widget.canCreate
                      ? () => context.go(RouteNames.leadsCreate)
                      : null,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            const _LeadFilters(),
            const SizedBox(height: AppSpacing.lg),
            Expanded(child: _LeadsBody(state: state)),
          ],
        );
      },
    );
  }
}

class _LeadFilters extends StatelessWidget {
  const _LeadFilters();

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return BlocBuilder<LeadsCubit, LeadsState>(
      buildWhen: (previous, current) {
        return previous.searchQuery != current.searchQuery ||
            previous.statusFilter != current.statusFilter ||
            previous.sourceFilter != current.sourceFilter ||
            previous.priorityFilter != current.priorityFilter;
      },
      builder: (context, state) {
        return Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            SizedBox(
              width: 260,
              child: TextField(
                decoration: InputDecoration(
                  labelText: localizations.searchLeads,
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onChanged: context.read<LeadsCubit>().setSearchQuery,
              ),
            ),
            SizedBox(
              width: 190,
              child: AppDropdown<LeadStatus?>(
                label: localizations.status,
                value: state.statusFilter,
                items: <LeadStatus?>[null, ...LeadStatus.values],
                itemLabelBuilder: (status) => status == null
                    ? localizations.allStatuses
                    : _statusLabel(localizations, status),
                onChanged: context.read<LeadsCubit>().setStatusFilter,
              ),
            ),
            SizedBox(
              width: 190,
              child: AppDropdown<LeadSource?>(
                label: localizations.source,
                value: state.sourceFilter,
                items: <LeadSource?>[null, ...LeadSource.values],
                itemLabelBuilder: (source) => source == null
                    ? localizations.allSources
                    : _sourceLabel(localizations, source),
                onChanged: context.read<LeadsCubit>().setSourceFilter,
              ),
            ),
            SizedBox(
              width: 190,
              child: AppDropdown<LeadPriority?>(
                label: localizations.priority,
                value: state.priorityFilter,
                items: <LeadPriority?>[null, ...LeadPriority.values],
                itemLabelBuilder: (priority) => priority == null
                    ? localizations.allPriorities
                    : _priorityLabel(localizations, priority),
                onChanged: context.read<LeadsCubit>().setPriorityFilter,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _LeadsBody extends StatelessWidget {
  const _LeadsBody({required this.state});

  final LeadsState state;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    if (state.status == LeadsStatus.loading ||
        state.status == LeadsStatus.initial) {
      return const AppLoading();
    }

    if (state.status == LeadsStatus.failure) {
      return AppErrorView(message: localizations.unableToLoadLeads);
    }

    if (state.filteredLeads.isEmpty) {
      return AppEmptyState(
        title: localizations.noLeads,
        message: localizations.leadsSubtitle,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 720;
        return ListView.separated(
          itemCount: state.filteredLeads.length,
          separatorBuilder: (context, index) => compact
              ? const SizedBox(height: AppSpacing.sm)
              : const Divider(height: AppSpacing.lg),
          itemBuilder: (context, index) {
            final lead = state.filteredLeads[index];
            return compact ? _LeadCard(lead: lead) : _LeadRow(lead: lead);
          },
        );
      },
    );
  }
}

class _LeadRow extends StatelessWidget {
  const _LeadRow({required this.lead});

  final Lead lead;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return InkWell(
      onTap: () => context.go(RouteNames.leadDetails(lead.id)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            Expanded(flex: 3, child: _LeadTitle(lead: lead)),
            Expanded(
              flex: 2,
              child: Text(
                lead.phone,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                lead.preferredLocation.isEmpty
                    ? localizations.notAvailable
                    : lead.preferredLocation,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            AppStatusBadge(label: _statusLabel(localizations, lead.status)),
          ],
        ),
      ),
    );
  }
}

class _LeadCard extends StatelessWidget {
  const _LeadCard({required this.lead});

  final Lead lead;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return InkWell(
      onTap: () => context.go(RouteNames.leadDetails(lead.id)),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _LeadTitle(lead: lead),
            const SizedBox(height: AppSpacing.sm),
            Text(lead.phone, maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: AppSpacing.sm),
            AppStatusBadge(label: _statusLabel(localizations, lead.status)),
          ],
        ),
      ),
    );
  }
}

class _LeadTitle extends StatelessWidget {
  const _LeadTitle({required this.lead});

  final Lead lead;

  @override
  Widget build(BuildContext context) {
    return Text(
      lead.fullName,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
    );
  }
}

bool _can(AuthState state, AppPermission permission) {
  final role = state.userProfile?.role ?? state.user?.role;
  return role != null && PermissionService.can(role, permission);
}

String _statusLabel(AppLocalizations localizations, LeadStatus status) {
  switch (status) {
    case LeadStatus.newLead:
      return localizations.newLead;
    case LeadStatus.contacted:
      return localizations.contacted;
    case LeadStatus.interested:
      return localizations.interested;
    case LeadStatus.visitScheduled:
      return localizations.visitScheduled;
    case LeadStatus.negotiation:
      return localizations.negotiation;
    case LeadStatus.won:
      return localizations.won;
    case LeadStatus.lost:
      return localizations.lost;
  }
}

String _sourceLabel(AppLocalizations localizations, LeadSource source) {
  switch (source) {
    case LeadSource.facebook:
      return localizations.facebook;
    case LeadSource.website:
      return localizations.website;
    case LeadSource.phoneCall:
      return localizations.phoneCall;
    case LeadSource.whatsapp:
      return localizations.whatsapp;
    case LeadSource.referral:
      return localizations.referral;
    case LeadSource.walkIn:
      return localizations.walkIn;
    case LeadSource.other:
      return localizations.other;
  }
}

String _priorityLabel(AppLocalizations localizations, LeadPriority priority) {
  switch (priority) {
    case LeadPriority.low:
      return localizations.low;
    case LeadPriority.medium:
      return localizations.medium;
    case LeadPriority.high:
      return localizations.high;
  }
}
