import '../entities/support_ticket.dart';
import '../repositories/support_repository.dart';

class WatchPlatformSupportTicketsUseCase {
  const WatchPlatformSupportTicketsUseCase(this._repository);

  final SupportRepository _repository;

  Stream<List<SupportTicket>> call() {
    return _repository.watchPlatformTickets();
  }
}
