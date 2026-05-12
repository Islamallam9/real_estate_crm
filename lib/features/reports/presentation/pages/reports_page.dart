import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/widgets/app_search_field.dart';
import '../../../../core/constants/role_constants.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/permissions/app_permission.dart';
import '../../../../core/permissions/permission_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
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
import '../../../properties/presentation/widgets/property_labels.dart';
import '../../../tasks/domain/entities/crm_task.dart';
import '../../../tasks/presentation/cubit/tasks_cubit.dart';
import '../../../tasks/presentation/cubit/tasks_state.dart';
import '../../../tasks/presentation/widgets/tasks_scope.dart';
import '../../../users/data/datasources/user_profile_remote_data_source.dart';
import '../../../users/data/repositories/user_profile_repository_impl.dart';
import '../../../users/domain/entities/user_profile.dart';
import '../../../users/domain/usecases/watch_active_users_usecase.dart';

enum _ReportPeriod { allTime, today, thisWeek, thisMonth }

class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return CrmAppShell(
      selectedItem: CrmNavigationItem.reports,
      title: l.reports,
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          if (authState.status == AuthStatus.initial ||
              authState.status == AuthStatus.loading) {
            return const AppLoading();
          }

          final companyId =
              authState.userProfile?.companyId ?? authState.user?.companyId ?? '';
          final role = authState.userProfile?.role ?? authState.user?.role;
          final uid = authState.user?.uid ?? '';
          if (companyId.isEmpty || role == null || uid.isEmpty) {
            return AppErrorView(message: l.missingCompanyProfile);
          }
          if (!PermissionService.can(role, AppPermission.viewReports)) {
            return AppErrorView(message: l.permissionDenied);
          }

          return LeadsScope(
            child: PropertiesScope(
              child: ClientsScope(
                child: TasksScope(
                  child: DealsScope(
                    child: _ReportsContent(
                      companyId: companyId,
                      role: role,
                      currentUserId: uid,
                    ),
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

class _ReportsContent extends StatefulWidget {
  const _ReportsContent({
    required this.companyId,
    required this.role,
    required this.currentUserId,
  });

  final String companyId;
  final UserRole role;
  final String currentUserId;

  @override
  State<_ReportsContent> createState() => _ReportsContentState();
}

class _ReportsContentState extends State<_ReportsContent> {
  _ReportPeriod _period = _ReportPeriod.allTime;
  String _assignedTo = '';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  bool get _canFilterAssignee =>
      widget.role == UserRole.admin || widget.role == UserRole.manager;

  @override
  void initState() {
    super.initState();
    _watchAll();
  }
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _watchAll() {
    final assignedTo = widget.role == UserRole.salesAgent
        ? widget.currentUserId
        : null;
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
    context.read<DealsCubit>().watchDeals(
          companyId: widget.companyId,
          role: widget.role,
          currentUserId: widget.currentUserId,
        );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<UserProfile>>(
      stream: _canFilterAssignee ? _watchActiveUsers(widget.companyId) : null,
      builder: (context, usersSnapshot) {
        final users = usersSnapshot.data ?? const <UserProfile>[];
        return BlocBuilder<LeadsCubit, LeadsState>(
          builder: (context, leadsState) {
            return BlocBuilder<PropertiesCubit, PropertiesState>(
              builder: (context, propertiesState) {
                return BlocBuilder<ClientsCubit, ClientsState>(
                  builder: (context, clientsState) {
                    return BlocBuilder<TasksCubit, TasksState>(
                      builder: (context, tasksState) {
                        return BlocBuilder<DealsCubit, DealsState>(
                          builder: (context, dealsState) {
                            final isLoading =
                                leadsState.status == LeadsStatus.loading &&
                                        leadsState.leads.isEmpty ||
                                    propertiesState.status ==
                                            PropertiesStatus.loading &&
                                        propertiesState.properties.isEmpty ||
                                    clientsState.status ==
                                            ClientsStatus.loading &&
                                        clientsState.clients.isEmpty ||
                                    tasksState.status == TasksStatus.loading &&
                                        tasksState.tasks.isEmpty ||
                                    dealsState.status == DealsStatus.loading &&
                                        dealsState.deals.isEmpty;
                            final hasFailure =
                                leadsState.status == LeadsStatus.failure &&
                                        leadsState.leads.isEmpty ||
                                    propertiesState.status ==
                                            PropertiesStatus.failure &&
                                        propertiesState.properties.isEmpty ||
                                    clientsState.status ==
                                            ClientsStatus.failure &&
                                        clientsState.clients.isEmpty ||
                                    tasksState.status == TasksStatus.failure &&
                                        tasksState.tasks.isEmpty ||
                                    dealsState.status == DealsStatus.failure &&
                                        dealsState.deals.isEmpty;
                            final message = leadsState.message ??
                                propertiesState.message ??
                                clientsState.message ??
                                tasksState.message ??
                                dealsState.message;

                            if (isLoading) {
                              return const AppLoading();
                            }
                            if (hasFailure) {
                              final l = AppLocalizations.of(context)!;
                              return AppErrorView(
                                message: message == null
                                    ? l.unableToLoadReports
                                    : localizeErrorMessage(l, message),
                                onRetry: _watchAll,
                              );
                            }

                            final data = _ReportsData(
                              leads: leadsState.leads,
                              properties: propertiesState.properties,
                              clients: clientsState.clients,
                              tasks: tasksState.tasks,
                              deals: dealsState.deals,
                              period: _period,
                              assignedTo: _assignedTo,
                              searchQuery: _searchQuery,
                            );

                            if (!data.hasAnyData) {
                              return AppEmptyState(
                                title: AppLocalizations.of(context)!.noReportData,
                                message:
                                    AppLocalizations.of(context)!.reportsOverview,
                                icon: Icons.bar_chart_outlined,
                              );
                            }

                            return _ReportsView(
                              data: data,
                              users: users,
                              canFilterAssignee: _canFilterAssignee,
                              period: _period,
                              assignedTo: _assignedTo,
                              searchController: _searchController,
                              searchQuery: _searchQuery,
                              onPeriodChanged: (period) {
                                setState(() => _period = period);
                              },
                              onAssignedToChanged: (value) {
                                setState(() => _assignedTo = value);
                              },
                              onSearchChanged: (value) {
                                setState(() => _searchQuery = value);
                              },
                              onClearFilters: () {
                                setState(() {
                                  _period = _ReportPeriod.allTime;
                                  _assignedTo = '';
                                  _searchQuery = '';
                                  _searchController.clear();
                                });
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

class _ReportsView extends StatelessWidget {
  const _ReportsView({
    required this.data,
    required this.users,
    required this.canFilterAssignee,
    required this.period,
    required this.assignedTo,
    required this.onPeriodChanged,
    required this.onAssignedToChanged,
    required this.onClearFilters,
    required this.searchController,
    required this.searchQuery,
    required this.onSearchChanged,
  });

  final TextEditingController searchController;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final _ReportsData data;
  final List<UserProfile> users;
  final bool canFilterAssignee;
  final _ReportPeriod period;
  final String assignedTo;
  final ValueChanged<_ReportPeriod> onPeriodChanged;
  final ValueChanged<String> onAssignedToChanged;
  final VoidCallback onClearFilters;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final hasFilters = period != _ReportPeriod.allTime ||
        assignedTo.trim().isNotEmpty ||
        searchQuery.trim().isNotEmpty;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _ReportHeader(),
          const SizedBox(height: AppSpacing.md),
          _ReportsSearchFilterRow(
            users: users,
            canFilterAssignee: canFilterAssignee,
            period: period,
            assignedTo: assignedTo,
            hasFilters: hasFilters,
            searchController: searchController,
            searchQuery: searchQuery,
            onSearchChanged: onSearchChanged,
            onPeriodChanged: onPeriodChanged,
            onAssignedToChanged: onAssignedToChanged,
            onClearFilters: onClearFilters,
          ),
          const SizedBox(height: AppSpacing.md),
          _ExecutiveSummary(data: data),
          const SizedBox(height: AppSpacing.md),
          _ReportSection(
            title: l.leadsReport,
            children: [
              _DonutReportCard(
                title: l.leadsByStatus,
                segments: [
                  for (final status in LeadStatus.values)
                    _ChartSegment(
                      _leadStatusLabel(l, status),
                      data.leadsByStatus(status).length,
                      _leadStatusColor(context, status),
                    ),
                ],
              ),
              _BarReportCard(
                title: l.leadsBySource,
                rows: [
                  for (final source in LeadSource.values)
                    _BarRow(
                      label: _leadSourceLabel(l, source),
                      value: data.leadsBySource(source).length,
                      color: AppColors.primaryColor(context),
                    ),
                ],
              ),
              _BarReportCard(
                title: l.leadsByPriority,
                rows: [
                  for (final priority in LeadPriority.values)
                    _BarRow(
                      label: _leadPriorityLabel(l, priority),
                      value: data.leadsByPriority(priority).length,
                      color: _leadPriorityColor(context, priority),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _ReportSection(
            title: l.dealsReport,
            children: [
              _DonutReportCard(
                title: l.dealPipeline,
                segments: [
                  _ChartSegment(
                    l.openDeals,
                    data.openDeals.length,
                    AppColors.warningColor(context),
                  ),
                  _ChartSegment(
                    l.wonDeals,
                    data.wonDeals.length,
                    AppColors.successColor(context),
                  ),
                  _ChartSegment(
                    l.lostDeals,
                    data.lostDeals.length,
                    AppColors.errorColor(context),
                  ),
                ],
              ),
              _BarReportCard(
                title: l.dealsByStage,
                rows: [
                  for (final stage in DealStage.values)
                    _BarRow(
                      label: dealStageLabel(l, stage),
                      value: data.dealsByStage(stage).length,
                      amount: data.dealValueByStage(stage),
                      color: _dealStageColor(context, stage),
                    ),
                ],
              ),
              _ValueReportCard(
                title: l.pipelineValue,
                values: [
                  _ValueLine(l.expectedValueTotal, data.expectedValueTotal),
                  _ValueLine(l.commissionTotal, data.commissionTotal),
                  _ValueLine(l.wonValue, data.wonValue),
                  _ValueLine(l.lostValue, data.lostValue),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _ReportSection(
            title: l.tasksReport,
            children: [
              _DonutReportCard(
                title: l.taskStatusDistribution,
                segments: [
                  for (final status in TaskStatus.values)
                    _ChartSegment(
                      _taskStatusLabel(l, status),
                      data.tasksByStatus(status).length,
                      _taskStatusColor(context, status),
                    ),
                ],
              ),
              _ProgressReportCard(
                title: l.completionRate,
                value: data.completionRate,
                color: AppColors.successColor(context),
              ),
              _AttentionReportCard(tasks: data.attentionTasks),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _ReportSection(
            title: l.propertiesReport,
            children: [
              _DonutReportCard(
                title: l.propertiesByStatus,
                segments: [
                  for (final status in PropertyStatus.values)
                    _ChartSegment(
                      propertyStatusLabel(l, status),
                      data.propertiesByStatus(status).length,
                      _propertyStatusColor(context, status),
                    ),
                ],
              ),
              _BarReportCard(
                title: l.propertiesByType,
                rows: [
                  for (final type in PropertyType.values)
                    _BarRow(
                      label: propertyTypeLabel(l, type),
                      value: data.propertiesByType(type).length,
                      color: AppColors.primaryColor(context),
                    ),
                ],
              ),
              _ValueReportCard(
                title: l.inventoryValue,
                values: [
                  _ValueLine(l.totalListedValue, data.totalListedValue),
                  _ValueLine(l.averagePrice, data.averagePrice),
                ],
              ),
            ],
          ),
          if (canFilterAssignee) ...[
            const SizedBox(height: AppSpacing.md),
            _AgentReportSection(data: data, users: users),
          ],
        ],
      ),
    );
  }
}

class _ReportHeader extends StatelessWidget {
  const _ReportHeader();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.reportsOverview,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondaryColor(context),
          ),
        ),
      ],
    );
  }
}

class _ReportsSearchFilterRow extends StatelessWidget {
  const _ReportsSearchFilterRow({
    required this.users,
    required this.canFilterAssignee,
    required this.period,
    required this.assignedTo,
    required this.hasFilters,
    required this.searchController,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.onPeriodChanged,
    required this.onAssignedToChanged,
    required this.onClearFilters,
  });

  final List<UserProfile> users;
  final bool canFilterAssignee;
  final _ReportPeriod period;
  final String assignedTo;
  final bool hasFilters;
  final TextEditingController searchController;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<_ReportPeriod> onPeriodChanged;
  final ValueChanged<String> onAssignedToChanged;
  final VoidCallback onClearFilters;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final isMobile = MediaQuery.sizeOf(context).width < 600;

    if (isMobile) {
      return Row(
        children: [
          Expanded(
            child: TextField(
              controller: searchController,
              onChanged: onSearchChanged,
              decoration: InputDecoration(
                labelText: l.searchReports,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchQuery.trim().isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () {
                    searchController.clear();
                    onSearchChanged('');
                  },
                )
                    : null,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          AppButton(
            label: l.filters,
            icon: Icons.tune,
            variant: AppButtonVariant.secondary,
            onPressed: () => _showReportsFiltersSheet(context),
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: AppSearchField(
            controller: searchController,
            hint: l.searchReports,
            onChanged: onSearchChanged,
            onClear: searchQuery.trim().isNotEmpty
                ? () {
              searchController.clear();
              onSearchChanged('');
            }
                : null,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        AppButton(
          label: l.filters,
          icon: Icons.tune_rounded,
          variant: AppButtonVariant.secondary,
          onPressed: () => _showReportsFiltersSheet(context),
        ),
        if (hasFilters) ...[
          const SizedBox(width: AppSpacing.sm),
          AppButton(
            label: l.clearFilters,
            icon: Icons.filter_alt_off_outlined,
            variant: AppButtonVariant.secondary,
            onPressed: onClearFilters,
          ),
        ],
      ],
    );
  }

  void _showReportsFiltersSheet(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardSurface(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.xl),
        ),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l.filters,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(sheetContext).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                AppDropdown<_ReportPeriod>(
                  label: l.reportPeriod,
                  value: period,
                  items: _ReportPeriod.values,
                  itemLabelBuilder: (value) => _periodLabel(l, value),
                  onChanged: onPeriodChanged,
                ),
                if (canFilterAssignee) ...[
                  const SizedBox(height: AppSpacing.md),
                  AppDropdown<_AssigneeOption>(
                    label: l.assignedAgent,
                    value: _AssigneeOption.fromValue(assignedTo),
                    items: _assigneeOptions(users),
                    itemLabelBuilder: (option) => option.isAll
                        ? l.allAgents
                        : _assigneeLabel(l, users, option.value),
                    onChanged: (option) => onAssignedToChanged(option.value),
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                AppButton(
                  label: l.clearFilters,
                  icon: Icons.filter_alt_off_outlined,
                  variant: AppButtonVariant.secondary,
                  onPressed: () {
                    onClearFilters();
                    Navigator.of(sheetContext).pop();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ExecutiveSummary extends StatelessWidget {
  const _ExecutiveSummary({required this.data});

  final _ReportsData data;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final items = [
      _SummaryItem(l.totalLeads, data.leads.length, AppStatusTone.info),
      _SummaryItem(l.totalDeals, data.deals.length, AppStatusTone.warning),
      _SummaryItem(l.openDeals, data.openDeals.length, AppStatusTone.warning),
      _SummaryItem(l.completedTasks, data.completedTasks.length,
          AppStatusTone.success),
      _SummaryItem(l.availableProperties, data.availableProperties.length,
          AppStatusTone.success),
    ];

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final item in items)
          SizedBox(width: 168, child: _SummaryCard(item: item)),
      ],
    );
  }
}

class _ReportSection extends StatelessWidget {
  const _ReportSection({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return _ReportCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: AppSpacing.md),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 920
                  ? 3
                  : constraints.maxWidth >= 620
                      ? 2
                      : 1;
              final width =
                  (constraints.maxWidth - (columns - 1) * AppSpacing.md) /
                      columns;
              return Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.md,
                children: [
                  for (final child in children) SizedBox(width: width, child: child),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.cardSurface(context),
        border: Border.all(color: AppColors.borderColor(context)),
        borderRadius: AppRadius.xLarge,
        boxShadow:
            Theme.of(context).brightness == Brightness.dark ? null : AppShadows.card,
      ),
      child: child,
    );
  }
}

class _SummaryItem {
  const _SummaryItem(this.label, this.value, this.tone);

  final String label;
  final int value;
  final AppStatusTone tone;
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.item});

  final _SummaryItem item;

  @override
  Widget build(BuildContext context) {
    final color = _toneColor(context, item.tone);
    return _ReportCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.insights_outlined, color: color, size: 20),
          const SizedBox(height: AppSpacing.sm),
          Text(
            item.value.toString(),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          Text(
            item.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.textSecondaryColor(context),
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _DonutReportCard extends StatelessWidget {
  const _DonutReportCard({
    required this.title,
    required this.segments,
  });

  final String title;
  final List<_ChartSegment> segments;

  @override
  Widget build(BuildContext context) {
    final total = segments.fold<int>(0, (sum, item) => sum + item.value);

    return _InnerReportCard(
      title: title,
      child: Row(
        children: [
          CustomPaint(
            size: const Size.square(82),
            painter: _DonutPainter(segments: segments),
            child: SizedBox.square(
              dimension: 82,
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
    );
  }
}

class _BarReportCard extends StatelessWidget {
  const _BarReportCard({
    required this.title,
    required this.rows,
  });

  final String title;
  final List<_BarRow> rows;

  @override
  Widget build(BuildContext context) {
    final maxValue = rows.fold<num>(
      0,
      (max, row) => row.metric > max ? row.metric : max,
    );

    return _InnerReportCard(
      title: title,
      child: Column(
        children: [
          for (final row in rows)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: _BarLine(
                row: row,
                value: maxValue == 0 ? 0 : row.metric / maxValue,
              ),
            ),
        ],
      ),
    );
  }
}

class _ProgressReportCard extends StatelessWidget {
  const _ProgressReportCard({
    required this.title,
    required this.value,
    required this.color,
  });

  final String title;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(0.0, 1.0);
    return _InnerReportCard(
      title: title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${(clamped * 100).round()}%',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: clamped,
              minHeight: 10,
              backgroundColor: AppColors.borderColor(context),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}

class _AttentionReportCard extends StatelessWidget {
  const _AttentionReportCard({required this.tasks});

  final List<CrmTask> tasks;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return _InnerReportCard(
      title: l.highestPriorityTasks,
      child: tasks.isEmpty
          ? Text(
              l.noTasksYet,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondaryColor(context),
                  ),
            )
          : Column(
              children: [
                for (final task in tasks.take(5))
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                task.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              Text(
                                _taskSubtitle(l, task),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        AppStatusBadge(
                          label: _taskDueLabel(l, task),
                          tone: _taskDueTone(task),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}

class _ValueLine {
  const _ValueLine(this.label, this.value);

  final String label;
  final num value;
}

class _ValueReportCard extends StatelessWidget {
  const _ValueReportCard({
    required this.title,
    required this.values,
  });

  final String title;
  final List<_ValueLine> values;

  @override
  Widget build(BuildContext context) {
    return _InnerReportCard(
      title: title,
      child: Column(
        children: [
          for (final value in values)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      value.label,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  Text(
                    _formatMoney(context, value.value),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _AgentReportSection extends StatelessWidget {
  const _AgentReportSection({required this.data, required this.users});

  final _ReportsData data;
  final List<UserProfile> users;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final rows = data.agentRows(users, l);

    return _ReportCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l.agentPerformance,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (rows.isEmpty)
            Text(
              l.noReportData,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondaryColor(context),
                  ),
            )
          else
            for (final row in rows.take(8))
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        row.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Wrap(
                        spacing: AppSpacing.xs,
                        runSpacing: AppSpacing.xs,
                        children: [
                          AppStatusBadge(
                            label: '${l.leads}: ${row.leads}',
                            tone: AppStatusTone.info,
                          ),
                          AppStatusBadge(
                            label: '${l.deals}: ${row.deals}',
                            tone: AppStatusTone.warning,
                          ),
                          AppStatusBadge(
                            label: '${l.completed}: ${row.completedTasks}',
                            tone: AppStatusTone.success,
                          ),
                          if (row.overdueTasks > 0)
                            AppStatusBadge(
                              label: '${l.overdue}: ${row.overdueTasks}',
                              tone: AppStatusTone.error,
                            ),
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
}

class _InnerReportCard extends StatelessWidget {
  const _InnerReportCard({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
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
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}

class _ChartSegment {
  const _ChartSegment(this.label, this.value, this.color);

  final String label;
  final int value;
  final Color color;
}

class _DonutPainter extends CustomPainter {
  const _DonutPainter({required this.segments});

  final List<_ChartSegment> segments;

  @override
  void paint(Canvas canvas, Size size) {
    final total = segments.fold<int>(0, (sum, segment) => sum + segment.value);
    final rect = Offset.zero & size;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    if (total == 0) {
      paint.color = const Color(0xFFD8D0C2);
      canvas.drawArc(rect.deflate(8), -math.pi / 2, math.pi * 2, false, paint);
      return;
    }

    var start = -math.pi / 2;
    for (final segment in segments.where((segment) => segment.value > 0)) {
      final sweep = math.pi * 2 * segment.value / total;
      paint.color = segment.color;
      canvas.drawArc(rect.deflate(8), start, sweep, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) {
    return oldDelegate.segments != segments;
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

class _BarRow {
  const _BarRow({
    required this.label,
    required this.value,
    required this.color,
    this.amount,
  });

  final String label;
  final int value;
  final Color color;
  final num? amount;

  num get metric => amount ?? value;
}

class _BarLine extends StatelessWidget {
  const _BarLine({required this.row, required this.value});

  final _BarRow row;
  final num value;

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(0, 1).toDouble();
    return Row(
      children: [
        SizedBox(
          width: 104,
          child: Text(
            row.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: clamped,
              minHeight: 8,
              backgroundColor: AppColors.borderColor(context),
              valueColor: AlwaysStoppedAnimation<Color>(row.color),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        SizedBox(
          width: 54,
          child: Text(
            row.amount == null
                ? row.value.toString()
                : _formatCompact(context, row.amount!),
            textAlign: TextAlign.end,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
        ),
      ],
    );
  }
}

class _ReportsData {
  _ReportsData({
    required List<Lead> leads,
    required List<Property> properties,
    required List<Client> clients,
    required List<CrmTask> tasks,
    required List<Deal> deals,
    required this.period,
    required this.assignedTo,
    required this.searchQuery,
  })  : leads = _filterBySearch<Lead>(
    _filterByDateAndAssignee<Lead>(
      leads,
      period,
      assignedTo,
          (lead) => lead.createdAt,
          (lead) => lead.assignedTo,
    ),
    searchQuery,
        (lead) => [
      lead.fullName,
      lead.phone,
      lead.email,
      lead.preferredLocation,
      lead.preferredPropertyType,
      lead.assignedToName,
      lead.notes,
      lead.source.name,
      lead.status.name,
      lead.priority.name,
    ],
  ),
        properties = _filterBySearch<Property>(
          _filterByDateAndAssignee<Property>(
            properties,
            period,
            assignedTo,
                (property) => property.createdAt,
                (property) => property.assignedTo,
          ),
          searchQuery,
              (property) => [
            property.title,
            property.description,
            property.location,
            property.compound,
            property.ownerName,
            property.ownerPhone,
            property.propertyType.name,
            property.listingType.name,
            property.status.name,
          ],
        ),
        tasks = _filterBySearch<CrmTask>(
          _filterByDateAndAssignee<CrmTask>(
            tasks,
            period,
            assignedTo,
                (task) => task.createdAt ?? task.updatedAt,
                (task) => task.assignedTo,
          ),
          searchQuery,
              (task) => [
            task.title,
            task.description,
            task.assignedToName,
            task.assignedToEmail,
            task.relatedTitle,
            task.relatedSubtitle,
            task.relatedType.name,
            task.status.name,
            task.priority.name,
          ],
        ),
        clients = _filterBySearch<Client>(
          _filterByDateAndAssignee<Client>(
            clients,
            period,
            assignedTo,
                (client) => client.createdAt ?? client.updatedAt,
                (client) => client.assignedTo,
          ),
          searchQuery,
              (client) => [
            client.fullName,
            client.phone,
            client.email,
            client.preferredLocation,
            client.preferredPropertyType,
            client.assignedToName,
            client.assignedToEmail,
            client.notes,
          ],
        ),
        deals = _filterBySearch<Deal>(
          _filterByDateAndAssignee<Deal>(
            deals,
            period,
            assignedTo,
                (deal) => deal.createdAt ?? deal.updatedAt,
                (deal) => deal.assignedTo,
          ),
          searchQuery,
              (deal) => [
            deal.clientName,
            deal.clientEmail,
            deal.clientPhone,
            deal.leadName,
            deal.leadPhone,
            deal.propertyTitle,
            deal.propertyLocation,
            deal.assignedToName,
            deal.assignedToEmail,
            deal.stage.name,
            deal.lostReason,
            deal.notes,
          ],
        );


  final List<Lead> leads;
  final String searchQuery;
  final List<Property> properties;
  final List<Client> clients;
  final List<CrmTask> tasks;
  final List<Deal> deals;
  final _ReportPeriod period;
  final String assignedTo;

  bool get hasAnyData =>
      leads.isNotEmpty ||
      properties.isNotEmpty ||
      clients.isNotEmpty ||
      tasks.isNotEmpty ||
      deals.isNotEmpty;

  List<Lead> leadsByStatus(LeadStatus status) =>
      leads.where((lead) => lead.status == status).toList();

  List<Lead> leadsBySource(LeadSource source) =>
      leads.where((lead) => lead.source == source).toList();

  List<Lead> leadsByPriority(LeadPriority priority) =>
      leads.where((lead) => lead.priority == priority).toList();

  List<Deal> get openDeals =>
      deals.where((deal) => deal.stage != DealStage.won && deal.stage != DealStage.lost).toList();

  List<Deal> get wonDeals =>
      deals.where((deal) => deal.stage == DealStage.won).toList();

  List<Deal> get lostDeals =>
      deals.where((deal) => deal.stage == DealStage.lost).toList();

  List<Deal> dealsByStage(DealStage stage) =>
      deals.where((deal) => deal.stage == stage).toList();

  num dealValueByStage(DealStage stage) {
    return dealsByStage(stage).fold<num>(
      0,
      (sum, deal) => sum + deal.expectedValue,
    );
  }

  num get expectedValueTotal =>
      openDeals.fold<num>(0, (sum, deal) => sum + deal.expectedValue);

  num get commissionTotal =>
      openDeals.fold<num>(0, (sum, deal) => sum + deal.commission);

  num get wonValue =>
      wonDeals.fold<num>(0, (sum, deal) => sum + deal.expectedValue);

  num get lostValue =>
      lostDeals.fold<num>(0, (sum, deal) => sum + deal.expectedValue);

  List<CrmTask> tasksByStatus(TaskStatus status) =>
      tasks.where((task) => task.status == status).toList();

  List<CrmTask> get completedTasks => tasksByStatus(TaskStatus.completed);

  List<CrmTask> get overdueTasks => tasks.where((task) {
        final date = task.dueDate;
        return date != null &&
            task.status != TaskStatus.completed &&
            task.status != TaskStatus.cancelled &&
            _dateOnly(date.toLocal()).isBefore(_today);
      }).toList();

  List<CrmTask> get dueTodayTasks => tasks.where((task) {
        final date = task.dueDate;
        return date != null && _dateOnly(date.toLocal()) == _today;
      }).toList();

  List<CrmTask> get upcomingTasks => tasks.where((task) {
        final date = task.dueDate;
        return date != null && _dateOnly(date.toLocal()).isAfter(_today);
      }).toList();

  double get completionRate =>
      tasks.isEmpty ? 0 : completedTasks.length / tasks.length;

  List<CrmTask> get attentionTasks {
    final selected = [
      ...overdueTasks,
      ...dueTodayTasks.where((task) => !overdueTasks.contains(task)),
    ];
    selected.sort((a, b) {
      final priority = _taskPriorityRank(b.priority).compareTo(
        _taskPriorityRank(a.priority),
      );
      if (priority != 0) {
        return priority;
      }
      final aDate = a.dueDate ?? DateTime(9999);
      final bDate = b.dueDate ?? DateTime(9999);
      return aDate.compareTo(bDate);
    });
    return selected;
  }

  List<Property> propertiesByStatus(PropertyStatus status) =>
      properties.where((property) => property.status == status).toList();

  List<Property> propertiesByType(PropertyType type) =>
      properties.where((property) => property.propertyType == type).toList();

  List<Property> get availableProperties =>
      propertiesByStatus(PropertyStatus.available);

  num get totalListedValue =>
      properties.fold<num>(0, (sum, property) => sum + property.price);

  num get averagePrice =>
      properties.isEmpty ? 0 : totalListedValue / properties.length;

  List<_AgentRow> agentRows(List<UserProfile> users, AppLocalizations l) {
    final ids = <String>{};
    ids.addAll(leads.map((lead) => lead.assignedTo).where((id) => id.isNotEmpty));
    ids.addAll(tasks.map((task) => task.assignedTo).where((id) => id.isNotEmpty));
    ids.addAll(deals.map((deal) => deal.assignedTo).where((id) => id.isNotEmpty));

    final rows = [
      for (final id in ids)
        _AgentRow(
          name: _assigneeLabelById(users, id).isEmpty
              ? l.assignedUserUnavailable
              : _assigneeLabelById(users, id),
          leads: leads.where((lead) => lead.assignedTo == id).length,
          deals: deals.where((deal) => deal.assignedTo == id).length,
          completedTasks: tasks
              .where((task) =>
                  task.assignedTo == id && task.status == TaskStatus.completed)
              .length,
          overdueTasks:
              overdueTasks.where((task) => task.assignedTo == id).length,
        ),
    ];
    rows.sort((a, b) => b.score.compareTo(a.score));
    return rows;
  }
}

class _AgentRow {
  const _AgentRow({
    required this.name,
    required this.leads,
    required this.deals,
    required this.completedTasks,
    required this.overdueTasks,
  });

  final String name;
  final int leads;
  final int deals;
  final int completedTasks;
  final int overdueTasks;

  int get score => leads + deals + completedTasks - overdueTasks;
}

class _AssigneeOption {
  const _AssigneeOption._({required this.value, required this.isAll});

  const _AssigneeOption.all() : this._(value: '', isAll: true);

  const _AssigneeOption.value(String value)
      : this._(value: value, isAll: false);

  factory _AssigneeOption.fromValue(String value) {
    return value.trim().isEmpty
        ? const _AssigneeOption.all()
        : _AssigneeOption.value(value);
  }

  final String value;
  final bool isAll;

  @override
  bool operator ==(Object other) {
    return other is _AssigneeOption &&
        other.value == value &&
        other.isAll == isAll;
  }

  @override
  int get hashCode => Object.hash(value, isAll);
}

List<_AssigneeOption> _assigneeOptions(List<UserProfile> users) {
  final sorted = [...users]..sort((a, b) => a.fullName.compareTo(b.fullName));
  return [
    const _AssigneeOption.all(),
    for (final user in sorted) _AssigneeOption.value(user.uid),
  ];
}

List<T> _filterBySearch<T>(
    List<T> items,
    String searchQuery,
    List<String?> Function(T item) termsBuilder,
    ) {
  final query = searchQuery.trim().toLowerCase();
  if (query.isEmpty) {
    return items;
  }

  return items.where((item) {
    return termsBuilder(item).any((term) {
      final value = term?.trim().toLowerCase() ?? '';
      return value.contains(query);
    });
  }).toList();
}

List<T> _filterByDateAndAssignee<T>(
  List<T> items,
  _ReportPeriod period,
  String assignedTo,
  DateTime? Function(T item) dateOf,
  String Function(T item) assignedToOf,
) {
  final selectedAssignee = assignedTo.trim();
  return items.where((item) {
    if (selectedAssignee.isNotEmpty && assignedToOf(item) != selectedAssignee) {
      return false;
    }
    return _matchesPeriod(dateOf(item), period);
  }).toList();
}

bool _matchesPeriod(DateTime? date, _ReportPeriod period) {
  if (period == _ReportPeriod.allTime) {
    return true;
  }
  if (date == null) {
    return false;
  }
  final day = _dateOnly(date.toLocal());
  switch (period) {
    case _ReportPeriod.allTime:
      return true;
    case _ReportPeriod.today:
      return day == _today;
    case _ReportPeriod.thisWeek:
      final weekStart = _today.subtract(Duration(days: _today.weekday - 1));
      final weekEnd = weekStart.add(const Duration(days: 6));
      return !day.isBefore(weekStart) && !day.isAfter(weekEnd);
    case _ReportPeriod.thisMonth:
      return day.year == _today.year && day.month == _today.month;
  }
}

DateTime get _today => _dateOnly(DateTime.now());

DateTime _dateOnly(DateTime value) {
  return DateTime(value.year, value.month, value.day);
}

Stream<List<UserProfile>> _watchActiveUsers(String companyId) {
  final repository = UserProfileRepositoryImpl(
    remoteDataSource: FirestoreUserProfileRemoteDataSource(),
  );
  return WatchActiveUsersUseCase(repository)(companyId: companyId);
}

String _periodLabel(AppLocalizations l, _ReportPeriod period) {
  return switch (period) {
    _ReportPeriod.allTime => l.allTime,
    _ReportPeriod.today => l.today,
    _ReportPeriod.thisWeek => l.thisWeek,
    _ReportPeriod.thisMonth => l.thisMonth,
  };
}

String _assigneeLabel(AppLocalizations l, List<UserProfile> users, String uid) {
  final label = _assigneeLabelById(users, uid);
  return label == uid ? l.assignedUserUnavailable : label;
}

String _assigneeLabelById(List<UserProfile> users, String uid) {
  for (final user in users) {
    if (user.uid == uid) {
      return user.fullName.trim().isEmpty ? user.email : user.fullName;
    }
  }
  return '';
}

String _leadStatusLabel(AppLocalizations l, LeadStatus status) {
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

String _leadPriorityLabel(AppLocalizations l, LeadPriority priority) {
  return switch (priority) {
    LeadPriority.low => l.low,
    LeadPriority.medium => l.medium,
    LeadPriority.high => l.high,
  };
}

String _taskStatusLabel(AppLocalizations l, TaskStatus status) {
  return switch (status) {
    TaskStatus.pending => l.pending,
    TaskStatus.inProgress => l.inProgress,
    TaskStatus.completed => l.completed,
    TaskStatus.cancelled => l.cancelled,
  };
}

String _taskSubtitle(AppLocalizations l, CrmTask task) {
  final relatedTitle = task.relatedTitle.trim();
  if (relatedTitle.isNotEmpty) {
    return relatedTitle;
  }
  final assignee = task.assignedToName.trim();
  if (assignee.isNotEmpty) {
    return assignee;
  }
  return l.dashboardGeneralTask;
}

String _taskDueLabel(AppLocalizations l, CrmTask task) {
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

Color _leadStatusColor(BuildContext context, LeadStatus status) {
  return switch (status) {
    LeadStatus.won => AppColors.successColor(context),
    LeadStatus.lost => AppColors.errorColor(context),
    LeadStatus.negotiation || LeadStatus.visitScheduled =>
      AppColors.warningColor(context),
    LeadStatus.contacted || LeadStatus.interested => AppColors.infoColor(context),
    LeadStatus.newLead => AppColors.primaryColor(context),
  };
}

Color _leadPriorityColor(BuildContext context, LeadPriority priority) {
  return switch (priority) {
    LeadPriority.high => AppColors.errorColor(context),
    LeadPriority.medium => AppColors.warningColor(context),
    LeadPriority.low => AppColors.successColor(context),
  };
}

Color _dealStageColor(BuildContext context, DealStage stage) {
  return switch (stage) {
    DealStage.won => AppColors.successColor(context),
    DealStage.lost => AppColors.errorColor(context),
    DealStage.negotiation || DealStage.proposal => AppColors.warningColor(context),
    DealStage.qualified => AppColors.infoColor(context),
    DealStage.newDeal => AppColors.primaryColor(context),
  };
}

Color _taskStatusColor(BuildContext context, TaskStatus status) {
  return switch (status) {
    TaskStatus.completed => AppColors.successColor(context),
    TaskStatus.cancelled => AppColors.textMutedColor(context),
    TaskStatus.inProgress => AppColors.infoColor(context),
    TaskStatus.pending => AppColors.warningColor(context),
  };
}

Color _propertyStatusColor(BuildContext context, PropertyStatus status) {
  return switch (status) {
    PropertyStatus.available => AppColors.successColor(context),
    PropertyStatus.reserved => AppColors.warningColor(context),
    PropertyStatus.sold || PropertyStatus.rented => AppColors.infoColor(context),
    PropertyStatus.inactive => AppColors.textMutedColor(context),
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

int _taskPriorityRank(TaskPriority priority) {
  return switch (priority) {
    TaskPriority.high => 3,
    TaskPriority.medium => 2,
    TaskPriority.low => 1,
  };
}

String _formatMoney(BuildContext context, num value) {
  final localeName = Localizations.localeOf(context).toString();
  return NumberFormat.decimalPattern(localeName).format(value);
}

String _formatCompact(BuildContext context, num value) {
  final localeName = Localizations.localeOf(context).toString();
  return NumberFormat.compact(locale: localeName).format(value);
}
