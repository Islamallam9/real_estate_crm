import 'package:equatable/equatable.dart';

import '../../domain/entities/support_ticket.dart';

enum SupportStatus { initial, loading, ready, savingSupport, savingFeedback, failure }

class SupportState extends Equatable {
  const SupportState({
    this.status = SupportStatus.initial,
    this.tickets = const [],
    this.message,
  });

  final SupportStatus status;
  final List<SupportTicket> tickets;
  final String? message;

  bool get isSavingSupport => status == SupportStatus.savingSupport;
  bool get isSavingFeedback => status == SupportStatus.savingFeedback;

  SupportState copyWith({
    SupportStatus? status,
    List<SupportTicket>? tickets,
    String? message,
    bool clearMessage = false,
  }) {
    return SupportState(
      status: status ?? this.status,
      tickets: tickets ?? this.tickets,
      message: clearMessage ? null : message ?? this.message,
    );
  }

  @override
  List<Object?> get props => [status, tickets, message];
}
