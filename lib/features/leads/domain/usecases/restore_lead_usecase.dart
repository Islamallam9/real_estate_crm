import '../repositories/leads_repository.dart';

class RestoreLeadUseCase {
  const RestoreLeadUseCase(this._repository);

  final LeadsRepository _repository;

  Future<void> call({
    required String companyId,
    required String leadId,
    required String restoredBy,
  }) {
    return _repository.restoreLead(
      companyId: companyId,
      leadId: leadId,
      restoredBy: restoredBy,
    );
  }
}
