import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_dropdown.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../users/domain/entities/user_profile.dart';
import '../../domain/entities/lead.dart';

class LeadForm extends StatefulWidget {
  const LeadForm({
    super.key,
    required this.companyId,
    required this.createdBy,
    required this.onSubmit,
    this.lead,
    this.submitLabel,
    this.assignmentUsers = const [],
    this.canAssign = false,
    this.isSaving = false,
  });

  final String companyId;
  final String createdBy;
  final bool isSaving;
  final ValueChanged<Lead> onSubmit;
  final Lead? lead;
  final String? submitLabel;
  final List<UserProfile> assignmentUsers;
  final bool canAssign;

  @override
  State<LeadForm> createState() => _LeadFormState();
}

class _LeadFormState extends State<LeadForm> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _budgetMinController = TextEditingController();
  final _budgetMaxController = TextEditingController();
  final _sourceDetailsController = TextEditingController();
  final _preferredLocationController = TextEditingController();
  final _preferredPropertyTypeController = TextEditingController();
  final _notesController = TextEditingController();

  LeadSource _source = LeadSource.other;
  LeadStatus _status = LeadStatus.newLead;
  LeadPriority _priority = LeadPriority.medium;
  String _assignedTo = '';
  String _assignedToName = '';
  DateTime? _lastContactAt;
  DateTime? _nextFollowUpAt;

  @override
  void initState() {
    super.initState();
    final lead = widget.lead;
    if (lead == null) {
      return;
    }
    _fullNameController.text = lead.fullName;
    _phoneController.text = lead.phone;
    _emailController.text = lead.email;
    _budgetMinController.text = lead.budgetMin == 0
        ? ''
        : lead.budgetMin.toString();
    _budgetMaxController.text = lead.budgetMax == 0
        ? ''
        : lead.budgetMax.toString();
    _sourceDetailsController.text = lead.sourceDetails;
    _preferredLocationController.text = lead.preferredLocation;
    _preferredPropertyTypeController.text = lead.preferredPropertyType;
    _notesController.text = lead.notes;
    _source = lead.source;
    _status = lead.status;
    _priority = lead.priority;
    _assignedTo = lead.assignedTo;
    _assignedToName = lead.assignedToName;
    _lastContactAt = lead.lastContactAt;
    _nextFollowUpAt = lead.nextFollowUpAt;
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _budgetMinController.dispose();
    _budgetMaxController.dispose();
    _sourceDetailsController.dispose();
    _preferredLocationController.dispose();
    _preferredPropertyTypeController.dispose();
    _notesController.dispose();
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
          _section(context, l.contactInformation, [
            AppTextField(
              controller: _fullNameController,
              label: l.leadName,
              enabled: !widget.isSaving,
              validator: (value) => _required(value, l),
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _phoneController,
              label: l.phone,
              keyboardType: TextInputType.phone,
              enabled: !widget.isSaving,
              validator: (value) => _required(value, l),
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _emailController,
              label: l.email,
              keyboardType: TextInputType.emailAddress,
              enabled: !widget.isSaving,
            ),
            const SizedBox(height: AppSpacing.md),
            _LeadDateField(
              label: l.lastContact,
              value: _lastContactAt,
              enabled: !widget.isSaving,
              firstDate: DateTime(2000),
              lastDate: DateTime.now(),
              onChanged: (value) => setState(() => _lastContactAt = value),
            ),
            const SizedBox(height: AppSpacing.md),
            _LeadDateField(
              label: l.nextFollowUp,
              value: _nextFollowUpAt,
              enabled: !widget.isSaving,
              firstDate: DateTime.now(),
              lastDate: DateTime(2100, 12, 31),
              onChanged: (value) => setState(() => _nextFollowUpAt = value),
            ),
          ]),
          const SizedBox(height: AppSpacing.lg),
          _section(context, l.leadPreferences, [
            AppDropdown<LeadSource>(
              label: l.source,
              value: _source,
              items: LeadSource.values,
              enabled: !widget.isSaving,
              itemLabelBuilder: (source) => _sourceLabel(l, source),
              onChanged: (value) {
                setState(() {
                  _source = value;
                  if (_source != LeadSource.other) {
                    _sourceDetailsController.clear();
                  }
                });
              },
            ),
            if (_source == LeadSource.other) ...[
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _sourceDetailsController,
                label: l.sourceDetails,
                enabled: !widget.isSaving,
                validator: (value) => _required(value, l),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            AppDropdown<LeadStatus>(
              label: l.status,
              value: _status,
              items: LeadStatus.values,
              enabled: !widget.isSaving,
              itemLabelBuilder: (status) => _statusLabel(l, status),
              onChanged: (value) => setState(() => _status = value),
            ),
            const SizedBox(height: AppSpacing.md),
            AppDropdown<LeadPriority>(
              label: l.priority,
              value: _priority,
              items: LeadPriority.values,
              enabled: !widget.isSaving,
              itemLabelBuilder: (priority) => _priorityLabel(l, priority),
              onChanged: (value) => setState(() => _priority = value),
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _budgetMinController,
              label: l.budgetMin,
              keyboardType: TextInputType.number,
              enabled: !widget.isSaving,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _budgetMaxController,
              label: l.budgetMax,
              keyboardType: TextInputType.number,
              enabled: !widget.isSaving,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _preferredLocationController,
              label: l.preferredLocation,
              enabled: !widget.isSaving,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _preferredPropertyTypeController,
              label: l.preferredPropertyType,
              enabled: !widget.isSaving,
            ),
          ]),
          const SizedBox(height: AppSpacing.lg),
          _section(context, l.leadAssignment, [
            if (widget.canAssign)
              AppDropdown<String>(
                label: l.assignedToLabel,
                value: _assignedTo,
                enabled: !widget.isSaving,
                items: ['', ...widget.assignmentUsers.map((user) => user.uid)],
                itemLabelBuilder: (uid) => _assigneeLabel(l, uid),
                onChanged: (uid) {
                  setState(() {
                    _assignedTo = uid;
                    _assignedToName = _assigneeNameForUid(uid);
                  });
                },
              )
            else
              InputDecorator(
                decoration: InputDecoration(
                  labelText: l.assignedToLabel,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(_readonlyAssigneeLabel(l)),
              ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _notesController,
              label: l.notes,
              enabled: !widget.isSaving,
            ),
          ]),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: widget.submitLabel ?? l.saveLead,
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

  String? _required(String? value, AppLocalizations l) {
    if (value == null || value.trim().isEmpty) {
      return l.requiredField;
    }
    return null;
  }

  String _assigneeLabel(AppLocalizations l, String uid) {
    if (uid.isEmpty) {
      return l.unassigned;
    }
    final name = _assigneeNameForUid(uid);
    return name.isEmpty ? l.assignedUserUnavailable : name;
  }

  String _readonlyAssigneeLabel(AppLocalizations l) {
    if (_assignedTo.isEmpty) {
      return l.unassigned;
    }
    if (_assignedToName.isNotEmpty) {
      return _assignedToName;
    }
    final name = _assigneeNameForUid(_assignedTo);
    return name.isEmpty ? l.assignedUserUnavailable : name;
  }

  String _assigneeNameForUid(String uid) {
    for (final user in widget.assignmentUsers) {
      if (user.uid == uid) {
        return user.fullName;
      }
    }
    return '';
  }

  void _submit() {
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) {
      return;
    }

    final now = DateTime.now();
    widget.onSubmit(
      Lead(
        id: widget.lead?.id ?? '',
        companyId: widget.companyId,
        fullName: _fullNameController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        source: _source,
        sourceDetails: _source == LeadSource.other
            ? _sourceDetailsController.text.trim()
            : '',
        status: _status,
        priority: _priority,
        budgetMin: num.tryParse(_budgetMinController.text.trim()) ?? 0,
        budgetMax: num.tryParse(_budgetMaxController.text.trim()) ?? 0,
        preferredLocation: _preferredLocationController.text.trim(),
        preferredPropertyType: _preferredPropertyTypeController.text.trim(),
        assignedTo: widget.canAssign
            ? _assignedTo
            : widget.lead?.assignedTo ?? '',
        assignedToName: widget.canAssign
            ? _assignedToName
            : widget.lead?.assignedToName ?? '',
        notes: _notesController.text.trim(),
        createdAt: widget.lead?.createdAt ?? now,
        updatedAt: now,
        createdBy: widget.lead?.createdBy ?? widget.createdBy,
        updatedBy: widget.createdBy,
        lastContactAt: _lastContactAt,
        nextFollowUpAt: _nextFollowUpAt,
        isArchived: widget.lead?.isArchived ?? false,
        archivedAt: widget.lead?.archivedAt,
        archivedBy: widget.lead?.archivedBy,
      ),
    );
  }
}

class _LeadDateField extends StatelessWidget {
  const _LeadDateField({
    required this.label,
    required this.value,
    required this.enabled,
    required this.firstDate,
    required this.lastDate,
    required this.onChanged,
  });

  final String label;
  final DateTime? value;
  final bool enabled;
  final DateTime firstDate;
  final DateTime lastDate;
  final ValueChanged<DateTime?> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final selectedValue = value;

    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabled: enabled,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              selectedValue == null ? l.notAvailable : _formatDate(selectedValue),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: enabled
                    ? AppColors.textPrimaryColor(context)
                    : AppColors.textSecondaryColor(context),
              ),
            ),
          ),
          if (selectedValue != null)
            IconButton(
              tooltip: l.clearDate,
              onPressed: enabled ? () => onChanged(null) : null,
              icon: const Icon(Icons.clear),
            ),
          IconButton(
            tooltip: label,
            onPressed: enabled ? () => _pickDate(context) : null,
            icon: const Icon(Icons.calendar_today_outlined),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final initialDate = _initialDate();
    final safeFirstDate = DateUtils.dateOnly(firstDate);
    final safeLastDate = DateUtils.dateOnly(lastDate);
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: safeFirstDate,
      lastDate: safeLastDate,
    );

    if (pickedDate == null) {
      return;
    }

    onChanged(pickedDate);
  }

  DateTime _initialDate() {
    final safeFirstDate = DateUtils.dateOnly(firstDate);
    final safeLastDate = DateUtils.dateOnly(lastDate);
    final currentValue = value;
    final selectedValue = currentValue == null
        ? null
        : DateUtils.dateOnly(currentValue);
    if (selectedValue == null) {
      final today = DateUtils.dateOnly(DateTime.now());
      if (today.isBefore(safeFirstDate)) {
        return safeFirstDate;
      }
      if (today.isAfter(safeLastDate)) {
        return safeLastDate;
      }
      return today;
    }
    if (selectedValue.isBefore(safeFirstDate)) {
      return safeFirstDate;
    }
    if (selectedValue.isAfter(safeLastDate)) {
      return safeLastDate;
    }
    return selectedValue;
  }
}

String _formatDate(DateTime value) {
  final local = value.toLocal();
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  return '${local.year}-$month-$day';
}

String _sourceLabel(AppLocalizations l, LeadSource source) {
  switch (source) {
    case LeadSource.facebook:
      return l.facebook;
    case LeadSource.website:
      return l.website;
    case LeadSource.phoneCall:
      return l.phoneCall;
    case LeadSource.whatsapp:
      return l.whatsapp;
    case LeadSource.referral:
      return l.referral;
    case LeadSource.walkIn:
      return l.walkIn;
    case LeadSource.other:
      return l.other;
  }
}

String _statusLabel(AppLocalizations l, LeadStatus status) {
  switch (status) {
    case LeadStatus.newLead:
      return l.newLeadStatus;
    case LeadStatus.contacted:
      return l.contactedLeadStatus;
    case LeadStatus.interested:
      return l.interestedLeadStatus;
    case LeadStatus.visitScheduled:
      return l.visitScheduledLeadStatus;
    case LeadStatus.negotiation:
      return l.negotiationLeadStatus;
    case LeadStatus.won:
      return l.wonLeadStatus;
    case LeadStatus.lost:
      return l.lostLeadStatus;
  }
}

String _priorityLabel(AppLocalizations l, LeadPriority priority) {
  switch (priority) {
    case LeadPriority.low:
      return l.low;
    case LeadPriority.medium:
      return l.medium;
    case LeadPriority.high:
      return l.high;
  }
}
