import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/firebase_paths.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../domain/entities/support_ticket.dart';
import '../../domain/entities/support_ticket_draft.dart';
import '../models/support_ticket_model.dart';

const _platformTicketsStreamLimit = 150;

abstract interface class SupportRemoteDataSource {
  Future<void> createTicket(SupportTicketDraft draft);

  Stream<List<SupportTicketModel>> watchMyTickets({required String userId});

  Stream<List<SupportTicketModel>> watchPlatformTickets();

  Future<void> updateTicketStatus({
    required String ticketId,
    required String status,
  });
}

class FirebaseSupportRemoteDataSource implements SupportRemoteDataSource {
  FirebaseSupportRemoteDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Future<void> createTicket(SupportTicketDraft draft) async {
    try {
      final document = _tickets.doc();
      await document.set({
        'id': document.id,
        'companyId': draft.companyId,
        'companyName': draft.companyName,
        'userId': draft.userId,
        'userName': draft.userName,
        'userEmail': draft.userEmail,
        'userRole': draft.userRole,
        'type': draft.type,
        'category': draft.category,
        'priority': draft.priority,
        'rating': draft.rating,
        'title': draft.title,
        'message': draft.message,
        'status': SupportTicketStatus.open,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'resolvedAt': null,
        'appVersion': draft.appVersion,
        'appBuildNumber': draft.appBuildNumber,
        'platform': draft.platform,
        'currentRoute': draft.currentRoute,
        'deviceInfo': draft.deviceInfo,
        'attachments': const <String>[],
        'lastReplyAt': null,
        'lastReplyBy': '',
      });
    } on FirebaseException catch (error) {
      throw Exception(_mapFirebaseError(error));
    }
  }

  @override
  Stream<List<SupportTicketModel>> watchMyTickets({required String userId}) {
    return _tickets.where('userId', isEqualTo: userId).snapshots().map(
      (snapshot) {
        final tickets = snapshot.docs
            .map(SupportTicketModel.fromFirestore)
            .where((ticket) => ticket.userId == userId)
            .toList()
          ..sort(_compareTickets);
        return tickets;
      },
    );
  }

  @override
  Stream<List<SupportTicketModel>> watchPlatformTickets() {
    return _tickets
        .orderBy('createdAt', descending: true)
        .limit(_platformTicketsStreamLimit)
        .snapshots()
        .map((snapshot) {
      final tickets = snapshot.docs
          .map(SupportTicketModel.fromFirestore)
          .toList()
        ..sort(_compareTickets);
      return tickets;
    });
  }

  @override
  Future<void> updateTicketStatus({
    required String ticketId,
    required String status,
  }) async {
    try {
      await _tickets.doc(ticketId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
        if (status == SupportTicketStatus.resolved ||
            status == SupportTicketStatus.closed)
          'resolvedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (error) {
      throw Exception(_mapFirebaseError(error));
    }
  }

  CollectionReference<Map<String, dynamic>> get _tickets {
    return _firestore.collection(FirebasePaths.supportTickets());
  }
}

int _compareTickets(SupportTicket a, SupportTicket b) {
  final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
  final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
  final dateCompare = bDate.compareTo(aDate);
  if (dateCompare != 0) {
    return dateCompare;
  }
  return b.id.compareTo(a.id);
}

String _mapFirebaseError(FirebaseException error) {
  return switch (error.code) {
    'unavailable' || 'deadline-exceeded' || 'network-request-failed' =>
      AppErrorMessages.unableToConnect,
    'permission-denied' => AppErrorMessages.permissionDenied,
    'unauthenticated' => AppErrorMessages.unauthenticated,
    _ => AppErrorMessages.unknown,
  };
}
