import '../entities/client.dart';
import '../repositories/client_repository.dart';

class CreateClientUseCase {
  const CreateClientUseCase(this._repository);

  final ClientRepository _repository;

  Future<Client> call({required String companyId, required Client client}) {
    return _repository.createClient(companyId: companyId, client: client);
  }
}
