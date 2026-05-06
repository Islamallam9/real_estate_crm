import 'dart:async';

import 'package:bloc/bloc.dart';

import '../../../../core/errors/error_mapper.dart';
import '../../../users/domain/errors/user_profile_exception.dart';
import '../../../users/domain/usecases/get_current_user_profile_usecase.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/errors/auth_exception.dart';
import '../../domain/usecases/auth_state_changes_usecase.dart';
import '../../domain/usecases/get_current_user_usecase.dart';
import '../../domain/usecases/sign_in_usecase.dart';
import '../../domain/usecases/sign_out_usecase.dart';
import 'auth_event.dart';
import 'auth_state.dart';

const _demoCompanyId = 'demo_company';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({
    required SignInUseCase signInUseCase,
    required SignOutUseCase signOutUseCase,
    required GetCurrentUserUseCase getCurrentUserUseCase,
    required AuthStateChangesUseCase authStateChangesUseCase,
    required GetCurrentUserProfileUseCase getCurrentUserProfileUseCase,
  }) : _signInUseCase = signInUseCase,
       _signOutUseCase = signOutUseCase,
       _getCurrentUserUseCase = getCurrentUserUseCase,
       _authStateChangesUseCase = authStateChangesUseCase,
       _getCurrentUserProfileUseCase = getCurrentUserProfileUseCase,
       super(const AuthState.initial()) {
    on<AuthStarted>(_onStarted);
    on<AuthSignInRequested>(_onSignInRequested);
    on<AuthSignOutRequested>(_onSignOutRequested);
    on<AuthUserChanged>(_onUserChanged);
  }

  final SignInUseCase _signInUseCase;
  final SignOutUseCase _signOutUseCase;
  final GetCurrentUserUseCase _getCurrentUserUseCase;
  final AuthStateChangesUseCase _authStateChangesUseCase;
  final GetCurrentUserProfileUseCase _getCurrentUserProfileUseCase;

  StreamSubscription<AppUser?>? _authSubscription;

  Future<void> _onStarted(AuthStarted event, Emitter<AuthState> emit) async {
    emit(
      state.copyWith(
        status: AuthStatus.loading,
        clearMessage: true,
        clearErrorCode: true,
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
    );
  }

  Future<void> _onSignInRequested(
    AuthSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(
      state.copyWith(
        status: AuthStatus.loading,
        clearMessage: true,
        clearErrorCode: true,
        clearUserProfile: true,
      ),
    );

    try {
      final user = await _signInUseCase(
        email: event.email,
        password: event.password,
      );

      await _loadProfileAndEmitAuthenticated(
        emit: emit,
        user: user,
        signOutOnFailure: true,
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

  Future<void> _onSignOutRequested(
    AuthSignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(
      state.copyWith(
        status: AuthStatus.loading,
        clearMessage: true,
        clearErrorCode: true,
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

  Future<void> _onUserChanged(
    AuthUserChanged event,
    Emitter<AuthState> emit,
  ) async {
    if (event.user == null) {
      if (state.status == AuthStatus.failure) {
        return;
      }

      emit(const AuthState(status: AuthStatus.unauthenticated));
      return;
    }

    await _loadProfileAndEmitAuthenticated(
      emit: emit,
      user: event.user!,
      signOutOnFailure: false,
    );
  }

  Future<void> _loadProfileAndEmitAuthenticated({
    required Emitter<AuthState> emit,
    required AppUser user,
    required bool signOutOnFailure,
  }) async {
    try {
      final profile = await _getCurrentUserProfileUseCase(
        companyId: _demoCompanyId,
        uid: user.uid,
      );

      if (!profile.isActive) {
        if (signOutOnFailure) {
          await _signOutUseCase();
        }

        throw const AuthException(
          AuthErrorMessages.inactiveAccount,
          code: AuthErrorCode.inactiveAccount,
        );
      }

      emit(
        AuthState(
          status: AuthStatus.authenticated,
          user: user.copyWith(
            companyId: profile.companyId,
            role: profile.role,
            fullName: profile.fullName,
            email: profile.email,
          ),
          userProfile: profile,
        ),
      );
    } on UserProfileException catch (error) {
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
      emit(
        AuthState(
          status: AuthStatus.failure,
          message: error.message,
          errorCode: error.code,
        ),
      );
    } catch (_) {
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

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}
