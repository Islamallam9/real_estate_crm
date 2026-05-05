import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_dropdown.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/lead.dart';

class LeadForm extends StatefulWidget {
  const LeadForm({
    super.key,
    required this.companyId,
    required this.createdBy,
    required this.onSubmit,
    this.isSaving = false,
  });

  final String companyId;
  final String createdBy;
  final bool isSaving;
  final ValueChanged<Lead> onSubmit;

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
  final _preferredLocationController = TextEditingController();
  final _preferredPropertyTypeController = TextEditingController();
  final _assignedToController = TextEditingController();
  final _notesController = TextEditingController();

  LeadSource _source = LeadSource.other;
  LeadStatus _status = LeadStatus.newLead;
  LeadPriority _priority = LeadPriority.medium;

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _budgetMinController.dispose();
    _budgetMaxController.dispose();
    _preferredLocationController.dispose();
    _preferredPropertyTypeController.dispose();
    _assignedToController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _FormSection(
            title: localizations.contactInformation,
            children: [
              AppTextField(
                controller: _fullNameController,
                label: localizations.leadName,
                enabled: !widget.isSaving,
                validator: (value) => _required(value, localizations),
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _phoneController,
                label: localizations.phone,
                keyboardType: TextInputType.phone,
                enabled: !widget.isSaving,
                validator: (value) => _required(value, localizations),
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _emailController,
                label: localizations.email,
                keyboardType: TextInputType.emailAddress,
                enabled: !widget.isSaving,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _FormSection(
            title: localizations.leadPreferences,
            children: [
              AppDropdown<LeadSource>(
                label: localizations.source,
                value: _source,
                enabled: !widget.isSaving,
                items: LeadSource.values,
                itemLabelBuilder: (source) =>
                    _sourceLabel(localizations, source),
                onChanged: (value) => setState(() => _source = value),
              ),
              const SizedBox(height: AppSpacing.md),
              AppDropdown<LeadStatus>(
                label: localizations.status,
                value: _status,
                enabled: !widget.isSaving,
                items: LeadStatus.values,
                itemLabelBuilder: (status) =>
                    _statusLabel(localizations, status),
                onChanged: (value) => setState(() => _status = value),
              ),
              const SizedBox(height: AppSpacing.md),
              AppDropdown<LeadPriority>(
                label: localizations.priority,
                value: _priority,
                enabled: !widget.isSaving,
                items: LeadPriority.values,
                itemLabelBuilder: (priority) =>
                    _priorityLabel(localizations, priority),
                onChanged: (value) => setState(() => _priority = value),
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _budgetMinController,
                label: localizations.budgetMin,
                keyboardType: TextInputType.number,
                enabled: !widget.isSaving,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _budgetMaxController,
                label: localizations.budgetMax,
                keyboardType: TextInputType.number,
                enabled: !widget.isSaving,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _preferredLocationController,
                label: localizations.preferredLocation,
                enabled: !widget.isSaving,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _preferredPropertyTypeController,
                label: localizations.preferredPropertyType,
                enabled: !widget.isSaving,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _FormSection(
            title: localizations.leadAssignment,
            children: [
              AppTextField(
                controller: _assignedToController,
                label: localizations.assignedTo,
                enabled: !widget.isSaving,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _notesController,
                label: localizations.notes,
                enabled: !widget.isSaving,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: localizations.saveLead,
            isLoading: widget.isSaving,
            onPressed: widget.isSaving ? null : _submit,
          ),
        ],
      ),
    );
  }

  String? _required(String? value, AppLocalizations localizations) {
    if (value == null || value.trim().isEmpty) {
      return localizations.requiredField;
    }

    return null;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final now = DateTime.now();
    widget.onSubmit(
      Lead(
        id: '',
        companyId: widget.companyId,
        fullName: _fullNameController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        source: _source,
        status: _status,
        priority: _priority,
        budgetMin: num.tryParse(_budgetMinController.text.trim()) ?? 0,
        budgetMax: num.tryParse(_budgetMaxController.text.trim()) ?? 0,
        preferredLocation: _preferredLocationController.text.trim(),
        preferredPropertyType: _preferredPropertyTypeController.text.trim(),
        assignedTo: _assignedToController.text.trim(),
        notes: _notesController.text.trim(),
        createdAt: now,
        updatedAt: now,
        createdBy: widget.createdBy,
        updatedBy: widget.createdBy,
      ),
    );
  }
}

class _FormSection extends StatelessWidget {
  const _FormSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
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
