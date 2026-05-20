import '../entities/support_ticket.dart';
import '../repositories/support_repository.dart';

class WatchMySupportTicketsUseCase {
  const WatchMySupportTicketsUseCase(this._repository);

  final SupportRepository _repository;

  Stream<List<SupportTicket>> call({required String userId}) {
    return _repository.watchMyTickets(userId: userId);
  }
}
