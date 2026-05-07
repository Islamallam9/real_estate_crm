import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_status_badge.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/property.dart';
import 'property_labels.dart';

class PropertyCard extends StatelessWidget {
  const PropertyCard({
    super.key,
    required this.property,
    required this.canEdit,
    required this.canDeactivate,
    required this.onDeactivate,
  });

  final Property property;
  final bool canEdit;
  final bool canDeactivate;
  final ValueChanged<Property> onDeactivate;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    if (localizations == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.cardSurface(context),
        border: Border.all(color: AppColors.borderColor(context)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _displayText(localizations, property.title),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: AppStatusBadge(
                      label: propertyStatusLabel(
                        localizations,
                        property.status,
                      ),
                      tone: propertyStatusTone(property.status),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              _MetaChip(
                label:
                    '${propertyTypeLabel(localizations, property.propertyType)} / '
                    '${propertyListingTypeLabel(localizations, property.listingType)}',
              ),
              _MetaChip(label: _formatNumber(context, property.price)),
              _MetaChip(label: _displayText(localizations, property.location)),
            ],
          ),
          if (canEdit) ...[
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton.icon(
                onPressed: () =>
                    context.go(RouteNames.propertyDetails(property.id)),
                icon: const Icon(Icons.visibility_outlined),
                label: Text(localizations.details),
              ),
            ),
          ] else ...[
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton.icon(
                onPressed: () =>
                    context.go(RouteNames.propertyDetails(property.id)),
                icon: const Icon(Icons.visibility_outlined),
                label: Text(localizations.details),
              ),
            ),
          ],
          if (canEdit) ...[
            const SizedBox(height: AppSpacing.xs),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton.icon(
                onPressed: () => context.go(
                  RouteNames.propertyEdit(property.id),
                ),
                icon: const Icon(Icons.edit_outlined),
                label: Text(localizations.editProperty),
              ),
            ),
          ],
          if (canDeactivate && property.status != PropertyStatus.inactive) ...[
            const SizedBox(height: AppSpacing.xs),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton.icon(
                onPressed: () => onDeactivate(property),
                icon: const Icon(Icons.archive_outlined),
                label: Text(localizations.deactivateProperty),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: AppColors.appBackground(context),
        border: Border.all(color: AppColors.borderColor(context)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppColors.textSecondaryColor(context),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

String _displayText(AppLocalizations localizations, String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? localizations.notAvailable : trimmed;
}

String _formatNumber(BuildContext context, num value) {
  final localeName = Localizations.localeOf(context).toString();
  return NumberFormat.decimalPattern(localeName).format(value);
}
