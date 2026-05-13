import '../entities/property.dart';
import '../entities/property_image_upload.dart';
import '../repositories/property_repository.dart';

class UpdatePropertyUseCase {
  const UpdatePropertyUseCase(this._repository);

  final PropertyRepository _repository;

  Future<Property> call({
    required String companyId,
    required Property property,
    List<PropertyImageUpload> newImages = const [],
    List<String> removedImageStoragePaths = const [],
  }) {
    return _repository.updateProperty(
      companyId: companyId,
      property: property,
      newImages: newImages,
      removedImageStoragePaths: removedImageStoragePaths,
    );
  }
}
