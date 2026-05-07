import '../repositories/property_repository.dart';

class DeactivatePropertyUseCase {
  const DeactivatePropertyUseCase(this._repository);

  final PropertyRepository _repository;

  Future<void> call({
    required String companyId,
    required String propertyId,
    required String updatedBy,
  }) {
    return _repository.deactivateProperty(
      companyId: companyId,
      propertyId: propertyId,
      updatedBy: updatedBy,
    );
  }
}
