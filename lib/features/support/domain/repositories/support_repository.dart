import '../entities/support_ticket.dart';
import '../entities/support_ticket_draft.dart';

abstract interface class SupportRepository {
  Future<void> createTicket(SupportTicketDraft draft);

  Stream<List<SupportTicket>> watchMyTickets({required String userId});

  Stream<List<SupportTicket>> watchPlatformTickets();

  Future<void> updateTicketStatus({
    required String ticketId,
    required String status,
  });
}
