import '../entities/property.dart';
import '../repositories/property_repository.dart';

class WatchPropertiesUseCase {
  const WatchPropertiesUseCase(this._repository);

  final PropertyRepository _repository;

  Stream<List<Property>> call({required String companyId, int limit = 30}) {
    return _repository.watchProperties(companyId: companyId, limit: limit);
  }
}
