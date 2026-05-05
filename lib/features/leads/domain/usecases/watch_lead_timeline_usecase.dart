import '../entities/lead_timeline_event.dart';
import '../repositories/lead_timeline_repository.dart';

class WatchLeadTimelineUseCase {
  const WatchLeadTimelineUseCase(this._repository);

  final LeadTimelineRepository _repository;

  Stream<List<LeadTimelineEvent>> call({
    required String companyId,
    required String leadId,
  }) {
    return _repository.watchTimeline(companyId: companyId, leadId: leadId);
  }
}
