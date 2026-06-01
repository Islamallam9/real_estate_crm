import '../entities/appointment.dart';
import '../entities/appointment_related_record_option.dart';
import '../repositories/appointment_repository.dart';

class GetAppointmentRelatedRecordOptionsUseCase {
  const GetAppointmentRelatedRecordOptionsUseCase(this.repository);

  final AppointmentRepository repository;

  Future<List<AppointmentRelatedRecordOption>> call({
    required String companyId,
    required AppointmentRelatedType type,
    String? assignedTo,
    String? managerId,
    String? teamId,
    int limit = 30,
  }) {
    return repository.getRelatedRecordOptions(
      companyId: companyId,
      type: type,
      assignedTo: assignedTo,
      managerId: managerId,
      teamId: teamId,
      limit: limit,
    );
  }
}
