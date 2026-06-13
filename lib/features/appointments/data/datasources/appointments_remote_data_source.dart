import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/constants/firebase_paths.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../domain/entities/appointment.dart';
import '../../domain/entities/appointment_related_record_option.dart';
import '../../domain/errors/appointment_exception.dart';
import '../models/appointment_model.dart';

void _masarAppointmentsRemoteDebug(String message) {
  if (!kDebugMode) {
    return;
  }
  debugPrint('MasarAppointmentsRemoteDebug $message');
}

void _masarFirebaseIndexDebug(String message) {
  if (!kDebugMode) {
    return;
  }
  debugPrint('MasarFirebaseIndexDebug $message');
}

abstract interface class AppointmentsRemoteDataSource {
  Stream<List<AppointmentModel>> watchAppointments({
    required String companyId,
    String? assignedTo,
    String? managerId,
    String? teamId,
    DateTime? rangeStart,
    DateTime? rangeEnd,
    int limit = 80,
  });

  Stream<AppointmentModel?> watchAppointment({
    required String companyId,
    required String appointmentId,
  });

  Future<AppointmentModel> saveAppointment({
    required String companyId,
    required String operation,
    required AppointmentModel appointment,
  });

  Future<List<AppointmentRelatedRecordOption>> getRelatedRecordOptions({
    required String companyId,
    required AppointmentRelatedType type,
    String? assignedTo,
    String? managerId,
    String? teamId,
    int limit = 30,
  });
}

class FirebaseAppointmentsRemoteDataSource
    implements AppointmentsRemoteDataSource {
  FirebaseAppointmentsRemoteDataSource({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  @override
  Stream<List<AppointmentModel>> watchAppointments({
    required String companyId,
    String? assignedTo,
    String? managerId,
    String? teamId,
    DateTime? rangeStart,
    DateTime? rangeEnd,
    int limit = 80,
  }) {
    Query<Map<String, dynamic>> scopedQuery = _appointmentsCollection(companyId);
    scopedQuery = _applyScope(
      scopedQuery,
      assignedTo: assignedTo,
      managerId: managerId,
      teamId: teamId,
    );
    final rangedQuery = _applyScheduledRange(
      scopedQuery,
      rangeStart: rangeStart,
      rangeEnd: rangeEnd,
    );
    final fallbackQuery = scopedQuery.limit(limit);

    return (() async* {
      try {
        await for (final snapshot in rangedQuery.limit(limit).snapshots()) {
          yield _appointmentsFromSnapshot(
            companyId: companyId,
            snapshot: snapshot,
            label: 'watchAppointments.ranged',
          );
        }
      } on FirebaseException catch (error) {
        _debugAppointmentStreamError(
          label: 'watchAppointments.ranged',
          error: error,
        );
        if (error.code != 'failed-precondition') {
          throw AppointmentException(_mapFirestoreError(error));
        }
        _masarAppointmentsRemoteDebug(
          'watchAppointments fallback unordered company=$companyId '
          'assignedTo=${assignedTo ?? ''} managerId=${managerId ?? ''} '
          'teamId=${teamId ?? ''} limit=$limit rangeStart=$rangeStart '
          'rangeEnd=$rangeEnd reason=${error.code} '
          'indexLink=${_firebaseIndexLink(error) ?? ''}',
        );
        await for (final snapshot in fallbackQuery.snapshots()) {
          yield _filterAppointmentRange(
            _appointmentsFromSnapshot(
              companyId: companyId,
              snapshot: snapshot,
              label: 'watchAppointments.unorderedFallback',
            ),
            rangeStart: rangeStart,
            rangeEnd: rangeEnd,
          );
        }
      } on AppointmentException catch (error) {
        _debugAppointmentStreamError(
          label: 'watchAppointments.appointmentException',
          error: error,
        );
        throw error;
      } catch (error) {
        _debugAppointmentStreamError(
          label: 'watchAppointments.unknown',
          error: error,
        );
        throw const AppointmentException(AppErrorMessages.unknown);
      }
    })();
  }

  @override
  Stream<AppointmentModel?> watchAppointment({
    required String companyId,
    required String appointmentId,
  }) {
    return _appointmentsCollection(companyId).doc(appointmentId).snapshots().map(
      (snapshot) {
        if (!snapshot.exists) {
          return null;
        }
        try {
          final appointment = AppointmentModel.fromFirestore(snapshot);
          _ensureSameCompany(companyId: companyId, appointment: appointment);
          return appointment;
        } catch (error, stackTrace) {
          _debugAppointmentDocumentError(
            label: 'watchAppointment.map',
            companyId: companyId,
            document: snapshot,
            error: error,
            stackTrace: stackTrace,
          );
          rethrow;
        }
      },
    ).handleError((Object error) {
      _debugAppointmentStreamError(label: 'watchAppointment.stream', error: error);
      throw AppointmentException(_mapError(error));
    });
  }

  @override
  Future<AppointmentModel> saveAppointment({
    required String companyId,
    required String operation,
    required AppointmentModel appointment,
  }) async {
    try {
      final callable = _functions.httpsCallable('saveAppointmentRecord');
      final result = await callable.call(<String, Object?>{
        'companyId': companyId,
        'operation': operation,
        'appointment': appointment.toCallablePayload(),
      });
      final resultData =
          result.data as Map<Object?, Object?>? ?? const <Object?, Object?>{};
      final appointmentId = resultData['appointmentId'] as String? ?? '';
      if (appointmentId.isEmpty) {
        throw const AppointmentException(AppErrorMessages.unknown);
      }
      final snapshot =
          await _appointmentsCollection(companyId).doc(appointmentId).get();
      if (!snapshot.exists) {
        throw const AppointmentException(AppErrorMessages.notFound);
      }
      final saved = AppointmentModel.fromFirestore(snapshot);
      _ensureSameCompany(companyId: companyId, appointment: saved);
      return saved;
    } on AppointmentException {
      rethrow;
    } on FirebaseFunctionsException catch (error) {
      throw AppointmentException(_mapFunctionsError(error));
    } on FirebaseException catch (error) {
      throw AppointmentException(_mapFirestoreError(error));
    } catch (_) {
      throw const AppointmentException(AppErrorMessages.unknown);
    }
  }

  @override
  Future<List<AppointmentRelatedRecordOption>> getRelatedRecordOptions({
    required String companyId,
    required AppointmentRelatedType type,
    String? assignedTo,
    String? managerId,
    String? teamId,
    int limit = 30,
  }) async {
    try {
      return switch (type) {
        AppointmentRelatedType.lead => _getLeadOptions(
            companyId: companyId,
            assignedTo: assignedTo,
            managerId: managerId,
            teamId: teamId,
            limit: limit,
          ),
        AppointmentRelatedType.client => _getClientOptions(
            companyId: companyId,
            assignedTo: assignedTo,
            managerId: managerId,
            teamId: teamId,
            limit: limit,
          ),
        AppointmentRelatedType.property => _getPropertyOptions(
            companyId: companyId,
            assignedTo: assignedTo,
            managerId: managerId,
            teamId: teamId,
            limit: limit,
          ),
        AppointmentRelatedType.deal => _getDealOptions(
            companyId: companyId,
            assignedTo: assignedTo,
            managerId: managerId,
            teamId: teamId,
            limit: limit,
          ),
        AppointmentRelatedType.general => const [],
      };
    } on AppointmentException {
      rethrow;
    } on FirebaseException catch (error) {
      throw AppointmentException(_mapFirestoreError(error));
    } catch (_) {
      throw const AppointmentException(AppErrorMessages.unknown);
    }
  }

  Future<List<AppointmentRelatedRecordOption>> _getLeadOptions({
    required String companyId,
    String? assignedTo,
    String? managerId,
    String? teamId,
    required int limit,
  }) async {
    Query<Map<String, dynamic>> query = _firestore
        .collection(FirebasePaths.companyLeads(companyId))
        .where('isArchived', isEqualTo: false);
    query = _applyScope(
      query,
      assignedTo: assignedTo,
      managerId: managerId,
      teamId: teamId,
    );
    final snapshot = await query.limit(limit).get();
    final options = <AppointmentRelatedRecordOption>[];
    for (final document in snapshot.docs) {
      final data = document.data();
      _ensureRecordCompany(companyId, data);
      if (data['isArchived'] as bool? ?? false) {
        continue;
      }
      options.add(
        AppointmentRelatedRecordOption(
          id: document.id,
          type: AppointmentRelatedType.lead,
          title: data['fullName'] as String? ?? '',
          subtitle:
              (data['phone'] as String?) ?? (data['status'] as String?) ?? '',
        ),
      );
    }
    return _sortedOptions(options);
  }

  Future<List<AppointmentRelatedRecordOption>> _getClientOptions({
    required String companyId,
    String? assignedTo,
    String? managerId,
    String? teamId,
    required int limit,
  }) async {
    Query<Map<String, dynamic>> query = _firestore
        .collection(FirebasePaths.companyClients(companyId))
        .where('isActive', isEqualTo: true)
        .where('isArchived', isEqualTo: false);
    query = _applyScope(
      query,
      assignedTo: assignedTo,
      managerId: managerId,
      teamId: teamId,
    );
    final snapshot = await query.limit(limit).get();
    final options = <AppointmentRelatedRecordOption>[];
    for (final document in snapshot.docs) {
      final data = document.data();
      _ensureRecordCompany(companyId, data);
      options.add(
        AppointmentRelatedRecordOption(
          id: document.id,
          type: AppointmentRelatedType.client,
          title: data['fullName'] as String? ?? '',
          subtitle:
              (data['phone'] as String?) ??
              (data['preferredLocation'] as String?) ??
              '',
        ),
      );
    }
    return _sortedOptions(options);
  }

  Future<List<AppointmentRelatedRecordOption>> _getPropertyOptions({
    required String companyId,
    String? assignedTo,
    String? managerId,
    String? teamId,
    required int limit,
  }) async {
    Query<Map<String, dynamic>> query = _firestore.collection(
      FirebasePaths.companyProperties(companyId),
    );
    final snapshot = await query.limit(limit).get();
    final options = <AppointmentRelatedRecordOption>[];
    for (final document in snapshot.docs) {
      final data = document.data();
      _ensureRecordCompany(companyId, data);
      if ((data['status'] as String? ?? '') == 'inactive' ||
          (data['isArchived'] as bool? ?? false)) {
        continue;
      }
      options.add(
        AppointmentRelatedRecordOption(
          id: document.id,
          type: AppointmentRelatedType.property,
          title: data['title'] as String? ?? '',
          subtitle: data['location'] as String? ?? '',
        ),
      );
    }
    return _sortedOptions(options);
  }

  Future<List<AppointmentRelatedRecordOption>> _getDealOptions({
    required String companyId,
    String? assignedTo,
    String? managerId,
    String? teamId,
    required int limit,
  }) async {
    Query<Map<String, dynamic>> query = _firestore
        .collection(FirebasePaths.companyDeals(companyId))
        .where('isActive', isEqualTo: true)
        .where('isArchived', isEqualTo: false);
    query = _applyScope(
      query,
      assignedTo: assignedTo,
      managerId: managerId,
      teamId: teamId,
    );
    final snapshot = await query.limit(limit).get();
    final options = <AppointmentRelatedRecordOption>[];
    for (final document in snapshot.docs) {
      final data = document.data();
      _ensureRecordCompany(companyId, data);
      final clientName = data['clientName'] as String? ?? '';
      final propertyTitle = data['propertyTitle'] as String? ?? '';
      final title = clientName.trim().isEmpty
          ? propertyTitle
          : propertyTitle.trim().isEmpty
              ? clientName
              : '$clientName - $propertyTitle';
      options.add(
        AppointmentRelatedRecordOption(
          id: document.id,
          type: AppointmentRelatedType.deal,
          title: title,
          subtitle: data['stage'] as String? ?? '',
        ),
      );
    }
    return _sortedOptions(options);
  }

  Query<Map<String, dynamic>> _applyScope(
    Query<Map<String, dynamic>> query, {
    String? assignedTo,
    String? managerId,
    String? teamId,
  }) {
    if (teamId != null && teamId.trim().isNotEmpty) {
      return query.where('teamId', isEqualTo: teamId.trim());
    }
    if (managerId != null && managerId.trim().isNotEmpty) {
      return query.where('managerId', isEqualTo: managerId.trim());
    }
    if (assignedTo != null && assignedTo.trim().isNotEmpty) {
      return query.where('assignedTo', isEqualTo: assignedTo.trim());
    }
    return query;
  }

  Query<Map<String, dynamic>> _applyScheduledRange(
    Query<Map<String, dynamic>> query, {
    DateTime? rangeStart,
    DateTime? rangeEnd,
  }) {
    final hasStart = rangeStart != null;
    final hasEnd = rangeEnd != null;
    if (!hasStart && !hasEnd) {
      return query;
    }
    var ranged = query.orderBy('scheduledAt');
    if (hasStart) {
      ranged = ranged.where(
        'scheduledAt',
        isGreaterThanOrEqualTo: Timestamp.fromDate(rangeStart.toUtc()),
      );
    }
    if (hasEnd) {
      ranged = ranged.where(
        'scheduledAt',
        isLessThan: Timestamp.fromDate(rangeEnd.toUtc()),
      );
    }
    return ranged;
  }

  CollectionReference<Map<String, dynamic>> _appointmentsCollection(
    String companyId,
  ) {
    return _firestore.collection(FirebasePaths.companyAppointments(companyId));
  }
}

List<AppointmentModel> _appointmentsFromSnapshot({
  required String companyId,
  required QuerySnapshot<Map<String, dynamic>> snapshot,
  required String label,
}) {
  final appointments = <AppointmentModel>[];
  final skippedDocumentIds = <String>[];
  for (final document in snapshot.docs) {
    try {
      final appointment = AppointmentModel.fromFirestore(document);
      _ensureSameCompany(companyId: companyId, appointment: appointment);
      appointments.add(appointment);
    } on AppointmentException catch (error, stackTrace) {
      _debugAppointmentDocumentError(
        label: '$label.companyGuard',
        companyId: companyId,
        document: document,
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    } catch (error, stackTrace) {
      skippedDocumentIds.add(document.id);
      _debugAppointmentDocumentError(
        label: '$label.documentSkipped',
        companyId: companyId,
        document: document,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
  if (skippedDocumentIds.isNotEmpty) {
    _masarAppointmentsRemoteDebug(
      '$label skipped corrupt docs company=$companyId '
      'count=${skippedDocumentIds.length} ids=${skippedDocumentIds.join(',')}',
    );
  }
  appointments.sort(_compareAppointments);
  return appointments;
}

List<AppointmentModel> _filterAppointmentRange(
  List<AppointmentModel> appointments, {
  required DateTime? rangeStart,
  required DateTime? rangeEnd,
}) {
  if (rangeStart == null && rangeEnd == null) {
    return appointments;
  }
  final start = rangeStart?.toUtc();
  final end = rangeEnd?.toUtc();
  final filtered = appointments.where((appointment) {
    final scheduledAt = appointment.scheduledAt?.toUtc();
    if (scheduledAt == null) {
      return false;
    }
    if (start != null && scheduledAt.isBefore(start)) {
      return false;
    }
    if (end != null && !scheduledAt.isBefore(end)) {
      return false;
    }
    return true;
  }).toList()
    ..sort(_compareAppointments);
  return filtered;
}

void _debugAppointmentDocumentError({
  required String label,
  required String companyId,
  required DocumentSnapshot<Map<String, dynamic>> document,
  required Object error,
  required StackTrace stackTrace,
}) {
  final data = document.data() ?? const <String, dynamic>{};
  _masarAppointmentsRemoteDebug(
    '$label company=$companyId doc=${document.id} '
    'path=${document.reference.path} errorType=${error.runtimeType} '
    'error=$error fields=${_debugAppointmentFieldShapes(data)}',
  );
  _masarAppointmentsRemoteDebug('$label stack=$stackTrace');
}

void _debugAppointmentStreamError({
  required String label,
  required Object error,
}) {
  if (error is FirebaseException) {
    final indexLink = _firebaseIndexLink(error);
    _masarAppointmentsRemoteDebug(
      '$label firebase code=${error.code} indexLink=${indexLink ?? ''} '
      'message=${error.message}',
    );
    if (indexLink != null && indexLink.isNotEmpty) {
      _masarFirebaseIndexDebug('$label missingIndexLink=$indexLink');
    }
    return;
  }
  _masarAppointmentsRemoteDebug(
    '$label errorType=${error.runtimeType} error=$error',
  );
}

String? _firebaseIndexLink(FirebaseException error) {
  final message = error.message;
  if (message == null || message.isEmpty) {
    return null;
  }
  final match = RegExp(r'https://console\.firebase\.google\.com/\S+').firstMatch(message);
  if (match == null) {
    return null;
  }
  final rawLink = match.group(0);
  if (rawLink == null || rawLink.isEmpty) {
    return null;
  }
  var link = rawLink;
  while (link.endsWith('.') || link.endsWith(',') || link.endsWith(')')) {
    link = link.substring(0, link.length - 1);
  }
  return link;
}

String _debugAppointmentFieldShapes(Map<String, dynamic> data) {
  const fields = <String>[
    'id',
    'companyId',
    'title',
    'type',
    'status',
    'scheduledAt',
    'endAt',
    'durationMinutes',
    'assignedTo',
    'assignedToName',
    'assignedToEmail',
    'teamId',
    'teamName',
    'managerId',
    'managerName',
    'relatedType',
    'relatedId',
    'relatedTitle',
    'relatedSubtitle',
    'location',
    'notes',
    'outcome',
    'createdAt',
    'updatedAt',
    'createdBy',
    'updatedBy',
  ];
  return fields
      .where(data.containsKey)
      .map((field) => '$field=${_debugValueShape(data[field])}')
      .join(';');
}

String _debugValueShape(Object? value) {
  if (value == null) {
    return 'null';
  }
  if (value is String) {
    return 'String(len=${value.length},empty=${value.trim().isEmpty})';
  }
  if (value is Timestamp) {
    return 'Timestamp';
  }
  if (value is DateTime) {
    return 'DateTime';
  }
  if (value is num) {
    return value.runtimeType.toString();
  }
  if (value is bool) {
    return 'bool';
  }
  return value.runtimeType.toString();
}

void _ensureSameCompany({
  required String companyId,
  required AppointmentModel appointment,
}) {
  if (companyId.isEmpty || appointment.companyId != companyId) {
    throw const AppointmentException(AppErrorMessages.permissionDenied);
  }
}

void _ensureRecordCompany(String companyId, Map<String, dynamic> data) {
  if ((data['companyId'] as String? ?? '') != companyId) {
    throw const AppointmentException(AppErrorMessages.permissionDenied);
  }
}

List<AppointmentRelatedRecordOption> _sortedOptions(
  List<AppointmentRelatedRecordOption> options,
) {
  return options..sort((a, b) => a.title.compareTo(b.title));
}

int _compareAppointments(AppointmentModel a, AppointmentModel b) {
  final now = DateTime.now();
  final aGroup = _appointmentGroup(a, now);
  final bGroup = _appointmentGroup(b, now);
  final groupCompare = aGroup.compareTo(bGroup);
  if (groupCompare != 0) {
    return groupCompare;
  }
  final aDate = a.scheduledAt ?? DateTime(9999);
  final bDate = b.scheduledAt ?? DateTime(9999);
  return aDate.compareTo(bDate);
}

int _appointmentGroup(Appointment appointment, DateTime now) {
  if (appointment.status == AppointmentStatus.missed) {
    return 0;
  }
  if (_isOpenScheduledStatus(appointment.status) &&
      _isAppointmentPastEnd(appointment, now)) {
    return 0;
  }
  if (appointment.status == AppointmentStatus.scheduled ||
      appointment.status == AppointmentStatus.rescheduled) {
    return 1;
  }
  return 2;
}

bool _isOpenScheduledStatus(AppointmentStatus status) {
  return status == AppointmentStatus.scheduled ||
      status == AppointmentStatus.rescheduled;
}

bool _isAppointmentPastEnd(Appointment appointment, DateTime now) {
  final endAt = appointment.endAt ?? appointment.scheduledAt;
  return endAt != null && endAt.toLocal().isBefore(now);
}

String _mapError(Object error) {
  if (error is AppointmentException) {
    return error.message;
  }
  if (error is FirebaseException) {
    return _mapFirestoreError(error);
  }
  return AppErrorMessages.unknown;
}

String _mapFirestoreError(FirebaseException error) {
  return switch (error.code) {
    'unavailable' || 'network-request-failed' || 'deadline-exceeded' =>
      AppErrorMessages.unableToConnect,
    'permission-denied' => AppErrorMessages.permissionDenied,
    'unauthenticated' => AppErrorMessages.unauthenticated,
    'not-found' => AppErrorMessages.notFound,
    'cancelled' => AppErrorMessages.cancelled,
    _ => AppErrorMessages.unknown,
  };
}

String _mapFunctionsError(FirebaseFunctionsException error) {
  return switch (error.code) {
    'unavailable' || 'deadline-exceeded' => AppErrorMessages.unableToConnect,
    'permission-denied' => AppErrorMessages.permissionDenied,
    'unauthenticated' => AppErrorMessages.unauthenticated,
    'not-found' => AppErrorMessages.notFound,
    'already-exists' => AppErrorMessages.unknown,
    'failed-precondition' => error.message ?? AppErrorMessages.unknown,
    'invalid-argument' => error.message ?? AppErrorMessages.unknown,
    _ => error.message ?? AppErrorMessages.unknown,
  };
}
