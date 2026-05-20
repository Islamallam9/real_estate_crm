import '../repositories/platform_repository.dart';

class RefreshCompanyStorageUsageUseCase {
  const RefreshCompanyStorageUsageUseCase(this._repository);

  final PlatformRepository _repository;

  Future<void> call({required String companyId}) {
    return _repository.refreshCompanyStorageUsage(companyId: companyId);
  }
}
