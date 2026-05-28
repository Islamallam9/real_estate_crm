import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/connected_journey.dart';
import '../../domain/usecases/watch_connected_journey_usecase.dart';
import 'connected_journey_state.dart';

class ConnectedJourneyCubit extends Cubit<ConnectedJourneyState> {
  ConnectedJourneyCubit({required this.watchConnectedJourneyUseCase})
      : super(const ConnectedJourneyState());

  final WatchConnectedJourneyUseCase watchConnectedJourneyUseCase;
  final List<StreamSubscription<List<JourneyItem>>> _subscriptions = [];
  String? _watchKey;

  void watch({
    required JourneyRecordType recordType,
    required String recordId,
    required JourneyQueryScope scope,
  }) {
    final key = '${scope.companyId}:${scope.currentUserId}:${scope.role.name}:${scope.teamId}:${scope.managerId}:${recordType.name}:$recordId';
    if (_watchKey == key) {
      return;
    }
    _watchKey = key;
    _cancelSubscriptions();
    emit(const ConnectedJourneyState(status: ConnectedJourneyStatus.loading));

    _listen(
      watchConnectedJourneyUseCase.tasks(
        recordType: recordType,
        recordId: recordId,
        scope: scope,
      ),
      (items) => emit(state.copyWith(
        status: ConnectedJourneyStatus.loaded,
        taskItems: items,
        message: '',
      )),
    );
    _listen(
      watchConnectedJourneyUseCase.appointments(
        recordType: recordType,
        recordId: recordId,
        scope: scope,
      ),
      (items) => emit(state.copyWith(
        status: ConnectedJourneyStatus.loaded,
        appointmentItems: items,
        message: '',
      )),
    );
    _listen(
      watchConnectedJourneyUseCase.deals(
        recordType: recordType,
        recordId: recordId,
        scope: scope,
      ),
      (items) => emit(state.copyWith(
        status: ConnectedJourneyStatus.loaded,
        dealItems: items,
        message: '',
      )),
    );
    _listen(
      watchConnectedJourneyUseCase.audit(
        recordType: recordType,
        recordId: recordId,
        scope: scope,
      ),
      (items) => emit(state.copyWith(
        status: ConnectedJourneyStatus.loaded,
        auditItems: items,
        message: '',
      )),
    );
  }

  void _listen(
    Stream<List<JourneyItem>> stream,
    void Function(List<JourneyItem> items) onData,
  ) {
    _subscriptions.add(
      stream.listen(
        onData,
        onError: (Object error) {
          if (!isClosed) {
            emit(state.copyWith(
              status: state.remoteItems.isEmpty
                  ? ConnectedJourneyStatus.failure
                  : ConnectedJourneyStatus.loaded,
              message: error.toString(),
            ));
          }
        },
      ),
    );
  }

  @override
  Future<void> close() {
    _cancelSubscriptions();
    return super.close();
  }

  void _cancelSubscriptions() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();
  }
}
