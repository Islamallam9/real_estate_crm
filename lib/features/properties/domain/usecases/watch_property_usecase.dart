import '../entities/property.dart';
import '../repositories/property_repository.dart';

class WatchPropertyUseCase {
  const WatchPropertyUseCase(this._repository);

  final PropertyRepository _repository;

  Stream<Property?> call({
    required String companyId,
    required String propertyId,
  }) {
    return _repository.watchProperty(
      companyId: companyId,
      propertyId: propertyId,
    );
  }
}
