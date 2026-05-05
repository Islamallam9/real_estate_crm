import '../entities/lead.dart';
import '../repositories/leads_repository.dart';

class GetLeadByIdUseCase {
  const GetLeadByIdUseCase(this._repository);

  final LeadsRepository _repository;

  Future<Lead> call({required String companyId, required String leadId}) {
    return _repository.getLeadById(companyId: companyId, leadId: leadId);
  }
}
