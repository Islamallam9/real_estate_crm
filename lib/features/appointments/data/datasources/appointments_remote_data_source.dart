import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../../../../core/constants/firebase_paths.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../domain/entities/appointment.dart';
import '../../domain/entities/appointment_related_record_option.dart';
import '../../domain/errors/appointment_exception.dart';
import '../models/appointment_model.dart';

abstract interface class AppointmentsRemoteDataSource {
  Stream<List<AppointmentModel>> watchAppointments({
    required String companyId,
    String? assignedTo,
    String? managerId,
    int limit,
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
    int limit,
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
    int limit = 80,
  }) {
    Query<Map<String, dynamic>> query = _appointmentsCollection(companyId);
    if (managerId != null && managerId.trim().isNotEmpty) {
      query = query.where('managerId', isEqualTo: managerId.trim());
    } else if (assignedTo != null && assignedTo.trim().isNotEmpty) {
      query = query.where('assignedTo', isEqualTo: assignedTo.trim());
    }

    return query.limit(limit).snapshots().map((snapshot) {
      final appointments = snapshot.docs.map((document) {
        final appointment = AppointmentModel.fromFirestore(document);
        _ensureSameCompany(companyId: companyId, appointment: appointment);
        return appointment;
      }).toList()
        ..sort(_compareAppointments);
      return appointments;
    }).handleError((Object error) {
      throw AppointmentException(_mapError(error));
    });
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
        final appointment = AppointmentModel.fromFirestore(snapshot);
        _ensureSameCompany(companyId: companyId, appointment: appointment);
        return appointment;
      },
    ).handleError((Object error) {
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
    int limit = 30,
  }) async {
    try {
      return switch (type) {
        AppointmentRelatedType.lead => _getLeadOptions(
            companyId: companyId,
            assignedTo: assignedTo,
            managerId: managerId,
            limit: limit,
          ),
        AppointmentRelatedType.client => _getClientOptions(
            companyId: companyId,
            assignedTo: assignedTo,
            managerId: managerId,
            limit: limit,
          ),
        AppointmentRelatedType.property => _getPropertyOptions(
            companyId: companyId,
            assignedTo: assignedTo,
            managerId: managerId,
            limit: limit,
          ),
        AppointmentRelatedType.deal => _getDealOptions(
            companyId: companyId,
            assignedTo: assignedTo,
            managerId: managerId,
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
    required int limit,
  }) async {
    Query<Map<String, dynamic>> query = _firestore.collection(
      FirebasePaths.companyLeads(companyId),
    );
    query = _applyScope(query, assignedTo: assignedTo, managerId: managerId);
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
    required int limit,
  }) async {
    Query<Map<String, dynamic>> query = _firestore
        .collection(FirebasePaths.companyClients(companyId))
        .where('isActive', isEqualTo: true);
    query = _applyScope(query, assignedTo: assignedTo, managerId: managerId);
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
    required int limit,
  }) async {
    Query<Map<String, dynamic>> query = _firestore.collection(
      FirebasePaths.companyProperties(companyId),
    );
    query = _applyScope(query, assignedTo: assignedTo, managerId: managerId);
    final snapshot = await query.limit(limit).get();
    final options = <AppointmentRelatedRecordOption>[];
    for (final document in snapshot.docs) {
      final data = document.data();
      _ensureRecordCompany(companyId, data);
      if ((data['status'] as String? ?? '') == 'inactive') {
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
    required int limit,
  }) async {
    Query<Map<String, dynamic>> query = _firestore
        .collection(FirebasePaths.companyDeals(companyId))
        .where('isActive', isEqualTo: true);
    query = _applyScope(query, assignedTo: assignedTo, managerId: managerId);
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
  }) {
    if (managerId != null && managerId.trim().isNotEmpty) {
      return query.where('managerId', isEqualTo: managerId.trim());
    }
    if (assignedTo != null && assignedTo.trim().isNotEmpty) {
      return query.where('assignedTo', isEqualTo: assignedTo.trim());
    }
    return query;
  }

  CollectionReference<Map<String, dynamic>> _appointmentsCollection(
    String companyId,
  ) {
    return _firestore.collection(FirebasePaths.companyAppointments(companyId));
  }
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
      _isAppointmentPastStart(appointment, now)) {
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

bool _isAppointmentPastStart(Appointment appointment, DateTime now) {
  final scheduledAt = appointment.scheduledAt;
  return scheduledAt != null &&
      now.difference(scheduledAt.toLocal()).inSeconds >= 60;
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
