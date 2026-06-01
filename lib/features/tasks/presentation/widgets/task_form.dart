import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/error_mapper.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_dropdown.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../users/domain/entities/assignment_user_policy.dart';
import '../../../users/domain/entities/user_profile.dart';
import '../../domain/entities/crm_task.dart';
import '../../domain/entities/task_related_record_option.dart';
import '../cubit/tasks_cubit.dart';
import '../cubit/tasks_state.dart';

class TaskForm extends StatefulWidget {
  const TaskForm({
    super.key,
    required this.companyId,
    required this.actorUid,
    required this.onSubmit,
    this.task,
    this.users = const [],
    this.canEditAssignment = false,
    this.canEditStatus = false,
    this.assignedTo = '',
    this.relatedRecordsAssignedTo,
    this.relatedRecordsManagerId,
    this.relatedRecordsTeamId,
    this.initialRelatedType,
    this.initialRelatedId = '',
    this.initialRelatedTitle = '',
    this.initialRelatedSubtitle = '',
    this.initialTitle = '',
    this.isSaving = false,
    this.submitLabel,
  });

  final String companyId;
  final String actorUid;
  final ValueChanged<CrmTask> onSubmit;
  final CrmTask? task;
  final List<UserProfile> users;
  final bool canEditAssignment;
  final bool canEditStatus;
  final String assignedTo;
  final String? relatedRecordsAssignedTo;
  final String? relatedRecordsManagerId;
  final String? relatedRecordsTeamId;
  final TaskRelatedType? initialRelatedType;
  final String initialRelatedId;
  final String initialRelatedTitle;
  final String initialRelatedSubtitle;
  final String initialTitle;
  final bool isSaving;
  final String? submitLabel;

  @override
  State<TaskForm> createState() => _TaskFormState();
}

class _TaskFormState extends State<TaskForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  TaskRelatedType _relatedType = TaskRelatedType.general;
  TaskStatus _status = TaskStatus.pending;
  TaskPriority _priority = TaskPriority.medium;
  String _assignedTo = '';
  String _assignedToName = '';
  String _assignedToEmail = '';
  String _teamId = '';
  String _teamName = '';
  String _managerId = '';
  String _managerName = '';
  String _relatedId = '';
  String _relatedTitle = '';
  String _relatedSubtitle = '';
  DateTime? _dueDate;

  @override
  void initState() {
    super.initState();
    final task = widget.task;
    _assignedTo = task?.assignedTo ?? widget.assignedTo;
    _syncAssignedSnapshot();
    if (task == null) {
      _titleController.text = widget.initialTitle;
      _relatedType = widget.initialRelatedType ?? TaskRelatedType.general;
      _relatedId = widget.initialRelatedId.trim();
      _relatedTitle = widget.initialRelatedTitle.trim();
      _relatedSubtitle = widget.initialRelatedSubtitle.trim();
      if (_relatedType != TaskRelatedType.general) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) {
            return;
          }
          _loadRelatedOptions(_relatedType);
        });
      }
      return;
    }

    _assignedToName = task.assignedToName;
    _assignedToEmail = task.assignedToEmail;
    _teamId = task.teamId;
    _teamName = task.teamName;
    _managerId = task.managerId;
    _managerName = task.managerName;
    _titleController.text = task.title;
    _descriptionController.text = task.description;
    _relatedId = task.relatedId;
    _relatedTitle = task.relatedTitle;
    _relatedSubtitle = task.relatedSubtitle;
    _relatedType = task.relatedType;
    _status = task.status;
    _priority = task.priority;
    _dueDate = task.dueDate;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _loadRelatedOptions(_relatedType);
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
              _section(context, l.taskInformation, [
                AppTextField(
                  controller: _titleController,
                  label: l.taskTitle,
                  enabled: !widget.isSaving,
                  validator: (value) => _requiredValidator(value, l),
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: _descriptionController,
                  label: l.description,
                  enabled: !widget.isSaving,
                  maxLines: 3,
                ),
                const SizedBox(height: AppSpacing.md),
                AppDropdown<TaskRelatedType>(
                  label: l.relatedType,
                  value: _relatedType,
                  items: const [
                    TaskRelatedType.general,
                    TaskRelatedType.lead,
                    TaskRelatedType.client,
                    TaskRelatedType.property,
                    TaskRelatedType.deal,
                  ],
                  itemLabelBuilder: (type) => _relatedTypeLabel(l, type),
                  enabled: !widget.isSaving,
                  onChanged: _onRelatedTypeChanged,
                ),
                _RelatedRecordPicker(
                  type: _relatedType,
                  value: _relatedId,
                  enabled: !widget.isSaving,
                  onChanged: (record) {
                    setState(() {
                      _relatedId = record?.id ?? '';
                      _relatedTitle = record?.title ?? '';
                      _relatedSubtitle = record?.subtitle ?? '';
                    });
                  },
                ),
                if (widget.canEditAssignment) ...[
                  const SizedBox(height: AppSpacing.md),
                  AppDropdown<_TaskAssigneeOption>(
                    label: l.assignedTo,
                    value: _TaskAssigneeOption.fromValue(_assignedTo),
                    items: _taskAssigneeOptions(widget.users),
                    itemLabelBuilder: (option) => option.isUnassigned
                        ? l.unassigned
                        : _assigneeLabel(l, widget.users, option.value),
                    enabled: !widget.isSaving,
                    onChanged: (option) {
                      setState(() {
                        _assignedTo = option.value ?? '';
                        _syncAssignedSnapshot();
                      });
                    },
                  ),
                ],
              ]),
              const SizedBox(height: AppSpacing.lg),
              _section(context, l.scheduleAndPriority, [
                OutlinedButton.icon(
                  onPressed: widget.isSaving ? null : _pickDueDate,
                  icon: const Icon(Icons.event_outlined),
                  label: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(_dueDateLabel(l)),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                AppDropdown<TaskPriority>(
                  label: l.priority,
                  value: _priority,
                  items: TaskPriority.values,
                  itemLabelBuilder: (priority) => _priorityLabel(l, priority),
                  enabled: !widget.isSaving,
                  onChanged: (value) => setState(() => _priority = value),
                ),
                if (widget.canEditStatus) ...[
                  const SizedBox(height: AppSpacing.md),
                  AppDropdown<TaskStatus>(
                    label: l.status,
                    value: _status,
                    items: TaskStatus.values,
                    itemLabelBuilder: (status) => _statusLabel(l, status),
                    enabled: !widget.isSaving,
                    onChanged: (value) => setState(() => _status = value),
                  ),
                ],
              ]),
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                label: widget.submitLabel ?? l.createTask,
                isLoading: widget.isSaving,
                onPressed: widget.isSaving ? null : _submit,
              ),
        ],
      ),
    );
  }

  Widget _section(BuildContext context, String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.inputSurface(context),
        border: Border.all(color: AppColors.borderColor(context)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.lg),
          ...children,
        ],
      ),
    );
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (picked == null || !mounted) {
      return;
    }
    setState(() => _dueDate = picked);
  }

  String _dueDateLabel(AppLocalizations l) {
    final dueDate = _dueDate;
    if (dueDate == null) {
      return l.selectDueDate;
    }
    return MaterialLocalizations.of(context).formatMediumDate(dueDate);
  }

  String? _requiredValidator(String? value, AppLocalizations l) {
    if (value == null || value.trim().isEmpty) {
      return l.requiredField;
    }
    return null;
  }

  void _submit() {
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) {
      return;
    }
    if (_dueDate == null) {
      AppFeedback.warning(context, AppLocalizations.of(context)!.dueDateRequired);
      return;
    }
    if (_relatedType != TaskRelatedType.general && _relatedId.trim().isEmpty) {
      AppFeedback.warning(
        context,
        AppLocalizations.of(context)!.relatedRecordRequired,
      );
      return;
    }

    final now = DateTime.now();
    final previous = widget.task;
    final selectedRelatedRecord = _selectedRelatedRecordFromState();
    final relatedTitle = selectedRelatedRecord?.title ?? _relatedTitle;
    final relatedSubtitle = selectedRelatedRecord?.subtitle ?? _relatedSubtitle;
    final selectedAssignee = _selectedAssignee();
    final assignedToName = selectedAssignee?.fullName ?? _assignedToName;
    final assignedToEmail = selectedAssignee?.email ?? _assignedToEmail;
    final teamId = selectedAssignee?.teamId ?? _teamId;
    final teamName = selectedAssignee?.teamName ?? _teamName;
    final managerId = selectedAssignee?.managerId ?? _managerId;
    final managerName = selectedAssignee?.managerName ?? _managerName;
    final assignedTo = widget.canEditAssignment
        ? _assignedTo
        : previous?.assignedTo ?? widget.assignedTo;
    widget.onSubmit(
      CrmTask(
        id: previous?.id ?? '',
        companyId: widget.companyId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        assignedTo: assignedTo,
        assignedToName: assignedTo.trim().isEmpty ? '' : assignedToName.trim(),
        assignedToEmail: assignedTo.trim().isEmpty ? '' : assignedToEmail.trim(),
        teamId: assignedTo.trim().isEmpty ? '' : teamId.trim(),
        teamName: assignedTo.trim().isEmpty ? '' : teamName.trim(),
        managerId: assignedTo.trim().isEmpty ? '' : managerId.trim(),
        managerName: assignedTo.trim().isEmpty ? '' : managerName.trim(),
        relatedType: _relatedType,
        relatedId: _relatedType == TaskRelatedType.general
            ? ''
            : _relatedId.trim(),
        relatedTitle: _relatedType == TaskRelatedType.general
            ? ''
            : relatedTitle.trim(),
        relatedSubtitle: _relatedType == TaskRelatedType.general
            ? ''
            : relatedSubtitle.trim(),
        dueDate: _dueDate,
        status: widget.canEditStatus
            ? _status
            : previous?.status ?? TaskStatus.pending,
        priority: _priority,
        createdAt: previous?.createdAt ?? now,
        updatedAt: now,
        createdBy: previous?.createdBy ?? widget.actorUid,
        updatedBy: widget.actorUid,
        isActive: previous?.isActive ?? true,
      ),
    );
  }

  TaskRelatedRecordOption? _selectedRelatedRecordFromState() {
    if (_relatedId.trim().isEmpty) {
      return null;
    }
    final state = context.read<TasksCubit>().state;
    if (state.relatedRecordsType != _relatedType) {
      return null;
    }
    for (final option in state.relatedRecordOptions) {
      if (option.id == _relatedId.trim()) {
        return option;
      }
    }
    return null;
  }

  UserProfile? _selectedAssignee() {
    final uid = _assignedTo.trim();
    if (uid.isEmpty) {
      return null;
    }
    for (final user in widget.users) {
      if (user.uid == uid) {
        return user;
      }
    }
    return null;
  }

  void _syncAssignedSnapshot() {
    final user = _selectedAssignee();
    if (user == null) {
      if (_assignedTo.trim().isEmpty) {
        _assignedToName = '';
        _assignedToEmail = '';
        _teamId = '';
        _teamName = '';
        _managerId = '';
        _managerName = '';
      }
      return;
    }
    _assignedToName = user.fullName;
    _assignedToEmail = user.email;
    _teamId = user.teamId;
    _teamName = user.teamName;
    _managerId = user.managerId;
    _managerName = user.managerName;
  }

  void _onRelatedTypeChanged(TaskRelatedType value) {
    setState(() {
      _relatedType = value;
      _relatedId = '';
      _relatedTitle = '';
      _relatedSubtitle = '';
    });
    _loadRelatedOptions(value);
  }

  void _loadRelatedOptions(TaskRelatedType type) {
    final cubit = context.read<TasksCubit>();
    if (type == TaskRelatedType.general) {
      cubit.clearRelatedRecordOptions();
      return;
    }
    cubit.loadRelatedRecordOptions(
      companyId: widget.companyId,
      type: type,
      assignedTo: widget.relatedRecordsAssignedTo,
      managerId: widget.relatedRecordsManagerId,
      teamId: widget.relatedRecordsTeamId,
    );
  }
}

class _RelatedRecordPicker extends StatelessWidget {
  const _RelatedRecordPicker({
    required this.type,
    required this.value,
    required this.onChanged,
    required this.enabled,
  });

  final TaskRelatedType type;
  final String value;
  final ValueChanged<TaskRelatedRecordOption?> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (type == TaskRelatedType.general) {
      return const SizedBox.shrink();
    }

    final l = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: BlocBuilder<TasksCubit, TasksState>(
        buildWhen: (previous, current) =>
            previous.relatedRecordsStatus != current.relatedRecordsStatus ||
            previous.relatedRecordOptions != current.relatedRecordOptions ||
            previous.relatedRecordsType != current.relatedRecordsType ||
            previous.relatedRecordsMessage != current.relatedRecordsMessage,
        builder: (context, state) {
          if (state.relatedRecordsType != type &&
              state.relatedRecordsStatus != TaskRelatedRecordsStatus.initial) {
            return _RelatedRecordLoading(label: l.relatedRecord);
          }

          if (state.relatedRecordsStatus == TaskRelatedRecordsStatus.loading) {
            return _RelatedRecordLoading(label: l.relatedRecord);
          }

          if (state.relatedRecordsStatus == TaskRelatedRecordsStatus.failure) {
            return Text(
              localizeErrorMessage(l, state.relatedRecordsMessage),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.error,
              ),
            );
          }

          if (state.relatedRecordsStatus == TaskRelatedRecordsStatus.empty) {
            if (value.trim().isNotEmpty) {
              final options = _relatedRecordOptions(
                const [],
                selectedId: value,
                selectedType: type,
              );
              final selectedOption = _relatedRecordSelectionFor(
                value,
                options,
              );
              return AppDropdown<_RelatedRecordSelection>(
                key: ValueKey('${type.name}-${selectedOption.record?.id ?? ''}'),
                label: l.relatedRecord,
                value: selectedOption,
                items: options,
                itemLabelBuilder: (option) => option.isPlaceholder
                    ? l.selectRelatedRecord
                    : _relatedRecordLabel(l, option.record),
                enabled: false,
                onChanged: (option) => onChanged(option.record),
              );
            }
            return Text(
              _emptyRelatedRecordsLabel(l, type),
              style: Theme.of(context).textTheme.bodySmall,
            );
          }

          final options = _relatedRecordOptions(
            state.relatedRecordOptions,
            selectedId: value,
            selectedType: type,
          );
          final selectedOption = _relatedRecordSelectionFor(
            value,
            options,
          );

          return AppDropdown<_RelatedRecordSelection>(
            key: ValueKey('${type.name}-${selectedOption.record?.id ?? ''}'),
            label: l.relatedRecord,
            value: selectedOption,
            items: options,
            itemLabelBuilder: (option) => option.isPlaceholder
                ? l.selectRelatedRecord
                : _relatedRecordLabel(l, option.record),
            enabled: enabled && options.length > 1,
            onChanged: (option) => onChanged(option.record),
          );
        },
      ),
    );
  }
}

class _RelatedRecordLoading extends StatelessWidget {
  const _RelatedRecordLoading({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        floatingLabelBehavior: FloatingLabelBehavior.always,
      ),
      child: const SizedBox(
        height: 28,
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
    );
  }
}

class _RelatedRecordSelection {
  const _RelatedRecordSelection._({
    required this.record,
    required this.isPlaceholder,
  });

  const _RelatedRecordSelection.placeholder()
    : this._(record: null, isPlaceholder: true);

  const _RelatedRecordSelection.value(TaskRelatedRecordOption record)
    : this._(record: record, isPlaceholder: false);

  final TaskRelatedRecordOption? record;
  final bool isPlaceholder;

  @override
  bool operator ==(Object other) {
    return other is _RelatedRecordSelection &&
        other.isPlaceholder == isPlaceholder &&
        other.record?.id == record?.id;
  }

  @override
  int get hashCode => Object.hash(record?.id, isPlaceholder);
}

List<_RelatedRecordSelection> _relatedRecordOptions(
  List<TaskRelatedRecordOption> records, {
  required String selectedId,
  required TaskRelatedType selectedType,
}) {
  final sortedRecords = [...records]
    ..sort((a, b) => a.title.compareTo(b.title));
  return [
    const _RelatedRecordSelection.placeholder(),
    for (final record in sortedRecords) _RelatedRecordSelection.value(record),
  ];
}

_RelatedRecordSelection _relatedRecordSelectionFor(
  String selectedId,
  List<_RelatedRecordSelection> options,
) {
  final trimmed = selectedId.trim();
  if (trimmed.isEmpty) {
    return const _RelatedRecordSelection.placeholder();
  }
  for (final option in options) {
    if (option.record?.id == trimmed) {
      return option;
    }
  }
  return const _RelatedRecordSelection.placeholder();
}

class _TaskAssigneeOption {
  const _TaskAssigneeOption._({required this.value, required this.isUnassigned});

  const _TaskAssigneeOption.unassigned()
    : this._(value: null, isUnassigned: true);

  const _TaskAssigneeOption.value(String value)
    : this._(value: value, isUnassigned: false);

  factory _TaskAssigneeOption.fromValue(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty
        ? const _TaskAssigneeOption.unassigned()
        : _TaskAssigneeOption.value(trimmed);
  }

  final String? value;
  final bool isUnassigned;

  @override
  bool operator ==(Object other) {
    return other is _TaskAssigneeOption &&
        other.isUnassigned == isUnassigned &&
        other.value == value;
  }

  @override
  int get hashCode => Object.hash(value, isUnassigned);
}

List<_TaskAssigneeOption> _taskAssigneeOptions(List<UserProfile> users) {
  final assignableUsers = AssignmentUserPolicy.assignableUsersFor(
    AssignableWorkType.task,
    users,
  );
  return [
    const _TaskAssigneeOption.unassigned(),
    for (final user in assignableUsers) _TaskAssigneeOption.value(user.uid),
  ];
}

String _assigneeLabel(
  AppLocalizations l,
  List<UserProfile> users,
  String? uid,
) {
  final value = uid?.trim() ?? '';
  if (value.isEmpty) {
    return l.unassigned;
  }
  for (final user in users) {
    if (user.uid == value) {
      return user.fullName.trim().isEmpty ? user.email : user.fullName;
    }
  }
  return l.assignedUserUnavailable;
}

String _relatedTypeLabel(AppLocalizations l, TaskRelatedType type) {
  switch (type) {
    case TaskRelatedType.lead:
      return l.lead;
    case TaskRelatedType.client:
      return l.client;
    case TaskRelatedType.property:
      return l.property;
    case TaskRelatedType.deal:
      return l.deal;
    case TaskRelatedType.general:
      return l.general;
  }
}

String _emptyRelatedRecordsLabel(AppLocalizations l, TaskRelatedType type) {
  switch (type) {
    case TaskRelatedType.lead:
      return l.noLeadsFound;
    case TaskRelatedType.client:
      return l.noClientsFound;
    case TaskRelatedType.property:
      return l.noPropertiesFound;
    case TaskRelatedType.deal:
      return l.noDealsAvailable;
    case TaskRelatedType.general:
      return l.noData;
  }
}

String _relatedRecordLabel(
  AppLocalizations l,
  TaskRelatedRecordOption? record,
) {
  if (record == null) {
    return l.selectRelatedRecord;
  }
  final title = record.title.trim();
  final subtitle = record.subtitle.trim();
  if (title.isEmpty) {
    return l.relatedRecordUnavailable;
  }
  return subtitle.isEmpty ? title : '$title - $subtitle';
}

String _priorityLabel(AppLocalizations l, TaskPriority priority) {
  switch (priority) {
    case TaskPriority.low:
      return l.low;
    case TaskPriority.medium:
      return l.medium;
    case TaskPriority.high:
      return l.high;
  }
}

String _statusLabel(AppLocalizations l, TaskStatus status) {
  switch (status) {
    case TaskStatus.pending:
      return l.pending;
    case TaskStatus.inProgress:
      return l.inProgress;
    case TaskStatus.completed:
      return l.completed;
    case TaskStatus.cancelled:
      return l.cancelled;
  }
}
