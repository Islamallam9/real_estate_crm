import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/firebase_paths.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../domain/errors/lead_exception.dart';
import '../models/lead_timeline_event_model.dart';

abstract interface class LeadTimelineRemoteDataSource {
  Future<LeadTimelineEventModel> addEvent({
    required String companyId,
    required String leadId,
    required LeadTimelineEventModel event,
  });

  Stream<List<LeadTimelineEventModel>> watchTimeline({
    required String companyId,
    required String leadId,
  });
}

class FirestoreLeadTimelineRemoteDataSource
    implements LeadTimelineRemoteDataSource {
  FirestoreLeadTimelineRemoteDataSource({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Future<LeadTimelineEventModel> addEvent({
    required String companyId,
    required String leadId,
    required LeadTimelineEventModel event,
  }) async {
    if (event.companyId != companyId || event.leadId != leadId) {
      throw const LeadException(
        'You do not have permission to update this lead.',
      );
    }

    try {
      final collection = _timelineCollection(
        companyId: companyId,
        leadId: leadId,
      );
      final document = event.id.isEmpty
          ? collection.doc()
          : collection.doc(event.id);
      final eventToSave = LeadTimelineEventModel.fromEntity(
        event.copyWith(id: document.id),
      );
      final payload = eventToSave.toFirestore();
      payload['createdAt'] = FieldValue.serverTimestamp();
      await document.set(payload);
      return eventToSave.copyWith(createdAt: DateTime.now());
    } on FirebaseException catch (error) {
      throw LeadException(_mapFirestoreError(error));
    } catch (_) {
      throw const LeadException('Unable to update lead timeline.');
    }
  }

  @override
  Stream<List<LeadTimelineEventModel>> watchTimeline({
    required String companyId,
    required String leadId,
  }) {
    return _timelineCollection(
      companyId: companyId,
      leadId: leadId,
    ).orderBy('createdAt', descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map(LeadTimelineEventModel.fromFirestore).where((
        event,
      ) {
        return event.companyId == companyId && event.leadId == leadId;
      }).toList();
    });
  }

  CollectionReference<Map<String, dynamic>> _timelineCollection({
    required String companyId,
    required String leadId,
  }) {
    return _firestore.collection(
      '${FirebasePaths.companyLeads(companyId)}/$leadId/timeline',
    );
  }
}

String _mapFirestoreError(FirebaseException error) {
  switch (error.code) {
    case 'unavailable':
    case 'network-request-failed':
    case 'deadline-exceeded':
      return AppErrorMessages.unableToConnect;
    case 'permission-denied':
      return AppErrorMessages.permissionDenied;
    case 'unauthenticated':
      return AppErrorMessages.unauthenticated;
    case 'not-found':
      return AppErrorMessages.notFound;
    case 'cancelled':
      return AppErrorMessages.cancelled;
    default:
      return AppErrorMessages.unknown;
  }
}

extension on LeadTimelineEventModel {
  LeadTimelineEventModel copyWith({String? id, DateTime? createdAt}) {
    return LeadTimelineEventModel(
      id: id ?? this.id,
      leadId: leadId,
      companyId: companyId,
      type: type,
      title: title,
      description: description,
      oldValue: oldValue,
      newValue: newValue,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy,
      createdByName: createdByName,
      metadata: metadata,
    );
  }
}
