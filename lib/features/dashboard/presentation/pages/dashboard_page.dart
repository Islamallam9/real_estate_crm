import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' as intl;
import '../../../../core/constants/role_constants.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/permissions/app_permission.dart';
import '../../../../core/permissions/company_feature_gate.dart';
import '../../../../core/permissions/permission_service.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_status_badge.dart';
import '../../../../core/widgets/crm_app_shell.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../appointments/domain/entities/appointment.dart';
import '../../../appointments/presentation/cubit/appointments_cubit.dart';
import '../../../appointments/presentation/cubit/appointments_state.dart';
import '../../../appointments/presentation/widgets/appointments_scope.dart';
import '../../../audit_logs/domain/entities/audit_log.dart';
import '../../../audit_logs/presentation/cubit/audit_logs_cubit.dart';
import '../../../audit_logs/presentation/cubit/audit_logs_state.dart';
import '../../../audit_logs/presentation/widgets/audit_logs_scope.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../clients/domain/entities/client.dart';
import '../../../clients/presentation/cubit/clients_cubit.dart';
import '../../../clients/presentation/cubit/clients_state.dart';
import '../../../clients/presentation/widgets/clients_scope.dart';
import '../../../deals/domain/entities/deal.dart';
import '../../../deals/presentation/cubit/deals_cubit.dart';
import '../../../deals/presentation/cubit/deals_state.dart';
import '../../../deals/presentation/widgets/deal_card.dart';
import '../../../deals/presentation/widgets/deals_scope.dart';
import '../../../leads/domain/entities/lead.dart';
import '../../../leads/presentation/cubit/leads_cubit.dart';
import '../../../leads/presentation/cubit/leads_state.dart';
import '../../../leads/presentation/widgets/leads_scope.dart';
import '../../../properties/domain/entities/property.dart';
import '../../../properties/presentation/cubit/properties_cubit.dart';
import '../../../properties/presentation/cubit/properties_state.dart';
import '../../../properties/presentation/widgets/properties_scope.dart';
import '../../../tasks/domain/entities/crm_task.dart';
import '../../../tasks/presentation/cubit/tasks_cubit.dart';
import '../../../tasks/presentation/cubit/tasks_state.dart';
import '../../../tasks/presentation/widgets/tasks_scope.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({
    super.key,
    this.platformPreviewCompanyId,
    this.platformPreviewCompanyName,
  });

  final String? platformPreviewCompanyId;
  final String? platformPreviewCompanyName;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final previewCompanyId = platformPreviewCompanyId?.trim() ?? '';

    if (previewCompanyId.isNotEmpty) {
      return _PlatformDashboardPreviewScaffold(
        companyId: previewCompanyId,
        companyName: platformPreviewCompanyName?.trim(),
      );
    }

    return CrmAppShell(
      selectedItem: CrmNavigationItem.dashboard,
      title: l.dashboard,
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
            return AppErrorView(message: l.missingCompanyProfile);
          }

          return _DashboardScopes(
            child: _DashboardContent(
              companyId: companyId,
              authState: authState,
            ),
          );
        },
      ),
    );
  }
}

class _PlatformDashboardPreviewScaffold extends StatelessWidget {
  const _PlatformDashboardPreviewScaffold({
    required this.companyId,
    required this.companyName,
  });

  final String companyId;
  final String? companyName;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.appBackground(context),
      appBar: AppBar(
        leading: IconButton(
          tooltip: l.back,
          onPressed: () => context.go(RouteNames.platform),
          icon: const BackButtonIcon(),
        ),
        title: Text(
          (companyName == null || companyName!.isEmpty)
              ? l.dashboard
              : companyName!,
        ),
        actions: [
          Padding(
            padding: const EdgeInsetsDirectional.only(end: AppSpacing.md),
            child: Center(
              child: AppStatusBadge(
                label: l.readOnlyPreview,
                tone: AppStatusTone.info,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: BlocBuilder<AuthBloc, AuthState>(
            builder: (context, authState) {
              if (!authState.isPlatformAdmin) {
                return AppErrorView(message: l.platformAccessDenied);
              }

              return _DashboardScopes(
                child: _DashboardContent(
                  companyId: companyId,
                  authState: authState,
                  platformPreview: true,
                  previewCompanyName: companyName,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _DashboardScopes extends StatelessWidget {
  const _DashboardScopes({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LeadsScope(
      child: PropertiesScope(
        child: ClientsScope(
          child: TasksScope(
            child: AppointmentsScope(
              child: DealsScope(
                child: AuditLogsScope(child: child),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardContent extends StatefulWidget {
  const _DashboardContent({
    required this.companyId,
    required this.authState,
    this.platformPreview = false,
    this.previewCompanyName,
  });

  final String companyId;
  final AuthState authState;
  final bool platformPreview;
  final String? previewCompanyName;

  @override
  State<_DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<_DashboardContent> {
  String? _watchKey;
  Timer? _clockTicker;

  @override
  void initState() {
    super.initState();
    _watchScopedDashboardData();
    _clockTicker = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void didUpdateWidget(covariant _DashboardContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldRole =
        oldWidget.authState.userProfile?.role ?? oldWidget.authState.user?.role;
    final newRole =
        widget.authState.userProfile?.role ?? widget.authState.user?.role;
    final oldUid = oldWidget.authState.user?.uid ?? '';
    final newUid = widget.authState.user?.uid ?? '';
    if (oldWidget.companyId != widget.companyId ||
        oldWidget.platformPreview != widget.platformPreview ||
        oldRole != newRole ||
        oldUid != newUid) {
      _watchKey = null;
      _watchScopedDashboardData();
    }
  }

  @override
  void dispose() {
    _clockTicker?.cancel();
    super.dispose();
  }

  void _watchScopedDashboardData() {
    if (widget.platformPreview) {
      _watchPlatformPreviewData();
      return;
    }

    final role =
        widget.authState.userProfile?.role ?? widget.authState.user?.role;
    final uid = widget.authState.user?.uid ?? '';
    if (role == null || uid.isEmpty) {
      return;
    }
    final managerTeamId = role == UserRole.manager
        ? widget.authState.userProfile?.teamId.trim()
        : null;
    final key = '${widget.companyId}:${role.name}:$uid:${managerTeamId ?? ''}';
    if (_watchKey == key) {
      return;
    }
    _watchKey = key;
    final assignedTo = _assignedOnlyScope(role) ? uid : null;
    final managerId = role == UserRole.manager ? uid : null;

    if (widget.authState.companyMetadata.isFeatureEnabled(CompanyFeature.leads) &&
        PermissionService.can(role, AppPermission.viewLeads)) {
      context.read<LeadsCubit>().watchLeads(
        companyId: widget.companyId,
        assignedTo: assignedTo,
        managerId: managerId,
      );
    }
    if (widget.authState.companyMetadata
            .isFeatureEnabled(CompanyFeature.properties) &&
        PermissionService.can(role, AppPermission.viewProperties)) {
      context.read<PropertiesCubit>().watchProperties(
        companyId: widget.companyId,
      );
    }
    if (widget.authState.companyMetadata.isFeatureEnabled(CompanyFeature.clients) &&
        PermissionService.can(role, AppPermission.viewClients)) {
      context.read<ClientsCubit>().watchClients(
        companyId: widget.companyId,
        assignedTo: assignedTo,
        managerId: managerId,
      );
    }
    if (widget.authState.companyMetadata.isFeatureEnabled(CompanyFeature.tasks) &&
        PermissionService.can(role, AppPermission.viewTasks)) {
      context.read<TasksCubit>().watchTasks(
        companyId: widget.companyId,
        assignedTo: assignedTo,
        managerId: managerId,
      );
    }
    if (widget.authState.companyMetadata
            .isFeatureEnabled(CompanyFeature.appointments) &&
        PermissionService.can(role, AppPermission.viewAppointments)) {
      context.read<AppointmentsCubit>().watchAppointments(
        companyId: widget.companyId,
        assignedTo: assignedTo,
        managerId: managerId,
      );
    }
    if (widget.authState.companyMetadata.isFeatureEnabled(CompanyFeature.deals) &&
        PermissionService.can(role, AppPermission.viewDeals)) {
      context.read<DealsCubit>().watchDeals(
        companyId: widget.companyId,
        role: role,
        currentUserId: uid,
      );
    }
    if (widget.authState.companyMetadata.isFeatureEnabled(CompanyFeature.auditLogs) &&
        _canViewRecentActivity(widget.authState)) {
      context.read<AuditLogsCubit>().watchAuditLogs(
        companyId: widget.companyId,
        managerId: role == UserRole.manager ? uid : null,
        teamId: managerTeamId,
      );
    }
  }

  void _retry() {
    if (widget.platformPreview) {
      _watchPlatformPreviewData();
      return;
    }

    final role =
        widget.authState.userProfile?.role ?? widget.authState.user?.role;
    final uid = widget.authState.user?.uid ?? '';
    final assignedTo = _assignedOnlyScope(role) ? uid : null;
    final managerId = role == UserRole.manager ? uid : null;
    final managerTeamId = role == UserRole.manager
        ? widget.authState.userProfile?.teamId.trim()
        : null;

    if (role != null &&
        widget.authState.companyMetadata.isFeatureEnabled(CompanyFeature.leads) &&
        PermissionService.can(role, AppPermission.viewLeads)) {
      context.read<LeadsCubit>().watchLeads(
        companyId: widget.companyId,
        assignedTo: assignedTo,
        managerId: managerId,
      );
    }
    if (role != null &&
        widget.authState.companyMetadata
            .isFeatureEnabled(CompanyFeature.properties) &&
        PermissionService.can(role, AppPermission.viewProperties)) {
      context.read<PropertiesCubit>().watchProperties(
        companyId: widget.companyId,
      );
    }
    if (role != null &&
        widget.authState.companyMetadata.isFeatureEnabled(CompanyFeature.clients) &&
        PermissionService.can(role, AppPermission.viewClients)) {
      context.read<ClientsCubit>().watchClients(
        companyId: widget.companyId,
        assignedTo: assignedTo,
        managerId: managerId,
      );
    }
    if (role != null &&
        widget.authState.companyMetadata.isFeatureEnabled(CompanyFeature.tasks) &&
        PermissionService.can(role, AppPermission.viewTasks)) {
      context.read<TasksCubit>().watchTasks(
        companyId: widget.companyId,
        assignedTo: assignedTo,
        managerId: managerId,
      );
    }
    if (role != null &&
        widget.authState.companyMetadata
            .isFeatureEnabled(CompanyFeature.appointments) &&
        PermissionService.can(role, AppPermission.viewAppointments)) {
      context.read<AppointmentsCubit>().watchAppointments(
        companyId: widget.companyId,
        assignedTo: assignedTo,
        managerId: managerId,
      );
    }
    if (role != null &&
        uid.isNotEmpty &&
        widget.authState.companyMetadata.isFeatureEnabled(CompanyFeature.deals) &&
        PermissionService.can(role, AppPermission.viewDeals)) {
      context.read<DealsCubit>().watchDeals(
        companyId: widget.companyId,
        role: role,
        currentUserId: uid,
      );
    }
    if (widget.authState.companyMetadata.isFeatureEnabled(CompanyFeature.auditLogs) &&
        _canViewRecentActivity(widget.authState)) {
      context.read<AuditLogsCubit>().watchAuditLogs(
        companyId: widget.companyId,
        managerId: role == UserRole.manager ? uid : null,
        teamId: managerTeamId,
      );
    }
  }

  void _watchPlatformPreviewData() {
    context.read<LeadsCubit>().watchLeads(companyId: widget.companyId);
    context.read<PropertiesCubit>().watchProperties(companyId: widget.companyId);
    context.read<ClientsCubit>().watchClients(companyId: widget.companyId);
    context.read<TasksCubit>().watchTasks(companyId: widget.companyId);
    context.read<DealsCubit>().watchDeals(
      companyId: widget.companyId,
      role: UserRole.admin,
      currentUserId: widget.authState.user?.uid ?? '',
    );
    context.read<AuditLogsCubit>().watchAuditLogs(companyId: widget.companyId);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LeadsCubit, LeadsState>(
      builder: (context, leadsState) {
        return BlocBuilder<PropertiesCubit, PropertiesState>(
          builder: (context, propertiesState) {
            return BlocBuilder<ClientsCubit, ClientsState>(
              builder: (context, clientsState) {
                return BlocBuilder<TasksCubit, TasksState>(
                  builder: (context, tasksState) {
                    return BlocBuilder<AppointmentsCubit, AppointmentsState>(
                      builder: (context, appointmentsState) {
                        return BlocBuilder<DealsCubit, DealsState>(
                          builder: (context, dealsState) {
                            final appointmentsEnabled = _canViewAppointments(
                              widget.authState,
                              platformPreview: widget.platformPreview,
                            );
                        final data = _DashboardData(
                          leads: leadsState.leads,
                          properties: propertiesState.properties,
                          clients: clientsState.clients,
                          tasks: tasksState.tasks,
                          appointments: appointmentsState.appointments,
                          deals: dealsState.deals,
                        );

                        final isLoading =
                            leadsState.status == LeadsStatus.loading &&
                                leadsState.leads.isEmpty ||
                            propertiesState.status ==
                                    PropertiesStatus.loading &&
                                propertiesState.properties.isEmpty ||
                            clientsState.status == ClientsStatus.loading &&
                                clientsState.clients.isEmpty ||
                            tasksState.status == TasksStatus.loading &&
                                tasksState.tasks.isEmpty ||
                            appointmentsEnabled &&
                                appointmentsState.status ==
                                    AppointmentsStatus.loading &&
                                appointmentsState.appointments.isEmpty ||
                            dealsState.status == DealsStatus.loading &&
                                dealsState.deals.isEmpty;

                        final hasInitialFailure =
                            leadsState.status == LeadsStatus.failure &&
                                leadsState.leads.isEmpty ||
                            propertiesState.status ==
                                    PropertiesStatus.failure &&
                                propertiesState.properties.isEmpty ||
                            clientsState.status == ClientsStatus.failure &&
                                clientsState.clients.isEmpty ||
                            tasksState.status == TasksStatus.failure &&
                                tasksState.tasks.isEmpty ||
                            appointmentsEnabled &&
                                appointmentsState.status ==
                                    AppointmentsStatus.failure &&
                                appointmentsState.appointments.isEmpty ||
                            dealsState.status == DealsStatus.failure &&
                                dealsState.deals.isEmpty;

                        final failureMessage =
                            leadsState.message ??
                            propertiesState.message ??
                            clientsState.message ??
                            tasksState.message ??
                            appointmentsState.message ??
                            dealsState.message;

                        return _DashboardView(
                          data: data,
                          authState: widget.authState,
                          platformPreview: widget.platformPreview,
                          previewCompanyName: widget.previewCompanyName,
                          isLoading: isLoading,
                          hasInitialFailure: hasInitialFailure,
                          failureMessage: failureMessage,
                          onRetry: _retry,
                        );
                          },
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}

class _RecentActivityPanel extends StatelessWidget {
  const _RecentActivityPanel({
    required this.authState,
    this.platformPreview = false,
  });

  final AuthState authState;
  final bool platformPreview;

  @override
  Widget build(BuildContext context) {
    final role = authState.userProfile?.role ?? authState.user?.role;
    final canViewRecentActivity =
        platformPreview || role == UserRole.admin || role == UserRole.manager;

    if (!canViewRecentActivity) {
      return const SizedBox.shrink();
    }

    final l = AppLocalizations.of(context)!;
    final isManager = !platformPreview && role == UserRole.manager;

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionTitle(
            title: isManager ? l.teamRecentActivity : l.dashboardRecentActivity,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            isManager
                ? l.teamRecentActivitySubtitle
                : l.dashboardRecentActivitySubtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondaryColor(context),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          BlocBuilder<AuditLogsCubit, AuditLogsState>(
            builder: (context, state) {
              if (state.status == AuditLogsStatus.loading &&
                  state.logs.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state.status == AuditLogsStatus.failure) {
                return _CompactEmpty(
                  message: l.dashboardUnableToLoadRecentActivity,
                );
              }

              final items = state.logs
                  .take(5)
                  .map(
                    (log) => _auditLogActivityItem(
                      context,
                      log,
                      readOnly: platformPreview,
                    ),
                  )
                  .toList();

              if (items.isEmpty) {
                return _CompactEmpty(
                  message: isManager
                      ? l.noRecentTeamActivity
                      : l.dashboardNoRecentActivity,
                );
              }

              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: Column(
                  key: ValueKey(items.map((item) => item.id).join('|')),
                  children: [
                    for (var index = 0; index < items.length; index++) ...[
                      _RecentActivityTile(item: items[index]),
                      if (index != items.length - 1)
                        const SizedBox(height: AppSpacing.sm),
                    ],
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _RecentActivityItem {
  const _RecentActivityItem({
    required this.id,
    required this.action,
    required this.title,
    required this.subtitle,
    required this.actorName,
    required this.time,
    required this.timeLabel,
    required this.icon,
    required this.tone,
    this.onTap,
  });

  final String id;
  final String action;
  final String title;
  final String subtitle;
  final String actorName;
  final DateTime time;
  final String timeLabel;
  final IconData icon;
  final AppStatusTone tone;
  final void Function(BuildContext context)? onTap;
}

_RecentActivityItem _auditLogActivityItem(
  BuildContext context,
  AuditLog log, {
  required bool readOnly,
}) {
  final l = AppLocalizations.of(context)!;
  final action = _auditActionLabel(l, log.action);
  final module = _auditModuleLabel(l, log.module);
  final details = _auditLogDetails(l, log);

  return _RecentActivityItem(
    id: '${log.id}-${log.createdAt.millisecondsSinceEpoch}',
    action: l.dashboardAuditActionLabel(module, action),
    title: _fallback(log.recordTitle, module),
    subtitle: _fallback(details, log.recordSubtitle.trim()),
    actorName: _fallback(
      log.actorName,
      _fallback(log.actorEmail, l.unknownUser),
    ),
    time: log.createdAt,
    timeLabel: _relativeTimeLabel(context, log.createdAt),
    icon: _auditModuleIcon(log.module),
    tone: _auditActionTone(log.action),
    onTap: readOnly ? null : _auditRecordTap(log),
  );
}

String _auditLogDetails(AppLocalizations l, AuditLog log) {
  final changedFields = log.metadata['changedFields'];
  if (changedFields is Iterable) {
    final details = <String>[];
    for (final entry in changedFields) {
      if (entry is! Map) {
        continue;
      }
      final field = (entry['field'] ?? '').toString();
      final oldValue = (entry['oldValue'] ?? '').toString();
      final newValue = (entry['newValue'] ?? '').toString();
      if (field.isEmpty || oldValue == newValue) {
        continue;
      }
      details.add(
        '${_auditFieldLabel(l, field)}: '
        '${_auditChangeLabel(l, field, oldValue, newValue)}',
      );
    }
    if (details.isNotEmpty) {
      return details.take(3).join(' • ');
    }
  }

  final previousStatus = (log.metadata['previousStatus'] ?? '').toString();
  final newStatus = (log.metadata['newStatus'] ?? '').toString();
  if (previousStatus.isNotEmpty && newStatus.isNotEmpty) {
    return '${l.statusUpdated}: '
        '${_auditChangeLabel(l, 'status', previousStatus, newStatus)}';
  }

  final assignedToName = (log.metadata['assignedToName'] ?? '').toString();
  if (assignedToName.isNotEmpty) {
    return '${l.assignedToLabel}: $assignedToName';
  }

  return '';
}

String _auditChangeLabel(
  AppLocalizations l,
  String field,
  String oldValue,
  String newValue,
) {
  final oldLabel = _directionalAuditValue(_auditValueLabel(l, field, oldValue));
  final newLabel = _directionalAuditValue(_auditValueLabel(l, field, newValue));
  final localeName = l.localeName.toLowerCase();
  if (localeName.startsWith('ar')) {
    return 'من $oldLabel إلى $newLabel';
  }
  return '$oldLabel → $newLabel';
}

String _directionalAuditValue(String value) {
  if (value.trim().isEmpty) {
    return value;
  }
  return '⁨$value⁩';
}

String _auditFieldLabel(AppLocalizations l, String field) {
  return switch (field) {
    'fullName' => l.fullNameUpdated,
    'phone' => l.phoneUpdated,
    'email' => l.emailUpdated,
    'source' => l.sourceUpdated,
    'sourceDetails' => l.sourceDetails,
    'status' => l.statusUpdated,
    'priority' => l.priorityUpdated,
    'budget' => l.budgetUpdated,
    'budgetMin' => l.budgetMin,
    'budgetMax' => l.budgetMax,
    'preferredLocation' => l.preferredLocationUpdated,
    'preferredPropertyType' => l.preferredPropertyTypeUpdated,
    'assignedTo' => l.assignedToLabel,
    'notes' => l.notes,
    'lastContactAt' => l.lastContact,
    'nextFollowUpAt' => l.nextFollowUp,
    _ => field,
  };
}

String _auditValueLabel(AppLocalizations l, String field, String value) {
  if (value.trim().isEmpty) {
    return l.notAvailable;
  }
  return switch (field) {
    'status' => _auditStatusValueLabel(l, value),
    'source' => _auditSourceValueLabel(l, value),
    'priority' => _auditPriorityValueLabel(l, value),
    _ => value,
  };
}

String _auditStatusValueLabel(AppLocalizations l, String value) {
  return switch (value) {
    'newLead' || 'new' => l.newLeadStatus,
    'contacted' => l.contactedLeadStatus,
    'interested' => l.interestedLeadStatus,
    'visitScheduled' => l.visitScheduledLeadStatus,
    'negotiation' => l.negotiationLeadStatus,
    'won' => l.wonLeadStatus,
    'lost' => l.lostLeadStatus,
    _ => value,
  };
}

String _auditSourceValueLabel(AppLocalizations l, String value) {
  return switch (value) {
    'facebook' => l.facebook,
    'website' => l.website,
    'phoneCall' => l.phoneCall,
    'whatsapp' => l.whatsapp,
    'referral' => l.referral,
    'walkIn' => l.walkIn,
    'other' => l.other,
    _ => value,
  };
}

String _auditPriorityValueLabel(AppLocalizations l, String value) {
  return switch (value) {
    'low' => l.low,
    'medium' => l.medium,
    'high' => l.high,
    _ => value,
  };
}

String _auditActionLabel(AppLocalizations l, AuditLogAction action) {
  return switch (action) {
    AuditLogAction.create => l.dashboardAuditCreated,
    AuditLogAction.update => l.dashboardAuditUpdated,
    AuditLogAction.archive => l.dashboardAuditArchived,
    AuditLogAction.deactivate => l.dashboardAuditDeactivated,
    AuditLogAction.assign => l.dashboardAuditAssigned,
    AuditLogAction.statusChange => l.dashboardAuditStatusChanged,
    AuditLogAction.stageChange => l.dashboardAuditStageChanged,
    AuditLogAction.complete => l.dashboardAuditCompleted,
    AuditLogAction.cancel => l.dashboardAuditCancelled,
    AuditLogAction.imageAdded => l.dashboardAuditImageAdded,
    AuditLogAction.imageRemoved => l.dashboardAuditImageRemoved,
  };
}

String _auditModuleLabel(AppLocalizations l, AuditLogModule module) {
  return switch (module) {
    AuditLogModule.leads => l.dashboardAuditLead,
    AuditLogModule.clients => l.dashboardAuditClient,
    AuditLogModule.properties => l.dashboardAuditProperty,
    AuditLogModule.tasks => l.dashboardAuditTask,
    AuditLogModule.deals => l.dashboardAuditDeal,
  };
}

IconData _auditModuleIcon(AuditLogModule module) {
  return switch (module) {
    AuditLogModule.leads => Icons.person_search_outlined,
    AuditLogModule.clients => Icons.person_outline_rounded,
    AuditLogModule.properties => Icons.business_outlined,
    AuditLogModule.tasks => Icons.checklist_rtl_rounded,
    AuditLogModule.deals => Icons.handshake_outlined,
  };
}

AppStatusTone _auditActionTone(AuditLogAction action) {
  return switch (action) {
    AuditLogAction.create ||
    AuditLogAction.imageAdded => AppStatusTone.success,
    AuditLogAction.archive ||
    AuditLogAction.deactivate ||
    AuditLogAction.cancel ||
    AuditLogAction.imageRemoved => AppStatusTone.neutral,
    AuditLogAction.statusChange ||
    AuditLogAction.stageChange => AppStatusTone.warning,
    AuditLogAction.complete => AppStatusTone.success,
    AuditLogAction.assign => AppStatusTone.info,
    AuditLogAction.update => AppStatusTone.info,
  };
}

void Function(BuildContext context)? _auditRecordTap(AuditLog log) {
  if (log.recordId.trim().isEmpty) {
    return null;
  }

  return switch (log.module) {
    AuditLogModule.leads => (context) =>
        context.go(RouteNames.leadDetails(log.recordId)),
    AuditLogModule.clients => (context) =>
        context.go(RouteNames.clientDetails(log.recordId)),
    AuditLogModule.properties => (context) =>
        context.go(RouteNames.propertyDetails(log.recordId)),
    AuditLogModule.tasks => (context) => context.go(RouteNames.tasks),
    AuditLogModule.deals => (context) =>
        context.go(RouteNames.dealDetails(log.recordId)),
  };
}

class _RecentActivityTile extends StatelessWidget {
  const _RecentActivityTile({required this.item});

  final _RecentActivityItem item;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final color = _toneColor(context, item.tone);
    final meta = item.subtitle.trim().isEmpty
        ? '${l.byUser(item.actorName)} • ${item.timeLabel}'
        : '${item.subtitle} • ${l.byUser(item.actorName)} • ${item.timeLabel}';

    return TweenAnimationBuilder<double>(
      key: ValueKey(item.id),
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 14 * (1 - value)),
            child: child,
          ),
        );
      },
      child: _HoverLiftPanel(
        borderRadius: AppRadius.large,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: item.onTap == null ? null : () => item.onTap!(context),
            borderRadius: AppRadius.large,
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.inputSurface(context),
                borderRadius: AppRadius.large,
              ),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Icon(item.icon, size: 18, color: color),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.action,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          meta,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: AppColors.textSecondaryColor(context),
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardView extends StatelessWidget {
  const _DashboardView({
    required this.data,
    required this.authState,
    required this.platformPreview,
    this.previewCompanyName,
    required this.isLoading,
    required this.hasInitialFailure,
    required this.failureMessage,
    required this.onRetry,
  });

  final _DashboardData data;
  final AuthState authState;
  final bool platformPreview;
  final String? previewCompanyName;
  final bool isLoading;
  final bool hasInitialFailure;
  final String? failureMessage;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final copy = _DashboardCopy.of(context);

    if (isLoading) {
      return const AppLoading();
    }

    if (hasInitialFailure) {
      return AppErrorView(
        message: localizeErrorMessage(l, failureMessage),
        onRetry: onRetry,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 860;
        final mobile = constraints.maxWidth < 600;
        final features = authState.companyMetadata;
        final leadsEnabled = features.isFeatureEnabled(CompanyFeature.leads);
        final clientsEnabled = features.isFeatureEnabled(CompanyFeature.clients);
        final propertiesEnabled =
            features.isFeatureEnabled(CompanyFeature.properties);
        final tasksEnabled = features.isFeatureEnabled(CompanyFeature.tasks);
        final dealsEnabled = features.isFeatureEnabled(CompanyFeature.deals);
        final appointmentsEnabled = _canViewAppointments(
          authState,
          platformPreview: platformPreview,
        );
        final auditLogsEnabled =
            features.isFeatureEnabled(CompanyFeature.auditLogs);
        final analyticsEnabled =
            leadsEnabled || tasksEnabled || propertiesEnabled || dealsEnabled;
        final canViewUnassignedLeads = _canViewUnassignedLeads(
          authState,
          platformPreview: platformPreview,
        );
        final quickAddActions = platformPreview
            ? <_QuickAddAction>[]
            : _quickAddActions(context, authState);

        if (mobile) {
          return _MobileDashboardTabs(
            data: data,
            authState: authState,
            platformPreview: platformPreview,
            previewCompanyName: previewCompanyName,
            leadsEnabled: leadsEnabled,
            tasksEnabled: tasksEnabled,
            dealsEnabled: dealsEnabled,
            appointmentsEnabled: appointmentsEnabled,
            auditLogsEnabled: auditLogsEnabled,
            analyticsEnabled: analyticsEnabled,
            canViewUnassignedLeads: canViewUnassignedLeads,
            quickAddActions: quickAddActions,
          );
        }

        return Stack(
          children: [
            SingleChildScrollView(
              padding: EdgeInsets.only(
                bottom: mobile && quickAddActions.isNotEmpty ? 88 : 0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _DashboardReveal(
                    id: 'welcome',
                    delay: Duration.zero,
                    child: _WelcomePanel(
                      authState: authState,
                      platformPreview: platformPreview,
                      previewCompanyName: previewCompanyName,
                    ),
                  ),
                  const SizedBox(height: _kDashboardSectionGap),

                  _DashboardReveal(
                    id: 'summary-grid',
                    delay: const Duration(milliseconds: 60),
                    child: _SummaryGrid(data: data, authState: authState),
                  ),
                  const SizedBox(height: _kDashboardSectionGap),

                  if (compact) ...[
                    if (analyticsEnabled)
                      _DashboardReveal(
                        id: 'analytics-compact',
                      delay: const Duration(milliseconds: 120),
                      child: _AnalyticsPanel(data: data, authState: authState),
                    ),

                    if (!mobile && !platformPreview && (leadsEnabled || clientsEnabled || propertiesEnabled)) ...[
                      const SizedBox(height: _kDashboardSectionGap),
                      _DashboardReveal(
                        id: 'actions-compact',
                        delay: const Duration(milliseconds: 160),
                        child: _ActionPanel(authState: authState),
                      ),
                    ],

                    if (auditLogsEnabled &&
                        _canViewRecentActivity(
                          authState,
                          platformPreview: platformPreview,
                        )) ...[
                      const SizedBox(height: _kDashboardSectionGap),
                      _DashboardReveal(
                        id: 'recent-activity-compact',
                        delay: const Duration(milliseconds: 200),
                        child: _RecentActivityPanel(
                          authState: authState,
                          platformPreview: platformPreview,
                        ),
                      ),
                    ],
                  ] else if (analyticsEnabled)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: _DashboardReveal(
                            id: 'analytics-desktop',
                            delay: const Duration(milliseconds: 120),
                            child: _AnalyticsPanel(data: data, authState: authState),
                          ),
                        ),
                        const SizedBox(width: _kDashboardSectionGap),
                        Expanded(
                          flex: 2,
                          child: Column(
                            children: [
                              if (!platformPreview &&
                                  (leadsEnabled || clientsEnabled || propertiesEnabled))
                                _DashboardReveal(
                                  id: 'actions-desktop',
                                  delay: const Duration(milliseconds: 160),
                                  child: _ActionPanel(authState: authState),
                                ),
                              if (auditLogsEnabled &&
                                  _canViewRecentActivity(
                                    authState,
                                    platformPreview: platformPreview,
                                  )) ...[
                                if (!platformPreview)
                                  const SizedBox(height: _kDashboardSectionGap),
                                _DashboardReveal(
                                  id: 'recent-activity-desktop',
                                  delay: const Duration(milliseconds: 200),
                                  child: _RecentActivityPanel(
                                    authState: authState,
                                    platformPreview: platformPreview,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: _kDashboardSectionGap),

                  if (compact) ...[
                    if (appointmentsEnabled)
                      _DashboardReveal(
                        id: 'appointments-compact',
                        delay: const Duration(milliseconds: 220),
                        child: _AppointmentsDashboardSection(data: data),
                      ),
                    if (appointmentsEnabled && (dealsEnabled || tasksEnabled))
                      const SizedBox(height: _kDashboardSectionGap),
                    if (dealsEnabled)
                      _DashboardReveal(
                        id: 'deals-compact',
                      delay: const Duration(milliseconds: 260),
                      child: _DealsDashboardSection(
                        data: data,
                        readOnly: platformPreview,
                      ),
                    ),
                    if (dealsEnabled && tasksEnabled)
                      const SizedBox(height: _kDashboardSectionGap),
                    if (tasksEnabled)
                      _DashboardReveal(
                        id: 'tasks-compact',
                      delay: const Duration(milliseconds: 300),
                      child: _TaskBreakdownSection(
                        data: data,
                        readOnly: platformPreview,
                      ),
                    ),
                  ] else if (appointmentsEnabled || leadsEnabled)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (appointmentsEnabled)
                          Expanded(
                            child: _DashboardReveal(
                              id: 'appointments-desktop',
                              delay: const Duration(milliseconds: 220),
                              child: _AppointmentsDashboardSection(data: data),
                            ),
                          ),
                        if (appointmentsEnabled && (dealsEnabled || tasksEnabled))
                          const SizedBox(width: _kDashboardSectionGap),
                        if (dealsEnabled)
                          Expanded(
                            child: _DashboardReveal(
                              id: 'deals-desktop',
                            delay: const Duration(milliseconds: 260),
                            child: _DealsDashboardSection(
                              data: data,
                              readOnly: platformPreview,
                            ),
                          ),
                        ),
                        if (dealsEnabled && tasksEnabled)
                          const SizedBox(width: _kDashboardSectionGap),
                        if (tasksEnabled)
                          Expanded(
                            child: _DashboardReveal(
                              id: 'tasks-desktop',
                            delay: const Duration(milliseconds: 300),
                            child: _TaskBreakdownSection(
                              data: data,
                              readOnly: platformPreview,
                            ),
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: _kDashboardSectionGap),

                  if (leadsEnabled && compact) ...[
                    _DashboardReveal(
                      id: 'today-followups-compact',
                      delay: const Duration(milliseconds: 300),
                      child: _LeadSection(
                        title: copy.todaysFollowUps,
                        leads: data.todaysFollowUps,
                        emptyMessage: l.noLeads,
                        readOnly: platformPreview,
                      ),
                    ),
                    if (canViewUnassignedLeads) ...[
                      const SizedBox(height: _kDashboardSectionGap),
                      _DashboardReveal(
                        id: 'unassigned-leads-compact',
                        delay: const Duration(milliseconds: 340),
                        child: _LeadSection(
                          title: copy.unassignedLeads,
                          leads: data.unassignedLeads,
                          emptyMessage: l.noLeads,
                          readOnly: platformPreview,
                        ),
                      ),
                    ],
                  ] else if (leadsEnabled)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _DashboardReveal(
                            id: 'today-followups-desktop',
                            delay: const Duration(milliseconds: 300),
                            child: _LeadSection(
                              title: copy.todaysFollowUps,
                              leads: data.todaysFollowUps,
                              emptyMessage: l.noLeads,
                              readOnly: platformPreview,
                            ),
                          ),
                        ),
                        if (canViewUnassignedLeads) ...[
                          const SizedBox(width: _kDashboardSectionGap),
                          Expanded(
                            child: _DashboardReveal(
                              id: 'unassigned-leads-desktop',
                              delay: const Duration(milliseconds: 340),
                              child: _LeadSection(
                                title: copy.unassignedLeads,
                                leads: data.unassignedLeads,
                                emptyMessage: l.noLeads,
                                readOnly: platformPreview,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),

                  const SizedBox(height: _kDashboardSectionGap),

                  if (leadsEnabled)
                    _DashboardReveal(
                      id: 'recently-updated-leads',
                    delay: const Duration(milliseconds: 380),
                    child: _LeadSection(
                      title: copy.recentlyUpdatedLeads,
                      leads: data.recentLeads,
                      emptyMessage: l.noLeads,
                      readOnly: platformPreview,
                    ),
                  ),
                ],
              ),
            ),
            if (mobile && quickAddActions.isNotEmpty)
              Positioned.fill(
                child: _MobileQuickAddFab(actions: quickAddActions),
              ),
          ],
        );
      },
    );
  }

  List<_QuickAddAction> _quickAddActions(
    BuildContext context,
    AuthState authState,
  ) {
    final l = AppLocalizations.of(context)!;
    final role = authState.userProfile?.role ?? authState.user?.role;
    final canCreateLead =
        authState.companyMetadata.isFeatureEnabled(CompanyFeature.leads) &&
        role != null && PermissionService.can(role, AppPermission.createLead);
    final canCreateClient =
        authState.companyMetadata.isFeatureEnabled(CompanyFeature.clients) &&
        (role == UserRole.admin || role == UserRole.manager);
    final canCreateDeal =
        authState.companyMetadata.isFeatureEnabled(CompanyFeature.deals) &&
        role != null && PermissionService.can(role, AppPermission.createDeal);

    return [
      if (canCreateLead)
        _QuickAddAction(
          label: l.addLead,
          icon: Icons.person_add_alt_outlined,
          onTap: () => context.go(RouteNames.leadsCreate),
        ),
      if (canCreateClient)
        _QuickAddAction(
          label: l.addClient,
          icon: Icons.group_add_outlined,
          onTap: () => context.go(RouteNames.clientsCreate),
        ),
      if (canCreateDeal)
        _QuickAddAction(
          label: l.addDeal,
          icon: Icons.handshake_outlined,
          onTap: () => context.go(RouteNames.dealsCreate),
        ),
    ];
  }
}


class _MobileDashboardTabs extends StatelessWidget {
  const _MobileDashboardTabs({
    required this.data,
    required this.authState,
    required this.platformPreview,
    required this.leadsEnabled,
    required this.tasksEnabled,
    required this.dealsEnabled,
    required this.appointmentsEnabled,
    required this.auditLogsEnabled,
    required this.analyticsEnabled,
    required this.canViewUnassignedLeads,
    required this.quickAddActions,
    this.previewCompanyName,
  });

  final _DashboardData data;
  final AuthState authState;
  final bool platformPreview;
  final String? previewCompanyName;
  final bool leadsEnabled;
  final bool tasksEnabled;
  final bool dealsEnabled;
  final bool appointmentsEnabled;
  final bool auditLogsEnabled;
  final bool analyticsEnabled;
  final bool canViewUnassignedLeads;
  final List<_QuickAddAction> quickAddActions;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final copy = _DashboardCopy.of(context);
    final tabs = <_MobileDashboardTab>[
      _MobileDashboardTab(
        label: l.dashboard,
        icon: Icons.space_dashboard_outlined,
        child: _MobileDashboardTabBody(
          hasQuickActions: quickAddActions.isNotEmpty,
          children: _withDashboardGaps([
            _DashboardReveal(
              id: 'mobile-welcome',
              delay: Duration.zero,
              child: _WelcomePanel(
                authState: authState,
                platformPreview: platformPreview,
                previewCompanyName: previewCompanyName,
              ),
            ),
            _DashboardReveal(
              id: 'mobile-summary-grid',
              delay: const Duration(milliseconds: 60),
              child: _SummaryGrid(data: data, authState: authState),
            ),
          ], gap: AppSpacing.sm),
        ),
      ),
      if (analyticsEnabled)
        _MobileDashboardTab(
          label: copy.visualAnalytics,
          icon: Icons.donut_large_outlined,
          child: _MobileDashboardTabBody(
            hasQuickActions: quickAddActions.isNotEmpty,
            children: _withDashboardGaps([
              _DashboardReveal(
                id: 'mobile-analytics',
                delay: const Duration(milliseconds: 80),
                child: _AnalyticsPanel(data: data, authState: authState),
              ),
            ], gap: AppSpacing.sm),
          ),
        ),
      if (dealsEnabled)
        _MobileDashboardTab(
          label: l.deals,
          icon: Icons.handshake_outlined,
          child: _MobileDashboardTabBody(
            hasQuickActions: quickAddActions.isNotEmpty,
            children: _withDashboardGaps([
              _DashboardReveal(
                id: 'mobile-deals',
                delay: const Duration(milliseconds: 120),
                child: _DealsDashboardSection(
                  data: data,
                  readOnly: platformPreview,
                ),
              ),
            ], gap: AppSpacing.sm),
          ),
        ),
      if (tasksEnabled)
        _MobileDashboardTab(
          label: l.tasks,
          icon: Icons.event_note_outlined,
          child: _MobileDashboardTabBody(
            hasQuickActions: quickAddActions.isNotEmpty,
            children: _withDashboardGaps([
              _DashboardReveal(
                id: 'mobile-tasks',
                delay: const Duration(milliseconds: 160),
                child: _TaskBreakdownSection(
                  data: data,
                  readOnly: platformPreview,
                ),
              ),
            ], gap: AppSpacing.sm),
          ),
        ),
      if (appointmentsEnabled)
        _MobileDashboardTab(
          label: l.appointments,
          icon: Icons.event_available_outlined,
          child: _MobileDashboardTabBody(
            hasQuickActions: quickAddActions.isNotEmpty,
            children: _withDashboardGaps([
              _DashboardReveal(
                id: 'mobile-appointments',
                delay: const Duration(milliseconds: 180),
                child: _AppointmentsDashboardSection(data: data),
              ),
            ], gap: AppSpacing.sm),
          ),
        ),
      if (leadsEnabled)
        _MobileDashboardTab(
          label: l.followUps,
          icon: Icons.event_available_outlined,
          child: _MobileDashboardTabBody(
            hasQuickActions: quickAddActions.isNotEmpty,
            children: _withDashboardGaps([
              _DashboardReveal(
                id: 'mobile-today-followups',
                delay: const Duration(milliseconds: 180),
                child: _LeadSection(
                  title: copy.todaysFollowUps,
                  leads: data.todaysFollowUps,
                  emptyMessage: l.noLeads,
                  readOnly: platformPreview,
                ),
              ),
              if (canViewUnassignedLeads)
                _DashboardReveal(
                  id: 'mobile-unassigned-leads',
                  delay: const Duration(milliseconds: 220),
                  child: _LeadSection(
                    title: copy.unassignedLeads,
                    leads: data.unassignedLeads,
                    emptyMessage: l.noLeads,
                    readOnly: platformPreview,
                  ),
                ),
              _DashboardReveal(
                id: 'mobile-recent-leads',
                delay: const Duration(milliseconds: 260),
                child: _LeadSection(
                  title: copy.recentlyUpdatedLeads,
                  leads: data.recentLeads,
                  emptyMessage: l.noLeads,
                  readOnly: platformPreview,
                ),
              ),
            ], gap: AppSpacing.sm),
          ),
        ),
      if (auditLogsEnabled &&
          _canViewRecentActivity(authState, platformPreview: platformPreview))
        _MobileDashboardTab(
          label: l.dashboardRecentActivity,
          icon: Icons.history_outlined,
          child: _MobileDashboardTabBody(
            hasQuickActions: quickAddActions.isNotEmpty,
            children: _withDashboardGaps([
              _DashboardReveal(
                id: 'mobile-recent-activity',
                delay: const Duration(milliseconds: 300),
                child: _RecentActivityPanel(
                  authState: authState,
                  platformPreview: platformPreview,
                ),
              ),
            ], gap: AppSpacing.sm),
          ),
        ),
    ];

    return Stack(
      children: [
        DefaultTabController(
          length: tabs.length,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _MobileDashboardTabBar(tabs: tabs),
              const SizedBox(height: AppSpacing.sm),
              Expanded(
                child: TabBarView(
                  physics: const BouncingScrollPhysics(),
                  children: [for (final tab in tabs) tab.child],
                ),
              ),
            ],
          ),
        ),
        if (quickAddActions.isNotEmpty)
          Positioned.fill(
            child: _MobileQuickAddFab(actions: quickAddActions),
          ),
      ],
    );
  }
}

class _MobileDashboardTab {
  const _MobileDashboardTab({
    required this.label,
    required this.icon,
    required this.child,
  });

  final String label;
  final IconData icon;
  final Widget child;
}

class _MobileDashboardTabBar extends StatelessWidget {
  const _MobileDashboardTabBar({required this.tabs});

  final List<_MobileDashboardTab> tabs;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.isDark(context)
        ? AppColors.darkSurfaceAlt
        : AppColors.cardSurface(context);
    return Container(
      decoration: BoxDecoration(
        color: colors,
        border: Border.all(color: AppColors.borderColor(context)),
        borderRadius: BorderRadius.circular(18),
      ),
      child: TabBar(
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: AppColors.selectedSurface(context),
          borderRadius: BorderRadius.circular(14),
        ),
        labelColor: AppColors.primaryColor(context),
        unselectedLabelColor: AppColors.textSecondaryColor(context),
        labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
        padding: const EdgeInsets.all(4),
        tabs: [
          for (final tab in tabs)
            Tab(
              iconMargin: const EdgeInsets.only(bottom: 2),
              icon: Icon(tab.icon, size: 18),
              text: tab.label,
            ),
        ],
      ),
    );
  }
}

class _MobileDashboardTabBody extends StatelessWidget {
  const _MobileDashboardTabBody({
    required this.children,
    required this.hasQuickActions,
  });

  final List<Widget> children;
  final bool hasQuickActions;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      padding: EdgeInsets.only(
        bottom: hasQuickActions ? 88 : AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

List<Widget> _withDashboardGaps(
  List<Widget> children, {
  double gap = _kDashboardSectionGap,
}) {
  return [
    for (var index = 0; index < children.length; index++) ...[
      children[index],
      if (index != children.length - 1) SizedBox(height: gap),
    ],
  ];
}

class _MobileQuickAddFab extends StatefulWidget {
  const _MobileQuickAddFab({required this.actions});

  final List<_QuickAddAction> actions;

  @override
  State<_MobileQuickAddFab> createState() => _MobileQuickAddFabState();
}

class _MobileQuickAddFabState extends State<_MobileQuickAddFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 190),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return Stack(
      children: [
        if (_isOpen)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _close,
            ),
          ),
        PositionedDirectional(
          end: AppSpacing.md,
          bottom: AppSpacing.md,
          child: SizedBox(
            width: 218,
            height: 220,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: AlignmentDirectional.bottomEnd,
              children: [
                for (var index = 0; index < widget.actions.length; index++)
                  _QuickAddMenuItem(
                    action: widget.actions[index],
                    index: index,
                    animation: _animation,
                    onTap: () {
                      _close();
                      widget.actions[index].onTap();
                    },
                  ),
                FloatingActionButton(
                  tooltip: l.quickAdd,
                  onPressed: _toggle,
                  shape: const CircleBorder(),
                  child: AnimatedRotation(
                    turns: _isOpen ? 0.125 : 0,
                    duration: const Duration(milliseconds: 190),
                    curve: Curves.easeOut,
                    child: const Icon(Icons.add),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _toggle() {
    setState(() => _isOpen = !_isOpen);
    if (_isOpen) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  void _close() {
    if (!_isOpen) {
      return;
    }
    setState(() => _isOpen = false);
    _controller.reverse();
  }
}

class _QuickAddMenuItem extends StatelessWidget {
  const _QuickAddMenuItem({
    required this.action,
    required this.index,
    required this.animation,
    required this.onTap,
  });

  final _QuickAddAction action;
  final int index;
  final Animation<double> animation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final direction = Directionality.of(context);
    final horizontal = direction == TextDirection.rtl ? 64.0 : -64.0;
    final offset = switch (index) {
      0 => const Offset(0, -72),
      1 => Offset(horizontal, -42),
      _ => Offset(horizontal, -112),
    };

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return PositionedDirectional(
          end: offset.dx.abs() < 1 ? 0 : null,
          bottom: 0,
          child: Transform.translate(
            offset: Offset(
              offset.dx * animation.value,
              offset.dy * animation.value,
            ),
            child: Transform.scale(
              scale: 0.86 + (0.14 * animation.value),
              child: Opacity(
                opacity: animation.value,
                child: IgnorePointer(
                  ignoring: animation.value == 0,
                  child: child,
                ),
              ),
            ),
          ),
        );
      },
      child: Tooltip(
        message: action.label,
        child: FloatingActionButton.small(
          heroTag: 'dashboard-quick-add-${action.label}',
          tooltip: action.label,
          onPressed: onTap,
          shape: const CircleBorder(),
          child: Icon(action.icon),
        ),
      ),
    );
  }
}

class _QuickAddAction {
  const _QuickAddAction({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
}

const double _kDashboardRevealThreshold = 0.03;
const double _kDashboardSectionGap = 12;

/// Visible fade + slide-up reveal with optional stagger delay.
/// Uses a real [AnimationController] so [delay] produces true stagger.
class _DashboardReveal extends StatefulWidget {
  const _DashboardReveal({
    required this.id,
    required this.child,
    this.delay = Duration.zero,
  });

  final String id;
  final Widget child;
  final Duration delay;

  @override
  State<_DashboardReveal> createState() => _DashboardRevealState();
}

class _DashboardRevealState extends State<_DashboardReveal> {
  bool _visible = false;
  bool _queued = false;

  void _show() {
    if (_visible || _queued) return;

    _queued = true;
    Future.delayed(widget.delay, () {
      if (!mounted) return;
      setState(() => _visible = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: ValueKey('dashboard-reveal-${widget.id}'),
      onVisibilityChanged: (info) {
        if (info.visibleFraction >= _kDashboardRevealThreshold) {
          _show();
        }
      },
      child: AnimatedOpacity(
        opacity: _visible ? 1 : 0,
        duration: const Duration(milliseconds: 480),
        curve: Curves.easeOutCubic,
        child: AnimatedSlide(
          offset: _visible ? Offset.zero : const Offset(0, 0.045),
          duration: const Duration(milliseconds: 620),
          curve: Curves.easeOutCubic,
          child: widget.child,
        ),
      ),
    );
  }
}


/// Reusable card that lifts on hover (desktop) and scales on press (all).
/// Safe on mobile — hover only triggers above [_kHoverBreakpoint].
const double _kHoverBreakpoint = 900;

class _HoverLiftPanel extends StatefulWidget {
  const _HoverLiftPanel({required this.child, this.borderRadius});

  final Widget child;
  final BorderRadius? borderRadius;

  @override
  State<_HoverLiftPanel> createState() => _HoverLiftPanelState();
}

class _HoverLiftPanelState extends State<_HoverLiftPanel> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final hoverEnabled = width >= _kHoverBreakpoint;
    final activeHover = hoverEnabled && _hovered;
    final radius = widget.borderRadius ?? AppRadius.xLarge;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final scale = _pressed
        ? 0.99
        : activeHover
        ? 1.018
        : 1.0;
    final yOffset = activeHover ? -7.0 : 0.0;

    return MouseRegion(
      cursor: SystemMouseCursors.basic,
      onEnter: (_) {
        if (hoverEnabled) setState(() => _hovered = true);
      },
      onExit: (_) {
        if (hoverEnabled) setState(() => _hovered = false);
      },
      child: Listener(
        onPointerDown: (_) => setState(() => _pressed = true),
        onPointerUp: (_) => setState(() => _pressed = false),
        onPointerCancel: (_) => setState(() => _pressed = false),
        child: AnimatedSlide(
          offset: Offset(0, yOffset / 100),
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          child: AnimatedScale(
            scale: scale,
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              decoration: BoxDecoration(
                borderRadius: radius,
                border: Border.all(
                  color: activeHover
                      ? AppColors.primaryColor(context).withValues(alpha: 0.38)
                      : AppColors.borderColor(context),
                ),
                boxShadow: isDark
                    ? null
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: activeHover ? 0.13 : 0.05,
                          ),
                          blurRadius: activeHover ? 20 : 8,
                          offset: Offset(0, activeHover ? 8 : 3),
                        ),
                      ],
              ),
              child: ClipRRect(borderRadius: radius, child: widget.child),
            ),
          ),
        ),
      ),
    );
  }
}


class _WelcomePanel extends StatelessWidget {
  const _WelcomePanel({
    required this.authState,
    this.platformPreview = false,
    this.previewCompanyName,
  });

  final AuthState authState;
  final bool platformPreview;
  final String? previewCompanyName;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final copy = _DashboardCopy.of(context);
    final name =
        (authState.userProfile?.fullName ?? authState.user?.fullName ?? '')
            .trim();
    final previewName = (previewCompanyName ?? '').trim();
    final displayName = platformPreview
        ? (previewName.isEmpty ? l.companyDashboardPreview : previewName)
        : (name.isEmpty ? l.crmUser : name);
    final now = DateTime.now();
    final date = MaterialLocalizations.of(context).formatFullDate(now);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final direction = Directionality.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkCardSurface
            : AppColors.backgroundHighlight,
        border: Border.all(color: AppColors.borderColor(context)),
        borderRadius: AppRadius.xLarge,
        boxShadow: Theme.of(context).brightness == Brightness.dark
            ? null
            : AppShadows.card,
      ),
      child: CustomPaint(
        painter: _WelcomePropertyPainter(
          color: isDark
              ? AppColors.darkPrimary.withValues(alpha: 0.10)
              : const Color(0xFFE7C77B).withValues(alpha: 0.22),
          textDirection: direction,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    platformPreview ? l.companyDashboardPreview : copy.greeting(now),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimaryColor(context),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimaryColor(context),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    platformPreview ? l.readOnlyPreview : date,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondaryColor(context),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.selectedSurface(context),
                borderRadius: AppRadius.xLarge,
              ),
              child: Icon(
                Icons.real_estate_agent_outlined,
                color: AppColors.primaryColor(context),
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WelcomePropertyPainter extends CustomPainter {
  const _WelcomePropertyPainter({
    required this.color,
    required this.textDirection,
  });

  final Color color;
  final TextDirection textDirection;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()
      ..color = color.withValues(alpha: 0.28)
      ..style = PaintingStyle.fill;

    final isRtl = textDirection == TextDirection.rtl;
    final originX = isRtl ? size.width * 0.04 : size.width * 0.68;
    final width = size.width * 0.25;
    final top = size.height * 0.20;
    final base = size.height * 0.78;
    final sign = isRtl ? 1.0 : -1.0;

    final roof = Path()
      ..moveTo(originX, top + 28)
      ..lineTo(originX + sign * width * 0.42, top)
      ..lineTo(originX + sign * width * 0.84, top + 28);
    canvas.drawPath(roof, paint);

    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        isRtl ? originX : originX - width * 0.84,
        top + 28,
        width * 0.84,
        base - top - 28,
      ),
      const Radius.circular(14),
    );
    canvas.drawRRect(body, paint);

    for (var row = 0; row < 2; row++) {
      for (var col = 0; col < 3; col++) {
        final x = isRtl
            ? originX + 18 + col * 24
            : originX - width * 0.72 + col * 24;
        final y = top + 48 + row * 24;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x, y, 12, 10),
            const Radius.circular(3),
          ),
          fill,
        );
      }
    }

    canvas.drawCircle(
      Offset(isRtl ? originX + width * 0.94 : originX - width * 0.94, top + 18),
      18,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _WelcomePropertyPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.textDirection != textDirection;
  }
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({required this.data, required this.authState});

  final _DashboardData data;
  final AuthState authState;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final copy = _DashboardCopy.of(context);
    final features = authState.companyMetadata;
    final leadsEnabled = features.isFeatureEnabled(CompanyFeature.leads);
    final clientsEnabled = features.isFeatureEnabled(CompanyFeature.clients);
    final propertiesEnabled =
        features.isFeatureEnabled(CompanyFeature.properties);
    final tasksEnabled = features.isFeatureEnabled(CompanyFeature.tasks);
    final dealsEnabled = features.isFeatureEnabled(CompanyFeature.deals);
    // Ordered for a clean 4-column by 2-row desktop grid.
    final cards = [
      if (leadsEnabled)
        _MetricItem(
          l.totalLeads,
        data.leads.length,
        AppStatusTone.info,
        Icons.people_alt_outlined,
      ),
      if (leadsEnabled)
        _MetricItem(
          l.newLeads,
        data.newLeads.length,
        AppStatusTone.neutral,
        Icons.person_add_alt_outlined,
      ),
      if (tasksEnabled || leadsEnabled)
        _MetricItem(
          copy.upcomingFollowUps,
        data.upcomingFollowUps.length,
        AppStatusTone.info,
        Icons.upcoming_outlined,
      ),
      if (tasksEnabled || leadsEnabled)
        _MetricItem(
          copy.overdueFollowUps,
        data.overdueFollowUps.length,
        AppStatusTone.error,
        Icons.schedule_outlined,
      ),
      if (dealsEnabled)
        _MetricItem(
          l.openDeals,
        data.openDeals.length,
        AppStatusTone.warning,
        Icons.handshake_outlined,
      ),
      if (dealsEnabled)
        _MetricItem(
          l.wonDeals,
        data.wonDeals.length,
        AppStatusTone.success,
        Icons.emoji_events_outlined,
      ),
      if (propertiesEnabled)
        _MetricItem(
          copy.availableProperties,
        data.availableProperties.length,
        AppStatusTone.success,
        Icons.apartment_outlined,
      ),
      if (clientsEnabled)
        _MetricItem(
          l.clients,
        data.clients.length,
        AppStatusTone.neutral,
        Icons.group_outlined,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        // Desktop: 4 columns, Tablet: 2 columns, Mobile: 2 columns
        final columns = constraints.maxWidth >= 860 ? 4 : 2;
        final gap = AppSpacing.sm;
        final width = (constraints.maxWidth - (columns - 1) * gap) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final card in cards)
              SizedBox(
                width: width,
                child: _MetricCard(item: card),
              ),
          ],
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.item});

  final _MetricItem item;

  @override
  Widget build(BuildContext context) {
    final color = _toneColor(context, item.tone);
    return _HoverLiftPanel(
      borderRadius: AppRadius.xLarge,
      child: _Panel(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.textSecondaryColor(context),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: item.value.toDouble()),
                    duration: const Duration(milliseconds: 480),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) {
                      return Text(
                        value.round().toString(),
                        style: Theme.of(context).textTheme.titleLarge
                            ?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimaryColor(context),
                            ),
                      );
                    },
                  ),
                ],
              ),
            ),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: AppRadius.large,
              ),
              child: Icon(item.icon, size: 18, color: color),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnalyticsPanel extends StatelessWidget {
  const _AnalyticsPanel({required this.data, required this.authState});

  final _DashboardData data;
  final AuthState authState;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final copy = _DashboardCopy.of(context);
    final features = authState.companyMetadata;
    final leadsEnabled = features.isFeatureEnabled(CompanyFeature.leads);
    final tasksEnabled = features.isFeatureEnabled(CompanyFeature.tasks);
    final propertiesEnabled =
        features.isFeatureEnabled(CompanyFeature.properties);
    final dealsEnabled = features.isFeatureEnabled(CompanyFeature.deals);

    return _Panel(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionTitle(title: copy.visualAnalytics),
          const SizedBox(height: AppSpacing.sm),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 560 ? 2 : 1;
              const gap = AppSpacing.sm;
              final cardWidth =
                  (constraints.maxWidth - (columns - 1) * gap) / columns;

              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  if (leadsEnabled)
                    SizedBox(
                      width: cardWidth,
                      child: _DonutChartCard(
                        title: copy.leadStatusDistribution,
                      segments: [
                        _ChartSegment(
                          l.newLead,
                          data.newLeads.length,
                          AppColors.primaryColor(context),
                        ),
                        _ChartSegment(
                          copy.active,
                          data.activeLeads.length,
                          AppColors.successColor(context),
                        ),
                        _ChartSegment(
                          l.won,
                          data.wonLeads.length,
                          AppColors.primaryPressed,
                        ),
                        _ChartSegment(
                          l.lost,
                          data.lostLeads.length,
                          AppColors.errorColor(context),
                        ),
                      ],
                    ),
                  ),
                  if (tasksEnabled)
                    SizedBox(
                      width: cardWidth,
                      child: _DonutChartCard(
                        title: copy.tasksDueBreakdown,
                      segments: [
                        _ChartSegment(
                          l.overdue,
                          data.overdueTasks.length,
                          AppColors.errorColor(context),
                        ),
                        _ChartSegment(
                          l.dueToday,
                          data.todayTasks.length,
                          AppColors.warningColor(context),
                        ),
                        _ChartSegment(
                          l.upcoming,
                          data.upcomingTasks.length,
                          AppColors.primaryPressed,
                        ),
                        _ChartSegment(
                          l.completed,
                          data.completedTasks.length,
                          AppColors.successColor(context),
                        ),
                      ],
                    ),
                  ),
                  if (propertiesEnabled)
                    SizedBox(
                      width: cardWidth,
                      child: _DonutChartCard(
                        title: copy.propertyStatusDistribution,
                      segments: [
                        _ChartSegment(
                          copy.availableProperties,
                          data.availableProperties.length,
                          AppColors.successColor(context),
                        ),
                        _ChartSegment(
                          copy.inactive,
                          data.inactiveProperties.length,
                          const Color(0xFFD8D0C2),
                        ),
                        _ChartSegment(
                          copy.reservedOrClosed,
                          data.reservedOrClosedProperties.length,
                          AppColors.warningColor(context),
                        ),
                      ],
                    ),
                  ),
                  if (dealsEnabled)
                    SizedBox(
                      width: cardWidth,
                      child: _DonutChartCard(
                        title: l.dealsByStage,
                      segments: [
                        for (final stage in DealStage.values)
                          _ChartSegment(
                            dealStageLabel(l, stage),
                            data.dealsByStage(stage).length,
                            _dealStageColor(context, stage),
                          ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DonutChartCard extends StatefulWidget {
  const _DonutChartCard({
    required this.title,
    required this.segments,
  });

  final String title;
  final List<_ChartSegment> segments;

  @override
  State<_DonutChartCard> createState() => _DonutChartCardState();
}

class _DonutChartCardState extends State<_DonutChartCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _sweep;
  late Animation<double> _legend;
  late Animation<double> _centerScale;

  String _signature = '';

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1050),
    );

    _setupAnimations();
    _signature = _buildSignature(widget.segments);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _controller.forward(from: 0);
      }
    });
  }

  @override
  void didUpdateWidget(covariant _DonutChartCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    final nextSignature = _buildSignature(widget.segments);
    if (nextSignature != _signature) {
      _signature = nextSignature;
      _controller.forward(from: 0);
    }
  }

  void _setupAnimations() {
    _sweep = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.00, 0.72, curve: Curves.easeOutCubic),
    );

    _legend = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.32, 1.00, curve: Curves.easeOutCubic),
    );

    _centerScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.88, end: 1.06)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 55,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.06, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 45,
      ),
    ]).animate(_controller);
  }

  String _buildSignature(List<_ChartSegment> segments) {
    return segments
        .map((segment) => '${segment.label}:${segment.value}')
        .join('|');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.segments.fold<int>(
      0,
          (sum, item) => sum + item.value,
    );

    return _HoverLiftPanel(
      borderRadius: AppRadius.large,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.inputSurface(context),
          border: Border.all(color: AppColors.borderColor(context)),
          borderRadius: AppRadius.large,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    return Transform.scale(
                      scale: _centerScale.value,
                      child: _ModernDonutChart(
                        segments: widget.segments,
                        progress: _sweep.value,
                        total: total,
                        size: 72,
                        valueKey: 'donut-total-$_signature',
                      ),
                    );
                  },
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AnimatedBuilder(
                    animation: _legend,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _legend.value,
                        child: Transform.translate(
                          offset: Offset(10 * (1 - _legend.value), 0),
                          child: child,
                        ),
                      );
                    },
                    child: Column(
                      children: [
                        for (var index = 0;
                        index < widget.segments.length;
                        index++)
                          _AnimatedLegendRow(
                            segment: widget.segments[index],
                            index: index,
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


class _ModernDonutChart extends StatelessWidget {
  const _ModernDonutChart({
    required this.segments,
    required this.progress,
    required this.total,
    required this.size,
    required this.valueKey,
  });

  final List<_ChartSegment> segments;
  final double progress;
  final int total;
  final double size;
  final String valueKey;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: (size / 2) - 18,
              startDegreeOffset: -90,
              sections: _pieChartSections(context),
            ),
          ),
          TweenAnimationBuilder<double>(
            key: ValueKey(valueKey),
            tween: Tween(begin: 0.0, end: total.toDouble()),
            duration: const Duration(milliseconds: 760),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) {
              return Text(
                value.round().toString(),
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w900),
              );
            },
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _pieChartSections(BuildContext context) {
    final cleanTotal = segments.fold<int>(0, (sum, segment) => sum + segment.value);
    if (cleanTotal == 0) {
      return [
        PieChartSectionData(
          value: 1,
          radius: 12,
          showTitle: false,
          color: AppColors.borderColor(context),
        ),
      ];
    }
    return [
      for (final segment in segments)
        if (segment.value > 0)
          PieChartSectionData(
            value: segment.value * progress,
            radius: 12,
            showTitle: false,
            color: segment.color,
          ),
    ];
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({required this.segment});

  final _ChartSegment segment;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: segment.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              segment.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),
          Text(
            segment.value.toString(),
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}
class _AnimatedLegendRow extends StatelessWidget {
  const _AnimatedLegendRow({
    required this.segment,
    required this.index,
  });

  final _ChartSegment segment;
  final int index;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 420 + index * 70),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(8 * (1 - value), 0),
            child: child,
          ),
        );
      },
      child: _LegendRow(segment: segment),
    );
  }
}
class _DonutPainter extends CustomPainter {
  const _DonutPainter({required this.segments, this.progress = 1.0});

  final List<_ChartSegment> segments;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final total = segments.fold<int>(0, (sum, segment) => sum + segment.value);
    final rect = Offset.zero & size;
    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 11
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFE9E1D3);

    canvas.drawArc(
      rect.deflate(8),
      -math.pi / 2,
      math.pi * 2,
      false,
      trackPaint,
    );
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 11
      ..strokeCap = StrokeCap.round;

    if (total == 0) {
      stroke.color = const Color(0xFFDCE3EC);
      canvas.drawArc(
        rect.deflate(8),
        -math.pi / 2,
        math.pi * 2 * progress,
        false,
        stroke,
      );
      return;
    }

    var start = -math.pi / 2;
    for (final segment in segments.where((segment) => segment.value > 0)) {
      final fullSweep = math.pi * 2 * segment.value / total;
      final sweep = fullSweep * progress;
      stroke.color = segment.color;
      canvas.drawArc(rect.deflate(8), start, sweep, false, stroke);
      start += fullSweep; // advance by full so proportions stay correct
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) {
    return oldDelegate.segments != segments || oldDelegate.progress != progress;
  }
}

class _LeadSection extends StatelessWidget {
  const _LeadSection({
    required this.title,
    required this.leads,
    required this.emptyMessage,
    this.readOnly = false,
  });

  final String title;
  final List<Lead> leads;
  final String emptyMessage;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionTitle(title: title),
          const SizedBox(height: AppSpacing.sm),
          if (leads.isEmpty)
            _CompactEmpty(message: emptyMessage)
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 248),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    for (final lead in leads.take(6))
                      _DashboardListTile(
                        title: lead.fullName,
                        subtitle: lead.phone.isNotEmpty
                            ? lead.phone
                            : lead.email,
                        badge: _leadStatusLabel(context, lead.status),
                        tone: _leadStatusTone(lead.status),
                        onTap: readOnly
                            ? null
                            : () => context.go(RouteNames.leadDetails(lead.id)),
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

class _DealsDashboardSection extends StatelessWidget {
  const _DealsDashboardSection({
    required this.data,
    this.readOnly = false,
  });

  final _DashboardData data;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionTitle(title: l.dealsReport),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _MiniMetric(label: l.openDeals, value: data.openDeals.length),
              _MiniMetric(label: l.wonDeals, value: data.wonDeals.length),
              _MiniMetric(label: l.lostDeals, value: data.lostDeals.length),
              _MiniMetric(
                label: l.expectedValueTotal,
                value: _formatMoney(context, data.expectedValueTotal),
              ),
              _MiniMetric(
                label: l.commissionTotal,
                value: _formatMoney(context, data.commissionTotal),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _HorizontalDistribution(
            rows: [
              for (final stage in DealStage.values)
                _DistributionRow(
                  label: dealStageLabel(l, stage),
                  value: data.dealsByStage(stage).length,
                  color: _dealStageColor(context, stage),
                ),
            ],
          ),
          if (data.recentDeals.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            for (final deal in data.recentDeals.take(4))
              _DashboardListTile(
                title: _fallback(deal.clientName, l.deal),
                subtitle: _fallback(deal.propertyTitle, l.notAvailable),
                badge: dealStageLabel(l, deal.stage),
                tone: dealStageTone(deal.stage),
                onTap: readOnly
                    ? null
                    : () => context.go(RouteNames.dealDetails(deal.id)),
              ),
          ],
        ],
      ),
    );
  }
}

class _TaskBreakdownSection extends StatelessWidget {
  const _TaskBreakdownSection({
    required this.data,
    this.readOnly = false,
  });

  final _DashboardData data;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final total = data.tasks.length;
    final completionRate = total == 0
        ? 0.0
        : data.completedTasks.length / total;

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionTitle(title: l.tasksReport),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _MiniMetric(
                label: l.overdueTasks,
                value: data.overdueTasks.length,
              ),
              _MiniMetric(
                label: l.dueTodayTasks,
                value: data.todayTasks.length,
              ),
              _MiniMetric(
                label: l.upcomingTasks,
                value: data.upcomingTasks.length,
              ),
              _MiniMetric(
                label: l.completedTasks,
                value: data.completedTasks.length,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _ProgressRow(
            label: l.completionRate,
            value: completionRate,
            color: AppColors.successColor(context),
          ),
          const SizedBox(height: AppSpacing.md),
          if (data.attentionTasks.isEmpty)
            _CompactEmpty(message: l.noTasksYet)
          else
            for (final task in data.attentionTasks.take(5))
              _DashboardListTile(
                title: task.title,
                subtitle: _taskSubtitle(context, task),
                badge: _taskDueLabel(context, task),
                tone: _taskDueTone(task),
                onTap: readOnly ? null : () => context.go(RouteNames.tasks),
              ),
        ],
      ),
    );
  }
}

class _AppointmentsDashboardSection extends StatelessWidget {
  const _AppointmentsDashboardSection({required this.data});

  final _DashboardData data;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final nextAppointment = data.nextAppointment;
    final attentionItems = data.appointmentAttentionItems;

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionTitle(title: l.dashboardAppointmentsTitle),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _MiniMetric(
                label: l.todaysAppointments,
                value: data.todayAppointments.length,
              ),
              _MiniMetric(
                label: l.upcomingAppointments,
                value: data.upcomingAppointments.length,
              ),
              _MiniMetric(
                label: l.missedAppointments,
                value: data.missedAppointments.length,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (attentionItems.isNotEmpty)
            for (final appointment in attentionItems.take(4))
              _DashboardListTile(
                title: appointment.title,
                subtitle: _dashboardAppointmentSubtitle(context, appointment),
                badge: _dashboardAppointmentTimingLabel(context, appointment),
                tone: _dashboardAppointmentTone(appointment),
                onTap: () => context.go(
                  RouteNames.appointmentEdit(appointment.id),
                ),
              )
          else if (nextAppointment != null)
            _DashboardListTile(
              title: nextAppointment.title,
              subtitle: _dashboardAppointmentSubtitle(context, nextAppointment),
              badge: l.nextAppointment,
              tone: AppStatusTone.info,
              onTap: () => context.go(
                RouteNames.appointmentEdit(nextAppointment.id),
              ),
            )
          else
            _CompactEmpty(message: l.noUpcomingAppointments),
        ],
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({required this.label, required this.value});

  final String label;
  final Object value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 118,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.inputSurface(context),
        border: Border.all(color: AppColors.borderColor(context)),
        borderRadius: AppRadius.large,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.textSecondaryColor(context),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value.toString(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _DistributionRow {
  const _DistributionRow({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;
}

class _HorizontalDistribution extends StatelessWidget {
  const _HorizontalDistribution({required this.rows});

  final List<_DistributionRow> rows;

  @override
  Widget build(BuildContext context) {
    final maxValue = rows.fold<int>(
      0,
      (max, row) => row.value > max ? row.value : max,
    );

    return Column(
      children: [
        for (final row in rows)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: _ProgressRow(
              label: row.label,
              value: maxValue == 0 ? 0 : row.value / maxValue,
              trailing: row.value.toString(),
              color: row.color,
            ),
          ),
      ],
    );
  }
}

class _ProgressRow extends StatelessWidget {
  const _ProgressRow({
    required this.label,
    required this.value,
    required this.color,
    this.trailing,
  });

  final String label;
  final double value;
  final Color color;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(0.0, 1.0);
    return Row(
      children: [
        SizedBox(
          width: 104,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: clamped),
            duration: const Duration(milliseconds: 850),
            curve: Curves.easeOutCubic,
            builder: (context, animatedValue, _) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: animatedValue,
                  minHeight: 8,
                  backgroundColor: AppColors.borderColor(context),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        SizedBox(
          width: 44,
          child: Text(
            trailing ?? '${(clamped * 100).round()}%',
            textAlign: TextAlign.end,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}

class _CompactEmpty extends StatelessWidget {
  const _CompactEmpty({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppColors.textSecondaryColor(context),
        ),
      ),
    );
  }
}

class _DashboardListTile extends StatelessWidget {
  const _DashboardListTile({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.tone,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final String badge;
  final AppStatusTone tone;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.large,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (subtitle.trim().isNotEmpty)
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
              AppStatusBadge(label: badge, tone: tone),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionPanel extends StatelessWidget {
  const _ActionPanel({required this.authState});

  final AuthState authState;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final role = authState.userProfile?.role ?? authState.user?.role;
    final canCreateLead =
        authState.companyMetadata.isFeatureEnabled(CompanyFeature.leads) &&
        role != null && PermissionService.can(role, AppPermission.createLead);
    final canCreateProperty =
        authState.companyMetadata.isFeatureEnabled(CompanyFeature.properties) &&
        role != null &&
        PermissionService.can(role, AppPermission.createProperty);
    final canCreateClient =
        authState.companyMetadata.isFeatureEnabled(CompanyFeature.clients) &&
        role != null && PermissionService.can(role, AppPermission.createClient);

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionTitle(title: _DashboardCopy.of(context).quickActions),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: l.createLead,
            icon: Icons.person_add_alt_outlined,
            onPressed: canCreateLead
                ? () => context.go(RouteNames.leadsCreate)
                : null,
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            label: l.createClient,
            icon: Icons.group_add_outlined,
            variant: AppButtonVariant.secondary,
            onPressed: canCreateClient
                ? () => context.go(RouteNames.clientsCreate)
                : null,
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            label: l.createProperty,
            icon: Icons.add_business_outlined,
            variant: AppButtonVariant.secondary,
            onPressed: canCreateProperty
                ? () => context.go(RouteNames.propertiesCreate)
                : null,
          ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.child,
    this.padding = const EdgeInsets.all(12),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.cardSurface(context),
        border: Border.all(color: AppColors.borderColor(context)),
        borderRadius: AppRadius.xLarge,
        boxShadow: Theme.of(context).brightness == Brightness.dark
            ? null
            : AppShadows.card,
      ),
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
    );
  }
}

class _DashboardData {
  const _DashboardData({
    required this.leads,
    required this.properties,
    required this.clients,
    required this.tasks,
    required this.appointments,
    required this.deals,
  });

  final List<Lead> leads;
  final List<Property> properties;
  final List<Client> clients;
  final List<CrmTask> tasks;
  final List<Appointment> appointments;
  final List<Deal> deals;

  List<Lead> get newLeads =>
      leads.where((lead) => lead.status == LeadStatus.newLead).toList();

  List<Lead> get activeLeads => leads.where((lead) {
    return lead.status == LeadStatus.contacted ||
        lead.status == LeadStatus.interested ||
        lead.status == LeadStatus.visitScheduled ||
        lead.status == LeadStatus.negotiation;
  }).toList();

  List<Lead> get wonLeads =>
      leads.where((lead) => lead.status == LeadStatus.won).toList();

  List<Lead> get lostLeads =>
      leads.where((lead) => lead.status == LeadStatus.lost).toList();

  List<Lead> get unassignedLeads =>
      leads.where((lead) => lead.assignedTo.trim().isEmpty).toList();

  List<Lead> get overdueFollowUps => leads.where((lead) {
    final date = lead.nextFollowUpAt;
    return date != null && _dateOnly(date.toLocal()).isBefore(_today);
  }).toList();

  List<Lead> get upcomingFollowUps => leads.where((lead) {
    final date = lead.nextFollowUpAt;
    return date != null && _dateOnly(date.toLocal()).isAfter(_today);
  }).toList();

  List<Lead> get todaysFollowUps => leads.where((lead) {
    final date = lead.nextFollowUpAt;
    return date != null && _dateOnly(date.toLocal()) == _today;
  }).toList();

  List<Lead> get recentLeads {
    final sorted = [...leads]
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return sorted;
  }

  List<Property> get availableProperties => properties
      .where((property) => property.status == PropertyStatus.available)
      .toList();

  List<Property> get inactiveProperties => properties
      .where((property) => property.status == PropertyStatus.inactive)
      .toList();

  List<Property> get reservedOrClosedProperties => properties
      .where(
        (property) =>
            property.status != PropertyStatus.available &&
            property.status != PropertyStatus.inactive,
      )
      .toList();

  List<CrmTask> get overdueTasks => tasks.where((task) {
    final date = task.dueDate;
    return task.status != TaskStatus.completed &&
        task.status != TaskStatus.cancelled &&
        date != null &&
        _dateOnly(date.toLocal()).isBefore(_today);
  }).toList();

  List<CrmTask> get todayTasks => tasks.where((task) {
    final date = task.dueDate;
    return date != null && _dateOnly(date.toLocal()) == _today;
  }).toList();

  List<CrmTask> get upcomingTasks => tasks.where((task) {
    final date = task.dueDate;
    return date != null && _dateOnly(date.toLocal()).isAfter(_today);
  }).toList();

  List<CrmTask> get completedTasks =>
      tasks.where((task) => task.status == TaskStatus.completed).toList();

  List<CrmTask> get cancelledTasks =>
      tasks.where((task) => task.status == TaskStatus.cancelled).toList();

  List<Appointment> get todayAppointments => appointments.where((appointment) {
    final date = appointment.scheduledAt;
    return date != null && _dateOnly(date.toLocal()) == _today;
  }).toList();

  List<Appointment> get missedAppointments => appointments.where((appointment) {
    return _dashboardAppointmentIsMissed(appointment);
  }).toList();

  List<Appointment> get upcomingAppointments {
    final now = DateTime.now();
    final selected = appointments.where((appointment) {
      final scheduledAt = appointment.scheduledAt;
      return scheduledAt != null &&
          scheduledAt.toLocal().isAfter(now) &&
          !_dashboardAppointmentIsMissed(appointment) &&
          (appointment.status == AppointmentStatus.scheduled ||
              appointment.status == AppointmentStatus.rescheduled);
    }).toList()
      ..sort((a, b) {
        final aDate = a.scheduledAt ?? DateTime(9999);
        final bDate = b.scheduledAt ?? DateTime(9999);
        return aDate.compareTo(bDate);
      });
    return selected;
  }

  Appointment? get nextAppointment {
    final upcoming = upcomingAppointments;
    return upcoming.isEmpty ? null : upcoming.first;
  }

  List<Appointment> get appointmentAttentionItems {
    final selected = appointments.where((appointment) {
      if (appointment.status == AppointmentStatus.completed ||
          appointment.status == AppointmentStatus.cancelled) {
        return false;
      }
      return _dashboardAppointmentIsMissed(appointment) ||
          _dashboardAppointmentIsDueNow(appointment) ||
          todayAppointments.contains(appointment);
    }).toList()
      ..sort((a, b) {
        final rank = _dashboardAppointmentRank(a).compareTo(
          _dashboardAppointmentRank(b),
        );
        if (rank != 0) {
          return rank;
        }
        final aDate = a.scheduledAt ?? DateTime(9999);
        final bDate = b.scheduledAt ?? DateTime(9999);
        return aDate.compareTo(bDate);
      });
    return selected;
  }

  List<Deal> get openDeals => deals.where((deal) {
    return deal.stage != DealStage.won && deal.stage != DealStage.lost;
  }).toList();

  List<Deal> get wonDeals =>
      deals.where((deal) => deal.stage == DealStage.won).toList();

  List<Deal> get lostDeals =>
      deals.where((deal) => deal.stage == DealStage.lost).toList();

  List<Deal> dealsByStage(DealStage stage) {
    return deals.where((deal) => deal.stage == stage).toList();
  }

  num get expectedValueTotal =>
      openDeals.fold<num>(0, (sum, deal) => sum + deal.expectedValue);

  num get commissionTotal =>
      openDeals.fold<num>(0, (sum, deal) => sum + deal.commission);

  List<Deal> get recentDeals {
    final sorted = [...deals]
      ..sort((a, b) {
        final aDate = a.updatedAt ?? a.createdAt ?? DateTime(0);
        final bDate = b.updatedAt ?? b.createdAt ?? DateTime(0);
        return bDate.compareTo(aDate);
      });
    return sorted;
  }

  List<CrmTask> get attentionTasks {
    final selected = [
      ...overdueTasks,
      ...todayTasks.where((task) => !overdueTasks.contains(task)),
    ];
    selected.sort((a, b) {
      final priority = _taskPriorityRank(
        b.priority,
      ).compareTo(_taskPriorityRank(a.priority));
      if (priority != 0) {
        return priority;
      }
      final aDate = a.dueDate ?? DateTime(9999);
      final bDate = b.dueDate ?? DateTime(9999);
      return aDate.compareTo(bDate);
    });
    return selected;
  }

}

class _MetricItem {
  const _MetricItem(this.label, this.value, this.tone, this.icon);

  final String label;
  final int value;
  final AppStatusTone tone;
  final IconData icon;
}

class _ChartSegment {
  const _ChartSegment(this.label, this.value, this.color);

  final String label;
  final int value;
  final Color color;
}

class _DashboardCopy {
  const _DashboardCopy(this.l);

  final AppLocalizations l;

  static _DashboardCopy of(BuildContext context) {
    return _DashboardCopy(AppLocalizations.of(context)!);
  }

  String greeting(DateTime now) {
    if (now.hour < 12) {
      return l.dashboardGoodMorning;
    }
    if (now.hour < 17) {
      return l.dashboardGoodAfternoon;
    }
    return l.dashboardGoodEvening;
  }

  String get overdueFollowUps => l.dashboardOverdueFollowUps;
  String get upcomingFollowUps => l.dashboardUpcomingFollowUps;
  String get availableProperties => l.dashboardAvailableProperties;
  String get visualAnalytics => l.dashboardVisualAnalytics;
  String get leadStatusDistribution => l.dashboardLeadStatusDistribution;
  String get tasksDueBreakdown => l.dashboardTasksDueBreakdown;
  String get propertyStatusDistribution =>
      l.dashboardPropertyStatusDistribution;
  String get todaysFollowUps => l.dashboardTodaysFollowUps;
  String get overdueTasks => l.dashboardOverdueTasks;
  String get unassignedLeads => l.dashboardUnassignedLeads;
  String get recentlyUpdatedLeads => l.dashboardRecentlyUpdatedLeads;
  String get quickActions => l.dashboardQuickActions;
  String get active => l.dashboardActive;
  String get inactive => l.dashboardInactive;
  String get reservedOrClosed => l.dashboardReservedOrClosed;
  String get generalTask => l.dashboardGeneralTask;
}

DateTime get _today => _dateOnly(DateTime.now());

DateTime _dateOnly(DateTime value) {
  return DateTime(value.year, value.month, value.day);
}

String _relativeTimeLabel(BuildContext context, DateTime time) {
  final l = AppLocalizations.of(context)!;
  final now = DateTime.now();
  final localTime = time.toLocal();
  final diff = now.difference(localTime);

  if (diff.inMinutes < 1) {
    return l.dashboardJustNow;
  }

  if (diff.inMinutes < 60) {
    return l.dashboardMinutesAgo(diff.inMinutes);
  }

  if (diff.inHours < 24 && _dateOnly(localTime) == _today) {
    return l.dashboardHoursAgo(diff.inHours);
  }

  if (_dateOnly(localTime) == _today.subtract(const Duration(days: 1))) {
    return l.dashboardYesterday;
  }

  return intl.DateFormat.MMMd(
    Localizations.localeOf(context).toString(),
  ).format(localTime);
}

String _leadStatusLabel(BuildContext context, LeadStatus status) {
  final l = AppLocalizations.of(context)!;
  return switch (status) {
    LeadStatus.newLead => l.newLead,
    LeadStatus.contacted => l.contacted,
    LeadStatus.interested => l.interested,
    LeadStatus.visitScheduled => l.visitScheduled,
    LeadStatus.negotiation => l.negotiation,
    LeadStatus.won => l.won,
    LeadStatus.lost => l.lost,
  };
}

AppStatusTone _leadStatusTone(LeadStatus status) {
  return switch (status) {
    LeadStatus.won => AppStatusTone.success,
    LeadStatus.lost => AppStatusTone.error,
    LeadStatus.negotiation ||
    LeadStatus.visitScheduled => AppStatusTone.warning,
    LeadStatus.contacted || LeadStatus.interested => AppStatusTone.info,
    LeadStatus.newLead => AppStatusTone.neutral,
  };
}

String _taskDueLabel(BuildContext context, CrmTask task) {
  final l = AppLocalizations.of(context)!;
  if (task.status == TaskStatus.completed) {
    return l.completed;
  }
  if (task.status == TaskStatus.cancelled) {
    return l.cancelled;
  }
  final dueDate = task.dueDate;
  if (dueDate == null) {
    return l.notAvailable;
  }
  final dueDay = _dateOnly(dueDate.toLocal());
  if (dueDay.isBefore(_today)) {
    return l.overdue;
  }
  if (dueDay == _today) {
    return l.dueToday;
  }
  return l.upcoming;
}

AppStatusTone _taskDueTone(CrmTask task) {
  if (task.status == TaskStatus.completed) {
    return AppStatusTone.success;
  }
  if (task.status == TaskStatus.cancelled) {
    return AppStatusTone.neutral;
  }
  final dueDate = task.dueDate;
  if (dueDate == null) {
    return AppStatusTone.neutral;
  }
  final dueDay = _dateOnly(dueDate.toLocal());
  if (dueDay.isBefore(_today)) {
    return AppStatusTone.error;
  }
  if (dueDay == _today) {
    return AppStatusTone.warning;
  }
  return AppStatusTone.info;
}

String _taskSubtitle(BuildContext context, CrmTask task) {
  final copy = _DashboardCopy.of(context);
  final relatedTitle = task.relatedTitle.trim();
  if (relatedTitle.isNotEmpty) {
    return relatedTitle;
  }
  final assignee = task.assignedToName.trim();
  if (assignee.isNotEmpty) {
    return assignee;
  }
  return copy.generalTask;
}

bool _dashboardAppointmentIsMissed(Appointment appointment) {
  final endAt = appointment.endAt ?? appointment.scheduledAt;
  return appointment.status == AppointmentStatus.missed ||
      (appointment.status == AppointmentStatus.scheduled &&
          endAt != null &&
          endAt.toLocal().isBefore(DateTime.now()));
}

bool _dashboardAppointmentIsDueNow(Appointment appointment) {
  final scheduledAt = appointment.scheduledAt;
  if (appointment.status != AppointmentStatus.scheduled ||
      scheduledAt == null) {
    return false;
  }
  final now = DateTime.now();
  final start = scheduledAt.toLocal();
  final end = (appointment.endAt ?? scheduledAt).toLocal();
  return !start.isAfter(now) && !end.isBefore(now);
}

int _dashboardAppointmentRank(Appointment appointment) {
  if (_dashboardAppointmentIsMissed(appointment)) {
    return 0;
  }
  if (_dashboardAppointmentIsDueNow(appointment)) {
    return 1;
  }
  final scheduledAt = appointment.scheduledAt;
  if (scheduledAt != null && _dateOnly(scheduledAt.toLocal()) == _today) {
    return 2;
  }
  return 3;
}

String _dashboardAppointmentTimingLabel(
  BuildContext context,
  Appointment appointment,
) {
  final l = AppLocalizations.of(context)!;
  if (_dashboardAppointmentIsMissed(appointment)) {
    return l.notificationAppointmentMissedAttentionTitle;
  }
  if (_dashboardAppointmentIsDueNow(appointment)) {
    return l.notificationAppointmentDueNowTitle;
  }
  final scheduledAt = appointment.scheduledAt;
  if (scheduledAt != null && _dateOnly(scheduledAt.toLocal()) == _today) {
    return l.todaysAppointments;
  }
  return l.upcoming;
}

AppStatusTone _dashboardAppointmentTone(Appointment appointment) {
  if (_dashboardAppointmentIsMissed(appointment) ||
      _dashboardAppointmentIsDueNow(appointment)) {
    return AppStatusTone.error;
  }
  final scheduledAt = appointment.scheduledAt;
  if (scheduledAt != null && _dateOnly(scheduledAt.toLocal()) == _today) {
    return AppStatusTone.warning;
  }
  return AppStatusTone.info;
}

String _dashboardAppointmentSubtitle(
  BuildContext context,
  Appointment appointment,
) {
  final l = AppLocalizations.of(context)!;
  final scheduledAt = appointment.scheduledAt;
  final dateLabel = scheduledAt == null
      ? l.notAvailable
      : intl.DateFormat.yMMMd(l.localeName).add_jm().format(
            scheduledAt.toLocal(),
          );
  final related = appointment.relatedTitle.trim().isNotEmpty
      ? appointment.relatedTitle.trim()
      : appointment.relatedSubtitle.trim();
  final assignee = appointment.assignedToName.trim();
  return [
    dateLabel,
    if (related.isNotEmpty) related,
    if (assignee.isNotEmpty) assignee,
  ].join(' - ');
}

String _fallback(String value, String fallback) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? fallback : trimmed;
}

String _formatMoney(BuildContext context, num value) {
  final localeName = Localizations.localeOf(context).toString();
  return intl.NumberFormat.compact(locale: localeName).format(value);
}

Color _dealStageColor(BuildContext context, DealStage stage) {
  return switch (stage) {
    DealStage.won => AppColors.successColor(context),
    DealStage.lost => AppColors.errorColor(context),
    DealStage.negotiation ||
    DealStage.proposal => AppColors.warningColor(context),
    DealStage.qualified => AppColors.infoColor(context),
    DealStage.newDeal => AppColors.primaryColor(context),
  };
}

int _taskPriorityRank(TaskPriority priority) {
  return switch (priority) {
    TaskPriority.high => 3,
    TaskPriority.medium => 2,
    TaskPriority.low => 1,
  };
}

Color _toneColor(BuildContext context, AppStatusTone tone) {
  return switch (tone) {
    AppStatusTone.success => AppColors.successColor(context),
    AppStatusTone.warning => AppColors.warningColor(context),
    AppStatusTone.error => AppColors.errorColor(context),
    AppStatusTone.info => AppColors.infoColor(context),
    AppStatusTone.neutral => AppColors.primaryColor(context),
  };
}

bool _canViewRecentActivity(
  AuthState authState, {
  bool platformPreview = false,
}) {
  if (platformPreview) {
    return true;
  }

  final role = authState.userProfile?.role ?? authState.user?.role;
  return role == UserRole.admin || role == UserRole.manager;
}

bool _canViewAppointments(
  AuthState authState, {
  bool platformPreview = false,
}) {
  if (platformPreview) {
    return false;
  }
  final role = authState.userProfile?.role ?? authState.user?.role;
  return authState.companyMetadata.isFeatureEnabled(CompanyFeature.appointments) &&
      role != null &&
      PermissionService.can(role, AppPermission.viewAppointments);
}

bool _canViewUnassignedLeads(
  AuthState authState, {
  bool platformPreview = false,
}) {
  if (platformPreview) {
    return true;
  }

  final role = authState.userProfile?.role ?? authState.user?.role;
  return role == UserRole.admin;
}

bool _assignedOnlyScope(UserRole? role) {
  return role == UserRole.salesAgent ||
      role == UserRole.marketing ||
      role == UserRole.viewer;
}
