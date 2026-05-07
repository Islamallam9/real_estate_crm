import '../entities/property.dart';
import '../repositories/property_repository.dart';

class UpdatePropertyUseCase {
  const UpdatePropertyUseCase(this._repository);

  final PropertyRepository _repository;

  Future<Property> call({
    required String companyId,
    required Property property,
  }) {
    return _repository.updateProperty(
      companyId: companyId,
      property: property,
    );
  }
}
