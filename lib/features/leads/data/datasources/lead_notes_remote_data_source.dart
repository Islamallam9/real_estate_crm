import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/firebase_paths.dart';
import '../../domain/errors/lead_exception.dart';
import '../models/lead_note_model.dart';

abstract interface class LeadNotesRemoteDataSource {
  Future<LeadNoteModel> addNote({
    required String companyId,
    required String leadId,
    required LeadNoteModel note,
  });

  Stream<List<LeadNoteModel>> watchNotes({
    required String companyId,
    required String leadId,
  });
}

class FirestoreLeadNotesRemoteDataSource implements LeadNotesRemoteDataSource {
  FirestoreLeadNotesRemoteDataSource({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Future<LeadNoteModel> addNote({
    required String companyId,
    required String leadId,
    required LeadNoteModel note,
  }) async {
    _ensureSameCompany(companyId: companyId, leadId: leadId, note: note);

    try {
      final collection = _notesCollection(companyId: companyId, leadId: leadId);
      final document = note.id.isEmpty
          ? collection.doc()
          : collection.doc(note.id);
      final noteToSave = LeadNoteModel.fromEntity(
        LeadNoteModel(
          id: document.id,
          leadId: leadId,
          companyId: companyId,
          text: note.text,
          createdAt: note.createdAt,
          createdBy: note.createdBy,
        ),
      );

      await document.set(noteToSave.toFirestore());
      return noteToSave;
    } on LeadException {
      rethrow;
    } on FirebaseException catch (_) {
      throw const LeadException('Unable to add note. Please try again.');
    } catch (_) {
      throw const LeadException('Unable to add note. Please try again.');
    }
  }

  @override
  Stream<List<LeadNoteModel>> watchNotes({
    required String companyId,
    required String leadId,
  }) {
    return _notesCollection(
      companyId: companyId,
      leadId: leadId,
    ).orderBy('createdAt', descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map(LeadNoteModel.fromFirestore).where((note) {
        return note.companyId == companyId && note.leadId == leadId;
      }).toList();
    });
  }

  CollectionReference<Map<String, dynamic>> _notesCollection({
    required String companyId,
    required String leadId,
  }) {
    return _firestore.collection(
      '${FirebasePaths.companyLeads(companyId)}/$leadId/notes',
    );
  }
}

void _ensureSameCompany({
  required String companyId,
  required String leadId,
  required LeadNoteModel note,
}) {
  if (companyId.isEmpty ||
      note.companyId != companyId ||
      note.leadId != leadId) {
    throw const LeadException(
      'You do not have permission to access this note.',
    );
  }
}
