import '../entities/lead.dart';
import '../repositories/leads_repository.dart';

class CreateLeadUseCase {
  const CreateLeadUseCase(this._repository);

  final LeadsRepository _repository;

  Future<Lead> call({
    required String companyId,
    required Lead lead,
  }) {
    return _repository.createLead(
      companyId: companyId,
      lead: lead,
    );
  }
}
