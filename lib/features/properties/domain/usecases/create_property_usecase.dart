import '../entities/property.dart';
import '../entities/property_image_upload.dart';
import '../repositories/property_repository.dart';

class CreatePropertyUseCase {
  const CreatePropertyUseCase(this._repository);

  final PropertyRepository _repository;

  Future<Property> call({
    required String companyId,
    required Property property,
    List<PropertyImageUpload> newImages = const [],
  }) {
    return _repository.createProperty(
      companyId: companyId,
      property: property,
      newImages: newImages,
    );
  }
}
