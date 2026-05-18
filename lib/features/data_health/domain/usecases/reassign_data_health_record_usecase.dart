import '../repositories/data_health_repository.dart';

class ReassignDataHealthRecordUseCase {
  const ReassignDataHealthRecordUseCase(this._repository);

  final DataHealthRepository _repository;

  Future<void> call({
    required String companyId,
    required String module,
    required String recordId,
    required String newAssigneeUid,
  }) {
    return _repository.reassignRecord(
      companyId: companyId,
      module: module,
      recordId: recordId,
      newAssigneeUid: newAssigneeUid,
    );
  }
}
