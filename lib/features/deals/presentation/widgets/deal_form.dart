import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_dropdown.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../clients/domain/entities/client.dart';
import '../../../leads/domain/entities/lead.dart';
import '../../../properties/domain/entities/property.dart';
import '../../../users/domain/entities/assignment_user_policy.dart';
import '../../../users/domain/entities/user_profile.dart';
import '../../domain/entities/deal.dart';
import 'deal_card.dart';

class DealForm extends StatefulWidget {
  const DealForm({
    super.key,
    required this.companyId,
    required this.actorUid,
    required this.onSubmit,
    required this.clients,
    required this.leads,
    required this.properties,
    required this.users,
    this.deal,
    this.canEditAssignment = false,
    this.assignedTo = '',
    this.assignedToName = '',
    this.assignedToEmail = '',
    this.assignedTeamId = '',
    this.assignedTeamName = '',
    this.assignedManagerId = '',
    this.assignedManagerName = '',
    this.isSaving = false,
    this.submitLabel,
  });

  final String companyId;
  final String actorUid;
  final ValueChanged<Deal> onSubmit;
  final List<Client> clients;
  final List<Lead> leads;
  final List<Property> properties;
  final List<UserProfile> users;
  final Deal? deal;
  final bool canEditAssignment;
  final String assignedTo;
  final String assignedToName;
  final String assignedToEmail;
  final String assignedTeamId;
  final String assignedTeamName;
  final String assignedManagerId;
  final String assignedManagerName;
  final bool isSaving;
  final String? submitLabel;

  @override
  State<DealForm> createState() => _DealFormState();
}

class _DealFormState extends State<DealForm> {
  final _formKey = GlobalKey<FormState>();
  final _expectedValueController = TextEditingController();
  final _commissionController = TextEditingController();
  final _notesController = TextEditingController();

  String _clientId = '';
  String _leadId = '';
  String _propertyId = '';
  String _assignedTo = '';
  String _lostReason = '';
  DealStage _stage = DealStage.newDeal;
  DateTime? _closingDate;

  @override
  void initState() {
    super.initState();
    final deal = widget.deal;
    _assignedTo = deal?.assignedTo ?? widget.assignedTo;
    if (deal == null) {
      return;
    }
    _clientId = deal.clientId;
    _leadId = deal.leadId;
    _propertyId = deal.propertyId;
    _stage = deal.stage;
    _closingDate = deal.closingDate;
    _expectedValueController.text =
        deal.expectedValue == 0 ? '' : deal.expectedValue.toString();
    _commissionController.text =
        deal.commission == 0 ? '' : deal.commission.toString();
    _lostReason = isControlledDealLostReasonValue(deal.lostReason)
        ? deal.lostReason.trim()
        : '';
    _notesController.text = deal.notes;
  }

  @override
  void dispose() {
    _expectedValueController.dispose();
    _commissionController.dispose();
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
          _section(context, l.dealInformation, [
            _ClientPicker(
              clients: widget.clients,
              selectedId: _clientId,
              enabled: !widget.isSaving,
              onChanged: (client) => setState(() => _clientId = client?.id ?? ''),
            ),
            const SizedBox(height: AppSpacing.md),
            _LeadPicker(
              leads: widget.leads,
              selectedId: _leadId,
              enabled: !widget.isSaving,
              onChanged: (lead) => setState(() => _leadId = lead?.id ?? ''),
            ),
            const SizedBox(height: AppSpacing.md),
            _PropertyPicker(
              properties: widget.properties,
              selectedId: _propertyId,
              enabled: !widget.isSaving,
              onChanged: (property) =>
                  setState(() => _propertyId = property?.id ?? ''),
            ),
            if (widget.canEditAssignment) ...[
              const SizedBox(height: AppSpacing.md),
              _UserPicker(
                users: widget.users,
                selectedId: _assignedTo,
                enabled: !widget.isSaving,
                onChanged: (user) =>
                    setState(() => _assignedTo = user?.uid ?? ''),
              ),
            ],
          ]),
          const SizedBox(height: AppSpacing.lg),
          _section(context, l.dealValueAndStage, [
            AppDropdown<DealStage>(
              label: l.dealStage,
              value: _stage,
              items: DealStage.values,
              itemLabelBuilder: (stage) => dealStageLabel(l, stage),
              enabled: !widget.isSaving,
              onChanged: (stage) {
                setState(() {
                  _stage = stage;
                  if (stage != DealStage.lost) {
                    _lostReason = '';
                  }
                });
              },
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _expectedValueController,
              label: l.expectedValue,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              enabled: !widget.isSaving,
              validator: (value) => _nonNegativeNumberValidator(value, l),
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _commissionController,
              label: l.commission,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              enabled: !widget.isSaving,
              validator: (value) => _nonNegativeNumberValidator(value, l),
            ),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
              onPressed: widget.isSaving ? null : _pickClosingDate,
              icon: const Icon(Icons.event_outlined),
              label: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(_closingDateLabel(l)),
              ),
            ),
            if (_stage == DealStage.lost) ...[
              const SizedBox(height: AppSpacing.md),
              AppDropdown<String>(
                label: l.lostReason,
                value: _lostReason,
                items: dealLostReasonOptionValues,
                itemLabelBuilder: (reason) => reason.isEmpty
                    ? l.selectLostReason
                    : dealLostReasonLabel(l, reason),
                enabled: !widget.isSaving,
                onChanged: (reason) => setState(() => _lostReason = reason),
                validator: (reason) => (reason == null || reason.trim().isEmpty)
                    ? l.lostReasonControlledRequired
                    : null,
              ),
            ],
          ]),
          const SizedBox(height: AppSpacing.lg),
          _section(context, l.notes, [
            AppTextField(
              controller: _notesController,
              label: l.notes,
              enabled: !widget.isSaving,
              maxLines: 4,
            ),
          ]),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: widget.submitLabel ?? l.createDeal,
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

  Future<void> _pickClosingDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _closingDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (picked == null || !mounted) {
      return;
    }
    setState(() => _closingDate = picked);
  }

  String _closingDateLabel(AppLocalizations l) {
    final closingDate = _closingDate;
    if (closingDate == null) {
      return l.closingDate;
    }
    return MaterialLocalizations.of(context).formatMediumDate(closingDate);
  }


  String? _nonNegativeNumberValidator(String? value, AppLocalizations l) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return null;
    }
    final number = num.tryParse(trimmed);
    if (number == null) {
      return l.enterValidNumber;
    }
    if (number < 0) {
      return l.valueMustBeNonNegative;
    }
    return null;
  }

  void _submit() {
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) {
      return;
    }
    final l = AppLocalizations.of(context)!;
    final client = _clientById(_clientId);
    if (client == null) {
      AppFeedback.warning(context, l.selectClient);
      return;
    }
    final property = _propertyById(_propertyId);
    if (property == null) {
      AppFeedback.warning(context, l.selectProperty);
      return;
    }
    final assignedUser = _userById(_assignedTo);
    if (_assignedTo.trim().isEmpty || assignedUser == null) {
      AppFeedback.warning(context, l.selectAssignedAgent);
      return;
    }
    final lead = _leadById(_leadId);
    final expectedValue = num.tryParse(_expectedValueController.text.trim()) ?? 0;
    if (_stage == DealStage.lost && _lostReason.trim().isEmpty) {
      AppFeedback.warning(context, l.lostReasonControlledRequired);
      return;
    }
    if (_stage == DealStage.won && expectedValue <= 0) {
      AppFeedback.warning(context, l.dealWonRequiresExpectedValue);
      return;
    }
    final now = DateTime.now();
    final previous = widget.deal;

    widget.onSubmit(
      Deal(
        id: previous?.id ?? '',
        companyId: widget.companyId,
        clientId: client.id,
        clientName: client.fullName,
        clientEmail: client.email,
        clientPhone: client.phone,
        leadId: lead?.id ?? '',
        leadName: lead?.fullName ?? '',
        leadPhone: lead?.phone ?? '',
        propertyId: property.id,
        propertyTitle: property.title,
        propertyLocation: property.location,
        assignedTo: assignedUser.uid,
        assignedToName: assignedUser.fullName,
        assignedToEmail: assignedUser.email,
        teamId: assignedUser.teamId.isEmpty
            ? widget.assignedTeamId
            : assignedUser.teamId,
        teamName: assignedUser.teamName.isEmpty
            ? widget.assignedTeamName
            : assignedUser.teamName,
        managerId: assignedUser.managerId.isEmpty
            ? widget.assignedManagerId
            : assignedUser.managerId,
        managerName: assignedUser.managerName.isEmpty
            ? widget.assignedManagerName
            : assignedUser.managerName,
        stage: _stage,
        expectedValue: expectedValue,
        commission: num.tryParse(_commissionController.text.trim()) ?? 0,
        closingDate: _closingDate,
        lostReason: _stage == DealStage.lost ? _lostReason.trim() : '',
        notes: _notesController.text.trim(),
        isActive: previous?.isActive ?? true,
        createdAt: previous?.createdAt ?? now,
        updatedAt: now,
        createdBy: previous?.createdBy ?? widget.actorUid,
        updatedBy: widget.actorUid,
      ),
    );
  }

  Client? _clientById(String id) {
    for (final client in widget.clients) {
      if (client.id == id) {
        return client;
      }
    }
    return null;
  }

  Lead? _leadById(String id) {
    for (final lead in widget.leads) {
      if (lead.id == id) {
        return lead;
      }
    }
    return null;
  }

  Property? _propertyById(String id) {
    for (final property in widget.properties) {
      if (property.id == id) {
        return property;
      }
    }
    return null;
  }

  UserProfile? _userById(String id) {
    for (final user in widget.users) {
      if (user.uid == id) {
        return user;
      }
    }
    return null;
  }
}

class _ClientPicker extends StatelessWidget {
  const _ClientPicker({
    required this.clients,
    required this.selectedId,
    required this.enabled,
    required this.onChanged,
  });

  final List<Client> clients;
  final String selectedId;
  final bool enabled;
  final ValueChanged<Client?> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final options = [
      const _Selection.placeholder(),
      for (final client in clients)
        _Selection.value(client.id, client.fullName, client.phone),
    ];
    return AppDropdown<_Selection>(
      label: l.client,
      value: _selectionFor(selectedId, options),
      items: options,
      itemLabelBuilder: (option) => option.isPlaceholder
          ? l.selectClient
          : _selectionLabel(option),
      enabled: enabled && options.length > 1,
      onChanged: (option) => onChanged(_clientFor(option.id, clients)),
    );
  }
}

class _LeadPicker extends StatelessWidget {
  const _LeadPicker({
    required this.leads,
    required this.selectedId,
    required this.enabled,
    required this.onChanged,
  });

  final List<Lead> leads;
  final String selectedId;
  final bool enabled;
  final ValueChanged<Lead?> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final options = [
      const _Selection.placeholder(),
      for (final lead in leads) _Selection.value(lead.id, lead.fullName, lead.phone),
    ];
    return AppDropdown<_Selection>(
      label: l.lead,
      value: _selectionFor(selectedId, options),
      items: options,
      itemLabelBuilder: (option) => option.isPlaceholder
          ? l.selectLead
          : _selectionLabel(option),
      enabled: enabled && options.length > 1,
      onChanged: (option) => onChanged(_leadFor(option.id, leads)),
    );
  }
}

class _PropertyPicker extends StatelessWidget {
  const _PropertyPicker({
    required this.properties,
    required this.selectedId,
    required this.enabled,
    required this.onChanged,
  });

  final List<Property> properties;
  final String selectedId;
  final bool enabled;
  final ValueChanged<Property?> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final options = [
      const _Selection.placeholder(),
      for (final property in properties)
        _Selection.value(property.id, property.title, property.location),
    ];
    return AppDropdown<_Selection>(
      label: l.property,
      value: _selectionFor(selectedId, options),
      items: options,
      itemLabelBuilder: (option) => option.isPlaceholder
          ? l.selectProperty
          : _selectionLabel(option),
      enabled: enabled && options.length > 1,
      onChanged: (option) => onChanged(_propertyFor(option.id, properties)),
    );
  }
}

class _UserPicker extends StatelessWidget {
  const _UserPicker({
    required this.users,
    required this.selectedId,
    required this.enabled,
    required this.onChanged,
  });

  final List<UserProfile> users;
  final String selectedId;
  final bool enabled;
  final ValueChanged<UserProfile?> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final assignableUsers = AssignmentUserPolicy.assignableUsersFor(
      AssignableWorkType.deal,
      users,
    );
    final options = [
      const _Selection.placeholder(),
      for (final user in assignableUsers)
        _Selection.value(user.uid, user.fullName, user.email),
    ];
    return AppDropdown<_Selection>(
      label: l.assignedAgent,
      value: _userSelectionFor(selectedId, options, users),
      items: options,
      itemLabelBuilder: (option) => option.isPlaceholder
          ? l.selectAssignedAgent
          : _selectionLabel(option),
      enabled: enabled && options.length > 1,
      onChanged: (option) => onChanged(_userFor(option.id, users)),
    );
  }
}

class _Selection {
  const _Selection._({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.isPlaceholder,
  });

  const _Selection.placeholder()
    : this._(id: '', title: '', subtitle: '', isPlaceholder: true);

  const _Selection.value(String id, String title, String subtitle)
    : this._(
        id: id,
        title: title,
        subtitle: subtitle,
        isPlaceholder: false,
      );

  final String id;
  final String title;
  final String subtitle;
  final bool isPlaceholder;

  @override
  bool operator ==(Object other) {
    return other is _Selection &&
        other.id == id &&
        other.isPlaceholder == isPlaceholder;
  }

  @override
  int get hashCode => Object.hash(id, isPlaceholder);
}

_Selection _selectionFor(String selectedId, List<_Selection> options) {
  final trimmed = selectedId.trim();
  if (trimmed.isEmpty) {
    return const _Selection.placeholder();
  }
  for (final option in options) {
    if (option.id == trimmed) {
      return option;
    }
  }
  return const _Selection.placeholder();
}

String _selectionLabel(_Selection option) {
  final title = option.title.trim();
  final subtitle = option.subtitle.trim();
  return subtitle.isEmpty ? title : '$title - $subtitle';
}

Client? _clientFor(String id, List<Client> clients) {
  for (final client in clients) {
    if (client.id == id) {
      return client;
    }
  }
  return null;
}

Lead? _leadFor(String id, List<Lead> leads) {
  for (final lead in leads) {
    if (lead.id == id) {
      return lead;
    }
  }
  return null;
}

Property? _propertyFor(String id, List<Property> properties) {
  for (final property in properties) {
    if (property.id == id) {
      return property;
    }
  }
  return null;
}

UserProfile? _userFor(String id, List<UserProfile> users) {
  for (final user in users) {
    if (user.uid == id &&
        AssignmentUserPolicy.canOwn(AssignableWorkType.deal, user)) {
      return user;
    }
  }
  return null;
}

_Selection _userSelectionFor(
  String selectedId,
  List<_Selection> options,
  List<UserProfile> users,
) {
  final selected = _selectionFor(selectedId, options);
  if (!selected.isPlaceholder || selectedId.trim().isEmpty) {
    return selected;
  }

  final user = _rawUserFor(selectedId, users);
  if (user == null) {
    return const _Selection.placeholder();
  }

  return _Selection.value(user.uid, user.fullName, user.email);
}

UserProfile? _rawUserFor(String id, List<UserProfile> users) {
  for (final user in users) {
    if (user.uid == id) {
      return user;
    }
  }
  return null;
}
