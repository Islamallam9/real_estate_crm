import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/role_constants.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_status_badge.dart';
import '../../../../core/widgets/crm_app_shell.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../platform/domain/entities/company_data_health_report.dart';
import '../../../users/domain/entities/user_profile.dart';
import '../../data/datasources/data_health_remote_data_source.dart';
import '../../data/repositories/data_health_repository_impl.dart';
import '../../domain/usecases/backfill_operational_record_snapshots_usecase.dart';
import '../../domain/usecases/get_data_health_eligible_assignees_usecase.dart';
import '../../domain/usecases/get_operational_data_health_report_usecase.dart';
import '../../domain/usecases/notify_data_health_manager_usecase.dart';
import '../../domain/usecases/reassign_data_health_record_usecase.dart';
import '../cubit/data_health_cubit.dart';
import '../cubit/data_health_state.dart';

class DataHealthPage extends StatefulWidget {
  const DataHealthPage({super.key});

  static Widget withDependencies() => const DataHealthPage();

  @override
  State<DataHealthPage> createState() => _DataHealthPageState();
}

class _DataHealthPageState extends State<DataHealthPage> {
  late final DataHealthCubit _cubit;

  @override
  void initState() {
    super.initState();
    final remoteDataSource = FirebaseDataHealthRemoteDataSource();
    final repository = DataHealthRepositoryImpl(remoteDataSource: remoteDataSource);
    _cubit = DataHealthCubit(
      getReportUseCase: GetOperationalDataHealthReportUseCase(repository),
      backfillUseCase: BackfillOperationalRecordSnapshotsUseCase(repository),
      reassignUseCase: ReassignDataHealthRecordUseCase(repository),
      eligibleAssigneesUseCase: GetDataHealthEligibleAssigneesUseCase(repository),
      notifyManagerUseCase: NotifyDataHealthManagerUseCase(repository),
    );
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _DataHealthView(cubit: _cubit);
}

class _DataHealthView extends StatelessWidget {
  const _DataHealthView({required this.cubit});

  final DataHealthCubit cubit;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final authState = context.watch<AuthBloc>().state;
    final profile = authState.userProfile;
    final companyId = profile?.companyId ?? '';
    final role = profile?.role;
    final allowed = role == UserRole.admin;

    return CrmAppShell(
      selectedItem: CrmNavigationItem.dataHealth,
      title: l.dataHealth,
      child: BlocListener<DataHealthCubit, DataHealthState>(
        bloc: cubit,
        listenWhen: (previous, current) =>
            previous.status != current.status && current.status == DataHealthStatus.failure,
        listener: (context, state) {
          AppFeedback.error(context, state.message ?? l.somethingWentWrong);
        },
        child: !allowed
            ? AppErrorView(
                message: l.permissionDenied,
                onRetry: () => context.go(RouteNames.dashboard),
              )
            : _DataHealthContent(
                cubit: cubit,
                companyId: companyId,
                currentUser: profile,
              ),
      ),
    );
  }
}

class _DataHealthContent extends StatefulWidget {
  const _DataHealthContent({required this.cubit, required this.companyId, required this.currentUser});

  final DataHealthCubit cubit;
  final String companyId;
  final UserProfile? currentUser;

  @override
  State<_DataHealthContent> createState() => _DataHealthContentState();
}

class _DataHealthContentState extends State<_DataHealthContent> {
  String? _restoredForCompanyId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.companyId.isNotEmpty && _restoredForCompanyId != widget.companyId) {
      _restoredForCompanyId = widget.companyId;
      widget.cubit.restoreCachedReport(widget.companyId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return BlocBuilder<DataHealthCubit, DataHealthState>(
      bloc: widget.cubit,
      builder: (context, state) {
        final report = state.report;
        final isLoading = state.status == DataHealthStatus.loading && report == null;
        if (isLoading) {
          return const AppLoading();
        }

        return ListView(
          padding: EdgeInsets.zero,
          children: [
            _HeaderCard(
              title: l.dataHealth,
              subtitle: l.companyDataHealthMessage,
              action: AppButton(
                label: l.runDataHealthCheck,
                icon: Icons.fact_check_outlined,
                isLoading: state.status == DataHealthStatus.loading,
                onPressed: widget.companyId.isEmpty || state.status == DataHealthStatus.loading
                    ? null
                    : () => widget.cubit.loadReport(widget.companyId),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            if (report != null) ...[
              Text(
                '${l.updatedAt}: ${_formatDateTime(context, report.generatedAt)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondaryColor(context),
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            if (report == null)
              AppEmptyState(
                icon: Icons.health_and_safety_outlined,
                title: l.dataHealthNotRun,
                message: l.dataHealthNotRunMessage,
              )
            else ...[
              _SummaryGrid(report: report),
              const SizedBox(height: AppSpacing.sm),
              if (!report.hasIssues)
                AppEmptyState(
                  icon: Icons.verified_outlined,
                  title: l.dataHealthClean,
                  message: l.dataHealthCleanMessage,
                )
              else
                _IssueList(
                  cubit: widget.cubit,
                  companyId: widget.companyId,
                  currentUser: widget.currentUser,
                  state: state,
                  issues: report.issues,
                ),
            ],
          ],
        );
      },
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.title, required this.subtitle, required this.action});

  final String title;
  final String subtitle;
  final Widget action;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.cardSurface(context),
        border: Border.all(color: AppColors.borderColor(context)),
        borderRadius: AppRadius.xLarge,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 680;
          final text = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(subtitle, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondaryColor(context))),
            ],
          );
          if (narrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                text,
                const SizedBox(height: AppSpacing.sm),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: action,
                ),
              ],
            );
          }
          return Row(
            children: [Expanded(child: text), const SizedBox(width: AppSpacing.md), action],
          );
        },
      ),
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({required this.report});

  final CompanyDataHealthReport report;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 360 ? 2 : 1;
        return GridView.count(
          crossAxisCount: columns,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AppSpacing.sm,
          crossAxisSpacing: AppSpacing.sm,
          childAspectRatio: constraints.maxWidth < 520 ? 2.8 : 4.8,
          children: [
            _KpiCard(label: l.invalidAssignees, value: report.invalidAssignees.toString(), icon: Icons.person_off_outlined, tone: AppStatusTone.error),
            _KpiCard(label: l.inactiveAssignees, value: report.inactiveAssignees.toString(), icon: Icons.block_outlined, tone: AppStatusTone.warning),
          ],
        );
      },
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({required this.label, required this.value, required this.icon, required this.tone});

  final String label;
  final String value;
  final IconData icon;
  final AppStatusTone tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.cardSurface(context),
        border: Border.all(color: AppColors.borderColor(context)),
        borderRadius: AppRadius.large,
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: AppColors.primaryColor(context).withValues(alpha: 0.10),
              borderRadius: AppRadius.medium,
            ),
            child: Icon(icon, color: AppColors.primaryColor(context), size: 16),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondaryColor(context))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IssueList extends StatelessWidget {
  const _IssueList({
    required this.cubit,
    required this.companyId,
    required this.currentUser,
    required this.state,
    required this.issues,
  });

  final DataHealthCubit cubit;
  final String companyId;
  final UserProfile? currentUser;
  final DataHealthState state;
  final List<DataHealthIssue> issues;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l.dataHealthAffectedRecords, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: AppSpacing.sm),
        for (final issue in issues.take(120)) ...[
          _IssueTile(
            cubit: cubit,
            companyId: companyId,
            currentUser: currentUser,
            state: state,
            issue: issue,
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}

class _IssueTile extends StatelessWidget {
  const _IssueTile({
    required this.cubit,
    required this.companyId,
    required this.currentUser,
    required this.state,
    required this.issue,
  });

  final DataHealthCubit cubit;
  final String companyId;
  final UserProfile? currentUser;
  final DataHealthState state;
  final DataHealthIssue issue;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final backfillActionId = '${issue.module}/${issue.recordId}/backfill';
    final reassignActionId = '${issue.module}/${issue.recordId}/reassign';
    final notifyActionId = '${issue.module}/${issue.recordId}/notifyManager';
    final isBackfilling = state.activeActionId == backfillActionId;
    final isReassigning = state.activeActionId == reassignActionId;
    final isNotifying = state.activeActionId == notifyActionId;
    final assigneeLabel = _assigneeLabel(l, issue);
    final needsReassign = !issue.canBackfill;
    final canNotifyManager = issue.managerId.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.cardSurface(context),
        border: Border.all(color: AppColors.borderColor(context)),
        borderRadius: AppRadius.large,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 760;
          final content = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primaryColor(context).withValues(alpha: 0.12),
                child: Icon(Icons.fact_check_outlined, color: AppColors.primaryColor(context), size: 16),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: [
                        AppStatusBadge(label: _moduleLabel(l, issue.module), tone: AppStatusTone.neutral),
                        AppStatusBadge(label: _issueLabel(l, issue.issueType), tone: issue.canBackfill ? AppStatusTone.info : AppStatusTone.warning),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(issue.title.isEmpty ? issue.recordId : issue.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text('${l.assignedTo}: $assigneeLabel', maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondaryColor(context))),
                    if (issue.suggestedAction.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(_suggestedAction(l, issue), maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondaryColor(context))),
                    ],
                  ],
                ),
              ),
            ],
          );
          final actions = Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              if (issue.canBackfill)
                AppButton(
                  label: l.backfillSnapshots,
                  icon: Icons.auto_fix_high_outlined,
                  variant: AppButtonVariant.secondary,
                  isLoading: isBackfilling,
                  onPressed: isBackfilling
                      ? null
                      : () async {
                          final success = await cubit.backfill(
                                companyId: companyId,
                                module: issue.module,
                                recordId: issue.recordId,
                              );
                          if (context.mounted && success) {
                            AppFeedback.success(context, l.dataHealthRepairSuccess);
                          }
                        },
                ),
              if (needsReassign)
                AppButton(
                  label: l.reassignRecord,
                  icon: Icons.person_add_alt_1_outlined,
                  isLoading: isReassigning,
                  onPressed: isReassigning || currentUser == null
                      ? null
                      : () => _showReassignDialog(context, issue, currentUser!),
                ),
              Tooltip(
                message: canNotifyManager
                    ? l.notifyManager
                    : l.noManagerForDataHealthIssue,
                child: AppButton(
                  label: l.notifyManager,
                  icon: Icons.notifications_active_outlined,
                  variant: AppButtonVariant.secondary,
                  isLoading: isNotifying,
                  onPressed: !canNotifyManager || isNotifying
                      ? null
                      : () async {
                          final success = await cubit.notifyManager(
                            companyId: companyId,
                            module: issue.module,
                            recordId: issue.recordId,
                            issueType: issue.issueType,
                          );
                          if (context.mounted && success) {
                            AppFeedback.success(
                              context,
                              l.managerNotificationSent,
                            );
                          }
                        },
                ),
              ),
            ],
          );
          if (narrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [content, const SizedBox(height: AppSpacing.xs), Align(alignment: AlignmentDirectional.centerEnd, child: actions)],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [Expanded(child: content), const SizedBox(width: AppSpacing.md), actions],
          );
        },
      ),
    );
  }

  Future<void> _showReassignDialog(BuildContext context, DataHealthIssue issue, UserProfile currentUser) async {
    final l = AppLocalizations.of(context)!;
    await cubit.loadEligibleAssignees(
          companyId: companyId,
          module: issue.module,
          currentRole: currentUser.role,
          currentUid: currentUser.uid,
          currentTeamId: currentUser.teamId,
        );
    if (!context.mounted) {
      return;
    }
    String? selectedUid;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return BlocBuilder<DataHealthCubit, DataHealthState>(
              bloc: cubit,
              builder: (context, state) {
                final users = state.eligibleAssignees;
                final reassignActionId = '${issue.module}/${issue.recordId}/reassign';
                final isSaving = state.activeActionId == reassignActionId;
                return AlertDialog(
                  title: Text(
                    l.reassignRecord,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  content: SizedBox(
                    width: 460,
                    child: users.isEmpty
                        ? AppEmptyState(
                            icon: Icons.person_off_outlined,
                            title: l.noEligibleAssignees,
                            message: l.noEligibleAssigneesMessage,
                          )
                        : ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 340),
                            child: ListView.separated(
                              shrinkWrap: true,
                              itemCount: users.length,
                              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.xs),
                              itemBuilder: (context, index) {
                                final user = users[index];
                                final selected = selectedUid == user.uid;
                                return InkWell(
                                  borderRadius: AppRadius.large,
                                  onTap: isSaving ? null : () => setDialogState(() => selectedUid = user.uid),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.md,
                                      vertical: AppSpacing.sm,
                                    ),
                                    decoration: BoxDecoration(
                                      color: selected
                                          ? AppColors.primaryColor(context).withValues(alpha: 0.10)
                                          : AppColors.inputSurface(context),
                                      border: Border.all(
                                        color: selected
                                            ? AppColors.primaryColor(context).withValues(alpha: 0.45)
                                            : AppColors.borderColor(context),
                                      ),
                                      borderRadius: AppRadius.large,
                                    ),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 16,
                                          backgroundColor: AppColors.primaryColor(context).withValues(alpha: 0.14),
                                          child: Text(
                                            user.fullName.trim().isEmpty
                                                ? '?'
                                                : user.fullName.trim().substring(0, 1).toUpperCase(),
                                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                                  color: AppColors.primaryColor(context),
                                                  fontWeight: FontWeight.w800,
                                                ),
                                          ),
                                        ),
                                        const SizedBox(width: AppSpacing.sm),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                user.fullName,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                user.email,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                      color: AppColors.textSecondaryColor(context),
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (selected) Icon(Icons.check_circle, color: AppColors.primaryColor(context)),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: isSaving ? null : () => Navigator.of(dialogContext).pop(),
                      child: Text(l.cancel),
                    ),
                    AppButton(
                      label: l.reassignRecord,
                      icon: Icons.person_add_alt_1_outlined,
                      isLoading: isSaving,
                      onPressed: selectedUid == null || isSaving
                          ? null
                          : () async {
                              final uid = selectedUid;
                              if (uid == null || uid.isEmpty) {
                                return;
                              }
                              final success = await cubit.reassign(
                                    companyId: companyId,
                                    module: issue.module,
                                    recordId: issue.recordId,
                                    newAssigneeUid: uid,
                                  );
                              if (dialogContext.mounted) {
                                Navigator.of(dialogContext).pop();
                              }
                              if (context.mounted && success) {
                                AppFeedback.success(context, l.dataHealthReassignSuccess);
                              }
                            },
                    ),
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
String _moduleLabel(AppLocalizations l, String module) {
  switch (module) {
    case 'leads':
      return l.leads;
    case 'clients':
      return l.clients;
    case 'tasks':
      return l.tasks;
    case 'deals':
      return l.deals;
    case 'properties':
      return l.properties;
    default:
      return module;
  }
}

String _issueLabel(AppLocalizations l, String issueType) {
  switch (issueType) {
    case 'missingAssignee':
      return l.missingAssignee;
    case 'missingSnapshots':
      return l.missingSnapshots;
    case 'inactiveAssignee':
      return l.inactiveAssignees;
    case 'ineligibleAssignee':
      return l.invalidAssignees;
    case 'staleSnapshots':
      return l.staleTeamSnapshots;
    default:
      return issueType;
  }
}


String _assigneeLabel(AppLocalizations l, DataHealthIssue issue) {
  if (issue.issueType == 'missingAssignee') {
    return l.missingAssignee;
  }
  final name = issue.assignedToName.trim();
  if (name.isNotEmpty && !_looksLikeUid(name)) {
    return name;
  }
  switch (issue.issueType) {
    case 'inactiveAssignee':
      return l.inactiveAssignees;
    case 'ineligibleAssignee':
      return l.invalidAssignees;
    default:
      return l.notAvailable;
  }
}

bool _looksLikeUid(String value) {
  final clean = value.trim();
  if (clean.contains(' ') || clean.length < 16) {
    return false;
  }
  return RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(clean);
}

String _formatDateTime(BuildContext context, DateTime? value) {
  if (value == null) {
    return AppLocalizations.of(context)!.notAvailable;
  }
  final localeName = Localizations.localeOf(context).toLanguageTag();
  return DateFormat.yMd(localeName).add_jm().format(value.toLocal());
}

String _suggestedAction(AppLocalizations l, DataHealthIssue issue) {
  if (issue.canBackfill) {
    return l.backfillSnapshots;
  }
  return l.companyAdminActionRequired;
}
