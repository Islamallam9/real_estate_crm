import '../entities/support_ticket_draft.dart';
import '../repositories/support_repository.dart';

class CreateFeedbackUseCase {
  const CreateFeedbackUseCase(this._repository);

  final SupportRepository _repository;

  Future<void> call(SupportTicketDraft draft) {
    return _repository.createTicket(draft);
  }
}
