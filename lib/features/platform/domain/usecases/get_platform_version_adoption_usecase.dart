import '../entities/release_intelligence.dart';
import '../repositories/platform_repository.dart';

class GetPlatformVersionAdoptionUseCase {
  const GetPlatformVersionAdoptionUseCase(this.repository);

  final PlatformRepository repository;

  Future<List<VersionAdoptionRow>> call({
    String platform = 'all',
    String? companyId,
    int activeWithinDays = 30,
    bool includeInactive = false,
  }) {
    return repository.getPlatformVersionAdoption(
      platform: platform,
      companyId: companyId,
      activeWithinDays: activeWithinDays,
      includeInactive: includeInactive,
    );
  }
}
