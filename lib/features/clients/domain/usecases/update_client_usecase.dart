import '../entities/client.dart';
import '../repositories/client_repository.dart';

class UpdateClientUseCase {
  const UpdateClientUseCase(this._repository);

  final ClientRepository _repository;

  Future<Client> call({required String companyId, required Client client}) {
    return _repository.updateClient(companyId: companyId, client: client);
  }
}
