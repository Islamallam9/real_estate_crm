import '../../../../core/archive/archive_filter.dart';
import '../entities/lead.dart';

abstract interface class LeadsRepository {
  Future<bool> hasDuplicateLead({
    required String companyId,
    required String phone,
    required String email,
    String? excludeLeadId,
  });

  Future<Lead> createLead({required String companyId, required Lead lead});

  Future<Lead> updateLead({required String companyId, required Lead lead});

  Future<Lead> getLeadById({required String companyId, required String leadId});

  Future<void> archiveLead({
    required String companyId,
    required String leadId,
    required String archivedBy,
    String reason = '',
  });

  Future<void> restoreLead({
    required String companyId,
    required String leadId,
    required String restoredBy,
  });

  Stream<List<Lead>> watchLeads({
    required String companyId,
    String? assignedTo,
    String? managerId,
    String? teamId,
    ArchiveFilter archiveFilter = ArchiveFilter.active,
    int limit = 30,
  });
}
