import '../repositories/client_repository.dart';

class RestoreClientUseCase {
  const RestoreClientUseCase(this._repository);

  final ClientRepository _repository;

  Future<void> call({
    required String companyId,
    required String clientId,
    required String updatedBy,
  }) {
    return _repository.restoreClient(
      companyId: companyId,
      clientId: clientId,
      updatedBy: updatedBy,
    );
  }
}

