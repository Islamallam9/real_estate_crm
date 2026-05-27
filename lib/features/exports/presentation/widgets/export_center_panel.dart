import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/role_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/file_downloader.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_dropdown.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../users/domain/entities/user_profile.dart';
import '../../data/datasources/export_file_data_source.dart';
import '../../data/datasources/export_remote_data_source.dart';
import '../../data/repositories/export_repository_impl.dart';
import '../../domain/entities/export_request.dart';
import '../../domain/usecases/generate_export_usecase.dart';
import '../../domain/usecases/get_export_eligible_assignees_usecase.dart';
import '../cubit/export_cubit.dart';
import '../cubit/export_state.dart';

class ExportCenterPanel extends StatefulWidget {
  const ExportCenterPanel({
    super.key,
    required this.profile,
    required this.companyName,
  });

  final UserProfile profile;
  final String companyName;

  @override
  State<ExportCenterPanel> createState() => _ExportCenterPanelState();
}

class _ExportCenterPanelState extends State<ExportCenterPanel> {
  late final ExportCubit _cubit;
  bool _languageSynced = false;

  @override
  void initState() {
    super.initState();
    final repository = ExportRepositoryImpl(
      remoteDataSource: FirestoreExportRemoteDataSource(),
      fileDataSource: const LocalExportFileDataSource(),
    );
    _cubit = ExportCubit(
      generateExportUseCase: GenerateExportUseCase(repository),
      getEligibleAssigneesUseCase: GetExportEligibleAssigneesUseCase(repository),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final language = Localizations.localeOf(context).languageCode == 'ar'
        ? ExportOutputLanguage.ar
        : ExportOutputLanguage.en;
    if (!_languageSynced) {
      _languageSynced = true;
      _cubit.setOutputLanguage(language);
      _cubit.loadAssignees(_actor);
    }
  }

  @override
  void didUpdateWidget(covariant ExportCenterPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.profile.uid != widget.profile.uid ||
        oldWidget.profile.companyId != widget.profile.companyId ||
        oldWidget.profile.role != widget.profile.role) {
      _cubit.loadAssignees(_actor);
    }
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  ExportActor get _actor {
    return ExportActor(
      companyId: widget.profile.companyId,
      companyName: widget.companyName.trim().isEmpty
          ? widget.profile.companyId
          : widget.companyName,
      uid: widget.profile.uid,
      name: widget.profile.fullName.trim().isEmpty
          ? widget.profile.email
          : widget.profile.fullName,
      email: widget.profile.email,
      role: widget.profile.role,
      teamId: widget.profile.teamId,
      teamName: widget.profile.teamName,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: BlocConsumer<ExportCubit, ExportState>(
        listenWhen: (previous, current) =>
            current.status == ExportStatus.success &&
            current.result != null &&
            previous.result?.fileName != current.result?.fileName,
        listener: (context, state) => _downloadResult(context, state),
        builder: (context, state) {
          final l = AppLocalizations.of(context)!;
          final request = _request(l, state);
          final canExport = _canExport(widget.profile.role, state.module);

          return Container(
            padding: EdgeInsets.all(
              MediaQuery.sizeOf(context).width < 600
                  ? AppSpacing.sm
                  : AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: AppColors.cardSurface(context),
              borderRadius: AppRadius.xLarge,
              border: Border.all(color: AppColors.borderColor(context)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ExportHeader(state: state),
                const SizedBox(height: AppSpacing.sm),
                _ModuleSelector(
                  selected: state.module,
                  role: widget.profile.role,
                  onSelected: context.read<ExportCubit>().setModule,
                ),
                const SizedBox(height: AppSpacing.sm),
                _FiltersPanel(
                  state: state,
                  role: widget.profile.role,
                  onDateRangeChanged: context.read<ExportCubit>().setDateRange,
                  onAssigneeChanged: context.read<ExportCubit>().setAssignee,
                  onStatusChanged: context.read<ExportCubit>().setStatus,
                  onLanguageChanged:
                      context.read<ExportCubit>().setOutputLanguage,
                  onIncludeArchivedChanged:
                      context.read<ExportCubit>().setIncludeArchived,
                ),
                const SizedBox(height: AppSpacing.sm),
                _ColumnsPanel(
                  state: state,
                  availableColumns: _availableColumns(l, state.module),
                  onAdvancedChanged:
                      context.read<ExportCubit>().toggleAdvancedColumns,
                  onColumnChanged: context.read<ExportCubit>().toggleColumn,
                ),
                const SizedBox(height: AppSpacing.sm),
                _ExportActionBar(
                  canExport: canExport,
                  isGenerating: state.status == ExportStatus.generating,
                  onGenerate: () => context.read<ExportCubit>().generate(request),
                ),
                if (state.message != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  _InlineNotice(
                    icon: Icons.error_outline,
                    text: _cleanError(state.message!),
                    color: AppColors.errorColor(context),
                  ),
                ],
                if (state.result != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  _ExportResultCard(
                    state: state,
                    onDownload: () => _downloadResult(context, state),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  ExportRequest _request(AppLocalizations l, ExportState state) {
    return ExportRequest(
      module: state.module,
      actor: _actor,
      filters: state.filters,
      labels: {
        ..._exportLabels(l),
        'selectedAssignee': _selectedAssigneeLabel(l, state),
      },
      columns: state.advancedColumns ? state.selectedColumns : const <String>[],
    );
  }

  String _selectedAssigneeLabel(AppLocalizations l, ExportState state) {
    final selectedId = state.filters.assigneeId.trim();
    if (selectedId.isEmpty) {
      return l.allAgents;
    }
    for (final assignee in state.assignees) {
      if (assignee.uid == selectedId) {
        return assignee.displayName;
      }
    }
    return l.selectedAssignee;
  }

  Future<void> _downloadResult(BuildContext context, ExportState state) async {
    final l = AppLocalizations.of(context)!;
    final result = state.result;
    if (result == null) {
      return;
    }
    final ok = await downloadBytes(
      fileName: result.fileName,
      mimeType: result.mimeType,
      bytes: result.bytes,
    );
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? l.exportGeneratedSuccessfully : l.exportDownloadFailed,
        ),
      ),
    );
  }
}

class _ExportHeader extends StatelessWidget {
  const _ExportHeader({required this.state});

  final ExportState state;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final compact = MediaQuery.sizeOf(context).width < 600;

    if (compact) {
      return Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.primaryColor(context).withValues(alpha: 0.12),
              borderRadius: AppRadius.medium,
            ),
            child: Icon(
              Icons.file_download_outlined,
              size: 19,
              color: AppColors.primaryColor(context),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.exportCenter,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                Text(
                  l.exportsFollowRolePermissions,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.successColor(context),
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primaryColor(context).withValues(alpha: 0.12),
            borderRadius: AppRadius.medium,
          ),
          child: Icon(
            Icons.file_download_outlined,
            color: AppColors.primaryColor(context),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l.exportCenter,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                l.exportCenterSubtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondaryColor(context),
                    ),
              ),
              const SizedBox(height: AppSpacing.xs),
              _InlineNotice(
                icon: Icons.verified_user_outlined,
                text: l.exportsFollowRolePermissions,
                color: AppColors.successColor(context),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ModuleSelector extends StatelessWidget {
  const _ModuleSelector({
    required this.selected,
    required this.role,
    required this.onSelected,
  });

  final ExportModule selected;
  final UserRole role;
  final ValueChanged<ExportModule> onSelected;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final columns = availableWidth >= 900
            ? 4
            : availableWidth >= 560
                ? 3
                : 2;

        return _ExportSection(
          title: l.exportReportType,
          icon: Icons.article_outlined,
          children: [
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: ExportModule.values.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: AppSpacing.xs,
                mainAxisSpacing: AppSpacing.xs,
                childAspectRatio: availableWidth < 380 ? 3.7 : 4.4,
              ),
              itemBuilder: (context, index) {
                final module = ExportModule.values[index];
                return _ModuleCard(
                  module: module,
                  label: _moduleLabel(l, module),
                  icon: _moduleIcon(module),
                  selected: selected == module,
                  enabled: _canExport(role, module),
                  onTap: () => onSelected(module),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({
    required this.module,
    required this.label,
    required this.icon,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final ExportModule module;
  final String label;
  final IconData icon;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final color = selected
        ? AppColors.primaryColor(context)
        : AppColors.textSecondaryColor(context);
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: AppRadius.large,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: 8,
          vertical: 7,
        ),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primaryColor(context).withValues(alpha: 0.09)
              : AppColors.inputSurface(context),
          borderRadius: AppRadius.large,
          border: Border.all(
            color: selected
                ? AppColors.primaryColor(context).withValues(alpha: 0.45)
                : AppColors.borderColor(context),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 15,
              color: enabled ? color : Theme.of(context).disabledColor,
            ),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      height: 1.05,
                      color: enabled ? null : Theme.of(context).disabledColor,
                    ),
              ),
            ),
            if (!enabled)
              Tooltip(
                message: l.exportNotAvailableForRole,
                child: Icon(
                  Icons.lock_outline,
                  size: 15,
                  color: Theme.of(context).disabledColor,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ExportSection extends StatelessWidget {
  const _ExportSection({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(
        MediaQuery.sizeOf(context).width < 600 ? AppSpacing.xs : AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.inputSurface(context),
        borderRadius: AppRadius.large,
        border: Border.all(color: AppColors.borderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primaryColor(context)),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          ...children,
        ],
      ),
    );
  }
}

class _FiltersPanel extends StatelessWidget {
  const _FiltersPanel({
    required this.state,
    required this.role,
    required this.onDateRangeChanged,
    required this.onAssigneeChanged,
    required this.onStatusChanged,
    required this.onLanguageChanged,
    required this.onIncludeArchivedChanged,
  });

  final ExportState state;
  final UserRole role;
  final ValueChanged<ExportDateRangePreset> onDateRangeChanged;
  final ValueChanged<String> onAssigneeChanged;
  final ValueChanged<String> onStatusChanged;
  final ValueChanged<ExportOutputLanguage> onLanguageChanged;
  final ValueChanged<bool> onIncludeArchivedChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final statusOptions = _statusOptions(l, state.module);
    final canFilterAssignee = role == UserRole.admin || role == UserRole.manager;
    final canIncludeArchived = role == UserRole.admin || role == UserRole.manager;

    return _ExportSection(
      title: l.filters,
      icon: Icons.tune_rounded,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 720;
            final twoColumnCompact = compact && constraints.maxWidth >= 300;
            final fieldWidth = compact
                ? twoColumnCompact
                    ? (constraints.maxWidth - AppSpacing.xs) / 2
                    : constraints.maxWidth
                : 210.0;
            final agentWidth = compact ? constraints.maxWidth : 230.0;
            final languageWidth = compact
                ? twoColumnCompact
                    ? (constraints.maxWidth - AppSpacing.xs) / 2
                    : constraints.maxWidth
                : 170.0;

            return Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: fieldWidth,
                  child: AppDropdown<ExportDateRangePreset>(
                    label: l.dateRange,
                    value: state.filters.dateRange,
                    items: ExportDateRangePreset.values
                        .where((value) => value != ExportDateRangePreset.custom)
                        .toList(),
                    itemLabelBuilder: (value) => _dateRangeLabel(l, value),
                    onChanged: onDateRangeChanged,
                  ),
                ),
                if (statusOptions.length > 1)
                  SizedBox(
                    width: fieldWidth,
                    child: AppDropdown<_StatusOption>(
                      label: l.exportStatusFilter,
                      value: _StatusOption.fromValue(
                        state.filters.status,
                        statusOptions,
                      ),
                      items: statusOptions,
                      itemLabelBuilder: (value) => value.label,
                      onChanged: (value) => onStatusChanged(value.value),
                    ),
                  ),
                if (canFilterAssignee)
                  SizedBox(
                    width: agentWidth,
                    child: AppDropdown<_AssigneeFilterOption>(
                      label: l.assignedAgent,
                      value: _AssigneeFilterOption.fromValue(
                        state.filters.assigneeId,
                        state.assignees,
                        l.allAgents,
                      ),
                      items: [
                        _AssigneeFilterOption('', l.allAgents),
                        for (final assignee in state.assignees)
                          _AssigneeFilterOption(
                            assignee.uid,
                            assignee.displayName,
                          ),
                      ],
                      itemLabelBuilder: (value) => value.label,
                      onChanged: (value) => onAssigneeChanged(value.uid),
                    ),
                  ),
                SizedBox(
                  width: languageWidth,
                  child: AppDropdown<ExportOutputLanguage>(
                    label: l.exportLanguage,
                    value: state.filters.outputLanguage,
                    items: ExportOutputLanguage.values,
                    itemLabelBuilder: (value) => value == ExportOutputLanguage.ar
                        ? l.arabic
                        : l.english,
                    onChanged: onLanguageChanged,
                  ),
                ),
                if (canIncludeArchived)
                  SizedBox(
                    width: compact
                        ? twoColumnCompact
                            ? (constraints.maxWidth - AppSpacing.xs) / 2
                            : constraints.maxWidth
                        : 230,
                    child: _ExportToggleButton(
                      label: l.includeArchivedRecords,
                      icon: Icons.archive_outlined,
                      selected: state.filters.includeArchived,
                      onChanged: onIncludeArchivedChanged,
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _ExportToggleButton extends StatelessWidget {
  const _ExportToggleButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onChanged,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? AppColors.primaryColor(context)
        : AppColors.textSecondaryColor(context);

    return InkWell(
      borderRadius: AppRadius.large,
      onTap: () => onChanged(!selected),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primaryColor(context).withValues(alpha: 0.10)
              : AppColors.cardSurface(context),
          borderRadius: AppRadius.large,
          border: Border.all(
            color: selected
                ? AppColors.primaryColor(context).withValues(alpha: 0.42)
                : AppColors.borderColor(context),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Icon(
              selected ? Icons.check_circle_rounded : Icons.circle_outlined,
              size: 18,
              color: color,
            ),
          ],
        ),
      ),
    );
  }
}

class _ColumnsPanel extends StatelessWidget {
  const _ColumnsPanel({
    required this.state,
    required this.availableColumns,
    required this.onAdvancedChanged,
    required this.onColumnChanged,
  });

  final ExportState state;
  final List<_ColumnOption> availableColumns;
  final ValueChanged<bool> onAdvancedChanged;
  final void Function(String columnId, bool selected) onColumnChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return _ExportSection(
      title: l.exportColumns,
      icon: Icons.view_column_outlined,
      children: [
        InkWell(
          borderRadius: AppRadius.large,
          onTap: () => onAdvancedChanged(!state.advancedColumns),
          child: Container(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.sm,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: AppColors.cardSurface(context),
              borderRadius: AppRadius.large,
              border: Border.all(color: AppColors.borderColor(context)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        state.advancedColumns
                            ? l.advancedColumns
                            : l.recommendedColumns,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l.exportColumns,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondaryColor(context),
                            ),
                      ),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: state.advancedColumns,
                  onChanged: onAdvancedChanged,
                ),
              ],
            ),
          ),
        ),
        if (state.advancedColumns) ...[
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (final column in availableColumns)
                FilterChip(
                  selected: state.selectedColumns.isEmpty
                      ? column.recommended
                      : state.selectedColumns.contains(column.id),
                  label: Text(column.label),
                  onSelected: (selected) => onColumnChanged(column.id, selected),
                ),
            ],
          ),
        ],
      ],
    );
  }
}


class _ExportActionBar extends StatelessWidget {
  const _ExportActionBar({
    required this.canExport,
    required this.isGenerating,
    required this.onGenerate,
  });

  final bool canExport;
  final bool isGenerating;
  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: AppColors.primaryColor(context).withValues(alpha: 0.07),
        borderRadius: AppRadius.large,
        border: Border.all(
          color: AppColors.primaryColor(context).withValues(alpha: 0.18),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 560;
          final info = Row(
            children: [
              Icon(
                Icons.download_done_outlined,
                size: 20,
                color: AppColors.primaryColor(context),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  l.exportGenerateSection,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
            ],
          );

          final button = AppButton(
            label: l.generateExport,
            icon: Icons.file_download_outlined,
            isLoading: isGenerating,
            isExpanded: compact,
            onPressed: canExport && !isGenerating ? onGenerate : null,
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                info,
                const SizedBox(height: AppSpacing.sm),
                button,
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: info),
              const SizedBox(width: AppSpacing.sm),
              button,
            ],
          );
        },
      ),
    );
  }
}

class _ExportResultCard extends StatelessWidget {
  const _ExportResultCard({
    required this.state,
    required this.onDownload,
  });

  final ExportState state;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final result = state.result;
    if (result == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.successColor(context).withValues(alpha: 0.08),
        borderRadius: AppRadius.large,
        border: Border.all(
          color: AppColors.successColor(context).withValues(alpha: 0.22),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 560;
          final details = '${result.fileName} · ${result.recordCount} ${l.records}';

          final body = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.check_circle_outline,
                color: AppColors.successColor(context),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.exportReady,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      details,
                      maxLines: compact ? 3 : 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondaryColor(context),
                          ),
                    ),
                  ],
                ),
              ),
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                body,
                const SizedBox(height: AppSpacing.sm),
                AppButton(
                  label: l.downloadFile,
                  icon: Icons.download_rounded,
                  variant: AppButtonVariant.secondary,
                  onPressed: onDownload,
                ),
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: body),
              const SizedBox(width: AppSpacing.sm),
              AppButton(
                label: l.downloadFile,
                icon: Icons.download_rounded,
                variant: AppButtonVariant.secondary,
                onPressed: onDownload,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _InlineNotice extends StatelessWidget {
  const _InlineNotice({
    required this.icon,
    required this.text,
    required this.color,
  });

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: AppRadius.medium,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusOption {
  const _StatusOption(this.value, this.label);

  factory _StatusOption.fromValue(String value, List<_StatusOption> options) {
    return options.firstWhere(
      (option) => option.value == value,
      orElse: () => options.first,
    );
  }

  final String value;
  final String label;
}

class _AssigneeFilterOption {
  const _AssigneeFilterOption(this.uid, this.label);

  factory _AssigneeFilterOption.fromValue(
    String value,
    List<dynamic> assignees,
    String allLabel,
  ) {
    if (value.trim().isEmpty) {
      return _AssigneeFilterOption('', allLabel);
    }
    for (final assignee in assignees) {
      if (assignee.uid == value) {
        return _AssigneeFilterOption(value, assignee.displayName);
      }
    }
    return _AssigneeFilterOption('', allLabel);
  }

  final String uid;
  final String label;
}

class _ColumnOption {
  const _ColumnOption(this.id, this.label, {this.recommended = true});

  final String id;
  final String label;
  final bool recommended;
}

bool _canExport(UserRole role, ExportModule module) {
  if (role == UserRole.viewer) {
    return false;
  }
  if (module == ExportModule.properties && role != UserRole.admin) {
    return false;
  }
  if (module == ExportModule.teamPerformance &&
      role != UserRole.admin &&
      role != UserRole.manager) {
    return false;
  }
  if (module == ExportModule.auditSummary &&
      role != UserRole.admin &&
      role != UserRole.manager) {
    return false;
  }
  return true;
}

IconData _moduleIcon(ExportModule module) {
  return switch (module) {
    ExportModule.leads => Icons.groups_outlined,
    ExportModule.clients => Icons.person_outline_rounded,
    ExportModule.deals => Icons.handshake_outlined,
    ExportModule.tasks => Icons.task_alt_outlined,
    ExportModule.appointments => Icons.event_available_outlined,
    ExportModule.properties => Icons.apartment_outlined,
    ExportModule.teamPerformance => Icons.insights_outlined,
    ExportModule.pipeline => Icons.stacked_line_chart_outlined,
    ExportModule.followUps => Icons.schedule_outlined,
    ExportModule.auditSummary => Icons.history_outlined,
  };
}

String _moduleLabel(AppLocalizations l, ExportModule module) {
  return switch (module) {
    ExportModule.leads => l.leads,
    ExportModule.clients => l.clients,
    ExportModule.deals => l.deals,
    ExportModule.tasks => l.tasks,
    ExportModule.appointments => l.appointments,
    ExportModule.properties => l.properties,
    ExportModule.teamPerformance => l.teamPerformanceExport,
    ExportModule.pipeline => l.pipelineReportExport,
    ExportModule.followUps => l.followUpReportExport,
    ExportModule.auditSummary => l.auditSummaryExport,
  };
}

String _dateRangeLabel(AppLocalizations l, ExportDateRangePreset preset) {
  return switch (preset) {
    ExportDateRangePreset.allTime => l.allTime,
    ExportDateRangePreset.today => l.today,
    ExportDateRangePreset.thisWeek => l.thisWeek,
    ExportDateRangePreset.thisMonth => l.thisMonth,
    ExportDateRangePreset.lastMonth => l.lastMonth,
    ExportDateRangePreset.custom => l.customRange,
  };
}

List<_StatusOption> _statusOptions(AppLocalizations l, ExportModule module) {
  return switch (module) {
    ExportModule.leads => [
        _StatusOption('', l.allStatuses),
        _StatusOption('new', l.newLead),
        _StatusOption('contacted', l.contacted),
        _StatusOption('interested', l.interested),
        _StatusOption('visitScheduled', l.visitScheduled),
        _StatusOption('negotiation', l.negotiation),
        _StatusOption('won', l.won),
        _StatusOption('lost', l.lost),
      ],
    ExportModule.deals || ExportModule.pipeline => [
        _StatusOption('', l.allStatuses),
        _StatusOption('new', l.newDealStage),
        _StatusOption('qualified', l.qualified),
        _StatusOption('proposal', l.proposal),
        _StatusOption('negotiation', l.negotiation),
        _StatusOption('won', l.won),
        _StatusOption('lost', l.lost),
      ],
    ExportModule.tasks => [
        _StatusOption('', l.allStatuses),
        _StatusOption('pending', l.pending),
        _StatusOption('inProgress', l.inProgress),
        _StatusOption('completed', l.completed),
        _StatusOption('cancelled', l.cancelled),
      ],
    ExportModule.appointments => [
        _StatusOption('', l.allStatuses),
        _StatusOption('scheduled', l.appointmentStatusScheduled),
        _StatusOption('completed', l.appointmentStatusCompleted),
        _StatusOption('cancelled', l.appointmentStatusCancelled),
        _StatusOption('missed', l.appointmentStatusMissed),
        _StatusOption('rescheduled', l.appointmentStatusRescheduled),
      ],
    ExportModule.properties => [
        _StatusOption('', l.allStatuses),
        _StatusOption('available', l.available),
        _StatusOption('reserved', l.reserved),
        _StatusOption('sold', l.sold),
        _StatusOption('rented', l.rented),
        _StatusOption('inactive', l.inactive),
      ],
    ExportModule.clients ||
    ExportModule.teamPerformance ||
    ExportModule.followUps ||
    ExportModule.auditSummary => [
        _StatusOption('', l.allStatuses),
      ],
  };
}

List<_ColumnOption> _availableColumns(AppLocalizations l, ExportModule module) {
  final labels = _exportLabels(l);
  List<_ColumnOption> build(List<String> ids) {
    return [
      for (final id in ids)
        _ColumnOption(id, labels['column.$id'] ?? id),
    ];
  }

  return switch (module) {
    ExportModule.leads => build([
        'leadName',
        'phone',
        'email',
        'status',
        'priority',
        'source',
        'sourceDetails',
        'assignedTo',
        'team',
        'manager',
        'budget',
        'preferredLocation',
        'preferredPropertyType',
        'lastContactAt',
        'nextFollowUpAt',
        'createdAt',
        'updatedAt',
        'archived',
      ]),
    ExportModule.clients => build([
        'clientName',
        'phone',
        'email',
        'assignedTo',
        'team',
        'manager',
        'budget',
        'preferredLocation',
        'preferredPropertyType',
        'createdAt',
        'updatedAt',
        'archived',
      ]),
    ExportModule.deals => build([
        'dealTitle',
        'client',
        'property',
        'stage',
        'value',
        'commission',
        'expectedCloseDate',
        'assignedTo',
        'team',
        'manager',
        'createdAt',
        'updatedAt',
        'lostReason',
        'archived',
      ]),
    ExportModule.tasks => build([
        'title',
        'status',
        'priority',
        'dueDate',
        'assignedTo',
        'team',
        'manager',
        'relatedType',
        'relatedTitle',
        'createdAt',
        'updatedAt',
      ]),
    ExportModule.appointments => build([
        'title',
        'scheduledAt',
        'status',
        'appointmentType',
        'assignedTo',
        'team',
        'manager',
        'relatedType',
        'relatedTitle',
        'location',
        'createdAt',
        'updatedAt',
      ]),
    ExportModule.properties => build([
        'propertyTitle',
        'propertyType',
        'listingType',
        'status',
        'price',
        'location',
        'bedrooms',
        'bathrooms',
        'area',
        'assignedTo',
        'createdAt',
        'updatedAt',
        'imageCount',
        'archived',
      ]),
    ExportModule.pipeline => build([
        'stage',
        'dealCount',
        'totalValue',
        'averageDealValue',
      ]),
    ExportModule.followUps => build([
        'type',
        'title',
        'status',
        'dueDate',
        'assignedTo',
        'team',
        'relatedTitle',
      ]),
    ExportModule.teamPerformance => build([
        'team',
        'manager',
        'assignedTo',
        'leadsAssigned',
        'newLeads',
        'convertedLeads',
        'openDeals',
        'wonDeals',
        'pipelineValue',
        'tasksDue',
        'tasksOverdue',
        'tasksCompleted',
        'appointmentsUpcoming',
        'appointmentsCompleted',
      ]),
    ExportModule.auditSummary => build([
        'createdAt',
        'module',
        'action',
        'recordTitle',
        'actor',
        'assignedTo',
        'team',
      ]),
  };
}

Map<String, String> _exportLabels(AppLocalizations l) {
  return {
    'product': l.product,
    'company': l.company,
    'reportName': l.reportName,
    'scope': l.scope,
    'dateRange': l.dateRange,
    'generatedBy': l.generatedBy,
    'generatedAt': l.generatedAt,
    'recordCount': l.recordCount,
    'filtersSummary': l.filtersSummary,
    'field': l.field,
    'value': l.value,
    'reportSummary': l.reportSummary,
    'dataSheet': l.dataSheet,
    'yes': l.yes,
    'no': l.no,
    'status': l.status,
    'assignedTo': l.assignedTo,
    'selectedAssignee': l.selectedAssignee,
    'includeArchived': l.includeArchivedRecords,
    'permissionDenied': l.permissionDenied,
    'scope.companyWide': l.companyWideExportScope,
    'scope.myTeam': l.myTeamExportScope,
    'scope.myRecords': l.myRecordsExportScope,
    'scope.restricted': l.restrictedExportScope,
    'dateRange.allTime': l.allTime,
    'dateRange.today': l.today,
    'dateRange.thisWeek': l.thisWeek,
    'dateRange.thisMonth': l.thisMonth,
    'dateRange.lastMonth': l.lastMonth,
    'dateRange.custom': l.customRange,
    'module.leads': l.leads,
    'module.clients': l.clients,
    'module.deals': l.deals,
    'module.tasks': l.tasks,
    'module.appointments': l.appointments,
    'module.properties': l.properties,
    'module.teamPerformance': l.teamPerformanceExport,
    'module.pipeline': l.pipelineReportExport,
    'module.followUps': l.followUpReportExport,
    'module.auditSummary': l.auditSummaryExport,
    'tasks': l.tasks,
    'appointments': l.appointments,
    'leadStatus.newLead': l.newLead,
    'leadStatus.contacted': l.contacted,
    'leadStatus.interested': l.interested,
    'leadStatus.visitScheduled': l.visitScheduled,
    'leadStatus.negotiation': l.negotiation,
    'leadStatus.won': l.won,
    'leadStatus.lost': l.lost,
    'priority.low': l.low,
    'priority.medium': l.medium,
    'priority.high': l.high,
    'leadSource.facebook': l.facebook,
    'leadSource.website': l.website,
    'leadSource.phoneCall': l.phoneCall,
    'leadSource.whatsapp': l.whatsapp,
    'leadSource.referral': l.referral,
    'leadSource.walkIn': l.walkIn,
    'leadSource.other': l.other,
    'dealStage.newDeal': l.newDealStage,
    'dealStage.qualified': l.qualified,
    'dealStage.proposal': l.proposal,
    'dealStage.negotiation': l.negotiation,
    'dealStage.won': l.won,
    'dealStage.lost': l.lost,
    'taskStatus.pending': l.pending,
    'taskStatus.inProgress': l.inProgress,
    'taskStatus.completed': l.completed,
    'taskStatus.cancelled': l.cancelled,
    'taskRelated.lead': l.lead,
    'taskRelated.client': l.client,
    'taskRelated.property': l.property,
    'taskRelated.deal': l.deal,
    'taskRelated.general': l.general,
    'appointmentStatus.scheduled': l.appointmentStatusScheduled,
    'appointmentStatus.completed': l.appointmentStatusCompleted,
    'appointmentStatus.cancelled': l.appointmentStatusCancelled,
    'appointmentStatus.missed': l.appointmentStatusMissed,
    'appointmentStatus.rescheduled': l.appointmentStatusRescheduled,
    'appointmentType.call': l.appointmentTypeCall,
    'appointmentType.meeting': l.appointmentTypeMeeting,
    'appointmentType.propertyViewing': l.appointmentTypePropertyViewing,
    'appointmentType.siteVisit': l.appointmentTypeSiteVisit,
    'appointmentType.contractMeeting': l.appointmentTypeContractMeeting,
    'appointmentType.reservationMeeting': l.appointmentTypeReservationMeeting,
    'appointmentType.followUp': l.appointmentTypeFollowUp,
    'appointmentType.other': l.appointmentTypeOther,
    'appointmentRelated.lead': l.lead,
    'appointmentRelated.client': l.client,
    'appointmentRelated.property': l.property,
    'appointmentRelated.deal': l.deal,
    'appointmentRelated.general': l.general,
    'propertyType.apartment': l.apartment,
    'propertyType.villa': l.villa,
    'propertyType.office': l.office,
    'propertyType.shop': l.shop,
    'propertyType.land': l.land,
    'propertyType.studio': l.studio,
    'propertyType.duplex': l.duplex,
    'propertyType.penthouse': l.penthouse,
    'listingType.sale': l.sale,
    'listingType.rent': l.rent,
    'propertyStatus.available': l.available,
    'propertyStatus.reserved': l.reserved,
    'propertyStatus.sold': l.sold,
    'propertyStatus.rented': l.rented,
    'propertyStatus.inactive': l.inactive,
    'auditAction.create': l.dashboardAuditCreated,
    'auditAction.update': l.dashboardAuditUpdated,
    'auditAction.archive': l.dashboardAuditArchived,
    'auditAction.restore': l.dashboardAuditRestored,
    'auditAction.deactivate': l.dashboardAuditDeactivated,
    'auditAction.assign': l.dashboardAuditAssigned,
    'auditAction.statusChange': l.dashboardAuditStatusChanged,
    'auditAction.stageChange': l.dashboardAuditStageChanged,
    'auditAction.complete': l.dashboardAuditCompleted,
    'auditAction.cancel': l.dashboardAuditCancelled,
    'auditAction.imageAdded': l.dashboardAuditImageAdded,
    'auditAction.imageRemoved': l.dashboardAuditImageRemoved,
    'auditAction.exportGenerated': l.dashboardAuditExportGenerated,
    'auditModule.leads': l.dashboardAuditLead,
    'auditModule.clients': l.dashboardAuditClient,
    'auditModule.properties': l.dashboardAuditProperty,
    'auditModule.tasks': l.dashboardAuditTask,
    'auditModule.deals': l.dashboardAuditDeal,
    'auditModule.reports': l.reports,
    'column.leadName': l.exportColumnLeadName,
    'column.phone': l.phone,
    'column.email': l.email,
    'column.status': l.status,
    'column.priority': l.priority,
    'column.source': l.source,
    'column.sourceDetails': l.sourceDetails,
    'column.assignedTo': l.assignedTo,
    'column.team': l.team,
    'column.manager': l.manager,
    'column.budget': l.budget,
    'column.preferredLocation': l.preferredLocation,
    'column.preferredPropertyType': l.preferredPropertyType,
    'column.lastContactAt': l.lastContact,
    'column.nextFollowUpAt': l.nextFollowUp,
    'column.createdAt': l.createdAt,
    'column.updatedAt': l.updatedAt,
    'column.archived': l.archived,
    'column.clientName': l.exportColumnClientName,
    'column.dealTitle': l.exportColumnDealTitle,
    'column.client': l.client,
    'column.property': l.property,
    'column.stage': l.stage,
    'column.value': l.value,
    'column.commission': l.commission,
    'column.expectedCloseDate': l.expectedCloseDate,
    'column.lostReason': l.lostReason,
    'column.title': l.title,
    'column.dueDate': l.dueDate,
    'column.relatedType': l.relatedType,
    'column.relatedTitle': l.relatedRecord,
    'column.scheduledAt': l.scheduledAt,
    'column.appointmentType': l.appointmentType,
    'column.location': l.location,
    'column.propertyTitle': l.exportColumnPropertyTitle,
    'column.propertyType': l.propertyType,
    'column.listingType': l.listingType,
    'column.price': l.price,
    'column.bedrooms': l.bedrooms,
    'column.bathrooms': l.bathrooms,
    'column.area': l.area,
    'column.imageCount': l.imageCount,
    'column.dealCount': l.dealCount,
    'column.totalValue': l.totalValue,
    'column.averageDealValue': l.averageDealValue,
    'column.type': l.type,
    'column.leadsAssigned': l.leadsAssigned,
    'column.newLeads': l.newLeads,
    'column.convertedLeads': l.convertedLeads,
    'column.openDeals': l.openDeals,
    'column.wonDeals': l.wonDeals,
    'column.pipelineValue': l.pipelineValue,
    'column.tasksDue': l.tasksDue,
    'column.tasksOverdue': l.tasksOverdue,
    'column.tasksCompleted': l.completedTasks,
    'column.appointmentsUpcoming': l.appointmentsUpcoming,
    'column.appointmentsCompleted': l.completedAppointments,
    'column.module': l.module,
    'column.action': l.action,
    'column.recordTitle': l.recordTitle,
    'column.actor': l.actor,
  };
}

String _cleanError(String message) {
  return message.replaceFirst('Bad state: ', '').replaceFirst('Exception: ', '');
}
