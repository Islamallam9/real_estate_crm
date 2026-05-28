import '../entities/connected_journey.dart';

abstract class ConnectedJourneyRepository {
  Stream<List<JourneyItem>> watchTaskItems({
    required JourneyRecordType recordType,
    required String recordId,
    required JourneyQueryScope scope,
  });

  Stream<List<JourneyItem>> watchAppointmentItems({
    required JourneyRecordType recordType,
    required String recordId,
    required JourneyQueryScope scope,
  });

  Stream<List<JourneyItem>> watchDealItems({
    required JourneyRecordType recordType,
    required String recordId,
    required JourneyQueryScope scope,
  });

  Stream<List<JourneyItem>> watchAuditItems({
    required JourneyRecordType recordType,
    required String recordId,
    required JourneyQueryScope scope,
  });
}
