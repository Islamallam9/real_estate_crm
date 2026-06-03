import 'dart:async';
import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' as intl;
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/auth/protected_company_session.dart';
import '../../../../core/constants/role_constants.dart';
import '../../../../core/permissions/app_permission.dart';
import '../../../../core/permissions/company_feature_gate.dart';
import '../../../../core/permissions/permission_service.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/external_link_opener.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/app_status_badge.dart';
import '../../../../core/widgets/masar_tab_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../audit_logs/domain/entities/audit_log.dart';
import '../../../audit_logs/presentation/cubit/audit_logs_cubit.dart';
import '../../../audit_logs/presentation/cubit/audit_logs_state.dart';
import '../../../deals/domain/entities/deal.dart';
import '../../../deals/presentation/widgets/deal_card.dart';
import '../../../leads/domain/entities/lead.dart';
import '../../../leads/presentation/cubit/leads_cubit.dart';
import '../../../leads/presentation/cubit/leads_state.dart';
import '../../../properties/domain/entities/property.dart';
import '../../../tasks/domain/entities/crm_task.dart';
import '../../../tasks/presentation/cubit/tasks_cubit.dart';
import '../../domain/entities/dashboard_analytics.dart';
import '../../domain/entities/sales_command_center.dart';
import 'dashboard_chart_palette.dart';

const double _kCockpitGap = 10;
const double _kRailWidth = 304;

class DashboardCockpitBody extends StatelessWidget {
  const DashboardCockpitBody({
    super.key,
    required this.analytics,
    required this.commandSummary,
    required this.authState,
    required this.platformPreview,
    this.previewCompanyName,
  });

  final DashboardAnalytics analytics;
  final SalesCommandSummary commandSummary;
  final AuthState authState;
  final bool platformPreview;
  final String? previewCompanyName;

  Widget _withGuidanceOverlay({required Widget child}) {
    // Smart guidance now lives globally in CrmAppShell. Keeping a dashboard-only
    // overlay here caused duplicate popup styles on the dashboard.
    return child;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final mobile = constraints.maxWidth < 760;
        if (mobile) {
          return _withGuidanceOverlay(
            child: DashboardMobileTabs(
              analytics: analytics,
              commandSummary: commandSummary,
              authState: authState,
              platformPreview: platformPreview,
            ),
          );
        }

        final showRail = constraints.maxWidth >= 980;
        final main = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _AnimatedSection(
              index: 0,
              child: DashboardWelcomeStrip(
                authState: authState,
                analytics: analytics,
                previewCompanyName: previewCompanyName,
              ),
            ),
            const SizedBox(height: _kCockpitGap),
            _AnimatedSection(
              index: 1,
              child: DashboardKpiGrid(metrics: _primaryMetrics(analytics.metrics), platformPreview: platformPreview),
            ),
            const SizedBox(height: _kCockpitGap),
            _AnimatedSection(
              index: 2,
              child: DashboardSmartSuggestionsStrip(
                summary: commandSummary,
                authState: authState,
                platformPreview: platformPreview,
              ),
            ),
            const SizedBox(height: _kCockpitGap),
            _AnimatedSection(
              index: 3,
              child: _MainAnalyticsGrid(analytics: analytics),
            ),
            const SizedBox(height: _kCockpitGap),
            _AnimatedSection(
              index: 4,
              child: _SecondaryAnalyticsGrid(
                analytics: analytics,
                authState: authState,
                commandSummary: commandSummary,
                platformPreview: platformPreview,
              ),
            ),
            const SizedBox(height: _kCockpitGap),
            _AnimatedSection(
              index: 5,
              child: _BottomOpportunityGrid(
                analytics: analytics,
                platformPreview: platformPreview,
              ),
            ),
            if (!showRail) ...[
              const SizedBox(height: _kCockpitGap),
              _AnimatedSection(
                index: 6,
                child: DashboardTodayRail(
                  analytics: analytics,
                  authState: authState,
                  platformPreview: platformPreview,
                ),
              ),
            ],
          ],
        );

        if (!showRail) {
          return _withGuidanceOverlay(child: main);
        }

        return _withGuidanceOverlay(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: main),
              const SizedBox(width: _kCockpitGap),
              SizedBox(
                width: _kRailWidth,
                child: _AnimatedSection(
                  index: 1,
                  child: DashboardTodayRail(
                    analytics: analytics,
                    authState: authState,
                    platformPreview: platformPreview,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DashboardGuidanceOverlay extends StatefulWidget {
  const _DashboardGuidanceOverlay({
    required this.summary,
    required this.authState,
  });

  final SalesCommandSummary summary;
  final AuthState authState;

  @override
  State<_DashboardGuidanceOverlay> createState() =>
      _DashboardGuidanceOverlayState();
}

class _DashboardGuidanceOverlayState extends State<_DashboardGuidanceOverlay> {
  final math.Random _random = math.Random();
  Timer? _showTimer;
  Timer? _hideTimer;
  SalesCommandItem? _item;
  bool _visible = false;
  bool _openedOnce = false;

  @override
  void initState() {
    super.initState();
    _scheduleNext(initial: true);
  }

  @override
  void didUpdateWidget(covariant _DashboardGuidanceOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.summary != widget.summary && !_visible) {
      _scheduleNext(initial: !_openedOnce);
    }
  }

  @override
  void dispose() {
    _showTimer?.cancel();
    _hideTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = _item;
    final isMobile = MediaQuery.sizeOf(context).width < 760;
    final reducedMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    return PositionedDirectional(
      end: isMobile ? 12 : 18,
      start: isMobile ? 12 : null,
      top: isMobile ? 14 : 18,
      child: IgnorePointer(
        ignoring: !_visible || item == null,
        child: AnimatedOpacity(
          opacity: _visible && item != null ? 1 : 0,
          duration: reducedMotion
              ? Duration.zero
              : const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          child: AnimatedSlide(
            offset: _visible || reducedMotion ? Offset.zero : const Offset(0, 0.08),
            duration: reducedMotion
                ? Duration.zero
                : const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            child: item == null
                ? const SizedBox.shrink()
                : ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isMobile ? double.infinity : 360,
                    ),
                    child: _DashboardGuidanceCard(
                      item: item,
                      authState: widget.authState,
                      onClose: _dismiss,
                      onOpen: () => _openSuggestion(context, item),
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  void _scheduleNext({required bool initial}) {
    _showTimer?.cancel();
    _hideTimer?.cancel();
    _showTimer = null;
    _hideTimer = null;

    if (!mounted || _visible || _availableItems().isEmpty) {
      return;
    }

    final delay = initial
        ? const Duration(seconds: 8)
        : Duration(seconds: 28 + _random.nextInt(28));
    _showTimer = Timer(delay, _showSuggestion);
  }

  List<SalesCommandItem> _availableItems() {
    return _topCommandItems(widget.summary)
        .where((item) => _commandRoute(item) != null || item.actionType == DashboardCommandActionType.createFollowUp)
        .take(8)
        .toList();
  }

  void _showSuggestion() {
    if (!mounted || _visible) {
      return;
    }
    final items = _availableItems();
    if (items.isEmpty) {
      _scheduleNext(initial: false);
      return;
    }

    setState(() {
      _openedOnce = true;
      _item = items[_random.nextInt(items.length)];
      _visible = true;
    });

    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 12), () {
      if (!mounted) return;
      setState(() => _visible = false);
      _scheduleNext(initial: false);
    });
  }

  void _dismiss() {
    _hideTimer?.cancel();
    if (mounted) {
      setState(() => _visible = false);
      _scheduleNext(initial: false);
    }
  }

  Future<void> _openSuggestion(BuildContext context, SalesCommandItem item) async {
    _hideTimer?.cancel();
    if (mounted) {
      setState(() => _visible = false);
    }
    await _showWorkQueueActionDrawer(
      context,
      item: item,
      authState: widget.authState,
    );
    if (mounted) {
      _scheduleNext(initial: false);
    }
  }
}

class _DashboardGuidanceCard extends StatelessWidget {
  const _DashboardGuidanceCard({
    required this.item,
    required this.authState,
    required this.onClose,
    required this.onOpen,
  });

  final SalesCommandItem item;
  final AuthState authState;
  final VoidCallback onClose;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final priorityColor = _commandPriorityColor(context, item.priority);
    final moduleLabel = _commandModuleLabel(l, item.module);
    final suggestion = _guidanceSuggestionLabel(l, item, authState);

    return Material(
      color: Colors.transparent,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.cardSurface(context),
          border: Border.all(
            color: priorityColor.withValues(alpha: 0.30),
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: Theme.of(context).brightness == Brightness.dark
              ? null
              : AppShadows.shell,
        ),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(12, 10, 10, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: priorityColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.auto_awesome_motion_outlined,
                      color: priorityColor,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.dashboardSuggestedNextAction,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$moduleLabel · ${_commandReasonText(l, item)}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: AppColors.textSecondaryColor(context),
                                fontWeight: FontWeight.w500,
                                height: 1.18,
                              ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: l.close,
                    visualDensity: VisualDensity.compact,
                    onPressed: onClose,
                    icon: const Icon(Icons.close_rounded, size: 18),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _fallback(item.title, moduleLabel),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              if (item.subtitle.trim().isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  item.subtitle.trim(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.textSecondaryColor(context),
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      suggestion,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: AppColors.textPrimaryColor(context),
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  AppButton(
                    label: l.open,
                    icon: Icons.open_in_new_rounded,
                    onPressed: onOpen,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 260.ms, curve: Curves.easeOutCubic)
        .slideY(begin: 0.06, end: 0);
  }
}

String _guidanceSuggestionLabel(
  AppLocalizations l,
  SalesCommandItem item,
  AuthState authState,
) {
  final role = authState.protectedCompanySession?.profile.role;
  final canCreateTask = role != null &&
      (role == UserRole.admin || role == UserRole.manager) &&
      PermissionService.can(role, AppPermission.createTask);
  final canCreateAppointment = role != null &&
      PermissionService.can(role, AppPermission.createAppointment);
  return _suggestedCommandActionLabel(
    l,
    item,
    canCreateTask: canCreateTask,
    canCreateAppointment: canCreateAppointment,
  );
}

class DashboardMobileTabs extends StatelessWidget {
  const DashboardMobileTabs({
    super.key,
    required this.analytics,
    required this.commandSummary,
    required this.authState,
    required this.platformPreview,
  });

  final DashboardAnalytics analytics;
  final SalesCommandSummary commandSummary;
  final AuthState authState;
  final bool platformPreview;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final tabs = [
      _MobileTab(
        label: l.dashboardOverviewTab,
        icon: Icons.space_dashboard_outlined,
        child: _MobileTabBody(
          children: [
            DashboardKpiGrid(
              metrics: _primaryMetrics(analytics.metrics),
              platformPreview: platformPreview,
            ),
            DashboardSmartSuggestionsStrip(
              summary: commandSummary,
              authState: authState,
              platformPreview: platformPreview,
            ),
          ],
        ),
      ),
      _MobileTab(
        label: l.today,
        icon: Icons.calendar_month_outlined,
        child: _MobileTabBody(
          children: [
            DashboardTodayRail(
              analytics: analytics,
              authState: authState,
              platformPreview: platformPreview,
            ),
          ],
        ),
      ),
      _MobileTab(
        label: l.dashboardPerformanceTab,
        icon: Icons.show_chart_rounded,
        child: _MobileTabBody(
          children: [
            DashboardPerformanceChartCard(analytics: analytics),
            DashboardDealsStageChart(analytics: analytics),
            DashboardLeadSourceChart(analytics: analytics),
          ],
        ),
      ),
      _MobileTab(
        label: l.dashboardOpportunitiesTab,
        icon: Icons.local_fire_department_outlined,
        child: _MobileTabBody(
          children: [
            DashboardOpportunitiesStrip(
              analytics: analytics,
              platformPreview: platformPreview,
            ),
          ],
        ),
      ),
    ];

    return DefaultTabController(
      length: tabs.length,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MasarTabBar(
            compact: true,
            tabs: [
              for (final tab in tabs)
                MasarTabItem(label: tab.label, icon: tab.icon),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: math.max(MediaQuery.sizeOf(context).height - 230, 520.0),
            child: TabBarView(
              physics: const NeverScrollableScrollPhysics(),
              children: [for (final tab in tabs) tab.child],
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileTab {
  const _MobileTab({
    required this.label,
    required this.icon,
    required this.child,
  });

  final String label;
  final IconData icon;
  final Widget child;
}

class _MobileTabBody extends StatelessWidget {
  const _MobileTabBody({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 92),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var index = 0; index < children.length; index++) ...[
            _AnimatedSection(index: index, child: children[index]),
            if (index != children.length - 1)
              const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}

class DashboardWelcomeStrip extends StatelessWidget {
  const DashboardWelcomeStrip({
    super.key,
    required this.authState,
    required this.analytics,
    this.previewCompanyName,
  });

  final AuthState authState;
  final DashboardAnalytics analytics;
  final String? previewCompanyName;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final name = _dashboardUserName(authState, previewCompanyName);
    final greeting = _timeGreeting(l, DateTime.now());
    final hot = analytics.metrics
        .where((item) => item.type == DashboardKpiType.hotOpportunities)
        .map((item) => item.value.round())
        .fold<int>(0, (sum, value) => sum + value);
    final due = analytics.metrics
        .where((item) => item.type == DashboardKpiType.dueTodayFollowUps)
        .map((item) => item.value.round())
        .fold<int>(0, (sum, value) => sum + value);
    final appointments = analytics.metrics
        .where((item) => item.type == DashboardKpiType.appointmentsToday)
        .map((item) => item.value.round())
        .fold<int>(0, (sum, value) => sum + value);

    return _DashboardCard(
      padding: const EdgeInsetsDirectional.fromSTEB(14, 12, 14, 12),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primaryColor(context).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.waving_hand_outlined,
              color: AppColors.primaryColor(context),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$greeting، $name',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        height: 1.15,
                      ),
                ),
                const SizedBox(height: 3),
                Text(
                  _welcomeInsight(l, hot: hot, due: due, appointments: appointments),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondaryColor(context),
                        fontWeight: FontWeight.w400,
                        height: 1.35,
                      ),
                ),
              ],
            ),
          ),
          if (MediaQuery.sizeOf(context).width >= 620) ...[
            const SizedBox(width: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _MiniCountChip(
                  label: l.dashboardKpiHotOpportunities,
                  value: hot,
                  tone: AppStatusTone.error,
                  route: RouteNames.filteredLeads(queue: 'hot'),
                ),
                _MiniCountChip(
                  label: l.dashboardKpiDueTodayFollowUps,
                  value: due,
                  tone: AppStatusTone.warning,
                  route: RouteNames.filteredLeads(followUp: 'dueToday'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _MiniCountChip extends StatelessWidget {
  const _MiniCountChip({
    required this.label,
    required this.value,
    required this.tone,
    this.route,
  });

  final String label;
  final int value;
  final AppStatusTone tone;
  final String? route;

  @override
  Widget build(BuildContext context) {
    final badge = AppStatusBadge(label: '$value $label', tone: tone);
    final targetRoute = route;
    if (targetRoute == null) {
      return badge;
    }
    return InkWell(
      onTap: () => context.go(targetRoute),
      borderRadius: BorderRadius.circular(999),
      child: badge,
    );
  }
}

String _dashboardUserName(AuthState authState, String? previewCompanyName) {
  final preview = previewCompanyName?.trim() ?? '';
  if (preview.isNotEmpty) {
    return preview;
  }
  final profile = authState.protectedCompanySession?.profile;
  final fullName = profile?.fullName.trim() ?? '';
  if (fullName.isNotEmpty) {
    return fullName;
  }
  final email = authState.user?.email?.trim() ?? '';
  if (email.isNotEmpty) {
    return email.split('@').first;
  }
  return 'Masar';
}

String _timeGreeting(AppLocalizations l, DateTime now) {
  if (now.hour < 12) {
    return l.dashboardGoodMorning;
  }
  if (now.hour < 18) {
    return l.dashboardGoodAfternoon;
  }
  return l.dashboardGoodEvening;
}

String _welcomeInsight(
  AppLocalizations l, {
  required int hot,
  required int due,
  required int appointments,
}) {
  final locale = l.localeName.toLowerCase();
  if (locale.startsWith('ar')) {
    if (hot > 0 || due > 0 || appointments > 0) {
      return l.dashboardWelcomeInsightActive;
    }
    return l.dashboardWelcomeInsightCalm;
  }
  if (hot > 0 || due > 0 || appointments > 0) {
    return l.dashboardWelcomeInsightActive;
  }
  return l.dashboardWelcomeInsightCalm;
}

class _MainAnalyticsGrid extends StatelessWidget {
  const _MainAnalyticsGrid({required this.analytics});

  final DashboardAnalytics analytics;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 760;
        if (stacked) {
          return Column(
            children: [
              DashboardPerformanceChartCard(analytics: analytics),
              const SizedBox(height: _kCockpitGap),
              DashboardDealsStageChart(analytics: analytics),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 7,
              child: DashboardPerformanceChartCard(analytics: analytics),
            ),
            const SizedBox(width: _kCockpitGap),
            Expanded(
              flex: 5,
              child: DashboardDealsStageChart(analytics: analytics),
            ),
          ],
        );
      },
    );
  }
}

class _SecondaryAnalyticsGrid extends StatelessWidget {
  const _SecondaryAnalyticsGrid({
    required this.analytics,
    required this.authState,
    required this.commandSummary,
    required this.platformPreview,
  });

  final DashboardAnalytics analytics;
  final AuthState authState;
  final SalesCommandSummary commandSummary;
  final bool platformPreview;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 760) {
          return Column(
            children: [
              DashboardLeadSourceChart(analytics: analytics),
              const SizedBox(height: _kCockpitGap),
              DashboardDailyInsightCard(
                insight: analytics.dailyInsight,
                platformPreview: platformPreview,
              ),
              const SizedBox(height: _kCockpitGap),
              DashboardTeamPerformanceCard(analytics: analytics),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: Column(
                children: [
                  DashboardLeadSourceChart(analytics: analytics),
                  const SizedBox(height: _kCockpitGap),
                  DashboardDailyInsightCard(
                    insight: analytics.dailyInsight,
                    platformPreview: platformPreview,
                  ),
                ],
              ),
            ),
            const SizedBox(width: _kCockpitGap),
            Expanded(
              flex: 7,
              child: DashboardTeamPerformanceCard(analytics: analytics),
            ),
          ],
        );
      },
    );
  }
}

class _BottomOpportunityGrid extends StatelessWidget {
  const _BottomOpportunityGrid({
    required this.analytics,
    required this.platformPreview,
  });

  final DashboardAnalytics analytics;
  final bool platformPreview;

  @override
  Widget build(BuildContext context) {
    return DashboardOpportunitiesStrip(
      analytics: analytics,
      platformPreview: platformPreview,
    );
  }
}

class DashboardKpiGrid extends StatefulWidget {
  const DashboardKpiGrid({
    super.key,
    required this.metrics,
    this.platformPreview = false,
  });

  final List<DashboardKpiMetric> metrics;
  final bool platformPreview;

  @override
  State<DashboardKpiGrid> createState() => _DashboardKpiGridState();
}

class _DashboardKpiGridState extends State<DashboardKpiGrid> {
  final ScrollController _controller = ScrollController();
  Timer? _autoScrollStartTimer;
  bool _autoScrollCancelled = false;
  bool _autoScrollRunning = false;

  @override
  void dispose() {
    _autoScrollStartTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final metrics = widget.metrics;
    if (metrics.isEmpty) {
      return DashboardChartEmptyState(
        message: AppLocalizations.of(context)!.dashboardNotEnoughData,
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final mobile = constraints.maxWidth < 620;
        final gap = mobile ? 8.0 : _kCockpitGap;
        final itemWidth = mobile
            ? math.min(190.0, math.max(164.0, constraints.maxWidth * 0.54))
            : constraints.maxWidth >= 1180
                ? 198.0
                : constraints.maxWidth >= 900
                    ? 188.0
                    : 176.0;
        final cardExtent = mobile ? 94.0 : 100.0;
        final stripHeight = cardExtent * 2 + gap;
        final columnCount = (metrics.length / 2).ceil();
        final contentWidth = columnCount * itemWidth +
            math.max(0, columnCount - 1) * gap;
        final canScroll = contentWidth > constraints.maxWidth;
        final showControls = canScroll && !mobile;
        _scheduleAutoScroll(context, canScroll: canScroll);
        return SizedBox(
          height: stripHeight,
          child: MouseRegion(
            onEnter: (_) => _cancelAutoScroll(stopScroll: true),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Padding(
                  padding: EdgeInsetsDirectional.symmetric(
                    horizontal: showControls ? 34 : 0,
                  ),
                  child: Listener(
                    onPointerDown: (_) => _cancelAutoScroll(stopScroll: true),
                    onPointerSignal: _handlePointerSignal,
                    child: ListView.separated(
                      controller: _controller,
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: columnCount,
                      separatorBuilder: (_, __) => SizedBox(width: gap),
                      itemBuilder: (context, columnIndex) {
                        final firstIndex = columnIndex * 2;
                        final secondIndex = firstIndex + 1;
                        return SizedBox(
                          width: itemWidth,
                          child: Column(
                            children: [
                              SizedBox(
                                height: cardExtent,
                                child: DashboardKpiCard(
                                  metric: metrics[firstIndex],
                                  compact: mobile,
                                  platformPreview: widget.platformPreview,
                                ),
                              )
                                  .animate(delay: Duration(milliseconds: 70 * firstIndex))
                                  .fadeIn(duration: 480.ms, curve: Curves.easeOutCubic)
                                  .slideX(begin: 0.035, end: 0),
                              if (secondIndex < metrics.length) ...[
                                SizedBox(height: gap),
                                SizedBox(
                                  height: cardExtent,
                                  child: DashboardKpiCard(
                                    metric: metrics[secondIndex],
                                    compact: mobile,
                                    platformPreview: widget.platformPreview,
                                  ),
                                )
                                    .animate(delay: Duration(milliseconds: 70 * secondIndex))
                                    .fadeIn(duration: 480.ms, curve: Curves.easeOutCubic)
                                    .slideX(begin: 0.035, end: 0),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
                if (showControls) ...[
                  PositionedDirectional(
                    start: 0,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: _RailRoundButton(
                        icon: Icons.chevron_left_rounded,
                        onTap: () => _scrollBy(-itemWidth - gap),
                      ),
                    ),
                  ),
                  PositionedDirectional(
                    end: 0,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: _RailRoundButton(
                        icon: Icons.chevron_right_rounded,
                        onTap: () => _scrollBy(itemWidth + gap),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  void _handlePointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent || !_controller.hasClients) {
      return;
    }
    _cancelAutoScroll(stopScroll: true);
    final delta = event.scrollDelta.dx.abs() > event.scrollDelta.dy.abs()
        ? event.scrollDelta.dx
        : event.scrollDelta.dy;
    if (delta == 0) {
      return;
    }
    final direction = Directionality.of(context) == TextDirection.rtl ? -1 : 1;
    _scrollBy((delta * direction).toDouble());
  }

  void _scrollBy(double delta) {
    _cancelAutoScroll(stopScroll: true);
    if (!_controller.hasClients) return;
    final target = (_controller.offset + delta).clamp(
      _controller.position.minScrollExtent,
      _controller.position.maxScrollExtent,
    );
    _controller.animateTo(
      target.toDouble(),
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
    );
  }

  void _scheduleAutoScroll(
    BuildContext context, {
    required bool canScroll,
  }) {
    if (!canScroll ||
        _autoScrollCancelled ||
        _autoScrollRunning ||
        _autoScrollStartTimer != null ||
        (MediaQuery.maybeOf(context)?.disableAnimations ?? false)) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          _autoScrollCancelled ||
          _autoScrollRunning ||
          _autoScrollStartTimer != null ||
          !_controller.hasClients ||
          _controller.position.maxScrollExtent <= 1) {
        return;
      }

      _autoScrollStartTimer = Timer(const Duration(milliseconds: 4200), () {
        _autoScrollStartTimer = null;
        _runAutoScrollLoop();
      });
    });
  }

  Future<void> _runAutoScrollLoop() async {
    if (_autoScrollRunning || _autoScrollCancelled || !_controller.hasClients) {
      return;
    }
    _autoScrollRunning = true;
    var forward = Directionality.of(context) != TextDirection.rtl;
    try {
      while (mounted &&
          !_autoScrollCancelled &&
          _controller.hasClients &&
          _controller.position.maxScrollExtent > 1) {
        final position = _controller.position;
        final min = position.minScrollExtent;
        final max = position.maxScrollExtent;
        final current = _controller.offset.clamp(min, max).toDouble();
        var target = forward ? max : min;
        var distance = (target - current).abs();

        // If the strip is already at the chosen edge, reverse direction and
        // start a calm back-and-forth bounce instead of feeling like an
        // endless one-way marquee.
        if (distance <= 2) {
          forward = !forward;
          target = forward ? max : min;
          distance = (target - current).abs();
          if (distance <= 2) {
            await Future<void>.delayed(const Duration(milliseconds: 650));
            continue;
          }
        }

        final duration = Duration(
          milliseconds: math.max(26000, math.min(68000, (distance * 120).round())),
        );
        await _controller.animateTo(
          target.toDouble(),
          duration: duration,
          curve: Curves.easeInOutCubic,
        );
        if (!mounted || _autoScrollCancelled) {
          return;
        }
        forward = !forward;
        await Future<void>.delayed(const Duration(milliseconds: 3200));
      }
    } catch (_) {
      // A user gesture can interrupt animateTo; cancellation is expected.
    } finally {
      _autoScrollRunning = false;
    }
  }

  void _cancelAutoScroll({bool stopScroll = false}) {
    if (!_autoScrollCancelled) {
      _autoScrollCancelled = true;
      _autoScrollStartTimer?.cancel();
      _autoScrollStartTimer = null;
    }

    if (stopScroll && _controller.hasClients) {
      final current = _controller.offset.clamp(
        _controller.position.minScrollExtent,
        _controller.position.maxScrollExtent,
      );
      _controller.jumpTo(current.toDouble());
    }
  }
}

class DashboardKpiCard extends StatefulWidget {
  const DashboardKpiCard({
    super.key,
    required this.metric,
    required this.compact,
    required this.platformPreview,
  });

  final DashboardKpiMetric metric;
  final bool compact;
  final bool platformPreview;

  @override
  State<DashboardKpiCard> createState() => _DashboardKpiCardState();
}

class _DashboardKpiCardState extends State<DashboardKpiCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final metric = widget.metric;
    final color = DashboardChartPalette.kpiColor(context, metric.type);
    final trend = metric.trendPercent;
    final route = widget.platformPreview ? null : _kpiRoute(metric.type);
    final enabled = route != null;
    final cardHeight = widget.compact ? 78.0 : 82.0;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        scale: _hovered && enabled ? 1.018 : 1,
        child: _DashboardCard(
          padding: EdgeInsetsDirectional.fromSTEB(
            widget.compact ? 8 : 10,
            widget.compact ? 8 : 9,
            widget.compact ? 8 : 10,
            widget.compact ? 8 : 9,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: enabled ? () => context.go(route) : null,
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                height: cardHeight,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _kpiTitle(context, metric.type),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: AppColors.textSecondaryColor(context),
                                  fontSize: widget.compact ? 10 : 10.5,
                                  height: 1.08,
                                  fontWeight: FontWeight.w400,
                                ),
                          ),
                        ),
                        _SoftIcon(icon: _kpiIcon(metric.type), color: color),
                      ],
                    ),
                    const Spacer(),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(child: _AnimatedMetricValue(metric: metric)),
                        SizedBox(
                          width: widget.compact ? 44 : 52,
                          height: widget.compact ? 20 : 24,
                          child: DashboardSparkline(
                            values: metric.sparkline,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: widget.compact ? 3 : 4),
                    Row(
                      children: [
                        if (trend != null) ...[
                          _TrendChip(value: trend),
                          const SizedBox(width: 5),
                        ],
                        Expanded(
                          child: Text(
                            _kpiPeriod(context, metric.type),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: AppColors.textMutedColor(context),
                                  fontSize: widget.compact ? 10 : null,
                                  fontWeight: FontWeight.w400,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String? _kpiRoute(DashboardKpiType type) {
  return switch (type) {
    DashboardKpiType.activeLeads => RouteNames.filteredLeads(queue: 'active'),
    DashboardKpiType.newLeadsToday => RouteNames.filteredLeads(queue: 'newToday'),
    DashboardKpiType.hotOpportunities => RouteNames.filteredLeads(queue: 'hot'),
    DashboardKpiType.dueTodayFollowUps =>
      RouteNames.filteredLeads(followUp: 'dueToday'),
    DashboardKpiType.overdueFollowUps =>
      RouteNames.filteredLeads(followUp: 'overdue'),
    DashboardKpiType.overdueActions => null,
    DashboardKpiType.appointmentsToday =>
      RouteNames.filteredAppointments(selectedDate: _queryDate(DateTime.now())),
    DashboardKpiType.missedAppointments =>
      RouteNames.filteredAppointments(date: 'missed'),
    DashboardKpiType.overdueTasks => RouteNames.filteredTasks(due: 'overdue'),
    DashboardKpiType.pipelineDeals ||
    DashboardKpiType.expectedPipelineValue =>
      RouteNames.filteredDeals(queue: 'open'),
    DashboardKpiType.expectedCommission => RouteNames.filteredDeals(queue: 'open'),
    DashboardKpiType.wonDealsThisMonth => RouteNames.filteredDeals(queue: 'wonThisMonth'),
    DashboardKpiType.stuckDeals => RouteNames.filteredDeals(queue: 'atRisk'),
    DashboardKpiType.unassignedLeads =>
      RouteNames.filteredLeads(queue: 'unassigned'),
    DashboardKpiType.teamWorkload => null,
    DashboardKpiType.activeProperties =>
      RouteNames.filteredProperties(status: 'available'),
  };
}

class _AnimatedMetricValue extends StatelessWidget {
  const _AnimatedMetricValue({required this.metric});

  final DashboardKpiMetric metric;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w500,
          height: 1,
        );
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: metric.value.toDouble()),
      duration: const Duration(milliseconds: 850),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        final label = _isMoneyKpi(metric.type)
            ? _formatMoney(context, value)
            : value.round().toString();
        return Text(
          metric.value == 0 && metric.valueLabel.trim().isNotEmpty
              ? metric.valueLabel
              : label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: style,
        );
      },
    );
  }
}

class DashboardSparkline extends StatelessWidget {
  const DashboardSparkline({
    super.key,
    required this.values,
    required this.color,
  });

  final List<int> values;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty || values.every((value) => value == 0)) {
      return CustomPaint(
        painter: _EmptySparklinePainter(color: color.withValues(alpha: 0.32)),
      );
    }
    final maxValue = values.fold<int>(
      1,
      (maxValue, value) => value > maxValue ? value : maxValue,
    );

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (values.length - 1).toDouble(),
        minY: 0,
        maxY: maxValue.toDouble(),
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineTouchData: const LineTouchData(enabled: false),
        lineBarsData: [
          LineChartBarData(
            spots: [
              for (var index = 0; index < values.length; index++)
                FlSpot(index.toDouble(), values[index].toDouble()),
            ],
            isCurved: true,
            color: color,
            barWidth: 2.2,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: color.withValues(alpha: 0.12),
            ),
          ),
        ],
      ),
    );
  }
}

class DashboardPerformanceChartCard extends StatefulWidget {
  const DashboardPerformanceChartCard({super.key, required this.analytics});

  final DashboardAnalytics analytics;

  @override
  State<DashboardPerformanceChartCard> createState() =>
      _DashboardPerformanceChartCardState();
}

enum _PerformanceSeriesFilter { all, leads, appointments, followUps, deals, properties }

enum _PerformanceTrendMode { total, daily }

class _DashboardPerformanceChartCardState
    extends State<DashboardPerformanceChartCard> {
  int _selectedRange = 1;
  _PerformanceSeriesFilter _selectedFilter = _PerformanceSeriesFilter.all;
  _PerformanceTrendMode _selectedMode = _PerformanceTrendMode.total;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final mobile = MediaQuery.sizeOf(context).width < 760;
    final rangeDays = _selectedRange == 0 ? 7 : 30;
    final series = widget.analytics.performanceSeries
        .where(_matchesPerformanceFilter)
        .where((item) => item.type != DashboardPerformanceSeriesType.pipelineValue)
        .map((item) {
          final points = item.points.length > rangeDays
              ? item.points.sublist(item.points.length - rangeDays)
              : item.points;
          return DashboardChartSeries(
            type: item.type,
            points: _pointsForTrendMode(item.type, points),
          );
        })
        .where((item) => item.points.isNotEmpty)
        .toList();

    return _DashboardCard(
      padding: EdgeInsets.all(mobile ? AppSpacing.sm : AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CardHeader(
            title: l.dashboardPerformanceOverview,
            trailing: mobile ? null : _PerformanceControls(
              selectedRange: _selectedRange,
              selectedFilter: _selectedFilter,
              selectedMode: _selectedMode,
              onRangeChanged: (value) => setState(() => _selectedRange = value),
              onFilterChanged: (value) => setState(() => _selectedFilter = value),
              onModeChanged: (value) => setState(() => _selectedMode = value),
            ),
          ),
          if (mobile) ...[
            const SizedBox(height: AppSpacing.xs),
            _PerformanceControls(
              selectedRange: _selectedRange,
              selectedFilter: _selectedFilter,
              selectedMode: _selectedMode,
              onRangeChanged: (value) => setState(() => _selectedRange = value),
              onFilterChanged: (value) => setState(() => _selectedFilter = value),
              onModeChanged: (value) => setState(() => _selectedMode = value),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Text(
            _selectedMode == _PerformanceTrendMode.total
                ? l.dashboardPerformanceTotalTrendNote
                : l.dashboardPerformanceDailyActivityNote,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textSecondaryColor(context),
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(height: AppSpacing.xs),
          if (series.isEmpty)
            SizedBox(
              height: mobile ? 106 : 218,
              child: DashboardChartEmptyState(message: l.dashboardNotEnoughData),
            )
          else ...[
            _PerformanceLegend(series: series),
            const SizedBox(height: AppSpacing.xs),
            SizedBox(
              height: mobile ? 116 : 218,
              child: LineChart(_performanceChartData(context, series)),
            ),
          ],
        ],
      ),
    );
  }

  List<DashboardTrendPoint> _pointsForTrendMode(
    DashboardPerformanceSeriesType type,
    List<DashboardTrendPoint> points,
  ) {
    if (_selectedMode == _PerformanceTrendMode.daily || points.isEmpty) {
      return points;
    }

    final currentTotal = _currentTotalForSeries(type);
    final visibleTotal = points.fold<int>(0, (sum, point) => sum + point.value);
    var runningTotal = math.max(currentTotal - visibleTotal, 0);
    return [
      for (final point in points)
        DashboardTrendPoint(
          date: point.date,
          value: runningTotal += point.value,
        ),
    ];
  }

  int _currentTotalForSeries(DashboardPerformanceSeriesType type) {
    int valueFor(DashboardKpiType metricType) {
      for (final metric in widget.analytics.metrics) {
        if (metric.type == metricType) {
          return metric.value.round().clamp(0, 1 << 30).toInt();
        }
      }
      return 0;
    }

    return switch (type) {
      DashboardPerformanceSeriesType.leads =>
        valueFor(DashboardKpiType.activeLeads),
      DashboardPerformanceSeriesType.appointments =>
        valueFor(DashboardKpiType.appointmentsToday) +
            valueFor(DashboardKpiType.missedAppointments),
      DashboardPerformanceSeriesType.followUps =>
        valueFor(DashboardKpiType.dueTodayFollowUps) +
            valueFor(DashboardKpiType.overdueFollowUps),
      DashboardPerformanceSeriesType.deals =>
        valueFor(DashboardKpiType.pipelineDeals) +
            valueFor(DashboardKpiType.wonDealsThisMonth),
      DashboardPerformanceSeriesType.properties =>
        valueFor(DashboardKpiType.activeProperties),
      DashboardPerformanceSeriesType.pipelineValue => 0,
    };
  }

  bool _matchesPerformanceFilter(DashboardChartSeries item) {
    return switch (_selectedFilter) {
      _PerformanceSeriesFilter.all => true,
      _PerformanceSeriesFilter.leads => item.type == DashboardPerformanceSeriesType.leads,
      _PerformanceSeriesFilter.appointments => item.type == DashboardPerformanceSeriesType.appointments,
      _PerformanceSeriesFilter.followUps => item.type == DashboardPerformanceSeriesType.followUps,
      _PerformanceSeriesFilter.deals => item.type == DashboardPerformanceSeriesType.deals,
      _PerformanceSeriesFilter.properties => item.type == DashboardPerformanceSeriesType.properties,
    };
  }
}

class _PerformanceControls extends StatelessWidget {
  const _PerformanceControls({
    required this.selectedRange,
    required this.selectedFilter,
    required this.selectedMode,
    required this.onRangeChanged,
    required this.onFilterChanged,
    required this.onModeChanged,
  });

  final int selectedRange;
  final _PerformanceSeriesFilter selectedFilter;
  final _PerformanceTrendMode selectedMode;
  final ValueChanged<int> onRangeChanged;
  final ValueChanged<_PerformanceSeriesFilter> onFilterChanged;
  final ValueChanged<_PerformanceTrendMode> onModeChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final compact = MediaQuery.sizeOf(context).width < 760;
    final rangeWidth = compact ? 190.0 : 222.0;
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      alignment: WrapAlignment.end,
      children: [
        SizedBox(
          width: rangeWidth,
          child: MasarSwitchTabBar(
            compact: true,
            selectedIndex: selectedRange,
            onChanged: onRangeChanged,
            tabs: [
              MasarSwitchTabItem(
                label: l.dashboardLast7Days,
                icon: Icons.timeline_outlined,
              ),
              MasarSwitchTabItem(
                label: l.last30Days,
                icon: Icons.show_chart_rounded,
              ),
            ],
          ),
        ),
        SizedBox(
          width: compact ? 154.0 : 174.0,
          child: MasarSwitchTabBar(
            compact: true,
            selectedIndex: selectedMode.index,
            onChanged: (value) => onModeChanged(_PerformanceTrendMode.values[value]),
            tabs: [
              MasarSwitchTabItem(
                label: l.dashboardPerformanceTotalTrend,
                icon: Icons.stacked_line_chart_rounded,
              ),
              MasarSwitchTabItem(
                label: l.dashboardPerformanceDailyTrend,
                icon: Icons.bar_chart_rounded,
              ),
            ],
          ),
        ),
        PopupMenuButton<_PerformanceSeriesFilter>(
          tooltip: _performanceFilterLabel(context, selectedFilter),
          position: PopupMenuPosition.under,
          onSelected: onFilterChanged,
          itemBuilder: (context) => [
            for (final filter in _PerformanceSeriesFilter.values)
              PopupMenuItem<_PerformanceSeriesFilter>(
                value: filter,
                child: Text(_performanceFilterLabel(context, filter)),
              ),
          ],
          child: Container(
            height: 38,
            padding: const EdgeInsetsDirectional.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.cardSurface(context),
              border: Border.all(color: AppColors.borderColor(context)),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.filter_alt_outlined, size: 17, color: AppColors.primaryColor(context)),
                const SizedBox(width: 6),
                Text(
                  _performanceFilterLabel(context, selectedFilter),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class DashboardDealsStageChart extends StatelessWidget {
  const DashboardDealsStageChart({super.key, required this.analytics});

  final DashboardAnalytics analytics;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final rows = analytics.dealStages.where((item) => item.count > 0).toList();
    final total = rows.fold<int>(0, (sum, item) => sum + item.count);

    return _DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CardHeader(title: l.dashboardDealsByStage),
          const SizedBox(height: AppSpacing.md),
          if (total == 0)
            SizedBox(
              height: MediaQuery.sizeOf(context).width < 760 ? 112 : 216,
              child: DashboardChartEmptyState(message: l.dashboardNotEnoughData),
            )
          else
            SizedBox(
              height: MediaQuery.sizeOf(context).width < 760 ? 132 : 216,
              child: Row(
                children: [
                  Expanded(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        PieChart(
                          PieChartData(
                            sectionsSpace: 2,
                            centerSpaceRadius: MediaQuery.sizeOf(context).width < 760 ? 34 : 54,
                            startDegreeOffset: -90,
                            sections: [
                              for (var index = 0; index < rows.length; index++)
                                PieChartSectionData(
                                  value: rows[index].count.toDouble(),
                                  title: '',
                                  radius: MediaQuery.sizeOf(context).width < 760 ? 22 : 34,
                                  color: DashboardChartPalette.dealStageColor(
                                    context,
                                    index,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              total.toString(),
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.w500),
                            ),
                            Text(
                              l.deals,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: AppColors.textSecondaryColor(context),
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _DonutLegend(
                      total: total,
                      rows: [
                        for (var index = 0; index < rows.length; index++)
                          _LegendRowData(
                            label: dealStageLabel(l, rows[index].stage),
                            value: rows[index].count,
                            color: DashboardChartPalette.dealStageColor(
                              context,
                              index,
                            ),
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

class DashboardLeadSourceChart extends StatelessWidget {
  const DashboardLeadSourceChart({super.key, required this.analytics});

  final DashboardAnalytics analytics;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final rows = analytics.leadSources.take(6).toList();
    final total = rows.fold<int>(0, (sum, item) => sum + item.count);

    return _DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CardHeader(title: l.dashboardLeadSources),
          const SizedBox(height: AppSpacing.md),
          if (total == 0)
            SizedBox(
              height: MediaQuery.sizeOf(context).width < 760 ? 112 : 166,
              child: DashboardChartEmptyState(message: l.dashboardNotEnoughData),
            )
          else
            SizedBox(
              height: MediaQuery.sizeOf(context).width < 760 ? 126 : 166,
              child: Row(
                children: [
                  SizedBox(
                    width: MediaQuery.sizeOf(context).width < 760 ? 92 : 118,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        PieChart(
                          PieChartData(
                            sectionsSpace: 2,
                            centerSpaceRadius: MediaQuery.sizeOf(context).width < 760 ? 28 : 36,
                            sections: [
                              for (var index = 0; index < rows.length; index++)
                                PieChartSectionData(
                                  value: rows[index].count.toDouble(),
                                  title: '',
                                  radius: MediaQuery.sizeOf(context).width < 760 ? 20 : 26,
                                  color: DashboardChartPalette.leadSourceColor(
                                    context,
                                    index,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Text(
                          total.toString(),
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _DonutLegend(
                      total: total,
                      rows: [
                        for (var index = 0; index < rows.length; index++)
                          _LegendRowData(
                            label: _leadSourceLabel(l, rows[index].source),
                            value: rows[index].count,
                            color: DashboardChartPalette.leadSourceColor(
                              context,
                              index,
                            ),
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

class DashboardQuickActionsCard extends StatelessWidget {
  const DashboardQuickActionsCard({
    super.key,
    required this.authState,
    required this.commandSummary,
    required this.platformPreview,
  });

  final AuthState authState;
  final SalesCommandSummary commandSummary;
  final bool platformPreview;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final actions = platformPreview
        ? const <_DashboardAction>[]
        : _dashboardActions(context, authState);

    return _DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CardHeader(title: l.dashboardQuickActions),
          const SizedBox(height: AppSpacing.md),
          if (actions.isEmpty)
            DashboardChartEmptyState(
              message: platformPreview
                  ? l.readOnlyPreview
                  : l.dashboardQuickActionsUnavailable,
            )
          else
            GridView.builder(
              itemCount: actions.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: AppSpacing.sm,
                mainAxisSpacing: AppSpacing.sm,
                mainAxisExtent: 54,
              ),
              itemBuilder: (context, index) {
                final action = actions[index];
                return _QuickActionTile(action: action);
              },
            ),
        ],
      ),
    );
  }
}

class DashboardTeamPerformanceCard extends StatelessWidget {
  const DashboardTeamPerformanceCard({super.key, required this.analytics});

  final DashboardAnalytics analytics;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final personal = analytics.role == UserRole.salesAgent ||
        analytics.role == UserRole.marketing;
    final rows = [...analytics.teamRows]
      ..sort((a, b) {
        final score = _teamScore(b).compareTo(_teamScore(a));
        if (score != 0) return score;
        return b.activeRecords.compareTo(a.activeRecords);
      });
    final visibleRows = rows;
    final maxScore = visibleRows.fold<num>(1, (maxValue, row) {
      final score = _teamScore(row);
      return score > maxValue ? score : maxValue;
    });
    final mobile = MediaQuery.sizeOf(context).width < 760;

    return _DashboardCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CardHeader(
            title: personal ? l.dashboardPersonalPerformance : l.agentActivityResults,
            subtitle: l.agentActivityResultsSummary,
          ),
          const SizedBox(height: AppSpacing.sm),
          if (visibleRows.isEmpty)
            SizedBox(
              height: 118,
              child: DashboardChartEmptyState(
                message: analytics.teamPerformance.isLimited
                    ? l.dashboardPerformanceLimitedForRole
                    : l.dashboardNotEnoughData,
              ),
            )
          else if (mobile)
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var index = 0; index < visibleRows.length; index++) ...[
                  _AgentActivityDashboardCard(
                    row: visibleRows[index],
                    maxScore: maxScore,
                  ),
                  if (index != visibleRows.length - 1)
                    const SizedBox(height: AppSpacing.xs),
                ],
              ],
            )
          else
            SizedBox(
              height: 330,
              child: Scrollbar(
                thumbVisibility: visibleRows.length > 3,
                child: ListView.separated(
                  padding: EdgeInsets.zero,
                  physics: const BouncingScrollPhysics(),
                  itemCount: visibleRows.length,
                  separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.xs),
                  itemBuilder: (context, index) {
                    return _AgentActivityDashboardCard(
                      row: visibleRows[index],
                      maxScore: maxScore,
                    )
                        .animate(delay: Duration(milliseconds: 70 * math.min(index, 6)))
                        .fadeIn(duration: 700.ms, curve: Curves.easeOutCubic)
                        .slideY(begin: 0.035, end: 0);
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AgentActivityDashboardCard extends StatelessWidget {
  const _AgentActivityDashboardCard({required this.row, required this.maxScore});

  final DashboardTeamPerformanceRow row;
  final num maxScore;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final score = _teamScore(row);
    final completionPercent = row.conversionPercent ?? 0;
    final color = completionPercent >= 80
        ? AppColors.successColor(context)
        : completionPercent >= 40
            ? AppColors.warningColor(context)
            : AppColors.errorColor(context);

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
          Row(
            children: [
              _InitialsAvatar(name: row.name, size: 34),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      row.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${row.leads} ${l.leads} · ${row.tasks} ${l.tasks} · ${row.deals} ${l.deals}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.textSecondaryColor(context),
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ],
                ),
              ),
              Text(
                '$completionPercent%',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _CompactAgentMetric(label: l.leads, value: row.leads),
              _CompactAgentMetric(label: l.tasks, value: row.tasks),
              _CompactAgentMetric(label: l.completedTasks, value: row.completedTasks),
              _CompactAgentMetric(label: l.appointments, value: row.appointments),
              _CompactAgentMetric(label: l.deals, value: row.deals),
              _CompactAgentMetric(label: l.wonDeals, value: row.wonDeals),
              if (row.overdueTasks > 0)
                _CompactAgentMetric(label: l.overdueTasks, value: row.overdueTasks),
              _CompactAgentMoney(label: l.dashboardTeamPipeline, value: row.pipelineValue),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: math.min(score / math.max(maxScore, 1), 1).toDouble(),
              minHeight: 5,
              backgroundColor: AppColors.borderColor(context),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactAgentMetric extends StatelessWidget {
  const _CompactAgentMetric({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.cardSurface(context),
        border: Border.all(color: AppColors.borderColor(context)),
        borderRadius: AppRadius.medium,
      ),
      child: Text(
        '$value $label',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondaryColor(context),
            ),
      ),
    );
  }
}

class _CompactAgentMoney extends StatelessWidget {
  const _CompactAgentMoney({required this.label, required this.value});

  final String label;
  final num value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.primaryColor(context).withValues(alpha: 0.08),
        border: Border.all(color: AppColors.primaryColor(context).withValues(alpha: 0.20)),
        borderRadius: AppRadius.medium,
      ),
      child: Text(
        '${_formatMoney(context, value)} $label',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.primaryColor(context),
            ),
      ),
    );
  }
}

num _teamScore(DashboardTeamPerformanceRow row) {
  return row.pipelineValue +
      (row.wonDeals * 150000) +
      (row.deals * 100000) +
      (row.completedTasks * 45000) +
      (row.appointments * 35000) +
      (row.leads * 20000) +
      (row.activeRecords * 15000) -
      (row.overdueTasks * 60000);
}

class DashboardOpportunitiesStrip extends StatefulWidget {
  const DashboardOpportunitiesStrip({
    super.key,
    required this.analytics,
    required this.platformPreview,
  });

  final DashboardAnalytics analytics;
  final bool platformPreview;

  @override
  State<DashboardOpportunitiesStrip> createState() => _DashboardOpportunitiesStripState();
}

class _DashboardOpportunitiesStripState extends State<DashboardOpportunitiesStrip> {
  final ScrollController _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final opportunities = widget.analytics.importantOpportunities.take(5).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final vertical = constraints.maxWidth < 620;
        return _DashboardCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _CardHeader(
                title: l.dashboardImportantOpportunities,
                trailing: widget.platformPreview
                    ? null
                    : TextButton(
                        onPressed: () =>
                            context.go(RouteNames.filteredDeals(queue: 'open')),
                        child: Text(l.viewAll),
                      ),
              ),
              const SizedBox(height: AppSpacing.sm),
              if (opportunities.isEmpty)
                SizedBox(
                  height: 94,
                  child: DashboardChartEmptyState(message: l.dashboardNoOpportunities),
                )
              else if (vertical)
                SizedBox(
                  height: 132,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: opportunities.length,
                    separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.xs),
                    itemBuilder: (context, index) {
                      return SizedBox(
                        width: math.min(232.0, MediaQuery.sizeOf(context).width * 0.68),
                        child: _OpportunityCard(
                          item: opportunities[index],
                          platformPreview: widget.platformPreview,
                        )
                            .animate(delay: Duration(milliseconds: 45 * index))
                            .fadeIn(duration: 320.ms, curve: Curves.easeOutCubic)
                            .slideX(begin: 0.035, end: 0),
                      );
                    },
                  ),
                )
              else
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsetsDirectional.symmetric(horizontal: 34),
                      child: SingleChildScrollView(
                        controller: _controller,
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: [
                            for (var index = 0; index < opportunities.length; index++) ...[
                              SizedBox(
                                width: 178,
                                child: _OpportunityCard(
                                  item: opportunities[index],
                                  platformPreview: widget.platformPreview,
                                ),
                              ),
                              if (index != opportunities.length - 1)
                                const SizedBox(width: AppSpacing.sm),
                            ],
                          ],
                        ),
                      ),
                    ),
                    if (opportunities.length > 1) ...[
                      PositionedDirectional(
                        start: 0,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: _RailRoundButton(
                            icon: Icons.chevron_left_rounded,
                            onTap: () => _scrollBy(-210),
                          ),
                        ),
                      ),
                      PositionedDirectional(
                        end: 0,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: _RailRoundButton(
                            icon: Icons.chevron_right_rounded,
                            onTap: () => _scrollBy(210),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  void _scrollBy(double delta) {
    if (!_controller.hasClients) return;
    final target = (_controller.offset + delta).clamp(
      _controller.position.minScrollExtent,
      _controller.position.maxScrollExtent,
    );
    _controller.animateTo(
      target.toDouble(),
      duration: 420.ms,
      curve: Curves.easeOutCubic,
    );
  }
}

class DashboardDailyInsightCard extends StatelessWidget {
  const DashboardDailyInsightCard({
    super.key,
    required this.insight,
    this.platformPreview = false,
  });

  final DashboardDailyInsight insight;
  final bool platformPreview;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final color = AppColors.primaryColor(context);
    final route = platformPreview ? null : _dailyInsightRoute(insight.type);
    return _DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(
            title: l.dashboardDailyInsight,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _SoftIcon(icon: Icons.lightbulb_outline_rounded, color: color),
                const SizedBox(width: 4),
                IconButton(
                  tooltip: l.actions,
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _showDailyInsightDrawer(
                    context,
                    insight,
                    platformPreview: platformPreview,
                  ),
                  icon: const Icon(Icons.more_horiz_rounded, size: 18),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            _dailyInsightText(l, insight),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textPrimaryColor(context),
                  fontWeight: FontWeight.w400,
                  height: 1.45,
                ),
          ),
          if (route != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                onPressed: () => context.go(route),
                icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                label: Text(l.viewDetails),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

String? _dailyInsightRoute(DashboardDailyInsightType type) {
  return switch (type) {
    DashboardDailyInsightType.staleLeads =>
      RouteNames.filteredLeads(queue: 'stale'),
    DashboardDailyInsightType.conversionUp => RouteNames.reports,
    DashboardDailyInsightType.calm || DashboardDailyInsightType.notEnoughData => null,
  };
}

enum _CommandFilter { all, dueToday, hot, atRisk }

class DashboardSmartSuggestionsStrip extends StatefulWidget {
  const DashboardSmartSuggestionsStrip({
    super.key,
    required this.summary,
    required this.authState,
    required this.platformPreview,
  });

  final SalesCommandSummary summary;
  final AuthState authState;
  final bool platformPreview;

  @override
  State<DashboardSmartSuggestionsStrip> createState() => _DashboardSmartSuggestionsStripState();
}

class _DashboardSmartSuggestionsStripState extends State<DashboardSmartSuggestionsStrip> {
  final ScrollController _controller = ScrollController();
  _CommandFilter _filter = _CommandFilter.all;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final topItems = _topCommandItems(widget.summary);
    final items = _filteredCommandItems(topItems, _filter).take(10).toList();

    return _DashboardCard(
      padding: const EdgeInsetsDirectional.fromSTEB(12, 10, 12, 10),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 720;
          if (isMobile) {
            return _buildMobileCommandCenter(context, l, topItems, items);
          }
          return _buildDesktopCommandCenter(context, l, items);
        },
      ),
    );
  }

  Widget _buildMobileCommandCenter(
    BuildContext context,
    AppLocalizations l,
    List<SalesCommandItem> topItems,
    List<SalesCommandItem> items,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.salesCommandCenterTitle,
                    maxLines: 2,
                    overflow: TextOverflow.visible,
                    softWrap: true,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          height: 1.1,
                        ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _mobileCommandSubtitle(l, widget.summary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.textSecondaryColor(context),
                          fontWeight: FontWeight.w500,
                          height: 1.18,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            _CommandLegendButton(),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        _MobileCommandFilterSelector(
          label: _commandFilterLabel(l, _filter),
          icon: _commandFilterIcon(_filter),
          badge: _commandBadge(_commandFilterCount(topItems, _filter)),
          onTap: () => _showCommandFilterSheet(context, topItems),
        ),
        const SizedBox(height: AppSpacing.sm),
        _MobileOperationalGroupStrip(
          summary: widget.summary,
          platformPreview: widget.platformPreview,
        ),
        const SizedBox(height: AppSpacing.sm),
        if (items.isEmpty)
          _InlineEmptyMessage(
            icon: Icons.check_circle_outline_rounded,
            message: widget.summary.isLimitedForRole
                ? l.salesCommandLimitedMessage
                : l.salesCommandEmptyMessage,
          )
        else
          _MobileSmartSuggestionGrid(
            items: items,
            authState: widget.authState,
            platformPreview: widget.platformPreview,
          ),
      ],
    );
  }

  Future<void> _showCommandFilterSheet(
    BuildContext context,
    List<SalesCommandItem> topItems,
  ) async {
    final selected = await showModalBottomSheet<_CommandFilter>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      backgroundColor: AppColors.cardSurface(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (sheetContext) {
        final l = AppLocalizations.of(sheetContext)!;
        final options = [
          _CommandFilterSheetOption(
            filter: _CommandFilter.all,
            label: l.viewAll,
            subtitle: l.salesCommandCenterTitle,
            icon: Icons.dashboard_outlined,
            count: topItems.length,
          ),
          _CommandFilterSheetOption(
            filter: _CommandFilter.dueToday,
            label: l.salesCommandMetricDueToday,
            subtitle: l.salesCommandReasonDueTodayFollowUp,
            icon: Icons.event_available_outlined,
            count: _filteredCommandItems(
              topItems,
              _CommandFilter.dueToday,
            ).length,
          ),
          _CommandFilterSheetOption(
            filter: _CommandFilter.hot,
            label: l.salesCommandMetricHot,
            subtitle: l.salesCommandReasonHotLead,
            icon: Icons.local_fire_department_outlined,
            count: _filteredCommandItems(topItems, _CommandFilter.hot).length,
          ),
          _CommandFilterSheetOption(
            filter: _CommandFilter.atRisk,
            label: l.dashboardKpiOverdueActions,
            subtitle: l.salesCommandReasonOverdueFollowUp,
            icon: Icons.report_problem_outlined,
            count: _filteredCommandItems(topItems, _CommandFilter.atRisk).length,
          ),
        ];

        return SafeArea(
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              AppSpacing.md,
              AppSpacing.xs,
              AppSpacing.md,
              AppSpacing.md,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l.salesCommandCenterTitle,
                  style: Theme.of(sheetContext).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: AppSpacing.sm),
                for (final option in options) ...[
                  _CommandFilterSheetTile(
                    option: option,
                    selected: option.filter == _filter,
                    onTap: () => Navigator.of(sheetContext).pop(option.filter),
                  ),
                  if (option != options.last)
                    const SizedBox(height: AppSpacing.xs),
                ],
              ],
            ),
          ),
        );
      },
    );

    if (selected != null && mounted) {
      setState(() => _filter = selected);
    }
  }

  Widget _buildDesktopCommandCenter(
    BuildContext context,
    AppLocalizations l,
    List<SalesCommandItem> items,
  ) {
    final filters = [
      _CommandFilterButton(
        selected: _filter == _CommandFilter.all,
        label: l.viewAll,
        onTap: () => setState(() => _filter = _CommandFilter.all),
      ),
      _CommandFilterButton(
        selected: _filter == _CommandFilter.dueToday,
        label: l.salesCommandMetricDueToday,
        onTap: () => setState(() => _filter = _CommandFilter.dueToday),
      ),
      _CommandFilterButton(
        selected: _filter == _CommandFilter.hot,
        label: l.salesCommandMetricHot,
        onTap: () => setState(() => _filter = _CommandFilter.hot),
      ),
      _CommandFilterButton(
        selected: _filter == _CommandFilter.atRisk,
        label: l.dashboardKpiOverdueActions,
        onTap: () => setState(() => _filter = _CommandFilter.atRisk),
      ),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _CardHeader(
          title: l.salesCommandCenterTitle,
          trailing: Wrap(
            spacing: 5,
            runSpacing: 5,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _CommandLegendButton(),
              ...filters,
            ],
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 5,
          runSpacing: 5,
          children: [
            _CompactMetricPill(
              label: l.dashboardKpiDueTodayFollowUps,
              value: widget.summary.dueTodayCount,
              tone: AppStatusTone.warning,
              route: widget.platformPreview
                  ? null
                  : RouteNames.filteredLeads(followUp: 'dueToday'),
            ),
            _CompactMetricPill(
              label: l.salesCommandMetricHot,
              value: widget.summary.hotOpportunityCount,
              tone: AppStatusTone.info,
              route: widget.platformPreview
                  ? null
                  : RouteNames.filteredLeads(queue: 'hot'),
            ),
            _CompactMetricPill(
              label: l.dashboardOverdueFollowUps,
              value: widget.summary.overdueCount,
              tone: AppStatusTone.error,
              route: widget.platformPreview
                  ? null
                  : RouteNames.filteredLeads(followUp: 'overdue'),
            ),
            _CompactMetricPill(
              label: l.dashboardDealRisks,
              value: widget.summary.atRiskCount,
              tone: AppStatusTone.error,
              route: widget.platformPreview
                  ? null
                  : RouteNames.filteredDeals(queue: 'atRisk'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _OperationalCommandGroups(
          summary: widget.summary,
          platformPreview: widget.platformPreview,
        ),
        const SizedBox(height: 8),
        if (items.isEmpty)
          _InlineEmptyMessage(
            icon: Icons.check_circle_outline_rounded,
            message: widget.summary.isLimitedForRole
                ? l.salesCommandLimitedMessage
                : l.salesCommandEmptyMessage,
          )
        else
          SizedBox(
            height: 104,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Padding(
                  padding: const EdgeInsetsDirectional.symmetric(horizontal: 34),
                  child: ListView.separated(
                    controller: _controller,
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      return SizedBox(
                        width: 248,
                        child: _SmartSuggestionCard(
                          item: items[index],
                          authState: widget.authState,
                          platformPreview: widget.platformPreview,
                        ),
                      )
                          .animate(delay: Duration(milliseconds: 120 * index))
                          .fadeIn(duration: 920.ms, curve: Curves.easeOutCubic)
                          .slideX(begin: 0.05, end: 0);
                    },
                  ),
                ),
                if (items.length > 1) ...[
                  PositionedDirectional(
                    start: 0,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: _RailRoundButton(
                        icon: Icons.chevron_left_rounded,
                        onTap: () => _scrollBy(-260),
                      ),
                    ),
                  ),
                  PositionedDirectional(
                    end: 0,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: _RailRoundButton(
                        icon: Icons.chevron_right_rounded,
                        onTap: () => _scrollBy(260),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }

  void _scrollBy(double offset) {
    if (!_controller.hasClients) return;
    final target = (_controller.offset + offset).clamp(
      _controller.position.minScrollExtent,
      _controller.position.maxScrollExtent,
    );
    _controller.animateTo(
      target.toDouble(),
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
    );
  }
}


class _MobileCommandFilterSelector extends StatelessWidget {
  const _MobileCommandFilterSelector({
    required this.label,
    required this.icon,
    required this.onTap,
    this.badge,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final primary = AppColors.primaryColor(context);
    final isDark = AppColors.isDark(context);
    return Material(
      color: AppColors.inputSurface(context),
      borderRadius: AppRadius.xLarge,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.xLarge,
        child: Container(
          constraints: const BoxConstraints(minHeight: 46),
          padding: const EdgeInsetsDirectional.fromSTEB(10, 7, 10, 7),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.borderColor(context)),
            borderRadius: AppRadius.xLarge,
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: isDark ? 0.18 : 0.12),
                  borderRadius: AppRadius.medium,
                ),
                child: Icon(icon, color: primary, size: 18),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                      ),
                ),
              ),
              if (badge != null) ...[
                const SizedBox(width: AppSpacing.xs),
                _FilterCountBadge(value: badge!),
              ],
              const SizedBox(width: AppSpacing.xs),
              Icon(
                Icons.tune_rounded,
                color: AppColors.textSecondaryColor(context),
                size: 18,
              ),
              const SizedBox(width: 2),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppColors.textSecondaryColor(context),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CommandFilterSheetOption {
  const _CommandFilterSheetOption({
    required this.filter,
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.count,
  });

  final _CommandFilter filter;
  final String label;
  final String subtitle;
  final IconData icon;
  final int count;
}

class _CommandFilterSheetTile extends StatelessWidget {
  const _CommandFilterSheetTile({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final _CommandFilterSheetOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = AppColors.primaryColor(context);
    return Material(
      color: selected
          ? primary.withValues(alpha: 0.14)
          : AppColors.inputSurface(context),
      borderRadius: AppRadius.large,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.large,
        child: Container(
          padding: const EdgeInsetsDirectional.fromSTEB(12, 10, 12, 10),
          decoration: BoxDecoration(
            borderRadius: AppRadius.large,
            border: Border.all(
              color: selected
                  ? primary.withValues(alpha: 0.36)
                  : AppColors.borderColor(context),
            ),
          ),
          child: Row(
            children: [
              Icon(option.icon, size: 19, color: selected ? primary : AppColors.textSecondaryColor(context)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      option.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: selected ? primary : AppColors.textPrimaryColor(context),
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      option.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.textSecondaryColor(context),
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              _FilterCountBadge(value: option.count.toString()),
              if (selected) ...[
                const SizedBox(width: AppSpacing.xs),
                Icon(Icons.check_circle_rounded, color: primary, size: 18),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterCountBadge extends StatelessWidget {
  const _FilterCountBadge({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
      alignment: Alignment.center,
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 7),
      decoration: BoxDecoration(
        color: AppColors.errorColor(context).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.errorColor(context).withValues(alpha: 0.28)),
      ),
      child: Text(
        value,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.errorColor(context),
              fontWeight: FontWeight.w900,
              height: 1,
            ),
      ),
    );
  }
}

String _commandFilterLabel(AppLocalizations l, _CommandFilter filter) {
  return switch (filter) {
    _CommandFilter.all => l.viewAll,
    _CommandFilter.dueToday => l.salesCommandMetricDueToday,
    _CommandFilter.hot => l.salesCommandMetricHot,
    _CommandFilter.atRisk => l.dashboardKpiOverdueActions,
  };
}

IconData _commandFilterIcon(_CommandFilter filter) {
  return switch (filter) {
    _CommandFilter.all => Icons.dashboard_outlined,
    _CommandFilter.dueToday => Icons.event_available_outlined,
    _CommandFilter.hot => Icons.local_fire_department_outlined,
    _CommandFilter.atRisk => Icons.report_problem_outlined,
  };
}

int _commandFilterCount(
  List<SalesCommandItem> topItems,
  _CommandFilter filter,
) {
  return switch (filter) {
    _CommandFilter.all => topItems.length,
    _CommandFilter.dueToday ||
    _CommandFilter.hot ||
    _CommandFilter.atRisk =>
      _filteredCommandItems(topItems, filter).length,
  };
}


class _MobileCommandFilterTabData {
  const _MobileCommandFilterTabData({
    required this.filter,
    required this.label,
    required this.icon,
    this.badge,
  });

  final _CommandFilter filter;
  final String label;
  final IconData icon;
  final String? badge;
}

class _MobileCommandFilterTabs extends StatelessWidget {
  const _MobileCommandFilterTabs({
    required this.tabs,
    required this.selectedFilter,
    required this.onChanged,
  });

  final List<_MobileCommandFilterTabData> tabs;
  final _CommandFilter selectedFilter;
  final ValueChanged<_CommandFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    if (tabs.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = AppSpacing.xs;
        final columns = constraints.maxWidth >= 620 ? tabs.length : 2;
        final itemWidth =
            (constraints.maxWidth - (columns - 1) * gap) / columns;

        return DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.inputSurface(context).withValues(alpha: 0.58),
            border: Border.all(color: AppColors.borderColor(context)),
            borderRadius: AppRadius.xLarge,
          ),
          child: Padding(
            padding: const EdgeInsets.all(5),
            child: Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final tab in tabs)
                  SizedBox(
                    width: itemWidth - 3,
                    child: _MobileCommandFilterTabButton(
                      data: tab,
                      selected: tab.filter == selectedFilter,
                      onTap: () => onChanged(tab.filter),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MobileCommandFilterTabButton extends StatelessWidget {
  const _MobileCommandFilterTabButton({
    required this.data,
    required this.selected,
    required this.onTap,
  });

  final _MobileCommandFilterTabData data;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = AppColors.primaryColor(context);
    final foreground = selected
        ? (AppColors.isDark(context) ? const Color(0xFF050505) : AppColors.textStrong)
        : AppColors.textSecondaryColor(context);

    return Material(
      color: selected ? primary : Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 190),
          curve: Curves.easeOutCubic,
          constraints: const BoxConstraints(minHeight: 46),
          padding: const EdgeInsetsDirectional.fromSTEB(9, 7, 8, 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? Colors.white.withValues(alpha: 0.22)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              Icon(data.icon, size: 17, color: foreground),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  data.label,
                  maxLines: 2,
                  overflow: TextOverflow.visible,
                  softWrap: true,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: foreground,
                        fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                        fontSize: 10.2,
                        height: 1.05,
                      ),
                ),
              ),
              if (data.badge != null) ...[
                const SizedBox(width: 5),
                Container(
                  constraints: const BoxConstraints(minWidth: 21, minHeight: 21),
                  padding: const EdgeInsetsDirectional.symmetric(horizontal: 5),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected
                        ? Colors.white.withValues(alpha: 0.32)
                        : AppColors.errorColor(context).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: selected
                          ? Colors.white.withValues(alpha: 0.48)
                          : AppColors.errorColor(context).withValues(alpha: 0.28),
                    ),
                  ),
                  child: Text(
                    data.badge!,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: selected ? foreground : AppColors.errorColor(context),
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          height: 1,
                        ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MobileOperationalGroupStrip extends StatelessWidget {
  const _MobileOperationalGroupStrip({
    required this.summary,
    required this.platformPreview,
  });

  final SalesCommandSummary summary;
  final bool platformPreview;

  @override
  Widget build(BuildContext context) {
    final groups = [
      summary.section(SalesCommandSectionType.overdueFollowUps),
      summary.section(SalesCommandSectionType.missedAppointments),
      summary.section(SalesCommandSectionType.overdueTasks),
      summary.section(SalesCommandSectionType.stuckDeals),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth * 0.46)
            .clamp(148.0, 176.0)
            .toDouble();
        return SizedBox(
          height: 104,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: groups.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.xs),
            itemBuilder: (context, index) {
              return SizedBox(
                width: itemWidth,
                child: _OperationalGroupCard(
                  section: groups[index],
                  platformPreview: platformPreview,
                  compact: true,
                )
                    .animate(delay: Duration(milliseconds: 45 * index))
                    .fadeIn(duration: 300.ms, curve: Curves.easeOutCubic)
                    .slideX(begin: 0.035, end: 0),
              );
            },
          ),
        );
      },
    );
  }
}

class _MobileSmartSuggestionGrid extends StatelessWidget {
  const _MobileSmartSuggestionGrid({
    required this.items,
    required this.authState,
    required this.platformPreview,
  });

  final List<SalesCommandItem> items;
  final AuthState authState;
  final bool platformPreview;

  @override
  Widget build(BuildContext context) {
    final visibleItems = items.take(6).toList();
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = AppSpacing.xs;
        final width = (constraints.maxWidth - gap) / 2;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (var index = 0; index < visibleItems.length; index++)
              SizedBox(
                width: width,
                child: _MobileCommandActionCard(
                  item: visibleItems[index],
                  authState: authState,
                  platformPreview: platformPreview,
                )
                    .animate(delay: Duration(milliseconds: 45 * math.min(index, 6)))
                    .fadeIn(duration: 320.ms, curve: Curves.easeOutCubic)
                    .slideY(begin: 0.025, end: 0),
              ),
          ],
        );
      },
    );
  }
}

class _MobileCommandActionCard extends StatelessWidget {
  const _MobileCommandActionCard({
    required this.item,
    required this.authState,
    required this.platformPreview,
  });

  final SalesCommandItem item;
  final AuthState authState;
  final bool platformPreview;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final color = _commandPriorityColor(context, item.priority);
    final title = _fallback(item.title, _commandModuleLabel(l, item.module));
    final reason = _commandReasonText(l, item);

    return Material(
      color: AppColors.inputSurface(context),
      borderRadius: AppRadius.large,
      child: InkWell(
        onTap: platformPreview
            ? null
            : () => _showWorkQueueActionDrawer(
                  context,
                  item: item,
                  authState: authState,
                ),
        borderRadius: AppRadius.large,
        child: Container(
          constraints: const BoxConstraints(minHeight: 108),
          padding: const EdgeInsetsDirectional.fromSTEB(9, 9, 9, 9),
          decoration: BoxDecoration(
            border: Border.all(color: color.withValues(alpha: 0.30)),
            borderRadius: AppRadius.large,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.visible,
                      softWrap: true,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: color,
                            fontWeight: FontWeight.w800,
                            height: 1.08,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              AppStatusBadge(
                label: _commandModuleLabel(l, item.module),
                tone: AppStatusTone.neutral,
              ),
              const SizedBox(height: 6),
              Text(
                reason,
                maxLines: 2,
                overflow: TextOverflow.visible,
                softWrap: true,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textSecondaryColor(context),
                      fontWeight: FontWeight.w500,
                      height: 1.12,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                _commandTimeLabel(context, item),
                maxLines: 1,
                overflow: TextOverflow.fade,
                softWrap: false,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textMutedColor(context),
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _mobileCommandSubtitle(AppLocalizations l, SalesCommandSummary summary) {
  if (summary.overdueCount > 0 || summary.atRiskCount > 0) {
    return l.salesCommandAtRiskSubtitle;
  }
  if (summary.dueTodayCount > 0) {
    return l.salesCommandReasonDueTodayFollowUp;
  }
  if (summary.hotOpportunityCount > 0) {
    return l.salesCommandReasonHotLead;
  }
  return l.salesCommandEmptyMessage;
}

String? _commandBadge(int value) {
  if (value <= 0) {
    return null;
  }
  return value > 99 ? '99+' : value.toString();
}

class _OperationalCommandGroups extends StatelessWidget {
  const _OperationalCommandGroups({
    required this.summary,
    required this.platformPreview,
  });

  final SalesCommandSummary summary;
  final bool platformPreview;

  @override
  Widget build(BuildContext context) {
    final groups = [
      summary.section(SalesCommandSectionType.overdueFollowUps),
      summary.section(SalesCommandSectionType.missedAppointments),
      summary.section(SalesCommandSectionType.overdueTasks),
      summary.section(SalesCommandSectionType.stuckDeals),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 8.0;
        final compact = constraints.maxWidth < 620;
        final itemWidth = compact
            ? (constraints.maxWidth * 0.46).clamp(148.0, 176.0).toDouble()
            : constraints.maxWidth >= 980
                ? 238.0
                : 212.0;
        final height = compact ? 104.0 : 82.0;

        return SizedBox(
          height: height,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: groups.length,
            separatorBuilder: (_, __) => const SizedBox(width: gap),
            itemBuilder: (context, index) {
              return SizedBox(
                width: itemWidth,
                child: _OperationalGroupCard(
                  section: groups[index],
                  platformPreview: platformPreview,
                  compact: compact,
                )
                    .animate(delay: Duration(milliseconds: 55 * index))
                    .fadeIn(duration: 320.ms, curve: Curves.easeOutCubic)
                    .slideX(begin: 0.035, end: 0),
              );
            },
          ),
        );
      },
    );
  }
}

class _OperationalGroupCard extends StatefulWidget {
  const _OperationalGroupCard({
    required this.section,
    required this.platformPreview,
    this.compact = false,
  });

  final SalesCommandSection section;
  final bool platformPreview;
  final bool compact;

  @override
  State<_OperationalGroupCard> createState() => _OperationalGroupCardState();
}

class _OperationalGroupCardState extends State<_OperationalGroupCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final section = widget.section;
    final l = AppLocalizations.of(context)!;
    final tone = _operationalGroupTone(section.type);
    final color = _toneColor(context, tone);
    final route = widget.platformPreview ? null : _operationalGroupRoute(section.type);
    final enabled = route != null && section.count > 0;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        scale: _hovered && enabled ? 1.015 : 1,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        child: Material(
          color: AppColors.inputSurface(context),
          borderRadius: AppRadius.large,
          child: InkWell(
            onTap: enabled ? () => context.go(route) : null,
            borderRadius: AppRadius.large,
            child: Container(
              constraints: BoxConstraints(minHeight: widget.compact ? 92 : 74),
              padding: EdgeInsetsDirectional.fromSTEB(
                widget.compact ? 9 : 10,
                widget.compact ? 9 : 9,
                widget.compact ? 9 : 10,
                widget.compact ? 9 : 9,
              ),
              decoration: BoxDecoration(
                border: Border.all(
                  color: section.count > 0
                      ? color.withValues(alpha: 0.34)
                      : AppColors.borderColor(context),
                ),
                borderRadius: AppRadius.large,
              ),
              child: widget.compact
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.10),
                                borderRadius: AppRadius.medium,
                              ),
                              child: Icon(
                                _operationalGroupIcon(section.type),
                                color: color,
                                size: 17,
                              ),
                            ),
                            const Spacer(),
                            _UrgentCountBadge(
                              value: section.count,
                              tone: section.count > 0 ? tone : AppStatusTone.neutral,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _operationalGroupTitle(l, section.type),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          softWrap: true,
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                height: 1.12,
                              ),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.10),
                            borderRadius: AppRadius.medium,
                          ),
                          child: Icon(
                            _operationalGroupIcon(section.type),
                            color: color,
                            size: 17,
                          ),
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _operationalGroupTitle(l, section.type),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      height: 1.1,
                                    ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                _operationalGroupSubtitle(l, section.type),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: AppColors.textSecondaryColor(context),
                                      fontWeight: FontWeight.w400,
                                      height: 1.12,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        _UrgentCountBadge(
                          value: section.count,
                          tone: section.count > 0 ? tone : AppStatusTone.neutral,
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

class _UrgentCountBadge extends StatelessWidget {
  const _UrgentCountBadge({required this.value, required this.tone});

  final int value;
  final AppStatusTone tone;

  @override
  Widget build(BuildContext context) {
    final color = _toneColor(context, tone);
    final badge = Container(
      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
      alignment: Alignment.center,
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.32)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        value.toString(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
      ),
    );
    if (value <= 0 || tone != AppStatusTone.error) {
      return badge;
    }
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeInOut,
      builder: (context, t, child) {
        return Transform.scale(
          scale: 1 + (math.sin(t * math.pi) * 0.035),
          child: child,
        );
      },
      child: badge,
    );
  }
}

String _operationalGroupTitle(
  AppLocalizations l,
  SalesCommandSectionType type,
) {
  return switch (type) {
    SalesCommandSectionType.overdueFollowUps => l.dashboardOverdueFollowUps,
    SalesCommandSectionType.missedAppointments => l.missedAppointments,
    SalesCommandSectionType.overdueTasks => l.dashboardOverdueTasks,
    SalesCommandSectionType.stuckDeals => l.dashboardDealRisks,
    _ => l.salesCommandMetricRisk,
  };
}

String _operationalGroupSubtitle(
  AppLocalizations l,
  SalesCommandSectionType type,
) {
  return switch (type) {
    SalesCommandSectionType.overdueFollowUps =>
      l.salesCommandReasonOverdueFollowUp,
    SalesCommandSectionType.missedAppointments =>
      l.salesCommandReasonAppointmentMissed,
    SalesCommandSectionType.overdueTasks => l.salesCommandReasonOverdueTask,
    SalesCommandSectionType.stuckDeals => l.salesCommandAtRiskSubtitle,
    _ => l.salesCommandAtRiskSubtitle,
  };
}

IconData _operationalGroupIcon(SalesCommandSectionType type) {
  return switch (type) {
    SalesCommandSectionType.overdueFollowUps => Icons.phone_missed_outlined,
    SalesCommandSectionType.missedAppointments => Icons.event_busy_outlined,
    SalesCommandSectionType.overdueTasks => Icons.assignment_late_outlined,
    SalesCommandSectionType.stuckDeals => Icons.hourglass_bottom_outlined,
    _ => Icons.report_problem_outlined,
  };
}

String? _operationalGroupRoute(SalesCommandSectionType type) {
  return switch (type) {
    SalesCommandSectionType.overdueFollowUps =>
      RouteNames.filteredLeads(followUp: 'overdue'),
    SalesCommandSectionType.missedAppointments =>
      RouteNames.filteredAppointments(date: 'missed'),
    SalesCommandSectionType.overdueTasks => RouteNames.filteredTasks(due: 'overdue'),
    SalesCommandSectionType.stuckDeals => RouteNames.filteredDeals(queue: 'atRisk'),
    _ => null,
  };
}

AppStatusTone _operationalGroupTone(SalesCommandSectionType type) {
  return switch (type) {
    SalesCommandSectionType.overdueFollowUps ||
    SalesCommandSectionType.missedAppointments ||
    SalesCommandSectionType.overdueTasks ||
    SalesCommandSectionType.stuckDeals =>
      AppStatusTone.error,
    _ => AppStatusTone.warning,
  };
}

class _CommandFilterButton extends StatelessWidget {
  const _CommandFilterButton({
    required this.selected,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primaryColor(context).withValues(alpha: 0.16)
              : AppColors.inputSurface(context),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? AppColors.primaryColor(context).withValues(alpha: 0.42)
                : AppColors.borderColor(context),
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: selected
                    ? AppColors.primaryColor(context)
                    : AppColors.textSecondaryColor(context),
                fontWeight: FontWeight.w500,
              ),
        ),
      ),
    );
  }
}

class _CommandLegendButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Tooltip(
      message: l.dashboardCommandLegendTooltip,
      child: Container(
        height: 30,
        width: 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.inputSurface(context),
          border: Border.all(color: AppColors.borderColor(context)),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Icon(
          Icons.info_outline_rounded,
          size: 16,
          color: AppColors.textSecondaryColor(context),
        ),
      ),
    );
  }
}

class _RailRoundButton extends StatelessWidget {
  const _RailRoundButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: AppColors.inputSurface(context),
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.borderColor(context)),
        ),
        child: Icon(icon, size: 18, color: AppColors.textSecondaryColor(context)),
      ),
    );
  }
}

List<SalesCommandItem> _filteredCommandItems(
  List<SalesCommandItem> items,
  _CommandFilter filter,
) {
  return switch (filter) {
    _CommandFilter.all => items,
    _CommandFilter.dueToday => items.where((item) {
      return item.reason == DashboardAttentionReason.dueTodayFollowUp ||
          item.reason == DashboardAttentionReason.dueTodayTask ||
          item.reason == DashboardAttentionReason.appointmentDueNow;
    }).toList(),
    _CommandFilter.hot => items.where((item) {
      return item.reason == DashboardAttentionReason.hotLead ||
          item.module == DashboardCommandModule.deal;
    }).toList(),
    _CommandFilter.atRisk => items.where((item) {
      return item.priority == DashboardPriority.high ||
          item.reason == DashboardAttentionReason.staleLead ||
          item.reason == DashboardAttentionReason.dealAtRisk ||
          item.reason == DashboardAttentionReason.appointmentMissed ||
          item.reason == DashboardAttentionReason.overdueFollowUp ||
          item.reason == DashboardAttentionReason.overdueTask;
    }).toList(),
  };
}

class _CompactMetricPill extends StatelessWidget {
  const _CompactMetricPill({
    required this.label,
    required this.value,
    required this.tone,
    this.route,
  });

  final String label;
  final int value;
  final AppStatusTone tone;
  final String? route;

  @override
  Widget build(BuildContext context) {
    final badge = AppStatusBadge(label: '$value $label', tone: tone);
    final targetRoute = route;
    if (targetRoute == null) {
      return badge;
    }
    return InkWell(
      onTap: () => context.go(targetRoute),
      borderRadius: BorderRadius.circular(999),
      child: badge,
    );
  }
}

class _SmartSuggestionCard extends StatelessWidget {
  const _SmartSuggestionCard({
    required this.item,
    required this.authState,
    required this.platformPreview,
  });

  final SalesCommandItem item;
  final AuthState authState;
  final bool platformPreview;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final color = _commandPriorityColor(context, item.priority);

    return Material(
      color: AppColors.inputSurface(context),
      borderRadius: AppRadius.large,
      child: InkWell(
        onTap: platformPreview
            ? null
            : () => _showWorkQueueActionDrawer(
                  context,
                  item: item,
                  authState: authState,
                ),
        borderRadius: AppRadius.large,
        child: Container(
          constraints: const BoxConstraints(minHeight: 96),
          padding: const EdgeInsetsDirectional.fromSTEB(10, 9, 10, 9),
          decoration: BoxDecoration(
            border: Border.all(color: color.withValues(alpha: 0.28)),
            borderRadius: AppRadius.large,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 7,
                height: 7,
                margin: const EdgeInsetsDirectional.only(top: 6),
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _fallback(item.title, _commandModuleLabel(l, item.module)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                  color: color,
                                  fontWeight: FontWeight.w500,
                                  height: 1.05,
                                ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        AppStatusBadge(
                          label: _commandModuleLabel(l, item.module),
                          tone: AppStatusTone.neutral,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _fallback(item.subtitle, _commandReasonText(l, item)),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.textSecondaryColor(context),
                            fontWeight: FontWeight.w400,
                            height: 1.2,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _commandTimeLabel(context, item),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.textMutedColor(context),
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InlineEmptyMessage extends StatelessWidget {
  const _InlineEmptyMessage({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.inputSurface(context),
        borderRadius: AppRadius.large,
        border: Border.all(color: AppColors.borderColor(context)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.successColor(context), size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.textSecondaryColor(context),
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

List<SalesCommandItem> _topCommandItems(SalesCommandSummary summary) {
  final used = <String>{};
  final items = [
    for (final section in summary.sections)
      for (final item in section.items)
        if (used.add(item.recordKey)) item,
  ]..sort((a, b) {
      final priority = _commandPriorityRank(b.priority).compareTo(
        _commandPriorityRank(a.priority),
      );
      if (priority != 0) {
        return priority;
      }
      final score = b.score.compareTo(a.score);
      if (score != 0) {
        return score;
      }
      final aDate = a.sortDate ?? a.dueAt ?? a.relatedDate ?? DateTime(9999);
      final bDate = b.sortDate ?? b.dueAt ?? b.relatedDate ?? DateTime(9999);
      return aDate.compareTo(bDate);
    });
  return items;
}

String _commandModuleLabel(AppLocalizations l, DashboardCommandModule module) {
  return switch (module) {
    DashboardCommandModule.lead => l.salesCommandModuleLead,
    DashboardCommandModule.task => l.salesCommandModuleTask,
    DashboardCommandModule.deal => l.salesCommandModuleDeal,
    DashboardCommandModule.appointment => l.salesCommandModuleAppointment,
    DashboardCommandModule.client => l.salesCommandModuleClient,
    DashboardCommandModule.user => l.salesCommandModuleUser,
    DashboardCommandModule.team => l.salesCommandModuleTeam,
  };
}

String _commandReasonText(AppLocalizations l, SalesCommandItem item) {
  return switch (item.reason) {
    DashboardAttentionReason.overdueFollowUp => l.salesCommandReasonOverdueFollowUp,
    DashboardAttentionReason.dueTodayFollowUp => l.salesCommandReasonDueTodayFollowUp,
    DashboardAttentionReason.overdueTask => l.salesCommandReasonOverdueTask,
    DashboardAttentionReason.dueTodayTask => l.salesCommandReasonDueTodayTask,
    DashboardAttentionReason.staleLead => l.salesCommandReasonStaleLead,
    DashboardAttentionReason.hotLead => l.salesCommandReasonHotLead,
    DashboardAttentionReason.unassignedLead => l.salesCommandReasonUnassignedLead,
    DashboardAttentionReason.appointmentMissed => l.salesCommandReasonAppointmentMissed,
    DashboardAttentionReason.appointmentDueNow => l.salesCommandReasonAppointmentDueNow,
    DashboardAttentionReason.appointmentUpcoming => l.salesCommandReasonAppointmentUpcoming,
    DashboardAttentionReason.appointmentNeedsFeedback => l.salesCommandReasonAppointmentNeedsFeedback,
    DashboardAttentionReason.dealAtRisk => l.dashboardDealRisks,
    DashboardAttentionReason.overloadedAssignee =>
      l.salesCommandReasonOverloadedAssignee(item.count ?? 0),
  };
}

String? _commandRoute(SalesCommandItem item) {
  return switch (item.actionType) {
    DashboardCommandActionType.openLead ||
    DashboardCommandActionType.assignLead =>
      RouteNames.leadDetails(item.recordId),
    DashboardCommandActionType.openTask => RouteNames.taskEdit(item.recordId),
    DashboardCommandActionType.openDeal => RouteNames.dealDetails(item.recordId),
    DashboardCommandActionType.openAppointment =>
      RouteNames.appointmentEdit(item.recordId),
    DashboardCommandActionType.createFollowUp => _taskCreateRouteForCommand(item),
    DashboardCommandActionType.openClient => RouteNames.clientDetails(item.recordId),
    DashboardCommandActionType.openTasks =>
      RouteNames.filteredTasks(due: 'overdue', assignedTo: item.recordId),
  };
}

String? _taskCreateRouteForCommand(SalesCommandItem item) {
  final relatedType = _taskRelatedTypeForCommand(item.module);
  if (relatedType == null || item.recordId.trim().isEmpty) {
    return null;
  }
  return RouteNames.taskCreateFor(
    relatedType: relatedType,
    relatedId: item.recordId,
    relatedTitle: item.title,
    relatedSubtitle: item.subtitle,
    assignedTo: item.assignedTo,
  );
}

String? _appointmentCreateRouteForCommand(SalesCommandItem item) {
  final relatedType = _appointmentRelatedTypeForCommand(item.module);
  if (relatedType == null || item.recordId.trim().isEmpty) {
    return null;
  }
  return RouteNames.appointmentCreateFor(
    relatedType: relatedType,
    relatedId: item.recordId,
    relatedTitle: item.title,
    relatedSubtitle: item.subtitle,
    assignedTo: item.assignedTo,
  );
}

String? _taskRelatedTypeForCommand(DashboardCommandModule module) {
  return switch (module) {
    DashboardCommandModule.lead => 'lead',
    DashboardCommandModule.client => 'client',
    DashboardCommandModule.deal => 'deal',
    DashboardCommandModule.task ||
    DashboardCommandModule.appointment ||
    DashboardCommandModule.user ||
    DashboardCommandModule.team => null,
  };
}

String? _appointmentRelatedTypeForCommand(DashboardCommandModule module) {
  return switch (module) {
    DashboardCommandModule.lead => 'lead',
    DashboardCommandModule.client => 'client',
    DashboardCommandModule.deal => 'deal',
    DashboardCommandModule.task ||
    DashboardCommandModule.appointment ||
    DashboardCommandModule.user ||
    DashboardCommandModule.team => null,
  };
}

Future<void> _showWorkQueueActionDrawer(
  BuildContext context, {
  required SalesCommandItem item,
  required AuthState authState,
}) {
  final l = AppLocalizations.of(context)!;
  final session = authState.protectedCompanySession;
  final role = session?.profile.role;
  final openRoute = _commandRoute(item);
  final canCreateTask = role != null &&
      (role == UserRole.admin || role == UserRole.manager) &&
      PermissionService.can(role, AppPermission.createTask);
  final canCreateAppointment = role != null &&
      PermissionService.can(role, AppPermission.createAppointment);
  final canEditLead = role != null &&
      PermissionService.can(role, AppPermission.editLead) &&
      item.module == DashboardCommandModule.lead;
  final canUpdateTask = role != null &&
      item.module == DashboardCommandModule.task &&
      (role == UserRole.admin ||
          role == UserRole.manager ||
          item.assignedTo == (session?.uid ?? ''));
  final taskRoute = canCreateTask ? _taskCreateRouteForCommand(item) : null;
  final appointmentRoute = canCreateAppointment
      ? _appointmentCreateRouteForCommand(item)
      : null;
  final phone = _commandPhoneCandidate(item);

  return _showDashboardActionDrawer(
    context,
    title: _fallback(item.title, _commandModuleLabel(l, item.module)),
    moduleLabel: _commandModuleLabel(l, item.module),
    assignedUser: _assignedCommandUser(l, item),
    reason: _commandReasonText(l, item),
    timelineLabel: item.dueAt == null ? l.updated : l.dueDate,
    timelineValue: _commandTimeLabel(context, item),
    suggestedAction: _suggestedCommandActionLabel(
      l,
      item,
      canCreateTask: taskRoute != null,
      canCreateAppointment: appointmentRoute != null,
    ),
    actions: [
      if (openRoute != null)
        _DashboardDrawerAction.route(
          label: l.open,
          icon: Icons.open_in_new_rounded,
          route: openRoute,
          style: _DashboardDrawerActionStyle.primary,
          group: _DashboardDrawerActionGroup.primary,
        ),
      if (phone != null)
        _DashboardDrawerAction.callback(
          label: l.dashboardCallPhone,
          icon: Icons.call_outlined,
          onPressed: (rootContext) => _launchCall(rootContext, phone),
        ),
      if (phone != null)
        _DashboardDrawerAction.callback(
          label: l.dashboardOpenWhatsApp,
          icon: Icons.chat_bubble_outline_rounded,
          onPressed: (rootContext) => _launchWhatsApp(rootContext, phone),
        ),
      if (canEditLead)
        _DashboardDrawerAction.callback(
          label: l.markContactedToday,
          icon: Icons.check_circle_outline_rounded,
          group: _DashboardDrawerActionGroup.outcome,
          onPressed: (rootContext) => _applyLeadDrawerOutcome(
            rootContext,
            item: item,
            authState: authState,
            outcome: _LeadDrawerOutcome.contacted,
          ),
        ),
      if (canEditLead)
        _DashboardDrawerAction.callback(
          label: l.dashboardActionNoAnswer,
          icon: Icons.phone_missed_outlined,
          group: _DashboardDrawerActionGroup.outcome,
          onPressed: (rootContext) => _applyLeadDrawerOutcome(
            rootContext,
            item: item,
            authState: authState,
            outcome: _LeadDrawerOutcome.noAnswer,
          ),
        ),
      if (canEditLead)
        _DashboardDrawerAction.callback(
          label: l.dashboardActionInterested,
          icon: Icons.local_fire_department_outlined,
          group: _DashboardDrawerActionGroup.outcome,
          onPressed: (rootContext) => _applyLeadDrawerOutcome(
            rootContext,
            item: item,
            authState: authState,
            outcome: _LeadDrawerOutcome.interested,
          ),
        ),
      if (canEditLead)
        _DashboardDrawerAction.callback(
          label: l.dashboardActionNotInterested,
          icon: Icons.block_outlined,
          style: _DashboardDrawerActionStyle.danger,
          group: _DashboardDrawerActionGroup.outcome,
          onPressed: (rootContext) => _applyLeadDrawerOutcome(
            rootContext,
            item: item,
            authState: authState,
            outcome: _LeadDrawerOutcome.notInterested,
          ),
        ),
      if (canEditLead)
        _DashboardDrawerAction.callback(
          label: l.scheduleFollowUp,
          icon: Icons.event_repeat_outlined,
          group: _DashboardDrawerActionGroup.outcome,
          onPressed: (rootContext) => _scheduleLeadFollowUpFromDrawer(
            rootContext,
            item: item,
            authState: authState,
          ),
        ),
      if (canUpdateTask)
        _DashboardDrawerAction.callback(
          label: l.dashboardActionMarkTaskCompleted,
          icon: Icons.task_alt_rounded,
          group: _DashboardDrawerActionGroup.outcome,
          onPressed: (rootContext) => _markTaskCompletedFromDrawer(
            rootContext,
            item: item,
            authState: authState,
          ),
        ),
      if (taskRoute != null)
        _DashboardDrawerAction.route(
          label: l.createTask,
          icon: Icons.add_task_rounded,
          route: taskRoute,
        ),
      if (appointmentRoute != null)
        _DashboardDrawerAction.route(
          label: l.newAppointment,
          icon: Icons.event_available_outlined,
          route: appointmentRoute,
        ),
    ],
  );
}

Future<void> _showDailyInsightDrawer(
  BuildContext context,
  DashboardDailyInsight insight, {
  required bool platformPreview,
}) {
  final l = AppLocalizations.of(context)!;
  final route = platformPreview ? null : _dailyInsightRoute(insight.type);
  final moduleLabel = switch (insight.type) {
    DashboardDailyInsightType.conversionUp => l.reports,
    DashboardDailyInsightType.staleLeads ||
    DashboardDailyInsightType.calm ||
    DashboardDailyInsightType.notEnoughData => l.leads,
  };
  return _showDashboardActionDrawer(
    context,
    title: l.dashboardDailyInsight,
    moduleLabel: moduleLabel,
    assignedUser: l.notAvailable,
    reason: _dailyInsightText(l, insight),
    timelineLabel: l.updated,
    timelineValue: _compactRelativeTime(context, DateTime.now()),
    suggestedAction: route == null ? l.dashboardNoUrgentActions : l.viewDetails,
    actions: [
      if (route != null)
        _DashboardDrawerAction.route(
          label: l.viewDetails,
          icon: Icons.open_in_new_rounded,
          route: route,
          style: _DashboardDrawerActionStyle.primary,
        ),
    ],
  );
}

String _assignedCommandUser(AppLocalizations l, SalesCommandItem item) {
  final name = item.assignedToName.trim();
  if (name.isNotEmpty) {
    return name;
  }
  if (item.assignedTo.trim().isNotEmpty) {
    return l.assignedUserUnavailable;
  }
  return l.unassigned;
}

String _suggestedCommandActionLabel(
  AppLocalizations l,
  SalesCommandItem item, {
  required bool canCreateTask,
  required bool canCreateAppointment,
}) {
  if (item.reason == DashboardAttentionReason.overdueFollowUp ||
      item.reason == DashboardAttentionReason.dueTodayFollowUp ||
      item.reason == DashboardAttentionReason.staleLead ||
      item.reason == DashboardAttentionReason.hotLead) {
    return l.markContactedToday;
  }
  if (item.reason == DashboardAttentionReason.overdueTask ||
      item.reason == DashboardAttentionReason.dueTodayTask) {
    return l.dashboardActionMarkTaskCompleted;
  }
  if (item.reason == DashboardAttentionReason.appointmentMissed ||
      item.reason == DashboardAttentionReason.appointmentNeedsFeedback) {
    return l.viewDetails;
  }
  if (canCreateTask) {
    return l.createTask;
  }
  if (canCreateAppointment) {
    return l.newAppointment;
  }
  return l.open;
}

enum _DashboardDrawerActionStyle { primary, secondary, danger }

enum _DashboardDrawerActionGroup { primary, secondary, outcome }

class _DashboardDrawerAction {
  const _DashboardDrawerAction._({
    required this.label,
    required this.icon,
    this.route,
    this.onPressed,
    this.style = _DashboardDrawerActionStyle.secondary,
    this.group = _DashboardDrawerActionGroup.secondary,
  });

  factory _DashboardDrawerAction.route({
    required String label,
    required IconData icon,
    required String route,
    _DashboardDrawerActionStyle style = _DashboardDrawerActionStyle.secondary,
    _DashboardDrawerActionGroup? group,
  }) {
    return _DashboardDrawerAction._(
      label: label,
      icon: icon,
      route: route,
      style: style,
      group: group ??
          (style == _DashboardDrawerActionStyle.primary
              ? _DashboardDrawerActionGroup.primary
              : _DashboardDrawerActionGroup.secondary),
    );
  }

  factory _DashboardDrawerAction.callback({
    required String label,
    required IconData icon,
    required Future<bool> Function(BuildContext context) onPressed,
    _DashboardDrawerActionStyle style = _DashboardDrawerActionStyle.secondary,
    _DashboardDrawerActionGroup group = _DashboardDrawerActionGroup.secondary,
  }) {
    return _DashboardDrawerAction._(
      label: label,
      icon: icon,
      onPressed: onPressed,
      style: style,
      group: group,
    );
  }

  final String label;
  final IconData icon;
  final String? route;
  final Future<bool> Function(BuildContext context)? onPressed;
  final _DashboardDrawerActionStyle style;
  final _DashboardDrawerActionGroup group;
}

Future<void> _showDashboardActionDrawer(
  BuildContext context, {
  required String title,
  required String moduleLabel,
  required String assignedUser,
  required String reason,
  required String timelineLabel,
  required String timelineValue,
  required String suggestedAction,
  required List<_DashboardDrawerAction> actions,
}) {
  final l = AppLocalizations.of(context)!;
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) {
      var saving = false;
      return StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          Future<void> runAction(_DashboardDrawerAction action) async {
            if (saving) {
              return;
            }
            final route = action.route;
            if (route != null) {
              Navigator.of(sheetContext).pop();
              context.go(route);
              return;
            }
            final callback = action.onPressed;
            if (callback == null) {
              return;
            }
            setSheetState(() => saving = true);
            final shouldClose = await callback(context);
            if (!sheetContext.mounted) {
              return;
            }
            setSheetState(() => saving = false);
            if (shouldClose) {
              Navigator.of(sheetContext).pop();
            }
          }

          final primaryActions = actions
              .where((action) => action.group == _DashboardDrawerActionGroup.primary)
              .toList();
          final secondaryActions = actions
              .where((action) => action.group == _DashboardDrawerActionGroup.secondary)
              .toList();
          final outcomeActions = actions
              .where((action) => action.group == _DashboardDrawerActionGroup.outcome)
              .toList();

          return SafeArea(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.86,
              ),
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
                ),
                child: Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(
                    AppSpacing.md,
                    AppSpacing.xs,
                    AppSpacing.md,
                    AppSpacing.lg,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(sheetContext).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                          IconButton(
                            tooltip: l.close,
                            onPressed: saving
                                ? null
                                : () => Navigator.of(sheetContext).pop(),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _DrawerSection(
                        title: l.recordTitle,
                        child: Column(
                          children: [
                            _DrawerDetailRow(label: l.module, value: moduleLabel),
                            _DrawerDetailRow(
                              label: l.assignedUser,
                              value: assignedUser,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _DrawerSection(
                        title: l.salesCommandWhyThisAppears,
                        child: Column(
                          children: [
                            _DrawerDetailRow(
                              label: l.salesCommandWhyThisAppears,
                              value: reason,
                            ),
                            _DrawerDetailRow(
                              label: timelineLabel,
                              value: timelineValue,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _DrawerSection(
                        title: l.dashboardSuggestedNextAction,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              suggestedAction,
                              style: Theme.of(sheetContext)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            if (primaryActions.isNotEmpty) ...[
                              const SizedBox(height: AppSpacing.sm),
                              _DrawerActionButtons(
                                actions: primaryActions,
                                saving: saving,
                                runAction: runAction,
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (saving) ...[
                        const SizedBox(height: AppSpacing.md),
                        const Center(
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.4),
                          ),
                        ),
                      ],
                      if (secondaryActions.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.md),
                        _DrawerSection(
                          title: l.actions,
                          child: _DrawerActionButtons(
                            actions: secondaryActions,
                            saving: saving,
                            runAction: runAction,
                          ),
                        ),
                      ],
                      if (outcomeActions.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.sm),
                        _DrawerSection(
                          title: l.dashboardSuggestedNextAction,
                          child: _DrawerActionButtons(
                            actions: outcomeActions,
                            saving: saving,
                            runAction: runAction,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

class _DrawerSection extends StatelessWidget {
  const _DrawerSection({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.inputSurface(context).withValues(alpha: 0.56),
        border: Border.all(color: AppColors.borderColor(context)),
        borderRadius: AppRadius.large,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.textSecondaryColor(context),
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 4),
            child,
          ],
        ),
      ),
    );
  }
}

class _DrawerActionButtons extends StatelessWidget {
  const _DrawerActionButtons({
    required this.actions,
    required this.saving,
    required this.runAction,
  });

  final List<_DashboardDrawerAction> actions;
  final bool saving;
  final Future<void> Function(_DashboardDrawerAction action) runAction;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final action in actions)
          AppButton(
            label: action.label,
            icon: action.icon,
            variant: switch (action.style) {
              _DashboardDrawerActionStyle.primary => AppButtonVariant.primary,
              _DashboardDrawerActionStyle.danger => AppButtonVariant.danger,
              _DashboardDrawerActionStyle.secondary =>
                AppButtonVariant.secondary,
            },
            onPressed: saving ? null : () => runAction(action),
          ),
      ],
    );
  }
}

class _DrawerDetailRow extends StatelessWidget {
  const _DrawerDetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 132,
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.textSecondaryColor(context),
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _LeadDrawerOutcome { contacted, noAnswer, interested, notInterested }

Future<bool> _applyLeadDrawerOutcome(
  BuildContext context, {
  required SalesCommandItem item,
  required AuthState authState,
  required _LeadDrawerOutcome outcome,
}) async {
  final l = AppLocalizations.of(context)!;
  final session = authState.protectedCompanySession;
  final actorId = session?.uid ?? '';
  final actorName = session?.profile.fullName.trim().isNotEmpty == true
      ? session!.profile.fullName.trim()
      : (authState.user?.email ?? actorId);
  final companyId = session?.companyId ?? '';
  if (companyId.isEmpty || actorId.isEmpty) {
    AppFeedback.error(context, l.dashboardActionFailed);
    return false;
  }

  final lead = _leadForCommand(context, item);
  if (lead == null) {
    AppFeedback.error(context, l.dashboardActionFailed);
    return false;
  }

  final now = DateTime.now();
  final nextDay = DateTime(now.year, now.month, now.day + 1, 10);
  final updated = switch (outcome) {
    _LeadDrawerOutcome.contacted => lead.copyWith(
        status: lead.status == LeadStatus.newLead
            ? LeadStatus.contacted
            : lead.status,
        lastContactAt: now,
        updatedAt: now,
        updatedBy: actorId,
      ),
    _LeadDrawerOutcome.noAnswer => lead.copyWith(
        lastContactAt: now,
        nextFollowUpAt: nextDay,
        updatedAt: now,
        updatedBy: actorId,
      ),
    _LeadDrawerOutcome.interested => lead.copyWith(
        status: LeadStatus.interested,
        lastContactAt: now,
        updatedAt: now,
        updatedBy: actorId,
      ),
    _LeadDrawerOutcome.notInterested => lead.copyWith(
        status: LeadStatus.lost,
        lastContactAt: now,
        updatedAt: now,
        updatedBy: actorId,
      ),
  };

  final cubit = context.read<LeadsCubit>();
  await cubit.updateLead(
    companyId: companyId,
    lead: updated,
    actorName: actorName,
  );
  if (cubit.state.status != LeadsStatus.saved) {
    AppFeedback.error(context, l.dashboardActionFailed);
    return false;
  }
  await cubit.addNote(
    companyId: companyId,
    leadId: lead.id,
    text: _leadOutcomeNote(l, outcome),
    createdBy: actorId,
    actorName: actorName,
  );
  AppFeedback.success(context, l.dashboardActionSaved);
  return true;
}

Future<bool> _scheduleLeadFollowUpFromDrawer(
  BuildContext context, {
  required SalesCommandItem item,
  required AuthState authState,
}) async {
  final l = AppLocalizations.of(context)!;
  final today = DateTime.now();
  final picked = await showDatePicker(
    context: context,
    initialDate: today.add(const Duration(days: 1)),
    firstDate: today,
    lastDate: today.add(const Duration(days: 365)),
    locale: Locale(l.localeName),
  );
  if (picked == null) {
    return false;
  }

  final session = authState.protectedCompanySession;
  final actorId = session?.uid ?? '';
  final actorName = session?.profile.fullName.trim().isNotEmpty == true
      ? session!.profile.fullName.trim()
      : (authState.user?.email ?? actorId);
  final companyId = session?.companyId ?? '';
  final lead = _leadForCommand(context, item);
  if (companyId.isEmpty || actorId.isEmpty || lead == null) {
    AppFeedback.error(context, l.dashboardActionFailed);
    return false;
  }

  final followUpAt = DateTime(picked.year, picked.month, picked.day, 10);
  final cubit = context.read<LeadsCubit>();
  await cubit.updateLead(
    companyId: companyId,
    lead: lead.copyWith(
      nextFollowUpAt: followUpAt,
      updatedAt: DateTime.now(),
      updatedBy: actorId,
    ),
    actorName: actorName,
  );
  if (cubit.state.status != LeadsStatus.saved) {
    AppFeedback.error(context, l.dashboardActionFailed);
    return false;
  }
  await cubit.addNote(
    companyId: companyId,
    leadId: lead.id,
    text: l.dashboardLeadNoteFollowUpScheduled(
      intl.DateFormat.yMMMd(l.localeName).format(followUpAt),
    ),
    createdBy: actorId,
    actorName: actorName,
  );
  AppFeedback.success(context, l.dashboardActionSaved);
  return true;
}

Future<bool> _markTaskCompletedFromDrawer(
  BuildContext context, {
  required SalesCommandItem item,
  required AuthState authState,
}) async {
  final l = AppLocalizations.of(context)!;
  final session = authState.protectedCompanySession;
  final companyId = session?.companyId ?? '';
  final actorId = session?.uid ?? '';
  final task = _taskForCommand(context, item);
  if (companyId.isEmpty || actorId.isEmpty || task == null) {
    AppFeedback.error(context, l.dashboardActionFailed);
    return false;
  }
  if (task.status == TaskStatus.completed || task.status == TaskStatus.cancelled) {
    AppFeedback.success(context, l.dashboardActionSaved);
    return true;
  }
  final success = await context.read<TasksCubit>().markCompleted(
        companyId: companyId,
        task: task,
        updatedBy: actorId,
      );
  if (!success) {
    AppFeedback.error(context, l.dashboardActionFailed);
    return false;
  }
  AppFeedback.success(context, l.dashboardActionSaved);
  return true;
}

Lead? _leadForCommand(BuildContext context, SalesCommandItem item) {
  if (item.module != DashboardCommandModule.lead || item.recordId.trim().isEmpty) {
    return null;
  }
  for (final lead in context.read<LeadsCubit>().state.leads) {
    if (lead.id == item.recordId) {
      return lead;
    }
  }
  return null;
}

CrmTask? _taskForCommand(BuildContext context, SalesCommandItem item) {
  if (item.module != DashboardCommandModule.task || item.recordId.trim().isEmpty) {
    return null;
  }
  for (final task in context.read<TasksCubit>().state.tasks) {
    if (task.id == item.recordId) {
      return task;
    }
  }
  return null;
}

String _leadOutcomeNote(AppLocalizations l, _LeadDrawerOutcome outcome) {
  return switch (outcome) {
    _LeadDrawerOutcome.contacted => l.dashboardLeadNoteContacted,
    _LeadDrawerOutcome.noAnswer => l.dashboardLeadNoteNoAnswer,
    _LeadDrawerOutcome.interested => l.dashboardLeadNoteInterested,
    _LeadDrawerOutcome.notInterested => l.dashboardLeadNoteNotInterested,
  };
}

String? _commandPhoneCandidate(SalesCommandItem item) {
  if (item.module != DashboardCommandModule.lead &&
      item.module != DashboardCommandModule.client &&
      item.module != DashboardCommandModule.appointment) {
    return null;
  }
  final candidates = [item.subtitle, item.title];
  for (final value in candidates) {
    final normalized = _phoneDigits(value);
    if (normalized.length >= 8) {
      return value;
    }
  }
  return null;
}

String _phoneDigits(String value) {
  return value.replaceAll(RegExp(r'[^0-9+]'), '');
}

String _whatsAppPhone(String value) {
  var phone = _phoneDigits(value);
  if (phone.startsWith('+')) {
    return phone.substring(1);
  }
  phone = phone.replaceAll(RegExp(r'[^0-9]'), '');
  if (phone.startsWith('00')) {
    return phone.substring(2);
  }
  if (phone.startsWith('0') && phone.length >= 10) {
    return '20${phone.substring(1)}';
  }
  return phone;
}

Future<bool> _launchCall(BuildContext context, String phone) async {
  final l = AppLocalizations.of(context)!;
  final normalized = _phoneDigits(phone);
  if (normalized.isEmpty) {
    AppFeedback.error(context, l.dashboardActionFailed);
    return false;
  }
  final url = Uri(scheme: 'tel', path: normalized).toString();
  final launched = await _openDashboardExternalLink(url);
  if (!launched && context.mounted) {
    AppFeedback.error(context, l.dashboardActionFailed);
  }
  return launched;
}

Future<bool> _launchWhatsApp(BuildContext context, String phone) async {
  final l = AppLocalizations.of(context)!;
  final normalized = _whatsAppPhone(phone);
  if (normalized.isEmpty) {
    AppFeedback.error(context, l.dashboardActionFailed);
    return false;
  }
  final url = Uri.https('wa.me', '/$normalized').toString();
  final launched = await _openDashboardExternalLink(url);
  if (!launched && context.mounted) {
    AppFeedback.error(context, l.dashboardActionFailed);
  }
  return launched;
}

Future<bool> _openDashboardExternalLink(String url) async {
  try {
    if (kIsWeb) {
      return openExternalLink(url);
    }
    return launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
  } catch (_) {
    return false;
  }
}

String _commandTimeLabel(BuildContext context, SalesCommandItem item) {
  final l = AppLocalizations.of(context)!;
  final dueAt = item.dueAt;
  if (dueAt != null) {
    final today = _dateOnly(DateTime.now());
    final dueDay = _dateOnly(dueAt);
    if (dueDay.isBefore(today)) {
      return l.salesCommandOverdueByDays(today.difference(dueDay).inDays);
    }
    if (dueDay == today) {
      return l.salesCommandDueToday;
    }
    return l.salesCommandDueAt(
      intl.DateFormat.MMMd(l.localeName).format(dueAt.toLocal()),
    );
  }
  final age = item.ageDays ?? 0;
  return age > 0 ? l.salesCommandAgeDays(age) : l.salesCommandUpdatedNow;
}

Color _commandPriorityColor(BuildContext context, DashboardPriority priority) {
  return switch (priority) {
    DashboardPriority.high => AppColors.errorColor(context),
    DashboardPriority.medium => AppColors.warningColor(context),
    DashboardPriority.low => AppColors.infoColor(context),
  };
}

int _commandPriorityRank(DashboardPriority priority) {
  return switch (priority) {
    DashboardPriority.high => 3,
    DashboardPriority.medium => 2,
    DashboardPriority.low => 1,
  };
}

class DashboardTodayRail extends StatefulWidget {
  const DashboardTodayRail({
    super.key,
    required this.analytics,
    required this.authState,
    required this.platformPreview,
  });

  final DashboardAnalytics analytics;
  final AuthState authState;
  final bool platformPreview;

  @override
  State<DashboardTodayRail> createState() => _DashboardTodayRailState();
}

class _DashboardTodayRailState extends State<DashboardTodayRail> {
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = _dateOnly(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final selectedAppointments = _appointmentsForDate(
      widget.analytics.calendarItems,
      _selectedDate,
    );
    final urgentItems = _urgentItemsForDate(
      widget.analytics.calendarItems,
      _selectedDate,
    );
    final actions = widget.platformPreview
        ? const <_DashboardAction>[]
        : _dashboardActions(context, widget.authState);

    return _DashboardCard(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(6, 4, 6, 0),
            child: _CardHeader(
              title: l.dashboardTodayRailTitle,
              trailing: IconButton(
                tooltip: l.dashboardTodayRailTitle,
                onPressed: () async {
                  final picked = await _showDashboardCalendarPicker(
                    context,
                    initialDate: _selectedDate,
                  );
                  if (picked != null && mounted) {
                    setState(() => _selectedDate = _dateOnly(picked));
                  }
                },
                icon: Icon(
                  Icons.calendar_month_outlined,
                  color: AppColors.textSecondaryColor(context),
                  size: 20,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(6, 0, 6, 0),
            child: Text(
              intl.DateFormat.yMMMMEEEEd(l.localeName).format(_selectedDate),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.textSecondaryColor(context),
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          DashboardWeekStrip(
            selectedDate: _selectedDate,
            onSelected: (date) => setState(() => _selectedDate = date),
          ),
          const SizedBox(height: 10),
          _RailSectionHeader(
            title: _dateOnly(_selectedDate) == _dateOnly(DateTime.now())
                ? l.todaysAppointments
                : l.dashboardAppointmentsForDate(
                    intl.DateFormat.MMMd(l.localeName).format(_selectedDate),
                  ),
            count: selectedAppointments.length,
            onViewAll: widget.platformPreview
                ? null
                : () => context.go(
                      RouteNames.filteredAppointments(
                        selectedDate: _queryDate(_selectedDate),
                      ),
                    ),
          ),
          const SizedBox(height: AppSpacing.xs),
          if (selectedAppointments.isEmpty)
            _RailEmpty(message: l.dashboardNoAppointmentsForDay)
          else
            for (final item in selectedAppointments.take(4))
              _RailItem(item: item, platformPreview: widget.platformPreview),
          const SizedBox(height: 10),
          _RailSectionHeader(
            title: l.dashboardUrgentActions,
            count: urgentItems.length,
          ),
          const SizedBox(height: AppSpacing.xs),
          if (urgentItems.isEmpty)
            _RailEmpty(message: l.dashboardNoUrgentActions)
          else
            for (final item in urgentItems.take(4))
              _RailItem(item: item, platformPreview: widget.platformPreview),
          const SizedBox(height: 10),
          DashboardRecentActivityRailCard(
            authState: widget.authState,
            platformPreview: widget.platformPreview,
          ),
          if (MediaQuery.sizeOf(context).width >= 760) ...[
            const SizedBox(height: 10),
            AppButton(
              label: l.dashboardQuickAction,
              icon: Icons.add_rounded,
              onPressed: actions.isEmpty
                  ? null
                  : () {
                      _openQuickActionMenu(context, actions);
                    },
            ),
          ],
        ],
      ),
    );
  }
}

class DashboardRecentActivityRailCard extends StatelessWidget {
  const DashboardRecentActivityRailCard({
    super.key,
    required this.authState,
    required this.platformPreview,
  });

  final AuthState authState;
  final bool platformPreview;

  @override
  Widget build(BuildContext context) {
    final role = authState.protectedCompanySession?.profile.role;
    final canView = platformPreview || role == UserRole.admin || role == UserRole.manager;
    if (!canView) {
      return const SizedBox.shrink();
    }

    final l = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(10, 9, 10, 9),
      decoration: BoxDecoration(
        color: AppColors.inputSurface(context).withValues(alpha: 0.78),
        borderRadius: AppRadius.large,
        border: Border.all(color: AppColors.borderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _RailSectionHeader(
            title: l.dashboardRecentActivity,
            count: null,
            onViewAll: null,
          ),
          const SizedBox(height: 7),
          BlocBuilder<AuditLogsCubit, AuditLogsState>(
            builder: (context, state) {
              if (state.status == AuditLogsStatus.loading && state.logs.isEmpty) {
                return const SizedBox(
                  height: 42,
                  child: Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))),
                );
              }
              if (state.status == AuditLogsStatus.failure) {
                return _RailEmpty(message: l.dashboardUnableToLoadRecentActivity);
              }
              final logs = state.logs.take(5).toList();
              if (logs.isEmpty) {
                return _RailEmpty(message: l.dashboardNoRecentActivity);
              }
              return Column(
                children: [
                  for (var index = 0; index < logs.length; index++) ...[
                    _RailAuditItem(log: logs[index], platformPreview: platformPreview),
                    if (index != logs.length - 1) const SizedBox(height: 6),
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

class _RailAuditItem extends StatelessWidget {
  const _RailAuditItem({required this.log, required this.platformPreview});

  final AuditLog log;
  final bool platformPreview;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final color = _auditToneColor(context, log.action);
    final title = _fallback(log.recordTitle, _auditModuleLabel(l, log.module));
    final actor = _fallback(log.actorName, _fallback(log.actorEmail, l.unknownUser));
    final subtitle = log.recordSubtitle.trim();
    final route = platformPreview ? null : _auditRoute(log);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: route == null ? null : () => context.go(route),
        borderRadius: AppRadius.medium,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                            height: 1.15,
                          ),
                    ),
                    if (subtitle.isNotEmpty)
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppColors.textMutedColor(context),
                              fontWeight: FontWeight.w400,
                              height: 1.1,
                            ),
                      ),
                    Text(
                      '${_auditActionLabel(l, log.action)} • ${_auditModuleLabel(l, log.module)} • $actor • ${_compactRelativeTime(context, log.createdAt)}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.textSecondaryColor(context),
                            fontWeight: FontWeight.w400,
                            height: 1.15,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<DateTime?> _showDashboardCalendarPicker(
  BuildContext context, {
  required DateTime initialDate,
}) {
  final l = AppLocalizations.of(context)!;
  final today = DateTime.now();
  var selected = initialDate;
  return showDialog<DateTime>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(l.dashboardTodayRailTitle),
        content: SizedBox(
          width: 360,
          height: 360,
          child: CalendarDatePicker(
            initialDate: initialDate,
            firstDate: DateTime(today.year - 2),
            lastDate: DateTime(today.year + 2),
            onDateChanged: (date) {
              selected = date;
              Navigator.of(dialogContext).pop(date);
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l.close),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(selected),
            child: Text(l.done),
          ),
        ],
      );
    },
  );
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

String _auditActionLabel(AppLocalizations l, AuditLogAction action) {
  return switch (action) {
    AuditLogAction.create => l.dashboardAuditCreated,
    AuditLogAction.update => l.dashboardAuditUpdated,
    AuditLogAction.archive => l.dashboardAuditArchived,
    AuditLogAction.restore => l.dashboardAuditRestored,
    AuditLogAction.deactivate => l.dashboardAuditDeactivated,
    AuditLogAction.assign => l.dashboardAuditAssigned,
    AuditLogAction.statusChange => l.dashboardAuditStatusChanged,
    AuditLogAction.stageChange => l.dashboardAuditStageChanged,
    AuditLogAction.complete => l.dashboardAuditCompleted,
    AuditLogAction.cancel => l.dashboardAuditCancelled,
    AuditLogAction.imageAdded => l.dashboardAuditImageAdded,
    AuditLogAction.imageRemoved => l.dashboardAuditImageRemoved,
    AuditLogAction.exportGenerated => l.dashboardAuditExportGenerated,
    AuditLogAction.exported => l.dashboardAuditExportGenerated,
  };
}

String? _auditRoute(AuditLog log) {
  if (log.recordId.trim().isEmpty) {
    return null;
  }
  return switch (log.module) {
    AuditLogModule.leads => RouteNames.leadDetails(log.recordId),
    AuditLogModule.clients => RouteNames.clientDetails(log.recordId),
    AuditLogModule.properties => RouteNames.propertyDetails(log.recordId),
    AuditLogModule.tasks => RouteNames.taskEdit(log.recordId),
    AuditLogModule.deals => RouteNames.dealDetails(log.recordId),
    AuditLogModule.appointments => RouteNames.appointmentEdit(log.recordId),
    AuditLogModule.users => RouteNames.users,
    AuditLogModule.teams => RouteNames.teams,
    AuditLogModule.reports => RouteNames.reports,
    AuditLogModule.exports => RouteNames.auditLogs,
    AuditLogModule.auditLogs => RouteNames.auditLogs,
    AuditLogModule.other => null,
  };
}

Color _auditToneColor(BuildContext context, AuditLogAction action) {
  return switch (action) {
    AuditLogAction.create ||
    AuditLogAction.imageAdded ||
    AuditLogAction.complete ||
    AuditLogAction.restore => AppColors.successColor(context),
    AuditLogAction.archive ||
    AuditLogAction.deactivate ||
    AuditLogAction.cancel ||
    AuditLogAction.imageRemoved => AppColors.textMutedColor(context),
    AuditLogAction.statusChange ||
    AuditLogAction.stageChange => AppColors.warningColor(context),
    AuditLogAction.assign ||
    AuditLogAction.update ||
    AuditLogAction.exportGenerated ||
    AuditLogAction.exported => AppColors.infoColor(context),
  };
}

String _compactRelativeTime(BuildContext context, DateTime date) {
  final l = AppLocalizations.of(context)!;
  final diff = DateTime.now().difference(date.toLocal());
  final ar = l.localeName.toLowerCase().startsWith('ar');
  if (diff.inMinutes < 1) {
    return ar ? 'الآن' : 'now';
  }
  if (diff.inHours < 1) {
    return ar ? 'منذ ${diff.inMinutes} د' : '${diff.inMinutes}m ago';
  }
  if (diff.inDays < 1) {
    return ar ? 'منذ ${diff.inHours} س' : '${diff.inHours}h ago';
  }
  return ar ? 'منذ ${diff.inDays} يوم' : '${diff.inDays}d ago';
}

class DashboardWeekStrip extends StatelessWidget {
  const DashboardWeekStrip({
    super.key,
    required this.selectedDate,
    required this.onSelected,
  });

  final DateTime selectedDate;
  final ValueChanged<DateTime> onSelected;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final today = _dateOnly(DateTime.now());
    final weekStart = _weekStart(today, l.localeName);
    return Row(
      children: [
        for (var index = 0; index < 7; index++)
          Expanded(
            child: Padding(
              padding: EdgeInsetsDirectional.only(end: index == 6 ? 0 : 4),
              child: _DayPill(
                date: weekStart.add(Duration(days: index)),
                selected: _dateOnly(weekStart.add(Duration(days: index))) ==
                    _dateOnly(selectedDate),
                today: _dateOnly(weekStart.add(Duration(days: index))) == today,
                onTap: onSelected,
              ),
            ),
          ),
      ],
    );
  }
}

class DashboardChartEmptyState extends StatelessWidget {
  const DashboardChartEmptyState({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.inputSurface(context).withValues(alpha: 0.72),
        border: Border.all(color: AppColors.borderColor(context)),
        borderRadius: AppRadius.large,
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondaryColor(context),
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  const _DashboardCard({
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.cardSurface(context),
        border: Border.all(
          color: AppColors.borderColor(context).withValues(alpha: isDark ? 0.82 : 0.72),
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark ? null : AppShadows.card,
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

class _CardHeader extends StatelessWidget {
  const _CardHeader({
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final subtitleText = subtitle?.trim() ?? '';

    Widget titleBlock() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.visible,
            softWrap: true,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              height: 1.18,
            ),
          ),
          if (subtitleText.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(
              subtitleText,
              maxLines: 3,
              overflow: TextOverflow.visible,
              softWrap: true,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.textSecondaryColor(context),
                fontWeight: FontWeight.w500,
                height: 1.25,
              ),
            ),
          ],
        ],
      );
    }

    final trailingWidget = trailing;
    if (trailingWidget == null) {
      return titleBlock();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 640;

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              titleBlock(),
              const SizedBox(height: AppSpacing.xs),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: trailingWidget,
              ),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: titleBlock()),
            const SizedBox(width: AppSpacing.sm),
            Flexible(
              fit: FlexFit.loose,
              child: Align(
                alignment: AlignmentDirectional.centerEnd,
                child: trailingWidget,
              ),
            ),
          ],
        );
      },
    );
  }
}
class _AnimatedSection extends StatelessWidget {
  const _AnimatedSection({
    required this.index,
    required this.child,
  });

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 720;
    if (isMobile) {
      return child;
    }
    return child
        .animate(delay: Duration(milliseconds: 90 * index))
        .fadeIn(duration: 560.ms, curve: Curves.easeOutCubic)
        .slideY(begin: 0.04, end: 0);
  }
}

class _SoftIcon extends StatelessWidget {
  const _SoftIcon({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 31,
      height: 31,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Icon(icon, color: color, size: 18),
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
    return Text(
      '${positive ? '+' : ''}$value%',
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w500,
          ),
    );
  }
}

class _EmptySparklinePainter extends CustomPainter {
  const _EmptySparklinePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(0, size.height * 0.62),
      Offset(size.width, size.height * 0.62),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _EmptySparklinePainter oldDelegate) {
    return color != oldDelegate.color;
  }
}

class _PerformanceLegend extends StatelessWidget {
  const _PerformanceLegend({required this.series});

  final List<DashboardChartSeries> series;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.end,
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.xs,
      children: [
        for (final item in series)
          _LegendPill(
            color: DashboardChartPalette.seriesColor(context, item.type),
            label: _seriesLabel(context, item.type),
          ),
      ],
    );
  }
}

class _LegendPill extends StatelessWidget {
  const _LegendPill({
    required this.color,
    required this.label,
  });

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.textSecondaryColor(context),
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}

class _DonutLegend extends StatelessWidget {
  const _DonutLegend({
    required this.total,
    required this.rows,
  });

  final int total;
  final List<_LegendRowData> rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final row in rows)
          Padding(
            padding: const EdgeInsets.only(bottom: 7),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: row.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    row.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                Text(
                  '${row.value} (${((row.value / total) * 100).round()}%)',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
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

class _LegendRowData {
  const _LegendRowData({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({required this.action});

  final _DashboardAction action;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.inputSurface(context),
      borderRadius: AppRadius.large,
      child: InkWell(
        onTap: action.onTap,
        borderRadius: AppRadius.large,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.borderColor(context)),
            borderRadius: AppRadius.large,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(action.icon, color: AppColors.primaryColor(context), size: 18),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  action.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w500,
                        height: 1.1,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TeamHeaderRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final style = Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppColors.textSecondaryColor(context),
          fontWeight: FontWeight.w500,
        );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Expanded(flex: 4, child: Text(l.dashboardTeamUser, style: style)),
          Expanded(child: Text(l.dashboardTeamAppointments, style: style)),
          Expanded(child: Text(l.dashboardTeamDeals, style: style)),
          Expanded(flex: 2, child: Text(l.dashboardTeamPipeline, style: style)),
        ],
      ),
    );
  }
}

class _TeamPerformanceRow extends StatelessWidget {
  const _TeamPerformanceRow({required this.row, required this.maxScore});

  final DashboardTeamPerformanceRow row;
  final num maxScore;

  @override
  Widget build(BuildContext context) {
    final score = _teamScore(row);
    final progress = maxScore <= 0 ? 0.0 : (score / maxScore).clamp(0.04, 1.0).toDouble();
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.inputSurface(context),
        borderRadius: AppRadius.large,
        border: Border.all(color: AppColors.borderColor(context).withValues(alpha: 0.72)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _InitialsAvatar(name: row.name, size: 30),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      row.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${row.appointments} · ${row.deals} · ${_formatMoney(context, row.pipelineValue)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.textSecondaryColor(context),
                            fontWeight: FontWeight.w400,
                          ),
                    ),
                  ],
                ),
              ),
              _SmallCell(row.activeRecords.toString()),
            ],
          ),
          const SizedBox(height: 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              backgroundColor: AppColors.borderColor(context).withValues(alpha: 0.55),
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor(context)),
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallCell extends StatelessWidget {
  const _SmallCell(this.value);

  final String value;

  @override
  Widget build(BuildContext context) {
    return Text(
      value,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
    );
  }
}

class _OpportunityCard extends StatelessWidget {
  const _OpportunityCard({
    required this.item,
    required this.platformPreview,
  });

  final DashboardOpportunityItem item;
  final bool platformPreview;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final route = platformPreview ? null : _opportunityRoute(item);
    return Material(
      color: AppColors.inputSurface(context),
      borderRadius: AppRadius.large,
      child: InkWell(
        onTap: route == null ? null : () => context.go(route),
        borderRadius: AppRadius.large,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.borderColor(context)),
            borderRadius: AppRadius.large,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppStatusBadge(
                label: _opportunityStatusLabel(l, item),
                tone: _opportunityTone(item),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
              const SizedBox(height: 3),
              Text(
                _fallback(item.ownerName, l.notAvailable),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textSecondaryColor(context),
                      fontWeight: FontWeight.w500,
                    ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.value > 0 ? _formatMoney(context, item.value) : l.dashboardNoValue,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ),
                  Text(
                    _ageLabel(context, item.updatedAt ?? item.createdAt),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.textMutedColor(context),
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InitialsAvatar extends StatelessWidget {
  const _InitialsAvatar({required this.name, required this.size});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.primaryColor(context).withValues(alpha: 0.16),
        shape: BoxShape.circle,
      ),
      child: Text(
        _initials(name),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.primaryColor(context),
              fontWeight: FontWeight.w500,
            ),
      ),
    );
  }
}

class _RailSectionHeader extends StatelessWidget {
  const _RailSectionHeader({
    required this.title,
    this.count,
    this.onViewAll,
  });

  final String title;
  final int? count;
  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(
          child: Text(
            count == null ? title : '$title ($count)',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
        ),
        if (onViewAll != null)
          TextButton(onPressed: onViewAll, child: Text(l.viewAll)),
      ],
    );
  }
}

class _RailItem extends StatelessWidget {
  const _RailItem({
    required this.item,
    required this.platformPreview,
  });

  final DashboardTodayItem item;
  final bool platformPreview;

  @override
  Widget build(BuildContext context) {
    final color = _urgencyColor(context, item.urgency);
    final route = platformPreview ? null : _todayRoute(item);
    final l = AppLocalizations.of(context)!;
    final reason = _todayReasonLabel(l, item);
    final recordType = _todayModuleLabel(l, item.module);
    final dueLabel = _timeLabel(context, item.dueAt);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Material(
        color: AppColors.inputSurface(context),
        borderRadius: AppRadius.large,
        child: InkWell(
          onTap: route == null ? null : () => context.go(route),
          borderRadius: AppRadius.large,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              border: Border.all(color: color.withValues(alpha: 0.34)),
              borderRadius: AppRadius.large,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        reason,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: color,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    AppStatusBadge(
                      label: recordType,
                      tone: _todayModuleTone(item),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: 3,
                  children: [
                    _RailMetaPill(
                      icon: Icons.schedule_rounded,
                      label: dueLabel,
                    ),
                    _RailMetaPill(
                      icon: Icons.person_outline_rounded,
                      label: _fallback(item.subtitle, l.notAvailable),
                    ),
                    if (item.dueAt != null)
                      _RailMetaPill(
                        icon: Icons.timer_outlined,
                        label: _ageLabel(context, item.dueAt),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RailMetaPill extends StatelessWidget {
  const _RailMetaPill({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.cardSurface(context),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.borderColor(context)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.textMutedColor(context)),
          const SizedBox(width: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textSecondaryColor(context),
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

class _RailEmpty extends StatelessWidget {
  const _RailEmpty({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.inputSurface(context),
        borderRadius: AppRadius.large,
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.textSecondaryColor(context),
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _DayPill extends StatelessWidget {
  const _DayPill({
    required this.date,
    required this.selected,
    required this.today,
    required this.onTap,
  });

  final DateTime date;
  final bool selected;
  final bool today;
  final ValueChanged<DateTime> onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final color = AppColors.primaryColor(context);
    return Material(
      color: selected ? color : AppColors.inputSurface(context),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: () => onTap(_dateOnly(date)),
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(
              color: selected
                  ? color
                  : today
                      ? color.withValues(alpha: 0.44)
                      : AppColors.borderColor(context),
            ),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Column(
            children: [
              Text(
                intl.DateFormat.E(l.localeName).format(date),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: selected
                          ? AppColors.textStrong
                          : AppColors.textSecondaryColor(context),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              Text(
                date.day.toString(),
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: selected
                          ? AppColors.textStrong
                          : AppColors.textPrimaryColor(context),
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardAction {
  const _DashboardAction({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
}

List<DashboardKpiMetric> _primaryMetrics(List<DashboardKpiMetric> metrics) {
  final orderedTypes = [
    DashboardKpiType.activeLeads,
    DashboardKpiType.newLeadsToday,
    DashboardKpiType.hotOpportunities,
    DashboardKpiType.dueTodayFollowUps,
    DashboardKpiType.overdueFollowUps,
    DashboardKpiType.appointmentsToday,
    DashboardKpiType.missedAppointments,
    DashboardKpiType.overdueTasks,
    DashboardKpiType.expectedPipelineValue,
    DashboardKpiType.pipelineDeals,
    DashboardKpiType.expectedCommission,
    DashboardKpiType.wonDealsThisMonth,
    DashboardKpiType.stuckDeals,
    DashboardKpiType.unassignedLeads,
    DashboardKpiType.activeProperties,
  ];
  final selected = <DashboardKpiMetric>[];
  for (final type in orderedTypes) {
    if ((type == DashboardKpiType.pipelineDeals &&
            selected.any((item) => item.type == DashboardKpiType.expectedPipelineValue)) ||
        (type == DashboardKpiType.expectedPipelineValue &&
            selected.any((item) => item.type == DashboardKpiType.pipelineDeals))) {
      continue;
    }
    for (final metric in metrics) {
      if (metric.type == type) {
        selected.add(metric);
        break;
      }
    }
  }
  return selected;
}

LineChartData _performanceChartData(
  BuildContext context,
  List<DashboardChartSeries> series,
) {
  final maxPointCount = series
      .map((item) => item.points.length)
      .fold<int>(1, (maxValue, value) => value > maxValue ? value : maxValue);
  final maxY = series
      .expand((item) => item.points.map((point) => point.value))
      .fold<int>(1, (maxValue, value) => value > maxValue ? value : maxValue)
      .toDouble();

  return LineChartData(
    minX: 0,
    maxX: (maxPointCount - 1).toDouble(),
    minY: 0,
    maxY: maxY * 1.16,
    gridData: FlGridData(
      show: true,
      drawVerticalLine: false,
      horizontalInterval: math.max(maxY / 4, 1.0),
      getDrawingHorizontalLine: (_) => FlLine(
        color: AppColors.borderColor(context),
        strokeWidth: 1,
      ),
    ),
    titlesData: FlTitlesData(
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 32,
          getTitlesWidget: (value, meta) => Text(
            intl.NumberFormat.compact(
              locale: Localizations.localeOf(context).toString(),
            ).format(value),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textMutedColor(context),
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ),
      ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 24,
          interval: math.max((maxPointCount / 5).floorToDouble(), 1.0),
          getTitlesWidget: (value, meta) {
            final first = series.first.points;
            final index = value.round().clamp(0, first.length - 1).toInt();
            return Padding(
              padding: const EdgeInsets.only(top: 7),
              child: Text(
                intl.DateFormat.MMMd(
                  Localizations.localeOf(context).toString(),
                ).format(first[index].date),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textMutedColor(context),
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            );
          },
        ),
      ),
    ),
    borderData: FlBorderData(show: false),
    lineTouchData: LineTouchData(
      touchTooltipData: LineTouchTooltipData(
        getTooltipColor: (_) => AppColors.cardSurface(context),
        tooltipBorder: BorderSide(color: AppColors.borderColor(context)),
        getTooltipItems: (spots) {
          return spots.map((spot) {
            final item = series[spot.barIndex];
            return LineTooltipItem(
              '${_seriesLabel(context, item.type)}: ${spot.y.round()}',
              Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: DashboardChartPalette.seriesColor(context, item.type),
                        fontWeight: FontWeight.w500,
                      ) ??
                  const TextStyle(),
            );
          }).toList();
        },
      ),
    ),
    lineBarsData: [
      for (final item in series)
        LineChartBarData(
          spots: [
            for (var index = 0; index < item.points.length; index++)
              FlSpot(index.toDouble(), item.points[index].value.toDouble()),
          ],
          isCurved: false,
          color: DashboardChartPalette.seriesColor(context, item.type),
          barWidth: 2.8,
          dotData: const FlDotData(show: true),
          belowBarData: BarAreaData(show: false),
        ),
    ],
  );
}

List<_DashboardAction> _dashboardActions(BuildContext context, AuthState authState) {
  final l = AppLocalizations.of(context)!;
  final role = authState.protectedCompanySession?.profile.role;
  final company = authState.companyMetadata;
  if (role == null) {
    return const <_DashboardAction>[];
  }

  return [
    if (company.isFeatureEnabled(CompanyFeature.leads) &&
        PermissionService.can(role, AppPermission.createLead))
      _DashboardAction(
        label: l.dashboardAddLead,
        icon: Icons.person_add_alt_outlined,
        onTap: () => context.go(RouteNames.leadsCreate),
      ),
    if (company.isFeatureEnabled(CompanyFeature.clients) &&
        PermissionService.can(role, AppPermission.createClient))
      _DashboardAction(
        label: l.dashboardAddClient,
        icon: Icons.group_add_outlined,
        onTap: () => context.go(RouteNames.clientsCreate),
      ),
    if (company.isFeatureEnabled(CompanyFeature.properties) &&
        PermissionService.can(role, AppPermission.createProperty))
      _DashboardAction(
        label: l.dashboardAddProperty,
        icon: Icons.add_business_outlined,
        onTap: () => context.go(RouteNames.propertiesCreate),
      ),
    if (company.isFeatureEnabled(CompanyFeature.appointments) &&
        PermissionService.can(role, AppPermission.createAppointment))
      _DashboardAction(
        label: l.dashboardAddAppointment,
        icon: Icons.event_available_outlined,
        onTap: () => context.go(RouteNames.appointmentsCreate),
      ),
  ];
}

Future<void> _openQuickActionMenu(
  BuildContext context,
  List<_DashboardAction> actions,
) {
  final l = AppLocalizations.of(context)!;
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l.dashboardQuickAction,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
              const SizedBox(height: AppSpacing.sm),
              for (final action in actions)
                ListTile(
                  leading: Icon(action.icon, color: AppColors.primaryColor(context)),
                  title: Text(action.label),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    action.onTap();
                  },
                ),
            ],
          ),
        ),
      );
    },
  );
}

List<DashboardTodayItem> _appointmentsForDate(
  List<DashboardTodayItem> items,
  DateTime date,
) {
  final selected = _dateOnly(date);
  return items.where((item) {
    return item.module == DashboardTodayModule.appointment &&
        item.dueAt != null &&
        _dateOnly(item.dueAt!) == selected;
  }).toList()
    ..sort(_compareTodayItems);
}

List<DashboardTodayItem> _urgentItemsForDate(
  List<DashboardTodayItem> items,
  DateTime date,
) {
  final selected = _dateOnly(date);
  return items.where((item) {
    if (item.module == DashboardTodayModule.appointment || item.dueAt == null) {
      return false;
    }
    final day = _dateOnly(item.dueAt!);
    return day == selected || day.isBefore(selected);
  }).toList()
    ..sort((a, b) {
      final urgency = _urgencyRank(b.urgency).compareTo(_urgencyRank(a.urgency));
      if (urgency != 0) {
        return urgency;
      }
      return _compareTodayItems(a, b);
    });
}

int _compareTodayItems(DashboardTodayItem a, DashboardTodayItem b) {
  final aDate = a.dueAt ?? DateTime(9999);
  final bDate = b.dueAt ?? DateTime(9999);
  return aDate.compareTo(bDate);
}

DateTime _weekStart(DateTime today, String localeName) {
  final startsOnSaturday = localeName.toLowerCase().startsWith('ar');
  final targetWeekday = startsOnSaturday ? DateTime.saturday : DateTime.sunday;
  final delta = (today.weekday - targetWeekday) % 7;
  return today.subtract(Duration(days: delta));
}

DateTime _dateOnly(DateTime value) {
  final local = value.toLocal();
  return DateTime(local.year, local.month, local.day);
}

String _queryDate(DateTime value) {
  final local = value.toLocal();
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  return '${local.year}-$month-$day';
}

String _kpiTitle(BuildContext context, DashboardKpiType type) {
  final l = AppLocalizations.of(context)!;
  return switch (type) {
    DashboardKpiType.activeLeads => l.dashboardKpiActiveLeads,
    DashboardKpiType.newLeadsToday => l.newLeads,
    DashboardKpiType.hotOpportunities => l.dashboardKpiHotOpportunities,
    DashboardKpiType.dueTodayFollowUps => l.dashboardKpiDueTodayFollowUps,
    DashboardKpiType.overdueFollowUps => l.dashboardOverdueFollowUps,
    DashboardKpiType.appointmentsToday => l.dashboardKpiAppointmentsToday,
    DashboardKpiType.missedAppointments => l.missedAppointments,
    DashboardKpiType.overdueTasks => l.dashboardOverdueTasks,
    DashboardKpiType.expectedPipelineValue ||
    DashboardKpiType.pipelineDeals =>
      l.dashboardKpiExpectedPipeline,
    DashboardKpiType.expectedCommission => l.commissionTotal,
    DashboardKpiType.wonDealsThisMonth => l.wonDealsThisMonth,
    DashboardKpiType.stuckDeals => l.dashboardDealRisks,
    DashboardKpiType.unassignedLeads => l.dashboardUnassignedLeads,
    DashboardKpiType.teamWorkload => l.workload,
    DashboardKpiType.activeProperties => l.dashboardKpiActiveListings,
    DashboardKpiType.overdueActions => l.dashboardKpiOverdueActions,
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
    DashboardKpiType.pipelineDeals =>
      l.dashboardPeriodCurrentScope,
    DashboardKpiType.wonDealsThisMonth => l.dashboardPeriodThisMonth,
    DashboardKpiType.overdueFollowUps ||
    DashboardKpiType.overdueActions ||
    DashboardKpiType.overdueTasks ||
    DashboardKpiType.stuckDeals ||
    DashboardKpiType.unassignedLeads ||
    DashboardKpiType.teamWorkload =>
      l.dashboardPeriodCurrentScope,
    _ => l.dashboardPeriodCurrentScope,
  };
}

IconData _kpiIcon(DashboardKpiType type) {
  // Use the safest Material icon glyphs here. Some rounded/filled glyphs were
  // not rendering reliably on mobile builds, while these baseline glyphs render
  // consistently across Flutter Web and mobile.
  return switch (type) {
    DashboardKpiType.activeLeads => Icons.people_outline,
    DashboardKpiType.newLeadsToday => Icons.person_add_alt_outlined,
    DashboardKpiType.hotOpportunities => Icons.star_border,
    DashboardKpiType.dueTodayFollowUps => Icons.event_available_outlined,
    DashboardKpiType.overdueFollowUps => Icons.phone_missed_outlined,
    DashboardKpiType.overdueActions => Icons.report_problem_outlined,
    DashboardKpiType.appointmentsToday => Icons.calendar_today_outlined,
    DashboardKpiType.missedAppointments => Icons.event_busy_outlined,
    DashboardKpiType.overdueTasks => Icons.assignment_late_outlined,
    DashboardKpiType.pipelineDeals ||
    DashboardKpiType.expectedPipelineValue =>
      Icons.attach_money,
    DashboardKpiType.expectedCommission => Icons.price_check_outlined,
    DashboardKpiType.wonDealsThisMonth => Icons.verified_outlined,
    DashboardKpiType.stuckDeals => Icons.hourglass_bottom_outlined,
    DashboardKpiType.unassignedLeads => Icons.person_search_outlined,
    DashboardKpiType.teamWorkload => Icons.groups_outlined,
    DashboardKpiType.activeProperties => Icons.home_work_outlined,
  };
}

String _performanceFilterLabel(
  BuildContext context,
  _PerformanceSeriesFilter filter,
) {
  final l = AppLocalizations.of(context)!;
  return switch (filter) {
    _PerformanceSeriesFilter.all => l.all,
    _PerformanceSeriesFilter.leads => l.newLeads,
    _PerformanceSeriesFilter.appointments => l.dashboardSeriesAppointments,
    _PerformanceSeriesFilter.followUps => l.followUps,
    _PerformanceSeriesFilter.deals => l.dashboardSeriesDeals,
    _PerformanceSeriesFilter.properties => l.dashboardAvailableProperties,
  };
}

String _seriesLabel(
  BuildContext context,
  DashboardPerformanceSeriesType type,
) {
  final l = AppLocalizations.of(context)!;
  return switch (type) {
    DashboardPerformanceSeriesType.leads => l.newLeads,
    DashboardPerformanceSeriesType.appointments => l.dashboardSeriesAppointments,
    DashboardPerformanceSeriesType.followUps => l.followUps,
    DashboardPerformanceSeriesType.deals => l.dashboardSeriesDeals,
    DashboardPerformanceSeriesType.pipelineValue => l.dashboardSeriesPipelineValue,
    DashboardPerformanceSeriesType.properties => l.dashboardAvailableProperties,
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

String _propertyStatusLabel(AppLocalizations l, PropertyStatus status) {
  return switch (status) {
    PropertyStatus.available => l.available,
    PropertyStatus.reserved => l.reserved,
    PropertyStatus.sold => l.sold,
    PropertyStatus.rented => l.rented,
    PropertyStatus.inactive => l.inactive,
  };
}

String _opportunityStatusLabel(AppLocalizations l, DashboardOpportunityItem item) {
  final leadStatus = item.leadStatus;
  final dealStage = item.dealStage;
  final propertyStatus = item.propertyStatus;
  if (leadStatus != null) {
    return _leadStatusLabel(l, leadStatus);
  }
  if (dealStage != null) {
    return dealStageLabel(l, dealStage);
  }
  if (propertyStatus != null) {
    return _propertyStatusLabel(l, propertyStatus);
  }
  return l.notAvailable;
}

AppStatusTone _opportunityTone(DashboardOpportunityItem item) {
  final dealStage = item.dealStage;
  if (dealStage != null) {
    return dealStageTone(dealStage);
  }
  if (item.leadStatus == LeadStatus.negotiation ||
      item.leadStatus == LeadStatus.visitScheduled ||
      item.leadStatus == LeadStatus.interested) {
    return AppStatusTone.warning;
  }
  if (item.propertyStatus == PropertyStatus.available) {
    return AppStatusTone.success;
  }
  return AppStatusTone.info;
}

String? _opportunityRoute(DashboardOpportunityItem item) {
  return switch (item.type) {
    DashboardOpportunityType.lead => RouteNames.leadDetails(item.recordId),
    DashboardOpportunityType.deal => RouteNames.dealDetails(item.recordId),
    DashboardOpportunityType.property => RouteNames.propertyDetails(item.recordId),
  };
}

String _todayReasonLabel(AppLocalizations l, DashboardTodayItem item) {
  return switch (item.module) {
    DashboardTodayModule.appointment => switch (item.urgency) {
        DashboardTodayUrgency.overdue => l.salesCommandReasonAppointmentMissed,
        DashboardTodayUrgency.dueToday => l.salesCommandReasonAppointmentDueNow,
        DashboardTodayUrgency.normal => l.salesCommandReasonAppointmentUpcoming,
      },
    DashboardTodayModule.followUp => switch (item.urgency) {
        DashboardTodayUrgency.overdue => l.salesCommandReasonOverdueFollowUp,
        DashboardTodayUrgency.dueToday => l.salesCommandReasonDueTodayFollowUp,
        DashboardTodayUrgency.normal => l.followUps,
      },
    DashboardTodayModule.task => switch (item.urgency) {
        DashboardTodayUrgency.overdue => l.salesCommandReasonOverdueTask,
        DashboardTodayUrgency.dueToday => l.salesCommandReasonDueTodayTask,
        DashboardTodayUrgency.normal => l.tasks,
      },
    DashboardTodayModule.deal => l.salesCommandReasonDealAtRisk,
  };
}

String _todayModuleLabel(AppLocalizations l, DashboardTodayModule module) {
  return switch (module) {
    DashboardTodayModule.appointment => l.appointments,
    DashboardTodayModule.followUp => l.followUps,
    DashboardTodayModule.task => l.tasks,
    DashboardTodayModule.deal => l.deals,
  };
}

AppStatusTone _todayModuleTone(DashboardTodayItem item) {
  return switch (item.urgency) {
    DashboardTodayUrgency.overdue => AppStatusTone.error,
    DashboardTodayUrgency.dueToday => AppStatusTone.warning,
    DashboardTodayUrgency.normal => AppStatusTone.info,
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

String _dailyInsightText(AppLocalizations l, DashboardDailyInsight insight) {
  return switch (insight.type) {
    DashboardDailyInsightType.staleLeads =>
      l.dashboardDailyInsightStaleLeads(insight.primaryValue),
    DashboardDailyInsightType.conversionUp =>
      l.dashboardDailyInsightConversionUp(insight.percent),
    DashboardDailyInsightType.calm => l.dashboardDailyInsightCalm,
    DashboardDailyInsightType.notEnoughData => l.dashboardDailyInsightNotEnoughData,
  };
}

String _formatMoney(BuildContext context, num value) {
  if (value <= 0) {
    return '0';
  }
  return intl.NumberFormat.compact(
    locale: Localizations.localeOf(context).toString(),
  ).format(value);
}

bool _isMoneyKpi(DashboardKpiType type) {
  return type == DashboardKpiType.expectedPipelineValue ||
      type == DashboardKpiType.expectedCommission;
}

String _timeLabel(BuildContext context, DateTime? date) {
  final l = AppLocalizations.of(context)!;
  if (date == null) {
    return l.notAvailable;
  }
  return intl.DateFormat.jm(l.localeName).format(date.toLocal());
}

String _ageLabel(BuildContext context, DateTime? date) {
  final l = AppLocalizations.of(context)!;
  if (date == null) {
    return l.notAvailable;
  }
  final days = _dateOnly(DateTime.now()).difference(_dateOnly(date)).inDays;
  if (days <= 0) {
    return l.dashboardTodayShort;
  }
  return l.dashboardDaysAgo(days);
}

Color _urgencyColor(BuildContext context, DashboardTodayUrgency urgency) {
  return switch (urgency) {
    DashboardTodayUrgency.overdue => AppColors.errorColor(context),
    DashboardTodayUrgency.dueToday => AppColors.warningColor(context),
    DashboardTodayUrgency.normal => AppColors.infoColor(context),
  };
}

int _urgencyRank(DashboardTodayUrgency urgency) {
  return switch (urgency) {
    DashboardTodayUrgency.overdue => 3,
    DashboardTodayUrgency.dueToday => 2,
    DashboardTodayUrgency.normal => 1,
  };
}

String _fallback(String value, String fallback) {
  final trimmed = value.trim();
  return trimmed.isNotEmpty ? trimmed : fallback.trim();
}

Color _toneColor(BuildContext context, AppStatusTone tone) {
  return switch (tone) {
    AppStatusTone.success => AppColors.successColor(context),
    AppStatusTone.warning => AppColors.warningColor(context),
    AppStatusTone.error => AppColors.errorColor(context),
    AppStatusTone.info => AppColors.infoColor(context),
    AppStatusTone.neutral => AppColors.textMutedColor(context),
    _ => AppColors.textMutedColor(context),
  };
}

String _initials(String name) {
  final words = name.trim().split(RegExp(r'\s+')).where((item) => item.isNotEmpty);
  if (words.isEmpty) {
    return 'M';
  }
  return words.take(2).map((item) => item.characters.first.toUpperCase()).join();
}
