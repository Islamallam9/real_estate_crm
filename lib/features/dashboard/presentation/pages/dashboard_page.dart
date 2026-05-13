import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../../../properties/presentation/widgets/property_labels.dart';
import '../../../users/domain/entities/user_profile.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../users/data/datasources/user_profile_remote_data_source.dart';
import '../../../users/data/repositories/user_profile_repository_impl.dart';
import '../../../users/domain/entities/user_profile.dart';
import '../../../users/domain/usecases/watch_active_users_usecase.dart';
import 'package:intl/intl.dart' as intl;
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
                  child: DealsScope(
                    child: _DashboardContent(
                      companyId: companyId,
                      authState: authState,
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
    if (role != null && uid.isNotEmpty) {
      context.read<DealsCubit>().watchDeals(
            companyId: widget.companyId,
            role: role,
            currentUserId: uid,
      );
    }
  }

  void _retry() {
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
    if (role != null && uid.isNotEmpty) {
      context.read<DealsCubit>().watchDeals(
            companyId: widget.companyId,
            role: role,
            currentUserId: uid,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<UserProfile>>(
      stream: _watchActiveUsers(widget.companyId),
      builder: (context, usersSnapshot) {
        final currentProfile = widget.authState.userProfile;
        final loadedUsers = usersSnapshot.data ?? const <UserProfile>[];

        final users = <UserProfile>[
          ...loadedUsers,
          if (currentProfile != null &&
              !loadedUsers.any((user) => user.uid == currentProfile.uid))
            currentProfile,
        ];

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
                            final data = _DashboardData(
                              leads: leadsState.leads,
                              properties: propertiesState.properties,
                              clients: clientsState.clients,
                              tasks: tasksState.tasks,
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
                                    dealsState.status == DealsStatus.failure &&
                                        dealsState.deals.isEmpty;

                            final failureMessage = leadsState.message ??
                                propertiesState.message ??
                                clientsState.message ??
                                tasksState.message ??
                                dealsState.message;

                            return _DashboardView(
                              data: data,
                              users: users,
                              authState: widget.authState,
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
  }}

class _RecentActivityPanel extends StatelessWidget {
  const _RecentActivityPanel({
    required this.data,
    required this.users,
    required this.authState,
  });

  final _DashboardData data;
  final List<UserProfile> users;
  final AuthState authState;

  @override
  Widget build(BuildContext context) {
    final role = authState.userProfile?.role ?? authState.user?.role;
    final canViewRecentActivity =
        role == UserRole.admin || role == UserRole.manager;

    if (!canViewRecentActivity) {
      return const SizedBox.shrink();
    }

    final l = AppLocalizations.of(context)!;
    final items = data.recentActivities(context, users).take(5).toList();

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionTitle(title: l.dashboardRecentActivity),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l.dashboardRecentActivitySubtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondaryColor(context),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (items.isEmpty)
            _CompactEmpty(message: l.dashboardNoRecentActivity)
          else
            AnimatedSwitcher(
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
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: item.onTap == null ? null : () => item.onTap!(context),
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
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        meta,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
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
    );
  }
}

class _DashboardView extends StatelessWidget {
  const _DashboardView({
    required this.data,
    required this.users,
    required this.authState,
    required this.isLoading,
    required this.hasInitialFailure,
    required this.failureMessage,
    required this.onRetry,
  });

  final _DashboardData data;
  final AuthState authState;
  final List<UserProfile> users;
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
        final quickAddActions = _quickAddActions(context, authState);

        return Stack(
          children: [
            SingleChildScrollView(
              padding: EdgeInsets.only(
                bottom: mobile && quickAddActions.isNotEmpty ? 88 : 0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _WelcomePanel(authState: authState),
                  const SizedBox(height: AppSpacing.md),
                  _SummaryGrid(data: data),
                  const SizedBox(height: AppSpacing.md),
                  if (compact) ...[
                    _AnalyticsPanel(data: data),
                    if (!mobile) ...[
                      const SizedBox(height: AppSpacing.md),
                      _ActionPanel(authState: authState),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    _RecentActivityPanel(
                      data: data,
                      users: users,
                      authState: authState,
                    ),
                  ] else
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: _AnalyticsPanel(data: data)),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          flex: 2,
                          child: Column(
                            children: [
                              _ActionPanel(authState: authState),
                              const SizedBox(height: AppSpacing.md),
                              _RecentActivityPanel(
                                data: data,
                                users: users,
                                authState: authState,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: AppSpacing.md),
                  if (compact) ...[
                    _DealsDashboardSection(data: data),
                    const SizedBox(height: AppSpacing.md),
                    _TaskBreakdownSection(data: data),
                  ] else
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _DealsDashboardSection(data: data)),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(child: _TaskBreakdownSection(data: data)),
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
            ),
            if (mobile && quickAddActions.isNotEmpty)
              Positioned.fill(child: _MobileQuickAddFab(actions: quickAddActions)),
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
        role != null && PermissionService.can(role, AppPermission.createLead);
    final canCreateClient = role == UserRole.admin || role == UserRole.manager;
    final canCreateDeal =
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
            offset: Offset(offset.dx * animation.value, offset.dy * animation.value),
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

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final direction = Directionality.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardSurface : AppColors.backgroundHighlight,
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
                color: AppColors.selectedSurface(context),
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
      _MetricItem(l.openDeals, data.openDeals.length, AppStatusTone.warning),
      _MetricItem(l.wonDeals, data.wonDeals.length, AppStatusTone.success),
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
                            AppColors.primaryColor(context)),
                        _ChartSegment(copy.active, data.activeLeads.length,
                            AppColors.successColor(context)),
                        _ChartSegment(l.won, data.wonLeads.length,
                            AppColors.primaryPressed),
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
                            AppColors.primaryPressed),
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
                            const Color(0xFFD8D0C2)),
                        _ChartSegment(copy.reservedOrClosed,
                            data.reservedOrClosedProperties.length,
                            AppColors.warningColor(context)),
                      ],
                    ),
                  ),
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

class _DealsDashboardSection extends StatelessWidget {
  const _DealsDashboardSection({required this.data});

  final _DashboardData data;

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
                onTap: () => context.go(RouteNames.dealDetails(deal.id)),
              ),
          ],
        ],
      ),
    );
  }
}

class _TaskBreakdownSection extends StatelessWidget {
  const _TaskBreakdownSection({required this.data});

  final _DashboardData data;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final total = data.tasks.length;
    final completionRate =
        total == 0 ? 0.0 : data.completedTasks.length / total;

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
              _MiniMetric(label: l.overdueTasks, value: data.overdueTasks.length),
              _MiniMetric(label: l.dueTodayTasks, value: data.todayTasks.length),
              _MiniMetric(label: l.upcomingTasks, value: data.upcomingTasks.length),
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
                onTap: () => context.go(RouteNames.tasks),
              ),
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
      width: 132,
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
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
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
          width: 116,
          child: Text(
            label,
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
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        SizedBox(
          width: 44,
          child: Text(
            trailing ?? '${(clamped * 100).round()}%',
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
    required this.deals,
  });

  final List<Lead> leads;
  final List<Property> properties;
  final List<Client> clients;
  final List<CrmTask> tasks;
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

  List<CrmTask> get cancelledTasks =>
      tasks.where((task) => task.status == TaskStatus.cancelled).toList();

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
  List<_RecentActivityItem> recentActivities(
      BuildContext context,
      List<UserProfile> users,
      ) {
    final l = AppLocalizations.of(context)!;
    final items = <_RecentActivityItem>[];

    for (final lead in leads) {
      items.add(
        _RecentActivityItem(
          id: 'lead-${lead.id}-${lead.updatedAt.millisecondsSinceEpoch}',
          action: l.dashboardActivityLeadUpdated,
          title: _fallback(lead.fullName, l.lead),
          subtitle: _leadStatusLabel(context, lead.status),
          actorName: _actorNameFromId(l, users, lead.updatedBy),
          time: lead.updatedAt,
          timeLabel: _relativeTimeLabel(context, lead.updatedAt),
          icon: Icons.person_search_outlined,
          tone: _leadStatusTone(lead.status),
          onTap: (context) => context.go(RouteNames.leadDetails(lead.id)),
        ),
      );
    }

    for (final client in clients) {
      final time = client.updatedAt ?? client.createdAt;
      if (time == null) continue;

      items.add(
        _RecentActivityItem(
          id: 'client-${client.id}-${time.millisecondsSinceEpoch}',
          action: l.dashboardActivityClientUpdated,
          title: _fallback(client.fullName, l.client),
          subtitle: _fallback(client.preferredLocation, client.phone),
          actorName: _actorNameFromId(l, users, client.updatedBy),
          time: time,
          timeLabel: _relativeTimeLabel(context, time),
          icon: Icons.person_outline_rounded,
          tone: AppStatusTone.info,
          onTap: (context) => context.go(RouteNames.clientDetails(client.id)),
        ),
      );
    }

    for (final property in properties) {
      final time = property.updatedAt ?? property.createdAt;
      if (time == null) continue;

      items.add(
        _RecentActivityItem(
          id: 'property-${property.id}-${time.millisecondsSinceEpoch}',
          action: l.dashboardActivityPropertyUpdated,
          title: _fallback(property.title, l.property),
          subtitle: propertyStatusLabel(l, property.status),
          actorName: _actorNameFromId(l, users, property.updatedBy),
          time: time,
          timeLabel: _relativeTimeLabel(context, time),
          icon: Icons.business_outlined,
          tone: _propertyStatusTone(property.status),
          onTap: (context) => context.go(RouteNames.propertyDetails(property.id)),
        ),
      );
    }

    for (final task in tasks) {
      final time = task.updatedAt ?? task.createdAt;
      if (time == null) continue;

      items.add(
        _RecentActivityItem(
          id: 'task-${task.id}-${time.millisecondsSinceEpoch}',
          action: task.status == TaskStatus.completed
              ? l.dashboardActivityTaskCompleted
              : l.dashboardActivityTaskUpdated,
          title: _fallback(task.title, l.tasks),
          subtitle: _taskSubtitle(context, task),
          actorName: _actorNameFromId(l, users, task.updatedBy),
          time: time,
          timeLabel: _relativeTimeLabel(context, time),
          icon: Icons.checklist_rtl_rounded,
          tone: _taskDueTone(task),
          onTap: (context) => context.go(RouteNames.tasks),
        ),
      );
    }

    for (final deal in deals) {
      final time = deal.updatedAt ?? deal.createdAt;
      if (time == null) continue;

      items.add(
        _RecentActivityItem(
          id: 'deal-${deal.id}-${time.millisecondsSinceEpoch}',
          action: deal.stage == DealStage.won
              ? l.dashboardActivityDealWon
              : deal.stage == DealStage.lost
              ? l.dashboardActivityDealLost
              : l.dashboardActivityDealUpdated,
          title: _fallback(deal.clientName, l.deal),
          subtitle: _fallback(deal.propertyTitle, dealStageLabel(l, deal.stage)),
          actorName: _actorNameFromId(l, users, deal.updatedBy),
          time: time,
          timeLabel: _relativeTimeLabel(context, time),
          icon: Icons.handshake_outlined,
          tone: dealStageTone(deal.stage),
          onTap: (context) => context.go(RouteNames.dealDetails(deal.id)),
        ),
      );
    }

    items.sort((a, b) => b.time.compareTo(a.time));
    return items.take(5).toList();
  }
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

String _actorNameFromId(
    AppLocalizations l,
    List<UserProfile> users,
    String? uid,
    ) {
  final value = uid?.trim() ?? '';
  if (value.isEmpty) {
    return l.unknownUser;
  }

  for (final user in users) {
    if (user.uid == value) {
      final name = user.fullName.trim();
      if (name.isNotEmpty) return name;

      final email = user.email.trim();
      if (email.isNotEmpty) return email;
    }
  }

  return l.unknownUser;
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

AppStatusTone _propertyStatusTone(PropertyStatus status) {
  return switch (status) {
    PropertyStatus.available => AppStatusTone.success,
    PropertyStatus.reserved => AppStatusTone.warning,
    PropertyStatus.sold || PropertyStatus.rented => AppStatusTone.info,
    PropertyStatus.inactive => AppStatusTone.neutral,
  };
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

String _fallback(String value, String fallback) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? fallback : trimmed;
}

String _formatMoney(BuildContext context, num value) {
  final localeName = Localizations.localeOf(context).toString();
  return intl.NumberFormat.compact(locale: localeName).format(value);}

Color _dealStageColor(BuildContext context, DealStage stage) {
  return switch (stage) {
    DealStage.won => AppColors.successColor(context),
    DealStage.lost => AppColors.errorColor(context),
    DealStage.negotiation || DealStage.proposal => AppColors.warningColor(context),
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
Stream<List<UserProfile>> _watchActiveUsers(String companyId) {
  final repository = UserProfileRepositoryImpl(
    remoteDataSource: FirestoreUserProfileRemoteDataSource(),
  );
  return WatchActiveUsersUseCase(repository)(companyId: companyId);
}