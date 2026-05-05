import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/lead_note.dart';

class LeadNoteModel extends LeadNote {
  const LeadNoteModel({
    required super.id,
    required super.leadId,
    required super.companyId,
    required super.text,
    required super.createdAt,
    required super.createdBy,
  });

  factory LeadNoteModel.fromEntity(LeadNote note) {
    return LeadNoteModel(
      id: note.id,
      leadId: note.leadId,
      companyId: note.companyId,
      text: note.text,
      createdAt: note.createdAt,
      createdBy: note.createdBy,
    );
  }

  factory LeadNoteModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    if (data == null) {
      throw StateError('Lead note data was not found.');
    }

    return LeadNoteModel(
      id: data['id'] as String? ?? document.id,
      leadId: data['leadId'] as String? ?? '',
      companyId: data['companyId'] as String? ?? '',
      text: data['text'] as String? ?? '',
      createdAt: _dateTimeFromValue(data['createdAt']),
      createdBy: data['createdBy'] as String? ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'leadId': leadId,
      'companyId': companyId,
      'text': text,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
    };
  }
}

DateTime _dateTimeFromValue(Object? value) {
  if (value is Timestamp) {
    return value.toDate();
  }

  if (value is DateTime) {
    return value;
  }

  return DateTime.fromMillisecondsSinceEpoch(0);
}
