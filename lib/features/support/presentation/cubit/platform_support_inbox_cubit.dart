import 'dart:async';

import 'package:bloc/bloc.dart';

import '../../domain/usecases/update_support_ticket_status_usecase.dart';
import '../../domain/usecases/watch_platform_support_tickets_usecase.dart';
import 'platform_support_inbox_state.dart';

class PlatformSupportInboxCubit extends Cubit<PlatformSupportInboxState> {
  PlatformSupportInboxCubit({
    required WatchPlatformSupportTicketsUseCase watchPlatformTicketsUseCase,
    required UpdateSupportTicketStatusUseCase updateTicketStatusUseCase,
  })  : _watchPlatformTicketsUseCase = watchPlatformTicketsUseCase,
        _updateTicketStatusUseCase = updateTicketStatusUseCase,
        super(const PlatformSupportInboxState());

  final WatchPlatformSupportTicketsUseCase _watchPlatformTicketsUseCase;
  final UpdateSupportTicketStatusUseCase _updateTicketStatusUseCase;

  StreamSubscription? _ticketsSubscription;

  void watchTickets() {
    emit(
      state.copyWith(
        status: PlatformSupportInboxStatus.loading,
        clearMessage: true,
      ),
    );
    _ticketsSubscription?.cancel();
    _ticketsSubscription = _watchPlatformTicketsUseCase().listen(
      (tickets) {
        emit(
          state.copyWith(
            status: PlatformSupportInboxStatus.ready,
            tickets: tickets,
            clearMessage: true,
          ),
        );
      },
      onError: (Object error) {
        emit(
          state.copyWith(
            status: PlatformSupportInboxStatus.failure,
            message: error.toString(),
          ),
        );
      },
    );
  }

  Future<bool> updateStatus({
    required String ticketId,
    required String status,
  }) async {
    emit(
      state.copyWith(
        status: PlatformSupportInboxStatus.saving,
        activeTicketId: ticketId,
        clearMessage: true,
      ),
    );
    try {
      await _updateTicketStatusUseCase(ticketId: ticketId, status: status);
      emit(
        state.copyWith(
          status: PlatformSupportInboxStatus.ready,
          clearActiveTicket: true,
          clearMessage: true,
        ),
      );
      return true;
    } catch (error) {
      emit(
        state.copyWith(
          status: PlatformSupportInboxStatus.failure,
          message: error.toString(),
          clearActiveTicket: true,
        ),
      );
      return false;
    }
  }

  @override
  Future<void> close() {
    _ticketsSubscription?.cancel();
    return super.close();
  }
}
