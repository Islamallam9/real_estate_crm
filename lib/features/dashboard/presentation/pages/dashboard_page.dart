import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/role_constants.dart';
import '../../../../core/permissions/app_permission.dart';
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
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../clients/domain/entities/client.dart';
import '../../../clients/presentation/cubit/clients_cubit.dart';
import '../../../clients/presentation/cubit/clients_state.dart';
import '../../../clients/presentation/widgets/clients_scope.dart';
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
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

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
              authState.userProfile?.companyId ?? authState.user?.companyId ?? '';
          if (companyId.isEmpty) {
            return AppErrorView(message: l.missingCompanyProfile);
          }

          return LeadsScope(
            child: PropertiesScope(
              child: ClientsScope(
                child: TasksScope(
                  child: _DashboardContent(
                    companyId: companyId,
                    authState: authState,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DashboardContent extends StatefulWidget {
  const _DashboardContent({
    required this.companyId,
    required this.authState,
  });

  final String companyId;
  final AuthState authState;

  @override
  State<_DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<_DashboardContent> {
  @override
  void initState() {
    super.initState();
    final role = widget.authState.userProfile?.role ?? widget.authState.user?.role;
    final uid = widget.authState.user?.uid ?? '';
    final assignedTo = role == UserRole.salesAgent ? uid : null;

    context.read<LeadsCubit>().watchLeads(
          companyId: widget.companyId,
          assignedTo: assignedTo,
        );
    context.read<PropertiesCubit>().watchProperties(companyId: widget.companyId);
    context.read<ClientsCubit>().watchClients(
          companyId: widget.companyId,
          assignedTo: assignedTo,
        );
    context.read<TasksCubit>().watchTasks(
          companyId: widget.companyId,
          assignedTo: assignedTo,
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
                    final data = _DashboardData(
                      leads: leadsState.leads,
                      properties: propertiesState.properties,
                      clients: clientsState.clients,
                      tasks: tasksState.tasks,
                    );

                    return _DashboardView(
                      data: data,
                      authState: widget.authState,
                      isLoading: leadsState.status == LeadsStatus.loading &&
                              leadsState.leads.isEmpty ||
                          propertiesState.status == PropertiesStatus.loading &&
                              propertiesState.properties.isEmpty ||
                          clientsState.status == ClientsStatus.loading &&
                              clientsState.clients.isEmpty ||
                          tasksState.status == TasksStatus.loading &&
                              tasksState.tasks.isEmpty,
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

class _DashboardView extends StatelessWidget {
  const _DashboardView({
    required this.data,
    required this.authState,
    required this.isLoading,
  });

  final _DashboardData data;
  final AuthState authState;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final copy = _DashboardCopy.of(context);

    if (isLoading) {
      return const AppLoading();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 860;

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _WelcomePanel(authState: authState),
              const SizedBox(height: AppSpacing.md),
              _SummaryGrid(data: data),
              const SizedBox(height: AppSpacing.md),
              if (compact) ...[
                _AnalyticsPanel(data: data),
                const SizedBox(height: AppSpacing.md),
                _ActionPanel(authState: authState),
              ] else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: _AnalyticsPanel(data: data)),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(flex: 2, child: _ActionPanel(authState: authState)),
                  ],
                ),
              const SizedBox(height: AppSpacing.md),
              if (compact) ...[
                _LeadSection(
                  title: copy.todaysFollowUps,
                  leads: data.todaysFollowUps,
                  emptyMessage: l.noLeads,
                ),
                const SizedBox(height: AppSpacing.md),
                _TaskSection(
                  title: copy.overdueTasks,
                  tasks: data.overdueTasks,
                  emptyMessage: l.noTasksYet,
                ),
                const SizedBox(height: AppSpacing.md),
                _LeadSection(
                  title: copy.unassignedLeads,
                  leads: data.unassignedLeads,
                  emptyMessage: l.noLeads,
                ),
              ] else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _LeadSection(
                        title: copy.todaysFollowUps,
                        leads: data.todaysFollowUps,
                        emptyMessage: l.noLeads,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _TaskSection(
                        title: copy.overdueTasks,
                        tasks: data.overdueTasks,
                        emptyMessage: l.noTasksYet,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _LeadSection(
                        title: copy.unassignedLeads,
                        leads: data.unassignedLeads,
                        emptyMessage: l.noLeads,
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: AppSpacing.md),
              _LeadSection(
                title: copy.recentlyUpdatedLeads,
                leads: data.recentLeads,
                emptyMessage: l.noLeads,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _WelcomePanel extends StatelessWidget {
  const _WelcomePanel({required this.authState});

  final AuthState authState;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final copy = _DashboardCopy.of(context);
    final name = (authState.userProfile?.fullName ?? authState.user?.fullName ?? '')
        .trim();
    final displayName = name.isEmpty ? l.crmUser : name;
    final now = DateTime.now();
    final date = MaterialLocalizations.of(context).formatFullDate(now);

    return _Panel(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  copy.greeting(now),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
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
                  date,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondaryColor(context),
                      ),
                ),
              ],
            ),
          ),
          Container(
            width: 54,
            height: 54,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primaryColor(context).withValues(alpha: 0.12),
              borderRadius: AppRadius.xLarge,
            ),
            child: Icon(
              Icons.real_estate_agent_outlined,
              color: AppColors.primaryColor(context),
              size: 28,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({required this.data});

  final _DashboardData data;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final copy = _DashboardCopy.of(context);
    final cards = [
      _MetricItem(l.totalLeads, data.leads.length, AppStatusTone.info),
      _MetricItem(l.newLeads, data.newLeads.length, AppStatusTone.info),
      _MetricItem(copy.overdueFollowUps, data.overdueFollowUps.length,
          AppStatusTone.error),
      _MetricItem(copy.upcomingFollowUps, data.upcomingFollowUps.length,
          AppStatusTone.info),
      _MetricItem(copy.availableProperties, data.availableProperties.length,
          AppStatusTone.success),
      _MetricItem(l.clients, data.clients.length, AppStatusTone.neutral),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 980
            ? 6
            : constraints.maxWidth >= 680
                ? 3
                : 2;
        final width = (constraints.maxWidth - (columns - 1) * AppSpacing.sm) /
            columns;

        return Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final card in cards)
              SizedBox(width: width, child: _MetricCard(item: card)),
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
    return _Panel(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.textSecondaryColor(context),
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: AppSpacing.xs),
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: item.value.toDouble()),
                  duration: const Duration(milliseconds: 220),
                  builder: (context, value, _) {
                    return Text(
                      value.round().toString(),
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
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
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: AppRadius.large,
            ),
            child: Icon(Icons.trending_up, size: 18, color: color),
          ),
        ],
      ),
    );
  }
}

class _AnalyticsPanel extends StatelessWidget {
  const _AnalyticsPanel({required this.data});

  final _DashboardData data;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final copy = _DashboardCopy.of(context);

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionTitle(title: copy.visualAnalytics),
          const SizedBox(height: AppSpacing.md),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 900
                  ? 3
                  : constraints.maxWidth >= 600
                      ? 2
                      : 1;
              final cardWidth =
                  (constraints.maxWidth - (columns - 1) * AppSpacing.md) /
                      columns;

              return Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.md,
                children: [
                  SizedBox(
                    width: cardWidth,
                    child: _DonutChartCard(
                      title: copy.leadStatusDistribution,
                      segments: [
                        _ChartSegment(l.newLead, data.newLeads.length,
                            AppColors.infoColor(context)),
                        _ChartSegment(copy.active, data.activeLeads.length,
                            AppColors.successColor(context)),
                        _ChartSegment(l.won, data.wonLeads.length,
                            AppColors.secondary),
                        _ChartSegment(l.lost, data.lostLeads.length,
                            AppColors.errorColor(context)),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: _DonutChartCard(
                      title: copy.tasksDueBreakdown,
                      segments: [
                        _ChartSegment(l.overdue, data.overdueTasks.length,
                            AppColors.errorColor(context)),
                        _ChartSegment(l.dueToday, data.todayTasks.length,
                            AppColors.warningColor(context)),
                        _ChartSegment(l.upcoming, data.upcomingTasks.length,
                            AppColors.infoColor(context)),
                        _ChartSegment(l.completed, data.completedTasks.length,
                            AppColors.successColor(context)),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: _DonutChartCard(
                      title: copy.propertyStatusDistribution,
                      segments: [
                        _ChartSegment(copy.availableProperties,
                            data.availableProperties.length,
                            AppColors.successColor(context)),
                        _ChartSegment(copy.inactive,
                            data.inactiveProperties.length,
                            AppColors.textSecondaryColor(context)),
                        _ChartSegment(copy.reservedOrClosed,
                            data.reservedOrClosedProperties.length,
                            AppColors.warningColor(context)),
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

class _DonutChartCard extends StatelessWidget {
  const _DonutChartCard({
    required this.title,
    required this.segments,
  });

  final String title;
  final List<_ChartSegment> segments;

  @override
  Widget build(BuildContext context) {
    final total = segments.fold<int>(0, (sum, item) => sum + item.value);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.inputSurface(context),
        border: Border.all(color: AppColors.borderColor(context)),
        borderRadius: AppRadius.large,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              CustomPaint(
                size: const Size.square(76),
                painter: _DonutPainter(segments: segments),
                child: SizedBox.square(
                  dimension: 76,
                  child: Center(
                    child: Text(
                      total.toString(),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  children: [
                    for (final segment in segments)
                      _LegendRow(segment: segment),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
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
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  const _DonutPainter({required this.segments});

  final List<_ChartSegment> segments;

  @override
  void paint(Canvas canvas, Size size) {
    final total = segments.fold<int>(0, (sum, segment) => sum + segment.value);
    final rect = Offset.zero & size;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    if (total == 0) {
      stroke.color = const Color(0xFFDCE3EC);
      canvas.drawArc(rect.deflate(8), -math.pi / 2, math.pi * 2, false, stroke);
      return;
    }

    var start = -math.pi / 2;
    for (final segment in segments.where((segment) => segment.value > 0)) {
      final sweep = math.pi * 2 * segment.value / total;
      stroke.color = segment.color;
      canvas.drawArc(rect.deflate(8), start, sweep, false, stroke);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) {
    return oldDelegate.segments != segments;
  }
}

class _LeadSection extends StatelessWidget {
  const _LeadSection({
    required this.title,
    required this.leads,
    required this.emptyMessage,
  });

  final String title;
  final List<Lead> leads;
  final String emptyMessage;

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
              constraints: const BoxConstraints(maxHeight: 286),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    for (final lead in leads.take(6))
                      _DashboardListTile(
                        title: lead.fullName,
                        subtitle:
                            lead.phone.isNotEmpty ? lead.phone : lead.email,
                        badge: _leadStatusLabel(context, lead.status),
                        tone: _leadStatusTone(lead.status),
                        onTap: () => context.go(RouteNames.leadDetails(lead.id)),
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

class _TaskSection extends StatelessWidget {
  const _TaskSection({
    required this.title,
    required this.tasks,
    required this.emptyMessage,
  });

  final String title;
  final List<CrmTask> tasks;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionTitle(title: title),
          const SizedBox(height: AppSpacing.sm),
          if (tasks.isEmpty)
            _CompactEmpty(message: emptyMessage)
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 286),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    for (final task in tasks.take(6))
                      _DashboardListTile(
                        title: task.title,
                        subtitle: _taskSubtitle(context, task),
                        badge: _taskDueLabel(context, task),
                        tone: _taskDueTone(task),
                        onTap: () => context.go(RouteNames.tasks),
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

class _CompactEmpty extends StatelessWidget {
  const _CompactEmpty({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
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
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String badge;
  final AppStatusTone tone;
  final VoidCallback onTap;

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
        role != null && PermissionService.can(role, AppPermission.createLead);
    final canCreateProperty =
        role != null && PermissionService.can(role, AppPermission.createProperty);
    final canCreateClient =
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
            onPressed: canCreateLead ? () => context.go(RouteNames.leadsCreate) : null,
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            label: l.createClient,
            icon: Icons.group_add_outlined,
            variant: AppButtonVariant.secondary,
            onPressed:
                canCreateClient ? () => context.go(RouteNames.clientsCreate) : null,
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
    this.padding = const EdgeInsets.all(AppSpacing.md),
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
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
    );
  }
}

class _DashboardData {
  const _DashboardData({
    required this.leads,
    required this.properties,
    required this.clients,
    required this.tasks,
  });

  final List<Lead> leads;
  final List<Property> properties;
  final List<Client> clients;
  final List<CrmTask> tasks;

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
    final sorted = [...leads]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return sorted;
  }

  List<Property> get availableProperties => properties
      .where((property) => property.status == PropertyStatus.available)
      .toList();

  List<Property> get inactiveProperties => properties
      .where((property) => property.status == PropertyStatus.inactive)
      .toList();

  List<Property> get reservedOrClosedProperties => properties
      .where((property) => property.status != PropertyStatus.available &&
          property.status != PropertyStatus.inactive)
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
}

class _MetricItem {
  const _MetricItem(this.label, this.value, this.tone);

  final String label;
  final int value;
  final AppStatusTone tone;
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
  String get propertyStatusDistribution => l.dashboardPropertyStatusDistribution;
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
    LeadStatus.negotiation || LeadStatus.visitScheduled => AppStatusTone.warning,
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

Color _toneColor(BuildContext context, AppStatusTone tone) {
  return switch (tone) {
    AppStatusTone.success => AppColors.successColor(context),
    AppStatusTone.warning => AppColors.warningColor(context),
    AppStatusTone.error => AppColors.errorColor(context),
    AppStatusTone.info => AppColors.infoColor(context),
    AppStatusTone.neutral => AppColors.primaryColor(context),
  };
}
