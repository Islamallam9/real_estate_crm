import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_dropdown.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/crm_task.dart';

class TaskForm extends StatefulWidget {
  const TaskForm({
    super.key,
    required this.companyId,
    required this.actorUid,
    required this.onSubmit,
    this.isSaving = false,
    this.submitLabel,
  });

  final String companyId;
  final String actorUid;
  final ValueChanged<CrmTask> onSubmit;
  final bool isSaving;
  final String? submitLabel;

  @override
  State<TaskForm> createState() => _TaskFormState();
}

class _TaskFormState extends State<TaskForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _relatedIdController = TextEditingController();

  TaskRelatedType _relatedType = TaskRelatedType.general;
  TaskPriority _priority = TaskPriority.medium;
  DateTime? _dueDate;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _relatedIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return Form(
      key: _formKey,
      child: Stack(
        children: [
          Column(
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
                  items: TaskRelatedType.values,
                  itemLabelBuilder: (type) => _relatedTypeLabel(l, type),
                  enabled: !widget.isSaving,
                  onChanged: (value) => setState(() => _relatedType = value),
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: _relatedIdController,
                  label: l.relatedRecordId,
                  enabled: !widget.isSaving,
                ),
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
              ]),
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                label: widget.submitLabel ?? l.createTask,
                isLoading: widget.isSaving,
                onPressed: widget.isSaving ? null : _submit,
              ),
            ],
          ),
          if (widget.isSaving)
            Positioned.fill(
              child: ColoredBox(
                color: AppColors.appBackground(
                  context,
                ).withValues(alpha: 0.42),
                child: const Center(child: CircularProgressIndicator()),
              ),
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.dueDateRequired)),
      );
      return;
    }

    final now = DateTime.now();
    widget.onSubmit(
      CrmTask(
        id: '',
        companyId: widget.companyId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        assignedTo: '',
        relatedType: _relatedType,
        relatedId: _relatedIdController.text.trim(),
        dueDate: _dueDate,
        status: TaskStatus.pending,
        priority: _priority,
        createdAt: now,
        updatedAt: now,
        createdBy: widget.actorUid,
        updatedBy: widget.actorUid,
        isActive: true,
      ),
    );
  }
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
