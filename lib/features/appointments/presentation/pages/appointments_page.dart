import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' as intl;

import '../../../../core/constants/role_constants.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_dropdown.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_status_badge.dart';
import '../../../../core/widgets/crm_app_shell.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
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
  const AppointmentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return CrmAppShell(
      selectedItem: CrmNavigationItem.appointments,
      title: l.appointments,
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          if (authState.status == AuthStatus.initial ||
              authState.status == AuthStatus.loading) {
            return const AppLoading();
          }

          final user = authState.user;
          final profile = authState.userProfile;
          if (user == null || profile == null || profile.uid != user.uid) {
            return const AppLoading();
          }

          final companyId = profile.companyId;
          final role = profile.role;
          if (companyId.isEmpty) {
            return AppErrorView(message: l.missingCompanyProfile);
          }
          if (role == UserRole.viewer) {
            return AppErrorView(message: l.permissionDenied);
          }

          String? assignedTo;
          String? managerId;
          if (role == UserRole.manager) {
            managerId = profile.uid;
          } else if (role == UserRole.salesAgent ||
              role == UserRole.marketing) {
            assignedTo = profile.uid;
          }
          final scopeKey = ValueKey('appointments-scope:$companyId:${profile.uid}:${role.name}');

          return AppointmentsScope(
            key: scopeKey,
            child: _AppointmentsContent(
              key: ValueKey('appointments-content:$companyId:${profile.uid}:${role.name}'),
              companyId: companyId,
              uid: profile.uid,
              role: role,
              assignedTo: assignedTo,
              managerId: managerId,
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
  });

  final String companyId;
  final String uid;
  final UserRole role;
  final String? assignedTo;
  final String? managerId;

  @override
  State<_AppointmentsContent> createState() => _AppointmentsContentState();
}

class _AppointmentsContentState extends State<_AppointmentsContent> {
  Timer? _clockTicker;
  int _clockPulse = 0;
  int _selectedTab = 0;

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
        oldWidget.managerId != widget.managerId) {
      _watchAppointments();
    }
  }

  void _watchAppointments() {
    context.read<AppointmentsCubit>().watchAppointments(
          companyId: widget.companyId,
          assignedTo: widget.assignedTo,
          managerId: widget.managerId,
        );
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
                    _attentionAppointments(state.appointments);
                final attention = _AppointmentsAttentionStrip(
                  key: ValueKey('appointments-attention-${widget.companyId}:${widget.uid}:$_clockPulse'),
                  appointments: attentionAppointments,
                  users: users,
                  companyId: widget.companyId,
                  uid: widget.uid,
                  canManage: canManage,
                );
                final header = _AppointmentsHeader(
                  canCreate: canCreate,
                  onCreate: () => context.go(RouteNames.appointmentsCreate),
                );
                final summary = _AppointmentsSummary(
                  appointments: state.appointments,
                );
                final tabs = _AppointmentsTabs(
                  selectedIndex: _selectedTab,
                  attentionCount: attentionAppointments.length,
                  onChanged: (index) => setState(() => _selectedTab = index),
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
                );
                final showAttentionTab = _selectedTab == 1;

                if (isMobile) {
                  return SingleChildScrollView(
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

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    header,
                    const SizedBox(height: AppSpacing.xs),
                    summary,
                    const SizedBox(height: AppSpacing.xs),
                    tabs,
                    const SizedBox(height: AppSpacing.xs),
                    if (showAttentionTab)
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: attention,
                        ),
                      )
                    else ...[
                      filters,
                      const SizedBox(height: AppSpacing.xs),
                      Expanded(child: body),
                    ],
                  ],
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
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.cardSurface(context),
        border: Border.all(color: AppColors.borderColor(context)),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Row(
          children: [
            Expanded(
              child: _AppointmentsTabButton(
                label: l.appointments,
                icon: Icons.event_available_outlined,
                selected: selectedIndex == 0,
                onTap: () => onChanged(0),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: _AppointmentsTabButton(
                label: l.attentionNeeded,
                icon: Icons.notifications_active_outlined,
                selected: selectedIndex == 1,
                badge: attentionCount > 0 ? attentionCount.toString() : null,
                onTap: () => onChanged(1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppointmentsTabButton extends StatelessWidget {
  const _AppointmentsTabButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? AppColors.primaryColor(context)
        : AppColors.textSecondaryColor(context);
    return Material(
      color: selected ? AppColors.selectedSurface(context) : Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: 9,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 17, color: color),
              const SizedBox(width: AppSpacing.xs),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: color,
                        fontWeight:
                            selected ? FontWeight.w900 : FontWeight.w700,
                      ),
                ),
              ),
              if (badge != null) ...[
                const SizedBox(width: AppSpacing.xs),
                AppStatusBadge(label: badge!, tone: AppStatusTone.warning),
              ],
            ],
          ),
        ),
      ),
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
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
  const _AppointmentsSummary({required this.appointments});

  final List<Appointment> appointments;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final completed = appointments
        .where((appointment) => appointment.status == AppointmentStatus.completed)
        .length;
    final missed = appointments.where((appointment) {
      return appointment.status == AppointmentStatus.missed ||
          (_isOpenScheduledStatus(appointment.status) &&
              _isAppointmentPastStart(appointment, now));
    }).length;
    final todayCount = appointments.where((appointment) {
      final date = appointment.scheduledAt?.toLocal();
      return date != null &&
          DateTime(date.year, date.month, date.day) == today;
    }).length;
    final upcoming = appointments.where((appointment) {
      final scheduledAt = appointment.scheduledAt;
      return scheduledAt != null &&
          scheduledAt.isAfter(now) &&
          (appointment.status == AppointmentStatus.scheduled ||
              appointment.status == AppointmentStatus.rescheduled);
    }).length;

    final cards = [
      _SummaryCardData(
        label: l.todaysAppointments,
        value: todayCount.toString(),
        icon: Icons.today_outlined,
        tone: AppStatusTone.info,
      ),
      _SummaryCardData(
        label: l.upcomingAppointments,
        value: upcoming.toString(),
        icon: Icons.event_available_outlined,
        tone: AppStatusTone.warning,
      ),
      _SummaryCardData(
        label: l.missedAppointments,
        value: missed.toString(),
        icon: Icons.event_busy_outlined,
        tone: AppStatusTone.error,
      ),
      _SummaryCardData(
        label: l.completedAppointments,
        value: completed.toString(),
        icon: Icons.verified_outlined,
        tone: AppStatusTone.success,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth < 680 ? 2 : 4;
        return GridView.count(
          crossAxisCount: columns,
          crossAxisSpacing: AppSpacing.xs,
          mainAxisSpacing: AppSpacing.xs,
          childAspectRatio: constraints.maxWidth < 680 ? 2.9 : 4.6,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            for (var index = 0; index < cards.length; index++)
              _AnimatedSummaryTile(
                index: index,
                child: _SummaryTile(card: cards[index]),
              ),
          ],
        );
      },
    );
  }
}

class _SummaryCardData {
  const _SummaryCardData({
    required this.label,
    required this.value,
    required this.icon,
    required this.tone,
  });

  final String label;
  final String value;
  final IconData icon;
  final AppStatusTone tone;
}

class _AnimatedSummaryTile extends StatelessWidget {
  const _AnimatedSummaryTile({required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 220 + index * 35),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 12 * (1 - value)),
            child: Transform.scale(
              scale: 0.985 + (0.015 * value),
              child: child,
            ),
          ),
        );
      },
      child: child,
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({required this.card});

  final _SummaryCardData card;

  @override
  Widget build(BuildContext context) {
    final toneColor = _toneColor(context, card.tone);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.cardSurface(context),
        border: Border.all(color: AppColors.borderColor(context)),
        borderRadius: AppRadius.large,
        boxShadow:
            Theme.of(context).brightness == Brightness.dark ? null : AppShadows.card,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 6,
        ),
        child: Row(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: toneColor.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(card.icon, color: toneColor, size: 16),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    card.value,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  Text(
                    card.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: AppColors.textSecondaryColor(context),
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
  });

  final List<Appointment> appointments;
  final List<UserProfile> users;
  final String companyId;
  final String uid;
  final bool canManage;

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
    if (widget.appointments.length <= 3 && _expanded) {
      _expanded = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.appointments.isEmpty) {
      return const SizedBox.shrink();
    }
    final l = AppLocalizations.of(context)!;
    final canToggle = widget.appointments.length > 3;
    final itemCount = _expanded
        ? widget.appointments.length
        : widget.appointments.length > 3
            ? 3
            : widget.appointments.length;
    final visibleRows = _expanded
        ? (itemCount > 6 ? 6 : itemCount)
        : itemCount;
    final listHeight = (visibleRows * 56.0).toDouble();

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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
                  physics: _expanded && widget.appointments.length > 6
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
                      ),
                    );
                  },
                ),
              ),
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
  });

  final Appointment appointment;
  final List<UserProfile> users;
  final String companyId;
  final String uid;
  final bool canManage;

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
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appointment.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    Text(
                      _appointmentAttentionSubtitle(l, appointment, users),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondaryColor(context),
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              _AnimatedStatusBadge(
                label: _appointmentAttentionLabel(l, type),
                tone: tone,
                statusKey: type?.name ?? 'scheduled',
              ),
              if (canManage) ...[
                const SizedBox(width: AppSpacing.xs),
                _AppointmentActions(
                  appointment: appointment,
                  companyId: companyId,
                  updatedBy: uid,
                  compact: true,
                ),
              ],
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
        state.dateFilter != AppointmentDateFilter.today ||
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
                        items: _filterOptions(AppointmentDateFilter.values),
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
    this.assignedTo,
    this.managerId,
  });

  final String companyId;
  final String uid;
  final AppointmentsState state;
  final List<UserProfile> users;
  final bool canManage;
  final String? assignedTo;
  final String? managerId;

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
        onRetry: () => context.read<AppointmentsCubit>().watchAppointments(
              companyId: companyId,
              assignedTo: assignedTo,
              managerId: managerId,
            ),
      );
    }
    if (state.appointments.isEmpty) {
      return _AnimatedEmptyState(
        child: AppEmptyState(
          title: l.noAppointmentsYet,
          message: l.createFirstAppointment,
          icon: Icons.event_available_outlined,
        ),
      );
    }
    if (state.filteredAppointments.isEmpty) {
      return _AnimatedEmptyState(
        child: AppEmptyState(
          title: l.noAppointmentsMatchFilters,
          message: l.clearFilters,
          icon: Icons.manage_search_outlined,
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 720) {
          return Column(
            children: [
              for (var index = 0;
                  index < state.filteredAppointments.length;
                  index++) ...[
                _AnimatedListItem(
                  index: index,
                  child: _AppointmentCard(
                    appointment: state.filteredAppointments[index],
                    companyId: companyId,
                    uid: uid,
                    users: users,
                    canManage: canManage,
                  ),
                ),
                if (index != state.filteredAppointments.length - 1)
                  const SizedBox(height: AppSpacing.sm),
              ],
            ],
          );
        }
        return SizedBox.expand(
          child: _AppointmentsTable(
            appointments: state.filteredAppointments,
            companyId: companyId,
            uid: uid,
            users: users,
            canManage: canManage,
          ),
        );
      },
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
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
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
    return Container(
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
  _AppointmentActionMenu? _busyAction;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final isBusy = _busyAction != null;
    if (isBusy) {
      return SizedBox(
        width: widget.compact ? 40 : 48,
        height: 36,
        child: Center(
          child: SizedBox.square(
            dimension: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              color: AppColors.primaryColor(context),
            ),
          ),
        ),
      );
    }
    return PopupMenuButton<_AppointmentActionMenu>(
      tooltip: l.actions,
      onSelected: _handleAction,
      itemBuilder: (context) => [
        PopupMenuItem(
          value: _AppointmentActionMenu.edit,
          child: _MenuItem(icon: Icons.edit_outlined, label: l.editAppointment),
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
    if (action == _AppointmentActionMenu.edit ||
        action == _AppointmentActionMenu.reschedule) {
      context.go(RouteNames.appointmentEdit(widget.appointment.id));
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

    setState(() => _busyAction = action);
    try {
      await context.read<AppointmentsCubit>().changeStatus(
            companyId: widget.companyId,
            appointment: widget.appointment,
            status: AppointmentStatus.completed,
            updatedBy: widget.updatedBy,
          );
    } finally {
      if (mounted) {
        setState(() => _busyAction = null);
      }
    }
  }

  Future<void> _confirmStatusChange(
    BuildContext context, {
    required String title,
    required String message,
    required AppointmentStatus status,
  }) async {
    final l = AppLocalizations.of(context)!;
    final controller = TextEditingController();
    final cubit = context.read<AppointmentsCubit>();
    var isSubmitting = false;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(title),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(message),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: controller,
                    maxLines: 3,
                    decoration: InputDecoration(labelText: l.outcomeNotes),
                    enabled: !isSubmitting,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: Text(l.cancel),
                ),
                AppButton(
                  label: title,
                  isLoading: isSubmitting,
                  onPressed: () async {
                    FocusScope.of(dialogContext).unfocus();
                    setDialogState(() => isSubmitting = true);
                    final success = await cubit.changeStatus(
                      companyId: widget.companyId,
                      appointment: widget.appointment,
                      status: status,
                      updatedBy: widget.updatedBy,
                      outcomeNotes: controller.text,
                    );
                    if (success && dialogContext.mounted) {
                      Navigator.of(dialogContext).pop();
                      return;
                    }
                    if (dialogContext.mounted) {
                      setDialogState(() => isSubmitting = false);
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
    controller.dispose();
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
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
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
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
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
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
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

List<_FilterOption<T>> _filterOptions<T>(List<T> values) {
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

enum _AppointmentAttentionType { missed, dueNow, upcomingSoon, today }

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
  if (_isOpenScheduledStatus(appointment.status) &&
      _isAppointmentDueNow(appointment, now)) {
    return _AppointmentAttentionType.dueNow;
  }
  if (appointment.status == AppointmentStatus.missed ||
      (_isOpenScheduledStatus(appointment.status) &&
          _isAppointmentPastStart(appointment, now))) {
    return _AppointmentAttentionType.missed;
  }
  if (localStart.isAfter(now) &&
      localStart.isBefore(now.add(const Duration(hours: 2)))) {
    return _AppointmentAttentionType.upcomingSoon;
  }
  final today = DateTime(now.year, now.month, now.day);
  final appointmentDay = DateTime(
    localStart.year,
    localStart.month,
    localStart.day,
  );
  if (appointmentDay == today) {
    return _AppointmentAttentionType.today;
  }
  return null;
}

int _appointmentAttentionRank(_AppointmentAttentionType? type) {
  return switch (type) {
    _AppointmentAttentionType.missed => 0,
    _AppointmentAttentionType.dueNow => 1,
    _AppointmentAttentionType.upcomingSoon => 2,
    _AppointmentAttentionType.today => 3,
    null => 4,
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
    _AppointmentAttentionType.today => l.notificationAppointmentTodayAttentionTitle,
    null => l.appointmentStatusScheduled,
  };
}

AppStatusTone _appointmentAttentionTone(_AppointmentAttentionType? type) {
  return switch (type) {
    _AppointmentAttentionType.missed || _AppointmentAttentionType.dueNow =>
      AppStatusTone.error,
    _AppointmentAttentionType.upcomingSoon || _AppointmentAttentionType.today =>
      AppStatusTone.warning,
    null => AppStatusTone.info,
  };
}

IconData _appointmentAttentionIcon(_AppointmentAttentionType? type) {
  return switch (type) {
    _AppointmentAttentionType.missed => Icons.event_busy_outlined,
    _AppointmentAttentionType.dueNow => Icons.notifications_active_outlined,
    _AppointmentAttentionType.upcomingSoon => Icons.upcoming_outlined,
    _AppointmentAttentionType.today => Icons.today_outlined,
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

String _dateTimeLabel(AppLocalizations l, DateTime? value) {
  if (value == null) {
    return l.notAvailable;
  }
  final local = value.toLocal();
  final date = intl.DateFormat.yMMMd(l.localeName).format(local);
  final time = intl.DateFormat.jm(l.localeName).format(local);
  return '$date - $time';
}

String _dateFilterLabel(AppLocalizations l, AppointmentDateFilter filter) {
  return switch (filter) {
    AppointmentDateFilter.today => l.today,
    AppointmentDateFilter.thisWeek => l.thisWeek,
    AppointmentDateFilter.upcoming => l.upcoming,
    AppointmentDateFilter.missed => l.missedAppointments,
    AppointmentDateFilter.all => l.allAppointments,
  };
}

AppointmentStatus _effectiveStatus(Appointment appointment) {
  if (_isOpenScheduledStatus(appointment.status) &&
      _isAppointmentPastStart(appointment, DateTime.now())) {
    return AppointmentStatus.missed;
  }
  return appointment.status;
}

bool _isAppointmentPastStart(Appointment appointment, DateTime now) {
  final scheduledAt = appointment.scheduledAt;
  return scheduledAt != null &&
      now.difference(scheduledAt.toLocal()).inSeconds >= 60;
}

bool _isAppointmentDueNow(Appointment appointment, DateTime now) {
  final scheduledAt = appointment.scheduledAt?.toLocal();
  if (scheduledAt == null || scheduledAt.isAfter(now)) {
    return false;
  }
  return now.difference(scheduledAt).inSeconds < 60;
}

bool _isOpenScheduledStatus(AppointmentStatus status) {
  return status == AppointmentStatus.scheduled ||
      status == AppointmentStatus.rescheduled;
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

Stream<List<UserProfile>> _watchActiveUsers(String companyId) {
  final repository = UserProfileRepositoryImpl(
    remoteDataSource: FirestoreUserProfileRemoteDataSource(),
  );
  return WatchActiveUsersUseCase(repository)(companyId: companyId);
}
