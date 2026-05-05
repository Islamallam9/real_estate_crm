import '../entities/lead_note.dart';
import '../repositories/lead_notes_repository.dart';

class WatchLeadNotesUseCase {
  const WatchLeadNotesUseCase(this._repository);

  final LeadNotesRepository _repository;

  Stream<List<LeadNote>> call({
    required String companyId,
    required String leadId,
  }) {
    return _repository.watchNotes(companyId: companyId, leadId: leadId);
  }
}
