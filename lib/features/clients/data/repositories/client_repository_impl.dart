import '../../domain/entities/client.dart';
import '../../domain/repositories/client_repository.dart';
import '../datasources/clients_remote_data_source.dart';
import '../models/client_model.dart';

class ClientRepositoryImpl implements ClientRepository {
  const ClientRepositoryImpl({required ClientsRemoteDataSource remoteDataSource})
    : _remoteDataSource = remoteDataSource;

  final ClientsRemoteDataSource _remoteDataSource;

  @override
  Future<Client> createClient({
    required String companyId,
    required Client client,
  }) {
    return _remoteDataSource.createClient(
      companyId: companyId,
      client: ClientModel.fromEntity(client),
    );
  }

  @override
  Future<Client> updateClient({
    required String companyId,
    required Client client,
  }) {
    return _remoteDataSource.updateClient(
      companyId: companyId,
      client: ClientModel.fromEntity(client),
    );
  }

  @override
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
  }) {
    return _remoteDataSource.assignClient(
      companyId: companyId,
      clientId: clientId,
      assignedTo: assignedTo,
      assignedToName: assignedToName,
      assignedToEmail: assignedToEmail,
      teamId: teamId,
      teamName: teamName,
      managerId: managerId,
      managerName: managerName,
      updatedBy: updatedBy,
    );
  }

  @override
  Future<void> archiveClient({
    required String companyId,
    required String clientId,
    required String updatedBy,
  }) {
    return _remoteDataSource.archiveClient(
      companyId: companyId,
      clientId: clientId,
      updatedBy: updatedBy,
    );
  }

  @override
  Stream<Client?> watchClient({
    required String companyId,
    required String clientId,
  }) {
    return _remoteDataSource.watchClient(
      companyId: companyId,
      clientId: clientId,
    );
  }

  @override
  Stream<List<Client>> watchClients({
    required String companyId,
    String? assignedTo,
    String? managerId,
    int limit = 30,
  }) {
    return _remoteDataSource.watchClients(
      companyId: companyId,
      assignedTo: assignedTo,
      managerId: managerId,
      limit: limit,
    );
  }
}
