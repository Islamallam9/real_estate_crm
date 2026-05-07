import 'package:equatable/equatable.dart';

import '../../domain/entities/property.dart';

enum PropertiesStatus { initial, loading, loaded, saving, saved, empty, failure }

enum PropertiesAction { none, createProperty, updateProperty }

class PropertiesState extends Equatable {
  const PropertiesState({
    required this.status,
    this.properties = const [],
    this.filteredProperties = const [],
    this.searchQuery = '',
    this.propertyTypeFilter,
    this.listingTypeFilter,
    this.statusFilter,
    this.message,
    this.lastAction = PropertiesAction.none,
  });

  const PropertiesState.initial()
    : status = PropertiesStatus.initial,
      properties = const [],
      filteredProperties = const [],
      searchQuery = '',
      propertyTypeFilter = null,
      listingTypeFilter = null,
      statusFilter = null,
      message = null,
      lastAction = PropertiesAction.none;

  final PropertiesStatus status;
  final List<Property> properties;
  final List<Property> filteredProperties;
  final String searchQuery;
  final PropertyType? propertyTypeFilter;
  final PropertyListingType? listingTypeFilter;
  final PropertyStatus? statusFilter;
  final String? message;
  final PropertiesAction lastAction;

  PropertiesState copyWith({
    PropertiesStatus? status,
    List<Property>? properties,
    List<Property>? filteredProperties,
    String? searchQuery,
    PropertyType? propertyTypeFilter,
    PropertyListingType? listingTypeFilter,
    PropertyStatus? statusFilter,
    String? message,
    PropertiesAction? lastAction,
    bool clearMessage = false,
    bool clearLastAction = false,
    bool clearPropertyTypeFilter = false,
    bool clearListingTypeFilter = false,
    bool clearStatusFilter = false,
  }) {
    return PropertiesState(
      status: status ?? this.status,
      properties: properties ?? this.properties,
      filteredProperties: filteredProperties ?? this.filteredProperties,
      searchQuery: searchQuery ?? this.searchQuery,
      propertyTypeFilter: clearPropertyTypeFilter
          ? null
          : propertyTypeFilter ?? this.propertyTypeFilter,
      listingTypeFilter: clearListingTypeFilter
          ? null
          : listingTypeFilter ?? this.listingTypeFilter,
      statusFilter: clearStatusFilter ? null : statusFilter ?? this.statusFilter,
      message: clearMessage ? null : message ?? this.message,
      lastAction: clearLastAction
          ? PropertiesAction.none
          : lastAction ?? this.lastAction,
    );
  }

  @override
  List<Object?> get props => [
    status,
    properties,
    filteredProperties,
    searchQuery,
    propertyTypeFilter,
    listingTypeFilter,
    statusFilter,
    message,
    lastAction,
  ];
}
