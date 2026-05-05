import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/permissions/app_permission.dart';
import '../../../../core/permissions/permission_service.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_status_badge.dart';
import '../../../../core/widgets/crm_app_shell.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/entities/lead.dart';
import '../cubit/leads_cubit.dart';
import '../cubit/leads_state.dart';
import '../widgets/leads_scope.dart';

class LeadDetailsPage extends StatelessWidget {
  const LeadDetailsPage({super.key, required this.leadId});

  final String leadId;

  @override
  Widget build(BuildContext context) {
    return LeadsScope(child: _LeadDetailsView(leadId: leadId));
  }
}

class _LeadDetailsView extends StatefulWidget {
  const _LeadDetailsView({required this.leadId});

  final String leadId;

  @override
  State<_LeadDetailsView> createState() => _LeadDetailsViewState();
}

class _LeadDetailsViewState extends State<_LeadDetailsView> {
  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    final companyId =
        authState.userProfile?.companyId ?? authState.user?.companyId ?? '';
    if (companyId.isNotEmpty) {
      context.read<LeadsCubit>().loadLead(
        companyId: companyId,
        leadId: widget.leadId,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final authState = context.read<AuthBloc>().state;
    final companyId =
        authState.userProfile?.companyId ?? authState.user?.companyId ?? '';
    final uid = authState.user?.uid ?? '';
    final role = authState.userProfile?.role ?? authState.user?.role;

    return CrmAppShell(
      selectedItem: CrmNavigationItem.leads,
      title: localizations.leadDetails,
      child: BlocBuilder<LeadsCubit, LeadsState>(
        builder: (context, state) {
          if (state.status == LeadsStatus.loading ||
              state.status == LeadsStatus.initial) {
            return const AppLoading();
          }

          if (state.status == LeadsStatus.failure ||
              state.selectedLead == null) {
            return AppErrorView(message: localizations.unableToLoadLeads);
          }

          return _LeadDetailsContent(
            lead: state.selectedLead!,
            canArchive: role == null
                ? false
                : PermissionService.can(role, AppPermission.archiveLead),
            onArchive: companyId.isEmpty || uid.isEmpty
                ? null
                : () => _confirmArchiveLead(
                    context: context,
                    companyId: companyId,
                    leadId: state.selectedLead!.id,
                    archivedBy: uid,
                  ),
          );
        },
      ),
    );
  }

  Future<void> _confirmArchiveLead({
    required BuildContext context,
    required String companyId,
    required String leadId,
    required String archivedBy,
  }) async {
    final localizations = AppLocalizations.of(context)!;
    final shouldArchive = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(localizations.archiveLead),
          content: Text(localizations.archiveLeadConfirmation),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(localizations.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(localizations.archive),
            ),
          ],
        );
      },
    );

    if (shouldArchive != true || !context.mounted) {
      return;
    }

    final cubit = context.read<LeadsCubit>();
    await cubit.archiveLead(
      companyId: companyId,
      leadId: leadId,
      archivedBy: archivedBy,
    );

    if (context.mounted && cubit.state.status == LeadsStatus.saved) {
      context.go(RouteNames.leads);
    }
  }
}

class _LeadDetailsContent extends StatelessWidget {
  const _LeadDetailsContent({
    required this.lead,
    required this.canArchive,
    required this.onArchive,
  });

  final Lead lead;
  final bool canArchive;
  final VoidCallback? onArchive;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  lead.fullName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              AppStatusBadge(label: _statusLabel(localizations, lead.status)),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _DetailText(label: localizations.phone, value: lead.phone),
          _DetailText(label: localizations.email, value: lead.email),
          _DetailText(
            label: localizations.preferredLocation,
            value: lead.preferredLocation,
          ),
          _DetailText(
            label: localizations.preferredPropertyType,
            value: lead.preferredPropertyType,
          ),
          _DetailText(label: localizations.notes, value: lead.notes),
          if (canArchive && onArchive != null) ...[
            const SizedBox(height: AppSpacing.lg),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: AppButton(
                label: localizations.archiveLead,
                onPressed: onArchive,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailText extends StatelessWidget {
  const _DetailText({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value.isEmpty ? localizations.notAvailable : value,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
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
