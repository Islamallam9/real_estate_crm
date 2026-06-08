import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/error_mapper.dart';
import '../../../../core/utils/initial_load_timeout.dart';
import '../../../audit_logs/domain/entities/audit_log.dart';
import '../../../audit_logs/domain/usecases/create_audit_log_usecase.dart';
import '../../domain/entities/property.dart';
import '../../domain/entities/property_image_upload.dart';
import '../../domain/errors/property_exception.dart';
import '../../domain/usecases/create_property_usecase.dart';
import '../../domain/usecases/deactivate_property_usecase.dart';
import '../../domain/usecases/update_property_usecase.dart';
import '../../domain/usecases/watch_property_usecase.dart';
import '../../domain/usecases/watch_properties_usecase.dart';
import 'properties_state.dart';

class PropertiesCubit extends Cubit<PropertiesState> {
  PropertiesCubit({
    required WatchPropertyUseCase watchPropertyUseCase,
    required WatchPropertiesUseCase watchPropertiesUseCase,
    required CreatePropertyUseCase createPropertyUseCase,
    required UpdatePropertyUseCase updatePropertyUseCase,
    required DeactivatePropertyUseCase deactivatePropertyUseCase,
    required CreateAuditLogUseCase createAuditLogUseCase,
  }) : _watchPropertyUseCase = watchPropertyUseCase,
        _watchPropertiesUseCase = watchPropertiesUseCase,
        _createPropertyUseCase = createPropertyUseCase,
        _updatePropertyUseCase = updatePropertyUseCase,
        _deactivatePropertyUseCase = deactivatePropertyUseCase,
        _createAuditLogUseCase = createAuditLogUseCase,
        super(const PropertiesState.initial());

  final WatchPropertyUseCase _watchPropertyUseCase;
  final WatchPropertiesUseCase _watchPropertiesUseCase;
  final CreatePropertyUseCase _createPropertyUseCase;
  final UpdatePropertyUseCase _updatePropertyUseCase;
  final DeactivatePropertyUseCase _deactivatePropertyUseCase;
  final CreateAuditLogUseCase _createAuditLogUseCase;

  StreamSubscription<dynamic>? _propertiesSubscription;
  final InitialLoadTimeout _propertiesInitialLoadTimeout =
  InitialLoadTimeout();
  static const Duration _defaultFirebaseTimeout = Duration(seconds: 15);
  static const Duration _imageUploadFirebaseTimeout = Duration(minutes: 4);

  Future<bool> _hasConnection() async {
    final results = await Connectivity().checkConnectivity();
    return results.any((result) => result != ConnectivityResult.none);
  }

  Future<T> _guardFirebaseAction<T>(
      Future<T> Function() action, {
        Duration timeout = _defaultFirebaseTimeout,
      }) async {
    final connected = await _hasConnection();

    if (!connected) {
      throw const PropertyException(AppErrorMessages.unableToConnect);
    }

    return action().timeout(
      timeout,
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
    _propertiesInitialLoadTimeout.start(() {
      if (isClosed ||
          state.status != PropertiesStatus.loading ||
          state.properties.isNotEmpty) {
        return;
      }
      emit(
        state.copyWith(
          status: PropertiesStatus.failure,
          message: AppErrorMessages.connectionTimeout,
        ),
      );
    });
    _propertiesSubscription = _watchPropertiesUseCase(companyId: companyId)
        .listen(
          (properties) {
        if (isClosed) {
          return;
        }
        _propertiesInitialLoadTimeout.complete();
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
        _propertiesInitialLoadTimeout.complete();
        emit(
          state.copyWith(
            status: PropertiesStatus.failure,
            message: _propertyErrorMessage(
              error,
              AppErrorMessages.connectionTimeout,
            ),
          ),
        );
      },
    );
  }

  void watchProperty({
    required String companyId,
    required String propertyId,
  }) {
    emit(
      state.copyWith(
        status: PropertiesStatus.loading,
        clearMessage: true,
        clearLastAction: true,
      ),
    );
    _propertiesSubscription?.cancel();
    _propertiesInitialLoadTimeout.start(() {
      if (isClosed ||
          state.status != PropertiesStatus.loading ||
          state.properties.isNotEmpty) {
        return;
      }
      emit(
        state.copyWith(
          status: PropertiesStatus.failure,
          message: AppErrorMessages.connectionTimeout,
        ),
      );
    });
    _propertiesSubscription = _watchPropertyUseCase(
      companyId: companyId,
      propertyId: propertyId,
    ).listen(
      (property) {
        if (isClosed) {
          return;
        }
        _propertiesInitialLoadTimeout.complete();
        final properties = property == null
            ? const <Property>[]
            : <Property>[property];
        emit(
          state.copyWith(
            status: property == null
                ? PropertiesStatus.empty
                : PropertiesStatus.loaded,
            properties: properties,
            filteredProperties: properties,
            clearMessage: true,
          ),
        );
      },
      onError: (error) {
        if (isClosed) {
          return;
        }
        _propertiesInitialLoadTimeout.complete();
        emit(
          state.copyWith(
            status: PropertiesStatus.failure,
            message: _propertyErrorMessage(
              error,
              AppErrorMessages.connectionTimeout,
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
    List<PropertyImageUpload> newImages = const [],
  }) async {
    emit(
      state.copyWith(
        status: PropertiesStatus.saving,
        clearMessage: true,
        clearLastAction: true,
      ),
    );
    try {
      final createdProperty = await _guardFirebaseAction(
            () => _createPropertyUseCase(
          companyId: companyId,
          property: property,
          newImages: newImages,
        ),
        timeout: newImages.isEmpty
            ? _defaultFirebaseTimeout
            : _imageUploadFirebaseTimeout,
      );
      unawaited(
        _writeAuditLog(
          companyId: companyId,
          actorId: createdProperty.createdBy,
          action: AuditLogAction.create,
          recordId: createdProperty.id,
          recordTitle: _propertyTitle(createdProperty),
          recordSubtitle: _propertySubtitle(createdProperty),
          metadata: {
            'status': _propertyStatusValue(createdProperty.status),
            'imageCount': createdProperty.imageUrls.length,
          },
        ),
      );
      if (newImages.isNotEmpty) {
        unawaited(
          _writeAuditLog(
            companyId: companyId,
            actorId: createdProperty.createdBy,
            action: AuditLogAction.imageAdded,
            recordId: createdProperty.id,
            recordTitle: _propertyTitle(createdProperty),
            recordSubtitle: _propertySubtitle(createdProperty),
            metadata: {'imageCount': newImages.length},
          ),
        );
      }
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
    List<PropertyImageUpload> newImages = const [],
    List<String> removedImageStoragePaths = const [],
  }) async {
    emit(
      state.copyWith(
        status: PropertiesStatus.saving,
        clearMessage: true,
        clearLastAction: true,
      ),
    );
    try {
      final updatedProperty = await _guardFirebaseAction(
            () => _updatePropertyUseCase(
          companyId: companyId,
          property: property,
          newImages: newImages,
          removedImageStoragePaths: removedImageStoragePaths,
        ),
        timeout: newImages.isEmpty && removedImageStoragePaths.isEmpty
            ? _defaultFirebaseTimeout
            : _imageUploadFirebaseTimeout,
      );
      unawaited(
        _writeAuditLog(
          companyId: companyId,
          actorId: updatedProperty.updatedBy,
          action: AuditLogAction.update,
          recordId: updatedProperty.id,
          recordTitle: _propertyTitle(updatedProperty),
          recordSubtitle: _propertySubtitle(updatedProperty),
          metadata: {
            'status': _propertyStatusValue(updatedProperty.status),
            'imageCount': updatedProperty.imageUrls.length,
          },
        ),
      );
      if (newImages.isNotEmpty) {
        unawaited(
          _writeAuditLog(
            companyId: companyId,
            actorId: updatedProperty.updatedBy,
            action: AuditLogAction.imageAdded,
            recordId: updatedProperty.id,
            recordTitle: _propertyTitle(updatedProperty),
            recordSubtitle: _propertySubtitle(updatedProperty),
            metadata: {'imageCount': newImages.length},
          ),
        );
      }
      if (removedImageStoragePaths.isNotEmpty) {
        unawaited(
          _writeAuditLog(
            companyId: companyId,
            actorId: updatedProperty.updatedBy,
            action: AuditLogAction.imageRemoved,
            recordId: updatedProperty.id,
            recordTitle: _propertyTitle(updatedProperty),
            recordSubtitle: _propertySubtitle(updatedProperty),
            metadata: {'imageCount': removedImageStoragePaths.length},
          ),
        );
      }
      if (isClosed) {
        return;
      }
      final updatedProperties = _replacePropertyInCurrentList(updatedProperty);
      emit(
        state.copyWith(
          status: PropertiesStatus.saved,
          properties: updatedProperties,
          filteredProperties: _applyFilters(
            updatedProperties,
            searchQuery: state.searchQuery,
            propertyTypeFilter: state.propertyTypeFilter,
            listingTypeFilter: state.listingTypeFilter,
            statusFilter: state.statusFilter,
          ),
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

  Future<bool> deactivateProperty({
    required String companyId,
    required String propertyId,
    required String updatedBy,
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
            () => _deactivatePropertyUseCase(
          companyId: companyId,
          propertyId: propertyId,
          updatedBy: updatedBy,
        ),
      );
      final property = _propertyById(propertyId);
      unawaited(
        _writeAuditLog(
          companyId: companyId,
          actorId: updatedBy,
          action: AuditLogAction.deactivate,
          recordId: propertyId,
          recordTitle: property == null ? 'Property' : _propertyTitle(property),
          recordSubtitle: property == null ? '' : _propertySubtitle(property),
          metadata: const {'newStatus': 'inactive'},
        ),
      );
      if (isClosed) {
        return true;
      }
      emit(
        state.copyWith(
          status: PropertiesStatus.saved,
          clearMessage: true,
          lastAction: PropertiesAction.deactivateProperty,
        ),
      );
      return true;
    } on PropertyException catch (error) {
      if (isClosed) {
        return false;
      }
      emit(
        state.copyWith(
          status: PropertiesStatus.failure,
          message: error.message,
          lastAction: PropertiesAction.deactivateProperty,
        ),
      );
    } catch (error) {
      if (isClosed) {
        return false;
      }
      emit(
        state.copyWith(
          status: PropertiesStatus.failure,
          message: _propertyErrorMessage(
            error,
            'Unable to deactivate property. Please try again.',
          ),
          lastAction: PropertiesAction.deactivateProperty,
        ),
      );
    }
    return false;
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

  Future<void> _writeAuditLog({
    required String companyId,
    required String actorId,
    required AuditLogAction action,
    required String recordId,
    required String recordTitle,
    required String recordSubtitle,
    required Map<String, Object?> metadata,
  }) async {
    try {
      await _createAuditLogUseCase(
        companyId: companyId,
        auditLog: AuditLog(
          id: '',
          companyId: companyId,
          actorId: actorId,
          actorName: '',
          actorEmail: '',
          actorRole: '',
          action: action,
          module: AuditLogModule.properties,
          recordId: recordId,
          recordTitle: recordTitle,
          recordSubtitle: recordSubtitle,
          createdAt: DateTime.now(),
          metadata: metadata,
        ),
      );
    } catch (_) {
      // Audit logging is best-effort and must not block property workflows.
    }
  }

  Property? _propertyById(String propertyId) {
    for (final property in state.properties) {
      if (property.id == propertyId) {
        return property;
      }
    }
    return null;
  }


  List<Property> _replacePropertyInCurrentList(Property updated) {
    final index = state.properties.indexWhere((property) => property.id == updated.id);
    if (index < 0) {
      return state.properties;
    }
    final next = List<Property>.of(state.properties);
    next[index] = updated;
    return next;
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
    _propertiesInitialLoadTimeout.cancel();
    _propertiesSubscription?.cancel();
    return super.close();
  }
}

String _propertyTitle(Property property) {
  final title = property.title.trim();
  return title.isEmpty ? 'Property' : title;
}

String _propertySubtitle(Property property) {
  final location = property.location.trim();
  if (location.isNotEmpty) {
    return location;
  }
  return property.price.toString();
}

String _propertyStatusValue(PropertyStatus status) {
  return switch (status) {
    PropertyStatus.available => 'available',
    PropertyStatus.reserved => 'reserved',
    PropertyStatus.sold => 'sold',
    PropertyStatus.rented => 'rented',
    PropertyStatus.inactive => 'inactive',
  };
}
