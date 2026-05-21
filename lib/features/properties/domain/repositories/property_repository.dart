import '../entities/property.dart';
import '../entities/property_image_upload.dart';

abstract interface class PropertyRepository {
  Future<Property> createProperty({
    required String companyId,
    required Property property,
    List<PropertyImageUpload> newImages = const [],
  });

  Future<Property> updateProperty({
    required String companyId,
    required Property property,
    List<PropertyImageUpload> newImages = const [],
    List<String> removedImageStoragePaths = const [],
  });

  Future<void> deactivateProperty({
    required String companyId,
    required String propertyId,
    required String updatedBy,
  });

  Stream<List<Property>> watchProperties({
    required String companyId,
    int limit = 50,
  });
}
