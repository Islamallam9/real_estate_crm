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
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_status_badge.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/crm_app_shell.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../users/data/datasources/user_profile_remote_data_source.dart';
import '../../../users/data/repositories/user_profile_repository_impl.dart';
import '../../../users/domain/entities/user_profile.dart';
import '../../../users/domain/usecases/watch_active_users_usecase.dart';
import '../../domain/entities/lead.dart';
import '../../domain/entities/lead_timeline_event.dart';
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
    final companyId = _companyId(context);
    if (companyId.isNotEmpty) {
      final cubit = context.read<LeadsCubit>();
      cubit.loadLead(companyId: companyId, leadId: widget.leadId);
      cubit.watchTimeline(companyId: companyId, leadId: widget.leadId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final l = AppLocalizations.of(context)!;
    final role = authState.userProfile?.role ?? authState.user?.role;
    final uid = authState.user?.uid ?? '';
    final actorName =
        authState.userProfile?.fullName ??
        authState.user?.fullName ??
        l.unknownUser;
    final companyId = _companyId(context);

    return CrmAppShell(
      selectedItem: CrmNavigationItem.leads,
      title: l.leadDetails,
      child: BlocBuilder<LeadsCubit, LeadsState>(
        builder: (context, state) {
          if (state.status == LeadsStatus.loading ||
              state.status == LeadsStatus.initial) {
            return const AppLoading();
          }

          final lead = state.selectedLead;
          if (lead == null ||
              companyId.isEmpty ||
              uid.isEmpty ||
              role == null) {
            return AppErrorView(message: l.unableToLoadLeads);
          }

          final isSalesAgent = role.name == 'salesAgent';
          if (isSalesAgent && lead.assignedTo != uid) {
            return AppErrorView(message: l.youDoNotHavePermissionToViewLead);
          }

          final canEdit =
              PermissionService.can(role, AppPermission.editLead) &&
              (!isSalesAgent || lead.assignedTo == uid);
          final canArchive = PermissionService.can(
            role,
            AppPermission.archiveLead,
          );
          final canStatus = canEdit || (isSalesAgent && lead.assignedTo == uid);

          return StreamBuilder<List<UserProfile>>(
            stream: _watchActiveUsers(companyId),
            builder: (context, usersSnapshot) {
              final users = usersSnapshot.data ?? const <UserProfile>[];
              final assigneeName = lead.assignedToName.isNotEmpty
                  ? lead.assignedToName
                  : _assigneeName(users, lead.assignedTo, l);

              return _LeadDetailsContent(
                lead: lead,
                timeline: state.timeline,
                companyId: companyId,
                uid: uid,
                actorName: actorName,
                canEdit: canEdit,
                canArchive: canArchive,
                canStatus: canStatus,
                assigneeName: assigneeName,
                activeUsers: users,
              );
            },
          );
        },
      ),
    );
  }
}

class _LeadDetailsContent extends StatefulWidget {
  const _LeadDetailsContent({
    required this.lead,
    required this.timeline,
    required this.companyId,
    required this.uid,
    required this.actorName,
    required this.canEdit,
    required this.canArchive,
    required this.canStatus,
    required this.assigneeName,
    required this.activeUsers,
  });

  final Lead lead;
  final List<LeadTimelineEvent> timeline;
  final String companyId;
  final String uid;
  final String actorName;
  final bool canEdit;
  final bool canArchive;
  final bool canStatus;
  final String assigneeName;
  final List<UserProfile> activeUsers;

  @override
  State<_LeadDetailsContent> createState() => _LeadDetailsContentState();
}

class _LeadDetailsContentState extends State<_LeadDetailsContent> {
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return ListView(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                widget.lead.fullName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            AppStatusBadge(label: _statusLabel(l, widget.lead.status)),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text('${l.assignedToLabel}: ${widget.assigneeName}'),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            if (widget.canEdit)
              AppButton(
                label: l.editLead,
                onPressed: () =>
                    context.go(RouteNames.leadEdit(widget.lead.id)),
              ),
            if (widget.canArchive)
              AppButton(
                label: l.archiveLead,
                onPressed: () => _archive(context),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        if (widget.canStatus)
          AppDropdown<LeadStatus>(
            label: l.changeStatus,
            value: widget.lead.status,
            items: LeadStatus.values,
            itemLabelBuilder: (status) => _statusLabel(l, status),
            onChanged: (status) {
              context.read<LeadsCubit>().updateStatus(
                companyId: widget.companyId,
                updatedBy: widget.uid,
                actorName: widget.actorName,
                status: status,
              );
            },
          ),
        const SizedBox(height: AppSpacing.lg),
        _detail(l.phone, widget.lead.phone, l),
        _detail(l.email, widget.lead.email, l),
        _detail(l.preferredLocation, widget.lead.preferredLocation, l),
        _detail(l.preferredPropertyType, widget.lead.preferredPropertyType, l),
        _detail(l.notes, widget.lead.notes, l),
        const SizedBox(height: AppSpacing.lg),
        Text(
          l.addNote,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.sm),
        AppTextField(controller: _noteController, label: l.note),
        const SizedBox(height: AppSpacing.sm),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: AppButton(
            label: l.saveNote,
            onPressed: () {
              context.read<LeadsCubit>().addNote(
                companyId: widget.companyId,
                leadId: widget.lead.id,
                text: _noteController.text,
                createdBy: widget.uid,
                actorName: widget.actorName,
              );
              _noteController.clear();
            },
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          l.timeline,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (widget.timeline.isEmpty) Text(l.noTimelineEvents),
        for (int i = 0; i < widget.timeline.length; i++)
          _TimelineItem(
            event: widget.timeline[i],
            isLast: i == widget.timeline.length - 1,
            users: widget.activeUsers,
          ),
      ],
    );
  }

  Widget _detail(String label, String value, AppLocalizations l) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value.isEmpty ? l.notAvailable : value,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Future<void> _archive(BuildContext context) async {
    final l = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l.archiveLead),
        content: Text(l.archiveLeadConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l.archive),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) {
      return;
    }
    final cubit = context.read<LeadsCubit>();
    await cubit.archiveLead(
      companyId: widget.companyId,
      leadId: widget.lead.id,
      archivedBy: widget.uid,
      actorName: widget.actorName,
    );
    if (context.mounted && cubit.state.status == LeadsStatus.saved) {
      context.go(RouteNames.leads);
    }
  }
}

class _TimelineItem extends StatelessWidget {
  const _TimelineItem({
    required this.event,
    required this.isLast,
    required this.users,
  });

  final LeadTimelineEvent event;
  final bool isLast;
  final List<UserProfile> users;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final description = _timelineDescription(l, event);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
              if (!isLast)
                Expanded(child: Container(width: 2, color: AppColors.border)),
            ],
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _timelineTitle(l, event, users),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (description.isNotEmpty)
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  Text(
                    event.createdAt.toLocal().toString(),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _timelineTitle(
  AppLocalizations l,
  LeadTimelineEvent event,
  List<UserProfile> users,
) {
  final actor = _eventActorName(l, event, users);
  switch (event.title) {
    case 'lead_created':
      return l.leadCreatedBy(actor);
    case 'lead_assigned':
      return l.leadReassignedBy(actor);
    case 'lead_reassigned':
      return l.leadReassignedBy(actor);
    case 'status_changed':
      return l.statusChangedToBy(_statusValueLabel(l, event.newValue), actor);
    case 'note_added':
      return l.noteAddedBy(actor);
    case 'lead_archived':
      return l.leadArchivedBy(actor);
    case 'field_changed':
      return l.fieldChangedBy(_fieldLabel(l, event.description), actor);
    default:
      return l.fieldChangedBy(_fieldLabel(l, event.description), actor);
  }
}

String _timelineDescription(AppLocalizations l, LeadTimelineEvent event) {
  if (event.title == 'note_added') {
    return event.description;
  }
  if (event.oldValue.isEmpty && event.newValue.isEmpty) {
    return '';
  }
  return l.changedFromTo(
    _timelineValueLabel(l, event.description, event.oldValue),
    _timelineValueLabel(l, event.description, event.newValue),
  );
}

String _eventActorName(
  AppLocalizations l,
  LeadTimelineEvent event,
  List<UserProfile> users,
) {
  if (event.createdByName.isNotEmpty) {
    return event.createdByName;
  }
  for (final user in users) {
    if (user.uid == event.createdBy) {
      return user.fullName;
    }
  }
  return l.unknownUser;
}

String _fieldLabel(AppLocalizations l, String field) {
  switch (field) {
    case 'fullName':
      return l.fullNameUpdated;
    case 'phone':
      return l.phoneUpdated;
    case 'email':
      return l.emailUpdated;
    case 'source':
      return l.sourceUpdated;
    case 'status':
      return l.statusUpdated;
    case 'priority':
      return l.priorityUpdated;
    case 'budget':
      return l.budgetUpdated;
    case 'preferredLocation':
      return l.preferredLocationUpdated;
    case 'preferredPropertyType':
      return l.preferredPropertyTypeUpdated;
    case 'assignedTo':
      return l.assignedToLabel;
    case 'notes':
      return l.notes;
    default:
      return field;
  }
}

String _timelineValueLabel(AppLocalizations l, String field, String value) {
  if (field == 'status') {
    return _statusValueLabel(l, value);
  }
  if (field == 'source') {
    return _sourceValueLabel(l, value);
  }
  if (field == 'priority') {
    return _priorityValueLabel(l, value);
  }
  return value.isEmpty ? l.notAvailable : value;
}

String _assigneeName(List<UserProfile> users, String uid, AppLocalizations l) {
  if (uid.isEmpty) {
    return l.unassigned;
  }
  for (final user in users) {
    if (user.uid == uid) {
      return user.fullName;
    }
  }
  return l.assignedUserUnavailable;
}

String _companyId(BuildContext context) {
  final auth = context.read<AuthBloc>().state;
  return auth.userProfile?.companyId ?? auth.user?.companyId ?? '';
}

Stream<List<UserProfile>> _watchActiveUsers(String companyId) {
  final repository = UserProfileRepositoryImpl(
    remoteDataSource: FirestoreUserProfileRemoteDataSource(),
  );
  return WatchActiveUsersUseCase(repository)(companyId: companyId);
}

String _statusLabel(AppLocalizations l, LeadStatus status) {
  switch (status) {
    case LeadStatus.newLead:
      return l.newLeadStatus;
    case LeadStatus.contacted:
      return l.contactedLeadStatus;
    case LeadStatus.interested:
      return l.interestedLeadStatus;
    case LeadStatus.visitScheduled:
      return l.visitScheduledLeadStatus;
    case LeadStatus.negotiation:
      return l.negotiationLeadStatus;
    case LeadStatus.won:
      return l.wonLeadStatus;
    case LeadStatus.lost:
      return l.lostLeadStatus;
  }
}

String _statusValueLabel(AppLocalizations l, String value) {
  switch (value) {
    case 'newLead':
    case 'new':
      return l.newLeadStatus;
    case 'contacted':
      return l.contactedLeadStatus;
    case 'interested':
      return l.interestedLeadStatus;
    case 'visitScheduled':
      return l.visitScheduledLeadStatus;
    case 'negotiation':
      return l.negotiationLeadStatus;
    case 'won':
      return l.wonLeadStatus;
    case 'lost':
      return l.lostLeadStatus;
    default:
      return value;
  }
}

String _sourceValueLabel(AppLocalizations l, String value) {
  switch (value) {
    case 'facebook':
      return l.facebook;
    case 'website':
      return l.website;
    case 'phoneCall':
      return l.phoneCall;
    case 'whatsapp':
      return l.whatsapp;
    case 'referral':
      return l.referral;
    case 'walkIn':
      return l.walkIn;
    case 'other':
      return l.other;
    default:
      return value;
  }
}

String _priorityValueLabel(AppLocalizations l, String value) {
  switch (value) {
    case 'low':
      return l.low;
    case 'medium':
      return l.medium;
    case 'high':
      return l.high;
    default:
      return value;
  }
}
