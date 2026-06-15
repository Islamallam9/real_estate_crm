import '../entities/property.dart';
import '../repositories/property_repository.dart';

class FindAvailablePropertiesForMatchingUseCase {
  const FindAvailablePropertiesForMatchingUseCase(this._repository);

  final PropertyRepository _repository;

  Future<List<Property>> call({required String companyId, int limit = 120}) {
    return _repository.findAvailablePropertiesForMatching(
      companyId: companyId,
      limit: limit,
    );
  }
}
