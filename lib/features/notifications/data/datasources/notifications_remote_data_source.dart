import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../../../../core/constants/firebase_paths.dart';
import '../../../../core/constants/role_constants.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../domain/constants/notification_limits.dart';
import '../../domain/entities/attention_reminder.dart';
import '../../domain/errors/notification_exception.dart';
import '../models/crm_notification_model.dart';

abstract interface class NotificationsRemoteDataSource {
  Stream<List<CrmNotificationModel>> watchNotifications({
    required String companyId,
    required String recipientUid,
    int limit = notificationDropdownLimit,
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
    int limit = notificationMarkAllReadLimit,
  });

  Future<void> markAsRead({
    required String companyId,
    required String notificationId,
  });

  Future<void> markAllRead({
    required String companyId,
    required String recipientUid,
    int limit = 60,
  });

  Future<void> markResolved({
    required String companyId,
    required String notificationId,
  });

  Future<void> dismiss({
    required String companyId,
    required String notificationId,
  });
}

class FirestoreNotificationsRemoteDataSource
    implements NotificationsRemoteDataSource {
  FirestoreNotificationsRemoteDataSource({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _functions =
            functions ?? FirebaseFunctions.instanceFor(region: 'us-east1');

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  @override
  Stream<List<CrmNotificationModel>> watchNotifications({
    required String companyId,
    required String recipientUid,
    int limit = notificationDropdownLimit,
  }) {
    final safeLimit = _safeNotificationLimit(limit);
    final fetchLimit = _boundedNotificationFetchLimit(safeLimit);
    final controller = StreamController<List<CrmNotificationModel>>();

    List<CrmNotificationModel> orderedNotifications = const [];
    List<CrmNotificationModel> recipientNotifications = const [];
    Object? orderedError;
    Object? recipientError;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? orderedSub;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? recipientSub;

    void emitCombined() {
      final byId = <String, CrmNotificationModel>{};
      for (final notification in recipientNotifications) {
        byId[notification.id] = notification;
      }
      for (final notification in orderedNotifications) {
        byId[notification.id] = notification;
      }
      final notifications = byId.values
          .where((notification) => !notification.isDismissed)
          .toList()
        ..sort(_compareNotificationRecency);

      if (notifications.isEmpty && orderedError != null && recipientError != null) {
        if (!controller.isClosed) {
          controller.addError(
            NotificationException(_mapFirestoreError(orderedError!)),
          );
        }
        return;
      }

      if (!controller.isClosed) {
        controller.add(notifications.take(safeLimit).toList());
      }
    }

    List<CrmNotificationModel> parseSnapshot(
      QuerySnapshot<Map<String, dynamic>> snapshot,
    ) {
      final parsed = <CrmNotificationModel>[];
      for (final document in snapshot.docs) {
        try {
          final notification = CrmNotificationModel.fromFirestore(document);
          _ensureRecipient(
            companyId: companyId,
            recipientUid: recipientUid,
            notification: notification,
          );
          parsed.add(notification);
        } on NotificationException catch (error) {
          if (error.message == AppErrorMessages.permissionDenied) {
            rethrow;
          }
          // Keep the center usable when one legacy notification document has
          // malformed optional fields. Valid documents should still load.
        } catch (_) {
          // Keep the center usable when one legacy notification document has
          // malformed optional fields. Valid documents should still load.
        }
      }
      return parsed;
    }

    orderedSub = _notificationsCollection(companyId)
        .where('recipientUid', isEqualTo: recipientUid)
        .orderBy('createdAt', descending: true)
        .limit(fetchLimit)
        .snapshots()
        .listen(
      (snapshot) {
        try {
          orderedError = null;
          orderedNotifications = parseSnapshot(snapshot);
          emitCombined();
        } catch (error) {
          orderedError = error;
          orderedNotifications = const [];
          emitCombined();
        }
      },
      onError: (Object error) {
        orderedError = error;
        orderedNotifications = const [];
        emitCombined();
      },
    );

    // Legacy repair path: older notification docs may miss createdAt, isRead,
    // or actionState. Firestore orderBy('createdAt') excludes those docs, so a
    // bounded recipient-scoped stream keeps old notifications visible without
    // opening broad company reads.
    recipientSub = _notificationsCollection(companyId)
        .where('recipientUid', isEqualTo: recipientUid)
        .limit(fetchLimit)
        .snapshots()
        .listen(
      (snapshot) {
        try {
          recipientError = null;
          recipientNotifications = parseSnapshot(snapshot);
          emitCombined();
        } catch (error) {
          recipientError = error;
          recipientNotifications = const [];
          emitCombined();
        }
      },
      onError: (Object error) {
        recipientError = error;
        recipientNotifications = const [];
        emitCombined();
      },
    );

    controller.onCancel = () async {
      await orderedSub?.cancel();
      await recipientSub?.cancel();
    };

    return controller.stream;
  }

  @override
  Stream<int> watchUnreadCount({
    required String companyId,
    required String recipientUid,
  }) {
    final controller = StreamController<int>();
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? unreadSub;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? legacySub;
    Timer? timingRefreshTimer;
    var timingRefreshInFlight = false;
    Set<String> unreadIds = <String>{};
    Set<String> legacyUnreadIds = <String>{};

    void emitCount() {
      if (controller.isClosed) {
        return;
      }
      controller.add({...unreadIds, ...legacyUnreadIds}.length);
    }

    Future<void> refreshTimingNotifications() async {
      if (timingRefreshInFlight || controller.isClosed) {
        return;
      }
      timingRefreshInFlight = true;
      try {
        await _refreshAppointmentTimingNotifications(companyId: companyId);
        await _refreshActionableReminderNotifications(companyId: companyId);
      } on FirebaseFunctionsException {
        // Best-effort safety net. Keep the bell usable if a callable has not
        // been deployed yet or the network is temporarily unavailable.
      } catch (_) {
        // Keep notification streams usable even if timing refresh fails.
      } finally {
        timingRefreshInFlight = false;
      }
    }

    unreadSub = _notificationsCollection(companyId)
        .where('recipientUid', isEqualTo: recipientUid)
        .where('isRead', isEqualTo: false)
        .limit(notificationUnreadCountLimit)
        .snapshots()
        .listen(
      (snapshot) {
        try {
          unreadIds = _safeParseNotifications(
            snapshot,
            companyId: companyId,
            recipientUid: recipientUid,
          )
              .where((notification) =>
                  !notification.isRead && !notification.isDismissed)
              .map((notification) => notification.id)
              .toSet();
          emitCount();
        } catch (error) {
          if (!controller.isClosed) {
            controller.addError(NotificationException(_mapFirestoreError(error)));
          }
        }
      },
      onError: (Object error) {
        if (!controller.isClosed) {
          controller.addError(NotificationException(_mapFirestoreError(error)));
        }
      },
    );

    // Count unread legacy docs that do not have isRead=false and therefore do
    // not appear in the indexed unread query.
    legacySub = _notificationsCollection(companyId)
        .where('recipientUid', isEqualTo: recipientUid)
        .limit(notificationUnreadCountLimit)
        .snapshots()
        .listen(
      (snapshot) {
        try {
          legacyUnreadIds = _safeParseNotifications(
            snapshot,
            companyId: companyId,
            recipientUid: recipientUid,
          )
              .where((notification) =>
                  !notification.isRead && !notification.isDismissed)
              .map((notification) => notification.id)
              .toSet();
          emitCount();
        } catch (error) {
          if (!controller.isClosed) {
            controller.addError(NotificationException(_mapFirestoreError(error)));
          }
        }
      },
      onError: (Object error) {
        if (!controller.isClosed) {
          controller.addError(NotificationException(_mapFirestoreError(error)));
        }
      },
    );

    unawaited(refreshTimingNotifications());
    timingRefreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => unawaited(refreshTimingNotifications()),
    );

    controller.onCancel = () async {
      timingRefreshTimer?.cancel();
      await unreadSub?.cancel();
      await legacySub?.cancel();
    };

    return controller.stream;
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
    List<AttentionReminder> latestAppointmentReminders = const [];
    List<QueryDocumentSnapshot<Map<String, dynamic>>> latestAppointmentDocs =
        const [];
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? leadsSub;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? tasksSub;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? appointmentsSub;
    Timer? appointmentTicker;
    var timingRefreshInFlight = false;

    Future<void> refreshTimingNotifications() async {
      if (timingRefreshInFlight || controller.isClosed) {
        return;
      }
      timingRefreshInFlight = true;
      try {
        await _refreshAppointmentTimingNotifications(companyId: companyId);
        // Do not create persistent notification documents for general
        // follow-up/task/deal suggestions. The live Attention section already
        // shows them without inflating the bell count or unread list.
      } on FirebaseFunctionsException {
        // Timing refresh is a best-effort safety net. The scheduled backend
        // function remains the source of truth, so do not break the
        // notification UI if the callable is not deployed yet or is delayed.
      } catch (_) {
        // Keep notification streams usable even if the timing refresh fails.
      } finally {
        timingRefreshInFlight = false;
      }
    }

    void emitCombined() {
      final reminders = [
        ...latestAppointmentReminders,
        ...latestLeadReminders,
        ...latestTaskReminders,
      ];
      reminders.sort(_compareReminderUrgency);
      if (!controller.isClosed) {
        controller.add(reminders.take(limit).toList());
      }
    }

    void refreshAppointmentReminders() {
      try {
        latestAppointmentReminders = _appointmentRemindersFromDocs(
          latestAppointmentDocs,
          companyId: companyId,
        );
        emitCombined();
      } catch (error) {
        if (!controller.isClosed) {
          controller.addError(NotificationException(_mapFirestoreError(error)));
        }
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

    appointmentsSub = _appointmentReminderQuery(
      companyId: companyId,
      currentUserId: currentUserId,
      role: role,
      managerTeamId: managerTeamId,
      limit: limit,
    ).snapshots().listen(
      (snapshot) {
        latestAppointmentDocs = snapshot.docs;
        refreshAppointmentReminders();
      },
      onError: (Object error) {
        if (!controller.isClosed) {
          controller.addError(NotificationException(_mapFirestoreError(error)));
        }
      },
    );

    unawaited(refreshTimingNotifications());

    appointmentTicker = Timer.periodic(
      const Duration(minutes: 1),
      (_) {
        unawaited(refreshTimingNotifications());
        refreshAppointmentReminders();
      },
    );

    controller.onCancel = () async {
      appointmentTicker?.cancel();
      await leadsSub?.cancel();
      await tasksSub?.cancel();
      await appointmentsSub?.cancel();
    };

    return controller.stream;
  }

  @override
  Future<void> markAsRead({
    required String companyId,
    required String notificationId,
  }) async {
    try {
      final callable = _functions.httpsCallable('markCompanyNotificationRead');
      await callable.call(<String, Object?>{
        'companyId': companyId,
        'notificationId': notificationId,
      });
    } on FirebaseFunctionsException catch (error) {
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
      final callable = _functions.httpsCallable('markCompanyNotificationsRead');
      await callable.call(<String, Object?>{
        'companyId': companyId,
        'limit': limit,
      });
    } on FirebaseFunctionsException catch (error) {
      throw NotificationException(_mapFirestoreError(error));
    } catch (_) {
      throw const NotificationException(AppErrorMessages.unknown);
    }
  }


  @override
  Future<void> markResolved({
    required String companyId,
    required String notificationId,
  }) async {
    try {
      await _notificationsCollection(companyId).doc(notificationId).update({
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
        'actionState': 'resolved',
        'resolvedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (error) {
      throw NotificationException(_mapFirestoreError(error));
    } catch (_) {
      throw const NotificationException(AppErrorMessages.unknown);
    }
  }

  @override
  Future<void> dismiss({
    required String companyId,
    required String notificationId,
  }) async {
    try {
      await _notificationsCollection(companyId).doc(notificationId).update({
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
        'actionState': 'dismissed',
        'dismissedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
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
      query = query
          .where('assignedTo', isEqualTo: currentUserId)
          .where('isArchived', isEqualTo: false);
    }
    return query.limit(limit * 3);
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
      query = query
          .where('assignedTo', isEqualTo: currentUserId)
          .where('isActive', isEqualTo: true);
    }
    return query.limit(limit * 3);
  }

  Query<Map<String, dynamic>> _appointmentReminderQuery({
    required String companyId,
    required String currentUserId,
    required UserRole role,
    String? managerTeamId,
    required int limit,
  }) {
    Query<Map<String, dynamic>> query = _firestore.collection(
      FirebasePaths.companyAppointments(companyId),
    );
    if (role == UserRole.manager) {
      final teamId = (managerTeamId ?? '').trim();
      query = teamId.isNotEmpty
          ? query.where('teamId', isEqualTo: teamId)
          : query.where('managerId', isEqualTo: currentUserId);
    } else if (role == UserRole.salesAgent || role == UserRole.marketing) {
      query = query.where('assignedTo', isEqualTo: currentUserId);
    }
    return query.limit(limit * 3);
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
      final status = (data['status'] as String? ?? '').trim();
      if (status == 'won' || status == 'lost') {
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

  List<AttentionReminder> _appointmentRemindersFromDocs(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> documents, {
    required String companyId,
  }) {
    final now = DateTime.now();
    final today = _dateOnly(now);
    final soonCutoff = now.add(const Duration(hours: 2));
    final reminders = <AttentionReminder>[];
    for (final document in documents) {
      final data = document.data();
      if ((data['companyId'] as String? ?? '') != companyId) {
        throw const NotificationException(AppErrorMessages.permissionDenied);
      }
      final status = data['status'] as String? ?? '';
      if (status == 'completed' || status == 'cancelled') {
        continue;
      }
      final scheduledAt = _dateTimeFromValue(data['scheduledAt']);
      if (scheduledAt == null) {
        continue;
      }
      final scheduledDay = _dateOnly(scheduledAt);
      final isStoredMissed = status == 'missed';
      final isOpenScheduled =
          status == 'scheduled' || status == 'rescheduled';
      final secondsPastStart =
          now.difference(scheduledAt.toLocal()).inSeconds;
      final isDueNow = isOpenScheduled &&
          !scheduledAt.toLocal().isAfter(now) &&
          secondsPastStart < 60;
      final isOverdueScheduled = isOpenScheduled && secondsPastStart >= 60;
      final isUpcomingSoon =
          scheduledAt.toLocal().isAfter(now) &&
          scheduledAt.toLocal().isBefore(soonCutoff);
      final isToday = scheduledDay == today;

      AttentionReminderType? type;
      if (isStoredMissed || isOverdueScheduled) {
        type = AttentionReminderType.appointmentMissed;
      } else if (isDueNow) {
        type = AttentionReminderType.appointmentDueNow;
      } else if (isUpcomingSoon) {
        type = AttentionReminderType.appointmentUpcomingSoon;
      } else if (isToday) {
        type = AttentionReminderType.appointmentToday;
      }
      if (type == null) {
        continue;
      }

      final relatedTitle = data['relatedTitle'] as String? ?? '';
      final relatedSubtitle = data['relatedSubtitle'] as String? ?? '';
      final location = data['location'] as String? ?? '';
      reminders.add(
        AttentionReminder(
          id: 'appointment-${document.id}-${type.name}-${scheduledAt.toLocal().millisecondsSinceEpoch}',
          type: type,
          module: 'appointments',
          recordId: document.id,
          recordTitle: data['title'] as String? ?? '',
          recordSubtitle: relatedTitle.trim().isNotEmpty
              ? relatedTitle
              : relatedSubtitle.trim().isNotEmpty
                  ? relatedSubtitle
                  : location,
          route: RouteNames.appointments,
          dueAt: scheduledAt,
          assignedToName: data['assignedToName'] as String? ?? '',
        ),
      );
    }
    return reminders;
  }

  Future<void> _refreshAppointmentTimingNotifications({
    required String companyId,
  }) async {
    final callable = _functions.httpsCallable(
      'refreshAppointmentTimingNotifications',
    );
    await callable.call(<String, Object?>{
      'companyId': companyId,
    });
  }

  Future<void> _refreshActionableReminderNotifications({
    required String companyId,
  }) async {
    final callable = _functions.httpsCallable(
      'refreshActionableReminderNotifications',
    );
    await callable.call(<String, Object?>{
      'companyId': companyId,
    });
  }


  CollectionReference<Map<String, dynamic>> _notificationsCollection(
    String companyId,
  ) {
    return _firestore.collection(FirebasePaths.companyNotifications(companyId));
  }
}



int _safeNotificationLimit(int limit) {
  if (limit <= 0) {
    return notificationDropdownLimit;
  }
  if (limit > 300) {
    return 300;
  }
  return limit;
}

int _boundedNotificationFetchLimit(int displayLimit) {
  final minimum = displayLimit <= notificationDropdownLimit ? 120 : 500;
  final computed = displayLimit * 8;
  final effective = computed < minimum ? minimum : computed;
  return effective > 900 ? 900 : effective;
}


List<CrmNotificationModel> _safeParseNotifications(
  QuerySnapshot<Map<String, dynamic>> snapshot, {
  required String companyId,
  required String recipientUid,
}) {
  final parsed = <CrmNotificationModel>[];
  for (final document in snapshot.docs) {
    try {
      final notification = CrmNotificationModel.fromFirestore(document);
      _ensureRecipient(
        companyId: companyId,
        recipientUid: recipientUid,
        notification: notification,
      );
      parsed.add(notification);
    } on NotificationException catch (error) {
      if (error.message == AppErrorMessages.permissionDenied) {
        rethrow;
      }
    } catch (_) {
      // Skip malformed legacy notification docs instead of breaking the badge
      // or notification center for every valid document.
    }
  }
  return parsed;
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
    AttentionReminderType.appointmentMissed => 0,
    AttentionReminderType.appointmentDueNow => 1,
    AttentionReminderType.followUpOverdue => 2,
    AttentionReminderType.taskOverdue => 3,
    AttentionReminderType.unassignedLead => 4,
    AttentionReminderType.appointmentUpcomingSoon => 5,
    AttentionReminderType.appointmentToday => 6,
    AttentionReminderType.followUpDueToday => 7,
    AttentionReminderType.taskDueToday => 8,
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
