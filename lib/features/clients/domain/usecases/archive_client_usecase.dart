import '../repositories/client_repository.dart';

class ArchiveClientUseCase {
  const ArchiveClientUseCase(this._repository);

  final ClientRepository _repository;

  Future<void> call({
    required String companyId,
    required String clientId,
    required String updatedBy,
  }) {
    return _repository.archiveClient(
      companyId: companyId,
      clientId: clientId,
      updatedBy: updatedBy,
    );
  }
}
