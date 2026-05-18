import '../entities/appointment.dart';
import '../repositories/appointment_repository.dart';

class WatchAppointmentUseCase {
  const WatchAppointmentUseCase(this.repository);

  final AppointmentRepository repository;

  Stream<Appointment?> call({
    required String companyId,
    required String appointmentId,
  }) {
    return repository.watchAppointment(
      companyId: companyId,
      appointmentId: appointmentId,
    );
  }
}
