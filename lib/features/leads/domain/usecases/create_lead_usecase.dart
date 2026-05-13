import '../../../../core/errors/error_mapper.dart';
import '../entities/lead.dart';
import '../errors/lead_exception.dart';
import '../repositories/leads_repository.dart';

class CreateLeadUseCase {
  const CreateLeadUseCase(this._repository, this._checkDuplicateLeadUseCase);

  final LeadsRepository _repository;
  final CheckDuplicateLeadUseCase _checkDuplicateLeadUseCase;

  Future<Lead> call({required String companyId, required Lead lead}) async {
    final isDuplicate = await _hasDuplicateLead(
      companyId: companyId,
      lead: lead,
    );
    if (isDuplicate) {
      throw const LeadException(
        'A lead with this phone or email already exists.',
      );
    }

    return _repository.createLead(companyId: companyId, lead: lead);
  }

  Future<bool> _hasDuplicateLead({
    required String companyId,
    required Lead lead,
  }) async {
    try {
      return await _checkDuplicateLeadUseCase(
        companyId: companyId,
        phone: lead.phone,
        email: lead.email,
      );
    } on LeadException catch (error) {
      if (error.message == AppErrorMessages.permissionDenied) {
        return false;
      }
      rethrow;
    }
  }
}

class CheckDuplicateLeadUseCase {
  const CheckDuplicateLeadUseCase(this._repository);

  final LeadsRepository _repository;

  Future<bool> call({
    required String companyId,
    required String phone,
    required String email,
    String? excludeLeadId,
  }) {
    return _repository.hasDuplicateLead(
      companyId: companyId,
      phone: phone,
      email: email,
      excludeLeadId: excludeLeadId,
    );
  }
}
