import '../../domain/entities/lead.dart';
import '../../domain/repositories/leads_repository.dart';
import '../datasources/leads_remote_data_source.dart';
import '../models/lead_model.dart';

class LeadsRepositoryImpl implements LeadsRepository {
  const LeadsRepositoryImpl({required LeadsRemoteDataSource remoteDataSource})
    : _remoteDataSource = remoteDataSource;

  final LeadsRemoteDataSource _remoteDataSource;

  @override
  Future<bool> hasDuplicateLead({
    required String companyId,
    required String phone,
    required String email,
    String? excludeLeadId,
  }) {
    return _remoteDataSource.hasDuplicateLead(
      companyId: companyId,
      phone: phone,
      email: email,
      excludeLeadId: excludeLeadId,
    );
  }

  @override
  Future<Lead> createLead({required String companyId, required Lead lead}) {
    return _remoteDataSource.createLead(
      companyId: companyId,
      lead: LeadModel.fromEntity(lead),
    );
  }

  @override
  Future<Lead> updateLead({required String companyId, required Lead lead}) {
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
    return _remoteDataSource.getLeadById(companyId: companyId, leadId: leadId);
  }

  @override
  Future<void> archiveLead({
    required String companyId,
    required String leadId,
    required String archivedBy,
  }) {
    return _remoteDataSource.archiveLead(
      companyId: companyId,
      leadId: leadId,
      archivedBy: archivedBy,
    );
  }

  @override
  Stream<List<Lead>> watchLeads({
    required String companyId,
    String? assignedTo,
    String? managerId,
    int limit = 30,
  }) {
    return _remoteDataSource.watchLeads(
      companyId: companyId,
      assignedTo: assignedTo,
      managerId: managerId,
      limit: limit,
    );
  }
}
