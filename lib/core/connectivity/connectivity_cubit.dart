import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:equatable/equatable.dart';

enum MasarConnectivityStatus { unknown, online, offline }

class MasarConnectivityState extends Equatable {
  const MasarConnectivityState({
    required this.status,
    this.hasChecked = false,
  });

  const MasarConnectivityState.initial()
      : status = MasarConnectivityStatus.unknown,
        hasChecked = false;

  final MasarConnectivityStatus status;
  final bool hasChecked;

  @override
  List<Object?> get props => [status, hasChecked];
}

class MasarConnectivityCubit extends Cubit<MasarConnectivityState> {
  MasarConnectivityCubit({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity(),
        super(const MasarConnectivityState.initial());

  final Connectivity _connectivity;
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _started = false;

  Future<void> start() async {
    if (_started) {
      return;
    }
    _started = true;
    try {
      _applyResults(await _connectivity.checkConnectivity());
      _subscription = _connectivity.onConnectivityChanged.listen(
        _applyResults,
        onError: (_) {
          emit(
            const MasarConnectivityState(
              status: MasarConnectivityStatus.unknown,
              hasChecked: true,
            ),
          );
        },
      );
    } catch (_) {
      emit(
        const MasarConnectivityState(
          status: MasarConnectivityStatus.unknown,
          hasChecked: true,
        ),
      );
    }
  }

  void _applyResults(List<ConnectivityResult> results) {
    final isOnline = results.any((result) => result != ConnectivityResult.none);
    final nextStatus = isOnline
        ? MasarConnectivityStatus.online
        : MasarConnectivityStatus.offline;
    if (state.status == nextStatus && state.hasChecked) {
      return;
    }
    emit(MasarConnectivityState(status: nextStatus, hasChecked: true));
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
