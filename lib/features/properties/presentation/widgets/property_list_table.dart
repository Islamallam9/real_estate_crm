import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_status_badge.dart';
import '../../../../core/widgets/app_scroll_surface.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/property.dart';
import 'property_labels.dart';

class PropertyListTable extends StatelessWidget {
  const PropertyListTable({
    super.key,
    required this.properties,
    required this.canEdit,
    required this.canDeactivate,
    required this.onDeactivate,
  });

  final List<Property> properties;
  final bool canEdit;
  final bool canDeactivate;
  final ValueChanged<Property> onDeactivate;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    if (localizations == null) {
      return const SizedBox.shrink();
    }

    return AppHorizontalScrollView(
      minWidth: 1180,
      child: Container(
        decoration: BoxDecoration(
        color: AppColors.cardSurface(context),
        border: Border.all(color: AppColors.borderColor(context)),
        borderRadius: AppRadius.large,
        boxShadow: Theme.of(context).brightness == Brightness.dark
            ? null
            : AppShadows.card,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _TableHeader(
            localizations: localizations,
            canEdit: canEdit,
            canDeactivate: canDeactivate,
          ),
          Divider(height: 1, color: AppColors.borderColor(context)),
          Expanded(
            child: ListView.separated(
              itemCount: properties.length,
              separatorBuilder: (context, index) =>
                  Divider(height: 1, color: AppColors.borderColor(context)),
              itemBuilder: (context, index) {
                return _PropertyTableRow(
                  property: properties[index],
                  canEdit: canEdit,
                  canDeactivate: canDeactivate,
                  onDeactivate: onDeactivate,
                );
              },
            ),
          ),
          ],
        ),
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader({
    required this.localizations,
    required this.canEdit,
    required this.canDeactivate,
  });

  final AppLocalizations localizations;
  final bool canEdit;
  final bool canDeactivate;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          _HeaderText(localizations.propertyTitle, flex: 3),
          _HeaderText(localizations.propertyType, flex: 2),
          _HeaderText(localizations.listingType, flex: 2),
          _HeaderText(localizations.price, flex: 2),
          _HeaderText(localizations.area, flex: 1),
          _HeaderText(localizations.location, flex: 2),
          _HeaderText(localizations.status, flex: 2),
          _HeaderText(
            localizations.actions,
            flex: (canEdit || canDeactivate) ? 2 : 1,
          ),
        ],
      ),
    );
  }
}

class _PropertyTableRow extends StatelessWidget {
  const _PropertyTableRow({
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

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          _BodyText(_displayText(localizations, property.title), flex: 3),
          _BodyText(
            propertyTypeLabel(localizations, property.propertyType),
            flex: 2,
          ),
          _BodyText(
            propertyListingTypeLabel(localizations, property.listingType),
            flex: 2,
          ),
          _BodyText(_formatNumber(context, property.price), flex: 2),
          _BodyText(_formatNumber(context, property.area), flex: 1),
          _BodyText(_displayText(localizations, property.location), flex: 2),
          Expanded(
            flex: 2,
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: AppStatusBadge(
                  label: propertyStatusLabel(localizations, property.status),
                  tone: propertyStatusTone(property.status),
                ),
              ),
            ),
          ),
          Expanded(
            flex: (canEdit || canDeactivate) ? 2 : 1,
            child: Wrap(
              spacing: 4,
              children: [
                IconButton(
                  tooltip: localizations.details,
                  onPressed: () =>
                      context.go(RouteNames.propertyDetails(property.id)),
                  icon: const Icon(Icons.visibility_outlined, size: 18),
                ),
                if (canEdit)
                  IconButton(
                    tooltip: localizations.editProperty,
                    onPressed: () =>
                        context.go(RouteNames.propertyEdit(property.id)),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                  ),
                if (canDeactivate && property.status != PropertyStatus.inactive)
                  IconButton(
                    tooltip: localizations.deactivateProperty,
                    onPressed: () => onDeactivate(property),
                    icon: const Icon(Icons.archive_outlined, size: 18),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderText extends StatelessWidget {
  const _HeaderText(this.value, {required this.flex});

  final String value;
  final int flex;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        softWrap: false,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: AppColors.textSecondaryColor(context),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _BodyText extends StatelessWidget {
  const _BodyText(this.value, {required this.flex});

  final String value;
  final int flex;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsetsDirectional.only(end: AppSpacing.sm),
        child: Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          softWrap: false,
          style: Theme.of(context).textTheme.bodyMedium,
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
