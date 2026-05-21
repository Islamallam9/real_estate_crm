import 'dart:async';
import 'dart:math' as math;

import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../users/domain/entities/user_profile.dart';
import '../../../users/domain/errors/user_profile_exception.dart';
import '../../../users/domain/usecases/resolve_auth_company_usecase.dart';
import '../../../users/domain/usecases/get_current_user_profile_usecase.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/errors/auth_exception.dart';
import '../../domain/usecases/auth_state_changes_usecase.dart';
import '../../domain/usecases/get_current_user_usecase.dart';
import '../../domain/usecases/record_login_activity_usecase.dart';
import '../../domain/usecases/send_password_reset_email_usecase.dart';
import '../../domain/usecases/sign_in_usecase.dart';
import '../../domain/usecases/sign_out_usecase.dart';
import 'auth_event.dart';
import 'auth_state.dart';

const _profileLoadTimeout = Duration(seconds: 10);
const _initialInvalidCredentialsBackoffSeconds = 2;
const _maxInvalidCredentialsBackoffSeconds = 60;

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({
    required SignInUseCase signInUseCase,
    required SignOutUseCase signOutUseCase,
    required SendPasswordResetEmailUseCase sendPasswordResetEmailUseCase,
    required GetCurrentUserUseCase getCurrentUserUseCase,
    required AuthStateChangesUseCase authStateChangesUseCase,
    required GetCurrentUserProfileUseCase getCurrentUserProfileUseCase,
    required ResolveAuthCompanyUseCase resolveAuthCompanyUseCase,
    required RecordLoginActivityUseCase recordLoginActivityUseCase,
  }) : _signInUseCase = signInUseCase,
       _signOutUseCase = signOutUseCase,
       _sendPasswordResetEmailUseCase = sendPasswordResetEmailUseCase,
       _getCurrentUserUseCase = getCurrentUserUseCase,
       _authStateChangesUseCase = authStateChangesUseCase,
       _getCurrentUserProfileUseCase = getCurrentUserProfileUseCase,
       _resolveAuthCompanyUseCase = resolveAuthCompanyUseCase,
       _recordLoginActivityUseCase = recordLoginActivityUseCase,
       super(const AuthState.initial()) {
    on<AuthStarted>(_onStarted);
    on<AuthSignInRequested>(_onSignInRequested);
    on<AuthPasswordResetRequested>(_onPasswordResetRequested);
    on<AuthLockoutTicked>(_onLockoutTicked);
    on<AuthSignOutRequested>(_onSignOutRequested);
    on<AuthUserChanged>(_onUserChanged);
    on<AuthProfileUpdated>(_onProfileUpdated);
  }

  final SignInUseCase _signInUseCase;
  final SignOutUseCase _signOutUseCase;
  final SendPasswordResetEmailUseCase _sendPasswordResetEmailUseCase;
  final GetCurrentUserUseCase _getCurrentUserUseCase;
  final AuthStateChangesUseCase _authStateChangesUseCase;
  final GetCurrentUserProfileUseCase _getCurrentUserProfileUseCase;
  final ResolveAuthCompanyUseCase _resolveAuthCompanyUseCase;
  final RecordLoginActivityUseCase _recordLoginActivityUseCase;

  StreamSubscription<AppUser?>? _authSubscription;
  Timer? _lockoutTimer;
  int _invalidCredentialAttempts = 0;
  DateTime? _lockedUntil;
  int _sessionGeneration = 0;

  Future<void> _onStarted(AuthStarted event, Emitter<AuthState> emit) async {
    final generation = _nextSessionGeneration();

    emit(
      state.copyWith(
        status: AuthStatus.loading,
        clearMessage: true,
        clearErrorCode: true,
        passwordResetSent: false,
      ),
    );

    await _authSubscription?.cancel();
    _authSubscription = _authStateChangesUseCase().listen((user) {
      add(AuthUserChanged(user));
    });

    final user = _getCurrentUserUseCase();
    if (user == null) {
      emit(const AuthState(status: AuthStatus.unauthenticated));
      return;
    }

      await _loadProfileAndEmitAuthenticated(
        emit: emit,
        user: user,
        signOutOnFailure: false,
        recordLoginActivity: false,
        expectedGeneration: generation,
      );
  }

  Future<void> _onSignInRequested(
    AuthSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    final generation = _nextSessionGeneration();
    final remaining = _lockoutSecondsRemaining();
    if (remaining > 0) {
      emit(
        AuthState(
          status: AuthStatus.failure,
          message: AuthErrorMessages.tooManyAttempts,
          errorCode: AuthErrorCode.tooManyAttempts,
          lockoutSecondsRemaining: remaining,
        ),
      );
      _startLockoutTimer();
      return;
    }

    emit(
      state.copyWith(
        status: AuthStatus.loading,
        clearMessage: true,
        clearErrorCode: true,
        clearUserProfile: true,
        clearCompanyMetadata: true,
        lockoutSecondsRemaining: 0,
        passwordResetSent: false,
      ),
    );

    try {
      final user = await _signInUseCase(
        email: event.email,
        password: event.password,
      );

      _resetInvalidCredentialBackoff();
      await _loadProfileAndEmitAuthenticated(
        emit: emit,
        user: user,
        signOutOnFailure: true,
        recordLoginActivity: true,
        expectedGeneration: generation,
      );
    } on AuthException catch (error) {
      if (error.code == AuthErrorCode.invalidCredentials) {
        final delaySeconds = _registerInvalidCredentialFailure();
        emit(
          AuthState(
            status: AuthStatus.failure,
            message: error.message,
            errorCode: error.code,
            lockoutSecondsRemaining: delaySeconds,
          ),
        );
        return;
      }

      emit(
        AuthState(
          status: AuthStatus.failure,
          message: error.message,
          errorCode: error.code,
        ),
      );
    } catch (_) {
      emit(
        const AuthState(
          status: AuthStatus.failure,
          message: AuthErrorMessages.signInFailed,
          errorCode: AuthErrorCode.signInFailed,
        ),
      );
    }
  }

  Future<void> _onPasswordResetRequested(
    AuthPasswordResetRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(
      state.copyWith(
        status: AuthStatus.loading,
        clearMessage: true,
        clearErrorCode: true,
        passwordResetSent: false,
      ),
    );

    try {
      await _sendPasswordResetEmailUseCase(email: event.email);
      emit(
        const AuthState(
          status: AuthStatus.unauthenticated,
          message: AuthSuccessMessages.passwordResetSent,
          passwordResetSent: true,
        ),
      );
    } on AuthException catch (error) {
      emit(
        AuthState(
          status: AuthStatus.failure,
          message: error.message,
          errorCode: error.code,
        ),
      );
    } catch (_) {
      emit(
        const AuthState(
          status: AuthStatus.failure,
          message: AuthErrorMessages.signInFailed,
          errorCode: AuthErrorCode.signInFailed,
        ),
      );
    }
  }

  void _onLockoutTicked(AuthLockoutTicked event, Emitter<AuthState> emit) {
    final remaining = _lockoutSecondsRemaining();
    if (remaining <= 0) {
      _lockoutTimer?.cancel();
      _lockoutTimer = null;
      emit(state.copyWith(lockoutSecondsRemaining: 0));
      return;
    }

    emit(state.copyWith(lockoutSecondsRemaining: remaining));
  }

  Future<void> _onSignOutRequested(
    AuthSignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    _nextSessionGeneration();
    emit(
      state.copyWith(
        status: AuthStatus.loading,
        clearMessage: true,
        clearErrorCode: true,
        clearUser: true,
        clearUserProfile: true,
        clearCompanyMetadata: true,
        passwordResetSent: false,
      ),
    );

    try {
      await _signOutUseCase();
      emit(const AuthState(status: AuthStatus.unauthenticated));
    } catch (_) {
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          message: AuthErrorMessages.signOutFailed,
          errorCode: AuthErrorCode.signOutFailed,
        ),
      );
    }
  }


  void _onProfileUpdated(
    AuthProfileUpdated event,
    Emitter<AuthState> emit,
  ) {
    final updatedProfile = event.profile ?? state.userProfile;
    final updatedName = event.fullName ?? updatedProfile?.fullName ?? state.user?.fullName;
    final updatedPhotoUrl = event.photoUrl ?? updatedProfile?.photoUrl ?? state.user?.photoUrl;

    emit(
      state.copyWith(
        userProfile: updatedProfile,
        user: state.user?.copyWith(
          fullName: updatedName,
          displayName: updatedName,
          photoUrl: updatedPhotoUrl,
        ),
      ),
    );
  }

  Future<void> _onUserChanged(
    AuthUserChanged event,
    Emitter<AuthState> emit,
  ) async {
    if (event.user == null) {
      _nextSessionGeneration();
      emit(const AuthState(status: AuthStatus.unauthenticated));
      return;
    }

    final nextUser = event.user!;
    final generation = _nextSessionGeneration();
    final currentUid = state.user?.uid;
    final currentProfileUid = state.userProfile?.uid;
    if (currentUid != nextUser.uid || currentProfileUid != nextUser.uid) {
      emit(
        state.copyWith(
          status: AuthStatus.loading,
          user: nextUser,
          clearUserProfile: true,
          clearCompanyMetadata: true,
          clearMessage: true,
          clearErrorCode: true,
        ),
      );
    }

    await _loadProfileAndEmitAuthenticated(
      emit: emit,
      user: nextUser,
      signOutOnFailure: false,
      recordLoginActivity: false,
      expectedGeneration: generation,
    );
  }

  Future<void> _loadProfileAndEmitAuthenticated({
    required Emitter<AuthState> emit,
    required AppUser user,
    required bool signOutOnFailure,
    required bool recordLoginActivity,
    required int expectedGeneration,
  }) async {
    try {
      final resolution = await _resolveAuthCompanyUseCase(
        uid: user.uid,
      ).timeout(
        _profileLoadTimeout,
        onTimeout: () {
          throw const UserProfileException(AppErrorMessages.unableToConnect);
        },
      );

      if (!_isCurrentSession(user.uid, expectedGeneration)) {
        return;
      }

      if (!resolution.hasCompany) {
        if (resolution.isPlatformAdmin) {
          if (!_isCurrentSession(user.uid, expectedGeneration)) {
            return;
          }
          _emitPlatformOnlySession(
            emit: emit,
            user: user,
            platformFullName: resolution.platformFullName,
            platformPhotoUrl: resolution.platformPhotoUrl,
          );
          _recordLoginActivityIfNeeded(recordLoginActivity: recordLoginActivity);
          return;
        }

        if (signOutOnFailure) {
          await _signOutUseCase();
        }

        throw const AuthException(
          AuthErrorMessages.accountNotLinked,
          code: AuthErrorCode.accountNotLinked,
        );
      }

      if (!resolution.isCompanyActive) {
        if (resolution.isPlatformAdmin) {
          if (!_isCurrentSession(user.uid, expectedGeneration)) {
            return;
          }
          _emitPlatformOnlySession(
            emit: emit,
            user: user,
            platformFullName: resolution.platformFullName,
            platformPhotoUrl: resolution.platformPhotoUrl,
          );
          _recordLoginActivityIfNeeded(recordLoginActivity: recordLoginActivity);
          return;
        }

        if (signOutOnFailure) {
          await _signOutUseCase();
        }

        throw const AuthException(
          AuthErrorMessages.companyInactive,
          code: AuthErrorCode.companyInactive,
        );
      }

      UserProfile profile;
      try {
        profile = await _loadCompanyProfile(
          companyId: resolution.membership!.companyId,
          uid: user.uid,
        );
      } on UserProfileException {
        if (resolution.isPlatformAdmin) {
          if (!_isCurrentSession(user.uid, expectedGeneration)) {
            return;
          }
          _emitPlatformOnlySession(
            emit: emit,
            user: user,
            platformFullName: resolution.platformFullName,
            platformPhotoUrl: resolution.platformPhotoUrl,
          );
          _recordLoginActivityIfNeeded(recordLoginActivity: recordLoginActivity);
          return;
        }
        rethrow;
      }

      if (!_isCurrentSession(user.uid, expectedGeneration)) {
        return;
      }

      if (!profile.isActive) {
        if (resolution.isPlatformAdmin) {
          if (!_isCurrentSession(user.uid, expectedGeneration)) {
            return;
          }
          _emitPlatformOnlySession(
            emit: emit,
            user: user,
            platformFullName: resolution.platformFullName,
            platformPhotoUrl: resolution.platformPhotoUrl,
          );
          _recordLoginActivityIfNeeded(recordLoginActivity: recordLoginActivity);
          return;
        }

        if (signOutOnFailure) {
          await _signOutUseCase();
        }

        throw const AuthException(
          AuthErrorMessages.inactiveAccount,
          code: AuthErrorCode.inactiveAccount,
        );
      }

      if (recordLoginActivity) {
        await _recordLoginActivity(companyId: profile.companyId);
        try {
          profile = await _loadCompanyProfile(
            companyId: profile.companyId,
            uid: user.uid,
          );
          if (!_isCurrentSession(user.uid, expectedGeneration)) {
            return;
          }
        } catch (_) {
          // Login telemetry should not block a valid session.
        }
      }

      if (!_isCurrentSession(user.uid, expectedGeneration)) {
        return;
      }

      emit(
        AuthState(
          status: AuthStatus.authenticated,
          user: user.copyWith(
            companyId: profile.companyId,
            role: profile.role,
            fullName: profile.fullName,
            email: profile.email,
            photoUrl: profile.photoUrl,
          ),
          userProfile: profile,
          companyMetadata: resolution.company,
          isPlatformAdmin: resolution.isPlatformAdmin,
        ),
      );
    } on UserProfileException catch (error) {
      if (!_isCurrentSession(user.uid, expectedGeneration)) {
        return;
      }
      if (signOutOnFailure) {
        await _signOutUseCase();
      }

      final errorCode = error.message == AppErrorMessages.unableToConnect
          ? AuthErrorCode.connection
          : AuthErrorCode.profileMissing;

      emit(
        AuthState(
          status: AuthStatus.failure,
          message: error.message,
          errorCode: errorCode,
        ),
      );
    } on AuthException catch (error) {
      if (!_isCurrentSession(user.uid, expectedGeneration)) {
        return;
      }
      emit(
        AuthState(
          status: AuthStatus.failure,
          message: error.message,
          errorCode: error.code,
        ),
      );
    } catch (_) {
      if (!_isCurrentSession(user.uid, expectedGeneration)) {
        return;
      }
      if (signOutOnFailure) {
        await _signOutUseCase();
      }

      emit(
        const AuthState(
          status: AuthStatus.failure,
          message: AuthErrorMessages.profileMissing,
          errorCode: AuthErrorCode.profileMissing,
        ),
      );
    }
  }

  void _recordLoginActivityIfNeeded({
    required bool recordLoginActivity,
    String? companyId,
  }) {
    if (!recordLoginActivity) {
      return;
    }

    unawaited(
      _recordLoginActivity(companyId: companyId),
    );
  }

  Future<void> _recordLoginActivity({String? companyId}) async {
    try {
      await _recordLoginActivityUseCase(
        companyId: companyId,
        locale: Intl.getCurrentLocale(),
        timezone: DateTime.now().timeZoneName,
        platform: defaultTargetPlatform.name,
        browser: kIsWeb ? 'web' : '',
        deviceType: kIsWeb ? 'web' : defaultTargetPlatform.name,
        userAgent: '',
        appVersion: AppConstants.appVersion,
      );
    } catch (_) {
      // Login telemetry should not block a valid session.
    }
  }

  Future<UserProfile> _loadCompanyProfile({
    required String companyId,
    required String uid,
  }) {
    return _getCurrentUserProfileUseCase(companyId: companyId, uid: uid)
        .timeout(
          _profileLoadTimeout,
          onTimeout: () {
            throw const UserProfileException(AppErrorMessages.unableToConnect);
          },
        );
  }

  void _emitPlatformOnlySession({
    required Emitter<AuthState> emit,
    required AppUser user,
    required String platformFullName,
    required String platformPhotoUrl,
  }) {
    final fullName = platformFullName.trim().isEmpty
        ? (user.fullName ?? user.displayName)
        : platformFullName.trim();
    final photoUrl = platformPhotoUrl.trim().isEmpty
        ? user.photoUrl
        : platformPhotoUrl.trim();
    emit(
      AuthState(
        status: AuthStatus.authenticated,
        user: user.copyWith(
          fullName: fullName,
          displayName: fullName,
          photoUrl: photoUrl,
        ),
        isPlatformAdmin: true,
      ),
    );
  }

  int _registerInvalidCredentialFailure() {
    _invalidCredentialAttempts += 1;
    final delaySeconds = math.min(
      _maxInvalidCredentialsBackoffSeconds,
      _initialInvalidCredentialsBackoffSeconds *
          math.pow(2, _invalidCredentialAttempts - 1).toInt(),
    );
    _lockedUntil = DateTime.now().add(Duration(seconds: delaySeconds));
    _startLockoutTimer();
    return delaySeconds;
  }

  int _lockoutSecondsRemaining() {
    final lockedUntil = _lockedUntil;
    if (lockedUntil == null) {
      return 0;
    }

    final remaining = lockedUntil.difference(DateTime.now()).inSeconds;
    return remaining > 0 ? remaining : 0;
  }

  void _startLockoutTimer() {
    _lockoutTimer?.cancel();
    _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      add(const AuthLockoutTicked());
    });
  }

  int _nextSessionGeneration() {
    _sessionGeneration += 1;
    return _sessionGeneration;
  }

  bool _isCurrentSession(String uid, int expectedGeneration) {
    if (isClosed || _sessionGeneration != expectedGeneration) {
      return false;
    }
    return _getCurrentUserUseCase()?.uid == uid;
  }

  void _resetInvalidCredentialBackoff() {
    _invalidCredentialAttempts = 0;
    _lockedUntil = null;
    _lockoutTimer?.cancel();
    _lockoutTimer = null;
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    _lockoutTimer?.cancel();
    return super.close();
  }
}
