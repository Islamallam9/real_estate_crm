import '../entities/release_intelligence.dart';
import '../repositories/platform_repository.dart';

class GetPlatformVersionHistoryUseCase {
  const GetPlatformVersionHistoryUseCase(this.repository);

  final PlatformRepository repository;

  Future<List<DeviceVersionEventRow>> call({
    String platform = 'all',
    String? companyId,
    int limit = 120,
  }) {
    return repository.getPlatformVersionHistory(
      platform: platform,
      companyId: companyId,
      limit: limit,
    );
  }
}
