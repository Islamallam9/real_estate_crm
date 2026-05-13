import '../../domain/entities/property.dart';
import '../../domain/entities/property_image_upload.dart';
import '../../domain/repositories/property_repository.dart';
import '../datasources/properties_remote_data_source.dart';
import '../models/property_model.dart';

class PropertyRepositoryImpl implements PropertyRepository {
  const PropertyRepositoryImpl({
    required PropertiesRemoteDataSource remoteDataSource,
  })
    : _remoteDataSource = remoteDataSource;

  final PropertiesRemoteDataSource _remoteDataSource;

  @override
  Future<Property> createProperty({
    required String companyId,
    required Property property,
    List<PropertyImageUpload> newImages = const [],
  }) {
    return _remoteDataSource.createProperty(
      companyId: companyId,
      property: PropertyModel.fromEntity(property),
      newImages: newImages,
    );
  }

  @override
  Future<Property> updateProperty({
    required String companyId,
    required Property property,
    List<PropertyImageUpload> newImages = const [],
    List<String> removedImageStoragePaths = const [],
  }) {
    return _remoteDataSource.updateProperty(
      companyId: companyId,
      property: PropertyModel.fromEntity(property),
      newImages: newImages,
      removedImageStoragePaths: removedImageStoragePaths,
    );
  }

  @override
  Future<void> deactivateProperty({
    required String companyId,
    required String propertyId,
    required String updatedBy,
  }) {
    return _remoteDataSource.deactivateProperty(
      companyId: companyId,
      propertyId: propertyId,
      updatedBy: updatedBy,
    );
  }

  @override
  Stream<List<Property>> watchProperties({
    required String companyId,
    int limit = 30,
  }) {
    return _remoteDataSource.watchProperties(
      companyId: companyId,
      limit: limit,
    );
  }
}
