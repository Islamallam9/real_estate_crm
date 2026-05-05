import '../entities/lead_note.dart';

abstract interface class LeadNotesRepository {
  Future<LeadNote> addNote({
    required String companyId,
    required String leadId,
    required LeadNote note,
  });

  Stream<List<LeadNote>> watchNotes({
    required String companyId,
    required String leadId,
  });
}
