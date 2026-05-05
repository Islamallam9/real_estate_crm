import '../repositories/leads_repository.dart';

class ArchiveLeadUseCase {
  const ArchiveLeadUseCase(this._repository);

  final LeadsRepository _repository;

  Future<void> call({
    required String companyId,
    required String leadId,
    required String archivedBy,
  }) {
    return _repository.archiveLead(
      companyId: companyId,
      leadId: leadId,
      archivedBy: archivedBy,
    );
  }
}
