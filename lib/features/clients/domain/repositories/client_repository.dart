import '../entities/client.dart';

abstract interface class ClientRepository {
  Future<Client> createClient({
    required String companyId,
    required Client client,
  });

  Future<Client> updateClient({
    required String companyId,
    required Client client,
  });

  Future<void> assignClient({
    required String companyId,
    required String clientId,
    required String assignedTo,
    required String updatedBy,
  });

  Future<void> archiveClient({
    required String companyId,
    required String clientId,
    required String updatedBy,
  });

  Stream<Client?> watchClient({
    required String companyId,
    required String clientId,
  });

  Stream<List<Client>> watchClients({
    required String companyId,
    String? assignedTo,
    int limit,
  });
}
