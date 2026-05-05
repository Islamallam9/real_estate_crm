import '../entities/lead.dart';
import '../repositories/leads_repository.dart';

class UpdateLeadUseCase {
  const UpdateLeadUseCase(this._repository);

  final LeadsRepository _repository;

  Future<Lead> call({required String companyId, required Lead lead}) {
    return _repository.updateLead(companyId: companyId, lead: lead);
  }
}
