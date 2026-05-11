import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/error_mapper.dart';
import '../../../../core/permissions/app_permission.dart';
import '../../../../core/permissions/permission_service.dart';
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
import '../../domain/entities/lead.dart';
import '../cubit/leads_cubit.dart';
import '../cubit/leads_state.dart';
import '../widgets/leads_scope.dart';

class LeadsListPage extends StatelessWidget {
  const LeadsListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    if (localizations == null) {
      return const SizedBox.shrink();
    }

    return CrmAppShell(
      selectedItem: CrmNavigationItem.leads,
      title: localizations.leads,
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
            return AppErrorView(message: localizations.missingCompanyProfile);
          }

          return LeadsScope(
            child: _LeadsListContent(
              companyId: companyId,
              uid: authState.user?.uid ?? '',
              actorName:
                  authState.userProfile?.fullName ??
                  authState.user?.fullName ??
                  localizations.unknownUser,
              canCreate: _can(authState, AppPermission.createLead),
              canEdit: _can(authState, AppPermission.editLead),
              roleName:
                  (authState.userProfile?.role ?? authState.user?.role)?.name ??
                  '',
            ),
          );
        },
      ),
    );
  }
}

class _LeadsListContent extends StatefulWidget {
  const _LeadsListContent({
    required this.companyId,
    required this.uid,
    required this.actorName,
    required this.canCreate,
    required this.canEdit,
    required this.roleName,
  });

  final String companyId;
  final String uid;
  final String actorName;
  final bool canCreate;
  final bool canEdit;
  final String roleName;

  @override
  State<_LeadsListContent> createState() => _LeadsListContentState();
}

class _LeadsListContentState extends State<_LeadsListContent> {
  String? get _assignedToFilter {
    final authState = context.read<AuthBloc>().state;
    final role = authState.userProfile?.role ?? authState.user?.role;
    final uid = authState.user?.uid ?? '';
    return role?.name == 'salesAgent' ? uid : null;
  }

  @override
  void initState() {
    super.initState();
    context.read<LeadsCubit>().watchLeads(
      companyId: widget.companyId,
      assignedTo: _assignedToFilter,
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    if (localizations == null) {
      return const SizedBox.shrink();
    }

    return BlocConsumer<LeadsCubit, LeadsState>(
      listenWhen: (previous, current) =>
          previous.status != current.status &&
          (current.status == LeadsStatus.saved ||
              current.status == LeadsStatus.failure),
      listener: (context, state) {
        if (state.status == LeadsStatus.failure) {
          AppFeedback.error(
            context,
            localizeErrorMessage(localizations, state.message),
          );
          return;
        }
        if (state.lastAction == LeadsAction.markContactedToday) {
          AppFeedback.success(context, localizations.leadMarkedContactedToday);
        } else if (state.lastAction == LeadsAction.updateLead) {
          AppFeedback.success(context, localizations.leadUpdatedSuccessfully);
        } else if (state.lastAction == LeadsAction.assignLead) {
          AppFeedback.success(context, localizations.leadAssignedSuccessfully);
        } else if (state.lastAction == LeadsAction.archiveLead) {
          AppFeedback.success(context, localizations.leadArchivedSuccessfully);
        } else if (state.lastAction == LeadsAction.updateStatus) {
          AppFeedback.success(
            context,
            localizations.leadStatusUpdatedSuccessfully,
          );
        }
      },
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    localizations.leadsSubtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondaryColor(context),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                AppButton(
                  label: localizations.createLead,
                  onPressed: widget.canCreate
                      ? () => context.go(RouteNames.leadsCreate)
                      : null,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: StreamBuilder<List<UserProfile>>(
                stream: _watchActiveUsers(widget.companyId),
                builder: (context, usersSnapshot) {
                  if (usersSnapshot.hasError) {
                    return AppErrorView(
                      message: localizations.unableToConnect,
                      onRetry: () {
                        context.read<LeadsCubit>().watchLeads(
                          companyId: widget.companyId,
                          assignedTo: _assignedToFilter,
                        );
                      },
                    );
                  }

                  final users = usersSnapshot.data ?? const <UserProfile>[];
                  final showAssignee =
                      widget.roleName == 'admin' ||
                      widget.roleName == 'manager';

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _LeadFilters(showAssignee: showAssignee, users: users),
                      const SizedBox(height: AppSpacing.md),
                      Expanded(
                        child: _LeadsBody(
                          state: state,
                          companyId: widget.companyId,
                          assignedTo: _assignedToFilter,
                          users: users,
                          roleName: widget.roleName,
                          canEdit: widget.canEdit,
                          uid: widget.uid,
                          actorName: widget.actorName,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _LeadFilters extends StatelessWidget {
  const _LeadFilters({required this.showAssignee, required this.users});

  final bool showAssignee;
  final List<UserProfile> users;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    if (localizations == null) {
      return const SizedBox.shrink();
    }

    return BlocBuilder<LeadsCubit, LeadsState>(
      buildWhen: (previous, current) {
        return previous.searchQuery != current.searchQuery ||
            previous.statusFilter != current.statusFilter ||
            previous.sourceFilter != current.sourceFilter ||
            previous.priorityFilter != current.priorityFilter ||
            previous.assignedToFilter != current.assignedToFilter ||
            previous.followUpFilter != current.followUpFilter;
      },
      builder: (context, state) {
        return LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 720) {
              return _MobileLeadFilters(
                state: state,
                showAssignee: showAssignee,
                users: users,
              );
            }

            final cubit = context.read<LeadsCubit>();
            final hasFilters =
                state.searchQuery.trim().isNotEmpty ||
                state.statusFilter != null ||
                state.sourceFilter != null ||
                state.priorityFilter != null ||
                state.assignedToFilter != null ||
                state.followUpFilter != null;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _LeadSearchField(
                        query: state.searchQuery,
                        onChanged: cubit.setSearchQuery,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    AppButton(
                      label: localizations.filters,
                      icon: Icons.tune,
                      variant: AppButtonVariant.secondary,
                      onPressed: () => _showLeadFiltersSheet(
                        context,
                        state,
                        showAssignee: showAssignee,
                        users: users,
                      ),
                    ),
                    if (hasFilters) ...[
                      const SizedBox(width: AppSpacing.sm),
                      AppButton(
                        label: localizations.clearFilters,
                        variant: AppButtonVariant.secondary,
                        onPressed: () {
                          cubit.setSearchQuery('');
                          cubit.setStatusFilter(null);
                          cubit.setSourceFilter(null);
                          cubit.setPriorityFilter(null);
                          cubit.setAssignedToFilter(null);
                          cubit.setFollowUpFilter(null);
                        },
                      ),
                    ],
                  ],
                ),
                if (hasFilters) ...[
                  const SizedBox(height: AppSpacing.sm),
                  _LeadActiveFilterChips(
                    state: state,
                    users: users,
                    showAssignee: showAssignee,
                  ),
                ],
              ],
            );
          },
        );
      },
    );
  }
}

class _LeadSearchField extends StatefulWidget {
  const _LeadSearchField({required this.query, required this.onChanged});

  final String query;
  final ValueChanged<String> onChanged;

  @override
  State<_LeadSearchField> createState() => _LeadSearchFieldState();
}

class _LeadSearchFieldState extends State<_LeadSearchField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.query);
  }

  @override
  void didUpdateWidget(covariant _LeadSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query != widget.query && _controller.text != widget.query) {
      _controller.text = widget.query;
      _controller.selection = TextSelection.collapsed(
        offset: _controller.text.length,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    if (localizations == null) {
      return const SizedBox.shrink();
    }

    return TextField(
      controller: _controller,
      decoration: InputDecoration(
        labelText: localizations.searchLeads,
        prefixIcon: const Icon(Icons.search),
      ),
      onChanged: widget.onChanged,
    );
  }
}

class _LeadActiveFilterChips extends StatelessWidget {
  const _LeadActiveFilterChips({
    required this.state,
    required this.users,
    required this.showAssignee,
  });

  final LeadsState state;
  final List<UserProfile> users;
  final bool showAssignee;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final chips = <Widget>[
      if (state.statusFilter != null)
        _FilterChipPill(label: _statusLabel(l, state.statusFilter)),
      if (state.sourceFilter != null)
        _FilterChipPill(label: _sourceLabel(l, state.sourceFilter)),
      if (state.priorityFilter != null)
        _FilterChipPill(label: _priorityLabel(l, state.priorityFilter)),
      if (state.followUpFilter != null)
        _FilterChipPill(label: _followUpFilterLabel(l, state.followUpFilter)),
      if (showAssignee && state.assignedToFilter != null)
        _FilterChipPill(
          label: _userNameForFilter(
            l,
            users,
            state.leads,
            state.assignedToFilter,
          ),
        ),
    ];

    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: chips,
    );
  }
}

class _FilterChipPill extends StatelessWidget {
  const _FilterChipPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.selectedSurface(context),
        border: Border.all(color: AppColors.borderColor(context)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 5,
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppColors.primaryColor(context),
                fontWeight: FontWeight.w800,
              ),
        ),
      ),
    );
  }
}

class _MobileLeadFilters extends StatelessWidget {
  const _MobileLeadFilters({
    required this.state,
    required this.showAssignee,
    required this.users,
  });

  final LeadsState state;
  final bool showAssignee;
  final List<UserProfile> users;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    if (localizations == null) {
      return const SizedBox.shrink();
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _LeadSearchField(
            query: state.searchQuery,
            onChanged: context.read<LeadsCubit>().setSearchQuery,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        AppButton(
          label: localizations.filters,
          icon: Icons.tune,
          variant: AppButtonVariant.secondary,
          onPressed: () => _showLeadFiltersSheet(
            context,
            state,
            showAssignee: showAssignee,
            users: users,
          ),
        ),
      ],
    );
  }
}

class _LeadFilterOption<T> {
  const _LeadFilterOption._({required this.value, required this.isAll});

  const _LeadFilterOption.all() : this._(value: null, isAll: true);

  const _LeadFilterOption.value(T value)
    : this._(value: value, isAll: false);

  factory _LeadFilterOption.fromValue(T? value) {
    return value == null
        ? _LeadFilterOption<T>.all()
        : _LeadFilterOption<T>.value(value);
  }

  final T? value;
  final bool isAll;

  @override
  bool operator ==(Object other) {
    return other is _LeadFilterOption<T> &&
        other.isAll == isAll &&
        other.value == value;
  }

  @override
  int get hashCode => Object.hash(value, isAll);
}

List<_LeadFilterOption<T>> _leadFilterOptions<T>(List<T> values) {
  return [
    _LeadFilterOption<T>.all(),
    for (final value in values) _LeadFilterOption<T>.value(value),
  ];
}

List<_LeadFilterOption<String>> _assigneeFilterOptions(
  List<UserProfile> users,
  List<Lead> leads,
) {
  final userIds = <String>{
    for (final user in users) user.uid,
    for (final lead in leads)
      if (lead.assignedTo.isNotEmpty) lead.assignedTo,
  };

  return [
    _LeadFilterOption<String>.all(),
    for (final uid in userIds) _LeadFilterOption<String>.value(uid),
  ];
}

String _userNameForFilter(
  AppLocalizations localizations,
  List<UserProfile> users,
  List<Lead> leads,
  String? uid,
) {
  if (uid == null || uid.isEmpty) {
    return localizations.unassigned;
  }
  for (final user in users) {
    if (user.uid == uid) {
      return user.fullName;
    }
  }
  for (final lead in leads) {
    if (lead.assignedTo == uid && lead.assignedToName.isNotEmpty) {
      return lead.assignedToName;
    }
  }
  return _looksLikeUid(uid) ? localizations.assignedUserUnavailable : uid;
}

void _showLeadFiltersSheet(
    BuildContext context,
    LeadsState state, {
      required bool showAssignee,
      required List<UserProfile> users,
    }) {
  final cubit = context.read<LeadsCubit>();

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) {
      LeadStatus? status = state.statusFilter;
      LeadSource? source = state.sourceFilter;
      LeadPriority? priority = state.priorityFilter;
      String? assignee = state.assignedToFilter;
      LeadFollowUpFilter? followUp = state.followUpFilter;

      return StatefulBuilder(
        builder: (context, setSheetState) {
          final localizations = AppLocalizations.of(context);
          if (localizations == null) {
            return const SizedBox.shrink();
          }

          return SafeArea(
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
                          localizations.filters,
                          style: Theme.of(sheetContext).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
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
                        width: 210,
                        child: AppDropdown<_LeadFilterOption<LeadStatus>>(
                          label: localizations.status,
                          value: _LeadFilterOption.fromValue(status),
                          items: _leadFilterOptions(LeadStatus.values),
                          itemLabelBuilder: (item) => item.isAll
                              ? localizations.allStatuses
                              : _statusLabel(localizations, item.value),
                          onChanged: (option) {
                            setSheetState(() => status = option.value);
                            cubit.setStatusFilter(option.value);
                          },
                        ),
                      ),
                      SizedBox(
                        width: 210,
                        child: AppDropdown<_LeadFilterOption<LeadSource>>(
                          label: localizations.source,
                          value: _LeadFilterOption.fromValue(source),
                          items: _leadFilterOptions(LeadSource.values),
                          itemLabelBuilder: (item) => item.isAll
                              ? localizations.allSources
                              : _sourceLabel(localizations, item.value),
                          onChanged: (option) {
                            setSheetState(() => source = option.value);
                            cubit.setSourceFilter(option.value);
                          },
                        ),
                      ),
                      SizedBox(
                        width: 210,
                        child: AppDropdown<_LeadFilterOption<LeadPriority>>(
                          label: localizations.priority,
                          value: _LeadFilterOption.fromValue(priority),
                          items: _leadFilterOptions(LeadPriority.values),
                          itemLabelBuilder: (item) => item.isAll
                              ? localizations.allPriorities
                              : _priorityLabel(localizations, item.value),
                          onChanged: (option) {
                            setSheetState(() => priority = option.value);
                            cubit.setPriorityFilter(option.value);
                          },
                        ),
                      ),
                      if (showAssignee)
                        SizedBox(
                          width: 210,
                          child: AppDropdown<_LeadFilterOption<String>>(
                            label: localizations.assignee,
                            value: _LeadFilterOption.fromValue(assignee),
                            items: _assigneeFilterOptions(users, state.leads),
                            itemLabelBuilder: (item) => item.isAll
                                ? localizations.allAssignees
                                : _userNameForFilter(
                              localizations,
                              users,
                              state.leads,
                              item.value,
                            ),
                            onChanged: (option) {
                              setSheetState(() => assignee = option.value);
                              cubit.setAssignedToFilter(option.value);
                            },
                          ),
                        ),
                      SizedBox(
                        width: 210,
                        child:
                        AppDropdown<_LeadFilterOption<LeadFollowUpFilter>>(
                          label: localizations.nextFollowUp,
                          value: _LeadFilterOption.fromValue(followUp),
                          items: _leadFilterOptions(LeadFollowUpFilter.values),
                          itemLabelBuilder: (item) => item.isAll
                              ? localizations.allFollowUps
                              : _followUpFilterLabel(
                            localizations,
                            item.value,
                          ),
                          onChanged: (option) {
                            setSheetState(() => followUp = option.value);
                            cubit.setFollowUpFilter(option.value);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppButton(
                    label: localizations.clearFilters,
                    variant: AppButtonVariant.secondary,
                    onPressed: () {
                      setSheetState(() {
                        status = null;
                        source = null;
                        priority = null;
                        assignee = null;
                        followUp = null;
                      });
                      cubit.setStatusFilter(null);
                      cubit.setSourceFilter(null);
                      cubit.setPriorityFilter(null);
                      cubit.setAssignedToFilter(null);
                      cubit.setFollowUpFilter(null);
                      Navigator.of(sheetContext).pop();
                    },
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

class _LeadsBody extends StatelessWidget {
  const _LeadsBody({
    required this.state,
    required this.companyId,
    required this.assignedTo,
    required this.users,
    required this.roleName,
    required this.canEdit,
    required this.uid,
    required this.actorName,
  });

  final LeadsState state;
  final String companyId;
  final String? assignedTo;
  final List<UserProfile> users;
  final String roleName;
  final bool canEdit;
  final String uid;
  final String actorName;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    if (localizations == null) {
      return const SizedBox.shrink();
    }

    if ((state.status == LeadsStatus.loading ||
            state.status == LeadsStatus.initial) &&
        state.leads.isEmpty) {
      return const AppLoading();
    }

    if (state.status == LeadsStatus.failure) {
      return AppErrorView(
        message: localizeErrorMessage(localizations, state.message),
        onRetry: () {
          context.read<LeadsCubit>().watchLeads(
            companyId: companyId,
            assignedTo: assignedTo,
          );
        },
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 720;
        if (compact) {
          if (state.filteredLeads.isEmpty) {
            return AppEmptyState(
              title: localizations.noLeads,
              message: localizations.leadsSubtitle,
            );
          }
          return ListView.separated(
            itemCount: state.filteredLeads.length,
            separatorBuilder: (context, index) =>
                const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              final lead = state.filteredLeads[index];
              return _LeadCard(lead: lead, users: users);
            },
          );
        }
        return _LeadsWebWorkspace(
          leads: state.filteredLeads,
          users: users,
          showAssignee: roleName == 'admin' || roleName == 'manager',
          companyId: companyId,
          canEdit: canEdit,
          uid: uid,
          actorName: actorName,
          isRefreshing: state.status == LeadsStatus.loading,
          isSaving: state.status == LeadsStatus.saving,
        );
      },
    );
  }
}

class _LeadsWebWorkspace extends StatefulWidget {
  const _LeadsWebWorkspace({
    required this.leads,
    required this.users,
    required this.showAssignee,
    required this.companyId,
    required this.canEdit,
    required this.uid,
    required this.actorName,
    required this.isRefreshing,
    required this.isSaving,
  });

  final List<Lead> leads;
  final List<UserProfile> users;
  final bool showAssignee;
  final String companyId;
  final bool canEdit;
  final String uid;
  final String actorName;
  final bool isRefreshing;
  final bool isSaving;

  @override
  State<_LeadsWebWorkspace> createState() => _LeadsWebWorkspaceState();
}

class _LeadsWebWorkspaceState extends State<_LeadsWebWorkspace> {
  String? _selectedLeadId;

  @override
  Widget build(BuildContext context) {
    final selectedLead = _selectedLead(widget.leads, _selectedLeadId);
    final localizations = AppLocalizations.of(context);
    if (localizations == null) {
      return const SizedBox.shrink();
    }

    return Stack(
      children: [
        Column(
          children: [
            _LeadSummaryCards(
              leads: widget.leads,
              showAssignee: widget.showAssignee,
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final table = widget.leads.isEmpty
                      ? AppEmptyState(
                          title: localizations.noLeads,
                          message: localizations.leadsSubtitle,
                        )
                      : _LeadsWebTable(
                          leads: widget.leads,
                          users: widget.users,
                          showAssignee: widget.showAssignee,
                          selectedLeadId: selectedLead?.id,
                          onLeadSelected: (lead) {
                            setState(() => _selectedLeadId = lead.id);
                          },
                        );
                  final preview = _LeadPreviewPanel(
                    lead: selectedLead,
                    users: widget.users,
                    showAssignee: widget.showAssignee,
                    companyId: widget.companyId,
                    canEdit: widget.canEdit,
                    uid: widget.uid,
                    actorName: widget.actorName,
                    isSaving: widget.isSaving,
                  );

                  if (constraints.maxWidth < 1100) {
                    return table;
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: table),
                      const SizedBox(width: AppSpacing.md),
                      SizedBox(
                        width: 390,
                        child: preview,
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
        if (widget.isRefreshing || widget.isSaving)
          Positioned.fill(
            child: AbsorbPointer(
              child: Container(
                color: _LeadListColors.of(
                  context,
                ).cardSurface.withValues(alpha: 0.70),
                alignment: Alignment.topCenter,
                padding: const EdgeInsets.only(top: AppSpacing.md),
                child: const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(strokeWidth: 3),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _LeadSummaryCards extends StatelessWidget {
  const _LeadSummaryCards({required this.leads, required this.showAssignee});

  final List<Lead> leads;
  final bool showAssignee;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    if (l == null) {
      return const SizedBox.shrink();
    }
    final newLeads = leads.where((lead) => lead.status == LeadStatus.newLead);
    final activeLeads = leads.where((lead) {
      return lead.status == LeadStatus.contacted ||
          lead.status == LeadStatus.interested ||
          lead.status == LeadStatus.visitScheduled ||
          lead.status == LeadStatus.negotiation;
    });
    final unassignedLeads = leads.where((lead) => lead.assignedTo.isEmpty);
    final overdueFollowUps = leads.where((lead) {
      final nextFollowUpAt = lead.nextFollowUpAt;
      if (nextFollowUpAt == null) {
        return false;
      }
      return DateUtils.dateOnly(
        nextFollowUpAt.toLocal(),
      ).isBefore(DateUtils.dateOnly(DateTime.now()));
    });
    final upcomingFollowUps = leads.where((lead) {
      final nextFollowUpAt = lead.nextFollowUpAt;
      if (nextFollowUpAt == null) {
        return false;
      }
      return DateUtils.dateOnly(
        nextFollowUpAt.toLocal(),
      ).isAfter(DateUtils.dateOnly(DateTime.now()));
    });
    final cards = [
      _LeadSummaryCard(
        label: l.totalLeads,
        value: leads.length,
        total: leads.isEmpty ? 1 : leads.length,
        tone: AppStatusTone.info,
      ),
      _LeadSummaryCard(
        label: l.newLeads,
        value: newLeads.length,
        total: leads.length,
        tone: AppStatusTone.info,
      ),
      _LeadSummaryCard(
        label: l.activeLeads,
        value: activeLeads.length,
        total: leads.length,
        tone: AppStatusTone.success,
      ),
      _LeadSummaryCard(
        label: l.overdue,
        value: overdueFollowUps.length,
        total: leads.length,
        tone: AppStatusTone.error,
      ),
      _LeadSummaryCard(
        label: l.upcoming,
        value: upcomingFollowUps.length,
        total: leads.length,
        tone: AppStatusTone.info,
      ),
      if (showAssignee)
        _LeadSummaryCard(
          label: l.unassignedLeads,
          value: unassignedLeads.length,
          total: leads.length,
          tone: AppStatusTone.warning,
        ),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var index = 0; index < cards.length; index++) ...[
            SizedBox(width: 154, child: cards[index]),
            if (index != cards.length - 1) const SizedBox(width: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}

class _LeadSummaryCard extends StatelessWidget {
  const _LeadSummaryCard({
    required this.label,
    required this.value,
    required this.total,
    required this.tone,
  });

  final String label;
  final int value;
  final int total;
  final AppStatusTone tone;

  @override
  Widget build(BuildContext context) {
    final progress =
        total <= 0 ? 0.0 : (value / total).clamp(0.0, 1.0).toDouble();
    final accent = _summaryToneColor(context, tone);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: _LeadListColors.of(context).cardSurface,
        border: Border.all(color: _LeadListColors.of(context).border),
        borderRadius: AppRadius.large,
        boxShadow: Theme.of(context).brightness == Brightness.dark
            ? null
            : AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.textSecondaryColor(context),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value.toString(),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimaryColor(context),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: progress),
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              builder: (context, value, _) {
                return LinearProgressIndicator(
                  minHeight: 5,
                  value: value,
                  backgroundColor: AppColors.inputSurface(context),
                  color: accent,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

Color _summaryToneColor(BuildContext context, AppStatusTone tone) {
  return switch (tone) {
    AppStatusTone.success => AppColors.successColor(context),
    AppStatusTone.warning => AppColors.warningColor(context),
    AppStatusTone.error => AppColors.errorColor(context),
    AppStatusTone.info => AppColors.infoColor(context),
    AppStatusTone.neutral => AppColors.primaryColor(context),
  };
}

class _LeadsWebTable extends StatelessWidget {
  const _LeadsWebTable({
    required this.leads,
    required this.users,
    required this.showAssignee,
    required this.selectedLeadId,
    required this.onLeadSelected,
  });

  final List<Lead> leads;
  final List<UserProfile> users;
  final bool showAssignee;
  final String? selectedLeadId;
  final ValueChanged<Lead> onLeadSelected;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    if (l == null) {
      return const SizedBox.shrink();
    }
    final colors = _LeadListColors.of(context);

    return Container(
      decoration: BoxDecoration(
        color: colors.cardSurface,
        border: Border.all(color: colors.border),
        borderRadius: AppRadius.large,
        boxShadow: Theme.of(context).brightness == Brightness.dark
            ? null
            : AppShadows.card,
      ),
      clipBehavior: Clip.antiAlias,
      child: DataTableTheme(
        data: Theme.of(context).dataTableTheme.copyWith(
          decoration: BoxDecoration(color: colors.cardSurface),
        ),
        child: ColoredBox(
          color: colors.cardSurface,
          child: SingleChildScrollView(
            child: DataTable(
              horizontalMargin: 8,
              columnSpacing: 10,
              headingRowHeight: 44,
              dataRowMinHeight: 46,
              dataRowMaxHeight: 82,
              columns: [
                DataColumn(label: _TableText(l.leadName, maxWidth: 180)),
                DataColumn(label: _TableText(l.status, maxWidth: 84)),
                DataColumn(label: _TableText(l.priority, maxWidth: 76)),
                DataColumn(label: _TableText(l.source, maxWidth: 110)),
                if (showAssignee)
                  DataColumn(label: _TableText(l.assignedToLabel, maxWidth: 120)),
                DataColumn(label: _TableText(l.nextFollowUp, maxWidth: 128)),
              ],
              rows: leads.map((lead) {
                final selected = lead.id == selectedLeadId;
                final assignee = _resolvedAssigneeName(
                  l,
                  lead.assignedTo,
                  lead.assignedToName,
                  users,
                );
                return DataRow(
                  selected: false,
                  color: WidgetStateProperty.resolveWith((states) {
                    if (selected || states.contains(WidgetState.hovered)) {
                      return colors.selectedSurface;
                    }
                    return null;
                  }),
                  cells: [
                    DataCell(
                      _LeadNameTableCell(lead: lead),
                      onTap: () => onLeadSelected(lead),
                    ),
                    DataCell(
                      _TableStatusBadge(
                        label: _statusLabel(l, lead.status),
                      ),
                      onTap: () => onLeadSelected(lead),
                    ),
                    DataCell(
                      _TableStatusBadge(
                        label: _priorityLabel(l, lead.priority),
                      ),
                      onTap: () => onLeadSelected(lead),
                    ),
                    DataCell(
                      _TableText(
                        _sourceDisplayLabel(l, lead),
                        maxWidth: 110,
                      ),
                      onTap: () => onLeadSelected(lead),
                    ),
                    if (showAssignee)
                      DataCell(
                        _TableText(
                          assignee,
                          maxWidth: 120,
                        ),
                        onTap: () => onLeadSelected(lead),
                      ),
                    DataCell(
                      _FollowUpCell(lead: lead),
                      onTap: () => onLeadSelected(lead),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

Lead? _selectedLead(List<Lead> leads, String? selectedLeadId) {
  if (selectedLeadId == null) {
    return null;
  }
  for (final lead in leads) {
    if (lead.id == selectedLeadId) {
      return lead;
    }
  }
  return null;
}

class _LeadPreviewPanel extends StatelessWidget {
  const _LeadPreviewPanel({
    required this.lead,
    required this.users,
    required this.showAssignee,
    required this.companyId,
    required this.canEdit,
    required this.uid,
    required this.actorName,
    required this.isSaving,
  });

  final Lead? lead;
  final List<UserProfile> users;
  final bool showAssignee;
  final String companyId;
  final bool canEdit;
  final String uid;
  final String actorName;
  final bool isSaving;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    if (l == null) {
      return const SizedBox.shrink();
    }
    final selectedLead = lead;
    final assignee = selectedLead == null
        ? ''
        : _resolvedAssigneeName(
            l,
            selectedLead.assignedTo,
            selectedLead.assignedToName,
            users,
          );

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: _LeadListColors.of(context).cardSurface,
        border: Border.all(color: _LeadListColors.of(context).border),
        borderRadius: AppRadius.large,
      ),
      child: selectedLead == null
          ? AppEmptyState(
              title: l.selectLeadPreview,
              message: l.selectLeadPreviewMessage,
            )
          : Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    selectedLead.fullName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: [
                      AppStatusBadge(label: _statusLabel(l, selectedLead.status)),
                      AppStatusBadge(
                        label: _priorityLabel(l, selectedLead.priority),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _LeadPreviewContact(
                    icon: Icons.phone_outlined,
                    value: selectedLead.phone.isEmpty
                        ? l.notAvailable
                        : selectedLead.phone,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  _LeadPreviewContact(
                    icon: Icons.email_outlined,
                    value: selectedLead.email.isEmpty
                        ? l.notAvailable
                        : selectedLead.email,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _LeadPreviewField(
                    label: l.source,
                    value: _sourceDisplayLabel(l, selectedLead),
                  ),
                  if (showAssignee)
                    _LeadPreviewField(
                      label: l.assignedToLabel,
                      value: assignee,
                    ),
                  _LeadPreviewField(
                    label: l.nextFollowUp,
                    value: _followUpDateLabel(l, selectedLead.nextFollowUpAt),
                  ),
                  _LeadPreviewField(
                    label: l.lastContact,
                    value: _followUpDateLabel(l, selectedLead.lastContactAt),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            label: l.viewDetails,
            icon: Icons.open_in_new,
            isExpanded: true,
            onPressed: () => context.go(RouteNames.leadDetails(selectedLead.id)),
          ),
          if (canEdit) ...[
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                _PreviewActionIcon(
                  tooltip: l.markContactedToday,
                  icon: Icons.today_outlined,
                  isLoading: isSaving,
                  onPressed: isSaving
                      ? null
                      : () => _markContactedToday(context, selectedLead),
                ),
                _PreviewActionIcon(
                  tooltip: l.scheduleFollowUp,
                  icon: Icons.event_available_outlined,
                  isLoading: isSaving,
                  onPressed: isSaving
                      ? null
                      : () => _scheduleFollowUp(context, selectedLead),
                ),
                _PreviewActionIcon(
                  tooltip: l.editLead,
                  icon: Icons.edit_outlined,
                  onPressed: () => context.go(RouteNames.leadEdit(selectedLead.id)),
                ),
              ],
            ),
          ],
        ],
      )
);
  }

  void _markContactedToday(BuildContext context, Lead lead) {
    final now = DateTime.now();
    context.read<LeadsCubit>().updateLead(
      companyId: companyId,
      lead: lead.copyWith(lastContactAt: now, updatedAt: now, updatedBy: uid),
      actorName: actorName,
      successAction: LeadsAction.markContactedToday,
    );
  }

  Future<void> _scheduleFollowUp(BuildContext context, Lead lead) async {
    final today = DateUtils.dateOnly(DateTime.now());
    final current = lead.nextFollowUpAt;
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
    context.read<LeadsCubit>().updateLead(
      companyId: companyId,
      lead: lead.copyWith(
        nextFollowUpAt: DateUtils.dateOnly(pickedDate),
        updatedAt: now,
        updatedBy: uid,
      ),
      actorName: actorName,
    );
  }
}

class _PreviewActionIcon extends StatelessWidget {
  const _PreviewActionIcon({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.isLoading = false,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: IconButton.outlined(
        icon: isLoading
            ? const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(icon, size: 18),
        onPressed: isLoading ? null : onPressed,
      ),
    );
  }
}

class _LeadPreviewContact extends StatelessWidget {
  const _LeadPreviewContact({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondaryColor(context)),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}

class _LeadPreviewField extends StatelessWidget {
  const _LeadPreviewField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.textSecondaryColor(context),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _LeadCard extends StatelessWidget {
  const _LeadCard({
    required this.lead,
    required this.users,
  });

  final Lead lead;
  final List<UserProfile> users;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    if (localizations == null) {
      return const SizedBox.shrink();
    }
    final contact = lead.phone.isNotEmpty
        ? lead.phone
        : lead.email.isNotEmpty
        ? lead.email
        : localizations.notAvailable;
    final assignee = _resolvedAssigneeName(
      localizations,
      lead.assignedTo,
      lead.assignedToName,
      users,
    );

    return InkWell(
      onTap: () => context.go(RouteNames.leadDetails(lead.id)),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
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
                Expanded(child: _LeadTitle(lead: lead)),
                AppStatusBadge(label: _statusLabel(localizations, lead.status)),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              contact,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                AppStatusBadge(
                  label: _priorityLabel(localizations, lead.priority),
                ),
                _LeadMetaChip(label: _sourceDisplayLabel(localizations, lead)),
                _LeadMetaChip(
                  label: '${localizations.assignedToLabel}: $assignee',
                ),
                _LeadMetaChip(
                  label:
                      '${localizations.nextFollowUp}: ${_followUpDateLabel(localizations, lead.nextFollowUpAt)}',
                ),
                AppStatusBadge(
                  label: _followUpStatusLabel(localizations, lead),
                  tone: _followUpStatusTone(lead),
                ),
                if (_needsStaleLeadAttention(lead))
                  Tooltip(
                    message: _staleLeadLabel(localizations, lead),
                    child: AppStatusBadge(
                      label: _staleLeadLabel(localizations, lead),
                      tone: AppStatusTone.warning,
                    ),
                  ),
                _LeadMetaChip(
                  label:
                      '${localizations.updated}: ${_shortDate(lead.updatedAt)}',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LeadMetaChip extends StatelessWidget {
  const _LeadMetaChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: _LeadListColors.of(context).inputSurface,
        border: Border.all(color: _LeadListColors.of(context).border),
        borderRadius: AppRadius.large,
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppColors.textSecondaryColor(context),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _FollowUpCell extends StatelessWidget {
  const _FollowUpCell({required this.lead});

  final Lead lead;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    if (localizations == null) {
      return const SizedBox.shrink();
    }
    if (lead.nextFollowUpAt == null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TableStatusBadge(
            label: _followUpStatusLabel(localizations, lead),
            tone: _followUpStatusTone(lead),
          ),
          if (_needsStaleLeadAttention(lead)) ...[
            const SizedBox(height: 2),
            _TableStatusBadge(
              label: _staleLeadLabel(localizations, lead),
              tone: AppStatusTone.warning,
            ),
          ],
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _followUpDateLabel(localizations, lead.nextFollowUpAt),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        _TableStatusBadge(
          label: _followUpStatusLabel(localizations, lead),
          tone: _followUpStatusTone(lead),
        ),
        if (_needsStaleLeadAttention(lead)) ...[
          const SizedBox(height: 2),
          _TableStatusBadge(
            label: _staleLeadLabel(localizations, lead),
            tone: AppStatusTone.warning,
          ),
        ],
      ],
    );
  }
}

class _TableStatusBadge extends StatelessWidget {
  const _TableStatusBadge({
    required this.label,
    this.tone = AppStatusTone.neutral,
  });

  final String label;
  final AppStatusTone tone;

  @override
  Widget build(BuildContext context) {
    final colors = _badgeColorsFor(context, tone);
    return Container(
      constraints: const BoxConstraints(maxWidth: 132),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: colors.background,
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        softWrap: false,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: colors.foreground,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _TableText extends StatelessWidget {
  const _TableText(this.value, {required this.maxWidth});

  final String value;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        softWrap: false,
      ),
    );
  }
}

class _LeadNameTableCell extends StatelessWidget {
  const _LeadNameTableCell({required this.lead});

  final Lead lead;

  @override
  Widget build(BuildContext context) {
    final secondary = lead.phone.isNotEmpty ? lead.phone : lead.email;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 180),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            lead.fullName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
          ),
          if (secondary.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              secondary,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondaryColor(context),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

_TableBadgeColors _badgeColorsFor(BuildContext context, AppStatusTone tone) {
  final scheme = Theme.of(context).colorScheme;
  final isDark = Theme.of(context).brightness == Brightness.dark;

  if (isDark) {
    return switch (tone) {
      AppStatusTone.success => const _TableBadgeColors(
        background: Color(0xFF123A28),
        foreground: AppColors.darkSuccess,
        border: Color(0xFF1F6B42),
      ),
      AppStatusTone.warning => const _TableBadgeColors(
        background: Color(0xFF3B2A10),
        foreground: AppColors.darkWarning,
        border: Color(0xFF78570F),
      ),
      AppStatusTone.error => const _TableBadgeColors(
        background: Color(0xFF3B1D1D),
        foreground: AppColors.darkError,
        border: Color(0xFF7F2D2D),
      ),
      AppStatusTone.info => const _TableBadgeColors(
        background: Color(0xFF172D4D),
        foreground: AppColors.darkInfo,
        border: Color(0xFF315A8E),
      ),
      AppStatusTone.neutral => const _TableBadgeColors(
        background: AppColors.darkSurfaceAlt,
        foreground: AppColors.darkTextSecondary,
        border: AppColors.darkBorder,
      ),
    };
  }

  return switch (tone) {
    AppStatusTone.success => const _TableBadgeColors(
      background: Color(0xFFEAF7EF),
      foreground: Color(0xFF15803D),
      border: Color(0xFFC8EAD3),
    ),
    AppStatusTone.warning => const _TableBadgeColors(
      background: Color(0xFFFFF7E6),
      foreground: Color(0xFF9A5B00),
      border: Color(0xFFF2D49B),
    ),
    AppStatusTone.error => const _TableBadgeColors(
      background: Color(0xFFFFEDEA),
      foreground: Color(0xFFB42318),
      border: Color(0xFFF4C7C1),
    ),
    AppStatusTone.info => const _TableBadgeColors(
      background: Color(0xFFEFF6FF),
      foreground: Color(0xFF2563EB),
      border: Color(0xFFC8DDFF),
    ),
    AppStatusTone.neutral => _TableBadgeColors(
      background: scheme.surface,
      foreground: scheme.onSurfaceVariant,
      border: scheme.outlineVariant,
    ),
  };
}

class _TableBadgeColors {
  const _TableBadgeColors({
    required this.background,
    required this.foreground,
    required this.border,
  });

  final Color background;
  final Color foreground;
  final Color border;
}

class _LeadTitle extends StatelessWidget {
  const _LeadTitle({required this.lead});

  final Lead lead;

  @override
  Widget build(BuildContext context) {
    return Text(
      lead.fullName,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
    );
  }
}

bool _can(AuthState state, AppPermission permission) {
  final role = state.userProfile?.role ?? state.user?.role;
  return role != null && PermissionService.can(role, permission);
}

class _LeadListColors {
  const _LeadListColors({
    required this.cardSurface,
    required this.inputSurface,
    required this.selectedSurface,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
  });

  final Color cardSurface;
  final Color inputSurface;
  final Color selectedSurface;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;

  factory _LeadListColors.of(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (!isDark) {
      return const _LeadListColors(
        cardSurface: AppColors.surface,
        inputSurface: AppColors.background,
        selectedSurface: Color(0x0F123047),
        border: AppColors.border,
        textPrimary: AppColors.textPrimary,
        textSecondary: AppColors.textSecondary,
      );
    }

    return const _LeadListColors(
      cardSurface: AppColors.darkCardSurface,
      inputSurface: AppColors.darkSurfaceAlt,
      selectedSurface: AppColors.darkSelectedSurface,
      border: AppColors.darkBorder,
      textPrimary: AppColors.darkTextPrimary,
      textSecondary: AppColors.darkTextSecondary,
    );
  }
}

String _statusLabel(AppLocalizations localizations, LeadStatus? status) {
  if (status == null) {
    return localizations.notAvailable;
  }
  switch (status) {
    case LeadStatus.newLead:
      return localizations.newLead;
    case LeadStatus.contacted:
      return localizations.contacted;
    case LeadStatus.interested:
      return localizations.interested;
    case LeadStatus.visitScheduled:
      return localizations.visitScheduled;
    case LeadStatus.negotiation:
      return localizations.negotiation;
    case LeadStatus.won:
      return localizations.won;
    case LeadStatus.lost:
      return localizations.lost;
  }
}

String _sourceLabel(AppLocalizations localizations, LeadSource? source) {
  if (source == null) {
    return localizations.notAvailable;
  }
  switch (source) {
    case LeadSource.facebook:
      return localizations.facebook;
    case LeadSource.website:
      return localizations.website;
    case LeadSource.phoneCall:
      return localizations.phoneCall;
    case LeadSource.whatsapp:
      return localizations.whatsapp;
    case LeadSource.referral:
      return localizations.referral;
    case LeadSource.walkIn:
      return localizations.walkIn;
    case LeadSource.other:
      return localizations.other;
  }
}

String _sourceDisplayLabel(AppLocalizations localizations, Lead lead) {
  final sourceLabel = _sourceLabel(localizations, lead.source);
  if (lead.source != LeadSource.other || lead.sourceDetails.trim().isEmpty) {
    return sourceLabel;
  }

  return '$sourceLabel - ${lead.sourceDetails.trim()}';
}

String _priorityLabel(AppLocalizations localizations, LeadPriority? priority) {
  if (priority == null) {
    return localizations.notAvailable;
  }
  switch (priority) {
    case LeadPriority.low:
      return localizations.low;
    case LeadPriority.medium:
      return localizations.medium;
    case LeadPriority.high:
      return localizations.high;
  }
}

String _shortDate(DateTime value) {
  final local = value.toLocal();
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  return '${local.year}-$month-$day';
}

String _followUpDateLabel(AppLocalizations localizations, DateTime? value) {
  if (value == null) {
    return localizations.notAvailable;
  }

  return _shortDate(value);
}

String _followUpStatusLabel(AppLocalizations localizations, Lead lead) {
  final nextFollowUpAt = lead.nextFollowUpAt;
  if (nextFollowUpAt == null) {
    return localizations.notScheduled;
  }

  final today = DateUtils.dateOnly(DateTime.now());
  final followUpDate = DateUtils.dateOnly(nextFollowUpAt.toLocal());
  if (followUpDate.isBefore(today)) {
    return localizations.overdue;
  }
  if (followUpDate == today) {
    return localizations.dueToday;
  }
  return localizations.upcoming;
}

AppStatusTone _followUpStatusTone(Lead lead) {
  final nextFollowUpAt = lead.nextFollowUpAt;
  if (nextFollowUpAt == null) {
    return AppStatusTone.neutral;
  }

  final today = DateUtils.dateOnly(DateTime.now());
  final followUpDate = DateUtils.dateOnly(nextFollowUpAt.toLocal());
  if (followUpDate.isBefore(today)) {
    return AppStatusTone.error;
  }
  if (followUpDate == today) {
    return AppStatusTone.warning;
  }
  return AppStatusTone.info;
}

bool _needsStaleLeadAttention(Lead lead) {
  final nextFollowUpAt = lead.nextFollowUpAt;
  final today = DateUtils.dateOnly(DateTime.now());
  if (nextFollowUpAt != null) {
    return DateUtils.dateOnly(nextFollowUpAt.toLocal()).isBefore(today);
  }

  final lastContactAt = lead.lastContactAt;
  if (lastContactAt == null) {
    return false;
  }

  final staleBefore = today.subtract(const Duration(days: 7));
  return DateUtils.dateOnly(lastContactAt.toLocal()).isBefore(staleBefore);
}

String _staleLeadLabel(AppLocalizations localizations, Lead lead) {
  return lead.nextFollowUpAt == null
      ? localizations.staleLead
      : localizations.needsAttention;
}

String _followUpFilterLabel(
  AppLocalizations localizations,
  LeadFollowUpFilter? filter,
) {
  if (filter == null) {
    return localizations.allFollowUps;
  }
  return switch (filter) {
    LeadFollowUpFilter.overdue => localizations.overdue,
    LeadFollowUpFilter.dueToday => localizations.dueToday,
    LeadFollowUpFilter.upcoming => localizations.upcoming,
    LeadFollowUpFilter.notScheduled => localizations.notScheduled,
  };
}

String _resolvedAssigneeName(
  AppLocalizations localizations,
  String uid,
  String assignedToName,
  List<UserProfile> users,
) {
  if (assignedToName.isNotEmpty) {
    return assignedToName;
  }
  if (uid.isEmpty) {
    return localizations.unassigned;
  }
  for (final user in users) {
    if (user.uid == uid) {
      return user.fullName;
    }
  }
  if (!_looksLikeUid(uid)) {
    return uid;
  }
  return localizations.assignedUserUnavailable;
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
