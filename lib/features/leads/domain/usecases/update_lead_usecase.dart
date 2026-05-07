import '../../../../core/errors/error_mapper.dart';
import '../entities/lead.dart';
import '../errors/lead_exception.dart';
import '../repositories/leads_repository.dart';
import 'create_lead_usecase.dart';

class UpdateLeadUseCase {
  const UpdateLeadUseCase(this._repository, this._checkDuplicateLeadUseCase);

  final LeadsRepository _repository;
  final CheckDuplicateLeadUseCase _checkDuplicateLeadUseCase;

  Future<Lead> call({
    required String companyId,
    required Lead lead,
    Lead? currentLead,
  }) async {
    final shouldCheckDuplicate =
        currentLead == null ||
        _normalizePhone(currentLead.phone) != _normalizePhone(lead.phone) ||
        _normalizeEmail(currentLead.email) != _normalizeEmail(lead.email);

    if (shouldCheckDuplicate) {
      final isDuplicate = await _hasDuplicateLead(
        companyId: companyId,
        lead: lead,
      );
      if (isDuplicate) {
        throw const LeadException(
          'A lead with this phone or email already exists.',
        );
      }
    }

    return _repository.updateLead(companyId: companyId, lead: lead);
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
        excludeLeadId: lead.id,
      );
    } on LeadException catch (error) {
      if (error.message == AppErrorMessages.permissionDenied) {
        return false;
      }
      rethrow;
    }
  }
}

String _normalizeEmail(String value) {
  return value.trim().toLowerCase();
}

String _normalizePhone(String value) {
  return value.replaceAll(RegExp(r'\s+'), '').trim();
}
