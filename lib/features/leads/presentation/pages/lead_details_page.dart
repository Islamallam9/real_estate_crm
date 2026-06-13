import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/protected_company_session.dart';
import '../../../../core/constants/role_constants.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/intelligence/lead_nba_evaluator.dart';
import '../../../../core/intelligence/sales_next_action_type.dart';
import '../../../../core/permissions/app_permission.dart';
import '../../../../core/permissions/permission_service.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_dropdown.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_status_badge.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/crm_app_shell.dart';
import '../../../../core/widgets/masar_tab_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../journeys/domain/entities/connected_journey.dart';
import '../../../journeys/presentation/widgets/connected_journey_panel.dart';
import '../../../journeys/presentation/widgets/journey_builders.dart';
import '../../../users/data/datasources/user_profile_remote_data_source.dart';
import '../../../users/data/repositories/user_profile_repository_impl.dart';
import '../../../users/domain/entities/user_profile.dart';
import '../../../users/domain/usecases/watch_active_users_usecase.dart';
import '../../domain/entities/lead.dart';
import '../../domain/entities/lead_timeline_event.dart';
import '../cubit/leads_cubit.dart';
import '../cubit/leads_state.dart';
import '../widgets/leads_scope.dart';
import '../../../../core/widgets/masar_loading_view.dart';

class LeadDetailsPage extends StatelessWidget {
  const LeadDetailsPage({super.key, required this.leadId});

  final String leadId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final session = authState.protectedCompanySession;
        return LeadsScope(
          key: ValueKey(
            session?.scopeKey('lead-details-scope') ??
                'lead-details-scope:loading',
          ),
          child: _LeadDetailsView(leadId: leadId),
        );
      },
    );
  }
}

class _LeadDetailsView extends StatefulWidget {
  const _LeadDetailsView({required this.leadId});

  final String leadId;

  @override
  State<_LeadDetailsView> createState() => _LeadDetailsViewState();
}

class _LeadDetailsViewState extends State<_LeadDetailsView> {
  Stream<List<UserProfile>>? _activeUsersStream;
  String? _activeUsersCompanyId;
  String? _loadedCompanyId;
  String? _timelineCompanyId;

  Stream<List<UserProfile>> _activeUsers(String companyId) {
    if (_activeUsersStream == null || _activeUsersCompanyId != companyId) {
      _activeUsersCompanyId = companyId;
      _activeUsersStream = _watchActiveUsers(companyId).asBroadcastStream();
    }

    return _activeUsersStream!;
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadLeadWhenReady();
  }

  void _loadLeadWhenReady() {
    final session = context.read<AuthBloc>().state.protectedCompanySession;
    if (session == null || widget.leadId.isEmpty) {
      return;
    }
    final companyId = session.companyId;

    final cubit = context.read<LeadsCubit>();
    if (_loadedCompanyId != companyId) {
      _loadedCompanyId = companyId;
      cubit.loadLead(companyId: companyId, leadId: widget.leadId);
    }
    if (_timelineCompanyId != companyId) {
      _timelineCompanyId = companyId;
      cubit.watchTimeline(companyId: companyId, leadId: widget.leadId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final session = authState.protectedCompanySession;
    final l = AppLocalizations.of(context)!;
    final role = session?.profile.role;
    final uid = session?.uid ?? '';
    final actorName = session?.profile.fullName.trim().isNotEmpty == true
        ? session!.profile.fullName
        : l.unknownUser;
    final companyId = session?.companyId ?? '';
    if (companyId.isNotEmpty && _loadedCompanyId != companyId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _loadLeadWhenReady();
        }
      });
    }

    return CrmAppShell(
      selectedItem: CrmNavigationItem.leads,
      title: l.leadDetails,
      child: authState.isWaitingForProtectedCompanySession
          ? const AppLoading()
          : session == null
              ? AppErrorView(message: l.missingCompanyProfile)
              : BlocConsumer<LeadsCubit, LeadsState>(
        listenWhen: (previous, current) =>
            previous.status != current.status &&
            (current.status == LeadsStatus.saved ||
                current.status == LeadsStatus.failure),
        listener: (context, state) {
          if (state.status == LeadsStatus.saved) {
            final message = _successMessageForAction(l, state.lastAction);
            if (message.isNotEmpty) {
              AppFeedback.success(context, message);
            }
            return;
          }
          if (state.status == LeadsStatus.failure) {
            AppFeedback.error(
              context,
              localizeErrorMessage(l, state.message),
            );
          }
        },
        builder: (context, state) {
          final lead = state.selectedLead;

          if (lead == null &&
              (state.status == LeadsStatus.loading ||
                  state.status == LeadsStatus.initial)) {
            return const AppLoading();
          }

          if (lead == null ||
              companyId.isEmpty ||
              uid.isEmpty ||
              role == null) {
            return AppErrorView(
              message: localizeErrorMessage(
                l,
                state.message ?? l.unableToLoadLeads,
              ),
              onRetry: () {
                final cubit = context.read<LeadsCubit>();
                cubit.loadLead(companyId: companyId, leadId: widget.leadId);
                cubit.watchTimeline(
                  companyId: companyId,
                  leadId: widget.leadId,
                );
              },
            );
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
            stream: _activeUsers(companyId),
            builder: (context, usersSnapshot) {
              final users = usersSnapshot.data ?? const <UserProfile>[];
              final assigneeName = lead.assignedToName.isNotEmpty
                  ? lead.assignedToName
                  : _assigneeName(users, lead.assignedTo, l);

              final content = _LeadDetailsContent(
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
                currentUserProfile: session.profile,
                isSaving: state.status == LeadsStatus.saving,
              );

              final isBusy =
                  state.status == LeadsStatus.saving ||
                  (usersSnapshot.connectionState == ConnectionState.waiting &&
                      users.isEmpty);

              return Stack(
                children: [
                  content,
                  if (isBusy)
                    Positioned.fill(
                      child: AbsorbPointer(
                        child: Container(
                          color: AppColors.appBackground(
                            context,
                          ).withValues(alpha: 0.70),
                          child: const Center(
                            child: MasarLogoLoader(size: 42),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

UserProfile? _currentUserProfileFromUsers(List<UserProfile> users, String uid) {
  for (final user in users) {
    if (user.uid == uid) {
      return user;
    }
  }
  return null;
}

String _successMessageForAction(AppLocalizations l, LeadsAction action) {
  switch (action) {
    case LeadsAction.createLead:
      return l.leadCreatedSuccessfully;
    case LeadsAction.updateLead:
      return l.leadUpdatedSuccessfully;
    case LeadsAction.archiveLead:
      return l.leadArchivedSuccessfully;
    case LeadsAction.restoreLead:
      return l.recordRestoredSuccessfully;
    case LeadsAction.updateStatus:
      return l.leadStatusUpdatedSuccessfully;
    case LeadsAction.assignLead:
      return l.leadAssignedSuccessfully;
    case LeadsAction.addNote:
      return l.noteAddedSuccessfully;
    case LeadsAction.markContactedToday:
      return l.leadMarkedContactedToday;
    case LeadsAction.none:
      return '';
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
    this.currentUserProfile,
    required this.isSaving,
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
  final UserProfile? currentUserProfile;
  final bool isSaving;

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

    return LayoutBuilder(
      builder: (context, constraints) {
        final useDesktopLayout = constraints.maxWidth >= 1024;
        if (!useDesktopLayout) {
          return DefaultTabController(
            length: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _LeadDetailsTabBar(
                  tabs: [
                    _LeadDetailsTab(
                      label: l.leadDetails,
                      icon: Icons.info_outline_rounded,
                    ),
                    _LeadDetailsTab(
                      label: l.timeline,
                      icon: Icons.timeline_outlined,
                    ),
                    _LeadDetailsTab(
                      label: l.connectedJourneyTitle,
                      icon: Icons.route_outlined,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Expanded(
                  child: TabBarView(
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      ListView(
                        children: _mainContent(l),
                      ),
                      ListView(
                        children: [
                          _TimelineSection(
                            timeline: widget.timeline,
                            users: widget.activeUsers,
                            scrollable: false,
                          ),
                        ],
                      ),
                      RefreshIndicator(
                        onRefresh: _refreshLeadJourney,
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            _journeyPanel(l, compact: false),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        final timelineWidth = constraints.maxWidth >= 1120 ? 360.0 : 320.0;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: DefaultTabController(
                length: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _LeadDetailsTabBar(
                      tabs: [
                        _LeadDetailsTab(
                          label: l.details,
                          icon: Icons.info_outline_rounded,
                        ),
                        _LeadDetailsTab(
                          label: l.connectedJourneyTitle,
                          icon: Icons.route_outlined,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Expanded(
                      child: TabBarView(
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          RefreshIndicator(
                            onRefresh: _refreshLeadJourney,
                            child: ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: _mainContent(l),
                            ),
                          ),
                          RefreshIndicator(
                            onRefresh: _refreshLeadJourney,
                            child: ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: [_journeyPanel(l, compact: false)],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            SizedBox(
              width: timelineWidth,
              child: SizedBox(
                height: constraints.hasBoundedHeight
                    ? constraints.maxHeight
                    : null,
                child: _TimelineSection(
                  timeline: widget.timeline,
                  users: widget.activeUsers,
                  scrollable: true,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _refreshLeadJourney() async {
    final cubit = context.read<LeadsCubit>();
    cubit.loadLead(companyId: widget.companyId, leadId: widget.lead.id);
    cubit.watchTimeline(companyId: widget.companyId, leadId: widget.lead.id);
    await Future<void>.delayed(const Duration(milliseconds: 320));
  }

  ConnectedJourneyPanel _journeyPanel(AppLocalizations l, {required bool compact}) {
    final role = widget.currentUserProfile?.role ?? UserRole.viewer;
    return ConnectedJourneyPanel(
      recordType: JourneyRecordType.lead,
      recordId: widget.lead.id,
      scope: JourneyQueryScope(
        companyId: widget.companyId,
        currentUserId: widget.uid,
        role: role,
        teamId: widget.currentUserProfile?.teamId ?? '',
        managerId: widget.currentUserProfile?.managerId ?? '',
      ),
      baseItems: leadBaseJourneyItems(
        l,
        widget.lead,
        widget.timeline,
        users: widget.activeUsers,
      ),
      recommendations: leadJourneyRecommendations(
        l,
        widget.lead,
        canCreateTask: PermissionService.can(role, AppPermission.createTask),
        canCreateAppointment: PermissionService.can(
          role,
          AppPermission.createAppointment,
        ),
      ),
      compact: compact,
    );
  }

  List<Widget> _mainContent(AppLocalizations l) {
    final smartSuggestion = _leadSmartSuggestion(l);
    return [
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
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              if (widget.lead.isArchived)
                AppStatusBadge(
                  label: l.archived,
                  tone: AppStatusTone.neutral,
                ),
              AppStatusBadge(label: _statusLabel(l, widget.lead.status)),
            ],
          ),
        ],
      ),
      const SizedBox(height: AppSpacing.sm),
      Text(l.leadAssignedTo(widget.assigneeName)),
      if (smartSuggestion != null) ...[
        const SizedBox(height: AppSpacing.md),
        _LeadSmartSuggestionCard(suggestion: smartSuggestion),
      ],
      const SizedBox(height: AppSpacing.md),
      _LeadDetailsActions(
        canEdit: widget.canEdit,
        canArchive: widget.canArchive,
        isArchived: widget.lead.isArchived,
        isSaving: widget.isSaving,
        onEdit: () => context.go(RouteNames.leadEdit(widget.lead.id)),
        onMarkContactedToday: () => _markContactedToday(context),
        onScheduleFollowUp: () => _scheduleFollowUp(context),
        onArchive: () => _archive(context),
        onRestore: () => _restore(context),
      ),
      const SizedBox(height: AppSpacing.lg),
      if (widget.canStatus && !widget.lead.isArchived)
        AppDropdown<LeadStatus>(
          label: l.changeStatus,
          value: widget.lead.status,
          items: LeadStatus.values,
          itemLabelBuilder: (status) => _statusLabel(l, status),
          onChanged: (status) {
            if (widget.isSaving) {
              return;
            }

            _updateLeadFromDetails(
              context,
              widget.lead.copyWith(
                status: status,
                updatedAt: DateTime.now(),
                updatedBy: widget.uid,
              ),
              successAction: LeadsAction.updateStatus,
            );
          },
        ),
      const SizedBox(height: AppSpacing.md),
      _DetailsSection(
        title: l.contactInformation,
        children: [
          _detail(l.phone, widget.lead.phone, l),
          _detail(l.email, widget.lead.email, l),
          _detail(l.lastContact, _formatNullableDate(widget.lead.lastContactAt), l),
          _detail(l.nextFollowUp, _formatNullableDate(widget.lead.nextFollowUpAt), l),
        ],
      ),
      const SizedBox(height: AppSpacing.md),
      _DetailsSection(
        title: l.leadPreferences,
        children: [
          _detail(l.source, _sourceDisplayLabel(l, widget.lead), l),
          _detail(l.priority, _priorityValueLabel(l, widget.lead.priority.name), l),
          _detail(l.preferredLocation, widget.lead.preferredLocation, l),
          _detail(
            l.preferredPropertyType,
            widget.lead.preferredPropertyType,
            l,
          ),
        ],
      ),
      const SizedBox(height: AppSpacing.md),
      _DetailsSection(
        title: l.leadAssignment,
        children: [_detail(l.assignedToLabel, widget.assigneeName, l)],
      ),
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
    ];
  }


  _LeadSmartSuggestion? _leadSmartSuggestion(AppLocalizations l) {
    final decision = _evaluateLeadNba();
    if (widget.lead.isArchived) {
      return null;
    }

    if (decision.reason == 'contactedToday') {
      return _LeadSmartSuggestion(
        title: l.leadNbaContactedTodayTitle,
        body: l.leadNbaContactedTodayBody,
        icon: Icons.check_circle_outline_rounded,
        primaryLabel: l.leadNbaPrimaryActionScheduleFollowUp,
        onPrimaryAction: widget.canEdit && !widget.isSaving
            ? () => _scheduleFollowUp(context)
            : null,
      );
    }

    switch (decision.nextActionType) {
      case SalesNextActionType.contactLead:
        return _LeadSmartSuggestion(
          title: l.leadNbaContactTitle,
          body: l.leadNbaContactBody,
          icon: Icons.phone_in_talk_outlined,
          primaryLabel: l.leadNbaPrimaryActionContact,
          onPrimaryAction: widget.canEdit && !widget.isSaving
              ? () => _markContactedToday(context)
              : null,
        );
      case SalesNextActionType.followUp:
        final overdue = decision.reason == 'overdueFollowUp';
        return _LeadSmartSuggestion(
          title: overdue
              ? l.leadNbaFollowUpOverdueTitle
              : l.leadNbaFollowUpTodayTitle,
          body: overdue
              ? l.leadNbaFollowUpOverdueBody
              : l.leadNbaFollowUpTodayBody,
          icon: overdue
              ? Icons.notification_important_outlined
              : Icons.event_available_outlined,
          primaryLabel: l.leadNbaPrimaryActionContact,
          onPrimaryAction: widget.canEdit && !widget.isSaving
              ? () => _markContactedToday(context)
              : null,
        );
      case SalesNextActionType.setNextStep:
        return _LeadSmartSuggestion(
          title: l.leadNbaMissingNextStepTitle,
          body: l.leadNbaMissingNextStepBody,
          icon: Icons.route_outlined,
          primaryLabel: l.leadNbaPrimaryActionScheduleFollowUp,
          onPrimaryAction: widget.canEdit && !widget.isSaving
              ? () => _scheduleFollowUp(context)
              : null,
        );
      case SalesNextActionType.scheduleAppointment:
        return _LeadSmartSuggestion(
          title: l.leadNbaScheduleAppointmentTitle,
          body: l.leadNbaScheduleAppointmentBody,
          icon: Icons.real_estate_agent_outlined,
          primaryLabel: l.leadNbaPrimaryActionCreateAppointment,
          onPrimaryAction: _canCreateAppointment && !widget.isSaving
              ? _createAppointmentFromLead
              : null,
        );
      case SalesNextActionType.createAppointment:
        return _LeadSmartSuggestion(
          title: l.leadNbaCreateAppointmentTitle,
          body: l.leadNbaCreateAppointmentBody,
          icon: Icons.event_note_outlined,
          primaryLabel: l.leadNbaPrimaryActionCreateAppointment,
          onPrimaryAction: _canCreateAppointment && !widget.isSaving
              ? _createAppointmentFromLead
              : null,
        );
      case SalesNextActionType.createDeal:
        return _LeadSmartSuggestion(
          title: l.leadNbaCreateDealTitle,
          body: l.leadNbaCreateDealBody,
          icon: Icons.handshake_outlined,
          primaryLabel: l.leadNbaPrimaryActionCreateDeal,
          onPrimaryAction: _canCreateDeal && !widget.isSaving
              ? () => context.go(RouteNames.dealsCreate)
              : null,
        );
      case SalesNextActionType.reviewStaleLead:
        return _LeadSmartSuggestion(
          title: l.leadNbaStaleTitle,
          body: l.leadNbaStaleBody,
          icon: Icons.restart_alt_outlined,
          primaryLabel: l.leadNbaPrimaryActionContact,
          onPrimaryAction: widget.canEdit && !widget.isSaving
              ? () => _markContactedToday(context)
              : null,
        );
      case SalesNextActionType.futureFollowUp:
        return _LeadSmartSuggestion(
          title: l.leadNbaFutureFollowUpTitle,
          body: l.leadNbaFutureFollowUpBody,
          icon: Icons.event_available_outlined,
          primaryLabel: l.leadNbaPrimaryActionScheduleFollowUp,
          onPrimaryAction: widget.canEdit && !widget.isSaving
              ? () => _scheduleFollowUp(context)
              : null,
        );
      case SalesNextActionType.assignLead:
      case SalesNextActionType.managerReview:
      case SalesNextActionType.closeLost:
      case SalesNextActionType.none:
        return null;
    }
  }

  LeadNbaDecision _evaluateLeadNba() {
    return LeadNbaEvaluator.evaluate(
      LeadNbaInput(
        status: _leadStatusValueForNba(widget.lead.status),
        priority: widget.lead.priority.name,
        isArchived: widget.lead.isArchived,
        createdAt: widget.lead.createdAt,
        updatedAt: widget.lead.updatedAt,
        lastContactAt: widget.lead.lastContactAt,
        nextActionAt: widget.lead.nextFollowUpAt,
        assignedTo: widget.lead.assignedTo,
        preferStatusSuggestions: true,
        now: DateTime.now(),
      ),
    );
  }

  bool get _canCreateAppointment {
    final role = widget.currentUserProfile?.role;
    return role != null &&
        PermissionService.can(role, AppPermission.createAppointment);
  }

  bool get _canCreateDeal {
    final role = widget.currentUserProfile?.role;
    return role != null && PermissionService.can(role, AppPermission.createDeal);
  }

  void _createAppointmentFromLead() {
    context.go(
      RouteNames.appointmentCreateFor(
        relatedType: 'lead',
        relatedId: widget.lead.id,
        relatedTitle: widget.lead.fullName,
        relatedSubtitle: widget.lead.phone.isNotEmpty
            ? widget.lead.phone
            : widget.lead.email,
        assignedTo: widget.lead.assignedTo,
      ),
    );
  }

  Widget _detail(String label, String value, AppLocalizations l) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.md),
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

  void _updateLeadFromDetails(
    BuildContext context,
    Lead lead, {
    LeadsAction? successAction,
  }) {
    final safeLead = _withCurrentUserAssignmentSnapshots(lead);
    context.read<LeadsCubit>().updateLead(
      companyId: widget.companyId,
      lead: safeLead,
      actorName: widget.actorName,
      successAction: successAction,
    );
  }

  Lead _withCurrentUserAssignmentSnapshots(Lead lead) {
    final profile = widget.currentUserProfile;
    if (profile == null) {
      return lead;
    }
    final isAssignedOnlyRole =
        profile.role == UserRole.salesAgent ||
        profile.role == UserRole.marketing ||
        profile.role == UserRole.viewer;
    if (!isAssignedOnlyRole || lead.assignedTo != widget.uid) {
      return lead;
    }
    return lead.copyWith(
      assignedTo: widget.uid,
      assignedToName: profile.fullName,
      teamId: profile.teamId,
      teamName: profile.teamName,
      managerId: profile.managerId,
      managerName: profile.managerName,
    );
  }

  Future<void> _archive(BuildContext context) async {
    final l = AppLocalizations.of(context)!;
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l.archiveLead),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l.archiveLeadConfirmation),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: reasonController,
                maxLines: 2,
                label: l.archiveReason,
              ),
            ],
          ),
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
        );
      },
    );
    if (confirmed != true || !context.mounted) {
      reasonController.dispose();
      return;
    }
    final cubit = context.read<LeadsCubit>();
    final success = await cubit.archiveLead(
      companyId: widget.companyId,
      leadId: widget.lead.id,
      archivedBy: widget.uid,
      actorName: widget.actorName,
      reason: reasonController.text.trim(),
    );
    reasonController.dispose();
    if (context.mounted && success) {
      context.go(RouteNames.leads);
    }
  }

  Future<void> _restore(BuildContext context) async {
    final l = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l.restoreRecord),
        content: Text(l.restoreRecordConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l.restore),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) {
      return;
    }
    final cubit = context.read<LeadsCubit>();
    final success = await cubit.restoreLead(
      companyId: widget.companyId,
      leadId: widget.lead.id,
      restoredBy: widget.uid,
      actorName: widget.actorName,
    );
    if (context.mounted && success) {
      context.go(RouteNames.leads);
    }
  }

  void _markContactedToday(BuildContext context) {
    final now = DateTime.now();
    final nextStatus = widget.lead.status == LeadStatus.newLead
        ? LeadStatus.contacted
        : widget.lead.status;
    _updateLeadFromDetails(
      context,
      widget.lead.copyWith(
        status: nextStatus,
        lastContactAt: now,
        updatedAt: now,
        updatedBy: widget.uid,
      ),
      successAction: LeadsAction.markContactedToday,
    );
  }

  Future<void> _scheduleFollowUp(BuildContext context) async {
    final today = DateUtils.dateOnly(DateTime.now());
    final current = widget.lead.nextFollowUpAt;
    final initialDate = current == null
        ? today
        : DateUtils.dateOnly(current.toLocal()).isBefore(today)
            ? today
            : DateUtils.dateOnly(current.toLocal());
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: today,
      lastDate: DateTime(2100, 12, 31),
    );
    if (pickedDate == null || !context.mounted) {
      return;
    }

    final now = DateTime.now();
    _updateLeadFromDetails(
      context,
      widget.lead.copyWith(
        nextFollowUpAt: DateUtils.dateOnly(pickedDate),
        updatedAt: now,
        updatedBy: widget.uid,
      ),
    );
  }
}



class _LeadSmartSuggestion {
  const _LeadSmartSuggestion({
    required this.title,
    required this.body,
    required this.icon,
    required this.primaryLabel,
    this.onPrimaryAction,
  });

  final String title;
  final String body;
  final IconData icon;
  final String primaryLabel;
  final VoidCallback? onPrimaryAction;
}

class _LeadSmartSuggestionCard extends StatelessWidget {
  const _LeadSmartSuggestionCard({required this.suggestion});

  final _LeadSmartSuggestion suggestion;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.inputSurface(context),
        border: Border.all(color: AppColors.borderColor(context)),
        borderRadius: AppRadius.large,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 680;
          final icon = Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(suggestion.icon, color: AppColors.primary, size: 22),
          );
          final text = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppStatusBadge(
                label: l.journeyRecommendedNextAction,
                tone: AppStatusTone.warning,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                suggestion.title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                suggestion.body,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondaryColor(context),
                      height: 1.35,
                    ),
              ),
            ],
          );
          final action = suggestion.onPrimaryAction == null
              ? null
              : AppButton(
                  label: suggestion.primaryLabel,
                  icon: Icons.arrow_forward_rounded,
                  variant: AppButtonVariant.secondary,
                  isExpanded: isNarrow,
                  onPressed: suggestion.onPrimaryAction,
                );

          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    icon,
                    const SizedBox(width: AppSpacing.md),
                    Expanded(child: text),
                  ],
                ),
                if (action != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  action,
                ],
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              icon,
              const SizedBox(width: AppSpacing.md),
              Expanded(child: text),
              if (action != null) ...[
                const SizedBox(width: AppSpacing.md),
                action,
              ],
            ],
          );
        },
      ),
    );
  }
}

class _LeadDetailsActions extends StatelessWidget {
  const _LeadDetailsActions({
    required this.canEdit,
    required this.canArchive,
    required this.isArchived,
    required this.isSaving,
    required this.onEdit,
    required this.onMarkContactedToday,
    required this.onScheduleFollowUp,
    required this.onArchive,
    required this.onRestore,
  });

  final bool canEdit;
  final bool canArchive;
  final bool isArchived;
  final bool isSaving;
  final VoidCallback onEdit;
  final VoidCallback onMarkContactedToday;
  final VoidCallback onScheduleFollowUp;
  final VoidCallback onArchive;
  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final isNarrow = MediaQuery.sizeOf(context).width < 720;

    final actions = <Widget>[
          if (canEdit && !isArchived)
            AppButton(
              label: l.editLead,
              icon: Icons.edit_outlined,
              isExpanded: isNarrow,
              onPressed: onEdit,
            ),
          if (canEdit && !isArchived)
            AppButton(
              label: l.markContactedToday,
              icon: Icons.today_outlined,
              variant: AppButtonVariant.secondary,
              isExpanded: isNarrow,
              onPressed: isSaving ? null : onMarkContactedToday,
            ),
          if (canEdit && !isArchived)
            AppButton(
              label: l.scheduleFollowUp,
              icon: Icons.event_available_outlined,
              variant: AppButtonVariant.secondary,
              isExpanded: isNarrow,
              onPressed: isSaving ? null : onScheduleFollowUp,
            ),
          if (canArchive && !isArchived)
            AppButton(
              label: l.archiveLead,
              icon: Icons.archive_outlined,
              variant: AppButtonVariant.danger,
              isExpanded: isNarrow,
              onPressed: isSaving ? null : onArchive,
            ),
          if (canArchive && isArchived)
            AppButton(
              label: l.restore,
              icon: Icons.unarchive_outlined,
              variant: AppButtonVariant.secondary,
              isExpanded: isNarrow,
              onPressed: isSaving ? null : onRestore,
            ),
        ];

        if (actions.isEmpty) {
          return const SizedBox.shrink();
        }

        if (isNarrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var index = 0; index < actions.length; index++) ...[
                actions[index],
                if (index != actions.length - 1)
                  const SizedBox(height: AppSpacing.xs),
              ],
            ],
          );
        }

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      alignment: WrapAlignment.start,
      children: actions,
    );
  }
}

class _LeadDetailsTab {
  const _LeadDetailsTab({required this.label, required this.icon});

  final String label;
  final IconData icon;
}

class _LeadDetailsTabBar extends StatelessWidget {
  const _LeadDetailsTabBar({required this.tabs});

  final List<_LeadDetailsTab> tabs;

  @override
  Widget build(BuildContext context) {
    return MasarTabBar(
      compact: true,
      fullWidth: true,
      tabs: [
        for (final tab in tabs) MasarTabItem(label: tab.label, icon: tab.icon),
      ],
    );
  }
}

class _TimelineSection extends StatelessWidget {
  const _TimelineSection({
    required this.timeline,
    required this.users,
    required this.scrollable,
  });

  final List<LeadTimelineEvent> timeline;
  final List<UserProfile> users;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final content = <Widget>[
      if (timeline.isEmpty) Text(l.noTimelineEvents),
      for (int i = 0; i < timeline.length; i++)
        _TimelineItem(
          event: timeline[i],
          isLast: i == timeline.length - 1,
          users: users,
        ),
    ];

    Widget buildTimelineBody() {
      final body = SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: content,
        ),
      );

      if (!scrollable) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: content,
        );
      }

      return body;
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.inputSurface(context),
        border: Border.all(color: AppColors.borderColor(context)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final body = buildTimelineBody();
          final timelineBody = scrollable && constraints.hasBoundedHeight
              ? Expanded(child: body)
              : body;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: scrollable ? MainAxisSize.max : MainAxisSize.min,
            children: [
              Text(
                l.timeline,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppSpacing.sm),
              timelineBody,
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
    final description = _timelineDescription(l, event, users);

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
                Expanded(
                  child: Container(
                    width: 2,
                    color: AppColors.borderColor(context),
                  ),
                ),
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
                    _timelineDateTimeLabel(event.createdAt),
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


String _timelineDateTimeLabel(DateTime value) {
  final now = DateTime.now();
  final safeValue = value.isAfter(now.add(const Duration(minutes: 5))) ? now : value;
  final local = safeValue.toLocal();
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '${local.year}-$month-$day $hour:$minute';
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
      return l.leadReassignedFromToBy(
        _timelineValueLabel(l, event.description, event.oldValue, users),
        _timelineValueLabel(l, event.description, event.newValue, users),
        actor,
      );
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

String _timelineDescription(
  AppLocalizations l,
  LeadTimelineEvent event,
  List<UserProfile> users,
) {
  if (event.title == 'note_added') {
    return event.description;
  }
  if (event.oldValue.isEmpty && event.newValue.isEmpty) {
    return '';
  }
  if (event.title == 'lead_reassigned') {
    return '';
  }
  return l.changedFromTo(
    _timelineValueLabel(l, event.description, event.oldValue, users),
    _timelineValueLabel(l, event.description, event.newValue, users),
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
    case 'sourceDetails':
      return l.sourceDetails;
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
    case 'lastContactAt':
      return l.lastContact;
    case 'nextFollowUpAt':
      return l.nextFollowUp;
    default:
      return field;
  }
}

String _timelineValueLabel(
  AppLocalizations l,
  String field,
  String value,
  List<UserProfile> users,
) {
  if (field == 'status') {
    return _statusValueLabel(l, value);
  }
  if (field == 'source') {
    return _sourceValueLabel(l, value);
  }
  if (field == 'priority') {
    return _priorityValueLabel(l, value);
  }
  if (field == 'assignedTo') {
    return _assigneeName(users, value, l);
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
  if (!_looksLikeUid(uid)) {
    return uid;
  }
  return l.assignedUserUnavailable;
}

bool _looksLikeUid(String value) {
  return RegExp(r'^[A-Za-z0-9_-]{20,}$').hasMatch(value);
}

Stream<List<UserProfile>> _watchActiveUsers(String companyId) {
  final repository = UserProfileRepositoryImpl(
    remoteDataSource: FirestoreUserProfileRemoteDataSource(),
  );
  return WatchActiveUsersUseCase(repository)(companyId: companyId);
}


String _leadStatusValueForNba(LeadStatus status) {
  return switch (status) {
    LeadStatus.newLead => 'new',
    LeadStatus.contacted => 'contacted',
    LeadStatus.interested => 'interested',
    LeadStatus.visitScheduled => 'visitScheduled',
    LeadStatus.negotiation => 'negotiation',
    LeadStatus.won => 'won',
    LeadStatus.lost => 'lost',
  };
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

String _sourceDisplayLabel(AppLocalizations l, Lead lead) {
  final sourceLabel = _sourceValueLabel(l, lead.source.name);
  if (lead.source != LeadSource.other || lead.sourceDetails.trim().isEmpty) {
    return sourceLabel;
  }

  return '$sourceLabel - ${lead.sourceDetails.trim()}';
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

String _formatNullableDate(DateTime? value) {
  if (value == null) {
    return '';
  }

  final local = value.toLocal();
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  return '${local.year}-$month-$day';
}
