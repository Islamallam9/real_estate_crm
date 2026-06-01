import '../entities/platform_login_activity.dart';
import '../repositories/platform_repository.dart';

class WatchPlatformLoginActivityUseCase {
  const WatchPlatformLoginActivityUseCase(this._repository);

  final PlatformRepository _repository;

  Stream<List<PlatformLoginActivity>> call({
    required String companyId,
    int limit = 300,
  }) {
    return _repository.watchCompanyLoginActivity(
      companyId: companyId,
      limit: limit,
    );
  }
}
