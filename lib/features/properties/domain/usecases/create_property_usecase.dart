import '../entities/property.dart';
import '../repositories/property_repository.dart';

class CreatePropertyUseCase {
  const CreatePropertyUseCase(this._repository);

  final PropertyRepository _repository;

  Future<Property> call({
    required String companyId,
    required Property property,
  }) {
    return _repository.createProperty(
      companyId: companyId,
      property: property,
    );
  }
}
