import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_dropdown.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/property.dart';
import 'property_labels.dart';

class PropertyForm extends StatefulWidget {
  const PropertyForm({
    super.key,
    required this.companyId,
    required this.actorUid,
    required this.onSubmit,
    this.property,
    this.isSaving = false,
    this.submitLabel,
  });

  final String companyId;
  final String actorUid;
  final ValueChanged<Property> onSubmit;
  final Property? property;
  final bool isSaving;
  final String? submitLabel;

  @override
  State<PropertyForm> createState() => _PropertyFormState();
}

class _PropertyFormState extends State<PropertyForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _areaController = TextEditingController();
  final _bedroomsController = TextEditingController();
  final _bathroomsController = TextEditingController();
  final _locationController = TextEditingController();
  final _compoundController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _ownerPhoneController = TextEditingController();

  PropertyType _propertyType = PropertyType.apartment;
  PropertyListingType _listingType = PropertyListingType.sale;
  PropertyStatus _status = PropertyStatus.available;

  @override
  void initState() {
    super.initState();
    final property = widget.property;
    if (property == null) {
      return;
    }

    _titleController.text = property.title;
    _descriptionController.text = property.description;
    _priceController.text = property.price == 0 ? '' : property.price.toString();
    _areaController.text = property.area == 0 ? '' : property.area.toString();
    _bedroomsController.text = property.bedrooms == 0
        ? ''
        : property.bedrooms.toString();
    _bathroomsController.text = property.bathrooms == 0
        ? ''
        : property.bathrooms.toString();
    _locationController.text = property.location;
    _compoundController.text = property.compound;
    _ownerNameController.text = property.ownerName;
    _ownerPhoneController.text = property.ownerPhone;
    _propertyType = property.propertyType;
    _listingType = property.listingType;
    _status = property.status;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _areaController.dispose();
    _bedroomsController.dispose();
    _bathroomsController.dispose();
    _locationController.dispose();
    _compoundController.dispose();
    _ownerNameController.dispose();
    _ownerPhoneController.dispose();
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
          _section(context, l.propertyBasicInformation, [
            AppTextField(
              controller: _titleController,
              label: l.propertyTitle,
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
            AppDropdown<PropertyType>(
              label: l.propertyType,
              value: _propertyType,
              enabled: !widget.isSaving,
              items: PropertyType.values,
              itemLabelBuilder: (value) => propertyTypeLabel(l, value),
              onChanged: (value) => setState(() => _propertyType = value),
            ),
            const SizedBox(height: AppSpacing.md),
            AppDropdown<PropertyListingType>(
              label: l.listingType,
              value: _listingType,
              enabled: !widget.isSaving,
              items: PropertyListingType.values,
              itemLabelBuilder: (value) => propertyListingTypeLabel(l, value),
              onChanged: (value) => setState(() => _listingType = value),
            ),
            const SizedBox(height: AppSpacing.md),
            AppDropdown<PropertyStatus>(
              label: l.status,
              value: _status,
              enabled: !widget.isSaving,
              items: PropertyStatus.values,
              itemLabelBuilder: (value) => propertyStatusLabel(l, value),
              onChanged: (value) => setState(() => _status = value),
            ),
          ]),
          const SizedBox(height: AppSpacing.lg),
          _section(context, l.propertyMetrics, [
            AppTextField(
              controller: _priceController,
              label: l.price,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              enabled: !widget.isSaving,
              validator: (value) => _positiveNumberValidator(value, l),
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _areaController,
              label: l.area,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              enabled: !widget.isSaving,
              validator: (value) => _positiveNumberValidator(value, l),
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _bedroomsController,
              label: l.bedrooms,
              keyboardType: TextInputType.number,
              enabled: !widget.isSaving,
              validator: (value) => _nonNegativeNumberValidator(value, l),
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _bathroomsController,
              label: l.bathrooms,
              keyboardType: TextInputType.number,
              enabled: !widget.isSaving,
              validator: (value) => _nonNegativeNumberValidator(value, l),
            ),
          ]),
          const SizedBox(height: AppSpacing.lg),
          _section(context, l.propertyLocationSection, [
            AppTextField(
              controller: _locationController,
              label: l.location,
              enabled: !widget.isSaving,
              validator: (value) => _requiredValidator(value, l),
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _compoundController,
              label: l.compound,
              enabled: !widget.isSaving,
            ),
          ]),
          const SizedBox(height: AppSpacing.lg),
          _section(context, l.propertyOwnerSection, [
            AppTextField(
              controller: _ownerNameController,
              label: l.ownerName,
              enabled: !widget.isSaving,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _ownerPhoneController,
              label: l.ownerPhone,
              keyboardType: TextInputType.phone,
              enabled: !widget.isSaving,
            ),
          ]),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: widget.submitLabel ?? l.createProperty,
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

  String? _positiveNumberValidator(String? value, AppLocalizations l) {
    if (value == null || value.trim().isEmpty) {
      return l.requiredField;
    }
    final number = num.tryParse(value.trim());
    if (number == null) {
      return l.enterValidNumber;
    }
    if (number <= 0) {
      return l.valueMustBePositive;
    }
    return null;
  }

  String? _nonNegativeNumberValidator(String? value, AppLocalizations l) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return null;
    }
    final number = int.tryParse(trimmed);
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

    final now = DateTime.now();
    final previous = widget.property;

    widget.onSubmit(
      Property(
        id: previous?.id ?? '',
        companyId: widget.companyId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        propertyType: _propertyType,
        listingType: _listingType,
        price: num.parse(_priceController.text.trim()),
        area: num.parse(_areaController.text.trim()),
        bedrooms: int.tryParse(_bedroomsController.text.trim()) ?? 0,
        bathrooms: int.tryParse(_bathroomsController.text.trim()) ?? 0,
        location: _locationController.text.trim(),
        compound: _compoundController.text.trim(),
        status: _status,
        ownerName: _ownerNameController.text.trim(),
        ownerPhone: _ownerPhoneController.text.trim(),
        assignedTo: previous?.assignedTo ?? '',
        imageUrls: previous?.imageUrls ?? const <String>[],
        createdAt: previous?.createdAt ?? now,
        updatedAt: now,
        createdBy: previous?.createdBy ?? widget.actorUid,
        updatedBy: widget.actorUid,
      ),
    );
  }
}
