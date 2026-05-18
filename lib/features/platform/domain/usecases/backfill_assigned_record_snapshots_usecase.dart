import '../repositories/platform_repository.dart';

class BackfillAssignedRecordSnapshotsUseCase {
  const BackfillAssignedRecordSnapshotsUseCase(this._repository);

  final PlatformRepository _repository;

  Future<void> call({
    required String companyId,
    required String module,
    required String recordId,
  }) {
    return _repository.backfillAssignedRecordSnapshots(
      companyId: companyId,
      module: module,
      recordId: recordId,
    );
  }
}
