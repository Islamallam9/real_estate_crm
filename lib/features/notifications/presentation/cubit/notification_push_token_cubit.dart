import 'dart:async';

import 'package:bloc/bloc.dart';

import '../../domain/repositories/notification_push_token_repository.dart';
import 'notification_push_token_state.dart';

class NotificationPushTokenCubit extends Cubit<NotificationPushTokenState> {
  NotificationPushTokenCubit({required NotificationPushTokenRepository repository})
      : _repository = repository,
        super(const NotificationPushTokenState());

  final NotificationPushTokenRepository _repository;
  StreamSubscription<String>? _refreshSubscription;

  Future<void> syncCompany({
    required String companyId,
    required String uid,
    required String role,
    required String locale,
  }) async {
    await _sync(
      scope: NotificationPushTokenScopeKind.company,
      companyId: companyId,
      uid: uid,
      locale: locale,
      register: (token) => _repository.registerCompanyToken(
        companyId: companyId,
        token: token,
        locale: locale,
        role: role,
      ),
    );
  }

  Future<void> syncPlatformOwner({required String uid, required String locale}) async {
    await _sync(
      scope: NotificationPushTokenScopeKind.platformOwner,
      companyId: '',
      uid: uid,
      locale: locale,
      register: (token) => _repository.registerPlatformToken(
        token: token,
        locale: locale,
      ),
    );
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
      // Token cleanup is best-effort and must never block sign-out or role switch.
    }
  }

  Future<void> _sync({
    required NotificationPushTokenScopeKind scope,
    required String companyId,
    required String uid,
    required String locale,
    required Future<void> Function(String token) register,
  }) async {
    if (uid.trim().isEmpty || state.isSyncing) return;
    emit(state.copyWith(isSyncing: true));
    try {
      final token = await _repository.currentToken();
      if (token == null || token.trim().isEmpty) {
        emit(state.copyWith(isSyncing: false));
        return;
      }
      await register(token);
      emit(NotificationPushTokenState(
        scope: scope,
        companyId: companyId,
        uid: uid,
        token: token,
      ));
      await _refreshSubscription?.cancel();
      _refreshSubscription = _repository.watchTokenRefreshes().listen((newToken) async {
        if (newToken.trim().isEmpty) return;
        try {
          await register(newToken);
          emit(NotificationPushTokenState(
            scope: scope,
            companyId: companyId,
            uid: uid,
            token: newToken,
          ));
        } catch (_) {
          // Retry on the next auth/locale/session sync.
        }
      });
    } catch (_) {
      emit(state.copyWith(isSyncing: false));
    }
  }

  @override
  Future<void> close() async {
    await _refreshSubscription?.cancel();
    return super.close();
  }
}
