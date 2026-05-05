import '../../domain/entities/lead_note.dart';
import '../../domain/repositories/lead_notes_repository.dart';
import '../datasources/lead_notes_remote_data_source.dart';
import '../models/lead_note_model.dart';

class LeadNotesRepositoryImpl implements LeadNotesRepository {
  const LeadNotesRepositoryImpl({
    required LeadNotesRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  final LeadNotesRemoteDataSource _remoteDataSource;

  @override
  Future<LeadNote> addNote({
    required String companyId,
    required String leadId,
    required LeadNote note,
  }) {
    return _remoteDataSource.addNote(
      companyId: companyId,
      leadId: leadId,
      note: LeadNoteModel.fromEntity(note),
    );
  }

  @override
  Stream<List<LeadNote>> watchNotes({
    required String companyId,
    required String leadId,
  }) {
    return _remoteDataSource.watchNotes(companyId: companyId, leadId: leadId);
  }
}
