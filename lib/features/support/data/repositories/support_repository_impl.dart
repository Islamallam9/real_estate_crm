import '../../domain/entities/support_ticket.dart';
import '../../domain/entities/support_ticket_draft.dart';
import '../../domain/repositories/support_repository.dart';
import '../datasources/support_remote_data_source.dart';

class SupportRepositoryImpl implements SupportRepository {
  const SupportRepositoryImpl({required SupportRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  final SupportRemoteDataSource _remoteDataSource;

  @override
  Future<void> createTicket(SupportTicketDraft draft) {
    return _remoteDataSource.createTicket(draft);
  }

  @override
  Stream<List<SupportTicket>> watchMyTickets({required String userId}) {
    return _remoteDataSource.watchMyTickets(userId: userId);
  }

  @override
  Stream<List<SupportTicket>> watchPlatformTickets() {
    return _remoteDataSource.watchPlatformTickets();
  }

  @override
  Future<void> updateTicketStatus({
    required String ticketId,
    required String status,
  }) {
    return _remoteDataSource.updateTicketStatus(
      ticketId: ticketId,
      status: status,
    );
  }
}
