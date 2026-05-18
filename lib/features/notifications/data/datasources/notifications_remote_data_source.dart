import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/firebase_paths.dart';
import '../../../../core/constants/role_constants.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../domain/constants/notification_limits.dart';
import '../../domain/entities/attention_reminder.dart';
import '../../domain/errors/notification_exception.dart';
import '../models/crm_notification_model.dart';

abstract interface class NotificationsRemoteDataSource {
  Stream<List<CrmNotificationModel>> watchNotifications({
    required String companyId,
    required String recipientUid,
    int limit,
  });

  Stream<int> watchUnreadCount({
    required String companyId,
    required String recipientUid,
  });

  Stream<List<AttentionReminder>> watchAttentionReminders({
    required String companyId,
    required String currentUserId,
    required UserRole role,
    String? managerTeamId,
    int limit,
  });

  Future<void> markAsRead({
    required String companyId,
    required String notificationId,
  });

  Future<void> markAllRead({
    required String companyId,
    required String recipientUid,
    int limit,
  });
}

class FirestoreNotificationsRemoteDataSource
    implements NotificationsRemoteDataSource {
  FirestoreNotificationsRemoteDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Stream<List<CrmNotificationModel>> watchNotifications({
    required String companyId,
    required String recipientUid,
    int limit = notificationDropdownLimit,
  }) {
    return _notificationsCollection(companyId)
        .where('recipientUid', isEqualTo: recipientUid)
        .snapshots()
        .map((snapshot) {
      final notifications = snapshot.docs.map((document) {
        final notification = CrmNotificationModel.fromFirestore(document);
        _ensureRecipient(
          companyId: companyId,
          recipientUid: recipientUid,
          notification: notification,
        );
        return notification;
      }).toList()
        ..sort(_compareNotificationRecency);
      return notifications.take(limit).toList();
    }).handleError((Object error) {
      throw NotificationException(_mapFirestoreError(error));
    });
  }

  @override
  Stream<int> watchUnreadCount({
    required String companyId,
    required String recipientUid,
  }) {
    return _notificationsCollection(companyId)
        .where('recipientUid', isEqualTo: recipientUid)
        .snapshots()
        .map((snapshot) {
      var unreadCount = 0;
      for (final document in snapshot.docs) {
        final notification = CrmNotificationModel.fromFirestore(document);
        _ensureRecipient(
          companyId: companyId,
          recipientUid: recipientUid,
          notification: notification,
        );
        if (!notification.isRead) {
          unreadCount += 1;
        }
      }
      return unreadCount;
    }).handleError((Object error) {
      throw NotificationException(_mapFirestoreError(error));
    });
  }

  @override
  Stream<List<AttentionReminder>> watchAttentionReminders({
    required String companyId,
    required String currentUserId,
    required UserRole role,
    String? managerTeamId,
    int limit = notificationMarkAllReadLimit,
  }) {
    if (role == UserRole.viewer) {
      return Stream<List<AttentionReminder>>.value(const []);
    }

    final controller = StreamController<List<AttentionReminder>>();
    List<AttentionReminder> latestLeadReminders = const [];
    List<AttentionReminder> latestTaskReminders = const [];
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? leadsSub;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? tasksSub;

    void emitCombined() {
      final reminders = [...latestLeadReminders, ...latestTaskReminders];
      reminders.sort(_compareReminderUrgency);
      if (!controller.isClosed) {
        controller.add(reminders.take(limit).toList());
      }
    }

    leadsSub = _leadReminderQuery(
      companyId: companyId,
      currentUserId: currentUserId,
      role: role,
      managerTeamId: managerTeamId,
      limit: limit,
    ).snapshots().listen(
      (snapshot) {
        latestLeadReminders = _leadRemindersFromSnapshot(
          snapshot,
          companyId: companyId,
          role: role,
        );
        emitCombined();
      },
      onError: (Object error) {
        if (!controller.isClosed) {
          controller.addError(NotificationException(_mapFirestoreError(error)));
        }
      },
    );

    tasksSub = _taskReminderQuery(
      companyId: companyId,
      currentUserId: currentUserId,
      role: role,
      managerTeamId: managerTeamId,
      limit: limit,
    ).snapshots().listen(
      (snapshot) {
        latestTaskReminders = _taskRemindersFromSnapshot(
          snapshot,
          companyId: companyId,
        );
        emitCombined();
      },
      onError: (Object error) {
        if (!controller.isClosed) {
          controller.addError(NotificationException(_mapFirestoreError(error)));
        }
      },
    );

    controller.onCancel = () async {
      await leadsSub?.cancel();
      await tasksSub?.cancel();
    };

    return controller.stream;
  }

  @override
  Future<void> markAsRead({
    required String companyId,
    required String notificationId,
  }) async {
    try {
      await _notificationsCollection(companyId).doc(notificationId).update({
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (error) {
      throw NotificationException(_mapFirestoreError(error));
    } catch (_) {
      throw const NotificationException(AppErrorMessages.unknown);
    }
  }

  @override
  Future<void> markAllRead({
    required String companyId,
    required String recipientUid,
    int limit = 60,
  }) async {
    try {
      final snapshot = await _notificationsCollection(companyId)
          .where('recipientUid', isEqualTo: recipientUid)
          .limit(limit)
          .get();
      if (snapshot.docs.isEmpty) {
        return;
      }
      final batch = _firestore.batch();
      var hasUpdates = false;
      for (final document in snapshot.docs) {
        final notification = CrmNotificationModel.fromFirestore(document);
        _ensureRecipient(
          companyId: companyId,
          recipientUid: recipientUid,
          notification: notification,
        );
        if (notification.isRead) {
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
      throw NotificationException(_mapFirestoreError(error));
    } catch (_) {
      throw const NotificationException(AppErrorMessages.unknown);
    }
  }

  Query<Map<String, dynamic>> _leadReminderQuery({
    required String companyId,
    required String currentUserId,
    required UserRole role,
    String? managerTeamId,
    required int limit,
  }) {
    Query<Map<String, dynamic>> query = _firestore.collection(
      FirebasePaths.companyLeads(companyId),
    );
    if (role == UserRole.manager) {
      final teamId = (managerTeamId ?? '').trim();
      query = teamId.isNotEmpty
          ? query.where('teamId', isEqualTo: teamId)
          : query.where('managerId', isEqualTo: currentUserId);
    } else if (role == UserRole.salesAgent || role == UserRole.marketing) {
      query = query.where('assignedTo', isEqualTo: currentUserId);
    }
    return query.limit(limit);
  }

  Query<Map<String, dynamic>> _taskReminderQuery({
    required String companyId,
    required String currentUserId,
    required UserRole role,
    String? managerTeamId,
    required int limit,
  }) {
    Query<Map<String, dynamic>> query = _firestore.collection(
      FirebasePaths.companyTasks(companyId),
    );
    if (role == UserRole.manager) {
      final teamId = (managerTeamId ?? '').trim();
      query = teamId.isNotEmpty
          ? query.where('teamId', isEqualTo: teamId)
          : query.where('managerId', isEqualTo: currentUserId);
    } else if (role == UserRole.salesAgent || role == UserRole.marketing) {
      query = query.where('assignedTo', isEqualTo: currentUserId);
    }
    return query.limit(limit);
  }

  List<AttentionReminder> _leadRemindersFromSnapshot(
    QuerySnapshot<Map<String, dynamic>> snapshot, {
    required String companyId,
    required UserRole role,
  }) {
    final today = _dateOnly(DateTime.now());
    final reminders = <AttentionReminder>[];
    for (final document in snapshot.docs) {
      final data = document.data();
      if ((data['companyId'] as String? ?? '') != companyId) {
        throw const NotificationException(AppErrorMessages.permissionDenied);
      }
      if ((data['isArchived'] as bool?) ?? false) {
        continue;
      }
      final title = data['fullName'] as String? ?? '';
      final subtitle =
          (data['sourceDetails'] as String? ?? '').trim().isNotEmpty
              ? data['sourceDetails'] as String
              : data['source'] as String? ?? '';
      final nextFollowUpAt = _dateTimeFromValue(data['nextFollowUpAt']);
      if (nextFollowUpAt != null) {
        final followUpDay = _dateOnly(nextFollowUpAt);
        if (followUpDay.isBefore(today) || followUpDay == today) {
          reminders.add(
            AttentionReminder(
              id: 'lead-${document.id}-${followUpDay.toIso8601String()}',
              type: followUpDay.isBefore(today)
                  ? AttentionReminderType.followUpOverdue
                  : AttentionReminderType.followUpDueToday,
              module: 'leads',
              recordId: document.id,
              recordTitle: title,
              recordSubtitle: subtitle,
              route: '/leads/${document.id}',
              dueAt: nextFollowUpAt,
              assignedToName: data['assignedToName'] as String? ?? '',
            ),
          );
        }
      }
      if (role == UserRole.admin &&
          (data['assignedTo'] as String? ?? '').trim().isEmpty) {
        reminders.add(
          AttentionReminder(
            id: 'lead-${document.id}-unassigned',
            type: AttentionReminderType.unassignedLead,
            module: 'leads',
            recordId: document.id,
            recordTitle: title,
            recordSubtitle: subtitle,
            route: '/leads/${document.id}',
            dueAt: null,
            assignedToName: '',
          ),
        );
      }
    }
    return reminders;
  }

  List<AttentionReminder> _taskRemindersFromSnapshot(
    QuerySnapshot<Map<String, dynamic>> snapshot, {
    required String companyId,
  }) {
    final today = _dateOnly(DateTime.now());
    final reminders = <AttentionReminder>[];
    for (final document in snapshot.docs) {
      final data = document.data();
      if ((data['companyId'] as String? ?? '') != companyId) {
        throw const NotificationException(AppErrorMessages.permissionDenied);
      }
      if (data['isActive'] == false) {
        continue;
      }
      final status = data['status'] as String? ?? '';
      if (status == 'completed' || status == 'cancelled') {
        continue;
      }
      final dueDate = _dateTimeFromValue(data['dueDate']);
      if (dueDate == null) {
        continue;
      }
      final dueDay = _dateOnly(dueDate);
      if (dueDay.isAfter(today)) {
        continue;
      }
      reminders.add(
        AttentionReminder(
          id: 'task-${document.id}-${dueDay.toIso8601String()}',
          type: dueDay.isBefore(today)
              ? AttentionReminderType.taskOverdue
              : AttentionReminderType.taskDueToday,
          module: 'tasks',
          recordId: document.id,
          recordTitle: data['title'] as String? ?? '',
          recordSubtitle: (data['relatedTitle'] as String? ?? '').isNotEmpty
              ? data['relatedTitle'] as String
              : data['relatedSubtitle'] as String? ?? '',
          route: '/tasks/${document.id}/edit',
          dueAt: dueDate,
          assignedToName: data['assignedToName'] as String? ?? '',
        ),
      );
    }
    return reminders;
  }

  CollectionReference<Map<String, dynamic>> _notificationsCollection(
    String companyId,
  ) {
    return _firestore.collection(FirebasePaths.companyNotifications(companyId));
  }
}


int _compareNotificationRecency(
  CrmNotificationModel a,
  CrmNotificationModel b,
) {
  final aDate = a.createdAt ?? a.readAt ?? DateTime.fromMillisecondsSinceEpoch(0);
  final bDate = b.createdAt ?? b.readAt ?? DateTime.fromMillisecondsSinceEpoch(0);
  final dateCompare = bDate.compareTo(aDate);
  if (dateCompare != 0) {
    return dateCompare;
  }
  if (a.isRead != b.isRead) {
    return a.isRead ? 1 : -1;
  }
  return b.id.compareTo(a.id);
}

void _ensureRecipient({
  required String companyId,
  required String recipientUid,
  required CrmNotificationModel notification,
}) {
  final notificationCompanyId = notification.companyId.trim();
  if ((notificationCompanyId.isNotEmpty && notificationCompanyId != companyId) ||
      notification.recipientUid != recipientUid) {
    throw const NotificationException(AppErrorMessages.permissionDenied);
  }
}

int _compareReminderUrgency(AttentionReminder a, AttentionReminder b) {
  final group = _reminderGroup(a).compareTo(_reminderGroup(b));
  if (group != 0) {
    return group;
  }
  final aDate = a.dueAt ?? DateTime.fromMillisecondsSinceEpoch(0);
  final bDate = b.dueAt ?? DateTime.fromMillisecondsSinceEpoch(0);
  return aDate.compareTo(bDate);
}

int _reminderGroup(AttentionReminder reminder) {
  return switch (reminder.type) {
    AttentionReminderType.followUpOverdue => 0,
    AttentionReminderType.taskOverdue => 1,
    AttentionReminderType.unassignedLead => 2,
    AttentionReminderType.followUpDueToday => 3,
    AttentionReminderType.taskDueToday => 4,
  };
}

DateTime _dateOnly(DateTime value) {
  final local = value.toLocal();
  return DateTime(local.year, local.month, local.day);
}

DateTime? _dateTimeFromValue(Object? value) {
  if (value is Timestamp) {
    return value.toDate();
  }
  if (value is DateTime) {
    return value;
  }
  return null;
}

String _mapFirestoreError(Object error) {
  if (error is NotificationException) {
    return error.message;
  }
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
      case 'not-found':
        return AppErrorMessages.notFound;
      case 'cancelled':
        return AppErrorMessages.cancelled;
      default:
        return AppErrorMessages.unknown;
    }
  }
  return AppErrorMessages.unknown;
}
