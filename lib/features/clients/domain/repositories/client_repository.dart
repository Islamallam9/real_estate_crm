import '../entities/client.dart';
import '../../../../core/archive/archive_filter.dart';

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
    required String assignedToName,
    required String assignedToEmail,
    required String teamId,
    required String teamName,
    required String managerId,
    required String managerName,
    required String updatedBy,
  });

  Future<void> archiveClient({
    required String companyId,
    required String clientId,
    required String updatedBy,
    String reason = '',
  });

  Future<void> restoreClient({
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
    String? managerId,
    String? teamId,
    ArchiveFilter archiveFilter = ArchiveFilter.active,
    int limit = 30,
  });
}
