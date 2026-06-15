import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' as intl;

import '../../../../core/auth/protected_company_session.dart';
import '../../../../core/constants/role_constants.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/masar_refresh_indicator.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_pagination_footer.dart';
import '../../../../core/widgets/app_dropdown.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_status_badge.dart';
import '../../../../core/widgets/app_scroll_surface.dart';
import '../../../../core/widgets/crm_app_shell.dart';
import '../../../../core/widgets/masar_tab_bar.dart';
import '../../../../core/widgets/module_kpi_card.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../dashboard/domain/services/dashboard_truth_rules.dart';
import '../../../users/data/datasources/user_profile_remote_data_source.dart';
import '../../../users/data/repositories/user_profile_repository_impl.dart';
import '../../../users/domain/entities/user_profile.dart';
import '../../../users/domain/usecases/watch_active_users_usecase.dart';
import '../../domain/entities/appointment.dart';
import '../cubit/appointments_cubit.dart';
import '../cubit/appointments_state.dart';
import '../widgets/appointment_form.dart';
import '../widgets/appointments_scope.dart';

class AppointmentsPage extends StatelessWidget {
  const AppointmentsPage({super.key, this.initialFilters = const {}});

  final Map<String, String> initialFilters;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return CrmAppShell(
      selectedItem: CrmNavigationItem.appointments,
      title: l.appointments,
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
          final role = profile.role;
          if (companyId.isEmpty) {
            return AppErrorView(message: l.missingCompanyProfile);
          }
          if (role == UserRole.viewer) {
            return AppErrorView(message: l.permissionDenied);
          }

          String? assignedTo;
          String? managerId;
          String? teamId;
          if (role == UserRole.manager) {
            managerId = profile.uid;
            teamId = profile.teamId.trim().isEmpty ? null : profile.teamId;
          } else if (role == UserRole.salesAgent ||
              role == UserRole.marketing) {
            assignedTo = profile.uid;
          }
          final scopeKey = ValueKey(session.scopeKey('appointments-scope'));

          return AppointmentsScope(
            key: scopeKey,
            child: _AppointmentsContent(
              key: ValueKey(session.scopeKey('appointments-content')),
              companyId: companyId,
              uid: profile.uid,
              role: role,
              assignedTo: assignedTo,
              managerId: managerId,
              teamId: teamId,
              initialFilters: initialFilters,
            ),
          );
        },
      ),
    );
  }
}

class _AppointmentsContent extends StatefulWidget {
  const _AppointmentsContent({
    super.key,
    required this.companyId,
    required this.uid,
    required this.role,
    this.assignedTo,
    this.managerId,
    this.teamId,
    required this.initialFilters,
  });

  final String companyId;
  final String uid;
  final UserRole role;
  final String? assignedTo;
  final String? managerId;
  final String? teamId;
  final Map<String, String> initialFilters;

  @override
  State<_AppointmentsContent> createState() => _AppointmentsContentState();
}

class _AppointmentsContentState extends State<_AppointmentsContent> {
  Timer? _clockTicker;
  int _clockPulse = 0;
  int _selectedTab = 0;
  String? _appliedFilterSignature;
  final Set<String> _dismissedAttentionAppointmentIds = <String>{};

  @override
  void initState() {
    super.initState();
    _watchAppointments();
    _clockTicker = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) {
        setState(() {
          _clockPulse++;
        });
      }
    });
  }

  @override
  void didUpdateWidget(covariant _AppointmentsContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.companyId != widget.companyId ||
        oldWidget.assignedTo != widget.assignedTo ||
        oldWidget.managerId != widget.managerId ||
        oldWidget.teamId != widget.teamId) {
      _watchAppointments();
    } else if (_filterSignature(oldWidget.initialFilters) !=
        _filterSignature(widget.initialFilters)) {
      _applyInitialFiltersIfNeeded();
    }
  }

  void _watchAppointments({bool attentionMode = false}) {
    final dateWindow = _appointmentsRollingDateWindow();
    context.read<AppointmentsCubit>().watchAppointments(
          companyId: widget.companyId,
          assignedTo: widget.assignedTo,
          managerId: widget.managerId,
          teamId: widget.teamId,
          rangeStart: dateWindow.start,
          rangeEnd: dateWindow.end,
          usePagination: !attentionMode,
        );
    _applyInitialFiltersIfNeeded();
  }

  void _setSelectedTab(int index) {
    if (_selectedTab == index) {
      return;
    }
    setState(() => _selectedTab = index);
    _watchAppointments(attentionMode: index == 1);
  }

  void _showAppointmentsTab() {
    if (_selectedTab == 0) {
      return;
    }
    setState(() => _selectedTab = 0);
    _watchAppointments();
  }

  void _applyInitialFiltersIfNeeded() {
    final signature = _filterSignature(widget.initialFilters);
    if (signature.isEmpty || _appliedFilterSignature == signature) {
      return;
    }
    _appliedFilterSignature = signature;
    final filters = widget.initialFilters;
    final cubit = context.read<AppointmentsCubit>();
    final selectedDate = _parseQueryDate(filters['selectedDate']);
    if (selectedDate != null) {
      cubit.setSelectedDateFilter(selectedDate);
    } else {
      cubit.setDateFilter(_appointmentDateFilter(filters['date']));
    }
    cubit.setStatusFilter(
      _enumByName(AppointmentStatus.values, filters['status']),
    );
    if (filters.containsKey('assignedTo')) {
      cubit.setAssignedToFilter(filters['assignedTo'] ?? '');
    }
  }

  @override
  void dispose() {
    _clockTicker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final canCreate = widget.role != UserRole.viewer;
    final canManage = widget.role != UserRole.viewer;
    final canFilterByAssignee =
        widget.role == UserRole.admin || widget.role == UserRole.manager;

    return StreamBuilder<List<UserProfile>>(
      stream: canFilterByAssignee ? _watchActiveUsers(widget.companyId) : null,
      builder: (context, usersSnapshot) {
        final users = usersSnapshot.data ?? const [];
        return BlocConsumer<AppointmentsCubit, AppointmentsState>(
          listenWhen: (previous, current) =>
              previous.status != current.status ||
              previous.lastAction != current.lastAction ||
              previous.message != current.message,
          listener: (context, state) {
            if (state.status == AppointmentsStatus.failure &&
                (state.message?.isNotEmpty ?? false)) {
              if (_isNonBlockingAppointmentsWatchFailure(state)) {
                debugPrint(
                  'MasarAppointments: non-blocking watch failure suppressed: '
                  '${state.message}',
                );
                return;
              }
              AppFeedback.error(
                context,
                localizeErrorMessage(l, state.message),
              );
              return;
            }
            if (state.status != AppointmentsStatus.saved ||
                state.lastAction == null) {
              return;
            }
            AppFeedback.success(
              context,
              _actionSuccessLabel(l, state.lastAction!),
            );
            context.read<AppointmentsCubit>().clearAction();
          },
          builder: (context, state) {
            return LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 720;
                final attentionAppointments =
                    _attentionAppointments(state.appointments)
                        .where((appointment) =>
                            !_dismissedAttentionAppointmentIds.contains(
                              appointment.id,
                            ))
                        .toList();
                final attention = _AppointmentsAttentionStrip(
                  key: ValueKey('appointments-attention-${widget.companyId}:${widget.uid}:$_clockPulse'),
                  appointments: attentionAppointments,
                  users: users,
                  companyId: widget.companyId,
                  uid: widget.uid,
                  canManage: canManage,
                  onDismiss: (appointmentId) {
                    setState(() {
                      _dismissedAttentionAppointmentIds.add(appointmentId);
                    });
                  },
                );
                final header = _AppointmentsHeader(
                  canCreate: canCreate,
                  onCreate: () => context.go(RouteNames.appointmentsCreate),
                );
                final summary = _AppointmentsSummary(
                  state: state,
                  onKpiSelected: _showAppointmentsTab,
                );
                final tabs = _AppointmentsTabs(
                  selectedIndex: _selectedTab,
                  attentionCount: _attentionBadgeCount(state, attentionAppointments),
                  onChanged: _setSelectedTab,
                );
                final filters = _AppointmentsFilters(
                  state: state,
                  users: users,
                  showAssigneeFilter: canFilterByAssignee,
                );
                final body = _AppointmentsBody(
                  companyId: widget.companyId,
                  uid: widget.uid,
                  state: state,
                  users: users,
                  canManage: canManage,
                  assignedTo: widget.assignedTo,
                  managerId: widget.managerId,
                  teamId: widget.teamId,
                  onLoadMore: () =>
                      context.read<AppointmentsCubit>().loadMoreAppointments(),
                );
                final showAttentionTab = _selectedTab == 1;

                if (isMobile) {
                  return SingleChildScrollView(
                    physics: const MasarRefreshPhysics(parent: BouncingScrollPhysics()),
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        header,
                        const SizedBox(height: AppSpacing.xs),
                        summary,
                        const SizedBox(height: AppSpacing.sm),
                        tabs,
                        const SizedBox(height: AppSpacing.sm),
                        if (showAttentionTab)
                          attention
                        else ...[
                          filters,
                          const SizedBox(height: AppSpacing.sm),
                          body,
                        ],
                        const SizedBox(height: 96),
                      ],
                    ),
                  );
                }

                return SingleChildScrollView(
                  physics: const MasarRefreshPhysics(parent: BouncingScrollPhysics()),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      header,
                      const SizedBox(height: AppSpacing.xs),
                      summary,
                      const SizedBox(height: AppSpacing.xs),
                      tabs,
                      const SizedBox(height: AppSpacing.xs),
                      if (showAttentionTab)
                        attention
                      else ...[
                        filters,
                        const SizedBox(height: AppSpacing.xs),
                        body,
                      ],
                      const SizedBox(height: 96),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _AppointmentsTabs extends StatelessWidget {
  const _AppointmentsTabs({
    required this.selectedIndex,
    required this.attentionCount,
    required this.onChanged,
  });

  final int selectedIndex;
  final int attentionCount;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return MasarSwitchTabBar(
      compact: true,
      selectedIndex: selectedIndex,
      onChanged: onChanged,
      tabs: [
        MasarSwitchTabItem(
          label: l.appointments,
          icon: Icons.event_available_outlined,
        ),
        MasarSwitchTabItem(
          label: l.attentionNeeded,
          icon: Icons.notifications_active_outlined,
          badge: attentionCount > 0 ? attentionCount.toString() : null,
        ),
      ],
    );
  }
}

class _AppointmentsHeader extends StatelessWidget {
  const _AppointmentsHeader({
    required this.canCreate,
    required this.onCreate,
  });

  final bool canCreate;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 8 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Row(
        children: [
          Expanded(
            child: Text(
              l.appointmentsSubtitle,
              maxLines: 3,
              softWrap: true,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondaryColor(context),
                  ),
            ),
          ),
          if (canCreate) ...[
            const SizedBox(width: AppSpacing.md),
            AppButton(
              label: l.newAppointment,
              icon: Icons.add,
              onPressed: onCreate,
            ),
          ],
        ],
      ),
    );
  }
}

class _AppointmentsSummary extends StatelessWidget {
  const _AppointmentsSummary({required this.state, this.onKpiSelected});

  final AppointmentsState state;
  final VoidCallback? onKpiSelected;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cubit = context.read<AppointmentsCubit>();
    final cards = [
      ModuleKpiCardData(
        label: l.allAppointments,
        value: state.kpiCounts.display(
          'listTotal',
          unavailableLabel: l.notAvailable,
          failureLabel: l.errorOccurred,
        ),
        icon: Icons.event_note_outlined,
        tone: AppStatusTone.neutral,
        selected: state.dateFilter == AppointmentDateFilter.all &&
            state.statusFilter == null,
        onTap: () {
          onKpiSelected?.call();
          cubit.showAllAppointments();
        },
      ),
      ModuleKpiCardData(
        label: l.todaysAppointments,
        value: state.kpiCounts.display(
          'today',
          unavailableLabel: l.notAvailable,
          failureLabel: l.errorOccurred,
        ),
        icon: Icons.today_outlined,
        tone: AppStatusTone.info,
        selected: state.dateFilter == AppointmentDateFilter.today,
        onTap: () {
          onKpiSelected?.call();
          cubit.clearFilters();
          cubit.setDateFilter(AppointmentDateFilter.today);
        },
      ),
      ModuleKpiCardData(
        label: l.upcomingAppointments,
        value: state.kpiCounts.display(
          'upcoming',
          unavailableLabel: l.notAvailable,
          failureLabel: l.errorOccurred,
        ),
        icon: Icons.event_available_outlined,
        tone: AppStatusTone.warning,
        selected: state.dateFilter == AppointmentDateFilter.upcoming,
        onTap: () {
          onKpiSelected?.call();
          cubit.clearFilters();
          cubit.setDateFilter(AppointmentDateFilter.upcoming);
        },
      ),
      ModuleKpiCardData(
        label: l.missedAppointments,
        value: state.kpiCounts.display(
          'missed',
          unavailableLabel: l.notAvailable,
          failureLabel: l.errorOccurred,
        ),
        icon: Icons.event_busy_outlined,
        tone: AppStatusTone.error,
        selected: state.dateFilter == AppointmentDateFilter.missed,
        onTap: () {
          onKpiSelected?.call();
          cubit.clearFilters();
          cubit.setDateFilter(AppointmentDateFilter.missed);
        },
      ),
      ModuleKpiCardData(
        label: l.cancelledAppointments,
        value: state.kpiCounts.display(
          'cancelled',
          unavailableLabel: l.notAvailable,
          failureLabel: l.errorOccurred,
        ),
        icon: Icons.event_busy_outlined,
        tone: AppStatusTone.neutral,
        selected: state.statusFilter == AppointmentStatus.cancelled,
        onTap: () {
          onKpiSelected?.call();
          cubit.clearFilters();
          cubit.setStatusFilter(AppointmentStatus.cancelled);
        },
      ),
      ModuleKpiCardData(
        label: l.completedAppointments,
        value: state.kpiCounts.display(
          'completed',
          unavailableLabel: l.notAvailable,
          failureLabel: l.errorOccurred,
        ),
        icon: Icons.verified_outlined,
        tone: AppStatusTone.success,
        selected: state.statusFilter == AppointmentStatus.completed,
        onTap: () {
          onKpiSelected?.call();
          cubit.clearFilters();
          cubit.setStatusFilter(AppointmentStatus.completed);
        },
      ),
    ];

    return ModuleKpiStrip(cards: cards);
  }
}

class _AppointmentsAttentionStrip extends StatefulWidget {
  const _AppointmentsAttentionStrip({
    super.key,
    required this.appointments,
    required this.users,
    required this.companyId,
    required this.uid,
    required this.canManage,
    required this.onDismiss,
  });

  final List<Appointment> appointments;
  final List<UserProfile> users;
  final String companyId;
  final String uid;
  final bool canManage;
  final ValueChanged<String> onDismiss;

  @override
  State<_AppointmentsAttentionStrip> createState() =>
      _AppointmentsAttentionStripState();
}

class _AppointmentsAttentionStripState
    extends State<_AppointmentsAttentionStrip> {
  bool _expanded = false;

  @override
  void didUpdateWidget(covariant _AppointmentsAttentionStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.appointments.length <= _attentionPageSize && _expanded) {
      _expanded = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    if (widget.appointments.isEmpty) {
      return _AnimatedEmptyState(
        child: AppEmptyState(
          title: l.attentionNeeded,
          message: l.noAppointmentsMatchFilters,
          icon: Icons.notifications_active_outlined,
        ),
      );
    }
    final canToggle = widget.appointments.length > _attentionPageSize;
    final itemCount = _expanded
        ? widget.appointments.length
        : widget.appointments.length > _attentionPageSize
            ? _attentionPageSize
            : widget.appointments.length;
    final visibleRows = itemCount > 6 ? 6 : itemCount;
    final listHeight = (visibleRows * 78.0).toDouble();

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 260),
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
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.cardSurface(context),
          border: Border.all(color: AppColors.borderColor(context)),
          borderRadius: AppRadius.large,
          boxShadow: Theme.of(context).brightness == Brightness.dark
              ? null
              : AppShadows.card,
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.warningColor(context)
                          .withValues(alpha: 0.10),
                      borderRadius: AppRadius.medium,
                    ),
                    child: Icon(
                      Icons.notifications_active_outlined,
                      size: 16,
                      color: AppColors.warningColor(context),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      l.appointmentAttention,
                      maxLines: 2,
                      softWrap: true,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                  ),
                  AppStatusBadge(
                    label: widget.appointments.length.toString(),
                    tone: AppStatusTone.warning,
                  ),
                  if (canToggle) ...[
                    const SizedBox(width: AppSpacing.xs),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: () => setState(() => _expanded = !_expanded),
                      icon: AnimatedRotation(
                        turns: _expanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 180),
                        child: const Icon(Icons.keyboard_arrow_down_rounded),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              SizedBox(
                height: listHeight,
                child: ListView.builder(
                  primary: false,
                  physics: itemCount > 6
                      ? const ClampingScrollPhysics()
                      : const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  itemCount: itemCount,
                  itemBuilder: (context, index) {
                    return _AnimatedListItem(
                      index: index,
                      child: _AppointmentAttentionTile(
                        appointment: widget.appointments[index],
                        users: widget.users,
                        companyId: widget.companyId,
                        uid: widget.uid,
                        canManage: widget.canManage,
                        onDismiss: widget.onDismiss,
                      ),
                    );
                  },
                ),
              ),
              if (canToggle) ...[
                const SizedBox(height: AppSpacing.xs),
                Align(
                  alignment: AlignmentDirectional.center,
                  child: AppButton(
                    label: _expanded
                        ? l.collapseAttentionNeeded
                        : '${l.more} +${widget.appointments.length - _attentionPageSize}',
                    icon: _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.expand_more_rounded,
                    variant: AppButtonVariant.secondary,
                    onPressed: () => setState(() => _expanded = !_expanded),
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

class _AppointmentAttentionTile extends StatelessWidget {
  const _AppointmentAttentionTile({
    required this.appointment,
    required this.users,
    required this.companyId,
    required this.uid,
    required this.canManage,
    required this.onDismiss,
  });

  final Appointment appointment;
  final List<UserProfile> users;
  final String companyId;
  final String uid;
  final bool canManage;
  final ValueChanged<String> onDismiss;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final type = _appointmentAttentionType(appointment);
    final tone = _appointmentAttentionTone(type);
    final color = _toneColor(context, tone);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: AppRadius.medium,
        onTap: canManage
            ? () => context.go(RouteNames.appointmentEdit(appointment.id))
            : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.10),
                      borderRadius: AppRadius.medium,
                    ),
                    child: Icon(
                      _appointmentAttentionIcon(type),
                      color: color,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      appointment.title,
                      maxLines: 2,
                      softWrap: true,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
                  IconButton(
                    tooltip: l.clearNotification,
                    visualDensity: VisualDensity.compact,
                    onPressed: () => onDismiss(appointment.id),
                    icon: const Icon(Icons.close_rounded, size: 18),
                  ),
                  if (canManage)
                    _AppointmentActions(
                      appointment: appointment,
                      companyId: companyId,
                      updatedBy: uid,
                      compact: true,
                    ),
                ],
              ),
              const SizedBox(height: 2),
              Padding(
                padding: const EdgeInsetsDirectional.only(start: 36),
                child: Row(
                  children: [
                    _AnimatedStatusBadge(
                      label: _appointmentAttentionLabel(l, type),
                      tone: tone,
                      statusKey: type?.name ?? 'scheduled',
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        _appointmentAttentionSubtitle(l, appointment, users),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondaryColor(context),
                            ),
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

class _AppointmentsFilters extends StatelessWidget {
  const _AppointmentsFilters({
    required this.state,
    required this.users,
    required this.showAssigneeFilter,
  });

  final AppointmentsState state;
  final List<UserProfile> users;
  final bool showAssigneeFilter;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cubit = context.read<AppointmentsCubit>();
    final hasFilters = state.statusFilter != null ||
        state.typeFilter != null ||
        state.dateFilter != null ||
        state.selectedDateFilter != null ||
        state.assignedToFilter.trim().isNotEmpty;

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 720;
        final search = TextField(
          onChanged: cubit.setSearchQuery,
          decoration: InputDecoration(
            labelText: l.searchAppointments,
            prefixIcon: const Icon(Icons.search),
          ),
        );
        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(child: search),
                  const SizedBox(width: AppSpacing.sm),
                  AppButton(
                    label: l.filters,
                    icon: Icons.tune,
                    variant: AppButtonVariant.secondary,
                    onPressed: () => _showFiltersSheet(
                      context,
                      state: state,
                      users: users,
                      showAssigneeFilter: showAssigneeFilter,
                    ),
                  ),
                ],
              ),
              if (hasFilters) ...[
                const SizedBox(height: AppSpacing.sm),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: AppButton(
                    label: l.clearFilters,
                    variant: AppButtonVariant.secondary,
                    onPressed: cubit.clearFilters,
                  ),
                ),
              ],
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: search),
            const SizedBox(width: AppSpacing.sm),
            AppButton(
              label: l.filters,
              icon: Icons.tune,
              variant: AppButtonVariant.secondary,
              onPressed: () => _showFiltersSheet(
                context,
                state: state,
                users: users,
                showAssigneeFilter: showAssigneeFilter,
              ),
            ),
            if (hasFilters) ...[
              const SizedBox(width: AppSpacing.sm),
              AppButton(
                label: l.clearFilters,
                icon: Icons.filter_alt_off_outlined,
                variant: AppButtonVariant.secondary,
                onPressed: cubit.clearFilters,
              ),
            ],
          ],
        );
      },
    );
  }
}

Future<void> _showFiltersSheet(
  BuildContext context, {
  required AppointmentsState state,
  required List<UserProfile> users,
  required bool showAssigneeFilter,
}) async {
  final l = AppLocalizations.of(context)!;
  final cubit = context.read<AppointmentsCubit>();
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) {
      return BlocProvider.value(
        value: cubit,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              AppSpacing.md,
              AppSpacing.md,
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
                        l.filters,
                        style: Theme.of(sheetContext)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(sheetContext).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.md,
                  children: [
                    SizedBox(
                      width: 220,
                      child: AppDropdown<_FilterOption<AppointmentDateFilter>>(
                        label: l.filterByDate,
                        value: _FilterOption.fromValue(state.dateFilter),
                        items: _filterOptions(
                          AppointmentDateFilter.values.where(
                            (filter) => filter != AppointmentDateFilter.all,
                          ),
                        ),
                        itemLabelBuilder: (option) => option.isAll
                            ? l.allAppointments
                            : _dateFilterLabel(l, option.value!),
                        onChanged: (option) =>
                            cubit.setDateFilter(option.value),
                      ),
                    ),
                    SizedBox(
                      width: 220,
                      child: AppDropdown<_FilterOption<AppointmentStatus>>(
                        label: l.filterByStatus,
                        value: _FilterOption.fromValue(state.statusFilter),
                        items: _filterOptions(AppointmentStatus.values),
                        itemLabelBuilder: (option) => option.isAll
                            ? l.allStatuses
                            : appointmentStatusLabel(l, option.value!),
                        onChanged: (option) =>
                            cubit.setStatusFilter(option.value),
                      ),
                    ),
                    SizedBox(
                      width: 220,
                      child: AppDropdown<_FilterOption<AppointmentType>>(
                        label: l.filterByType,
                        value: _FilterOption.fromValue(state.typeFilter),
                        items: _filterOptions(AppointmentType.values),
                        itemLabelBuilder: (option) => option.isAll
                            ? l.allAppointmentTypes
                            : appointmentTypeLabel(l, option.value!),
                        onChanged: (option) =>
                            cubit.setTypeFilter(option.value),
                      ),
                    ),
                    if (showAssigneeFilter)
                      SizedBox(
                        width: 220,
                        child: AppDropdown<_AssigneeFilterOption>(
                          label: l.assignedUser,
                          value: _AssigneeFilterOption.fromValue(
                            state.assignedToFilter,
                          ),
                          items: _assigneeFilterOptions(users),
                          itemLabelBuilder: (option) => option.isAll
                              ? l.allAssignees
                              : _assigneeLabel(l, users, option.value),
                          onChanged: (option) =>
                              cubit.setAssignedToFilter(option.value ?? ''),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                AppButton(
                  label: l.clearFilters,
                  variant: AppButtonVariant.secondary,
                  onPressed: () {
                    cubit.clearFilters();
                    Navigator.of(sheetContext).pop();
                  },
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _AppointmentsBody extends StatelessWidget {
  const _AppointmentsBody({
    required this.companyId,
    required this.uid,
    required this.state,
    required this.users,
    required this.canManage,
    required this.onLoadMore,
    this.assignedTo,
    this.managerId,
    this.teamId,
  });

  final String companyId;
  final String uid;
  final AppointmentsState state;
  final List<UserProfile> users;
  final bool canManage;
  final VoidCallback onLoadMore;
  final String? assignedTo;
  final String? managerId;
  final String? teamId;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    if ((state.status == AppointmentsStatus.initial ||
            state.status == AppointmentsStatus.loading) &&
        state.appointments.isEmpty) {
      return const AppLoading();
    }
    if (state.status == AppointmentsStatus.failure &&
        state.appointments.isEmpty) {
      return AppErrorView(
        message: localizeErrorMessage(l, state.message),
        onRetry: () {
          final dateWindow = _appointmentsRollingDateWindow();
          context.read<AppointmentsCubit>().watchAppointments(
                companyId: companyId,
                assignedTo: assignedTo,
                managerId: managerId,
                teamId: teamId,
                rangeStart: dateWindow.start,
                rangeEnd: dateWindow.end,
                limit: state.pageLimit,
                resetPage: false,
              );
        },
      );
    }
    if (state.appointments.isEmpty) {
      if (state.dateFilter == AppointmentDateFilter.missed) {
        return _AnimatedEmptyState(
          child: AppEmptyState(
            title: l.noMissedAppointments,
            message: l.noAppointmentsMatchFilters,
            icon: Icons.event_busy_outlined,
          ),
        );
      }
      return _AnimatedEmptyState(
        child: AppEmptyState(
          title: l.noAppointmentsYet,
          message: l.createFirstAppointment,
          icon: Icons.event_available_outlined,
        ),
      );
    }
    if (state.filteredAppointments.isEmpty) {
      return _withLoadMoreFooter(
        context,
        _AnimatedEmptyState(
          child: AppEmptyState(
            title: state.dateFilter == AppointmentDateFilter.missed
                ? l.noMissedAppointments
                : l.noAppointmentsMatchFilters,
            message: l.clearFilters,
            icon: state.dateFilter == AppointmentDateFilter.missed
                ? Icons.event_busy_outlined
                : Icons.manage_search_outlined,
          ),
        ),
      );
    }

    if (_shouldShowFilteredAppointmentsAgenda(state)) {
      final visibleAppointments = _visiblePagedAppointments(state);
      return _withLoadMoreFooter(
        context,
        SingleChildScrollView(
          primary: false,
          physics: const ClampingScrollPhysics(),
          child: _AgendaPanel(
            title: _appointmentsFilterTitle(l, state),
            appointments: visibleAppointments,
            companyId: companyId,
            uid: uid,
            users: users,
            canManage: canManage,
            emptyMessage: state.dateFilter == AppointmentDateFilter.missed
                ? l.noMissedAppointments
                : l.noAppointmentsMatchFilters,
          ),
        ),
        visibleCount: visibleAppointments.length,
        totalCountOverride: state.filteredAppointments.length,
      );
    }

    return _withLoadMoreFooter(
      context,
      _AppointmentsCalendarWorkspace(
        state: state,
        companyId: companyId,
        uid: uid,
        users: users,
        canManage: canManage,
      ),
      visibleCount: _visibleCalendarAppointmentCount(context, state),
      visibleCountMatchesLoadedScope: false,
    );
  }

  Widget _withLoadMoreFooter(
    BuildContext context,
    Widget child, {
    int? visibleCount,
    int? totalCountOverride,
    bool visibleCountMatchesLoadedScope = true,
  }) {
    const pageSize = 15;
    final loadedCount = visibleCount ?? state.filteredAppointments.length;
    if (!state.canLoadMore || loadedCount < pageSize) {
      return child;
    }
    final totalCount = totalCountOverride ??
        (visibleCountMatchesLoadedScope ? state.filteredTotalCount : null);

    final footer = Padding(
      padding: const EdgeInsetsDirectional.only(top: AppSpacing.sm),
      child: Align(
        alignment: AlignmentDirectional.center,
        child: _LoadMoreAppointmentsButton(
          loadedCount: loadedCount,
          totalCount: totalCount,
          pageSize: pageSize,
          isLoading: state.status == AppointmentsStatus.loadingMore,
          onPressed: onLoadMore,
        ),
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.hasBoundedHeight) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: child),
              footer,
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            child,
            footer,
          ],
        );
      },
    );
  }
}

class _AppointmentsCalendarWorkspace extends StatelessWidget {
  const _AppointmentsCalendarWorkspace({
    required this.state,
    required this.companyId,
    required this.uid,
    required this.users,
    required this.canManage,
  });

  final AppointmentsState state;
  final String companyId;
  final String uid;
  final List<UserProfile> users;
  final bool canManage;

  @override
  Widget build(BuildContext context) {
    final selectedDate = state.selectedCalendarDate ?? _dateOnly(DateTime.now());
    final content = _CalendarWorkspaceContent(
      state: state,
      selectedDate: selectedDate,
      companyId: companyId,
      uid: uid,
      users: users,
      canManage: canManage,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final child = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _CalendarViewSelector(
              selectedView: state.calendarView,
              onChanged: context.read<AppointmentsCubit>().setCalendarView,
            ),
            const SizedBox(height: AppSpacing.sm),
            content,
          ],
        );

        if (!constraints.hasBoundedHeight) {
          return child;
        }
        return SingleChildScrollView(
          primary: false,
          physics: const ClampingScrollPhysics(),
          child: child,
        );
      },
    );
  }
}

class _CalendarWorkspaceContent extends StatelessWidget {
  const _CalendarWorkspaceContent({
    required this.state,
    required this.selectedDate,
    required this.companyId,
    required this.uid,
    required this.users,
    required this.canManage,
  });

  final AppointmentsState state;
  final DateTime selectedDate;
  final String companyId;
  final String uid;
  final List<UserProfile> users;
  final bool canManage;

  @override
  Widget build(BuildContext context) {
    final appointments = state.filteredAppointments;
    final effectiveSelectedDate = state.calendarView == AppointmentCalendarView.today
        ? _dateOnly(DateTime.now())
        : selectedDate;
    final selectedDayAppointments =
        _appointmentsForDay(appointments, effectiveSelectedDate);

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 780;
        final agenda = _AgendaPanel(
          title: state.calendarView == AppointmentCalendarView.today
              ? AppLocalizations.of(context)!.todayAgenda
              : _agendaTitle(context, effectiveSelectedDate),
          appointments: selectedDayAppointments,
          companyId: companyId,
          uid: uid,
          users: users,
          canManage: canManage,
          emptyMessage: _emptyAgendaMessage(context, state.calendarView),
          trailing: state.calendarView == AppointmentCalendarView.day
              ? _CalendarNavigation(
                  selectedDate: effectiveSelectedDate,
                  onPrevious: () => context
                      .read<AppointmentsCubit>()
                      .setSelectedCalendarDate(
                        effectiveSelectedDate.subtract(const Duration(days: 1)),
                      ),
                  onToday: () => context
                      .read<AppointmentsCubit>()
                      .setSelectedCalendarDate(_dateOnly(DateTime.now())),
                  onNext: () => context
                      .read<AppointmentsCubit>()
                      .setSelectedCalendarDate(
                        effectiveSelectedDate.add(const Duration(days: 1)),
                      ),
                )
              : null,
        );

        switch (state.calendarView) {
          case AppointmentCalendarView.month:
            final month = _MonthCalendarPanel(
              selectedDate: selectedDate,
              appointments: appointments,
              onDateSelected:
                  context.read<AppointmentsCubit>().setSelectedCalendarDate,
            );
            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  month,
                  const SizedBox(height: AppSpacing.sm),
                  agenda,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: month),
                const SizedBox(width: AppSpacing.sm),
                Expanded(flex: 2, child: agenda),
              ],
            );
          case AppointmentCalendarView.week:
            return _WeekAgendaPanel(
              selectedDate: selectedDate,
              appointments: appointments,
              companyId: companyId,
              uid: uid,
              users: users,
              canManage: canManage,
              onDateSelected:
                  context.read<AppointmentsCubit>().setSelectedCalendarDate,
            );
          case AppointmentCalendarView.day:
            final dayCalendar = _MonthCalendarPanel(
              selectedDate: selectedDate,
              appointments: appointments,
              onDateSelected:
                  context.read<AppointmentsCubit>().setSelectedCalendarDate,
            );
            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  dayCalendar,
                  const SizedBox(height: AppSpacing.sm),
                  agenda,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: dayCalendar),
                const SizedBox(width: AppSpacing.sm),
                Expanded(flex: 2, child: agenda),
              ],
            );
          case AppointmentCalendarView.today:
            return agenda;
        }
      },
    );
  }
}

class _CalendarViewSelector extends StatelessWidget {
  const _CalendarViewSelector({
    required this.selectedView,
    required this.onChanged,
  });

  final AppointmentCalendarView selectedView;
  final ValueChanged<AppointmentCalendarView> onChanged;

  @override
  Widget build(BuildContext context) {
    final values = AppointmentCalendarView.values;
    return MasarSwitchTabBar(
      compact: true,
      selectedIndex: values.indexOf(selectedView),
      onChanged: (index) => onChanged(values[index]),
      tabs: [
        for (final view in values)
          MasarSwitchTabItem(
            label: _calendarViewLabel(context, view),
            icon: _calendarViewIcon(view),
          ),
      ],
    );
  }
}

class _MonthCalendarPanel extends StatelessWidget {
  const _MonthCalendarPanel({
    required this.selectedDate,
    required this.appointments,
    required this.onDateSelected,
  });

  final DateTime selectedDate;
  final List<Appointment> appointments;
  final ValueChanged<DateTime> onDateSelected;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final localeName = l.localeName;
    final visibleDays = _visibleMonthDays(context, selectedDate);
    final monthLabel = intl.DateFormat.yMMMM(localeName).format(selectedDate);
    final weekLabels = _weekdayLabels(context);

    return _WorkspacePanel(
      title: l.appointmentCalendarMonthView,
      subtitle: monthLabel,
      icon: Icons.calendar_month_outlined,
      trailing: _CalendarNavigation(
        selectedDate: selectedDate,
        onPrevious: () => onDateSelected(
          DateTime(selectedDate.year, selectedDate.month - 1, 1),
        ),
        onToday: () => onDateSelected(_dateOnly(DateTime.now())),
        onNext: () => onDateSelected(
          DateTime(selectedDate.year, selectedDate.month + 1, 1),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              for (final label in weekLabels)
                Expanded(
                  child: Center(
                    child: Text(
                      label,
                      maxLines: 2,
                      softWrap: true,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.textSecondaryColor(context),
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          GridView.builder(
            shrinkWrap: true,
            primary: false,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              childAspectRatio: 0.92,
            ),
            itemCount: visibleDays.length,
            itemBuilder: (context, index) {
              final day = visibleDays[index];
              final dayAppointments = _appointmentsForDay(appointments, day);
              return _MonthDayCell(
                day: day,
                selected: _sameDay(day, selectedDate),
                inCurrentMonth: day.month == selectedDate.month,
                appointments: dayAppointments,
                onTap: () => onDateSelected(day),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _MonthDayCell extends StatelessWidget {
  const _MonthDayCell({
    required this.day,
    required this.selected,
    required this.inCurrentMonth,
    required this.appointments,
    required this.onTap,
  });

  final DateTime day;
  final bool selected;
  final bool inCurrentMonth;
  final List<Appointment> appointments;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = _sameDay(day, now);
    final missed = appointments.where((item) {
      return _effectiveStatus(item) == AppointmentStatus.missed;
    }).length;
    final completed = appointments
        .where((item) => item.status == AppointmentStatus.completed)
        .length;
    final cancelled = appointments
        .where((item) => item.status == AppointmentStatus.cancelled)
        .length;
    final open = appointments.length - completed - cancelled;
    final primary = AppColors.primaryColor(context);
    final borderColor = selected
        ? primary
        : today
            ? primary.withValues(alpha: 0.45)
            : AppColors.borderColor(context);

    return Material(
      color: selected
          ? primary.withValues(alpha: 0.10)
          : AppColors.inputSurface(context),
      borderRadius: AppRadius.medium,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.medium,
        child: Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            border: Border.all(color: borderColor),
            borderRadius: AppRadius.medium,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      day.day.toString(),
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: inCurrentMonth
                                ? AppColors.textPrimaryColor(context)
                                : AppColors.textMutedColor(context),
                            fontWeight: selected || today
                                ? FontWeight.w900
                                : FontWeight.w700,
                          ),
                    ),
                  ),
                  if (appointments.isNotEmpty)
                    Text(
                      appointments.length.toString(),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: primary,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                ],
              ),
              const Spacer(),
              if (appointments.isEmpty)
                Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderColor(context),
                    borderRadius: BorderRadius.circular(999),
                  ),
                )
              else
                Row(
                  children: [
                    if (open > 0)
                      Expanded(
                        flex: open.clamp(1, 9).toInt(),
                        child: _DensityBar(
                          color: missed > 0
                              ? AppColors.errorColor(context)
                              : AppColors.warningColor(context),
                        ),
                      ),
                    if (completed > 0) ...[
                      const SizedBox(width: 3),
                      Expanded(
                        flex: completed.clamp(1, 9).toInt(),
                        child: _DensityBar(
                          color: AppColors.successColor(context),
                        ),
                      ),
                    ],
                    if (cancelled > 0) ...[
                      const SizedBox(width: 3),
                      Expanded(
                        flex: cancelled.clamp(1, 9).toInt(),
                        child: _DensityBar(
                          color: AppColors.textMutedColor(context),
                        ),
                      ),
                    ],
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DensityBar extends StatelessWidget {
  const _DensityBar({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 4,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

class _WeekAgendaPanel extends StatelessWidget {
  const _WeekAgendaPanel({
    required this.selectedDate,
    required this.appointments,
    required this.companyId,
    required this.uid,
    required this.users,
    required this.canManage,
    required this.onDateSelected,
  });

  final DateTime selectedDate;
  final List<Appointment> appointments;
  final String companyId;
  final String uid;
  final List<UserProfile> users;
  final bool canManage;
  final ValueChanged<DateTime> onDateSelected;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final days = _weekDays(context, selectedDate);
    final weekLabel =
        '${intl.DateFormat.MMMd(l.localeName).format(days.first)} - ${intl.DateFormat.MMMd(l.localeName).format(days.last)}';

    return _WorkspacePanel(
      title: l.appointmentCalendarWeekView,
      subtitle: weekLabel,
      icon: Icons.view_week_outlined,
      trailing: _CalendarNavigation(
        selectedDate: selectedDate,
        onPrevious: () => onDateSelected(
          selectedDate.subtract(const Duration(days: 7)),
        ),
        onToday: () => onDateSelected(_dateOnly(DateTime.now())),
        onNext: () => onDateSelected(
          selectedDate.add(const Duration(days: 7)),
        ),
      ),
      child: Column(
        children: [
          for (var index = 0; index < days.length; index++) ...[
            _WeekDayGroup(
              day: days[index],
              selected: _sameDay(days[index], selectedDate),
              appointments: _appointmentsForDay(appointments, days[index]),
              companyId: companyId,
              uid: uid,
              users: users,
              canManage: canManage,
              onTap: () => onDateSelected(days[index]),
            ),
            if (index != days.length - 1) const SizedBox(height: AppSpacing.xs),
          ],
        ],
      ),
    );
  }
}

class _WeekDayGroup extends StatelessWidget {
  const _WeekDayGroup({
    required this.day,
    required this.selected,
    required this.appointments,
    required this.companyId,
    required this.uid,
    required this.users,
    required this.canManage,
    required this.onTap,
  });

  final DateTime day;
  final bool selected;
  final List<Appointment> appointments;
  final String companyId;
  final String uid;
  final List<UserProfile> users;
  final bool canManage;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final color = selected
        ? AppColors.primaryColor(context)
        : AppColors.textSecondaryColor(context);
    final dateLabel = intl.DateFormat.EEEE(l.localeName).format(day);
    final dayLabel = intl.DateFormat.MMMd(l.localeName).format(day);

    return Container(
      decoration: BoxDecoration(
        color: selected
            ? AppColors.primaryColor(context).withValues(alpha: 0.08)
            : AppColors.inputSurface(context),
        border: Border.all(
          color: selected
              ? AppColors.primaryColor(context).withValues(alpha: 0.34)
              : AppColors.borderColor(context),
        ),
        borderRadius: AppRadius.large,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: AppRadius.large,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Row(
                children: [
                  Icon(Icons.event_note_outlined, size: 17, color: color),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      '$dateLabel - $dayLabel',
                      maxLines: 2,
                      softWrap: true,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: color,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                  ),
                  AppStatusBadge(
                    label: appointments.length.toString(),
                    tone: appointments.any(
                      (item) => _effectiveStatus(item) == AppointmentStatus.missed,
                    )
                        ? AppStatusTone.error
                        : AppStatusTone.info,
                  ),
                ],
              ),
            ),
          ),
          if (appointments.isNotEmpty)
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                AppSpacing.sm,
                0,
                AppSpacing.sm,
                AppSpacing.sm,
              ),
              child: Column(
                children: [
                  for (var index = 0; index < appointments.length; index++) ...[
                    _AgendaAppointmentTile(
                      appointment: appointments[index],
                      companyId: companyId,
                      uid: uid,
                      users: users,
                      canManage: canManage,
                    ),
                    if (index != appointments.length - 1)
                      const SizedBox(height: AppSpacing.xs),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}


class _LoadMoreAppointmentsButton extends StatelessWidget {
  const _LoadMoreAppointmentsButton({
    required this.loadedCount,
    required this.pageSize,
    required this.isLoading,
    required this.onPressed,
    this.totalCount,
  });

  final int loadedCount;
  final int pageSize;
  final bool isLoading;
  final VoidCallback onPressed;
  final int? totalCount;

  @override
  Widget build(BuildContext context) {
    return AppPaginationFooter(
      loadedCount: loadedCount,
      pageSize: pageSize,
      isLoading: isLoading,
      onLoadMore: onPressed,
      totalCount: totalCount,
    );
  }
}

class _AgendaPanel extends StatelessWidget {
  const _AgendaPanel({
    required this.title,
    required this.appointments,
    required this.companyId,
    required this.uid,
    required this.users,
    required this.canManage,
    required this.emptyMessage,
    this.trailing,
  });

  final String title;
  final List<Appointment> appointments;
  final String companyId;
  final String uid;
  final List<UserProfile> users;
  final bool canManage;
  final String emptyMessage;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return _WorkspacePanel(
      title: title,
      subtitle: appointments.isEmpty
          ? emptyMessage
          : '${appointments.length} ${AppLocalizations.of(context)!.appointments}',
      icon: Icons.today_outlined,
      trailing: trailing,
      child: appointments.isEmpty
          ? AppEmptyState(
              title: emptyMessage,
              message: AppLocalizations.of(context)!.noAppointmentsMatchFilters,
              icon: Icons.event_busy_outlined,
            )
          : Column(
              children: [
                for (var index = 0; index < appointments.length; index++) ...[
                  _AnimatedListItem(
                    index: index,
                    child: _AgendaAppointmentTile(
                      appointment: appointments[index],
                      companyId: companyId,
                      uid: uid,
                      users: users,
                      canManage: canManage,
                    ),
                  ),
                  if (index != appointments.length - 1)
                    const SizedBox(height: AppSpacing.sm),
                ],
              ],
            ),
    );
  }
}

class _AgendaAppointmentTile extends StatelessWidget {
  const _AgendaAppointmentTile({
    required this.appointment,
    required this.companyId,
    required this.uid,
    required this.users,
    required this.canManage,
  });

  final Appointment appointment;
  final String companyId;
  final String uid;
  final List<UserProfile> users;
  final bool canManage;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final status = _effectiveStatus(appointment);
    final tone = _statusTone(status);
    final color = _toneColor(context, tone);

    return Material(
      color: AppColors.inputSurface(context),
      borderRadius: AppRadius.large,
      child: InkWell(
        onTap: canManage
            ? () => context.go(RouteNames.appointmentEdit(appointment.id))
            : null,
        borderRadius: AppRadius.large,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.borderColor(context)),
            borderRadius: AppRadius.large,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 58,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: AppRadius.medium,
                ),
                child: Column(
                  children: [
                    Icon(Icons.schedule_outlined, size: 16, color: color),
                    const SizedBox(height: 4),
                    Text(
                      _timeOnlyLabel(l, appointment.scheduledAt),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      softWrap: true,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: color,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                  ],
                ),
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
                            appointment.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                        ),
                        if (canManage)
                          _AppointmentActions(
                            appointment: appointment,
                            companyId: companyId,
                            updatedBy: uid,
                            compact: true,
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: [
                        _AnimatedStatusBadge(
                          label: appointmentStatusLabel(l, status),
                          tone: tone,
                          statusKey: status.name,
                        ),
                        _Pill(label: _relatedRecordDisplayLabel(l, appointment)),
                        _Pill(label: _assigneeDisplayLabel(l, appointment, users)),
                      ],
                    ),
                    if (appointment.outcome != null ||
                        appointment.cancellationReason.trim().isNotEmpty ||
                        appointment.outcomeNotes.trim().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        _appointmentResultLine(l, appointment),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondaryColor(context),
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
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

class _WorkspacePanel extends StatelessWidget {
  const _WorkspacePanel({
    required this.title,
    required this.icon,
    required this.child,
    this.subtitle = '',
    this.trailing,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.cardSurface(context),
        border: Border.all(color: AppColors.borderColor(context)),
        borderRadius: AppRadius.large,
        boxShadow:
            Theme.of(context).brightness == Brightness.dark ? null : AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primaryColor(context).withValues(alpha: 0.11),
                  borderRadius: AppRadius.medium,
                ),
                child: Icon(icon, size: 18, color: AppColors.primaryColor(context)),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      softWrap: true,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    if (subtitle.trim().isNotEmpty)
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondaryColor(context),
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: AppSpacing.sm),
                trailing!,
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}

class _CalendarNavigation extends StatelessWidget {
  const _CalendarNavigation({
    required this.selectedDate,
    required this.onPrevious,
    required this.onToday,
    required this.onNext,
  });

  final DateTime selectedDate;
  final VoidCallback onPrevious;
  final VoidCallback onToday;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: l.back,
          visualDensity: VisualDensity.compact,
          onPressed: onPrevious,
          icon: const Icon(Icons.chevron_left_rounded),
        ),
        TextButton(
          onPressed: onToday,
          child: Text(l.today),
        ),
        IconButton(
          tooltip: l.next,
          visualDensity: VisualDensity.compact,
          onPressed: onNext,
          icon: const Icon(Icons.chevron_right_rounded),
        ),
      ],
    );
  }
}

class _AnimatedListItem extends StatelessWidget {
  const _AnimatedListItem({required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 180 + (index.clamp(0, 6) * 25)),
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
      child: child,
    );
  }
}

class _AnimatedEmptyState extends StatelessWidget {
  const _AnimatedEmptyState({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 14 * (1 - value)),
            child: Transform.scale(
              scale: 0.98 + (0.02 * value),
              child: child,
            ),
          ),
        );
      },
      child: child,
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  const _AppointmentCard({
    required this.appointment,
    required this.companyId,
    required this.uid,
    required this.users,
    required this.canManage,
  });

  final Appointment appointment;
  final String companyId;
  final String uid;
  final List<UserProfile> users;
  final bool canManage;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: AppRadius.large,
      onTap: canManage
          ? () => context.go(RouteNames.appointmentEdit(appointment.id))
          : null,
      child: Container(
        padding: EdgeInsets.all(
          MediaQuery.sizeOf(context).width < 720
              ? AppSpacing.sm
              : AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: AppColors.cardSurface(context),
          border: Border.all(color: AppColors.borderColor(context)),
          borderRadius: AppRadius.large,
          boxShadow: Theme.of(context).brightness == Brightness.dark
              ? null
              : AppShadows.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    appointment.title,
                    maxLines: 2,
                    softWrap: true,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (canManage)
                  _AppointmentActions(
                    appointment: appointment,
                    companyId: companyId,
                    updatedBy: uid,
                    compact: true,
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _dateTimeLabel(l, appointment.scheduledAt),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondaryColor(context),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                _AnimatedStatusBadge(
                  label: appointmentStatusLabel(
                    l,
                    _effectiveStatus(appointment),
                  ),
                  tone: _statusTone(_effectiveStatus(appointment)),
                  statusKey: _effectiveStatus(appointment).name,
                ),
                _Pill(label: appointmentTypeLabel(l, appointment.type)),
                _Pill(label: _relatedRecordDisplayLabel(l, appointment)),
                _Pill(label: _assigneeDisplayLabel(l, appointment, users)),
                if (appointment.location.trim().isNotEmpty)
                  _Pill(label: appointment.location.trim()),
              ],
            ),
            if (appointment.outcome != null ||
                appointment.cancellationReason.trim().isNotEmpty ||
                appointment.outcomeNotes.trim().isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                _appointmentResultLine(l, appointment),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
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

class _AppointmentsTable extends StatelessWidget {
  const _AppointmentsTable({
    required this.appointments,
    required this.companyId,
    required this.uid,
    required this.users,
    required this.canManage,
  });

  final List<Appointment> appointments;
  final String companyId;
  final String uid;
  final List<UserProfile> users;
  final bool canManage;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return AppHorizontalScrollView(
      minWidth: 1120,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
        color: AppColors.cardSurface(context),
        border: Border.all(color: AppColors.borderColor(context)),
        borderRadius: AppRadius.large,
        boxShadow:
            Theme.of(context).brightness == Brightness.dark ? null : AppShadows.card,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: Row(
              children: [
                _TableHeaderText(l.appointmentTime, flex: 2),
                _TableHeaderText(l.appointmentTitle, flex: 3),
                _TableHeaderText(l.appointmentType, flex: 2),
                _TableHeaderText(l.relatedRecord, flex: 2),
                _TableHeaderText(l.assignedUser, flex: 2),
                _TableHeaderText(l.status, flex: 2),
                _TableHeaderText(l.actions, flex: 2),
              ],
            ),
          ),
          Divider(height: 1, color: AppColors.borderColor(context)),
          Expanded(
            child: ListView.separated(
              itemCount: appointments.length,
              separatorBuilder: (context, index) =>
                  Divider(height: 1, color: AppColors.borderColor(context)),
              itemBuilder: (context, index) {
                final appointment = appointments[index];
                return _AnimatedListItem(
                  index: index,
                  child: Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      AppSpacing.md,
                      7,
                      AppSpacing.md,
                      7,
                    ),
                    child: Row(
                      children: [
                        _TableBodyText(
                          _dateTimeLabel(l, appointment.scheduledAt),
                          flex: 2,
                        ),
                        _TableBodyText(appointment.title, flex: 3),
                        _TableBodyText(
                          appointmentTypeLabel(l, appointment.type),
                          flex: 2,
                        ),
                        _TableBodyText(
                          _relatedRecordDisplayLabel(l, appointment),
                          flex: 2,
                        ),
                        _TableBodyText(
                          _assigneeDisplayLabel(l, appointment, users),
                          flex: 2,
                        ),
                        Expanded(
                          flex: 2,
                          child: Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: _AnimatedStatusBadge(
                              label: appointmentStatusLabel(
                                l,
                                _effectiveStatus(appointment),
                              ),
                              tone: _statusTone(_effectiveStatus(appointment)),
                              statusKey: _effectiveStatus(appointment).name,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: canManage
                              ? _AppointmentActions(
                                  appointment: appointment,
                                  companyId: companyId,
                                  updatedBy: uid,
                                )
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedStatusBadge extends StatelessWidget {
  const _AnimatedStatusBadge({
    required this.label,
    required this.tone,
    required this.statusKey,
  });

  final String label;
  final AppStatusTone tone;
  final String statusKey;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.96, end: 1).animate(animation),
            child: child,
          ),
        );
      },
      child: AppStatusBadge(
        key: ValueKey(statusKey),
        label: label,
        tone: tone,
      ),
    );
  }
}

enum _AppointmentActionMenu {
  edit,
  openLinkedRecord,
  complete,
  cancel,
  missed,
  reschedule,
}

class _AppointmentActions extends StatefulWidget {
  const _AppointmentActions({
    required this.appointment,
    required this.companyId,
    required this.updatedBy,
    this.compact = false,
  });

  final Appointment appointment;
  final String companyId;
  final String updatedBy;
  final bool compact;

  @override
  State<_AppointmentActions> createState() => _AppointmentActionsState();
}

class _AppointmentActionsState extends State<_AppointmentActions> {
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return PopupMenuButton<_AppointmentActionMenu>(
      tooltip: l.actions,
      onSelected: _handleAction,
      itemBuilder: (context) => [
        PopupMenuItem(
          value: _AppointmentActionMenu.edit,
          child: _MenuItem(icon: Icons.edit_outlined, label: l.editAppointment),
        ),
        if (_linkedRecordRoute(widget.appointment) != null)
          PopupMenuItem(
            value: _AppointmentActionMenu.openLinkedRecord,
            child: _MenuItem(
              icon: Icons.open_in_new_rounded,
              label: l.openLinkedRecord,
            ),
          ),
        PopupMenuItem(
          value: _AppointmentActionMenu.reschedule,
          child: _MenuItem(icon: Icons.event_repeat_outlined, label: l.reschedule),
        ),
        if (_effectiveStatus(widget.appointment) !=
            AppointmentStatus.completed)
          PopupMenuItem(
            value: _AppointmentActionMenu.complete,
            child: _MenuItem(
              icon: Icons.check_circle_outline,
              label: l.completeAppointment,
            ),
          ),
        if (_effectiveStatus(widget.appointment) != AppointmentStatus.missed)
          PopupMenuItem(
            value: _AppointmentActionMenu.missed,
            child: _MenuItem(
              icon: Icons.event_busy_outlined,
              label: l.markMissed,
            ),
          ),
        if (_effectiveStatus(widget.appointment) !=
            AppointmentStatus.cancelled)
          PopupMenuItem(
            value: _AppointmentActionMenu.cancel,
            child: _MenuItem(
              icon: Icons.cancel_outlined,
              label: l.cancelAppointment,
              destructive: true,
            ),
          ),
      ],
      icon: const Icon(Icons.more_horiz),
    );
  }

  Future<void> _handleAction(_AppointmentActionMenu action) async {
    if (action == _AppointmentActionMenu.edit) {
      context.go(RouteNames.appointmentEdit(widget.appointment.id));
      return;
    }
    if (action == _AppointmentActionMenu.openLinkedRecord) {
      final route = _linkedRecordRoute(widget.appointment);
      if (route == null) {
        AppFeedback.warning(
          context,
          AppLocalizations.of(context)!.relatedRecordUnavailable,
        );
        return;
      }
      context.go(route);
      return;
    }
    if (action == _AppointmentActionMenu.reschedule) {
      await _showRescheduleDialog();
      return;
    }

    if (action == _AppointmentActionMenu.cancel ||
        action == _AppointmentActionMenu.missed) {
      await Future<void>.delayed(Duration.zero);
      if (!mounted) {
        return;
      }
      await _confirmStatusChange(
        context,
        title: action == _AppointmentActionMenu.cancel
            ? AppLocalizations.of(context)!.cancelAppointment
            : AppLocalizations.of(context)!.markMissed,
        message: action == _AppointmentActionMenu.cancel
            ? AppLocalizations.of(context)!.cancelAppointmentConfirmation
            : AppLocalizations.of(context)!.markMissedConfirmation,
        status: action == _AppointmentActionMenu.cancel
            ? AppointmentStatus.cancelled
            : AppointmentStatus.missed,
      );
      return;
    }

    await _confirmStatusChange(
      context,
      title: AppLocalizations.of(context)!.completeAppointment,
      message: AppLocalizations.of(context)!.completeAppointmentConfirmation,
      status: AppointmentStatus.completed,
    );
  }

  Future<void> _showRescheduleDialog() async {
    final cubit = context.read<AppointmentsCubit>();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return _AppointmentRescheduleDialog(
          appointment: widget.appointment,
          companyId: widget.companyId,
          updatedBy: widget.updatedBy,
          cubit: cubit,
        );
      },
    );
  }

  Future<void> _confirmStatusChange(
    BuildContext context, {
    required String title,
    required String message,
    required AppointmentStatus status,
  }) async {
    final cubit = context.read<AppointmentsCubit>();
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return _AppointmentStatusChangeDialog(
          title: title,
          message: message,
          status: status,
          companyId: widget.companyId,
          appointment: widget.appointment,
          updatedBy: widget.updatedBy,
          cubit: cubit,
        );
      },
    );
    if (!mounted || status != AppointmentStatus.completed || saved != true) {
      return;
    }
    await Future<void>.delayed(Duration.zero);
    if (!mounted) {
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return _AppointmentOutcomePromptDialog(
          companyId: widget.companyId,
          appointment: widget.appointment,
          updatedBy: widget.updatedBy,
          cubit: cubit,
        );
      },
    );
  }
}

class _AppointmentStatusChangeDialog extends StatefulWidget {
  const _AppointmentStatusChangeDialog({
    required this.title,
    required this.message,
    required this.status,
    required this.companyId,
    required this.appointment,
    required this.updatedBy,
    required this.cubit,
  });

  final String title;
  final String message;
  final AppointmentStatus status;
  final String companyId;
  final Appointment appointment;
  final String updatedBy;
  final AppointmentsCubit cubit;

  @override
  State<_AppointmentStatusChangeDialog> createState() =>
      _AppointmentStatusChangeDialogState();
}

class _AppointmentRescheduleDialog extends StatefulWidget {
  const _AppointmentRescheduleDialog({
    required this.appointment,
    required this.companyId,
    required this.updatedBy,
    required this.cubit,
  });

  final Appointment appointment;
  final String companyId;
  final String updatedBy;
  final AppointmentsCubit cubit;

  @override
  State<_AppointmentRescheduleDialog> createState() =>
      _AppointmentRescheduleDialogState();
}

class _AppointmentRescheduleDialogState
    extends State<_AppointmentRescheduleDialog> {
  DateTime? _date;
  TimeOfDay? _time;
  late int _durationMinutes;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final scheduledAt = widget.appointment.scheduledAt?.toLocal() ??
        DateTime.now().add(const Duration(hours: 1));
    _date = DateTime(scheduledAt.year, scheduledAt.month, scheduledAt.day);
    _time = TimeOfDay.fromDateTime(scheduledAt);
    _durationMinutes = widget.appointment.durationMinutes <= 0
        ? 60
        : widget.appointment.durationMinutes;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l.reschedule),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ScheduleComparisonRow(
              label: l.currentAppointmentTime,
              value: _dateTimeLabel(l, widget.appointment.scheduledAt),
            ),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
              onPressed: _isSubmitting ? null : _pickDate,
              icon: const Icon(Icons.event_outlined),
              label: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(_dateLabel(l)),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              onPressed: _isSubmitting ? null : _pickTime,
              icon: const Icon(Icons.schedule_outlined),
              label: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(_timeLabel(l)),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            AppDropdown<int>(
              label: l.duration,
              value: _durationMinutes,
              items: const [15, 30, 45, 60, 90, 120],
              itemLabelBuilder: (value) => l.durationMinutes(value),
              enabled: !_isSubmitting,
              onChanged: (value) => setState(() => _durationMinutes = value),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: Text(l.cancel),
        ),
        AppButton(
          label: l.reschedule,
          isLoading: _isSubmitting,
          onPressed: _isSubmitting ? null : _submit,
        ),
      ],
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null && mounted) {
      setState(() => _date = DateTime(picked.year, picked.month, picked.day));
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time ?? TimeOfDay.now(),
    );
    if (picked != null && mounted) {
      setState(() => _time = picked);
    }
  }

  String _dateLabel(AppLocalizations l) {
    final date = _date;
    if (date == null) {
      return l.selectAppointmentDate;
    }
    return MaterialLocalizations.of(context).formatMediumDate(date);
  }

  String _timeLabel(AppLocalizations l) {
    final time = _time;
    if (time == null) {
      return l.selectStartTime;
    }
    return MaterialLocalizations.of(context).formatTimeOfDay(time);
  }

  Future<void> _submit() async {
    final date = _date;
    final time = _time;
    final l = AppLocalizations.of(context)!;
    if (date == null || time == null) {
      AppFeedback.warning(context, l.appointmentDateRequired);
      return;
    }
    if (_durationMinutes <= 0) {
      AppFeedback.warning(context, l.appointmentDurationRequired);
      return;
    }

    final scheduledAt = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    final endAt = scheduledAt.add(Duration(minutes: _durationMinutes));
    if (!endAt.isAfter(scheduledAt)) {
      AppFeedback.warning(context, l.appointmentEndAfterStartRequired);
      return;
    }
    if (!scheduledAt.isAfter(DateTime.now())) {
      AppFeedback.warning(context, l.appointmentFutureTimeRequired);
      return;
    }

    setState(() => _isSubmitting = true);
    final success = await widget.cubit.saveAppointment(
      companyId: widget.companyId,
      operation: 'update',
      appointment: widget.appointment.copyWith(
        status: AppointmentStatus.rescheduled,
        scheduledAt: scheduledAt,
        endAt: endAt,
        durationMinutes: _durationMinutes,
        updatedBy: widget.updatedBy,
        rescheduledFrom:
            widget.appointment.rescheduledFrom ?? widget.appointment.scheduledAt,
        previousScheduledAt: widget.appointment.scheduledAt,
        previousEndAt: widget.appointment.endAt,
      ),
      action: AppointmentAction.reschedule,
    );
    if (!mounted) {
      return;
    }
    if (success) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _isSubmitting = false);
  }
}

class _ScheduleComparisonRow extends StatelessWidget {
  const _ScheduleComparisonRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.inputSurface(context),
        border: Border.all(color: AppColors.borderColor(context)),
        borderRadius: AppRadius.medium,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textSecondaryColor(context),
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

class _AppointmentStatusChangeDialogState
    extends State<_AppointmentStatusChangeDialog> {
  late final TextEditingController _controller;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    final controller = _controller;
    // On Flutter Web, closing the dialog immediately after a status update can
    // leave TextField internals finishing the same frame. Deferring disposal by
    // one frame avoids "TextEditingController was used after being disposed"
    // without keeping the controller alive beyond the dialog teardown.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.dispose();
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final isComplete = widget.status == AppointmentStatus.completed;
    final isCancel = widget.status == AppointmentStatus.cancelled;
    return AlertDialog(
      title: Text(widget.title),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420, maxHeight: 320),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(widget.message),
              const SizedBox(height: AppSpacing.md),
              if (!isComplete)
                TextField(
                  controller: _controller,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: isCancel ? l.cancellationReason : l.outcomeNotes,
                  ),
                  enabled: !_isSubmitting,
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: Text(l.cancel),
        ),
        AppButton(
          label: widget.title,
          isLoading: _isSubmitting,
          onPressed: _isSubmitting ? null : _submit,
        ),
      ],
    );
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final l = AppLocalizations.of(context)!;
    if (widget.status == AppointmentStatus.cancelled &&
        _controller.text.trim().isEmpty) {
      AppFeedback.warning(context, l.cancellationReasonRequired);
      return;
    }
    setState(() => _isSubmitting = true);
    final success = await widget.cubit.changeStatus(
      companyId: widget.companyId,
      appointment: widget.appointment,
      status: widget.status,
      updatedBy: widget.updatedBy,
      outcome: null,
      outcomeNotes:
          widget.status == AppointmentStatus.cancelled ? '' : _controller.text,
      cancellationReason:
          widget.status == AppointmentStatus.cancelled ? _controller.text : '',
    );
    if (!mounted) {
      return;
    }
    if (success) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() => _isSubmitting = false);
  }
}


class _AppointmentOutcomePromptDialog extends StatefulWidget {
  const _AppointmentOutcomePromptDialog({
    required this.companyId,
    required this.appointment,
    required this.updatedBy,
    required this.cubit,
  });

  final String companyId;
  final Appointment appointment;
  final String updatedBy;
  final AppointmentsCubit cubit;

  @override
  State<_AppointmentOutcomePromptDialog> createState() =>
      _AppointmentOutcomePromptDialogState();
}

class _AppointmentOutcomePromptDialogState
    extends State<_AppointmentOutcomePromptDialog> {
  late final TextEditingController _notesController;
  AppointmentOutcome _outcome = AppointmentOutcome.successfulMeeting;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    final controller = _notesController;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.dispose();
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l.recordAppointmentOutcome),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440, maxHeight: 420),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l.appointmentCompletedOutcomePromptMessage),
              const SizedBox(height: AppSpacing.md),
              AppDropdown<AppointmentOutcome>(
                label: l.appointmentOutcome,
                value: _outcome,
                items: AppointmentOutcome.values,
                itemLabelBuilder: (outcome) => appointmentOutcomeLabel(l, outcome),
                enabled: !_isSubmitting,
                onChanged: (value) => setState(() => _outcome = value),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                appointmentOutcomeNextStepHint(l, _outcome),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondaryColor(context),
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _notesController,
                maxLines: 3,
                decoration: InputDecoration(labelText: l.outcomeNotes),
                enabled: !_isSubmitting,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: Text(l.addAppointmentOutcomeLater),
        ),
        AppButton(
          label: l.recordAppointmentOutcome,
          isLoading: _isSubmitting,
          onPressed: _isSubmitting ? null : _submit,
        ),
      ],
    );
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() => _isSubmitting = true);
    final success = await widget.cubit.changeStatus(
      companyId: widget.companyId,
      appointment: widget.appointment,
      status: AppointmentStatus.completed,
      updatedBy: widget.updatedBy,
      outcome: _outcome,
      outcomeNotes: _notesController.text,
    );
    if (!mounted) {
      return;
    }
    if (success) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _isSubmitting = false);
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.label,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive
        ? AppColors.errorColor(context)
        : AppColors.textPrimaryColor(context);
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.inputSurface(context),
        border: Border.all(color: AppColors.borderColor(context)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 6),
        child: Text(
          label,
          maxLines: 2,
          softWrap: true,
          style: Theme.of(context).textTheme.labelMedium,
        ),
      ),
    );
  }
}

class _TableHeaderText extends StatelessWidget {
  const _TableHeaderText(this.value, {required this.flex});

  final String value;
  final int flex;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsetsDirectional.only(end: AppSpacing.sm),
        child: Text(
          value,
          maxLines: 2,
          softWrap: true,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppColors.textSecondaryColor(context),
                fontWeight: FontWeight.w800,
              ),
        ),
      ),
    );
  }
}

class _TableBodyText extends StatelessWidget {
  const _TableBodyText(this.value, {required this.flex});

  final String value;
  final int flex;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsetsDirectional.only(end: AppSpacing.sm),
        child: Text(
          value,
          maxLines: 2,
          softWrap: true,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}

class _FilterOption<T> {
  const _FilterOption._({required this.value, required this.isAll});

  const _FilterOption.all() : this._(value: null, isAll: true);

  const _FilterOption.value(T value) : this._(value: value, isAll: false);

  factory _FilterOption.fromValue(T? value) {
    return value == null
        ? _FilterOption<T>.all()
        : _FilterOption<T>.value(value);
  }

  final T? value;
  final bool isAll;

  @override
  bool operator ==(Object other) {
    return other is _FilterOption<T> &&
        other.isAll == isAll &&
        other.value == value;
  }

  @override
  int get hashCode => Object.hash(value, isAll);
}

List<_FilterOption<T>> _filterOptions<T>(Iterable<T> values) {
  return [
    _FilterOption<T>.all(),
    for (final value in values) _FilterOption<T>.value(value),
  ];
}

class _AssigneeFilterOption {
  const _AssigneeFilterOption._({required this.value, required this.isAll});

  const _AssigneeFilterOption.all() : this._(value: null, isAll: true);

  const _AssigneeFilterOption.value(String value)
      : this._(value: value, isAll: false);

  factory _AssigneeFilterOption.fromValue(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty
        ? const _AssigneeFilterOption.all()
        : _AssigneeFilterOption.value(trimmed);
  }

  final String? value;
  final bool isAll;

  @override
  bool operator ==(Object other) {
    return other is _AssigneeFilterOption &&
        other.isAll == isAll &&
        other.value == value;
  }

  @override
  int get hashCode => Object.hash(value, isAll);
}

List<_AssigneeFilterOption> _assigneeFilterOptions(List<UserProfile> users) {
  final sorted = [...users]..sort((a, b) {
      final aLabel = a.fullName.trim().isEmpty ? a.email : a.fullName;
      final bLabel = b.fullName.trim().isEmpty ? b.email : b.fullName;
      return aLabel.compareTo(bLabel);
    });
  return [
    const _AssigneeFilterOption.all(),
    for (final user in sorted) _AssigneeFilterOption.value(user.uid),
  ];
}

String _assigneeLabel(
  AppLocalizations l,
  List<UserProfile> users,
  String? uid,
) {
  final value = uid?.trim() ?? '';
  if (value.isEmpty) {
    return l.allAssignees;
  }
  for (final user in users) {
    if (user.uid == value) {
      return user.fullName.trim().isEmpty ? user.email : user.fullName;
    }
  }
  return l.assignedUserUnavailable;
}

String _assigneeDisplayLabel(
  AppLocalizations l,
  Appointment appointment,
  List<UserProfile> users,
) {
  if (appointment.assignedTo.trim().isEmpty) {
    return l.unassigned;
  }
  if (appointment.assignedToName.trim().isNotEmpty) {
    return appointment.assignedToName.trim();
  }
  if (appointment.assignedToEmail.trim().isNotEmpty) {
    return appointment.assignedToEmail.trim();
  }
  for (final user in users) {
    if (user.uid == appointment.assignedTo) {
      return user.fullName.trim().isEmpty ? user.email : user.fullName;
    }
  }
  return l.assignedUserUnavailable;
}

String _relatedRecordDisplayLabel(
  AppLocalizations l,
  Appointment appointment,
) {
  final typeLabel = appointmentRelatedTypeLabel(l, appointment.relatedType);
  final title = appointment.relatedTitle.trim();
  if (appointment.relatedType == AppointmentRelatedType.general ||
      title.isEmpty) {
    return typeLabel;
  }
  return '$typeLabel: $title';
}

const int _attentionPageSize = 15;
const int _missedRecoveryAttentionDays = 7;

int _attentionBadgeCount(
  AppointmentsState state,
  List<Appointment> attentionAppointments,
) {
  return attentionAppointments.length;
}

enum _AppointmentAttentionType { missed, dueNow, upcomingSoon }

List<Appointment> _attentionAppointments(List<Appointment> appointments) {
  final selected = appointments.where((appointment) {
    if (appointment.status == AppointmentStatus.completed ||
        appointment.status == AppointmentStatus.cancelled) {
      return false;
    }
    return _appointmentAttentionType(appointment) != null;
  }).toList()
    ..sort((a, b) {
      final rank = _appointmentAttentionRank(
        _appointmentAttentionType(a),
      ).compareTo(_appointmentAttentionRank(_appointmentAttentionType(b)));
      if (rank != 0) {
        return rank;
      }
      final aDate = a.scheduledAt ?? DateTime(9999);
      final bDate = b.scheduledAt ?? DateTime(9999);
      return aDate.compareTo(bDate);
    });
  return selected;
}

_AppointmentAttentionType? _appointmentAttentionType(Appointment appointment) {
  final scheduledAt = appointment.scheduledAt;
  if (scheduledAt == null) {
    return null;
  }
  final now = DateTime.now();
  final localStart = scheduledAt.toLocal();
  if (DashboardTruthRules.isAppointmentDueNow(appointment, now)) {
    return _AppointmentAttentionType.dueNow;
  }
  if (DashboardTruthRules.isMissedAppointment(appointment, now)) {
    final staleCutoff = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(days: _missedRecoveryAttentionDays));
    if (localStart.isBefore(staleCutoff)) {
      return null;
    }
    return _AppointmentAttentionType.missed;
  }
  if (localStart.isAfter(now) &&
      localStart.isBefore(now.add(const Duration(hours: 2)))) {
    return _AppointmentAttentionType.upcomingSoon;
  }
  return null;
}

int _appointmentAttentionRank(_AppointmentAttentionType? type) {
  return switch (type) {
    _AppointmentAttentionType.missed => 0,
    _AppointmentAttentionType.dueNow => 1,
    _AppointmentAttentionType.upcomingSoon => 2,
    null => 3,
  };
}

String _appointmentAttentionLabel(
  AppLocalizations l,
  _AppointmentAttentionType? type,
) {
  return switch (type) {
    _AppointmentAttentionType.missed =>
      l.notificationAppointmentMissedAttentionTitle,
    _AppointmentAttentionType.dueNow => l.notificationAppointmentDueNowTitle,
    _AppointmentAttentionType.upcomingSoon =>
      l.notificationAppointmentUpcomingSoonTitle,
    null => l.appointmentStatusScheduled,
  };
}

AppStatusTone _appointmentAttentionTone(_AppointmentAttentionType? type) {
  return switch (type) {
    _AppointmentAttentionType.missed || _AppointmentAttentionType.dueNow =>
      AppStatusTone.error,
    _AppointmentAttentionType.upcomingSoon => AppStatusTone.warning,
    null => AppStatusTone.info,
  };
}

IconData _appointmentAttentionIcon(_AppointmentAttentionType? type) {
  return switch (type) {
    _AppointmentAttentionType.missed => Icons.event_busy_outlined,
    _AppointmentAttentionType.dueNow => Icons.notifications_active_outlined,
    _AppointmentAttentionType.upcomingSoon => Icons.upcoming_outlined,
    null => Icons.event_available_outlined,
  };
}

String _appointmentAttentionSubtitle(
  AppLocalizations l,
  Appointment appointment,
  List<UserProfile> users,
) {
  final parts = [
    _dateTimeLabel(l, appointment.scheduledAt),
    _relatedRecordDisplayLabel(l, appointment),
    _assigneeDisplayLabel(l, appointment, users),
  ].where((part) => part.trim().isNotEmpty && part != l.notAvailable).toList();
  return parts.join(' - ');
}

String _calendarViewLabel(BuildContext context, AppointmentCalendarView view) {
  final l = AppLocalizations.of(context)!;
  return switch (view) {
    AppointmentCalendarView.today => l.appointmentCalendarTodayView,
    AppointmentCalendarView.month => l.appointmentCalendarMonthView,
    AppointmentCalendarView.week => l.appointmentCalendarWeekView,
    AppointmentCalendarView.day => l.appointmentCalendarDayView,
  };
}

IconData _calendarViewIcon(AppointmentCalendarView view) {
  return switch (view) {
    AppointmentCalendarView.today => Icons.today_outlined,
    AppointmentCalendarView.month => Icons.calendar_month_outlined,
    AppointmentCalendarView.week => Icons.view_week_outlined,
    AppointmentCalendarView.day => Icons.view_day_outlined,
  };
}

String _agendaTitle(BuildContext context, DateTime selectedDate) {
  final l = AppLocalizations.of(context)!;
  return '${l.appointmentAgenda} - ${intl.DateFormat.yMMMd(l.localeName).format(selectedDate)}';
}

String _emptyAgendaMessage(
  BuildContext context,
  AppointmentCalendarView view,
) {
  final l = AppLocalizations.of(context)!;
  return view == AppointmentCalendarView.today
      ? l.noAppointmentsToday
      : l.noAppointmentsForSelectedDay;
}

List<Appointment> _appointmentsForDay(
  List<Appointment> appointments,
  DateTime day,
) {
  final selected = _dateOnly(day);
  return appointments.where((appointment) {
    final scheduledAt = appointment.scheduledAt;
    return scheduledAt != null && _dateOnly(scheduledAt) == selected;
  }).toList()
    ..sort((a, b) {
      final aDate = a.scheduledAt ?? DateTime(9999);
      final bDate = b.scheduledAt ?? DateTime(9999);
      return aDate.compareTo(bDate);
    });
}

int _visibleCalendarAppointmentCount(
  BuildContext context,
  AppointmentsState state,
) {
  final appointments = state.filteredAppointments;
  final selectedDate = state.calendarView == AppointmentCalendarView.today
      ? _dateOnly(DateTime.now())
      : state.selectedCalendarDate ?? _dateOnly(DateTime.now());
  return switch (state.calendarView) {
    AppointmentCalendarView.today =>
      _appointmentsForDay(appointments, selectedDate).length,
    AppointmentCalendarView.day =>
      _appointmentsForDay(appointments, selectedDate).length,
    AppointmentCalendarView.week => _appointmentsForDaysCount(
        appointments,
        _weekDays(context, selectedDate),
      ),
    AppointmentCalendarView.month => _appointmentsForDaysCount(
        appointments,
        _visibleMonthDays(context, selectedDate),
      ),
  };
}

int _appointmentsForDaysCount(
  List<Appointment> appointments,
  Iterable<DateTime> days,
) {
  final visibleDays = days.map(_dateOnly).toSet();
  var count = 0;
  for (final appointment in appointments) {
    final scheduledAt = appointment.scheduledAt;
    if (scheduledAt != null && visibleDays.contains(_dateOnly(scheduledAt))) {
      count++;
    }
  }
  return count;
}

List<DateTime> _visibleMonthDays(BuildContext context, DateTime selectedDate) {
  final firstOfMonth = DateTime(selectedDate.year, selectedDate.month);
  final firstDayIndex = MaterialLocalizations.of(context).firstDayOfWeekIndex;
  final monthWeekdayIndex = firstOfMonth.weekday % DateTime.daysPerWeek;
  final leadingDays =
      (monthWeekdayIndex - firstDayIndex) % DateTime.daysPerWeek;
  final firstVisible = firstOfMonth.subtract(Duration(days: leadingDays));
  return [
    for (var index = 0; index < 42; index++)
      _dateOnly(firstVisible.add(Duration(days: index))),
  ];
}

List<DateTime> _weekDays(BuildContext context, DateTime selectedDate) {
  final firstDayIndex = MaterialLocalizations.of(context).firstDayOfWeekIndex;
  final selectedWeekdayIndex = selectedDate.weekday % DateTime.daysPerWeek;
  final leadingDays =
      (selectedWeekdayIndex - firstDayIndex) % DateTime.daysPerWeek;
  final start = _dateOnly(selectedDate.subtract(Duration(days: leadingDays)));
  return [
    for (var index = 0; index < DateTime.daysPerWeek; index++)
      start.add(Duration(days: index)),
  ];
}

List<String> _weekdayLabels(BuildContext context) {
  final l = AppLocalizations.of(context)!;
  final days = _weekDays(context, DateTime(2024, 1, 7));
  return [
    for (final day in days) intl.DateFormat.E(l.localeName).format(day),
  ];
}

DateTime _dateOnly(DateTime value) {
  final local = value.toLocal();
  return DateTime(local.year, local.month, local.day);
}

_AppointmentDateWindow _appointmentsRollingDateWindow() {
  final today = _dateOnly(DateTime.now());
  return _AppointmentDateWindow(
    start: today.subtract(const Duration(days: 60)),
    end: today.add(const Duration(days: 121)),
  );
}

class _AppointmentDateWindow {
  const _AppointmentDateWindow({
    required this.start,
    required this.end,
  });

  final DateTime start;
  final DateTime end;
}

bool _sameDay(DateTime a, DateTime b) {
  return _dateOnly(a) == _dateOnly(b);
}

bool _isNonBlockingAppointmentsWatchFailure(AppointmentsState state) {
  final hasVisibleAppointments =
      state.appointments.isNotEmpty || state.filteredAppointments.isNotEmpty;
  if (!hasVisibleAppointments) {
    return false;
  }
  return state.message == AppErrorMessages.unknown ||
      state.message == AppErrorMessages.cancelled;
}

String _dateTimeLabel(AppLocalizations l, DateTime? value) {
  if (value == null) {
    return l.notAvailable;
  }
  final local = value.toLocal();
  final date = intl.DateFormat.yMMMd(l.localeName).format(local);
  final time = intl.DateFormat.jm(l.localeName).format(local);
  return '$date - $time';
}

String _timeOnlyLabel(AppLocalizations l, DateTime? value) {
  if (value == null) {
    return l.notAvailable;
  }
  return intl.DateFormat.jm(l.localeName).format(value.toLocal());
}

String _appointmentResultLine(
  AppLocalizations l,
  Appointment appointment,
) {
  final parts = <String>[];
  final outcome = appointment.outcome;
  if (outcome != null) {
    parts.add(appointmentOutcomeLabel(l, outcome));
  }
  if (appointment.cancellationReason.trim().isNotEmpty) {
    parts.add('${l.cancellationReason}: ${appointment.cancellationReason.trim()}');
  }
  if (appointment.outcomeNotes.trim().isNotEmpty) {
    parts.add(appointment.outcomeNotes.trim());
  }
  return parts.join(' - ');
}

String? _linkedRecordRoute(Appointment appointment) {
  final id = appointment.relatedId.trim();
  if (id.isEmpty || appointment.relatedType == AppointmentRelatedType.general) {
    return null;
  }
  return switch (appointment.relatedType) {
    AppointmentRelatedType.lead => RouteNames.leadDetails(id),
    AppointmentRelatedType.client => RouteNames.clientDetails(id),
    AppointmentRelatedType.property => RouteNames.propertyDetails(id),
    AppointmentRelatedType.deal => RouteNames.dealDetails(id),
    AppointmentRelatedType.general => null,
  };
}



List<Appointment> _visiblePagedAppointments(AppointmentsState state) {
  final limit = state.pageLimit < 1 ? 15 : state.pageLimit;
  if (state.filteredAppointments.length <= limit) {
    return state.filteredAppointments;
  }
  return state.filteredAppointments.take(limit).toList(growable: false);
}

bool _shouldShowFilteredAppointmentsAgenda(AppointmentsState state) {
  final hasSearch = state.searchQuery.trim().isNotEmpty;
  final hasAssignee = state.assignedToFilter.trim().isNotEmpty;
  final hasSelectedDate = state.selectedDateFilter != null;
  final hasStatus = state.statusFilter != null;
  final hasType = state.typeFilter != null;
  final dateFilter = state.dateFilter;
  final hasNonTodayDateFilter = dateFilter != null &&
      dateFilter != AppointmentDateFilter.today;
  return hasSearch ||
      hasAssignee ||
      hasSelectedDate ||
      hasStatus ||
      hasType ||
      hasNonTodayDateFilter;
}

String _appointmentsFilterTitle(AppLocalizations l, AppointmentsState state) {
  final selectedDate = state.selectedDateFilter;
  if (selectedDate != null) {
    return l.dashboardAppointmentsForDate(
      intl.DateFormat.yMMMd(l.localeName).format(selectedDate),
    );
  }
  if (state.dateFilter != null) {
    return _dateFilterLabel(l, state.dateFilter!);
  }
  if (state.statusFilter != null) {
    return appointmentStatusLabel(l, state.statusFilter!);
  }
  if (state.typeFilter != null) {
    return appointmentTypeLabel(l, state.typeFilter!);
  }
  return l.appointments;
}

String _dateFilterLabel(AppLocalizations l, AppointmentDateFilter filter) {
  return switch (filter) {
    AppointmentDateFilter.today => l.today,
    AppointmentDateFilter.thisWeek => l.thisWeek,
    AppointmentDateFilter.upcoming => l.upcoming,
    AppointmentDateFilter.missed => l.missedAppointments,
    AppointmentDateFilter.feedbackNeeded =>
      l.salesCommandReasonAppointmentNeedsFeedback,
    AppointmentDateFilter.all => l.allAppointments,
  };
}

AppointmentStatus _effectiveStatus(Appointment appointment) {
  if (DashboardTruthRules.isMissedAppointment(appointment, DateTime.now())) {
    return AppointmentStatus.missed;
  }
  return appointment.status;
}

AppStatusTone _statusTone(AppointmentStatus status) {
  return switch (status) {
    AppointmentStatus.scheduled => AppStatusTone.info,
    AppointmentStatus.completed => AppStatusTone.success,
    AppointmentStatus.cancelled => AppStatusTone.neutral,
    AppointmentStatus.missed => AppStatusTone.error,
    AppointmentStatus.rescheduled => AppStatusTone.warning,
  };
}

Color _toneColor(BuildContext context, AppStatusTone tone) {
  return switch (tone) {
    AppStatusTone.success => AppColors.successColor(context),
    AppStatusTone.warning => AppColors.warningColor(context),
    AppStatusTone.error => AppColors.errorColor(context),
    AppStatusTone.info => AppColors.primaryColor(context),
    AppStatusTone.neutral => AppColors.textSecondaryColor(context),
  };
}

String _actionSuccessLabel(AppLocalizations l, AppointmentAction action) {
  return switch (action) {
    AppointmentAction.create => l.appointmentSaved,
    AppointmentAction.update => l.appointmentUpdated,
    AppointmentAction.complete => l.appointmentCompleted,
    AppointmentAction.cancel => l.appointmentCancelled,
    AppointmentAction.markMissed => l.appointmentMissed,
    AppointmentAction.reschedule => l.appointmentRescheduled,
  };
}

String _filterSignature(Map<String, String> filters) {
  final entries = filters.entries
      .where((entry) => entry.value.trim().isNotEmpty)
      .toList()
    ..sort((a, b) => a.key.compareTo(b.key));
  return entries.map((entry) => '${entry.key}=${entry.value}').join('&');
}

T? _enumByName<T extends Enum>(List<T> values, String? name) {
  final clean = name?.trim();
  if (clean == null || clean.isEmpty) {
    return null;
  }
  for (final value in values) {
    if (value.name == clean) {
      return value;
    }
  }
  return null;
}

AppointmentDateFilter? _appointmentDateFilter(String? value) {
  return switch (value?.trim()) {
    'today' => AppointmentDateFilter.today,
    'thisWeek' => AppointmentDateFilter.thisWeek,
    'upcoming' => AppointmentDateFilter.upcoming,
    'missed' => AppointmentDateFilter.missed,
    'feedback-needed' || 'feedbackNeeded' =>
      AppointmentDateFilter.feedbackNeeded,
    'all' => null,
    _ => null,
  };
}

DateTime? _parseQueryDate(String? value) {
  final parsed = DateTime.tryParse(value?.trim() ?? '');
  if (parsed == null) {
    return null;
  }
  return DateTime(parsed.year, parsed.month, parsed.day);
}

Stream<List<UserProfile>> _watchActiveUsers(String companyId) {
  final repository = UserProfileRepositoryImpl(
    remoteDataSource: FirestoreUserProfileRemoteDataSource(),
  );
  return WatchActiveUsersUseCase(repository)(companyId: companyId);
}
