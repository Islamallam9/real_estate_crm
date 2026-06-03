import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';

import '../../domain/repositories/device_lifecycle_repository.dart';

class DeviceLifecycleCubit extends Cubit<int> {
  DeviceLifecycleCubit({required DeviceLifecycleRepository repository})
      : _repository = repository,
        super(0);

  final DeviceLifecycleRepository _repository;
  DateTime? _lastRegisterAt;
  DateTime? _lastHeartbeatAt;
  String _lastSessionKey = '';
  bool _busy = false;

  static const _registerThrottle = Duration(minutes: 10);
  static const _heartbeatThrottle = Duration(minutes: 20);

  Future<void> registerCompanySession({
    required String companyId,
    required String uid,
    required String role,
    required String locale,
    required String source,
  }) async {
    final key = '$companyId:$uid:$role:$locale';
    final now = DateTime.now();
    final shouldRegister = _lastSessionKey != key ||
        _lastRegisterAt == null ||
        now.difference(_lastRegisterAt!) >= _registerThrottle;
    if (!shouldRegister || _busy) {
      return;
    }
    _busy = true;
    try {
      await _repository.registerCompanyInstall(
        companyId: companyId,
        uid: uid,
        role: role,
        locale: locale,
        source: source,
      );
      _lastSessionKey = key;
      _lastRegisterAt = now;
      _lastHeartbeatAt = now;
    } catch (error) {
      if (kDebugMode) {
        debugPrint('MasarDeviceLifecycle: register failed ${error.runtimeType}');
      }
    } finally {
      _busy = false;
    }
  }

  Future<void> heartbeat({
    required String companyId,
    required String uid,
    required String role,
    required String locale,
  }) async {
    final now = DateTime.now();
    if (_busy ||
        (_lastHeartbeatAt != null &&
            now.difference(_lastHeartbeatAt!) < _heartbeatThrottle)) {
      return;
    }
    _busy = true;
    try {
      await _repository.recordHeartbeat(
        companyId: companyId,
        uid: uid,
        role: role,
        locale: locale,
      );
      _lastHeartbeatAt = now;
    } catch (error) {
      if (kDebugMode) {
        debugPrint('MasarDeviceLifecycle: heartbeat failed ${error.runtimeType}');
      }
    } finally {
      _busy = false;
    }
  }

  void clear() {
    _lastSessionKey = '';
    _lastRegisterAt = null;
    _lastHeartbeatAt = null;
  }
}
