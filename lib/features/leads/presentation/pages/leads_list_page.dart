import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/error_mapper.dart';
import '../../../../core/permissions/app_permission.dart';
import '../../../../core/permissions/permission_service.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/app_colors.dart';
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
    final localizations = AppLocalizations.of(context)!;

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
    required this.canCreate,
    required this.canEdit,
    required this.roleName,
  });

  final String companyId;
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
    final localizations = AppLocalizations.of(context)!;

    return BlocBuilder<LeadsCubit, LeadsState>(
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
                      const SizedBox(height: AppSpacing.lg),
                      Expanded(
                        child: _LeadsBody(
                          state: state,
                          companyId: widget.companyId,
                          assignedTo: _assignedToFilter,
                          users: users,
                          roleName: widget.roleName,
                          canEdit: widget.canEdit,
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
    final localizations = AppLocalizations.of(context)!;

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

            return Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.md,
              children: [
                SizedBox(
                  width: 260,
                  child: _LeadSearchField(
                    onChanged: context.read<LeadsCubit>().setSearchQuery,
                  ),
                ),
                _DesktopFilterDropdown<_LeadFilterOption<LeadStatus>>(
                  label: localizations.status,
                  value: _LeadFilterOption.fromValue(state.statusFilter),
                  items: _leadFilterOptions(LeadStatus.values),
                  itemLabelBuilder: (option) => option.isAll
                      ? localizations.allStatuses
                      : _statusLabel(localizations, option.value!),
                  onChanged: (option) {
                    context.read<LeadsCubit>().setStatusFilter(option.value);
                  },
                ),
                _DesktopFilterDropdown<_LeadFilterOption<LeadSource>>(
                  label: localizations.source,
                  value: _LeadFilterOption.fromValue(state.sourceFilter),
                  items: _leadFilterOptions(LeadSource.values),
                  itemLabelBuilder: (option) => option.isAll
                      ? localizations.allSources
                      : _sourceLabel(localizations, option.value!),
                  onChanged: (option) {
                    context.read<LeadsCubit>().setSourceFilter(option.value);
                  },
                ),
                _DesktopFilterDropdown<_LeadFilterOption<LeadPriority>>(
                  label: localizations.priority,
                  value: _LeadFilterOption.fromValue(state.priorityFilter),
                  items: _leadFilterOptions(LeadPriority.values),
                  itemLabelBuilder: (option) => option.isAll
                      ? localizations.allPriorities
                      : _priorityLabel(localizations, option.value!),
                  onChanged: (option) {
                    context.read<LeadsCubit>().setPriorityFilter(option.value);
                  },
                ),
                _DesktopFilterDropdown<_LeadFilterOption<LeadFollowUpFilter>>(
                  label: localizations.nextFollowUp,
                  value: _LeadFilterOption.fromValue(state.followUpFilter),
                  items: _leadFilterOptions(LeadFollowUpFilter.values),
                  itemLabelBuilder: (option) => option.isAll
                      ? localizations.allFollowUps
                      : _followUpFilterLabel(localizations, option.value!),
                  onChanged: (option) {
                    context.read<LeadsCubit>().setFollowUpFilter(option.value);
                  },
                ),
                if (showAssignee)
                  _DesktopFilterDropdown<_LeadFilterOption<String>>(
                    label: localizations.assignee,
                    value: _LeadFilterOption.fromValue(
                      state.assignedToFilter,
                    ),
                    items: _assigneeFilterOptions(users, state.leads),
                    itemLabelBuilder: (option) => option.isAll
                        ? localizations.allAssignees
                        : _userNameForFilter(
                            localizations,
                            users,
                            state.leads,
                            option.value!,
                          ),
                    onChanged: (option) {
                      context.read<LeadsCubit>().setAssignedToFilter(
                        option.value,
                      );
                    },
                  ),
              ],
            );
          },
        );
      },
    );
  }
}

class _LeadSearchField extends StatelessWidget {
  const _LeadSearchField({required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return TextField(
      decoration: InputDecoration(
        labelText: localizations.searchLeads,
        prefixIcon: const Icon(Icons.search),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onChanged: onChanged,
    );
  }
}

class _DesktopFilterDropdown<T> extends StatelessWidget {
  const _DesktopFilterDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.itemLabelBuilder,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<T> items;
  final String Function(T item) itemLabelBuilder;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 190,
      child: AppDropdown<T>(
        label: label,
        value: value,
        items: items,
        itemLabelBuilder: itemLabelBuilder,
        onChanged: onChanged,
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
    final localizations = AppLocalizations.of(context)!;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _LeadSearchField(
            onChanged: context.read<LeadsCubit>().setSearchQuery,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        SizedBox(
          height: 56,
          child: AppButton(
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
  String uid,
) {
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
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) {
      LeadStatus? status = state.statusFilter;
      LeadSource? source = state.sourceFilter;
      LeadPriority? priority = state.priorityFilter;
      String? assignee = state.assignedToFilter;
      LeadFollowUpFilter? followUp = state.followUpFilter;

      return StatefulBuilder(
        builder: (context, setSheetState) {
          final localizations = AppLocalizations.of(context)!;

          return SafeArea(
            child: Padding(
              padding: EdgeInsetsDirectional.only(
                start: AppSpacing.md,
                end: AppSpacing.md,
                bottom:
                    MediaQuery.of(context).viewInsets.bottom + AppSpacing.md,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    localizations.filters,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppDropdown<_LeadFilterOption<LeadStatus>>(
                    label: localizations.status,
                    value: _LeadFilterOption.fromValue(status),
                    items: _leadFilterOptions(LeadStatus.values),
                    itemLabelBuilder: (item) => item.isAll
                        ? localizations.allStatuses
                        : _statusLabel(localizations, item.value!),
                    onChanged: (option) {
                      setSheetState(() => status = option.value);
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppDropdown<_LeadFilterOption<LeadSource>>(
                    label: localizations.source,
                    value: _LeadFilterOption.fromValue(source),
                    items: _leadFilterOptions(LeadSource.values),
                    itemLabelBuilder: (item) => item.isAll
                        ? localizations.allSources
                        : _sourceLabel(localizations, item.value!),
                    onChanged: (option) {
                      setSheetState(() => source = option.value);
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppDropdown<_LeadFilterOption<LeadPriority>>(
                    label: localizations.priority,
                    value: _LeadFilterOption.fromValue(priority),
                    items: _leadFilterOptions(LeadPriority.values),
                    itemLabelBuilder: (item) => item.isAll
                        ? localizations.allPriorities
                        : _priorityLabel(localizations, item.value!),
                    onChanged: (option) {
                      setSheetState(() => priority = option.value);
                    },
                  ),
                  if (showAssignee) ...[
                    const SizedBox(height: AppSpacing.md),
                    AppDropdown<_LeadFilterOption<String>>(
                      label: localizations.assignee,
                      value: _LeadFilterOption.fromValue(assignee),
                      items: _assigneeFilterOptions(users, state.leads),
                      itemLabelBuilder: (item) => item.isAll
                          ? localizations.allAssignees
                          : _userNameForFilter(
                              localizations,
                              users,
                              state.leads,
                              item.value!,
                            ),
                      onChanged: (option) {
                        setSheetState(() => assignee = option.value);
                      },
                    ),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  AppDropdown<_LeadFilterOption<LeadFollowUpFilter>>(
                    label: localizations.nextFollowUp,
                    value: _LeadFilterOption.fromValue(followUp),
                    items: _leadFilterOptions(LeadFollowUpFilter.values),
                    itemLabelBuilder: (item) => item.isAll
                        ? localizations.allFollowUps
                        : _followUpFilterLabel(localizations, item.value!),
                    onChanged: (option) {
                      setSheetState(() => followUp = option.value);
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          label: localizations.clearFilters,
                          variant: AppButtonVariant.secondary,
                          onPressed: () {
                            cubit.setStatusFilter(null);
                            cubit.setSourceFilter(null);
                            cubit.setPriorityFilter(null);
                            cubit.setAssignedToFilter(null);
                            cubit.setFollowUpFilter(null);
                            Navigator.of(sheetContext).pop();
                          },
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: AppButton(
                          label: localizations.applyFilters,
                          onPressed: () {
                            cubit.setStatusFilter(status);
                            cubit.setSourceFilter(source);
                            cubit.setPriorityFilter(priority);
                            cubit.setAssignedToFilter(assignee);
                            cubit.setFollowUpFilter(followUp);
                            Navigator.of(sheetContext).pop();
                          },
                        ),
                      ),
                    ],
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
  });

  final LeadsState state;
  final String companyId;
  final String? assignedTo;
  final List<UserProfile> users;
  final String roleName;
  final bool canEdit;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

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
          allLeads: state.leads,
          users: users,
          showAssignee: roleName == 'admin' || roleName == 'manager',
          canEdit: canEdit,
          isRefreshing: state.status == LeadsStatus.loading,
        );
      },
    );
  }
}

class _LeadsWebWorkspace extends StatefulWidget {
  const _LeadsWebWorkspace({
    required this.leads,
    required this.allLeads,
    required this.users,
    required this.showAssignee,
    required this.canEdit,
    required this.isRefreshing,
  });

  final List<Lead> leads;
  final List<Lead> allLeads;
  final List<UserProfile> users;
  final bool showAssignee;
  final bool canEdit;
  final bool isRefreshing;

  @override
  State<_LeadsWebWorkspace> createState() => _LeadsWebWorkspaceState();
}

class _LeadsWebWorkspaceState extends State<_LeadsWebWorkspace> {
  String? _selectedLeadId;

  @override
  Widget build(BuildContext context) {
    final selectedLead = _selectedLead(widget.leads, _selectedLeadId);

    return Stack(
      children: [
        Column(
          children: [
            _LeadSummaryCards(
              leads: widget.allLeads,
              showAssignee: widget.showAssignee,
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 68,
                    child: widget.leads.isEmpty
                        ? AppEmptyState(
                            title: AppLocalizations.of(context)!.noLeads,
                            message:
                                AppLocalizations.of(context)!.leadsSubtitle,
                          )
                        : _LeadsWebTable(
                            leads: widget.leads,
                            users: widget.users,
                            showAssignee: widget.showAssignee,
                            selectedLeadId: selectedLead?.id,
                            onLeadSelected: (lead) {
                              setState(() => _selectedLeadId = lead.id);
                            },
                          ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    flex: 32,
                    child: _LeadPreviewPanel(
                      lead: selectedLead,
                      users: widget.users,
                      showAssignee: widget.showAssignee,
                      canEdit: widget.canEdit,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (widget.isRefreshing)
          Positioned.fill(
            child: IgnorePointer(
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
    final l = AppLocalizations.of(context)!;
    final newLeads = leads.where((lead) => lead.status == LeadStatus.newLead);
    final activeLeads = leads.where((lead) {
      return lead.status == LeadStatus.contacted ||
          lead.status == LeadStatus.interested ||
          lead.status == LeadStatus.visitScheduled ||
          lead.status == LeadStatus.negotiation;
    });
    final unassignedLeads = leads.where((lead) => lead.assignedTo.isEmpty);
    final cards = [
      _LeadSummaryCard(label: l.totalLeads, value: leads.length),
      _LeadSummaryCard(label: l.newLeads, value: newLeads.length),
      _LeadSummaryCard(label: l.activeLeads, value: activeLeads.length),
      if (showAssignee)
        _LeadSummaryCard(label: l.unassignedLeads, value: unassignedLeads.length),
    ];

    return Row(
      children: [
        for (var index = 0; index < cards.length; index++) ...[
          Expanded(child: cards[index]),
          if (index != cards.length - 1) const SizedBox(width: AppSpacing.sm),
        ],
      ],
    );
  }
}

class _LeadSummaryCard extends StatelessWidget {
  const _LeadSummaryCard({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: _LeadListColors.of(context).cardSurface,
        border: Border.all(color: _LeadListColors.of(context).border),
        borderRadius: BorderRadius.circular(8),
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
        ],
      ),
    );
  }
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
    final l = AppLocalizations.of(context)!;
    final colors = _LeadListColors.of(context);

    return Container(
      decoration: BoxDecoration(
        color: colors.cardSurface,
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(10),
      ),
      clipBehavior: Clip.antiAlias,
      child: DataTableTheme(
        data: Theme.of(context).dataTableTheme.copyWith(
          decoration: BoxDecoration(color: colors.cardSurface),
        ),
        child: ColoredBox(
          color: colors.cardSurface,
          child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
          horizontalMargin: 16,
          columnSpacing: 22,
          headingRowHeight: 44,
          dataRowMinHeight: 46,
          dataRowMaxHeight: 54,
          columns: [
            DataColumn(label: Text(l.leadName)),
            DataColumn(label: Text(l.phone)),
            DataColumn(label: Text(l.status)),
            DataColumn(label: Text(l.priority)),
            DataColumn(label: Text(l.source)),
            if (showAssignee) DataColumn(label: Text(l.assignedToLabel)),
            DataColumn(label: Text(l.nextFollowUp)),
            DataColumn(label: Text(l.updated)),
            DataColumn(label: Text(l.details)),
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
              selected: selected,
              color: WidgetStateProperty.resolveWith((states) {
                if (selected || states.contains(WidgetState.hovered)) {
                  return _LeadListColors.of(context).selectedSurface;
                }
                return null;
              }),
              cells: [
                DataCell(
                  Text(
                    lead.fullName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () => onLeadSelected(lead),
                ),
                DataCell(
                  Text(
                    lead.phone,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () => onLeadSelected(lead),
                ),
                DataCell(
                  AppStatusBadge(label: _statusLabel(l, lead.status)),
                  onTap: () => onLeadSelected(lead),
                ),
                DataCell(
                  AppStatusBadge(label: _priorityLabel(l, lead.priority)),
                  onTap: () => onLeadSelected(lead),
                ),
                DataCell(
                  Text(
                    _sourceDisplayLabel(l, lead),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () => onLeadSelected(lead),
                ),
                if (showAssignee)
                  DataCell(
                    Text(
                      assignee,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () => onLeadSelected(lead),
                  ),
                DataCell(
                  _FollowUpCell(lead: lead),
                  onTap: () => onLeadSelected(lead),
                ),
                DataCell(
                  Text(_shortDate(lead.updatedAt)),
                  onTap: () => onLeadSelected(lead),
                ),
                DataCell(
                  IconButton(
                    tooltip: l.details,
                    onPressed: () =>
                        context.go(RouteNames.leadDetails(lead.id)),
                    icon: const Icon(Icons.open_in_new, size: 18),
                  ),
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
    required this.canEdit,
  });

  final Lead? lead;
  final List<UserProfile> users;
  final bool showAssignee;
  final bool canEdit;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final selectedLead = lead;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: _LeadListColors.of(context).cardSurface,
        border: Border.all(color: _LeadListColors.of(context).border),
        borderRadius: BorderRadius.circular(10),
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
                  _LeadPreviewField(
                    label: l.source,
                    value: _sourceDisplayLabel(l, selectedLead),
                  ),
                  if (showAssignee)
                    _LeadPreviewField(
                      label: l.assignedToLabel,
                      value: _resolvedAssigneeName(
                        l,
                        selectedLead.assignedTo,
                        selectedLead.assignedToName,
                        users,
                      ),
                    ),
                  _LeadPreviewField(
                    label: l.updated,
                    value: _shortDate(selectedLead.updatedAt),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: l.viewDetails,
            icon: Icons.open_in_new,
            onPressed: () => context.go(RouteNames.leadDetails(selectedLead.id)),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            label: l.editLead,
            icon: Icons.edit_outlined,
            variant: AppButtonVariant.secondary,
            onPressed: canEdit
                ? () => context.go(RouteNames.leadEdit(selectedLead.id))
                : null,
          ),
        ],
      )
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
  const _LeadCard({required this.lead, required this.users});

  final Lead lead;
  final List<UserProfile> users;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
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
          borderRadius: BorderRadius.circular(8),
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
        borderRadius: BorderRadius.circular(8),
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
    final localizations = AppLocalizations.of(context)!;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _followUpDateLabel(localizations, lead.nextFollowUpAt),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(width: AppSpacing.xs),
        AppStatusBadge(
          label: _followUpStatusLabel(localizations, lead),
          tone: _followUpStatusTone(lead),
        ),
      ],
    );
  }
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

String _statusLabel(AppLocalizations localizations, LeadStatus status) {
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

String _sourceLabel(AppLocalizations localizations, LeadSource source) {
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

String _priorityLabel(AppLocalizations localizations, LeadPriority priority) {
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

String _followUpFilterLabel(
  AppLocalizations localizations,
  LeadFollowUpFilter filter,
) {
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
