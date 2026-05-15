import '../../../users/domain/entities/company_metadata.dart';
import '../repositories/platform_repository.dart';

class WatchPlatformCompaniesUseCase {
  const WatchPlatformCompaniesUseCase(this._repository);

  final PlatformRepository _repository;

  Stream<List<CompanyMetadata>> call() {
    return _repository.watchCompanies();
  }
}
