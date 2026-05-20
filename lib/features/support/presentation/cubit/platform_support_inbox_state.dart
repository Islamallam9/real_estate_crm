import 'package:equatable/equatable.dart';

import '../../domain/entities/support_ticket.dart';

enum PlatformSupportInboxStatus { initial, loading, ready, saving, failure }

class PlatformSupportInboxState extends Equatable {
  const PlatformSupportInboxState({
    this.status = PlatformSupportInboxStatus.initial,
    this.tickets = const [],
    this.activeTicketId,
    this.message,
  });

  final PlatformSupportInboxStatus status;
  final List<SupportTicket> tickets;
  final String? activeTicketId;
  final String? message;

  PlatformSupportInboxState copyWith({
    PlatformSupportInboxStatus? status,
    List<SupportTicket>? tickets,
    String? activeTicketId,
    String? message,
    bool clearActiveTicket = false,
    bool clearMessage = false,
  }) {
    return PlatformSupportInboxState(
      status: status ?? this.status,
      tickets: tickets ?? this.tickets,
      activeTicketId:
          clearActiveTicket ? null : activeTicketId ?? this.activeTicketId,
      message: clearMessage ? null : message ?? this.message,
    );
  }

  @override
  List<Object?> get props => [status, tickets, activeTicketId, message];
}
