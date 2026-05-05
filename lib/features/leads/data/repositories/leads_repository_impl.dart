import '../../domain/entities/lead.dart';
import '../../domain/repositories/leads_repository.dart';
import '../datasources/leads_remote_data_source.dart';
import '../models/lead_model.dart';

class LeadsRepositoryImpl implements LeadsRepository {
  const LeadsRepositoryImpl({
    required LeadsRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  final LeadsRemoteDataSource _remoteDataSource;

  @override
  Future<Lead> createLead({
    required String companyId,
    required Lead lead,
  }) {
    return _remoteDataSource.createLead(
      companyId: companyId,
      lead: LeadModel.fromEntity(lead),
    );
  }

  @override
  Future<Lead> updateLead({
    required String companyId,
    required Lead lead,
  }) {
    return _remoteDataSource.updateLead(
      companyId: companyId,
      lead: LeadModel.fromEntity(lead),
    );
  }

  @override
  Future<Lead> getLeadById({
    required String companyId,
    required String leadId,
  }) {
    return _remoteDataSource.getLeadById(
      companyId: companyId,
      leadId: leadId,
    );
  }

  @override
  Stream<List<Lead>> watchLeads({
    required String companyId,
    int limit = 30,
  }) {
    return _remoteDataSource.watchLeads(
      companyId: companyId,
      limit: limit,
    );
  }
}
