import '../entities/lead_timeline_event.dart';
import '../repositories/lead_timeline_repository.dart';

class AddLeadTimelineEventUseCase {
  const AddLeadTimelineEventUseCase(this._repository);

  final LeadTimelineRepository _repository;

  Future<LeadTimelineEvent> call({
    required String companyId,
    required String leadId,
    required LeadTimelineEvent event,
  }) {
    return _repository.addEvent(
      companyId: companyId,
      leadId: leadId,
      event: event,
    );
  }
}
