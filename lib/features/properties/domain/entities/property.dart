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
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    required this.updatedBy,
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
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;
  final String updatedBy;

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
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
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
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
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
    createdAt,
    updatedAt,
    createdBy,
    updatedBy,
  ];
}
