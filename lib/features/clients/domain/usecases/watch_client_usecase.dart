import '../entities/client.dart';
import '../repositories/client_repository.dart';

class WatchClientUseCase {
  const WatchClientUseCase(this._repository);

  final ClientRepository _repository;

  Stream<Client?> call({required String companyId, required String clientId}) {
    return _repository.watchClient(companyId: companyId, clientId: clientId);
  }
}
