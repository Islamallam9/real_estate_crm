import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_dropdown.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/property.dart';
import '../../domain/entities/property_image_upload.dart';
import 'property_labels.dart';

typedef PropertyFormSubmit = void Function(
    Property property, {
    List<PropertyImageUpload> newImages,
    List<String> removedImageStoragePaths,
    });

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
  final PropertyFormSubmit onSubmit;
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

  static const int _maxImageBytes = 5 * 1024 * 1024;
  static const int _maxOriginalImageBytes = 20 * 1024 * 1024;

  PropertyType _propertyType = PropertyType.apartment;
  PropertyListingType _listingType = PropertyListingType.sale;
  PropertyStatus _status = PropertyStatus.available;
  List<String> _existingImageUrls = const [];
  List<String> _existingImageStoragePaths = const [];
  final List<String> _removedImageStoragePaths = [];
  final List<_PendingPropertyImage> _pendingImages = [];
  bool _isPickingImages = false;

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
    _existingImageUrls = List<String>.from(property.imageUrls);
    _existingImageStoragePaths = List<String>.from(property.imageStoragePaths);
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
    final isBusy = widget.isSaving || _isPickingImages;
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _section(context, l.propertyBasicInformation, [
            AppTextField(
              controller: _titleController,
              label: l.propertyTitle,
              enabled: !isBusy,
              validator: (value) => _requiredValidator(value, l),
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _descriptionController,
              label: l.description,
              enabled: !isBusy,
              maxLines: 3,
            ),
            const SizedBox(height: AppSpacing.md),
            AppDropdown<PropertyType>(
              label: l.propertyType,
              value: _propertyType,
              enabled: !isBusy,
              items: PropertyType.values,
              itemLabelBuilder: (value) => propertyTypeLabel(l, value),
              onChanged: (value) => setState(() => _propertyType = value),
            ),
            const SizedBox(height: AppSpacing.md),
            AppDropdown<PropertyListingType>(
              label: l.listingType,
              value: _listingType,
              enabled: !isBusy,
              items: PropertyListingType.values,
              itemLabelBuilder: (value) => propertyListingTypeLabel(l, value),
              onChanged: (value) => setState(() => _listingType = value),
            ),
            const SizedBox(height: AppSpacing.md),
            AppDropdown<PropertyStatus>(
              label: l.status,
              value: _status,
              enabled: !isBusy,
              items: PropertyStatus.values,
              itemLabelBuilder: (value) => propertyStatusLabel(l, value),
              onChanged: (value) => setState(() => _status = value),
            ),
          ]),
          const SizedBox(height: AppSpacing.lg),
          _section(context, l.propertyImages, [
            _PropertyImagesPicker(
              existingImageUrls: _existingImageUrls,
              pendingImages: _pendingImages,
              isBusy: isBusy,
              onPickImages: _pickImages,
              onRemoveExisting: _removeExistingImage,
              onRemovePending: _removePendingImage,
            ),
          ]),
          const SizedBox(height: AppSpacing.lg),
          _section(context, l.propertyMetrics, [
            AppTextField(
              controller: _priceController,
              label: l.price,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              enabled: !isBusy,
              validator: (value) => _positiveNumberValidator(value, l),
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _areaController,
              label: l.area,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              enabled: !isBusy,
              validator: (value) => _positiveNumberValidator(value, l),
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _bedroomsController,
              label: l.bedrooms,
              keyboardType: TextInputType.number,
              enabled: !isBusy,
              validator: (value) => _nonNegativeNumberValidator(value, l),
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _bathroomsController,
              label: l.bathrooms,
              keyboardType: TextInputType.number,
              enabled: !isBusy,
              validator: (value) => _nonNegativeNumberValidator(value, l),
            ),
          ]),
          const SizedBox(height: AppSpacing.lg),
          _section(context, l.propertyLocationSection, [
            AppTextField(
              controller: _locationController,
              label: l.location,
              enabled: !isBusy,
              validator: (value) => _requiredValidator(value, l),
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _compoundController,
              label: l.compound,
              enabled: !isBusy,
            ),
          ]),
          const SizedBox(height: AppSpacing.lg),
          _section(context, l.propertyOwnerSection, [
            AppTextField(
              controller: _ownerNameController,
              label: l.ownerName,
              enabled: !isBusy,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _ownerPhoneController,
              label: l.ownerPhone,
              keyboardType: TextInputType.phone,
              enabled: !isBusy,
            ),
          ]),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: widget.submitLabel ?? l.createProperty,
            isLoading: widget.isSaving,
            onPressed: isBusy ? null : _submit,
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

  Future<void> _pickImages() async {
    final l = AppLocalizations.of(context)!;
    setState(() => _isPickingImages = true);

    try {
      final result = await FilePicker.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        return;
      }

      final pickedFile = result.files.first;
      final bytes = pickedFile.bytes;

      if (bytes == null || bytes.isEmpty) {
        if (mounted) {
          AppFeedback.error(context, l.unableToPickPropertyImages);
        }
        return;
      }

      final contentType = _contentTypeForFileName(pickedFile.name);
      if (!contentType.startsWith('image/')) {
        if (mounted) {
          AppFeedback.warning(context, l.propertyImageInvalidType);
        }
        return;
      }

      if (bytes.lengthInBytes > _maxOriginalImageBytes) {
        if (mounted) {
          AppFeedback.warning(context, l.propertyImageTooLarge);
        }
        return;
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _pendingImages.add(
          _PendingPropertyImage(
            fileName: pickedFile.name.isNotEmpty
                ? pickedFile.name
                : 'property_image_${DateTime.now().microsecondsSinceEpoch}.jpg',
            bytes: bytes,
            contentType: contentType,
          ),
        );
      });
    } catch (error, stackTrace) {
      debugPrint('Property image pick failed: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (mounted) {
        AppFeedback.error(context, l.unableToPickPropertyImages);
      }
    } finally {
      if (mounted) {
        setState(() => _isPickingImages = false);
      }
    }
  }

  void _removeExistingImage(int index) {
    if (index < 0 || index >= _existingImageUrls.length) {
      return;
    }

    setState(() {
      _existingImageUrls.removeAt(index);
      if (index < _existingImageStoragePaths.length) {
        final storagePath = _existingImageStoragePaths.removeAt(index).trim();
        if (storagePath.isNotEmpty) {
          _removedImageStoragePaths.add(storagePath);
        }
      }
    });
  }

  void _removePendingImage(int index) {
    if (index < 0 || index >= _pendingImages.length) {
      return;
    }

    setState(() => _pendingImages.removeAt(index));
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

    final l = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final previous = widget.property;
    final retainedCoverImageUrl = _resolveRetainedCoverImageUrl(
      previousCoverImageUrl: previous?.coverImageUrl,
      retainedImageUrls: _existingImageUrls,
    );

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
        imageUrls: List<String>.unmodifiable(_existingImageUrls),
        coverImageUrl: retainedCoverImageUrl,
        imageStoragePaths: List<String>.unmodifiable(_existingImageStoragePaths),
        createdAt: previous?.createdAt ?? now,
        updatedAt: now,
        createdBy: previous?.createdBy ?? widget.actorUid,
        updatedBy: widget.actorUid,
      ),
      newImages: _pendingImages
          .map(
            (image) => PropertyImageUpload(
          fileName: image.fileName,
          bytes: image.bytes,
          contentType: image.contentType,
        ),
      )
          .toList(growable: false),
      removedImageStoragePaths: List<String>.unmodifiable(
        _removedImageStoragePaths,
      ),
    );
  }
}

class _PropertyImagesPicker extends StatelessWidget {
  const _PropertyImagesPicker({
    required this.existingImageUrls,
    required this.pendingImages,
    required this.isBusy,
    required this.onPickImages,
    required this.onRemoveExisting,
    required this.onRemovePending,
  });

  final List<String> existingImageUrls;
  final List<_PendingPropertyImage> pendingImages;
  final bool isBusy;
  final VoidCallback onPickImages;
  final ValueChanged<int> onRemoveExisting;
  final ValueChanged<int> onRemovePending;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final hasImages = existingImageUrls.isNotEmpty || pendingImages.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l.propertyImagesHint,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondaryColor(context),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: AppButton(
            label: l.addPropertyImages,
            icon: Icons.add_photo_alternate_outlined,
            variant: AppButtonVariant.secondary,
            isLoading: isBusy,
            onPressed: isBusy ? null : onPickImages,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (!hasImages)
          _PropertyImagePlaceholder(label: l.noPropertyImagesYet)
        else
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (var index = 0; index < existingImageUrls.length; index += 1)
                _PropertyImageTile(
                  image: Image.network(
                    existingImageUrls[index],
                    fit: BoxFit.cover,
                    webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
                    errorBuilder: (context, error, stackTrace) => Icon(
                      Icons.broken_image_outlined,
                      color: AppColors.textMutedColor(context),
                    ),
                  ),
                  onRemove: isBusy ? null : () => onRemoveExisting(index),
                ),
              for (var index = 0; index < pendingImages.length; index += 1)
                _PropertyImageTile(
                  image: Image.memory(
                    pendingImages[index].bytes,
                    fit: BoxFit.cover,
                    cacheWidth: 236,
                    cacheHeight: 184,
                  ),
                  badge: l.newImage,
                  onRemove: isBusy ? null : () => onRemovePending(index),
                ),
            ],
          ),
      ],
    );
  }
}

class _PropertyImageTile extends StatelessWidget {
  const _PropertyImageTile({required this.image, this.badge, this.onRemove});

  final Image image;
  final String? badge;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 118,
      height: 92,
      child: ClipRRect(
        borderRadius: AppRadius.medium,
        child: Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(color: AppColors.appBackground(context)),
              child: image,
            ),
            if (badge != null)
              PositionedDirectional(
                start: 6,
                bottom: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.cardSurface(context).withValues(alpha: 0.9),
                    borderRadius: AppRadius.large,
                  ),
                  child: Text(
                    badge!,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            PositionedDirectional(
              top: 4,
              end: 4,
              child: IconButton.filledTonal(
                tooltip: AppLocalizations.of(context)!.removeImage,
                onPressed: onRemove,
                icon: const Icon(Icons.close, size: 16),
                constraints: const BoxConstraints.tightFor(width: 32, height: 32),
                padding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PropertyImagePlaceholder extends StatelessWidget {
  const _PropertyImagePlaceholder({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 96,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.appBackground(context),
        border: Border.all(color: AppColors.borderColor(context)),
        borderRadius: AppRadius.medium,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.image_outlined,
            color: AppColors.textMutedColor(context),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondaryColor(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingPropertyImage {
  const _PendingPropertyImage({
    required this.fileName,
    required this.bytes,
    required this.contentType,
  });

  final String fileName;
  final Uint8List bytes;
  final String contentType;
}


String _contentTypeForFileName(String fileName) {
  final lowerName = fileName.toLowerCase();

  if (lowerName.endsWith('.png')) {
    return 'image/png';
  }

  if (lowerName.endsWith('.webp')) {
    return 'image/webp';
  }

  if (lowerName.endsWith('.gif')) {
    return 'image/gif';
  }

  if (lowerName.endsWith('.heic') || lowerName.endsWith('.heif')) {
    return 'image/heic';
  }

  return 'image/jpeg';
}

String? _resolveRetainedCoverImageUrl({
  required String? previousCoverImageUrl,
  required List<String> retainedImageUrls,
}) {
  final trimmedCover = previousCoverImageUrl?.trim();
  if (trimmedCover != null &&
      trimmedCover.isNotEmpty &&
      retainedImageUrls.contains(trimmedCover)) {
    return trimmedCover;
  }

  for (final imageUrl in retainedImageUrls) {
    final trimmedUrl = imageUrl.trim();
    if (trimmedUrl.isNotEmpty) {
      return trimmedUrl;
    }
  }

  return null;
}
