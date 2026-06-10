import '../../../../core/archive/archive_filter.dart';
import '../entities/lead.dart';
import '../repositories/leads_repository.dart';

class WatchLeadsUseCase {
  const WatchLeadsUseCase(this._repository);

  final LeadsRepository _repository;

  Stream<List<Lead>> call({
    required String companyId,
    String? assignedTo,
    String? managerId,
    String? teamId,
    ArchiveFilter archiveFilter = ArchiveFilter.active,
    LeadStatus? statusFilter,
    LeadSource? sourceFilter,
    LeadPriority? priorityFilter,
    String? followUpFilter,
    String? workQueueFilter,
    int limit = 30,
  }) {
    return _repository.watchLeads(
      companyId: companyId,
      assignedTo: assignedTo,
      managerId: managerId,
      teamId: teamId,
      archiveFilter: archiveFilter,
      statusFilter: statusFilter,
      sourceFilter: sourceFilter,
      priorityFilter: priorityFilter,
      followUpFilter: followUpFilter,
      workQueueFilter: workQueueFilter,
      limit: limit,
    );
  }
}
