import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/property.dart';

class PropertyModel extends Property {
  const PropertyModel({
    required super.id,
    required super.companyId,
    required super.title,
    required super.description,
    required super.propertyType,
    required super.listingType,
    required super.price,
    required super.area,
    required super.bedrooms,
    required super.bathrooms,
    required super.location,
    required super.compound,
    required super.status,
    required super.ownerName,
    required super.ownerPhone,
    required super.assignedTo,
    required super.imageUrls,
    required super.coverImageUrl,
    required super.imageStoragePaths,
    required super.createdAt,
    required super.updatedAt,
    required super.createdBy,
    required super.updatedBy,
    super.isArchived,
    super.archivedAt,
    super.archivedBy,
    super.archivedByName,
    super.archiveReason,
    super.restoredAt,
    super.restoredBy,
    super.restoredByName,
  });

  factory PropertyModel.fromEntity(Property property) {
    return PropertyModel(
      id: property.id,
      companyId: property.companyId,
      title: property.title,
      description: property.description,
      propertyType: property.propertyType,
      listingType: property.listingType,
      price: property.price,
      area: property.area,
      bedrooms: property.bedrooms,
      bathrooms: property.bathrooms,
      location: property.location,
      compound: property.compound,
      status: property.status,
      ownerName: property.ownerName,
      ownerPhone: property.ownerPhone,
      assignedTo: property.assignedTo,
      imageUrls: property.imageUrls,
      coverImageUrl: property.coverImageUrl,
      imageStoragePaths: property.imageStoragePaths,
      createdAt: property.createdAt,
      updatedAt: property.updatedAt,
      createdBy: property.createdBy,
      updatedBy: property.updatedBy,
      isArchived: property.isArchived,
      archivedAt: property.archivedAt,
      archivedBy: property.archivedBy,
      archivedByName: property.archivedByName,
      archiveReason: property.archiveReason,
      restoredAt: property.restoredAt,
      restoredBy: property.restoredBy,
      restoredByName: property.restoredByName,
    );
  }

  factory PropertyModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    if (data == null) {
      throw StateError('Property data was not found.');
    }

    return PropertyModel(
      id: _stringFromValue(data['id'], fallback: document.id),
      companyId: _companyIdFromDataOrPath(
        data['companyId'],
        document.reference.path,
      ),
      title: _stringFromValue(data['title']),
      description: _stringFromValue(data['description']),
      propertyType: propertyTypeFromValue(
        _stringFromValue(data['propertyType'], fallback: 'apartment'),
      ),
      listingType: propertyListingTypeFromValue(
        _stringFromValue(data['listingType'], fallback: 'sale'),
      ),
      price: _numFromValue(data['price']),
      area: _numFromValue(data['area']),
      bedrooms: _intFromValue(data['bedrooms']),
      bathrooms: _intFromValue(data['bathrooms']),
      location: _stringFromValue(data['location']),
      compound: _stringFromValue(data['compound']),
      status: propertyStatusFromValue(
        _stringFromValue(data['status'], fallback: 'available'),
      ),
      ownerName: _stringFromValue(data['ownerName']),
      ownerPhone: _stringFromValue(data['ownerPhone']),
      assignedTo: _stringFromValue(data['assignedTo']),
      imageUrls: _stringListFromValue(data['imageUrls']),
      coverImageUrl: _coverImageUrlFromValue(
        data['coverImageUrl'],
        data['imageUrls'],
      ),
      imageStoragePaths: _stringListFromValue(data['imageStoragePaths']),
      createdAt: _dateTimeFromValue(data['createdAt']),
      updatedAt: _dateTimeFromValue(data['updatedAt']),
      createdBy: _stringFromValue(data['createdBy']),
      updatedBy: _stringFromValue(data['updatedBy']),
      isArchived: _boolFromValue(data['isArchived']),
      archivedAt: _nullableDateTimeFromValue(data['archivedAt']),
      archivedBy: _stringFromValue(data['archivedBy']),
      archivedByName: _stringFromValue(data['archivedByName']),
      archiveReason: _stringFromValue(data['archiveReason']),
      restoredAt: _nullableDateTimeFromValue(data['restoredAt']),
      restoredBy: _stringFromValue(data['restoredBy']),
      restoredByName: _stringFromValue(data['restoredByName']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'companyId': companyId,
      'title': title,
      'description': description,
      'propertyType': propertyTypeToValue(propertyType),
      'listingType': propertyListingTypeToValue(listingType),
      'price': price,
      'area': area,
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'location': location,
      'compound': compound,
      'status': propertyStatusToValue(status),
      'ownerName': ownerName,
      'ownerPhone': ownerPhone,
      'assignedTo': assignedTo,
      'imageUrls': imageUrls,
      'coverImageUrl': coverImageUrl,
      'imageStoragePaths': imageStoragePaths,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'createdBy': createdBy,
      'updatedBy': updatedBy,
      'isArchived': isArchived,
      'archivedAt': archivedAt == null ? null : Timestamp.fromDate(archivedAt!),
      'archivedBy': archivedBy,
      'archivedByName': archivedByName,
      'archiveReason': archiveReason,
      'restoredAt': restoredAt == null ? null : Timestamp.fromDate(restoredAt!),
      'restoredBy': restoredBy,
      'restoredByName': restoredByName,
    };
  }
}

PropertyType propertyTypeFromValue(String value) {
  switch (value) {
    case 'apartment':
      return PropertyType.apartment;
    case 'villa':
      return PropertyType.villa;
    case 'office':
      return PropertyType.office;
    case 'shop':
      return PropertyType.shop;
    case 'land':
      return PropertyType.land;
    case 'studio':
      return PropertyType.studio;
    case 'duplex':
      return PropertyType.duplex;
    case 'penthouse':
      return PropertyType.penthouse;
    default:
      return PropertyType.apartment;
  }
}

String propertyTypeToValue(PropertyType propertyType) {
  switch (propertyType) {
    case PropertyType.apartment:
      return 'apartment';
    case PropertyType.villa:
      return 'villa';
    case PropertyType.office:
      return 'office';
    case PropertyType.shop:
      return 'shop';
    case PropertyType.land:
      return 'land';
    case PropertyType.studio:
      return 'studio';
    case PropertyType.duplex:
      return 'duplex';
    case PropertyType.penthouse:
      return 'penthouse';
  }
}

PropertyListingType propertyListingTypeFromValue(String value) {
  switch (value) {
    case 'sale':
      return PropertyListingType.sale;
    case 'rent':
      return PropertyListingType.rent;
    default:
      return PropertyListingType.sale;
  }
}

String propertyListingTypeToValue(PropertyListingType listingType) {
  switch (listingType) {
    case PropertyListingType.sale:
      return 'sale';
    case PropertyListingType.rent:
      return 'rent';
  }
}

PropertyStatus propertyStatusFromValue(String value) {
  switch (value) {
    case 'available':
      return PropertyStatus.available;
    case 'reserved':
      return PropertyStatus.reserved;
    case 'sold':
      return PropertyStatus.sold;
    case 'rented':
      return PropertyStatus.rented;
    case 'inactive':
      return PropertyStatus.inactive;
    default:
      return PropertyStatus.available;
  }
}

String propertyStatusToValue(PropertyStatus status) {
  switch (status) {
    case PropertyStatus.available:
      return 'available';
    case PropertyStatus.reserved:
      return 'reserved';
    case PropertyStatus.sold:
      return 'sold';
    case PropertyStatus.rented:
      return 'rented';
    case PropertyStatus.inactive:
      return 'inactive';
  }
}

String _stringFromValue(Object? value, {String fallback = ''}) {
  if (value is String) {
    return value.trim();
  }

  return fallback;
}

String _companyIdFromDataOrPath(Object? value, String path) {
  final companyId = _stringFromValue(value);
  if (companyId.isNotEmpty) {
    return companyId;
  }

  final segments = path.split('/');
  final companySegmentIndex = segments.indexOf('companies');
  if (companySegmentIndex >= 0 && companySegmentIndex + 1 < segments.length) {
    return segments[companySegmentIndex + 1];
  }

  return '';
}

num _numFromValue(Object? value) {
  if (value is num) {
    return value;
  }

  if (value is String) {
    return num.tryParse(value.trim()) ?? 0;
  }

  return 0;
}

bool _boolFromValue(Object? value) {
  if (value is bool) {
    return value;
  }

  if (value is String) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'true') {
      return true;
    }
    if (normalized == 'false') {
      return false;
    }
  }

  return false;
}

DateTime _dateTimeFromValue(Object? value) {
  if (value is Timestamp) {
    return value.toDate();
  }

  if (value is DateTime) {
    return value;
  }

  return DateTime.fromMillisecondsSinceEpoch(0);
}

DateTime? _nullableDateTimeFromValue(Object? value) {
  if (value == null) {
    return null;
  }
  return _dateTimeFromValue(value);
}

List<String> _stringListFromValue(Object? value) {
  if (value is Iterable) {
    return value.whereType<String>().toList();
  }

  return const [];
}

int _intFromValue(Object? value) {
  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  return 0;
}


String? _coverImageUrlFromValue(Object? coverImageUrl, Object? imageUrls) {
  if (coverImageUrl is String && coverImageUrl.trim().isNotEmpty) {
    return coverImageUrl.trim();
  }

  final urls = _stringListFromValue(imageUrls);
  for (final url in urls) {
    final trimmedUrl = url.trim();
    if (trimmedUrl.isNotEmpty) {
      return trimmedUrl;
    }
  }

  return null;
}
