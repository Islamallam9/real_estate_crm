import '../entities/appointment.dart';
import '../entities/appointment_related_record_option.dart';

abstract interface class AppointmentRepository {
  Stream<List<Appointment>> watchAppointments({
    required String companyId,
    String? assignedTo,
    String? managerId,
    String? teamId,
    DateTime? rangeStart,
    DateTime? rangeEnd,
    int limit = 80,
  });

  Stream<Appointment?> watchAppointment({
    required String companyId,
    required String appointmentId,
  });

  Future<Appointment> saveAppointment({
    required String companyId,
    required String operation,
    required Appointment appointment,
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
