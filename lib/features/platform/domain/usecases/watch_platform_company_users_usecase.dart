import '../entities/platform_company_user.dart';
import '../repositories/platform_repository.dart';

class WatchPlatformCompanyUsersUseCase {
  const WatchPlatformCompanyUsersUseCase(this._repository);

  final PlatformRepository _repository;

  Stream<List<PlatformCompanyUser>> call({required String companyId}) {
    return _repository.watchCompanyUsers(companyId: companyId);
  }
}
