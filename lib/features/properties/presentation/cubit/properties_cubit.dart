import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/error_mapper.dart';
import '../../domain/entities/property.dart';
import '../../domain/errors/property_exception.dart';
import '../../domain/usecases/create_property_usecase.dart';
import '../../domain/usecases/update_property_usecase.dart';
import '../../domain/usecases/watch_properties_usecase.dart';
import 'properties_state.dart';

class PropertiesCubit extends Cubit<PropertiesState> {
  PropertiesCubit({
    required WatchPropertiesUseCase watchPropertiesUseCase,
    required CreatePropertyUseCase createPropertyUseCase,
    required UpdatePropertyUseCase updatePropertyUseCase,
  }) : _watchPropertiesUseCase = watchPropertiesUseCase,
       _createPropertyUseCase = createPropertyUseCase,
       _updatePropertyUseCase = updatePropertyUseCase,
       super(const PropertiesState.initial());

  final WatchPropertiesUseCase _watchPropertiesUseCase;
  final CreatePropertyUseCase _createPropertyUseCase;
  final UpdatePropertyUseCase _updatePropertyUseCase;

  StreamSubscription<List<Property>>? _propertiesSubscription;
  static const Duration _firebaseTimeout = Duration(seconds: 10);

  Future<bool> _hasConnection() async {
    final results = await Connectivity().checkConnectivity();
    return results.any((result) => result != ConnectivityResult.none);
  }

  Future<T> _guardFirebaseAction<T>(Future<T> Function() action) async {
    final connected = await _hasConnection();

    if (!connected) {
      throw const PropertyException(AppErrorMessages.unableToConnect);
    }

    return action().timeout(
      _firebaseTimeout,
      onTimeout: () {
        throw const PropertyException(AppErrorMessages.unableToConnect);
      },
    );
  }

  void watchProperties({required String companyId}) {
    emit(
      state.copyWith(
        status: PropertiesStatus.loading,
        clearMessage: true,
        clearLastAction: true,
      ),
    );
    _propertiesSubscription?.cancel();
    _propertiesSubscription = _watchPropertiesUseCase(companyId: companyId)
        .listen(
          (properties) {
            if (isClosed) {
              return;
            }
            emit(
              state.copyWith(
                status: properties.isEmpty
                    ? PropertiesStatus.empty
                    : PropertiesStatus.loaded,
                properties: properties,
                filteredProperties: _applyFilters(
                  properties,
                  searchQuery: state.searchQuery,
                  propertyTypeFilter: state.propertyTypeFilter,
                  listingTypeFilter: state.listingTypeFilter,
                  statusFilter: state.statusFilter,
                ),
                clearMessage: true,
              ),
            );
          },
          onError: (error) {
            if (isClosed) {
              return;
            }
            emit(
              state.copyWith(
                status: PropertiesStatus.failure,
                message: _propertyErrorMessage(
                  error,
                  'Unable to load properties. Please try again.',
                ),
              ),
            );
          },
        );
  }

  void setSearchQuery(String query) {
    emit(
      state.copyWith(
        searchQuery: query,
        filteredProperties: _applyFilters(
          state.properties,
          searchQuery: query,
          propertyTypeFilter: state.propertyTypeFilter,
          listingTypeFilter: state.listingTypeFilter,
          statusFilter: state.statusFilter,
        ),
      ),
    );
  }

  void setPropertyTypeFilter(PropertyType? propertyType) {
    emit(
      state.copyWith(
        propertyTypeFilter: propertyType,
        clearPropertyTypeFilter: propertyType == null,
        filteredProperties: _applyFilters(
          state.properties,
          searchQuery: state.searchQuery,
          propertyTypeFilter: propertyType,
          listingTypeFilter: state.listingTypeFilter,
          statusFilter: state.statusFilter,
        ),
      ),
    );
  }

  void setListingTypeFilter(PropertyListingType? listingType) {
    emit(
      state.copyWith(
        listingTypeFilter: listingType,
        clearListingTypeFilter: listingType == null,
        filteredProperties: _applyFilters(
          state.properties,
          searchQuery: state.searchQuery,
          propertyTypeFilter: state.propertyTypeFilter,
          listingTypeFilter: listingType,
          statusFilter: state.statusFilter,
        ),
      ),
    );
  }

  void setStatusFilter(PropertyStatus? status) {
    emit(
      state.copyWith(
        statusFilter: status,
        clearStatusFilter: status == null,
        filteredProperties: _applyFilters(
          state.properties,
          searchQuery: state.searchQuery,
          propertyTypeFilter: state.propertyTypeFilter,
          listingTypeFilter: state.listingTypeFilter,
          statusFilter: status,
        ),
      ),
    );
  }

  void clearFilters() {
    emit(
      state.copyWith(
        searchQuery: '',
        clearPropertyTypeFilter: true,
        clearListingTypeFilter: true,
        clearStatusFilter: true,
        filteredProperties: _applyFilters(state.properties),
      ),
    );
  }

  Future<void> createProperty({
    required String companyId,
    required Property property,
  }) async {
    emit(
      state.copyWith(
        status: PropertiesStatus.saving,
        clearMessage: true,
        clearLastAction: true,
      ),
    );
    try {
      await _guardFirebaseAction(
        () => _createPropertyUseCase(
          companyId: companyId,
          property: property,
        ),
      );
      if (isClosed) {
        return;
      }
      emit(
        state.copyWith(
          status: PropertiesStatus.saved,
          clearMessage: true,
          lastAction: PropertiesAction.createProperty,
        ),
      );
    } on PropertyException catch (error) {
      if (isClosed) {
        return;
      }
      emit(
        state.copyWith(
          status: PropertiesStatus.failure,
          message: error.message,
        ),
      );
    } catch (error) {
      if (isClosed) {
        return;
      }
      emit(
        state.copyWith(
          status: PropertiesStatus.failure,
          message: _propertyErrorMessage(
            error,
            'Unable to create property. Please try again.',
          ),
          lastAction: PropertiesAction.createProperty,
        ),
      );
    }
  }

  Future<void> updateProperty({
    required String companyId,
    required Property property,
  }) async {
    emit(
      state.copyWith(
        status: PropertiesStatus.saving,
        clearMessage: true,
        clearLastAction: true,
      ),
    );
    try {
      await _guardFirebaseAction(
        () => _updatePropertyUseCase(
          companyId: companyId,
          property: property,
        ),
      );
      if (isClosed) {
        return;
      }
      emit(
        state.copyWith(
          status: PropertiesStatus.saved,
          clearMessage: true,
          lastAction: PropertiesAction.updateProperty,
        ),
      );
    } on PropertyException catch (error) {
      if (isClosed) {
        return;
      }
      emit(
        state.copyWith(
          status: PropertiesStatus.failure,
          message: error.message,
        ),
      );
    } catch (error) {
      if (isClosed) {
        return;
      }
      emit(
        state.copyWith(
          status: PropertiesStatus.failure,
          message: _propertyErrorMessage(
            error,
            'Unable to update property. Please try again.',
          ),
          lastAction: PropertiesAction.updateProperty,
        ),
      );
    }
  }

  void clearError() {
    emit(state.copyWith(clearMessage: true));
  }

  void clearAction() {
    emit(state.copyWith(clearLastAction: true));
  }

  String _propertyErrorMessage(Object error, String fallback) {
    if (error is PropertyException) {
      return error.message;
    }

    return fallback;
  }

  List<Property> _applyFilters(
    List<Property> properties, {
    String? searchQuery,
    PropertyType? propertyTypeFilter,
    PropertyListingType? listingTypeFilter,
    PropertyStatus? statusFilter,
  }) {
    final query = (searchQuery ?? '').trim().toLowerCase();
    final filtered = properties.where((property) {
      final matchesQuery =
          query.isEmpty ||
          property.title.toLowerCase().contains(query) ||
          property.location.toLowerCase().contains(query) ||
          property.compound.toLowerCase().contains(query) ||
          property.ownerName.toLowerCase().contains(query) ||
          property.ownerPhone.toLowerCase().contains(query);
      final matchesType =
          propertyTypeFilter == null || property.propertyType == propertyTypeFilter;
      final matchesListingType =
          listingTypeFilter == null || property.listingType == listingTypeFilter;
      final matchesStatus =
          statusFilter == null || property.status == statusFilter;
      return matchesQuery && matchesType && matchesListingType && matchesStatus;
    }).toList();

    filtered.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return filtered;
  }

  @override
  Future<void> close() {
    _propertiesSubscription?.cancel();
    return super.close();
  }
}
