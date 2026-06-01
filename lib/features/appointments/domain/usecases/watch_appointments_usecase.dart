import '../entities/appointment.dart';
import '../repositories/appointment_repository.dart';

class WatchAppointmentsUseCase {
  const WatchAppointmentsUseCase(this.repository);

  final AppointmentRepository repository;

  Stream<List<Appointment>> call({
    required String companyId,
    String? assignedTo,
    String? managerId,
    String? teamId,
    DateTime? rangeStart,
    DateTime? rangeEnd,
    int limit = 80,
  }) {
    return repository.watchAppointments(
      companyId: companyId,
      assignedTo: assignedTo,
      managerId: managerId,
      teamId: teamId,
      rangeStart: rangeStart,
      rangeEnd: rangeEnd,
      limit: limit,
    );
  }
}
