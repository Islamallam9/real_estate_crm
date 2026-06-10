import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/errors/notification_exception.dart';
import '../../domain/repositories/notification_push_token_repository.dart';
import 'notification_push_token_state.dart';

class NotificationPushTokenCubit extends Cubit<NotificationPushTokenState> {
  NotificationPushTokenCubit({
    required NotificationPushTokenRepository repository,
  })  : _repository = repository,
        super(const NotificationPushTokenState());

  final NotificationPushTokenRepository _repository;
  StreamSubscription<String>? _refreshSubscription;

  static const _tokenReadTimeout = Duration(seconds: 20);
  static const _tokenRegisterTimeout = Duration(seconds: 25);

  Future<void> syncCompany({
    required String companyId,
    required String uid,
    required String role,
    required String locale,
  }) async {
    _debugStatus('company-session-ready', companyId: companyId, uid: uid, role: role);
    await _sync(
      scope: NotificationPushTokenScopeKind.company,
      companyId: companyId,
      uid: uid,
      role: role,
      locale: locale,
      requestPermission: false,
      register: (token) => _repository.registerCompanyToken(
        companyId: companyId,
        token: token,
        locale: locale,
        role: role,
      ),
    );
  }

  Future<void> syncPlatformOwner({
    required String uid,
    required String locale,
  }) async {
    _debugStatus('platform-session-ready', uid: uid);
    await _sync(
      scope: NotificationPushTokenScopeKind.platformOwner,
      companyId: '',
      uid: uid,
      role: 'platformOwner',
      locale: locale,
      requestPermission: false,
      register: (token) => _repository.registerPlatformToken(
        token: token,
        locale: locale,
      ),
    );
  }

  Future<void> requestPermissionAndSync() async {
    var current = state;
    if (!current.hasSession) {
      _debugStatus('manual-sync-not-ready');
      return;
    }
    await clearPromptSnooze();
    current = state;
    if (current.scope == NotificationPushTokenScopeKind.company) {
      await _sync(
        scope: current.scope,
        companyId: current.companyId,
        uid: current.uid,
        role: current.role,
        locale: current.locale,
        requestPermission: true,
        force: true,
        register: (token) => _repository.registerCompanyToken(
          companyId: current.companyId,
          token: token,
          locale: current.locale,
          role: current.role,
        ),
      );
      return;
    }
    if (current.scope == NotificationPushTokenScopeKind.platformOwner) {
      await _sync(
        scope: current.scope,
        companyId: '',
        uid: current.uid,
        role: 'platformOwner',
        locale: current.locale,
        requestPermission: true,
        force: true,
        register: (token) => _repository.registerPlatformToken(
          token: token,
          locale: current.locale,
        ),
      );
    }
  }

  Future<void> snoozePrompt(Duration duration) async {
    final current = state;
    if (!current.hasSession) {
      return;
    }
    final until = DateTime.now().add(duration);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_promptDismissedKey(current), until.toIso8601String());
    emit(current.copyWith(promptDismissedUntil: until));
    _debugStatus('prompt-snoozed');
  }

  Future<void> clearPromptSnooze() async {
    final current = state;
    if (!current.hasSession) {
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_promptDismissedKey(current));
    emit(current.copyWith(clearPromptDismissedUntil: true));
  }

  Future<void> clear() async {
    await _refreshSubscription?.cancel();
    _refreshSubscription = null;
    final token = state.token.trim();
    final previous = state;
    emit(const NotificationPushTokenState());
    if (token.isEmpty) return;
    try {
      if (previous.scope == NotificationPushTokenScopeKind.company &&
          previous.companyId.trim().isNotEmpty) {
        await _repository.deactivateCompanyToken(
          companyId: previous.companyId,
          token: token,
        );
      } else if (previous.scope == NotificationPushTokenScopeKind.platformOwner) {
        await _repository.deactivatePlatformToken(token: token);
      }
    } catch (_) {
      _debugStatus('token-clear-failed');
    }
  }

  Future<void> _sync({
    required NotificationPushTokenScopeKind scope,
    required String companyId,
    required String uid,
    required String role,
    required String locale,
    required bool requestPermission,
    bool force = false,
    required Future<void> Function(String token) register,
  }) async {
    if (!requestPermission &&
        state.isRegistered &&
        state.scope == scope &&
        state.companyId == companyId &&
        state.uid == uid &&
        state.role == role &&
        state.locale == locale) {
      _debugStatus('token-sync-already-registered', companyId: companyId, uid: uid, role: role);
      return;
    }

    if (uid.trim().isEmpty) {
      _debugStatus('session-not-ready');
      emit(state.copyWith(status: NotificationPushTokenStatus.idle));
      return;
    }
    if (state.isSyncing) {
      _debugStatus('sync-already-running');
      return;
    }

    final scopedState = state.copyWith(
      scope: scope,
      companyId: companyId,
      uid: uid,
      role: role,
      locale: locale,
    );
    final prefs = await SharedPreferences.getInstance();
    final dismissedUntil = _readDismissedUntil(
      prefs.getString(_promptDismissedKey(scopedState)),
    );
    final localRegistrationHint =
        prefs.getBool(_registrationHintKey(scopedState)) ?? false;
    final baseState = scopedState.copyWith(
      isSyncing: true,
      status: NotificationPushTokenStatus.syncing,
      lastError: '',
      promptDismissedUntil: dismissedUntil,
      localRegistrationHint: localRegistrationHint,
    );

    // A previous successful token save is only a hint. On Web especially, the
    // browser permission can later be blocked from site settings while the old
    // token document still exists. Revalidate silently so the UI never says
    // "enabled" when the browser is actually blocking notifications.
    if (!requestPermission && localRegistrationHint) {
      try {
        final token = await _repository
            .currentToken(requestPermission: false)
            .timeout(_tokenReadTimeout);
        if (token == null || token.trim().isEmpty) {
          await prefs.setBool(_registrationHintKey(scopedState), false);
          emit(scopedState.copyWith(
            isSyncing: false,
            status: NotificationPushTokenStatus.permissionRequired,
            lastError: '',
            promptDismissedUntil: dismissedUntil,
            localRegistrationHint: false,
          ));
          _debugStatus('token-sync-local-hint-invalid', companyId: companyId, uid: uid, role: role);
          return;
        }
        await register(token).timeout(_tokenRegisterTimeout);
        final activeToken = await _activeTokenAfterRegistration(token);
        final registeredState = scopedState.copyWith(
          isSyncing: false,
          status: NotificationPushTokenStatus.registered,
          token: activeToken,
          lastError: '',
          promptDismissedUntil: dismissedUntil,
          localRegistrationHint: true,
        );
        emit(registeredState);
        try {
          await prefs.setBool(_registrationHintKey(scopedState), true);
          await _startRefreshListener(register, registeredState);
        } catch (error) {
          _debugStatus(
            'token-sync-post-register-state-persist-failed-${error.runtimeType}',
            companyId: companyId,
            uid: uid,
            role: role,
          );
        }
        _debugStatus('token-sync-local-hint-revalidated', companyId: companyId, uid: uid, role: role);
        return;
      } on NotificationException catch (error) {
        await prefs.setBool(_registrationHintKey(scopedState), false);
        final denied = error.message == 'notification-permission-denied';
        emit(scopedState.copyWith(
          isSyncing: false,
          status: denied
              ? NotificationPushTokenStatus.denied
              : NotificationPushTokenStatus.failed,
          lastError: error.message,
          promptDismissedUntil: dismissedUntil,
          localRegistrationHint: false,
        ));
        _debugStatus(denied ? 'token-sync-browser-permission-blocked' : 'token-sync-local-hint-failed', companyId: companyId, uid: uid, role: role);
        return;
      } catch (error) {
        await prefs.setBool(_registrationHintKey(scopedState), false);
        emit(scopedState.copyWith(
          isSyncing: false,
          status: NotificationPushTokenStatus.failed,
          lastError: error.toString(),
          promptDismissedUntil: dismissedUntil,
          localRegistrationHint: false,
        ));
        _debugStatus('token-sync-local-hint-failed-${error.runtimeType}', companyId: companyId, uid: uid, role: role);
        return;
      }
    }

    emit(baseState);

    try {
      final token = await _repository
          .currentToken(requestPermission: requestPermission)
          .timeout(_tokenReadTimeout);
      if (token == null || token.trim().isEmpty) {
        _debugStatus(requestPermission ? 'permission-or-token-not-available' : 'permission-required');
        emit(baseState.copyWith(
          isSyncing: false,
          status: requestPermission
              ? NotificationPushTokenStatus.unavailable
              : NotificationPushTokenStatus.permissionRequired,
        ));
        return;
      }

      await register(token).timeout(_tokenRegisterTimeout);
      final activeToken = await _activeTokenAfterRegistration(token);
      final registeredState = baseState.copyWith(
        isSyncing: false,
        status: NotificationPushTokenStatus.registered,
        token: activeToken,
        clearPromptDismissedUntil: true,
        localRegistrationHint: true,
      );
      _debugStatus('token-save-success');
      emit(registeredState);
      try {
        await prefs.setBool(_registrationHintKey(baseState), true);
        await prefs.remove(_promptDismissedKey(baseState));
        await _startRefreshListener(register, registeredState);
      } catch (error) {
        _debugStatus(
          'token-sync-post-register-state-persist-failed-${error.runtimeType}',
          companyId: companyId,
          uid: uid,
          role: role,
        );
      }
    } on NotificationException catch (error) {
      final denied = error.message == 'notification-permission-denied';
      if (denied) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_registrationHintKey(baseState), false);
      }
      _debugStatus(denied ? 'token-sync-permission-denied' : 'token-sync-failed-${error.message}');
      emit(baseState.copyWith(
        isSyncing: false,
        status: denied
            ? NotificationPushTokenStatus.denied
            : NotificationPushTokenStatus.failed,
        lastError: error.message,
        localRegistrationHint: denied ? false : baseState.localRegistrationHint,
      ));
    } catch (error) {
      _debugStatus('token-sync-failed-${error.runtimeType}');
      emit(baseState.copyWith(
        isSyncing: false,
        status: NotificationPushTokenStatus.failed,
        lastError: error.toString(),
      ));
    }
  }


  Future<String> _activeTokenAfterRegistration(String fallbackToken) async {
    try {
      final latestToken = await _repository
          .currentToken(requestPermission: false)
          .timeout(_tokenReadTimeout);
      if (latestToken != null && latestToken.trim().isNotEmpty) {
        return latestToken;
      }
    } catch (_) {
      // Keep the already-registered token if reading the current token fails.
    }
    return fallbackToken;
  }

  Future<void> _startRefreshListener(
    Future<void> Function(String token) register,
    NotificationPushTokenState baseState,
  ) async {
    await _refreshSubscription?.cancel();
    _refreshSubscription =
        _repository.watchTokenRefreshes().listen((newToken) async {
      if (newToken.trim().isEmpty) return;
      try {
        await register(newToken).timeout(_tokenRegisterTimeout);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_registrationHintKey(baseState), true);
        _debugStatus('refreshed-token-save-success');
        emit(baseState.copyWith(
          isSyncing: false,
          status: NotificationPushTokenStatus.registered,
          token: newToken,
          clearPromptDismissedUntil: true,
          localRegistrationHint: true,
        ));
      } catch (error) {
        _debugStatus('refreshed-token-save-failed-${error.runtimeType}');
      }
    });
  }

  void _debugStatus(
    String status, {
    String companyId = '',
    String uid = '',
    String role = '',
  }) {
    return;
  }

  String _promptDismissedKey(NotificationPushTokenState state) {
    return 'masar_fcm_prompt_dismissed_until_v2:${state.scope.name}:${state.companyId}:${state.uid}:${_platformIdentity()}';
  }

  String _registrationHintKey(NotificationPushTokenState state) {
    return 'masar_fcm_registered_hint_v2:${state.scope.name}:${state.companyId}:${state.uid}:${_platformIdentity()}';
  }

  DateTime? _readDismissedUntil(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    return DateTime.tryParse(value.trim());
  }


  String _platformIdentity() {
    if (!kIsWeb) {
      return _platformName();
    }
    try {
      final origin = Uri.base.origin.trim();
      if (origin.isNotEmpty) {
        return 'web:$origin';
      }
    } catch (_) {}
    return 'web';
  }

  String _platformName() {
    if (kIsWeb) {
      return 'web';
    }
    return defaultTargetPlatform.name;
  }

  @override
  Future<void> close() async {
    await _refreshSubscription?.cancel();
    return super.close();
  }
}
