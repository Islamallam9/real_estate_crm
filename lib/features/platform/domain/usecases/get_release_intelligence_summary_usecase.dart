import '../entities/release_intelligence.dart';
import '../repositories/platform_repository.dart';

class GetReleaseIntelligenceSummaryUseCase {
  const GetReleaseIntelligenceSummaryUseCase(this.repository);

  final PlatformRepository repository;

  Future<ReleaseIntelligenceSummary> call({int activeWithinDays = 30}) {
    return repository.getReleaseIntelligenceSummary(
      activeWithinDays: activeWithinDays,
    );
  }
}
