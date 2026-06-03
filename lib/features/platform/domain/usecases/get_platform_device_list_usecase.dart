import '../entities/release_intelligence.dart';
import '../repositories/platform_repository.dart';

class GetPlatformDeviceListUseCase {
  const GetPlatformDeviceListUseCase(this.repository);

  final PlatformRepository repository;

  Future<List<PlatformDeviceInstallRow>> call({
    String platform = 'all',
    String? companyId,
    int activeWithinDays = 30,
    int limit = 120,
  }) {
    return repository.getPlatformDeviceList(
      platform: platform,
      companyId: companyId,
      activeWithinDays: activeWithinDays,
      limit: limit,
    );
  }
}
