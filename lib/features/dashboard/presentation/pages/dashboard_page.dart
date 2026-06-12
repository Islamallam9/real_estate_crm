import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' as intl;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/auth/protected_company_session.dart';
import '../../../../core/constants/role_constants.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/stats/module_kpi_counts_data_source.dart';
import '../../../../core/permissions/app_permission.dart';
import '../../../../core/permissions/company_feature_gate.dart';
import '../../../../core/permissions/permission_service.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/time/server_clock.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_status_badge.dart';
import '../../../../core/widgets/crm_app_shell.dart';
import '../../../../core/widgets/masar_refresh_indicator.dart';
import '../../../../core/widgets/masar_tab_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/dashboard_analytics.dart';
import '../../domain/entities/sales_command_center.dart';
import '../../domain/usecases/build_dashboard_analytics_usecase.dart';
import '../../domain/usecases/build_sales_command_center_usecase.dart';
import '../widgets/dashboard_cockpit_body.dart';
import '../widgets/sales_command_center_panel.dart';
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
import '../../../users/domain/entities/company_metadata.dart';
import '../../../users/domain/entities/user_profile.dart';
import '../../../users/domain/usecases/watch_active_users_usecase.dart';
import '../../../users/data/datasources/user_profile_remote_data_source.dart';
import '../../../users/data/repositories/user_profile_repository_impl.dart';
import '../../../../core/widgets/masar_loading_view.dart';

void _masarDashboardDebug(String message) {
  if (!kDebugMode) {
    return;
  }
  debugPrint('MasarDashboardDebug $message');
}

String _dashboardKpiDebug(ModuleKpiCounts counts) {
  final values = counts.values.entries
      .map((entry) => '${entry.key}=${entry.value}')
      .join(',');
  final failed = counts.failedKeys.join(',');
  return 'values={$values} failed=[$failed]';
}

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
          if (authState.isWaitingForProtectedCompanySession) {
            return const AppLoading();
          }

          final session = authState.protectedCompanySession;
          if (session == null) {
            return const AppLoading();
          }

          final profile = session.profile;
          final companyId = session.companyId;
          if (companyId.isEmpty) {
            return AppErrorView(message: l.missingCompanyProfile);
          }

          return _TrialAccessGate(
            company: authState.companyMetadata,
            child: _DashboardScopes(
              key: ValueKey(session.scopeKey('dashboard-scopes')),
              child: _DashboardContent(
                key: ValueKey(session.scopeKey('dashboard-content')),
                companyId: companyId,
                authState: authState,
              ),
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
                key: ValueKey('dashboard-preview-scopes:$companyId:${authState.user?.uid ?? ''}'),
                child: _DashboardContent(
                  key: ValueKey('dashboard-preview-content:$companyId:${authState.user?.uid ?? ''}'),
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
  const _DashboardScopes({super.key, required this.child});

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
    super.key,
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

class _DashboardContentState extends State<_DashboardContent>
    with WidgetsBindingObserver {
  _DashboardWatchScopeKey? _watchScopeKey;
  Timer? _clockTicker;
  Timer? _initialFailureRetryTimer;
  DateTime? _lastLifecycleRefreshAt;
  Stream<List<UserProfile>>? _activeUsersStream;
  bool _activeUsersRequested = false;
  bool _auditLogsRequested = false;
  int _initialFailureRetryCount = 0;
  String? _lastDashboardDebugSignature;
  String? _lastDashboardModuleWatchKey;
  DateTime? _lastDashboardModuleWatchAt;
  int _dashboardModuleWatchGeneration = 0;
  String? _activeUsersStreamKey;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _watchScopedDashboardData(reason: 'init');
    _clockTicker = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void didUpdateWidget(covariant _DashboardContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    _watchScopedDashboardData(reason: 'didUpdateWidget');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _clockTicker?.cancel();
    _initialFailureRetryTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state != AppLifecycleState.resumed) {
      return;
    }
    final now = DateTime.now();
    final lastRefreshAt = _lastLifecycleRefreshAt;
    if (lastRefreshAt != null &&
        now.difference(lastRefreshAt) < const Duration(minutes: 5)) {
      return;
    }
    _lastLifecycleRefreshAt = now;
    Future<void>.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _watchScopedDashboardData(force: true, reason: 'lifecycle-resume');
      }
    });
  }

  void _watchScopedDashboardData({
    bool force = false,
    String reason = 'auto',
  }) {
    final watchScopeKey = _dashboardWatchScopeKey(
      companyId: widget.companyId,
      authState: widget.authState,
      platformPreview: widget.platformPreview,
    );
    if (watchScopeKey == null) {
      _masarDashboardDebug(
        'watch skipped missing scope reason=$reason company=${widget.companyId} '
        'platformPreview=${widget.platformPreview} '
        'hasSession=${widget.authState.protectedCompanySession != null} '
        'uid=${widget.authState.user?.uid ?? ''}',
      );
      _watchScopeKey = null;
      _activeUsersRequested = false;
      _auditLogsRequested = false;
      _activeUsersStream = null;
      _activeUsersStreamKey = null;
      _lastDashboardModuleWatchKey = null;
      _lastDashboardModuleWatchAt = null;
      return;
    }
    final scopeChanged = _watchScopeKey != watchScopeKey;
    final moduleWatchKey = _dashboardModuleWatchKey(watchScopeKey);
    final lastModuleWatchAt = _lastDashboardModuleWatchAt;
    final rapidDuplicateForce = force &&
        !scopeChanged &&
        _lastDashboardModuleWatchKey == moduleWatchKey &&
        lastModuleWatchAt != null &&
        DateTime.now().difference(lastModuleWatchAt) <
            const Duration(seconds: 2) &&
        reason != 'manual-retry' &&
        reason != 'initial-failure-recovery';
    if (!force && !scopeChanged) {
      _masarDashboardDebug(
        'watch skipped unchanged scope reason=$reason company=${watchScopeKey.companyId} '
        'role=${watchScopeKey.role} uid=${watchScopeKey.uid} '
        'team=${watchScopeKey.managerTeamId}',
      );
      return;
    }
    if (rapidDuplicateForce) {
      _masarDashboardDebug(
        'watch skipped rapid duplicate force reason=$reason '
        'company=${watchScopeKey.companyId} role=${watchScopeKey.role} '
        'uid=${watchScopeKey.uid} team=${watchScopeKey.managerTeamId} '
        'ageMs=${DateTime.now().difference(lastModuleWatchAt).inMilliseconds}',
      );
      return;
    }

    _dashboardModuleWatchGeneration += 1;
    _lastDashboardModuleWatchKey = moduleWatchKey;
    _lastDashboardModuleWatchAt = DateTime.now();
    _masarDashboardDebug(
      'watch start gen=$_dashboardModuleWatchGeneration reason=$reason '
      'company=${watchScopeKey.companyId} force=$force '
      'scopeChanged=$scopeChanged platformPreview=${watchScopeKey.platformPreview} '
      'role=${watchScopeKey.role} uid=${watchScopeKey.uid} '
      'team=${watchScopeKey.managerTeamId} '
      'canView=leads:${watchScopeKey.canViewLeads},properties:${watchScopeKey.canViewProperties},'
      'clients:${watchScopeKey.canViewClients},tasks:${watchScopeKey.canViewTasks},'
      'appointments:${watchScopeKey.canViewAppointments},deals:${watchScopeKey.canViewDeals},'
      'audit:${watchScopeKey.canViewAuditLogs}',
    );

    if (scopeChanged) {
      _activeUsersRequested = false;
      _auditLogsRequested = false;
      _activeUsersStream = null;
      _activeUsersStreamKey = null;
      _lastLifecycleRefreshAt = null;
    }
    _watchScopeKey = watchScopeKey;
    if (widget.platformPreview) {
      _watchPlatformPreviewData();
      if (_activeUsersRequested) {
        _activeUsersStream = Stream<List<UserProfile>>.value(const <UserProfile>[]);
      }
      if (_auditLogsRequested) {
        _watchDashboardAuditLogs(watchScopeKey, force: force);
      }
      return;
    }

    final role = watchScopeKey.role;
    final uid = watchScopeKey.uid;
    final managerTeamId =
        watchScopeKey.managerTeamId.isEmpty ? null : watchScopeKey.managerTeamId;
    if (_activeUsersRequested && _canRequestDashboardActiveUsers(watchScopeKey)) {
      _syncDashboardActiveUsersStream(
        watchScopeKey,
        reason: 'watch:$reason',
      );
    }
    final assignedTo = _assignedOnlyScope(role) ? uid : null;
    final managerId = role == UserRole.manager ? uid : null;
    _masarDashboardDebug(
      'watch filters assignedTo=${assignedTo ?? ''} '
      'managerId=${managerId ?? ''} teamId=${managerTeamId ?? ''}',
    );

    if (watchScopeKey.canViewLeads) {
      context.read<LeadsCubit>().watchLeads(
        companyId: widget.companyId,
        assignedTo: assignedTo,
        managerId: managerId,
        teamId: managerTeamId,
        usePagination: false,
      );
    }
    if (watchScopeKey.canViewProperties) {
      context.read<PropertiesCubit>().watchProperties(
        companyId: widget.companyId,
        usePagination: false,
      );
    }
    if (watchScopeKey.canViewClients) {
      context.read<ClientsCubit>().watchClients(
        companyId: widget.companyId,
        assignedTo: assignedTo,
        managerId: managerId,
        teamId: managerTeamId,
        usePagination: false,
      );
    }
    if (watchScopeKey.canViewTasks) {
      context.read<TasksCubit>().watchTasks(
        companyId: widget.companyId,
        assignedTo: assignedTo,
        managerId: managerId,
        teamId: managerTeamId,
        usePagination: false,
      );
    }
    if (watchScopeKey.canViewAppointments) {
      final appointmentWindow = _dashboardAppointmentWindow(DateTime.now());
      context.read<AppointmentsCubit>().watchAppointments(
        companyId: widget.companyId,
        assignedTo: assignedTo,
        managerId: managerId,
        teamId: managerTeamId,
        rangeStart: appointmentWindow.start,
        rangeEnd: appointmentWindow.end,
        usePagination: false,
      );
    }
    if (watchScopeKey.canViewDeals) {
      context.read<DealsCubit>().watchDeals(
        companyId: widget.companyId,
        role: role,
        currentUserId: uid,
        teamId: managerTeamId,
        usePagination: false,
      );
    }
    if (_auditLogsRequested && watchScopeKey.canViewAuditLogs) {
      _watchDashboardAuditLogs(watchScopeKey, force: force);
    }
  }

  void _retry() {
    _masarDashboardDebug('manual retry tapped company=${widget.companyId}');
    _initialFailureRetryTimer?.cancel();
    _initialFailureRetryTimer = null;
    _initialFailureRetryCount = 0;
    _watchScopedDashboardData(force: true, reason: 'manual-retry');
  }

  void _scheduleInitialFailureRecovery(String? message) {
    if (_initialFailureRetryTimer != null ||
        _initialFailureRetryCount >= 3 ||
        !_isRecoverableDashboardInitialFailure(message)) {
      return;
    }
    final delay = Duration(seconds: 2 + (_initialFailureRetryCount * 2));
    _masarDashboardDebug(
      'schedule initial failure retry count=$_initialFailureRetryCount '
      'delay=${delay.inSeconds}s message=${message ?? ''}',
    );
    _initialFailureRetryTimer = Timer(delay, () {
      _initialFailureRetryTimer = null;
      _initialFailureRetryCount += 1;
      if (mounted) {
        _watchScopedDashboardData(
          force: true,
          reason: 'initial-failure-recovery',
        );
      }
    });
  }

  void _clearInitialFailureRecovery() {
    _initialFailureRetryTimer?.cancel();
    _initialFailureRetryTimer = null;
    _initialFailureRetryCount = 0;
  }

  void _requestDashboardActiveUsers() {
    final watchScopeKey = _watchScopeKey ??
        _dashboardWatchScopeKey(
          companyId: widget.companyId,
          authState: widget.authState,
          platformPreview: widget.platformPreview,
        );
    if (watchScopeKey == null ||
        _activeUsersRequested ||
        !_canRequestDashboardActiveUsers(watchScopeKey)) {
      return;
    }

    _activeUsersRequested = true;
    _masarDashboardDebug(
      'active users requested company=${watchScopeKey.companyId} '
      'role=${watchScopeKey.role} uid=${watchScopeKey.uid}',
    );
    _syncDashboardActiveUsersStream(
      watchScopeKey,
      reason: 'visibility-request',
      notify: true,
    );
  }

  void _syncDashboardActiveUsersStream(
    _DashboardWatchScopeKey watchScopeKey, {
    required String reason,
    bool notify = false,
  }) {
    final streamKey = _dashboardActiveUsersStreamKey(watchScopeKey);
    if (_activeUsersStreamKey == streamKey && _activeUsersStream != null) {
      _masarDashboardDebug(
        'active users watch skipped duplicate reason=$reason '
        'key=$streamKey',
      );
      return;
    }
    _activeUsersStreamKey = streamKey;
    _masarDashboardDebug(
      'active users watch created reason=$reason key=$streamKey',
    );
    final stream = watchScopeKey.platformPreview
        ? Stream<List<UserProfile>>.value(const <UserProfile>[])
        : _watchDashboardActiveUsers(widget.companyId);
    if (notify && mounted) {
      setState(() {
        _activeUsersStream = stream;
      });
      return;
    }
    _activeUsersStream = stream;
  }

  void _requestRecentActivity({bool force = false}) {
    final watchScopeKey = _watchScopeKey ??
        _dashboardWatchScopeKey(
          companyId: widget.companyId,
          authState: widget.authState,
          platformPreview: widget.platformPreview,
        );
    if (watchScopeKey == null) {
      _masarDashboardDebug(
        'recent activity skipped missing scope force=$force '
        'company=${widget.companyId}',
      );
      return;
    }
    if (!watchScopeKey.canViewAuditLogs) {
      _masarDashboardDebug(
        'recent activity skipped permission company=${watchScopeKey.companyId} '
        'role=${watchScopeKey.role} uid=${watchScopeKey.uid}',
      );
      return;
    }
    if (!force && _auditLogsRequested) {
      _masarDashboardDebug(
        'recent activity skipped duplicate request '
        'company=${watchScopeKey.companyId} role=${watchScopeKey.role} '
        'uid=${watchScopeKey.uid} team=${watchScopeKey.managerTeamId}',
      );
      return;
    }

    _auditLogsRequested = true;
    _masarDashboardDebug(
      'recent activity requested company=${watchScopeKey.companyId} '
      'force=$force role=${watchScopeKey.role} uid=${watchScopeKey.uid} '
      'team=${watchScopeKey.managerTeamId}',
    );
    _watchDashboardAuditLogs(watchScopeKey, force: force);
  }

  void _watchDashboardAuditLogs(
    _DashboardWatchScopeKey watchScopeKey, {
    bool force = false,
  }) {
    _masarDashboardDebug(
      'watch recent activity company=${widget.companyId} '
      'managerId=${watchScopeKey.role == UserRole.manager ? watchScopeKey.uid : ''} '
      'teamId=${watchScopeKey.managerTeamId} force=$force',
    );
    context.read<AuditLogsCubit>().watchDashboardRecentActivity(
      companyId: widget.companyId,
      managerId: watchScopeKey.role == UserRole.manager ? watchScopeKey.uid : null,
      teamId: watchScopeKey.managerTeamId.isEmpty
          ? null
          : watchScopeKey.managerTeamId,
      limit: 8,
      force: force,
    );
  }

  void _watchPlatformPreviewData() {
    context.read<LeadsCubit>().watchLeads(companyId: widget.companyId, usePagination: false);
    context.read<PropertiesCubit>().watchProperties(companyId: widget.companyId, usePagination: false);
    context.read<ClientsCubit>().watchClients(companyId: widget.companyId, usePagination: false);
    context.read<TasksCubit>().watchTasks(companyId: widget.companyId, usePagination: false);
    context.read<DealsCubit>().watchDeals(
      companyId: widget.companyId,
      role: UserRole.admin,
      currentUserId: widget.authState.user?.uid ?? '',
      usePagination: false,
    );
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
                            final dashboardRole = widget.platformPreview
                                ? UserRole.admin
                                : widget.authState.protectedCompanySession?.profile.role;
                            final dealsAllowed = widget.authState.companyMetadata
                                    .isFeatureEnabled(CompanyFeature.deals) &&
                                (widget.platformPreview ||
                                    (dashboardRole != null &&
                                        PermissionService.can(
                                          dashboardRole,
                                          AppPermission.viewDeals,
                                        )));
                        return StreamBuilder<List<UserProfile>>(
                          stream: _activeUsersStream ??
                              Stream<List<UserProfile>>.value(const <UserProfile>[]),
                          initialData: const <UserProfile>[],
                          builder: (context, activeUsersSnapshot) {
                            if (activeUsersSnapshot.hasError) {
                              _masarDashboardDebug(
                                'active users stream error=${activeUsersSnapshot.error}',
                              );
                            }
                            final data = _DashboardData(
                              leads: leadsState.leads,
                              properties: propertiesState.properties,
                              clients: clientsState.clients,
                              tasks: tasksState.tasks,
                              appointments: appointmentsState.appointments,
                              deals: dealsAllowed ? dealsState.deals : const <Deal>[],
                              activeUsers:
                                  activeUsersSnapshot.data ?? const <UserProfile>[],
                              leadCounts: leadsState.kpiCounts,
                              propertyCounts: propertiesState.kpiCounts,
                              taskCounts: tasksState.kpiCounts,
                              appointmentCounts: appointmentsState.kpiCounts,
                              dealCounts: dealsState.kpiCounts,
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
                            dealsAllowed &&
                                dealsState.status == DealsStatus.loading &&
                                dealsState.deals.isEmpty;

                        final rawInitialFailure =
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
                            dealsAllowed &&
                                dealsState.status == DealsStatus.failure &&
                                dealsState.deals.isEmpty;
                        final hasRenderableDashboardData =
                            leadsState.leads.isNotEmpty ||
                            !leadsState.kpiCounts.isEmpty ||
                            propertiesState.properties.isNotEmpty ||
                            !propertiesState.kpiCounts.isEmpty ||
                            clientsState.clients.isNotEmpty ||
                            !clientsState.kpiCounts.isEmpty ||
                            tasksState.tasks.isNotEmpty ||
                            !tasksState.kpiCounts.isEmpty ||
                            appointmentsState.appointments.isNotEmpty ||
                            !appointmentsState.kpiCounts.isEmpty ||
                            (dealsAllowed && dealsState.deals.isNotEmpty) ||
                            (dealsAllowed && !dealsState.kpiCounts.isEmpty);
                        final hasInitialFailure =
                            rawInitialFailure && !hasRenderableDashboardData;
                        final hasPartialModuleFailure =
                            rawInitialFailure && hasRenderableDashboardData;

                        final failureMessage =
                            leadsState.message ??
                            propertiesState.message ??
                            clientsState.message ??
                            tasksState.message ??
                            appointmentsState.message ??
                            (dealsAllowed ? dealsState.message : null);
                        final recoverInitialFailure = hasInitialFailure &&
                            _initialFailureRetryCount < 3 &&
                            _isRecoverableDashboardInitialFailure(failureMessage);
                        if (recoverInitialFailure) {
                          _scheduleInitialFailureRecovery(failureMessage);
                        } else if (!hasInitialFailure && !isLoading) {
                          _clearInitialFailureRecovery();
                        }

                        final debugSignature = <String>[
                          'loading=$isLoading',
                          'initialFailure=$hasInitialFailure',
                          'rawInitialFailure=$rawInitialFailure',
                          'partialModuleFailure=$hasPartialModuleFailure',
                          'recoverInitialFailure=$recoverInitialFailure',
                          'failureMessage=${failureMessage ?? ''}',
                          'leads=${leadsState.status}/${leadsState.leads.length}/${leadsState.message ?? ''}/${_dashboardKpiDebug(leadsState.kpiCounts)}',
                          'properties=${propertiesState.status}/${propertiesState.properties.length}/${propertiesState.message ?? ''}/${_dashboardKpiDebug(propertiesState.kpiCounts)}',
                          'clients=${clientsState.status}/${clientsState.clients.length}/${clientsState.message ?? ''}/${_dashboardKpiDebug(clientsState.kpiCounts)}',
                          'tasks=${tasksState.status}/${tasksState.tasks.length}/${tasksState.message ?? ''}/${_dashboardKpiDebug(tasksState.kpiCounts)}',
                          'appointmentsEnabled=$appointmentsEnabled',
                          'appointments=${appointmentsState.status}/${appointmentsState.appointments.length}/${appointmentsState.message ?? ''}/${_dashboardKpiDebug(appointmentsState.kpiCounts)}',
                          'dealsAllowed=$dealsAllowed',
                          'deals=${dealsState.status}/${dealsState.deals.length}/${dealsState.message ?? ''}/${_dashboardKpiDebug(dealsState.kpiCounts)}',
                          'activeUsers=${activeUsersSnapshot.data?.length ?? 0}',
                        ].join(' | ');
                        if (_lastDashboardDebugSignature != debugSignature ||
                            hasInitialFailure ||
                            recoverInitialFailure) {
                          _lastDashboardDebugSignature = debugSignature;
                          _masarDashboardDebug('state $debugSignature');
                        }
                        if (rawInitialFailure) {
                          _masarDashboardDebug(
                            'initial failure flags '
                            'leads=${leadsState.status == LeadsStatus.failure && leadsState.leads.isEmpty} '
                            'properties=${propertiesState.status == PropertiesStatus.failure && propertiesState.properties.isEmpty} '
                            'clients=${clientsState.status == ClientsStatus.failure && clientsState.clients.isEmpty} '
                            'tasks=${tasksState.status == TasksStatus.failure && tasksState.tasks.isEmpty} '
                            'appointments=${appointmentsEnabled && appointmentsState.status == AppointmentsStatus.failure && appointmentsState.appointments.isEmpty} '
                            'deals=${dealsAllowed && dealsState.status == DealsStatus.failure && dealsState.deals.isEmpty} '
                            'renderableData=$hasRenderableDashboardData',
                          );
                        }
                        if (hasPartialModuleFailure) {
                          _masarDashboardDebug(
                            'render partial dashboard despite module failure '
                            'message=${failureMessage ?? ''}',
                          );
                        }

                            return _DashboardView(
                              data: data,
                              authState: widget.authState,
                              platformPreview: widget.platformPreview,
                              previewCompanyName: widget.previewCompanyName,
                              isLoading: isLoading || recoverInitialFailure,
                              hasInitialFailure: recoverInitialFailure ? false : hasInitialFailure,
                              failureMessage: failureMessage,
                              onRetry: _retry,
                              onActiveUsersNeeded: _requestDashboardActiveUsers,
                              onRecentActivityNeeded: _requestRecentActivity,
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
      },
    );
  }
}



String _dashboardModuleWatchKey(_DashboardWatchScopeKey watchScopeKey) {
  return <String>[
    watchScopeKey.companyId,
    watchScopeKey.platformPreview.toString(),
    watchScopeKey.role.name,
    watchScopeKey.uid,
    watchScopeKey.managerTeamId,
    watchScopeKey.canViewLeads.toString(),
    watchScopeKey.canViewProperties.toString(),
    watchScopeKey.canViewClients.toString(),
    watchScopeKey.canViewTasks.toString(),
    watchScopeKey.canViewAppointments.toString(),
    watchScopeKey.canViewDeals.toString(),
    watchScopeKey.canViewAuditLogs.toString(),
  ].join('|');
}

String _dashboardActiveUsersStreamKey(_DashboardWatchScopeKey watchScopeKey) {
  return <String>[
    watchScopeKey.companyId,
    watchScopeKey.platformPreview.toString(),
    watchScopeKey.role.name,
    watchScopeKey.uid,
    watchScopeKey.managerTeamId,
  ].join('|');
}

bool _isRecoverableDashboardInitialFailure(String? message) {
  final normalized = (message ?? '').toLowerCase();
  if (normalized.contains('permission-denied') ||
      normalized.contains('permission denied') ||
      normalized.contains('missing index') ||
      normalized.contains('failed-precondition') ||
      normalized.contains('not-found')) {
    return false;
  }
  return true;
}

class _DashboardDateWindow {
  const _DashboardDateWindow({required this.start, required this.end});

  final DateTime start;
  final DateTime end;
}

_DashboardDateWindow _dashboardAppointmentWindow(DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  return _DashboardDateWindow(
    // Keeps recent missed/completed appointments and the near-future calendar
    // visible while avoiding a full appointment collection listener on the
    // dashboard. Other app flows are not affected.
    start: today.subtract(const Duration(days: 45)),
    end: today.add(const Duration(days: 90)),
  );
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
    final role = authState.protectedCompanySession?.profile.role;
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
              final recentStatus = state.recentStatus;
              final recentLogs = state.recentLogs;
              if (recentStatus == AuditLogsStatus.loading &&
                  recentLogs.isEmpty) {
                return const Center(child: MasarLogoLoader(size: 40));
              }

              if (recentStatus == AuditLogsStatus.failure && recentLogs.isEmpty) {
                return _CompactEmpty(
                  message: l.dashboardUnableToLoadRecentActivity,
                );
              }

              final limit = MediaQuery.sizeOf(context).width >= 900 ? 3 : 4;
              final logs = recentLogs.toList()
                ..sort((a, b) {
                  final timeCompare = b.createdAt.compareTo(a.createdAt);
                  return timeCompare != 0 ? timeCompare : b.id.compareTo(a.id);
                });
              final items = logs
                  .take(limit)
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

              return Column(
                children: [
                  for (var index = 0; index < items.length; index++) ...[
                    _RecentActivityTile(item: items[index]),
                    if (index != items.length - 1)
                      const SizedBox(height: AppSpacing.sm),
                  ],
                ],
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
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return l.notAvailable;
  }
  if (field == 'lastContactAt' || field == 'nextFollowUpAt') {
    final parsed = DateTime.tryParse(trimmed) ??
        DateTime.tryParse(trimmed.replaceFirst(' ', 'T'));
    if (parsed != null) {
      final local = parsed.toLocal();
      final today = _dateOnly(DateTime.now());
      final sameDay = _dateOnly(local) == today;
      final formatter = sameDay
          ? intl.DateFormat.jm(l.localeName)
          : intl.DateFormat.yMMMd(l.localeName).add_jm();
      return formatter.format(local);
    }
  }
  return switch (field) {
    'status' => _auditStatusValueLabel(l, trimmed),
    'source' => _auditSourceValueLabel(l, trimmed),
    'priority' => _auditPriorityValueLabel(l, trimmed),
    _ => trimmed,
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
    AuditLogAction.restore => l.dashboardAuditRestored,
    AuditLogAction.exportGenerated => l.dashboardAuditExportGenerated,
    AuditLogAction.exported => l.dashboardAuditExportGenerated,
  };
}

String _auditModuleLabel(AppLocalizations l, AuditLogModule module) {
  return switch (module) {
    AuditLogModule.leads => l.dashboardAuditLead,
    AuditLogModule.clients => l.dashboardAuditClient,
    AuditLogModule.properties => l.dashboardAuditProperty,
    AuditLogModule.tasks => l.dashboardAuditTask,
    AuditLogModule.deals => l.dashboardAuditDeal,
    AuditLogModule.appointments => l.appointments,
    AuditLogModule.users => l.userManagement,
    AuditLogModule.teams => l.teamManagement,
    AuditLogModule.reports => l.reports,
    AuditLogModule.exports => l.exportActivity,
    AuditLogModule.auditLogs => l.auditLogs,
    AuditLogModule.other => l.other,
  };
}

IconData _auditModuleIcon(AuditLogModule module) {
  return switch (module) {
    AuditLogModule.leads => Icons.person_search_outlined,
    AuditLogModule.clients => Icons.person_outline_rounded,
    AuditLogModule.properties => Icons.business_outlined,
    AuditLogModule.tasks => Icons.checklist_rtl_rounded,
    AuditLogModule.deals => Icons.handshake_outlined,
    AuditLogModule.appointments => Icons.event_note_outlined,
    AuditLogModule.users => Icons.manage_accounts_outlined,
    AuditLogModule.teams => Icons.groups_outlined,
    AuditLogModule.reports => Icons.file_download_outlined,
    AuditLogModule.exports => Icons.ios_share_outlined,
    AuditLogModule.auditLogs => Icons.manage_search_outlined,
    AuditLogModule.other => Icons.history_toggle_off_outlined,
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
    AuditLogAction.complete ||
    AuditLogAction.restore => AppStatusTone.success,
    AuditLogAction.assign => AppStatusTone.info,
    AuditLogAction.update => AppStatusTone.info,
    AuditLogAction.exportGenerated => AppStatusTone.info,
    AuditLogAction.exported => AppStatusTone.info,
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
    AuditLogModule.tasks => (context) => context.go(RouteNames.taskEdit(log.recordId)),
    AuditLogModule.deals => (context) =>
        context.go(RouteNames.dealDetails(log.recordId)),
    AuditLogModule.appointments => (context) =>
        context.go(RouteNames.appointmentEdit(log.recordId)),
    AuditLogModule.users => (context) => context.go(RouteNames.users),
    AuditLogModule.teams => (context) => context.go(RouteNames.teams),
    AuditLogModule.reports => (context) => context.go(RouteNames.reports),
    AuditLogModule.exports => (context) => context.go(RouteNames.auditLogs),
    AuditLogModule.auditLogs => (context) => context.go(RouteNames.auditLogs),
    AuditLogModule.other => null,
  };
}

class _RecentActivityTile extends StatelessWidget {
  const _RecentActivityTile({required this.item});

  final _RecentActivityItem item;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final color = _toneColor(context, item.tone);
    final subtitle = item.subtitle.trim();
    final actor = item.actorName.trim().isEmpty ? l.unknownUser : item.actorName.trim();
    final time = _activityAbsoluteTime(context, item.time);

    return _HoverLiftPanel(
      borderRadius: AppRadius.large,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: item.onTap == null ? null : () => item.onTap!(context),
          borderRadius: AppRadius.large,
          child: Container(
            padding: const EdgeInsetsDirectional.fromSTEB(10, 9, 10, 9),
            decoration: BoxDecoration(
              color: AppColors.inputSurface(context),
              borderRadius: AppRadius.large,
              border: Border.all(
                color: color.withValues(alpha: 0.16),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
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
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.action,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(fontWeight: FontWeight.w900),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            item.timeLabel,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: color,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      if (subtitle.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: AppColors.textSecondaryColor(context),
                              ),
                        ),
                      ],
                      const SizedBox(height: 5),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          _ActivityMiniChip(
                            icon: Icons.person_outline_rounded,
                            label: l.byUser(actor),
                          ),
                          _ActivityMiniChip(
                            icon: Icons.schedule_rounded,
                            label: time,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    )
        .animate(key: ValueKey(item.id))
        .fadeIn(duration: 180.ms, curve: Curves.easeOutCubic)
        .slideY(begin: 0.08, end: 0, duration: 180.ms, curve: Curves.easeOutCubic);
  }
}

class _ActivityMiniChip extends StatelessWidget {
  const _ActivityMiniChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(7, 3, 7, 3),
      decoration: BoxDecoration(
        color: AppColors.cardSurface(context).withValues(alpha: 0.74),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.borderColor(context)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: AppColors.textMutedColor(context),
          ),
          const SizedBox(width: 4),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 150),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textMutedColor(context),
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}



String _activityAbsoluteTime(BuildContext context, DateTime date) {
  final l = AppLocalizations.of(context)!;
  final local = date.toLocal();
  final now = DateTime.now();
  final safe = local.isAfter(now.add(const Duration(seconds: 45))) ? now : local;
  final sameDay = safe.year == now.year && safe.month == now.month && safe.day == now.day;
  final formatter = sameDay
      ? intl.DateFormat.jm(l.localeName)
      : intl.DateFormat.MMMd(l.localeName).add_jm();
  return formatter.format(safe);
}

_DashboardWatchScopeKey? _dashboardWatchScopeKey({
  required String companyId,
  required AuthState authState,
  required bool platformPreview,
}) {
  if (platformPreview) {
    return _DashboardWatchScopeKey(
      companyId: companyId,
      platformPreview: true,
      role: UserRole.admin,
      uid: authState.user?.uid ?? '',
      managerTeamId: '',
      canViewLeads: true,
      canViewProperties: true,
      canViewClients: true,
      canViewTasks: true,
      canViewAppointments: false,
      canViewDeals: true,
      canViewAuditLogs: true,
    );
  }

  final session = authState.protectedCompanySession;
  final role = session?.profile.role;
  final uid = session?.uid ?? '';
  if (role == null || uid.isEmpty) {
    return null;
  }

  final features = authState.companyMetadata;
  final managerTeamId = role == UserRole.manager
      ? session?.profile.teamId.trim() ?? ''
      : '';
  return _DashboardWatchScopeKey(
    companyId: companyId,
    platformPreview: false,
    role: role,
    uid: uid,
    managerTeamId: managerTeamId,
    canViewLeads: features.isFeatureEnabled(CompanyFeature.leads) &&
        PermissionService.can(role, AppPermission.viewLeads),
    canViewProperties: features.isFeatureEnabled(CompanyFeature.properties) &&
        PermissionService.can(role, AppPermission.viewProperties),
    canViewClients: features.isFeatureEnabled(CompanyFeature.clients) &&
        PermissionService.can(role, AppPermission.viewClients),
    canViewTasks: features.isFeatureEnabled(CompanyFeature.tasks) &&
        PermissionService.can(role, AppPermission.viewTasks),
    canViewAppointments: _canViewAppointments(authState),
    canViewDeals: features.isFeatureEnabled(CompanyFeature.deals) &&
        PermissionService.can(role, AppPermission.viewDeals),
    canViewAuditLogs: features.isFeatureEnabled(CompanyFeature.auditLogs) &&
        _canViewRecentActivity(authState),
  );
}

class _DashboardWatchScopeKey {
  const _DashboardWatchScopeKey({
    required this.companyId,
    required this.platformPreview,
    required this.role,
    required this.uid,
    required this.managerTeamId,
    required this.canViewLeads,
    required this.canViewProperties,
    required this.canViewClients,
    required this.canViewTasks,
    required this.canViewAppointments,
    required this.canViewDeals,
    required this.canViewAuditLogs,
  });

  final String companyId;
  final bool platformPreview;
  final UserRole role;
  final String uid;
  final String managerTeamId;
  final bool canViewLeads;
  final bool canViewProperties;
  final bool canViewClients;
  final bool canViewTasks;
  final bool canViewAppointments;
  final bool canViewDeals;
  final bool canViewAuditLogs;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is _DashboardWatchScopeKey &&
            companyId == other.companyId &&
            platformPreview == other.platformPreview &&
            role == other.role &&
            uid == other.uid &&
            managerTeamId == other.managerTeamId &&
            canViewLeads == other.canViewLeads &&
            canViewProperties == other.canViewProperties &&
            canViewClients == other.canViewClients &&
            canViewTasks == other.canViewTasks &&
            canViewAppointments == other.canViewAppointments &&
            canViewDeals == other.canViewDeals &&
            canViewAuditLogs == other.canViewAuditLogs;
  }

  @override
  int get hashCode => Object.hash(
        companyId,
        platformPreview,
        role,
        uid,
        managerTeamId,
        canViewLeads,
        canViewProperties,
        canViewClients,
        canViewTasks,
        canViewAppointments,
        canViewDeals,
        canViewAuditLogs,
      );
}

class _DashboardView extends StatefulWidget {
  const _DashboardView({
    required this.data,
    required this.authState,
    required this.platformPreview,
    this.previewCompanyName,
    required this.isLoading,
    required this.hasInitialFailure,
    required this.failureMessage,
    required this.onRetry,
    required this.onActiveUsersNeeded,
    required this.onRecentActivityNeeded,
  });

  final _DashboardData data;
  final AuthState authState;
  final bool platformPreview;
  final String? previewCompanyName;
  final bool isLoading;
  final bool hasInitialFailure;
  final String? failureMessage;
  final VoidCallback onRetry;
  final VoidCallback onActiveUsersNeeded;
  final VoidCallback onRecentActivityNeeded;

  @override
  State<_DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<_DashboardView> {
  _DashboardAnalyticsCache? _analyticsCache;
  _SalesCommandCache? _salesCommandCache;

  Future<void> _handleRefresh() async {
    widget.onRetry();
    widget.onRecentActivityNeeded();
    await Future<void>.delayed(const Duration(milliseconds: 650));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final data = widget.data;
    final authState = widget.authState;
    final platformPreview = widget.platformPreview;
    final previewCompanyName = widget.previewCompanyName;

    if (widget.isLoading) {
      return const AppLoading();
    }

    if (widget.hasInitialFailure) {
      _masarDashboardDebug(
        'render AppErrorView failureMessage=${widget.failureMessage ?? ''}',
      );
      return AppErrorView(
        message: localizeErrorMessage(l, widget.failureMessage),
        onRetry: widget.onRetry,
      );
    }

    return _TrialNoticeGate(
      company: authState.companyMetadata,
      child: Builder(
        builder: (context) {
        final features = authState.companyMetadata;
        final leadsEnabled = features.isFeatureEnabled(CompanyFeature.leads);
        final propertiesEnabled =
            features.isFeatureEnabled(CompanyFeature.properties);
        final tasksEnabled = features.isFeatureEnabled(CompanyFeature.tasks);
        final dealsEnabled = features.isFeatureEnabled(CompanyFeature.deals);
        final appointmentsEnabled = _canViewAppointments(
          authState,
          platformPreview: platformPreview,
        );
        final role = platformPreview
            ? UserRole.admin
            : authState.protectedCompanySession?.profile.role;
        final includeLeads = leadsEnabled &&
            (platformPreview ||
                (role != null &&
                    PermissionService.can(role, AppPermission.viewLeads)));
        final includeProperties = propertiesEnabled &&
            (platformPreview ||
                (role != null &&
                    PermissionService.can(role, AppPermission.viewProperties)));
        final includeTasks = tasksEnabled &&
            (platformPreview ||
                (role != null &&
                    PermissionService.can(role, AppPermission.viewTasks)));
        final includeDeals = dealsEnabled &&
            (platformPreview ||
                (role != null &&
                    PermissionService.can(role, AppPermission.viewDeals)));
        final canViewUnassignedLeads = platformPreview || role == UserRole.admin;
        final now = DateTime.now();
        final derived = _resolveDerivedDashboardData(
          role: role ?? UserRole.viewer,
          now: now,
          data: data,
          includeLeads: includeLeads,
          includeProperties: includeProperties,
          includeTasks: includeTasks,
          includeAppointments: appointmentsEnabled,
          includeDeals: includeDeals,
          canViewUnassignedLeads: canViewUnassignedLeads,
        );
        final analytics = derived.analytics;
        final commandSummary = derived.commandSummary;

        final mobile = MediaQuery.sizeOf(context).width < 760;
        final quickAddActions = mobile && !platformPreview
            ? _quickAddActions(context, authState)
            : const <_QuickAddAction>[];
        final dashboardScrollController = PrimaryScrollController.maybeOf(context);

        return Stack(
          children: [
            SingleChildScrollView(
              controller: dashboardScrollController,
              primary: dashboardScrollController == null,
              physics: const MasarRefreshPhysics(parent: BouncingScrollPhysics()),
              padding: EdgeInsets.only(
                bottom: quickAddActions.isEmpty ? 0 : 92,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _TrialBadgeBanner(company: authState.companyMetadata),
                  _PaymentStatusBanner(company: authState.companyMetadata),
                  DashboardCockpitBody(
                    analytics: analytics,
                    commandSummary: commandSummary,
                    authState: authState,
                    platformPreview: platformPreview,
                    previewCompanyName: previewCompanyName,
                    onActiveUsersNeeded: widget.onActiveUsersNeeded,
                    onRecentActivityNeeded: widget.onRecentActivityNeeded,
                  ),
                ],
              ),
            ),
            if (quickAddActions.isNotEmpty)
              _MobileQuickAddFab(actions: quickAddActions),
          ],
        );
        },
      ),
    );
  }

  _DashboardDerivedData _resolveDerivedDashboardData({
    required UserRole role,
    required DateTime now,
    required _DashboardData data,
    required bool includeLeads,
    required bool includeProperties,
    required bool includeTasks,
    required bool includeAppointments,
    required bool includeDeals,
    required bool canViewUnassignedLeads,
  }) {
    final minuteBucket = _dashboardMinuteBucket(now);
    final analytics = _resolveDashboardAnalytics(
      role: role,
      now: now,
      minuteBucket: minuteBucket,
      data: data,
      includeLeads: includeLeads,
      includeProperties: includeProperties,
      includeTasks: includeTasks,
      includeAppointments: includeAppointments,
      includeDeals: includeDeals,
      canViewUnassignedLeads: canViewUnassignedLeads,
    );
    final commandSummary = _resolveSalesCommandSummary(
      role: role,
      now: now,
      minuteBucket: minuteBucket,
      data: data,
      includeLeads: includeLeads,
      includeTasks: includeTasks,
      includeAppointments: includeAppointments,
      includeDeals: includeDeals,
      canViewUnassignedLeads: canViewUnassignedLeads,
    );
    return _DashboardDerivedData(
      analytics: analytics,
      commandSummary: commandSummary,
    );
  }

  DashboardAnalytics _resolveDashboardAnalytics({
    required UserRole role,
    required DateTime now,
    required DateTime minuteBucket,
    required _DashboardData data,
    required bool includeLeads,
    required bool includeProperties,
    required bool includeTasks,
    required bool includeAppointments,
    required bool includeDeals,
    required bool canViewUnassignedLeads,
  }) {
    final key = _DashboardAnalyticsKey(
      role: role,
      minuteBucket: minuteBucket,
      leads: includeLeads ? data.leads : const <Lead>[],
      properties: includeProperties ? data.properties : const <Property>[],
      tasks: includeTasks ? data.tasks : const <CrmTask>[],
      appointments:
          includeAppointments ? data.appointments : const <Appointment>[],
      deals: includeDeals ? data.deals : const <Deal>[],
      activeUsers: data.activeUsers,
      countsFingerprint: _dashboardCountsFingerprint(data),
      includeLeads: includeLeads,
      includeProperties: includeProperties,
      includeTasks: includeTasks,
      includeAppointments: includeAppointments,
      includeDeals: includeDeals,
      canViewUnassignedLeads: canViewUnassignedLeads,
    );

    final cached = _analyticsCache;
    if (cached != null && cached.key == key) {
      return cached.analytics;
    }

    final analytics = _withCountBackedKpis(
      const BuildDashboardAnalyticsUseCase()(
        DashboardAnalyticsInput(
        role: role,
        now: now,
        leads: key.leads,
        properties: key.properties,
        tasks: key.tasks,
        appointments: key.appointments,
        deals: key.deals,
        activeUsers: key.activeUsers,
        includeLeads: includeLeads,
        includeProperties: includeProperties,
        includeTasks: includeTasks,
        includeAppointments: includeAppointments,
        includeDeals: includeDeals,
          canViewUnassignedLeads: canViewUnassignedLeads,
        ),
      ),
      data,
    );
    _analyticsCache = _DashboardAnalyticsCache(
      key: key,
      analytics: analytics,
    );
    return analytics;
  }

  SalesCommandSummary _resolveSalesCommandSummary({
    required UserRole role,
    required DateTime now,
    required DateTime minuteBucket,
    required _DashboardData data,
    required bool includeLeads,
    required bool includeTasks,
    required bool includeAppointments,
    required bool includeDeals,
    required bool canViewUnassignedLeads,
  }) {
    final key = _SalesCommandKey(
      role: role,
      minuteBucket: minuteBucket,
      leads: includeLeads ? data.leads : const <Lead>[],
      tasks: includeTasks ? data.tasks : const <CrmTask>[],
      appointments:
          includeAppointments ? data.appointments : const <Appointment>[],
      deals: includeDeals ? data.deals : const <Deal>[],
      includeLeads: includeLeads,
      includeTasks: includeTasks,
      includeAppointments: includeAppointments,
      includeDeals: includeDeals,
      canViewUnassignedLeads: canViewUnassignedLeads,
    );

    final cached = _salesCommandCache;
    if (cached != null && cached.key == key) {
      return cached.commandSummary;
    }

    final commandSummary = const BuildSalesCommandCenterUseCase()(
      role: role,
      now: now,
      leads: key.leads,
      tasks: key.tasks,
      deals: key.deals,
      appointments: key.appointments,
      includeLeads: includeLeads,
      includeTasks: includeTasks,
      includeDeals: includeDeals,
      includeAppointments: includeAppointments,
      canViewUnassignedLeads: canViewUnassignedLeads,
    );
    _salesCommandCache = _SalesCommandCache(
      key: key,
      commandSummary: commandSummary,
    );
    return commandSummary;
  }

  List<_QuickAddAction> _quickAddActions(
    BuildContext context,
    AuthState authState,
  ) {
    final l = AppLocalizations.of(context)!;
    final role = authState.protectedCompanySession?.profile.role;
    final canCreateLead =
        authState.companyMetadata.isFeatureEnabled(CompanyFeature.leads) &&
        role != null && PermissionService.can(role, AppPermission.createLead);
    final canCreateClient =
        authState.companyMetadata.isFeatureEnabled(CompanyFeature.clients) &&
        (role == UserRole.admin || role == UserRole.manager);
    final canCreateDeal =
        authState.companyMetadata.isFeatureEnabled(CompanyFeature.deals) &&
        role != null && PermissionService.can(role, AppPermission.createDeal);
    final canCreateAppointment =
        authState.companyMetadata.isFeatureEnabled(CompanyFeature.appointments) &&
        role != null &&
        PermissionService.can(role, AppPermission.createAppointment);

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
      if (canCreateAppointment)
        _QuickAddAction(
          label: l.newAppointment,
          icon: Icons.event_available_outlined,
          onTap: () => context.go(RouteNames.appointmentsCreate),
        ),
    ];
  }
}


DashboardAnalytics _withCountBackedKpis(
  DashboardAnalytics analytics,
  _DashboardData data,
) {
  final replacements = <DashboardKpiType, int>{};

  void put(DashboardKpiType type, int? value) {
    if (value != null && value >= 0) {
      replacements[type] = value;
    }
  }

  final leadActive = data.leadCounts.valueOrNull('active');
  final leadOverdue = data.leadCounts.valueOrNull('overdue');
  final leadUnassigned = data.leadCounts.valueOrNull('unassigned');
  final taskOverdue = data.taskCounts.valueOrNull('overdue');
  final taskTotal = data.taskCounts.valueOrNull('total');
  final taskCompleted = data.taskCounts.valueOrNull('completed');
  final taskCancelled = data.taskCounts.valueOrNull('cancelled');
  final appointmentToday = data.appointmentCounts.valueOrNull('today');
  final appointmentMissed = data.appointmentCounts.valueOrNull('missed');
  final dealOpen = data.dealCounts.valueOrNull('open');
  final dealAtRisk = data.dealCounts.valueOrNull('atRisk');
  final dealWonThisMonth = data.dealCounts.valueOrNull('wonThisMonth');
  final propertyAvailable = data.propertyCounts.valueOrNull('available');

  put(DashboardKpiType.activeLeads, leadActive);
  put(DashboardKpiType.overdueFollowUps, leadOverdue);
  put(DashboardKpiType.unassignedLeads, leadUnassigned);
  put(DashboardKpiType.overdueTasks, taskOverdue);
  put(DashboardKpiType.appointmentsToday, appointmentToday);
  put(DashboardKpiType.missedAppointments, appointmentMissed);
  put(DashboardKpiType.pipelineDeals, dealOpen);
  put(DashboardKpiType.stuckDeals, dealAtRisk);
  put(DashboardKpiType.wonDealsThisMonth, dealWonThisMonth);
  put(DashboardKpiType.activeProperties, propertyAvailable);

  if (leadOverdue != null && taskOverdue != null) {
    put(DashboardKpiType.overdueActions, leadOverdue + taskOverdue);
  }
  if (leadActive != null && taskTotal != null && dealOpen != null) {
    final openTasks = taskTotal - (taskCompleted ?? 0) - (taskCancelled ?? 0);
    final boundedOpenTasks = openTasks.clamp(0, taskTotal).toInt();
    put(DashboardKpiType.teamWorkload, leadActive + boundedOpenTasks + dealOpen);
  }

  var changed = false;
  final metrics = analytics.metrics.map((metric) {
    final replacement = replacements[metric.type];
    if (replacement == null || metric.value == replacement) {
      return metric;
    }
    changed = true;
    return DashboardKpiMetric(
      type: metric.type,
      value: replacement,
      valueLabel: replacement.toString(),
      sparkline: metric.sparkline,
      trendPercent: metric.trendPercent,
    );
  }).toList(growable: false);

  if (!changed) {
    return analytics;
  }

  return DashboardAnalytics(
    role: analytics.role,
    metrics: metrics,
    leadTrend: analytics.leadTrend,
    followUpBars: analytics.followUpBars,
    appointmentBars: analytics.appointmentBars,
    dealStages: analytics.dealStages,
    leadSources: analytics.leadSources,
    todayItems: analytics.todayItems,
    calendarItems: analytics.calendarItems,
    performanceSeries: analytics.performanceSeries,
    teamPerformance: analytics.teamPerformance,
    teamRows: analytics.teamRows,
    importantOpportunities: analytics.importantOpportunities,
    dailyInsight: analytics.dailyInsight,
  );
}

String _dashboardCountsFingerprint(_DashboardData data) {
  return [
    _moduleCountsFingerprint(data.leadCounts),
    _moduleCountsFingerprint(data.propertyCounts),
    _moduleCountsFingerprint(data.taskCounts),
    _moduleCountsFingerprint(data.appointmentCounts),
    _moduleCountsFingerprint(data.dealCounts),
  ].join('|');
}

String _moduleCountsFingerprint(ModuleKpiCounts counts) {
  final keys = counts.values.keys.toList()..sort();
  final failed = counts.failedKeys.toList()..sort();
  return [
    for (final key in keys) '$key:${counts.values[key] ?? 0}',
    if (failed.isNotEmpty) 'failed:${failed.join(',')}',
  ].join(',');
}

class _DashboardAnalyticsCache {
  const _DashboardAnalyticsCache({
    required this.key,
    required this.analytics,
  });

  final _DashboardAnalyticsKey key;
  final DashboardAnalytics analytics;
}

class _SalesCommandCache {
  const _SalesCommandCache({
    required this.key,
    required this.commandSummary,
  });

  final _SalesCommandKey key;
  final SalesCommandSummary commandSummary;
}

class _DashboardDerivedData {
  const _DashboardDerivedData({
    required this.analytics,
    required this.commandSummary,
  });

  final DashboardAnalytics analytics;
  final SalesCommandSummary commandSummary;
}

class _DashboardAnalyticsKey {
  const _DashboardAnalyticsKey({
    required this.role,
    required this.minuteBucket,
    required this.leads,
    required this.properties,
    required this.tasks,
    required this.appointments,
    required this.deals,
    required this.activeUsers,
    required this.countsFingerprint,
    required this.includeLeads,
    required this.includeProperties,
    required this.includeTasks,
    required this.includeAppointments,
    required this.includeDeals,
    required this.canViewUnassignedLeads,
  });

  final UserRole role;
  final DateTime minuteBucket;
  final List<Lead> leads;
  final List<Property> properties;
  final List<CrmTask> tasks;
  final List<Appointment> appointments;
  final List<Deal> deals;
  final List<UserProfile> activeUsers;
  final String countsFingerprint;
  final bool includeLeads;
  final bool includeProperties;
  final bool includeTasks;
  final bool includeAppointments;
  final bool includeDeals;
  final bool canViewUnassignedLeads;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is _DashboardAnalyticsKey &&
            role == other.role &&
            minuteBucket == other.minuteBucket &&
            identical(leads, other.leads) &&
            identical(properties, other.properties) &&
            identical(tasks, other.tasks) &&
            identical(appointments, other.appointments) &&
            identical(deals, other.deals) &&
            identical(activeUsers, other.activeUsers) &&
            countsFingerprint == other.countsFingerprint &&
            includeLeads == other.includeLeads &&
            includeProperties == other.includeProperties &&
            includeTasks == other.includeTasks &&
            includeAppointments == other.includeAppointments &&
            includeDeals == other.includeDeals &&
            canViewUnassignedLeads == other.canViewUnassignedLeads;
  }

  @override
  int get hashCode => Object.hash(
        role,
        minuteBucket,
        identityHashCode(leads),
        identityHashCode(properties),
        identityHashCode(tasks),
        identityHashCode(appointments),
        identityHashCode(deals),
        identityHashCode(activeUsers),
        countsFingerprint,
        includeLeads,
        includeProperties,
        includeTasks,
        includeAppointments,
        includeDeals,
        canViewUnassignedLeads,
      );
}

class _SalesCommandKey {
  const _SalesCommandKey({
    required this.role,
    required this.minuteBucket,
    required this.leads,
    required this.tasks,
    required this.appointments,
    required this.deals,
    required this.includeLeads,
    required this.includeTasks,
    required this.includeAppointments,
    required this.includeDeals,
    required this.canViewUnassignedLeads,
  });

  final UserRole role;
  final DateTime minuteBucket;
  final List<Lead> leads;
  final List<CrmTask> tasks;
  final List<Appointment> appointments;
  final List<Deal> deals;
  final bool includeLeads;
  final bool includeTasks;
  final bool includeAppointments;
  final bool includeDeals;
  final bool canViewUnassignedLeads;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is _SalesCommandKey &&
            role == other.role &&
            minuteBucket == other.minuteBucket &&
            identical(leads, other.leads) &&
            identical(tasks, other.tasks) &&
            identical(appointments, other.appointments) &&
            identical(deals, other.deals) &&
            includeLeads == other.includeLeads &&
            includeTasks == other.includeTasks &&
            includeAppointments == other.includeAppointments &&
            includeDeals == other.includeDeals &&
            canViewUnassignedLeads == other.canViewUnassignedLeads;
  }

  @override
  int get hashCode => Object.hash(
        role,
        minuteBucket,
        identityHashCode(leads),
        identityHashCode(tasks),
        identityHashCode(appointments),
        identityHashCode(deals),
        includeLeads,
        includeTasks,
        includeAppointments,
        includeDeals,
        canViewUnassignedLeads,
      );
}

DateTime _dashboardMinuteBucket(DateTime value) {
  return DateTime(value.year, value.month, value.day, value.hour, value.minute);
}


class _DashboardControlRoom extends StatelessWidget {
  const _DashboardControlRoom({
    required this.analytics,
    required this.commandSummary,
    required this.authState,
    required this.compact,
    required this.mobile,
    required this.platformPreview,
    required this.analyticsEnabled,
    required this.auditLogsEnabled,
    required this.showQuickActions,
    this.previewCompanyName,
  });

  final DashboardAnalytics analytics;
  final SalesCommandSummary commandSummary;
  final AuthState authState;
  final bool compact;
  final bool mobile;
  final bool platformPreview;
  final bool analyticsEnabled;
  final bool auditLogsEnabled;
  final bool showQuickActions;
  final String? previewCompanyName;

  @override
  Widget build(BuildContext context) {
    final main = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DashboardReveal(
          id: 'control-room-welcome',
          delay: Duration.zero,
          child: _WelcomePanel(
            authState: authState,
            platformPreview: platformPreview,
            previewCompanyName: previewCompanyName,
          ),
        ),
        const SizedBox(height: _kDashboardSectionGap),
        _DashboardReveal(
          id: 'control-room-kpis',
          delay: const Duration(milliseconds: 50),
          child: _DashboardKpiGrid(analytics: analytics),
        ),
        if (mobile) ...[
          const SizedBox(height: _kDashboardSectionGap),
          _DashboardReveal(
            id: 'control-room-today-mobile',
            delay: const Duration(milliseconds: 70),
            child: _DashboardTodayRail(
              analytics: analytics,
              readOnly: platformPreview,
            ),
          ),
        ],
        const SizedBox(height: _kDashboardSectionGap),
        if (analyticsEnabled)
          _DashboardReveal(
            id: 'control-room-performance',
            delay: const Duration(milliseconds: 90),
            child: _DashboardPerformanceSection(analytics: analytics),
          ),
        const SizedBox(height: _kDashboardSectionGap),
        _DashboardReveal(
          id: 'control-room-command-center',
          delay: const Duration(milliseconds: 120),
          child: SalesCommandCenterPanel(
            summary: commandSummary,
            readOnly: platformPreview,
          ),
        ),
        const SizedBox(height: _kDashboardSectionGap),
        if (compact)
          Column(
            children: [
              _DashboardReveal(
                id: 'control-room-pipeline-compact',
                delay: const Duration(milliseconds: 150),
                child: _DashboardPipelineSnapshot(
                  analytics: analytics,
                  readOnly: platformPreview,
                ),
              ),
              const SizedBox(height: _kDashboardSectionGap),
              _DashboardReveal(
                id: 'control-room-team-compact',
                delay: const Duration(milliseconds: 180),
                child: _DashboardTeamPerformanceCard(analytics: analytics),
              ),
            ],
          )
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _DashboardReveal(
                  id: 'control-room-pipeline',
                  delay: const Duration(milliseconds: 150),
                  child: _DashboardPipelineSnapshot(
                    analytics: analytics,
                    readOnly: platformPreview,
                  ),
                ),
              ),
              const SizedBox(width: _kDashboardSectionGap),
              Expanded(
                child: _DashboardReveal(
                  id: 'control-room-team',
                  delay: const Duration(milliseconds: 180),
                  child: _DashboardTeamPerformanceCard(analytics: analytics),
                ),
              ),
            ],
          ),
        if (auditLogsEnabled &&
            _canViewRecentActivity(
              authState,
              platformPreview: platformPreview,
            )) ...[
          const SizedBox(height: _kDashboardSectionGap),
          _DashboardReveal(
            id: 'control-room-recent-activity',
            delay: const Duration(milliseconds: 210),
            child: _RecentActivityPanel(
              authState: authState,
              platformPreview: platformPreview,
            ),
          ),
        ],
      ],
    );

    if (compact) {
      return main;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: main),
        const SizedBox(width: _kDashboardSectionGap),
        SizedBox(
          width: 340,
          child: Column(
            children: [
              _DashboardReveal(
                id: 'control-room-today',
                delay: const Duration(milliseconds: 80),
                child: _DashboardTodayRail(
                  analytics: analytics,
                  readOnly: platformPreview,
                ),
              ),
              if (showQuickActions) ...[
                const SizedBox(height: _kDashboardSectionGap),
                _DashboardReveal(
                  id: 'control-room-actions',
                  delay: const Duration(milliseconds: 140),
                  child: _ActionPanel(authState: authState),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _DashboardKpiGrid extends StatelessWidget {
  const _DashboardKpiGrid({required this.analytics});

  final DashboardAnalytics analytics;

  @override
  Widget build(BuildContext context) {
    final metrics = analytics.metrics;
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1280
            ? 4
            : constraints.maxWidth >= 920
                ? 3
                : constraints.maxWidth >= 520
                    ? 2
                    : 1;
        const gap = AppSpacing.sm;
        final width = (constraints.maxWidth - (columns - 1) * gap) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final metric in metrics)
              SizedBox(
                width: width,
                child: _DashboardKpiCard(metric: metric),
              ),
          ],
        );
      },
    );
  }
}

class _DashboardKpiCard extends StatelessWidget {
  const _DashboardKpiCard({required this.metric});

  final DashboardKpiMetric metric;

  @override
  Widget build(BuildContext context) {
    final color = _kpiColor(context, metric.type);
    final trend = metric.trendPercent;
    return _HoverLiftPanel(
      borderRadius: AppRadius.xLarge,
      child: _Panel(
        padding: const EdgeInsetsDirectional.fromSTEB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: AppRadius.medium,
                  ),
                  child: Icon(_kpiIcon(metric.type), color: color, size: 18),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    _kpiTitle(context, metric.type),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppColors.textSecondaryColor(context),
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
                if (trend != null)
                  _TrendChip(value: trend),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Text(
                    _metricValueLabel(context, metric),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: AppColors.textPrimaryColor(context),
                          fontWeight: FontWeight.w900,
                          height: 1,
                        ),
                  ),
                ),
                SizedBox(
                  width: 82,
                  height: 32,
                  child: _DashboardSparkline(
                    values: metric.sparkline,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              _kpiPeriod(context, metric.type),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textSecondaryColor(context),
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrendChip extends StatelessWidget {
  const _TrendChip({required this.value});

  final int value;

  @override
  Widget build(BuildContext context) {
    final positive = value >= 0;
    final color = positive
        ? AppColors.successColor(context)
        : AppColors.errorColor(context);
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            positive ? Icons.trending_up_rounded : Icons.trending_down_rounded,
            size: 13,
            color: color,
          ),
          const SizedBox(width: 2),
          Text(
            '${positive ? '+' : ''}$value%',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w900,
                ),
          ),
        ],
      ),
    );
  }
}

class _DashboardPerformanceSection extends StatelessWidget {
  const _DashboardPerformanceSection({required this.analytics});

  final DashboardAnalytics analytics;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionHeader(
            title: AppLocalizations.of(context)!.dashboardPerformanceTitle,
            subtitle: AppLocalizations.of(context)!.dashboardLast7Days,
          ),
          const SizedBox(height: AppSpacing.md),
          LayoutBuilder(
            builder: (context, constraints) {
              final twoColumns = constraints.maxWidth >= 760;
              final width = twoColumns
                  ? (constraints.maxWidth - AppSpacing.md) / 2
                  : constraints.maxWidth;
              return Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.md,
                children: [
                  SizedBox(
                    width: width,
                    child: _TrendChartPanel(
                      title: AppLocalizations.of(context)!.dashboardLeadsTrend,
                      points: analytics.leadTrend,
                      color: AppColors.infoColor(context),
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: _BarChartPanel(
                      title: AppLocalizations.of(context)!
                          .dashboardFollowUpsCompletedMissed,
                      rows: analytics.followUpBars,
                      labelBuilder: (key) => _barLabel(context, key),
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: _BarChartPanel(
                      title:
                          AppLocalizations.of(context)!.dashboardAppointmentsFlow,
                      rows: analytics.appointmentBars,
                      labelBuilder: (key) => _barLabel(context, key),
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: _LeadSourcePanel(analytics: analytics),
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

class _TrendChartPanel extends StatelessWidget {
  const _TrendChartPanel({
    required this.title,
    required this.points,
    required this.color,
  });

  final String title;
  final List<DashboardTrendPoint> points;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return _InnerDashboardPanel(
      title: title,
      child: SizedBox(
        height: 172,
        child: CustomPaint(
          painter: _TrendLinePainter(
            values: points.map((point) => point.value).toList(),
            color: color,
            gridColor: AppColors.borderColor(context),
            textColor: AppColors.textSecondaryColor(context),
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _BarChartPanel extends StatelessWidget {
  const _BarChartPanel({
    required this.title,
    required this.rows,
    required this.labelBuilder,
  });

  final String title;
  final List<DashboardBarMetric> rows;
  final String Function(String key) labelBuilder;

  @override
  Widget build(BuildContext context) {
    final maxValue = rows.fold<int>(
      0,
      (max, item) => item.value > max ? item.value : max,
    );
    return _InnerDashboardPanel(
      title: title,
      child: Column(
        children: [
          for (var index = 0; index < rows.length; index++)
            Padding(
              padding: EdgeInsets.only(
                bottom: index == rows.length - 1 ? 0 : AppSpacing.sm,
              ),
              child: _ProgressRow(
                label: labelBuilder(rows[index].key),
                value: maxValue == 0 ? 0 : rows[index].value / maxValue,
                trailing: rows[index].value.toString(),
                color: _barColor(context, rows[index].key),
              ),
            ),
        ],
      ),
    );
  }
}

class _LeadSourcePanel extends StatelessWidget {
  const _LeadSourcePanel({required this.analytics});

  final DashboardAnalytics analytics;

  @override
  Widget build(BuildContext context) {
    final sources = analytics.leadSources.take(5).toList();
    return _InnerDashboardPanel(
      title: AppLocalizations.of(context)!.dashboardLeadSources,
      child: sources.isEmpty
          ? _CompactEmpty(
              message: AppLocalizations.of(context)!.dashboardNotEnoughData,
            )
          : Column(
              children: [
                for (var index = 0; index < sources.length; index++)
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: index == sources.length - 1 ? 0 : AppSpacing.xs,
                    ),
                    child: _ProgressRow(
                      label: _leadSourceLabel(
                        AppLocalizations.of(context)!,
                        sources[index].source,
                      ),
                      value: sources[index].count /
                          sources
                              .fold<int>(
                                0,
                                (total, source) => total + source.count,
                              )
                              .clamp(1, 999999),
                      trailing: sources[index].count.toString(),
                      color: _sourceColor(context, index),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _DashboardTodayRail extends StatelessWidget {
  const _DashboardTodayRail({
    required this.analytics,
    required this.readOnly,
  });

  final DashboardAnalytics analytics;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final now = DateTime.now();
    return _Panel(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionHeader(
            title: l.dashboardTodayRailTitle,
            subtitle: intl.DateFormat.yMMMMEEEEd(l.localeName).format(now),
          ),
          const SizedBox(height: AppSpacing.md),
          _DashboardWeekStrip(now: now),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _RailCounter(
                  label: l.todaysAppointments,
                  value: _todayCount(analytics, DashboardTodayModule.appointment),
                  tone: AppStatusTone.info,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _RailCounter(
                  label: l.dashboardDueFollowUps,
                  value: _todayCount(analytics, DashboardTodayModule.followUp),
                  tone: AppStatusTone.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (analytics.todayItems.isEmpty)
            _CompactEmpty(message: l.dashboardNoUrgentActions)
          else
            for (final item in analytics.todayItems.take(5))
              _TodayRailItem(
                item: item,
                readOnly: readOnly,
              ),
        ],
      ),
    );
  }
}

class _DashboardWeekStrip extends StatelessWidget {
  const _DashboardWeekStrip({required this.now});

  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final today = _dateOnly(now);
    final start = today.subtract(Duration(days: today.weekday - 1));
    return Row(
      children: [
        for (var index = 0; index < 7; index++)
          Expanded(
            child: Padding(
              padding: EdgeInsetsDirectional.only(
                end: index == 6 ? 0 : 4,
              ),
              child: _WeekDayPill(
                date: start.add(Duration(days: index)),
                selected: _dateOnly(start.add(Duration(days: index))) == today,
                localeName: l.localeName,
              ),
            ),
          ),
      ],
    );
  }
}

class _WeekDayPill extends StatelessWidget {
  const _WeekDayPill({
    required this.date,
    required this.selected,
    required this.localeName,
  });

  final DateTime date;
  final bool selected;
  final String localeName;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.primaryColor(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: selected ? color.withValues(alpha: 0.16) : AppColors.inputSurface(context),
        border: Border.all(
          color: selected ? color : AppColors.borderColor(context),
        ),
        borderRadius: AppRadius.large,
      ),
      child: Column(
        children: [
          Text(
            intl.DateFormat.E(localeName).format(date),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textSecondaryColor(context),
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            date.day.toString(),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: selected ? color : AppColors.textPrimaryColor(context),
                  fontWeight: FontWeight.w900,
                ),
          ),
        ],
      ),
    );
  }
}

class _RailCounter extends StatelessWidget {
  const _RailCounter({
    required this.label,
    required this.value,
    required this.tone,
  });

  final String label;
  final int value;
  final AppStatusTone tone;

  @override
  Widget build(BuildContext context) {
    final color = _toneColor(context, tone);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: AppRadius.large,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value.toString(),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w900,
                ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textSecondaryColor(context),
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _TodayRailItem extends StatelessWidget {
  const _TodayRailItem({
    required this.item,
    required this.readOnly,
  });

  final DashboardTodayItem item;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final route = readOnly ? null : _todayRoute(item);
    final color = _urgencyColor(context, item.urgency);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: route == null ? null : () => context.go(route),
          borderRadius: AppRadius.large,
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.inputSurface(context),
              border: Border.all(color: AppColors.borderColor(context)),
              borderRadius: AppRadius.large,
            ),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 42,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Icon(_todayIcon(item.module), size: 18, color: color),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _todaySubtitle(context, item),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppColors.textSecondaryColor(context),
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                  ),
                ),
                if (route != null) ...[
                  const SizedBox(width: AppSpacing.xs),
                  Icon(
                    Icons.open_in_new_rounded,
                    size: 16,
                    color: AppColors.textSecondaryColor(context),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardPipelineSnapshot extends StatelessWidget {
  const _DashboardPipelineSnapshot({
    required this.analytics,
    required this.readOnly,
  });

  final DashboardAnalytics analytics;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final openStages = analytics.dealStages
        .where((item) => item.stage != DealStage.won && item.stage != DealStage.lost)
        .toList();
    return _Panel(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionHeader(
            title: l.dashboardPipelineSnapshot,
            subtitle: analytics.pipelineValueTotal > 0
                ? _formatMoney(context, analytics.pipelineValueTotal)
                : l.dashboardPipelineHasNoValue,
          ),
          const SizedBox(height: AppSpacing.md),
          _HorizontalDistribution(
            rows: [
              for (final stage in openStages)
                _DistributionRow(
                  label: dealStageLabel(l, stage.stage),
                  value: stage.count,
                  color: _dealStageColor(context, stage.stage),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _MiniMetric(
                label: l.dashboardStuckDeals,
                value: analytics.stuckDealsCount,
              ),
              _MiniMetric(
                label: l.dashboardClosingThisMonth,
                value: analytics.closingThisMonthCount,
              ),
              _MiniMetric(
                label: l.dashboardWonLost,
                value:
                    '${analytics.dealStages.firstWhere((item) => item.stage == DealStage.won).count}/${analytics.dealStages.firstWhere((item) => item.stage == DealStage.lost).count}',
              ),
            ],
          ),
          if (!readOnly && analytics.openPipelineDeals > 0) ...[
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: l.viewAll,
              icon: Icons.open_in_new_rounded,
              variant: AppButtonVariant.secondary,
              onPressed: () => context.go(RouteNames.deals),
            ),
          ],
        ],
      ),
    );
  }
}

class _DashboardTeamPerformanceCard extends StatelessWidget {
  const _DashboardTeamPerformanceCard({required this.analytics});

  final DashboardAnalytics analytics;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final performance = analytics.teamPerformance;
    final personal = performance.role == UserRole.salesAgent ||
        performance.role == UserRole.marketing;
    return _Panel(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionHeader(
            title: personal
                ? l.dashboardPersonalPerformance
                : l.dashboardTeamPerformance,
            subtitle: performance.isLimited
                ? l.dashboardPerformanceLimitedForRole
                : l.dashboardLast7Days,
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _MiniMetric(
                label: l.dashboardOverdueReminders,
                value: performance.overdueActions,
              ),
              _MiniMetric(
                label: l.dashboardDueFollowUps,
                value: performance.dueTodayActions,
              ),
              _MiniMetric(
                label: l.todaysAppointments,
                value: performance.appointmentsToday,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (performance.isLimited)
            _CompactEmpty(message: l.dashboardPerformanceLimitedForRole)
          else ...[
            _AgentInsightRow(
              title: l.dashboardTopActiveAgent,
              agent: performance.topActiveAgent,
            ),
            const SizedBox(height: AppSpacing.sm),
            _AgentInsightRow(
              title: l.dashboardOverloadedAssignee,
              agent: performance.overloadedAssignee,
              empty: l.dashboardNoTeamSignal,
            ),
          ],
        ],
      ),
    );
  }
}

class _AgentInsightRow extends StatelessWidget {
  const _AgentInsightRow({
    required this.title,
    required this.agent,
    this.empty,
  });

  final String title;
  final DashboardAgentPerformance? agent;
  final String? empty;

  @override
  Widget build(BuildContext context) {
    final item = agent;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.inputSurface(context),
        border: Border.all(color: AppColors.borderColor(context)),
        borderRadius: AppRadius.large,
      ),
      child: Row(
        children: [
          Icon(
            Icons.person_pin_circle_outlined,
            color: AppColors.primaryColor(context),
            size: 20,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textSecondaryColor(context),
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  item?.name ?? empty ?? AppLocalizations.of(context)!.notAvailable,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ],
            ),
          ),
          if (item != null)
            AppStatusBadge(
              label: item.overdueActions > 0
                  ? item.overdueActions.toString()
                  : item.activeRecords.toString(),
              tone: item.overdueActions > 0
                  ? AppStatusTone.error
                  : AppStatusTone.success,
            ),
        ],
      ),
    );
  }
}

class _InnerDashboardPanel extends StatelessWidget {
  const _InnerDashboardPanel({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.inputSurface(context),
        border: Border.all(color: AppColors.borderColor(context)),
        borderRadius: AppRadius.large,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          child,
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondaryColor(context),
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DashboardSparkline extends StatelessWidget {
  const _DashboardSparkline({
    required this.values,
    required this.color,
  });

  final List<int> values;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _SparklinePainter(
        values: values,
        color: color,
        fillColor: color.withValues(alpha: 0.12),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  const _SparklinePainter({
    required this.values,
    required this.color,
    required this.fillColor,
  });

  final List<int> values;
  final Color color;
  final Color fillColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) {
      return;
    }
    final maxValue = values.fold<int>(
      1,
      (max, value) => value > max ? value : max,
    );
    final dx = values.length == 1 ? size.width : size.width / (values.length - 1);
    final path = Path();
    final fill = Path();
    for (var index = 0; index < values.length; index++) {
      final x = index * dx;
      final y = size.height - (values[index] / maxValue) * (size.height - 4) - 2;
      if (index == 0) {
        path.moveTo(x, y);
        fill.moveTo(x, size.height);
        fill.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fill.lineTo(x, y);
      }
    }
    fill.lineTo(size.width, size.height);
    fill.close();
    canvas.drawPath(fill, Paint()..color = fillColor);
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return values != oldDelegate.values ||
        color != oldDelegate.color ||
        fillColor != oldDelegate.fillColor;
  }
}

class _TrendLinePainter extends CustomPainter {
  const _TrendLinePainter({
    required this.values,
    required this.color,
    required this.gridColor,
    required this.textColor,
  });

  final List<int> values;
  final Color color;
  final Color gridColor;
  final Color textColor;

  @override
  void paint(Canvas canvas, Size size) {
    final left = 28.0;
    final bottom = 22.0;
    final chartSize = Size(size.width - left, size.height - bottom);
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (var i = 0; i < 4; i++) {
      final y = chartSize.height * (i / 3);
      canvas.drawLine(Offset(left, y), Offset(size.width, y), gridPaint);
    }

    final maxValue = values.fold<int>(
      1,
      (max, value) => value > max ? value : max,
    );
    final dx = values.length <= 1 ? chartSize.width : chartSize.width / (values.length - 1);
    final path = Path();
    for (var index = 0; index < values.length; index++) {
      final x = left + index * dx;
      final y = chartSize.height - (values[index] / maxValue) * (chartSize.height - 10) - 5;
      if (index == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
      canvas.drawCircle(Offset(x, y), 3, Paint()..color = color);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _TrendLinePainter oldDelegate) {
    return values != oldDelegate.values ||
        color != oldDelegate.color ||
        gridColor != oldDelegate.gridColor ||
        textColor != oldDelegate.textColor;
  }
}

class _TrialNoticeGate extends StatefulWidget {
  const _TrialNoticeGate({required this.company, required this.child});

  final CompanyMetadata? company;
  final Widget child;

  @override
  State<_TrialNoticeGate> createState() => _TrialNoticeGateState();
}

class _TrialAccessGate extends StatefulWidget {
  const _TrialAccessGate({
    required this.company,
    required this.child,
  });

  final CompanyMetadata? company;
  final Widget child;

  @override
  State<_TrialAccessGate> createState() => _TrialAccessGateState();
}

class _TrialAccessGateState extends State<_TrialAccessGate> {
  bool _expired = false;
  bool _checkFailed = false;
  String? _checkedKey;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkTrialAccess());
  }

  @override
  void didUpdateWidget(covariant _TrialAccessGate oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.company?.id != widget.company?.id ||
        oldWidget.company?.status != widget.company?.status ||
        oldWidget.company?.trialStartedAt != widget.company?.trialStartedAt ||
        oldWidget.company?.trialEndsAt != widget.company?.trialEndsAt ||
        oldWidget.company?.paymentStatus != widget.company?.paymentStatus ||
        oldWidget.company?.gracePeriodEndsAt != widget.company?.gracePeriodEndsAt) {
      _checkedKey = null;
      _expired = false;
      _checkFailed = false;
      WidgetsBinding.instance.addPostFrameCallback((_) => _checkTrialAccess());
    }
  }

  Future<void> _checkTrialAccess() async {
    final company = widget.company;
    final isTrialCheck = company != null && company.isTrial && company.trialEndsAt != null;
    final isGraceCheck = company != null &&
        company.paymentStatus == 'gracePeriod' &&
        company.gracePeriodEndsAt != null;
    if (!mounted || company == null || (!isTrialCheck && !isGraceCheck)) {
      return;
    }

    final target = isTrialCheck ? company.trialEndsAt! : company.gracePeriodEndsAt!;
    final key = isTrialCheck
        ? '${company.id}:trial:${company.trialStartedAt?.millisecondsSinceEpoch ?? 0}:${target.millisecondsSinceEpoch}'
        : '${company.id}:payment:${target.millisecondsSinceEpoch}';
    if (_checkedKey == key && !_expired) {
      return;
    }

    setState(() {
      _checkFailed = false;
    });
    try {
      final serverNow = await ServerClock.instance.now(forceRefresh: true);
      if (!mounted) {
        return;
      }
      setState(() {
        _checkedKey = key;
        _expired = !serverNow.isBefore(target);
        _checkFailed = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _checkFailed = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final company = widget.company;
    final isSuspended = company?.paymentStatus == 'suspended';
    final isTrialCheck = company != null && company.isTrial && company.trialEndsAt != null;
    final isGraceCheck = company != null &&
        company.paymentStatus == 'gracePeriod' &&
        company.gracePeriodEndsAt != null;
    if (isSuspended) {
      return AppErrorView(
        message: AppLocalizations.of(context)!.paymentAccessBlockedMessage,
        onRetry: _checkTrialAccess,
      );
    }
    if (company == null || (!isTrialCheck && !isGraceCheck)) {
      return widget.child;
    }
    if (_checkedKey == null) {
      if (_checkFailed) {
        return AppErrorView(
          message: AppLocalizations.of(context)!.unableToConnect,
          onRetry: _checkTrialAccess,
        );
      }
      return const AppLoading();
    }
    if (_expired) {
      return AppErrorView(
        message: isTrialCheck
            ? AppLocalizations.of(context)!.trialEndedAccessMessage
            : AppLocalizations.of(context)!.paymentAccessBlockedMessage,
        onRetry: _checkTrialAccess,
      );
    }
    return widget.child;
  }
}

class _TrialNoticeGateState extends State<_TrialNoticeGate> {
  String? _lastDialogKey;
  Timer? _trialNoticeTimer;

  @override
  void initState() {
    super.initState();
    _startTrialNoticeTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowTrialNotice());
  }

  @override
  void dispose() {
    _trialNoticeTimer?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _TrialNoticeGate oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.company?.id != widget.company?.id ||
        oldWidget.company?.trialStartedAt != widget.company?.trialStartedAt ||
        oldWidget.company?.trialEndsAt != widget.company?.trialEndsAt ||
        oldWidget.company?.status != widget.company?.status) {
      _startTrialNoticeTimer();
      WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowTrialNotice());
    }
  }

  void _startTrialNoticeTimer() {
    _trialNoticeTimer?.cancel();
    final company = widget.company;
    if (company == null || !company.isTrial || company.trialEndsAt == null) {
      return;
    }
    _trialNoticeTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _maybeShowTrialNotice(),
    );
  }

  Future<void> _maybeShowTrialNotice() async {
    final company = widget.company;
    if (!mounted || company == null || !company.isTrial || company.trialEndsAt == null) {
      return;
    }

    late final DateTime serverNow;
    try {
      serverNow = await ServerClock.instance.now();
    } catch (_) {
      // Do not use the device clock for trial/payment UX. If server time cannot
      // be reached, skip this client-side reminder until the next check.
      return;
    }
    if (!mounted) {
      return;
    }

    final trialEndsAt = company.trialEndsAt!;
    if (!serverNow.isBefore(trialEndsAt)) {
      // Once the trial has ended, the access gate owns the blocking UI.
      // Showing or closing a reminder dialog during the same frame that the
      // router/dashboard tree is being replaced can trip Navigator/GlobalKey
      // assertions on Flutter Web.
      return;
    }

    final milestone = _trialMilestone(company, serverNow);
    if (milestone == null) {
      return;
    }
    final key = 'trial_notice_${company.id}_${company.trialStartedAt?.millisecondsSinceEpoch ?? 0}_$milestone';
    if (_lastDialogKey == key) {
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    if (!mounted || (prefs.getBool(key) ?? false)) {
      return;
    }
    _lastDialogKey = key;
    final l = AppLocalizations.of(context)!;
    final remaining = trialEndsAt.difference(serverNow);
    final remainingText = _formatTrialRemaining(l, remaining);
    final milestoneText = _trialMilestoneText(l, milestone);
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l.trialReminderTitle),
          content: Text(
            '$milestoneText\n\n'
            '${l.trialRemaining}: $remainingText\n'
            '${l.trialEndsAt}: ${_formatTrialEndDate(dialogContext, trialEndsAt)}',
          ),
          actions: [
            TextButton(
              onPressed: () {
                // Close the dialog synchronously before writing preferences so
                // an auth/company refresh cannot dispose the routed dashboard
                // while this callback awaits. This avoids Navigator lock and
                // duplicate GlobalKey assertions when the trial expires.
                final navigator = Navigator.maybeOf(
                  dialogContext,
                  rootNavigator: true,
                );
                if (navigator?.canPop() ?? false) {
                  navigator!.pop();
                }
                unawaited(prefs.setBool(key, true));
              },
              child: Text(l.done),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

int? _trialMilestone(CompanyMetadata? company, DateTime now) {
  if (company == null) {
    return null;
  }
  final start = company.trialStartedAt;
  final end = company.trialEndsAt;
  if (start == null || end == null || !company.isTrial) {
    return null;
  }
  final total = end.difference(start).inSeconds;
  if (total <= 0) {
    return 3;
  }
  final elapsed = now.difference(start).inSeconds;
  if (elapsed < 0) {
    return null;
  }
  final finalWarningAt = (total * 0.90).floor().clamp(1, total);
  if (elapsed >= finalWarningAt) return 3;
  if (elapsed >= (total * 2 / 3)) return 2;
  if (elapsed >= (total / 3)) return 1;
  return null;
}

String _trialMilestoneText(AppLocalizations l, int milestone) {
  return switch (milestone) {
    1 => l.trialFirstReminderMessage,
    2 => l.trialSecondReminderMessage,
    _ => l.trialFinalReminderMessage,
  };
}

class _TrialBadgeBanner extends StatefulWidget {
  const _TrialBadgeBanner({required this.company});

  final CompanyMetadata? company;

  @override
  State<_TrialBadgeBanner> createState() => _TrialBadgeBannerState();
}

class _TrialBadgeBannerState extends State<_TrialBadgeBanner> {
  DateTime? _serverNow;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _refreshServerTime();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => _refreshServerTime());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _TrialBadgeBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.company?.id != widget.company?.id ||
        oldWidget.company?.trialEndsAt != widget.company?.trialEndsAt ||
        oldWidget.company?.status != widget.company?.status) {
      _refreshServerTime(forceRefresh: true);
    }
  }

  Future<void> _refreshServerTime({bool forceRefresh = false}) async {
    final company = widget.company;
    if (company == null || !company.isTrial || company.trialEndsAt == null) {
      return;
    }
    try {
      final now = await ServerClock.instance.now(forceRefresh: forceRefresh);
      if (mounted) {
        setState(() => _serverNow = now);
      }
    } catch (_) {
      // Never fall back to the device clock for trial/payment remaining time.
    }
  }

  @override
  Widget build(BuildContext context) {
    final company = widget.company;
    if (company == null) {
      return const SizedBox.shrink();
    }
    final l = AppLocalizations.of(context)!;
    final endsAt = company.trialEndsAt;
    if (!company.isTrial || endsAt == null) {
      return const SizedBox.shrink();
    }
    final serverNow = _serverNow ?? ServerClock.instance.estimatedNow;
    final remainingText = serverNow == null
        ? l.trial
        : _formatTrialRemaining(l, endsAt.difference(serverNow));
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.warningColor(context).withValues(alpha: 0.10),
        border: Border.all(color: AppColors.warningColor(context).withValues(alpha: 0.28)),
        borderRadius: AppRadius.large,
      ),
      child: Row(
        children: [
          Icon(Icons.hourglass_top_outlined, color: AppColors.warningColor(context), size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              '${l.trial} - $remainingText - ${l.trialEndsAt}: ${_formatTrialEndDate(context, endsAt)}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentStatusBanner extends StatelessWidget {
  const _PaymentStatusBanner({required this.company});

  final CompanyMetadata? company;

  @override
  Widget build(BuildContext context) {
    final current = company;
    final status = current?.paymentStatus;
    if (current == null ||
        status == null ||
        !['overdue', 'gracePeriod', 'suspended', 'dueSoon'].contains(status)) {
      return const SizedBox.shrink();
    }
    final l = AppLocalizations.of(context)!;
    final message = switch (status) {
      'suspended' => l.paymentAccessBlockedMessage,
      'gracePeriod' => l.paymentGraceMessage,
      'overdue' => l.paymentOverdueMessage,
      _ => l.paymentDueSoonMessage,
    };
    final tone = status == 'suspended' || status == 'overdue'
        ? AppStatusTone.error
        : AppStatusTone.warning;
    final color = _toneColor(context, tone);
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        border: Border.all(color: color.withValues(alpha: 0.28)),
        borderRadius: AppRadius.large,
      ),
      child: Row(
        children: [
          Icon(Icons.payments_outlined, color: color, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}


class _MobileDashboardTabs extends StatelessWidget {
  const _MobileDashboardTabs({
    required this.data,
    required this.authState,
    required this.platformPreview,
    required this.commandSummary,
    required this.leadsEnabled,
    required this.tasksEnabled,
    required this.dealsEnabled,
    required this.appointmentsEnabled,
    required this.auditLogsEnabled,
    required this.analyticsEnabled,
    required this.canViewUnassignedLeads,
    required this.quickAddActions,
    required this.onRefresh,
    this.previewCompanyName,
  });

  final _DashboardData data;
  final AuthState authState;
  final bool platformPreview;
  final String? previewCompanyName;
  final SalesCommandSummary commandSummary;
  final bool leadsEnabled;
  final bool tasksEnabled;
  final bool dealsEnabled;
  final bool appointmentsEnabled;
  final bool auditLogsEnabled;
  final bool analyticsEnabled;
  final bool canViewUnassignedLeads;
  final List<_QuickAddAction> quickAddActions;
  final Future<void> Function() onRefresh;

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
          onRefresh: onRefresh,
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
            _DashboardReveal(
              id: 'mobile-sales-command-center',
              delay: const Duration(milliseconds: 80),
              child: SalesCommandCenterPanel(
                summary: commandSummary,
                readOnly: platformPreview,
              ),
            ),
            if (auditLogsEnabled &&
                _canViewRecentActivity(authState, platformPreview: platformPreview))
              _DashboardReveal(
                id: 'mobile-dashboard-recent-activity',
                delay: const Duration(milliseconds: 100),
                child: _RecentActivityPanel(
                  authState: authState,
                  platformPreview: platformPreview,
                ),
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
            onRefresh: onRefresh,
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
            onRefresh: onRefresh,
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
            onRefresh: onRefresh,
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
            onRefresh: onRefresh,
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
            onRefresh: onRefresh,
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
                  physics: const NeverScrollableScrollPhysics(),
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
    return MasarTabBar(
      compact: true,
      tabs: [
        for (final tab in tabs)
          MasarTabItem(label: tab.label, icon: tab.icon),
      ],
    );
  }
}

class _MobileDashboardTabBody extends StatelessWidget {
  const _MobileDashboardTabBody({
    required this.children,
    required this.hasQuickActions,
    required this.onRefresh,
  });

  final List<Widget> children;
  final bool hasQuickActions;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const MasarRefreshPhysics(parent: BouncingScrollPhysics()),
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
            width: 248,
            height: 248,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: AlignmentDirectional.bottomEnd,
              children: [
                for (var index = 0; index < widget.actions.length; index++)
                  _QuickAddMenuItem(
                    action: widget.actions[index],
                    index: index,
                    total: widget.actions.length,
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
    required this.total,
    required this.animation,
    required this.onTap,
  });

  final _QuickAddAction action;
  final int index;
  final int total;
  final Animation<double> animation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textDirection = Directionality.of(context);
    final total = math.max(1, this.total);
    final isRtl = textDirection == TextDirection.rtl;
    final startAngle = isRtl ? -85.0 : -95.0;
    final endAngle = isRtl ? -5.0 : -175.0;
    final denominator = math.max(1, total - 1);
    final angleDegrees = total == 1
        ? (isRtl ? -45.0 : -135.0)
        : startAngle + ((endAngle - startAngle) * index / denominator);
    final angle = angleDegrees * math.pi / 180;
    final radius = 88.0 + (math.min(index, 2) * 10.0);
    final offset = Offset(math.cos(angle) * radius, math.sin(angle) * radius);

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return PositionedDirectional(
          end: 0,
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
    final disableReveal = kIsWeb && MediaQuery.sizeOf(context).width < 720;
    if (disableReveal) {
      return widget.child;
    }

    return VisibilityDetector(
      key: ValueKey('dashboard-reveal-${widget.id}'),
      onVisibilityChanged: (info) {
        if (info.visibleFraction >= _kDashboardRevealThreshold) {
          _show();
        }
      },
      child: AnimatedOpacity(
        opacity: _visible ? 1 : 0,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        child: AnimatedSlide(
          offset: _visible ? Offset.zero : const Offset(0, 0.018),
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
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
    final appointmentsEnabled =
        features.isFeatureEnabled(CompanyFeature.appointments);
    final cards = [
      if (leadsEnabled)
        _MetricItem(
          l.totalLeads,
          data.leads.length,
          AppStatusTone.info,
          Icons.people_alt_outlined,
          percentageLabel: _metricTrendLabel(
            context,
            _countThisMonth(data.leads.map((lead) => lead.createdAt)),
            _countPreviousMonth(data.leads.map((lead) => lead.createdAt)),
          ),
          percentageCaption: l.dashboardVsLastMonth,
          percentageTone: _metricTrendTone(
            _countThisMonth(data.leads.map((lead) => lead.createdAt)),
            _countPreviousMonth(data.leads.map((lead) => lead.createdAt)),
          ),
          percentageIsTrend: true,
        ),
      if (leadsEnabled)
        _MetricItem(
          l.newLeads,
          data.newLeads.length,
          AppStatusTone.neutral,
          Icons.person_add_alt_outlined,
          percentageLabel: _metricPercentLabel(
            context,
            data.newLeads.length,
            data.leads.length,
          ),
          percentageCaption: l.dashboardOfCurrentTotal,
          percentageTone: AppStatusTone.success,
        ),
      if (tasksEnabled || leadsEnabled)
        _MetricItem(
          copy.upcomingFollowUps,
          data.upcomingFollowUps.length,
          AppStatusTone.info,
          Icons.upcoming_outlined,
          percentageLabel: _metricPercentLabel(
            context,
            data.upcomingFollowUps.length,
            data.leads.length,
          ),
          percentageCaption: l.dashboardOfCurrentTotal,
        ),
      if (tasksEnabled || leadsEnabled)
        _MetricItem(
          copy.overdueFollowUps,
          data.overdueFollowUps.length,
          AppStatusTone.error,
          Icons.schedule_outlined,
          percentageLabel: _metricPercentLabel(
            context,
            data.overdueFollowUps.length,
            data.leads.length,
          ),
          percentageCaption: l.dashboardOfCurrentTotal,
          percentageTone: AppStatusTone.error,
        ),
      if (appointmentsEnabled)
        _MetricItem(
          l.upcomingAppointments,
          data.upcomingAppointments.length,
          AppStatusTone.info,
          Icons.event_available_outlined,
          percentageLabel: _metricPercentLabel(
            context,
            data.upcomingAppointments.length,
            data.appointments.length,
          ),
          percentageCaption: l.dashboardOfCurrentTotal,
        ),
      if (appointmentsEnabled)
        _MetricItem(
          l.missedAppointments,
          data.missedAppointments.length,
          AppStatusTone.error,
          Icons.event_busy_outlined,
          percentageLabel: _metricPercentLabel(
            context,
            data.missedAppointments.length,
            data.appointments.length,
          ),
          percentageCaption: l.dashboardOfCurrentTotal,
          percentageTone: AppStatusTone.error,
        ),
      if (dealsEnabled)
        _MetricItem(
          l.openDeals,
          data.openDeals.length,
          AppStatusTone.warning,
          Icons.handshake_outlined,
          percentageLabel: _metricPercentLabel(
            context,
            data.openDeals.length,
            data.deals.length,
          ),
          percentageCaption: l.dashboardOfCurrentTotal,
        ),
      if (dealsEnabled)
        _MetricItem(
          l.wonDeals,
          data.wonDeals.length,
          AppStatusTone.success,
          Icons.emoji_events_outlined,
          percentageLabel: _metricTrendLabel(
            context,
            _countThisMonth(data.wonDeals.map((deal) => deal.updatedAt ?? deal.createdAt)),
            _countPreviousMonth(data.wonDeals.map((deal) => deal.updatedAt ?? deal.createdAt)),
          ),
          percentageCaption: l.dashboardVsLastMonth,
          percentageTone: _metricTrendTone(
            _countThisMonth(data.wonDeals.map((deal) => deal.updatedAt ?? deal.createdAt)),
            _countPreviousMonth(data.wonDeals.map((deal) => deal.updatedAt ?? deal.createdAt)),
          ),
          percentageIsTrend: true,
        ),
      if (propertiesEnabled)
        _MetricItem(
          copy.availableProperties,
          data.availableProperties.length,
          AppStatusTone.success,
          Icons.apartment_outlined,
          percentageLabel: _metricPercentLabel(
            context,
            data.availableProperties.length,
            data.properties.length,
          ),
          percentageCaption: l.dashboardOfCurrentTotal,
          percentageTone: AppStatusTone.success,
        ),
      if (clientsEnabled)
        _MetricItem(
          l.clients,
          data.clients.length,
          AppStatusTone.neutral,
          Icons.group_outlined,
          percentageLabel: _metricTrendLabel(
            context,
            _countThisMonth(data.clients.map((client) => client.createdAt)),
            _countPreviousMonth(data.clients.map((client) => client.createdAt)),
          ),
          percentageCaption: l.dashboardVsLastMonth,
          percentageTone: _metricTrendTone(
            _countThisMonth(data.clients.map((client) => client.createdAt)),
            _countPreviousMonth(data.clients.map((client) => client.createdAt)),
          ),
          percentageIsTrend: true,
        ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1180
            ? 5
            : constraints.maxWidth >= 860
                ? 4
                : 2;
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


String _metricPercentLabel(BuildContext context, int value, int total) {
  if (total <= 0 || value <= 0) {
    return '0%';
  }
  final localeName = Localizations.localeOf(context).toLanguageTag();
  return intl.NumberFormat.decimalPercentPattern(
    locale: localeName,
    decimalDigits: 0,
  ).format(value / total);
}

String _metricTrendLabel(BuildContext context, int current, int previous) {
  final localeName = Localizations.localeOf(context).toLanguageTag();
  if (current == 0 && previous == 0) {
    return '0%';
  }
  final ratio = previous <= 0 ? 1.0 : (current - previous) / previous;
  final formatted = intl.NumberFormat.decimalPercentPattern(
    locale: localeName,
    decimalDigits: 0,
  ).format(ratio.abs());
  if (ratio > 0) {
    return '+$formatted';
  }
  if (ratio < 0) {
    return '-$formatted';
  }
  return '0%';
}

AppStatusTone _metricTrendTone(int current, int previous) {
  if (current < previous) {
    return AppStatusTone.error;
  }
  if (current > previous) {
    return AppStatusTone.success;
  }
  return AppStatusTone.neutral;
}

int _countThisMonth(Iterable<DateTime?> dates) {
  final now = DateTime.now();
  return dates.where((date) {
    if (date == null) {
      return false;
    }
    final local = date.toLocal();
    return local.year == now.year && local.month == now.month;
  }).length;
}

int _countPreviousMonth(Iterable<DateTime?> dates) {
  final now = DateTime.now();
  final previous = DateTime(now.year, now.month - 1);
  return dates.where((date) {
    if (date == null) {
      return false;
    }
    final local = date.toLocal();
    return local.year == previous.year && local.month == previous.month;
  }).length;
}
class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.item});

  final _MetricItem item;

  @override
  Widget build(BuildContext context) {
    final color = _toneColor(context, item.tone);
    final percentageColor = _toneColor(context, item.percentageTone ?? item.tone);
    return _HoverLiftPanel(
      borderRadius: AppRadius.xLarge,
      child: _Panel(
        padding: const EdgeInsetsDirectional.fromSTEB(12, 10, 12, 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: AppRadius.medium,
                  ),
                  child: Icon(item.icon, size: 16, color: color),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppColors.textSecondaryColor(context),
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: item.value.toDouble()),
                    duration: const Duration(milliseconds: 140),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) {
                      return Text(
                        value.round().toString(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.w800,
                              height: 1,
                              color: AppColors.textPrimaryColor(context),
                            ),
                      );
                    },
                  ),
                ),
                if (item.percentageLabel != null &&
                    item.percentageLabel!.trim().isNotEmpty)
                  Container(
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: percentageColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          item.percentageIsTrend
                              ? (item.percentageTone == AppStatusTone.error
                                  ? Icons.trending_down_rounded
                                  : Icons.trending_up_rounded)
                              : Icons.pie_chart_outline_rounded,
                          size: 14,
                          color: percentageColor,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          item.percentageLabel!,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: percentageColor,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            if (item.percentageLabel != null &&
                item.percentageLabel!.trim().isNotEmpty &&
                item.percentageCaption != null &&
                item.percentageCaption!.trim().isNotEmpty) ...[
              const SizedBox(height: 5),
              Text(
                item.percentageCaption!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textSecondaryColor(context),
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
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
      duration: const Duration(milliseconds: 420),
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
            duration: const Duration(milliseconds: 340),
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
            duration: const Duration(milliseconds: 360),
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
    final role = authState.protectedCompanySession?.profile.role;
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
    final canCreateAppointment =
        authState.companyMetadata.isFeatureEnabled(CompanyFeature.appointments) &&
        role != null &&
        PermissionService.can(role, AppPermission.createAppointment);

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
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            label: l.newAppointment,
            icon: Icons.event_available_outlined,
            variant: AppButtonVariant.secondary,
            onPressed: canCreateAppointment
                ? () => context.go(RouteNames.appointmentsCreate)
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


Stream<List<UserProfile>> _watchDashboardActiveUsers(String companyId) {
  final cleanCompanyId = companyId.trim();
  if (cleanCompanyId.isEmpty) {
    return Stream<List<UserProfile>>.value(const <UserProfile>[]);
  }
  final repository = UserProfileRepositoryImpl(
    remoteDataSource: FirestoreUserProfileRemoteDataSource(),
  );
  return WatchActiveUsersUseCase(repository)(companyId: cleanCompanyId);
}

class _DashboardData {
  const _DashboardData({
    required this.leads,
    required this.properties,
    required this.clients,
    required this.tasks,
    required this.appointments,
    required this.deals,
    required this.activeUsers,
    required this.leadCounts,
    required this.propertyCounts,
    required this.taskCounts,
    required this.appointmentCounts,
    required this.dealCounts,
  });

  final List<Lead> leads;
  final List<Property> properties;
  final List<Client> clients;
  final List<CrmTask> tasks;
  final List<Appointment> appointments;
  final List<Deal> deals;
  final List<UserProfile> activeUsers;
  final ModuleKpiCounts leadCounts;
  final ModuleKpiCounts propertyCounts;
  final ModuleKpiCounts taskCounts;
  final ModuleKpiCounts appointmentCounts;
  final ModuleKpiCounts dealCounts;

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

  List<Lead> get unassignedLeads => leads.where((lead) {
        return !lead.isArchived && lead.assignedTo.trim().isEmpty;
      }).toList();

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
  const _MetricItem(
    this.label,
    this.value,
    this.tone,
    this.icon, {
    this.percentageLabel,
    this.percentageCaption,
    this.percentageTone,
    this.percentageIsTrend = false,
  });

  final String label;
  final int value;
  final AppStatusTone tone;
  final IconData icon;
  final String? percentageLabel;
  final String? percentageCaption;
  final AppStatusTone? percentageTone;
  final bool percentageIsTrend;
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

String _metricValueLabel(BuildContext context, DashboardKpiMetric metric) {
  if (metric.type == DashboardKpiType.expectedPipelineValue ||
      metric.type == DashboardKpiType.expectedCommission) {
    return _formatMoney(context, metric.value);
  }
  final value = metric.valueLabel.trim();
  return value.isNotEmpty ? value : metric.value.round().toString();
}

String _kpiTitle(BuildContext context, DashboardKpiType type) {
  final l = AppLocalizations.of(context)!;
  return switch (type) {
    DashboardKpiType.activeLeads => l.dashboardKpiActiveLeads,
    DashboardKpiType.newLeadsToday => l.newLeads,
    DashboardKpiType.hotOpportunities => l.dashboardKpiHotOpportunities,
    DashboardKpiType.dueTodayFollowUps => l.dashboardKpiDueTodayFollowUps,
    DashboardKpiType.overdueFollowUps => l.dashboardOverdueFollowUps,
    DashboardKpiType.overdueActions => l.dashboardKpiOverdueActions,
    DashboardKpiType.appointmentsToday => l.dashboardKpiAppointmentsToday,
    DashboardKpiType.missedAppointments => l.missedAppointments,
    DashboardKpiType.overdueTasks => l.dashboardOverdueTasks,
    DashboardKpiType.pipelineDeals => l.dashboardKpiDealsPipeline,
    DashboardKpiType.expectedPipelineValue => l.dashboardKpiExpectedPipeline,
    DashboardKpiType.expectedCommission => l.commissionTotal,
    DashboardKpiType.wonDealsThisMonth => l.wonDealsThisMonth,
    DashboardKpiType.stuckDeals => l.dashboardDealRisks,
    DashboardKpiType.unassignedLeads => l.dashboardUnassignedLeads,
    DashboardKpiType.teamWorkload => l.workload,
    DashboardKpiType.activeProperties => l.dashboardKpiActiveListings,
  };
}

String _kpiPeriod(BuildContext context, DashboardKpiType type) {
  final l = AppLocalizations.of(context)!;
  return switch (type) {
    DashboardKpiType.newLeadsToday ||
    DashboardKpiType.dueTodayFollowUps ||
    DashboardKpiType.appointmentsToday =>
      l.dashboardPeriodToday,
    DashboardKpiType.expectedPipelineValue ||
    DashboardKpiType.expectedCommission ||
    DashboardKpiType.wonDealsThisMonth =>
      l.dashboardPeriodThisMonth,
    _ => l.dashboardPeriodCurrentScope,
  };
}

IconData _kpiIcon(DashboardKpiType type) {
  return switch (type) {
    DashboardKpiType.activeLeads => Icons.groups_2_outlined,
    DashboardKpiType.newLeadsToday => Icons.person_add_alt_outlined,
    DashboardKpiType.hotOpportunities => Icons.local_fire_department_outlined,
    DashboardKpiType.dueTodayFollowUps => Icons.event_available_outlined,
    DashboardKpiType.overdueFollowUps => Icons.phone_missed_outlined,
    DashboardKpiType.overdueActions => Icons.notification_important_outlined,
    DashboardKpiType.appointmentsToday => Icons.calendar_month_outlined,
    DashboardKpiType.missedAppointments => Icons.event_busy_outlined,
    DashboardKpiType.overdueTasks => Icons.assignment_late_outlined,
    DashboardKpiType.pipelineDeals => Icons.handshake_outlined,
    DashboardKpiType.expectedPipelineValue => Icons.payments_outlined,
    DashboardKpiType.expectedCommission => Icons.price_check_outlined,
    DashboardKpiType.wonDealsThisMonth => Icons.verified_outlined,
    DashboardKpiType.stuckDeals => Icons.hourglass_bottom_outlined,
    DashboardKpiType.unassignedLeads => Icons.person_search_outlined,
    DashboardKpiType.teamWorkload => Icons.groups_outlined,
    DashboardKpiType.activeProperties => Icons.apartment_outlined,
  };
}

Color _kpiColor(BuildContext context, DashboardKpiType type) {
  return switch (type) {
    DashboardKpiType.activeLeads => AppColors.infoColor(context),
    DashboardKpiType.newLeadsToday => AppColors.primaryColor(context),
    DashboardKpiType.hotOpportunities => AppColors.errorColor(context),
    DashboardKpiType.dueTodayFollowUps => AppColors.warningColor(context),
    DashboardKpiType.overdueFollowUps => AppColors.errorColor(context),
    DashboardKpiType.overdueActions => AppColors.errorColor(context),
    DashboardKpiType.appointmentsToday => AppColors.primaryColor(context),
    DashboardKpiType.missedAppointments => AppColors.errorColor(context),
    DashboardKpiType.overdueTasks => AppColors.errorColor(context),
    DashboardKpiType.pipelineDeals => AppColors.warningColor(context),
    DashboardKpiType.expectedPipelineValue => AppColors.successColor(context),
    DashboardKpiType.expectedCommission => AppColors.successColor(context),
    DashboardKpiType.wonDealsThisMonth => AppColors.successColor(context),
    DashboardKpiType.stuckDeals => AppColors.warningColor(context),
    DashboardKpiType.unassignedLeads => AppColors.warningColor(context),
    DashboardKpiType.teamWorkload => AppColors.infoColor(context),
    DashboardKpiType.activeProperties => AppColors.successColor(context),
  };
}

String _barLabel(BuildContext context, String key) {
  final l = AppLocalizations.of(context)!;
  return switch (key) {
    'completed' => l.completed,
    'dueToday' => l.dueToday,
    'overdue' => l.overdue,
    'booked' => l.appointmentStatusScheduled,
    'missed' => l.appointmentStatusMissed,
    _ => key,
  };
}

Color _barColor(BuildContext context, String key) {
  return switch (key) {
    'completed' => AppColors.successColor(context),
    'dueToday' || 'booked' => AppColors.primaryColor(context),
    'overdue' || 'missed' => AppColors.errorColor(context),
    _ => AppColors.infoColor(context),
  };
}

Color _sourceColor(BuildContext context, int index) {
  final colors = [
    AppColors.infoColor(context),
    AppColors.successColor(context),
    AppColors.warningColor(context),
    AppColors.errorColor(context),
    AppColors.primaryColor(context),
  ];
  return colors[index % colors.length];
}

String _leadSourceLabel(AppLocalizations l, LeadSource source) {
  return switch (source) {
    LeadSource.facebook => l.facebook,
    LeadSource.website => l.website,
    LeadSource.phoneCall => l.phoneCall,
    LeadSource.whatsapp => l.whatsapp,
    LeadSource.referral => l.referral,
    LeadSource.walkIn => l.walkIn,
    LeadSource.other => l.other,
  };
}

int _todayCount(DashboardAnalytics analytics, DashboardTodayModule module) {
  return analytics.todayItems.where((item) => item.module == module).length;
}

IconData _todayIcon(DashboardTodayModule module) {
  return switch (module) {
    DashboardTodayModule.appointment => Icons.event_available_outlined,
    DashboardTodayModule.followUp => Icons.phone_callback_outlined,
    DashboardTodayModule.task => Icons.task_alt_outlined,
    DashboardTodayModule.deal => Icons.handshake_outlined,
  };
}

String? _todayRoute(DashboardTodayItem item) {
  return switch (item.module) {
    DashboardTodayModule.appointment => RouteNames.appointmentEdit(item.recordId),
    DashboardTodayModule.followUp => RouteNames.leadDetails(item.recordId),
    DashboardTodayModule.task => RouteNames.taskEdit(item.recordId),
    DashboardTodayModule.deal => RouteNames.dealDetails(item.recordId),
  };
}

String _todaySubtitle(BuildContext context, DashboardTodayItem item) {
  final l = AppLocalizations.of(context)!;
  final time = item.dueAt == null
      ? ''
      : intl.DateFormat.jm(l.localeName).format(item.dueAt!.toLocal());
  final urgency = switch (item.urgency) {
    DashboardTodayUrgency.overdue => l.overdue,
    DashboardTodayUrgency.dueToday => l.dueToday,
    DashboardTodayUrgency.normal => l.today,
  };
  final subtitle = item.subtitle.trim();
  return [
    if (time.isNotEmpty) time,
    urgency,
    if (subtitle.isNotEmpty) subtitle,
  ].join(' - ');
}

Color _urgencyColor(BuildContext context, DashboardTodayUrgency urgency) {
  return switch (urgency) {
    DashboardTodayUrgency.overdue => AppColors.errorColor(context),
    DashboardTodayUrgency.dueToday => AppColors.warningColor(context),
    DashboardTodayUrgency.normal => AppColors.infoColor(context),
  };
}


String _formatDate(BuildContext context, DateTime value) {
  final localeName = AppLocalizations.of(context)!.localeName;
  return intl.DateFormat.yMMMd(localeName).format(value.toLocal());
}

String _formatTrialEndDate(BuildContext context, DateTime value) {
  final localeName = AppLocalizations.of(context)!.localeName;
  return intl.DateFormat.yMMMd(localeName).add_jm().format(value.toLocal());
}

String _formatTrialRemaining(AppLocalizations l, Duration remaining) {
  final isArabic = l.localeName.toLowerCase().startsWith('ar');
  if (remaining.inSeconds <= 0) {
    return isArabic ? '0 دقيقة' : '0 min';
  }
  if (remaining.inHours < 1) {
    final minutes = (remaining.inSeconds / 60).ceil().clamp(1, 60).toInt();
    return isArabic ? '$minutes دقيقة' : '$minutes min';
  }
  if (remaining.inDays < 1) {
    final hours = (remaining.inMinutes / 60).ceil().clamp(1, 24).toInt();
    return isArabic ? '$hours ساعة' : '$hours hr';
  }
  final days = (remaining.inHours / 24).ceil();
  return isArabic ? '$days يوم' : '$days d';
}

String _relativeTimeLabel(BuildContext context, DateTime time) {
  final l = AppLocalizations.of(context)!;
  final now = DateTime.now();
  final local = time.toLocal();
  final localTime = local.isAfter(now.add(const Duration(seconds: 45))) ? now : local;
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

  final role = authState.protectedCompanySession?.profile.role;
  return role == UserRole.admin || role == UserRole.manager;
}

bool _canRequestDashboardActiveUsers(_DashboardWatchScopeKey watchScopeKey) {
  if (watchScopeKey.platformPreview) {
    return true;
  }
  return watchScopeKey.role == UserRole.admin ||
      watchScopeKey.role == UserRole.manager ||
      watchScopeKey.role == UserRole.salesAgent ||
      watchScopeKey.role == UserRole.marketing;
}

bool _canViewAppointments(
  AuthState authState, {
  bool platformPreview = false,
}) {
  if (platformPreview) {
    return false;
  }
  final role = authState.protectedCompanySession?.profile.role;
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

  final role = authState.protectedCompanySession?.profile.role;
  return role == UserRole.admin;
}

bool _assignedOnlyScope(UserRole? role) {
  return role == UserRole.salesAgent ||
      role == UserRole.marketing ||
      role == UserRole.viewer;
}
