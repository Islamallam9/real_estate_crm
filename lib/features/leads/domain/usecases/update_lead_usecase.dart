import '../entities/lead.dart';
import '../errors/lead_exception.dart';
import '../repositories/leads_repository.dart';
import 'create_lead_usecase.dart';

class UpdateLeadUseCase {
  const UpdateLeadUseCase(this._repository, this._checkDuplicateLeadUseCase);

  final LeadsRepository _repository;
  final CheckDuplicateLeadUseCase _checkDuplicateLeadUseCase;

  Future<Lead> call({required String companyId, required Lead lead}) async {
    final isDuplicate = await _checkDuplicateLeadUseCase(
      companyId: companyId,
      phone: lead.phone,
      email: lead.email,
      excludeLeadId: lead.id,
    );
    if (isDuplicate) {
      throw const LeadException(
        'A lead with this phone or email already exists.',
      );
    }

    return _repository.updateLead(companyId: companyId, lead: lead);
  }
}
