import 'package:equatable/equatable.dart';

enum PropertyType {
  apartment,
  villa,
  office,
  shop,
  land,
  studio,
  duplex,
  penthouse,
}

enum PropertyListingType { sale, rent }

enum PropertyStatus { available, reserved, sold, rented, inactive }

class Property extends Equatable {
  const Property({
    required this.id,
    required this.companyId,
    required this.title,
    required this.description,
    required this.propertyType,
    required this.listingType,
    required this.price,
    required this.area,
    required this.bedrooms,
    required this.bathrooms,
    required this.location,
    required this.compound,
    required this.status,
    required this.ownerName,
    required this.ownerPhone,
    required this.assignedTo,
    required this.imageUrls,
    required this.coverImageUrl,
    required this.imageStoragePaths,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    required this.updatedBy,
    this.isArchived = false,
    this.archivedAt,
    this.archivedBy = '',
    this.archivedByName = '',
    this.archiveReason = '',
    this.restoredAt,
    this.restoredBy = '',
    this.restoredByName = '',
  });

  final String id;
  final String companyId;
  final String title;
  final String description;
  final PropertyType propertyType;
  final PropertyListingType listingType;
  final num price;
  final num area;
  final int bedrooms;
  final int bathrooms;
  final String location;
  final String compound;
  final PropertyStatus status;
  final String ownerName;
  final String ownerPhone;
  final String assignedTo;
  final List<String> imageUrls;
  final String? coverImageUrl;
  final List<String> imageStoragePaths;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;
  final String updatedBy;
  final bool isArchived;
  final DateTime? archivedAt;
  final String archivedBy;
  final String archivedByName;
  final String archiveReason;
  final DateTime? restoredAt;
  final String restoredBy;
  final String restoredByName;

  String? get effectiveCoverImageUrl {
    final trimmedCover = coverImageUrl?.trim();
    if (trimmedCover != null && trimmedCover.isNotEmpty) {
      return trimmedCover;
    }

    for (final imageUrl in imageUrls) {
      final trimmedUrl = imageUrl.trim();
      if (trimmedUrl.isNotEmpty) {
        return trimmedUrl;
      }
    }

    return null;
  }

  Property copyWith({
    String? id,
    String? companyId,
    String? title,
    String? description,
    PropertyType? propertyType,
    PropertyListingType? listingType,
    num? price,
    num? area,
    int? bedrooms,
    int? bathrooms,
    String? location,
    String? compound,
    PropertyStatus? status,
    String? ownerName,
    String? ownerPhone,
    String? assignedTo,
    List<String>? imageUrls,
    String? coverImageUrl,
    List<String>? imageStoragePaths,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
    bool? isArchived,
    DateTime? archivedAt,
    String? archivedBy,
    String? archivedByName,
    String? archiveReason,
    DateTime? restoredAt,
    String? restoredBy,
    String? restoredByName,
    bool clearCoverImageUrl = false,
  }) {
    return Property(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      title: title ?? this.title,
      description: description ?? this.description,
      propertyType: propertyType ?? this.propertyType,
      listingType: listingType ?? this.listingType,
      price: price ?? this.price,
      area: area ?? this.area,
      bedrooms: bedrooms ?? this.bedrooms,
      bathrooms: bathrooms ?? this.bathrooms,
      location: location ?? this.location,
      compound: compound ?? this.compound,
      status: status ?? this.status,
      ownerName: ownerName ?? this.ownerName,
      ownerPhone: ownerPhone ?? this.ownerPhone,
      assignedTo: assignedTo ?? this.assignedTo,
      imageUrls: imageUrls ?? this.imageUrls,
      coverImageUrl: clearCoverImageUrl
          ? null
          : coverImageUrl ?? this.coverImageUrl,
      imageStoragePaths: imageStoragePaths ?? this.imageStoragePaths,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      isArchived: isArchived ?? this.isArchived,
      archivedAt: archivedAt ?? this.archivedAt,
      archivedBy: archivedBy ?? this.archivedBy,
      archivedByName: archivedByName ?? this.archivedByName,
      archiveReason: archiveReason ?? this.archiveReason,
      restoredAt: restoredAt ?? this.restoredAt,
      restoredBy: restoredBy ?? this.restoredBy,
      restoredByName: restoredByName ?? this.restoredByName,
    );
  }

  @override
  List<Object?> get props => [
    id,
    companyId,
    title,
    description,
    propertyType,
    listingType,
    price,
    area,
    bedrooms,
    bathrooms,
    location,
    compound,
    status,
    ownerName,
    ownerPhone,
    assignedTo,
    imageUrls,
    coverImageUrl,
    imageStoragePaths,
    createdAt,
    updatedAt,
    createdBy,
    updatedBy,
    isArchived,
    archivedAt,
    archivedBy,
    archivedByName,
    archiveReason,
    restoredAt,
    restoredBy,
    restoredByName,
  ];
}
