import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/firebase_paths.dart';
import '../../../../core/errors/error_mapper.dart';
import '../models/platform_notification_model.dart';

const _platformUnreadCountLimit = 1000;

abstract interface class PlatformNotificationsRemoteDataSource {
  Stream<List<PlatformNotificationModel>> watchNotifications({int limit});

  Stream<int> watchUnreadCount();

  Future<void> markRead({
    required String notificationId,
    required bool isRead,
  });

  Future<void> markAllRead({int limit});
}

class FirestorePlatformNotificationsRemoteDataSource
    implements PlatformNotificationsRemoteDataSource {
  FirestorePlatformNotificationsRemoteDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Stream<List<PlatformNotificationModel>> watchNotifications({int limit = 80}) {
    return _collection
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      final notifications = snapshot.docs
          .map(PlatformNotificationModel.fromFirestore)
          .toList()
        ..sort(_compareNotificationRecency);
      return notifications.take(limit).toList(growable: false);
    }).handleError((Object error) {
      throw Exception(_mapFirestoreError(error));
    });
  }

  @override
  Stream<int> watchUnreadCount() {
    return _collection
        .where('isRead', isEqualTo: false)
        .limit(_platformUnreadCountLimit)
        .snapshots()
        .map((snapshot) => snapshot.docs.length)
        .handleError((Object error) {
      throw Exception(_mapFirestoreError(error));
    });
  }

  @override
  Future<void> markRead({
    required String notificationId,
    required bool isRead,
  }) async {
    try {
      await _collection.doc(notificationId).update({
        'isRead': isRead,
        'readAt': isRead ? FieldValue.serverTimestamp() : null,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (error) {
      throw Exception(_mapFirestoreError(error));
    }
  }

  @override
  Future<void> markAllRead({int limit = 100}) async {
    try {
      final snapshot = await _collection
          .where('isRead', isEqualTo: false)
          .limit(limit)
          .get();
      if (snapshot.docs.isEmpty) {
        return;
      }
      final batch = _firestore.batch();
      var hasUpdates = false;
      for (final document in snapshot.docs) {
        if (document.data()['isRead'] == true) {
          continue;
        }
        hasUpdates = true;
        batch.update(document.reference, {
          'isRead': true,
          'readAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      if (hasUpdates) {
        await batch.commit();
      }
    } on FirebaseException catch (error) {
      throw Exception(_mapFirestoreError(error));
    }
  }

  CollectionReference<Map<String, dynamic>> get _collection {
    return _firestore.collection(FirebasePaths.platformNotifications());
  }
}

int _compareNotificationRecency(
  PlatformNotificationModel a,
  PlatformNotificationModel b,
) {
  final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
  final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
  final dateCompare = bDate.compareTo(aDate);
  if (dateCompare != 0) {
    return dateCompare;
  }
  if (a.isRead != b.isRead) {
    return a.isRead ? 1 : -1;
  }
  return b.id.compareTo(a.id);
}

String _mapFirestoreError(Object error) {
  if (error is FirebaseException) {
    switch (error.code) {
      case 'unavailable':
      case 'network-request-failed':
      case 'deadline-exceeded':
        return AppErrorMessages.unableToConnect;
      case 'permission-denied':
        return AppErrorMessages.permissionDenied;
      case 'unauthenticated':
        return AppErrorMessages.unauthenticated;
      default:
        return AppErrorMessages.unknown;
    }
  }
  return AppErrorMessages.unknown;
}
