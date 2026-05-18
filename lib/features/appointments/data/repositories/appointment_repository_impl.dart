import '../../domain/entities/appointment.dart';
import '../../domain/entities/appointment_related_record_option.dart';
import '../../domain/repositories/appointment_repository.dart';
import '../datasources/appointments_remote_data_source.dart';
import '../models/appointment_model.dart';

class AppointmentRepositoryImpl implements AppointmentRepository {
  const AppointmentRepositoryImpl({required this.remoteDataSource});

  final AppointmentsRemoteDataSource remoteDataSource;

  @override
  Stream<List<Appointment>> watchAppointments({
    required String companyId,
    String? assignedTo,
    String? managerId,
    int limit = 80,
  }) {
    return remoteDataSource.watchAppointments(
      companyId: companyId,
      assignedTo: assignedTo,
      managerId: managerId,
      limit: limit,
    );
  }

  @override
  Stream<Appointment?> watchAppointment({
    required String companyId,
    required String appointmentId,
  }) {
    return remoteDataSource.watchAppointment(
      companyId: companyId,
      appointmentId: appointmentId,
    );
  }

  @override
  Future<Appointment> saveAppointment({
    required String companyId,
    required String operation,
    required Appointment appointment,
  }) {
    return remoteDataSource.saveAppointment(
      companyId: companyId,
      operation: operation,
      appointment: AppointmentModel.fromEntity(appointment),
    );
  }

  @override
  Future<List<AppointmentRelatedRecordOption>> getRelatedRecordOptions({
    required String companyId,
    required AppointmentRelatedType type,
    String? assignedTo,
    String? managerId,
    int limit = 30,
  }) {
    return remoteDataSource.getRelatedRecordOptions(
      companyId: companyId,
      type: type,
      assignedTo: assignedTo,
      managerId: managerId,
      limit: limit,
    );
  }
}
