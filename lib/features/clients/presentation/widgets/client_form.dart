import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_dropdown.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../users/domain/entities/user_profile.dart';
import '../../../properties/domain/entities/property.dart';
import '../../../properties/presentation/widgets/property_labels.dart';
import '../../domain/entities/client.dart';
import 'client_assignment_dropdown.dart';

class ClientForm extends StatefulWidget {
  const ClientForm({
    super.key,
    required this.companyId,
    required this.actorUid,
    required this.onSubmit,
    this.client,
    this.assignedTo = '',
    this.assignedToName = '',
    this.assignedToEmail = '',
    this.assignedTeamId = '',
    this.assignedTeamName = '',
    this.assignedManagerId = '',
    this.assignedManagerName = '',
    this.users = const [],
    this.canEditAssignment = false,
    this.isSaving = false,
    this.submitLabel,
  });

  final String companyId;
  final String actorUid;
  final String assignedTo;
  final String assignedToName;
  final String assignedToEmail;
  final String assignedTeamId;
  final String assignedTeamName;
  final String assignedManagerId;
  final String assignedManagerName;
  final List<UserProfile> users;
  final bool canEditAssignment;
  final ValueChanged<Client> onSubmit;
  final Client? client;
  final bool isSaving;
  final String? submitLabel;

  @override
  State<ClientForm> createState() => _ClientFormState();
}

class _ClientFormState extends State<ClientForm> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _budgetMinController = TextEditingController();
  final _budgetMaxController = TextEditingController();
  final _preferredLocationController = TextEditingController();
  final _notesController = TextEditingController();
  late String _assignedTo;
  String _assignedToName = '';
  String _assignedToEmail = '';
  String _teamId = '';
  String _teamName = '';
  String _managerId = '';
  String _managerName = '';
  String _preferredPropertyType = '';

  @override
  void initState() {
    super.initState();
    _assignedTo = widget.client?.assignedTo ?? widget.assignedTo;
    _assignedToName =
        widget.client?.assignedToName ?? widget.assignedToName;
    _assignedToEmail =
        widget.client?.assignedToEmail ?? widget.assignedToEmail;
    _teamId = widget.client?.teamId ?? widget.assignedTeamId;
    _teamName = widget.client?.teamName ?? widget.assignedTeamName;
    _managerId = widget.client?.managerId ?? widget.assignedManagerId;
    _managerName = widget.client?.managerName ?? widget.assignedManagerName;
    final client = widget.client;
    _syncAssignedSnapshot();
    if (client == null) {
      return;
    }

    _fullNameController.text = client.fullName;
    _phoneController.text = client.phone;
    _emailController.text = client.email;
    _budgetMinController.text = client.budgetMin?.toString() ?? '';
    _budgetMaxController.text = client.budgetMax?.toString() ?? '';
    _preferredLocationController.text = client.preferredLocation;
    _preferredPropertyType = _normalizeStoredPropertyType(client.preferredPropertyType);
    _notesController.text = client.notes;
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _budgetMinController.dispose();
    _budgetMaxController.dispose();
    _preferredLocationController.dispose();
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
                  label: l.fullNameUpdated,
                  enabled: !widget.isSaving,
                  validator: (value) => _requiredValidator(value, l),
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: _phoneController,
                  label: l.phone,
                  keyboardType: TextInputType.phone,
                  enabled: !widget.isSaving,
                  validator: (value) => _requiredValidator(value, l),
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: _emailController,
                  label: l.email,
                  keyboardType: TextInputType.emailAddress,
                  enabled: !widget.isSaving,
                  validator: (value) => _emailValidator(value, l),
                ),
              ]),
              const SizedBox(height: AppSpacing.lg),
              _section(context, l.clientPreferences, [
                AppTextField(
                  controller: _budgetMinController,
                  label: l.budgetMin,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  enabled: !widget.isSaving,
                  validator: (value) => _optionalPositiveNumberValidator(
                    value,
                    l,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: _budgetMaxController,
                  label: l.budgetMax,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  enabled: !widget.isSaving,
                  validator: (value) => _budgetMaxValidator(value, l),
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: _preferredLocationController,
                  label: l.preferredLocation,
                  enabled: !widget.isSaving,
                ),
                const SizedBox(height: AppSpacing.md),
                AppDropdown<String>(
                  label: l.preferredPropertyType,
                  value: _preferredPropertyType,
                  items: ['', ...PropertyType.values.map((type) => type.name)],
                  enabled: !widget.isSaving,
                  itemLabelBuilder: (value) => _propertyTypeChoiceLabel(l, value),
                  onChanged: (value) => setState(() => _preferredPropertyType = value),
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: _notesController,
                  label: l.notes,
                  enabled: !widget.isSaving,
                  maxLines: 3,
                ),
                if (widget.canEditAssignment) ...[
                  const SizedBox(height: AppSpacing.md),
                  ClientAssignmentField(
                    users: widget.users,
                    value: _assignedTo,
                    enabled: !widget.isSaving,
                    onChanged: (uid) {
                      setState(() {
                        _assignedTo = uid;
                        _syncAssignedSnapshot();
                      });
                    },
                  ),
                ],
              ]),
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                label: widget.submitLabel ?? l.createClient,
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

  String? _requiredValidator(String? value, AppLocalizations l) {
    if (value == null || value.trim().isEmpty) {
      return l.requiredField;
    }
    return null;
  }

  String? _emailValidator(String? value, AppLocalizations l) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return null;
    }
    final validEmail = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!validEmail.hasMatch(trimmed)) {
      return l.invalidEmail;
    }
    return null;
  }

  String? _optionalPositiveNumberValidator(
    String? value,
    AppLocalizations l,
  ) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return null;
    }
    final number = num.tryParse(trimmed);
    if (number == null) {
      return l.enterValidNumber;
    }
    if (number <= 0) {
      return l.valueMustBePositive;
    }
    return null;
  }

  String? _budgetMaxValidator(String? value, AppLocalizations l) {
    final baseError = _optionalPositiveNumberValidator(value, l);
    if (baseError != null) {
      return baseError;
    }
    final budgetMin = num.tryParse(_budgetMinController.text.trim());
    final budgetMax = num.tryParse(_budgetMaxController.text.trim());
    if (budgetMin != null && budgetMax != null && budgetMax < budgetMin) {
      return l.budgetMaxMustBeGreaterThanBudgetMin;
    }
    return null;
  }

  String _normalizeStoredPropertyType(String value) {
    final normalized = _normalizePropertyTypeInput(value);
    if (normalized.isEmpty) {
      return '';
    }
    for (final type in PropertyType.values) {
      if (type.name == normalized) {
        return type.name;
      }
    }
    return '';
  }

  String _normalizePropertyTypeInput(String value) {
    final normalized = value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '')
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا')
        .replaceAll('ة', 'ه')
        .replaceAll('ى', 'ي')
        .replaceAll(RegExp(r'[^a-z0-9\u0600-\u06FF]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return switch (normalized) {
      'apartment' || 'flat' || 'شقه' => 'apartment',
      'villa' || 'فيلا' => 'villa',
      'office' || 'مكتب' => 'office',
      'shop' || 'store' || 'محل' => 'shop',
      'land' || 'ارض' => 'land',
      'studio' || 'استوديو' => 'studio',
      'duplex' || 'douplex' || 'دوبلكس' => 'duplex',
      'penthouse' || 'بنتهاوس' => 'penthouse',
      _ => normalized,
    };
  }

  String _propertyTypeChoiceLabel(AppLocalizations l, String value) {
    if (value.trim().isEmpty) {
      return l.notAvailable;
    }
    for (final type in PropertyType.values) {
      if (type.name == value) {
        return propertyTypeLabel(l, type);
      }
    }
    return value;
  }

  void _submit() {
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) {
      return;
    }

    final now = DateTime.now();
    final previous = widget.client;
    final selectedAssignee = _selectedAssignee();
    final assignedTo = widget.canEditAssignment
        ? _assignedTo
        : previous?.assignedTo ?? widget.assignedTo;
    final assignedToName = selectedAssignee?.fullName ?? _assignedToName;
    final assignedToEmail = selectedAssignee?.email ?? _assignedToEmail;
    final teamId = selectedAssignee?.teamId ?? _teamId;
    final teamName = selectedAssignee?.teamName ?? _teamName;
    final managerId = selectedAssignee?.managerId ?? _managerId;
    final managerName = selectedAssignee?.managerName ?? _managerName;
    widget.onSubmit(
      Client(
        id: previous?.id ?? '',
        companyId: widget.companyId,
        fullName: _fullNameController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        budgetMin: num.tryParse(_budgetMinController.text.trim()),
        budgetMax: num.tryParse(_budgetMaxController.text.trim()),
        preferredLocation: _preferredLocationController.text.trim(),
        preferredPropertyType: _preferredPropertyType,
        notes: _notesController.text.trim(),
        assignedTo: assignedTo,
        assignedToName: assignedTo.trim().isEmpty ? '' : assignedToName.trim(),
        assignedToEmail: assignedTo.trim().isEmpty ? '' : assignedToEmail.trim(),
        teamId: assignedTo.trim().isEmpty ? '' : teamId.trim(),
        teamName: assignedTo.trim().isEmpty ? '' : teamName.trim(),
        managerId: assignedTo.trim().isEmpty ? '' : managerId.trim(),
        managerName: assignedTo.trim().isEmpty ? '' : managerName.trim(),
        isActive: previous?.isActive ?? true,
        createdAt: previous?.createdAt ?? now,
        updatedAt: now,
        createdBy: previous?.createdBy ?? widget.actorUid,
        updatedBy: widget.actorUid,
      ),
    );
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
}
