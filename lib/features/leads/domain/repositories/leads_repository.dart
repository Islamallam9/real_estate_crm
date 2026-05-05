import '../entities/lead.dart';

abstract interface class LeadsRepository {
  Future<Lead> createLead({
    required String companyId,
    required Lead lead,
  });

  Future<Lead> updateLead({
    required String companyId,
    required Lead lead,
  });

  Future<Lead> getLeadById({
    required String companyId,
    required String leadId,
  });

  Stream<List<Lead>> watchLeads({
    required String companyId,
    int limit,
  });
}
