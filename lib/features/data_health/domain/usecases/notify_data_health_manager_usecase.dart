import '../repositories/data_health_repository.dart';

class NotifyDataHealthManagerUseCase {
  const NotifyDataHealthManagerUseCase(this.repository);

  final DataHealthRepository repository;

  Future<void> call({
    required String companyId,
    required String module,
    required String recordId,
    required String issueType,
  }) {
    return repository.notifyManager(
      companyId: companyId,
      module: module,
      recordId: recordId,
      issueType: issueType,
    );
  }
}
