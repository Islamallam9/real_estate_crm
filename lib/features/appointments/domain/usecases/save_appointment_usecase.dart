import '../entities/appointment.dart';
import '../repositories/appointment_repository.dart';

class SaveAppointmentUseCase {
  const SaveAppointmentUseCase(this.repository);

  final AppointmentRepository repository;

  Future<Appointment> call({
    required String companyId,
    required String operation,
    required Appointment appointment,
  }) {
    return repository.saveAppointment(
      companyId: companyId,
      operation: operation,
      appointment: appointment,
    );
  }
}
