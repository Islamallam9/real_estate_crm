import '../entities/lead_timeline_event.dart';

abstract interface class LeadTimelineRepository {
  Future<LeadTimelineEvent> addEvent({
    required String companyId,
    required String leadId,
    required LeadTimelineEvent event,
  });

  Stream<List<LeadTimelineEvent>> watchTimeline({
    required String companyId,
    required String leadId,
  });
}
