import '../entities/connected_journey.dart';
import '../repositories/connected_journey_repository.dart';

class WatchConnectedJourneyUseCase {
  const WatchConnectedJourneyUseCase(this.repository);

  final ConnectedJourneyRepository repository;

  Stream<List<JourneyItem>> tasks({
    required JourneyRecordType recordType,
    required String recordId,
    required JourneyQueryScope scope,
  }) {
    return repository.watchTaskItems(
      recordType: recordType,
      recordId: recordId,
      scope: scope,
    );
  }

  Stream<List<JourneyItem>> appointments({
    required JourneyRecordType recordType,
    required String recordId,
    required JourneyQueryScope scope,
  }) {
    return repository.watchAppointmentItems(
      recordType: recordType,
      recordId: recordId,
      scope: scope,
    );
  }

  Stream<List<JourneyItem>> deals({
    required JourneyRecordType recordType,
    required String recordId,
    required JourneyQueryScope scope,
  }) {
    return repository.watchDealItems(
      recordType: recordType,
      recordId: recordId,
      scope: scope,
    );
  }

  Stream<List<JourneyItem>> audit({
    required JourneyRecordType recordType,
    required String recordId,
    required JourneyQueryScope scope,
  }) {
    return repository.watchAuditItems(
      recordType: recordType,
      recordId: recordId,
      scope: scope,
    );
  }
}
