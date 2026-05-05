import '../entities/lead_note.dart';
import '../repositories/lead_notes_repository.dart';

class AddLeadNoteUseCase {
  const AddLeadNoteUseCase(this._repository);

  final LeadNotesRepository _repository;

  Future<LeadNote> call({
    required String companyId,
    required String leadId,
    required LeadNote note,
  }) {
    return _repository.addNote(
      companyId: companyId,
      leadId: leadId,
      note: note,
    );
  }
}
