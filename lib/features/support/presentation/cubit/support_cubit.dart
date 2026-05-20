import 'dart:async';

import 'package:bloc/bloc.dart';

import '../../domain/entities/support_ticket_draft.dart';
import '../../domain/usecases/create_feedback_usecase.dart';
import '../../domain/usecases/create_support_ticket_usecase.dart';
import '../../domain/usecases/watch_my_support_tickets_usecase.dart';
import 'support_state.dart';

class SupportCubit extends Cubit<SupportState> {
  SupportCubit({
    required CreateSupportTicketUseCase createSupportTicketUseCase,
    required CreateFeedbackUseCase createFeedbackUseCase,
    required WatchMySupportTicketsUseCase watchMySupportTicketsUseCase,
  })  : _createSupportTicketUseCase = createSupportTicketUseCase,
        _createFeedbackUseCase = createFeedbackUseCase,
        _watchMySupportTicketsUseCase = watchMySupportTicketsUseCase,
        super(const SupportState());

  final CreateSupportTicketUseCase _createSupportTicketUseCase;
  final CreateFeedbackUseCase _createFeedbackUseCase;
  final WatchMySupportTicketsUseCase _watchMySupportTicketsUseCase;

  StreamSubscription? _ticketsSubscription;

  void watchMyTickets(String userId) {
    emit(state.copyWith(status: SupportStatus.loading, clearMessage: true));
    _ticketsSubscription?.cancel();
    _ticketsSubscription = _watchMySupportTicketsUseCase(userId: userId).listen(
      (tickets) {
        emit(
          state.copyWith(
            status: SupportStatus.ready,
            tickets: tickets,
            clearMessage: true,
          ),
        );
      },
      onError: (Object error) {
        emit(
          state.copyWith(
            status: SupportStatus.failure,
            message: error.toString(),
          ),
        );
      },
    );
  }

  Future<bool> createSupportTicket(SupportTicketDraft draft) {
    return _save(
      savingStatus: SupportStatus.savingSupport,
      action: () => _createSupportTicketUseCase(draft),
    );
  }

  Future<bool> createFeedback(SupportTicketDraft draft) {
    return _save(
      savingStatus: SupportStatus.savingFeedback,
      action: () => _createFeedbackUseCase(draft),
    );
  }

  Future<bool> _save({
    required SupportStatus savingStatus,
    required Future<void> Function() action,
  }) async {
    emit(state.copyWith(status: savingStatus, clearMessage: true));
    try {
      await action();
      emit(state.copyWith(status: SupportStatus.ready, clearMessage: true));
      return true;
    } catch (error) {
      emit(
        state.copyWith(
          status: SupportStatus.failure,
          message: error.toString(),
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
