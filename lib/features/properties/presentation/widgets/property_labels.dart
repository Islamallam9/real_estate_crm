import '../../../../core/widgets/app_status_badge.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/property.dart';

String propertyTypeLabel(
  AppLocalizations localizations,
  PropertyType propertyType,
) {
  return switch (propertyType) {
    PropertyType.apartment => localizations.apartment,
    PropertyType.villa => localizations.villa,
    PropertyType.office => localizations.office,
    PropertyType.shop => localizations.shop,
    PropertyType.land => localizations.land,
    PropertyType.studio => localizations.studio,
    PropertyType.duplex => localizations.duplex,
    PropertyType.penthouse => localizations.penthouse,
  };
}

String propertyListingTypeLabel(
  AppLocalizations localizations,
  PropertyListingType listingType,
) {
  return switch (listingType) {
    PropertyListingType.sale => localizations.sale,
    PropertyListingType.rent => localizations.rent,
  };
}

String propertyStatusLabel(
  AppLocalizations localizations,
  PropertyStatus status,
) {
  return switch (status) {
    PropertyStatus.available => localizations.available,
    PropertyStatus.reserved => localizations.reserved,
    PropertyStatus.sold => localizations.sold,
    PropertyStatus.rented => localizations.rented,
    PropertyStatus.inactive => localizations.inactive,
  };
}

AppStatusTone propertyStatusTone(PropertyStatus status) {
  return switch (status) {
    PropertyStatus.available => AppStatusTone.success,
    PropertyStatus.reserved => AppStatusTone.warning,
    PropertyStatus.sold => AppStatusTone.info,
    PropertyStatus.rented => AppStatusTone.info,
    PropertyStatus.inactive => AppStatusTone.neutral,
  };
}
