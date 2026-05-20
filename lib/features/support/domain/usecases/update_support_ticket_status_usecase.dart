import '../repositories/support_repository.dart';

class UpdateSupportTicketStatusUseCase {
  const UpdateSupportTicketStatusUseCase(this._repository);

  final SupportRepository _repository;

  Future<void> call({required String ticketId, required String status}) {
    return _repository.updateTicketStatus(
      ticketId: ticketId,
      status: status,
    );
  }
}
