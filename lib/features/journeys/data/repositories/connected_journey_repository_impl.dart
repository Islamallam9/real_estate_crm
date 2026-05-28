import '../../domain/entities/connected_journey.dart';
import '../../domain/repositories/connected_journey_repository.dart';
import '../datasources/connected_journey_remote_data_source.dart';

class ConnectedJourneyRepositoryImpl implements ConnectedJourneyRepository {
  const ConnectedJourneyRepositoryImpl({required this.remoteDataSource});

  final FirestoreConnectedJourneyRemoteDataSource remoteDataSource;

  @override
  Stream<List<JourneyItem>> watchAppointmentItems({
    required JourneyRecordType recordType,
    required String recordId,
    required JourneyQueryScope scope,
  }) {
    return remoteDataSource.watchAppointmentItems(
      recordType: recordType,
      recordId: recordId,
      scope: scope,
    );
  }

  @override
  Stream<List<JourneyItem>> watchAuditItems({
    required JourneyRecordType recordType,
    required String recordId,
    required JourneyQueryScope scope,
  }) {
    return remoteDataSource.watchAuditItems(
      recordType: recordType,
      recordId: recordId,
      scope: scope,
    );
  }

  @override
  Stream<List<JourneyItem>> watchDealItems({
    required JourneyRecordType recordType,
    required String recordId,
    required JourneyQueryScope scope,
  }) {
    return remoteDataSource.watchDealItems(
      recordType: recordType,
      recordId: recordId,
      scope: scope,
    );
  }

  @override
  Stream<List<JourneyItem>> watchTaskItems({
    required JourneyRecordType recordType,
    required String recordId,
    required JourneyQueryScope scope,
  }) {
    return remoteDataSource.watchTaskItems(
      recordType: recordType,
      recordId: recordId,
      scope: scope,
    );
  }
}
