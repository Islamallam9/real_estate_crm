import 'package:equatable/equatable.dart';

import '../../../../core/stats/module_kpi_counts_data_source.dart';

import '../../domain/entities/property.dart';

enum PropertiesStatus { initial, loading, loadingMore, loaded, saving, saved, empty, failure }

enum PropertiesAction { none, createProperty, updateProperty, deactivateProperty }

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
    this.pageLimit = 15,
    this.kpiCounts = const ModuleKpiCounts.empty(),
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
      pageLimit = 15,
      kpiCounts = const ModuleKpiCounts.empty(),
      lastAction = PropertiesAction.none;

  final PropertiesStatus status;
  final List<Property> properties;
  final List<Property> filteredProperties;
  final String searchQuery;
  final PropertyType? propertyTypeFilter;
  final PropertyListingType? listingTypeFilter;
  final PropertyStatus? statusFilter;
  final String? message;
  final int pageLimit;
  final ModuleKpiCounts kpiCounts;
  bool get hasLocalFilters {
    return searchQuery.trim().isNotEmpty ||
        propertyTypeFilter != null ||
        listingTypeFilter != null ||
        statusFilter != null;
  }

  int? get filteredTotalCount {
    if (searchQuery.trim().isNotEmpty ||
        propertyTypeFilter != null ||
        listingTypeFilter != null) {
      return null;
    }
    final status = statusFilter;
    if (status == null) {
      return kpiCounts.valueOrNull('total');
    }
    return switch (status) {
      PropertyStatus.available => kpiCounts.valueOrNull('available'),
      PropertyStatus.reserved => kpiCounts.valueOrNull('reserved'),
      PropertyStatus.sold => kpiCounts.valueOrNull('sold'),
      PropertyStatus.rented => kpiCounts.valueOrNull('rented'),
      PropertyStatus.inactive => null,
    };
  }

  bool get canLoadMore {
    if (hasLocalFilters) {
      return false;
    }
    final total = filteredTotalCount;
    if (total != null) {
      return filteredProperties.length < total;
    }
    return false;
  }
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
    int? pageLimit,
    ModuleKpiCounts? kpiCounts,
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
      pageLimit: pageLimit ?? this.pageLimit,
      kpiCounts: kpiCounts ?? this.kpiCounts,
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
    pageLimit,
    kpiCounts,
    lastAction,
  ];
}
