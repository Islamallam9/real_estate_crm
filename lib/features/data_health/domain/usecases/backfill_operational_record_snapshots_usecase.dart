import '../repositories/data_health_repository.dart';

class BackfillOperationalRecordSnapshotsUseCase {
  const BackfillOperationalRecordSnapshotsUseCase(this._repository);

  final DataHealthRepository _repository;

  Future<void> call({
    required String companyId,
    required String module,
    required String recordId,
  }) {
    return _repository.backfillSnapshots(
      companyId: companyId,
      module: module,
      recordId: recordId,
    );
  }
}
