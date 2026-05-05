import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
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

          return LeadsScope(child: _LeadsListContent(companyId: companyId));
        },
      ),
    );
  }
}

class _LeadsListContent extends StatefulWidget {
  const _LeadsListContent({required this.companyId});

  final String companyId;

  @override
  State<_LeadsListContent> createState() => _LeadsListContentState();
}

class _LeadsListContentState extends State<_LeadsListContent> {
  @override
  void initState() {
    super.initState();
    context.read<LeadsCubit>().watchLeads(companyId: widget.companyId);
  }

  @override
  void didUpdateWidget(covariant _LeadsListContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.companyId != widget.companyId) {
      context.read<LeadsCubit>().watchLeads(companyId: widget.companyId);
    }
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
                  onPressed: () => context.go(RouteNames.leadsCreate),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Expanded(child: _LeadsBody(state: state)),
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

    if (state.leads.isEmpty) {
      return AppEmptyState(
        title: localizations.noLeads,
        message: localizations.leadsSubtitle,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 720;

        if (compact) {
          return ListView.separated(
            itemCount: state.leads.length,
            separatorBuilder: (context, index) =>
                const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) =>
                _LeadCard(lead: state.leads[index]),
          );
        }

        return ListView.separated(
          itemCount: state.leads.length,
          separatorBuilder: (context, index) =>
              const Divider(height: AppSpacing.lg),
          itemBuilder: (context, index) => _LeadRow(lead: state.leads[index]),
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
