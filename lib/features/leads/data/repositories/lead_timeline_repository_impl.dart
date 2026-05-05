import '../../domain/entities/lead_timeline_event.dart';
import '../../domain/repositories/lead_timeline_repository.dart';
import '../datasources/lead_timeline_remote_data_source.dart';
import '../models/lead_timeline_event_model.dart';

class LeadTimelineRepositoryImpl implements LeadTimelineRepository {
  const LeadTimelineRepositoryImpl({
    required LeadTimelineRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  final LeadTimelineRemoteDataSource _remoteDataSource;

  @override
  Future<LeadTimelineEvent> addEvent({
    required String companyId,
    required String leadId,
    required LeadTimelineEvent event,
  }) {
    return _remoteDataSource.addEvent(
      companyId: companyId,
      leadId: leadId,
      event: LeadTimelineEventModel.fromEntity(event),
    );
  }

  @override
  Stream<List<LeadTimelineEvent>> watchTimeline({
    required String companyId,
    required String leadId,
  }) {
    return _remoteDataSource.watchTimeline(
      companyId: companyId,
      leadId: leadId,
    );
  }
}
