import '../entities/client.dart';
import '../repositories/client_repository.dart';

class WatchClientsUseCase {
  const WatchClientsUseCase(this._repository);

  final ClientRepository _repository;

  Stream<List<Client>> call({
    required String companyId,
    String? assignedTo,
    int limit = 30,
  }) {
    return _repository.watchClients(
      companyId: companyId,
      assignedTo: assignedTo,
      limit: limit,
    );
  }
}
