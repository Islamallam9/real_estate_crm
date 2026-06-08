import 'package:bloc/bloc.dart';

import '../../domain/errors/auth_exception.dart';
import '../../domain/usecases/change_password_usecase.dart';
import '../../domain/usecases/complete_required_password_change_usecase.dart';
import 'password_management_state.dart';

class PasswordManagementCubit extends Cubit<PasswordManagementState> {
  PasswordManagementCubit({
    required ChangePasswordUseCase changePasswordUseCase,
    CompleteRequiredPasswordChangeUseCase? completeRequiredPasswordChangeUseCase,
  }) : _changePasswordUseCase = changePasswordUseCase,
       _completeRequiredPasswordChangeUseCase = completeRequiredPasswordChangeUseCase,
       super(const PasswordManagementState());

  final ChangePasswordUseCase _changePasswordUseCase;
  final CompleteRequiredPasswordChangeUseCase? _completeRequiredPasswordChangeUseCase;

  Future<bool> completeRequiredPasswordChange({
    required String companyId,
    required String currentPassword,
    required String newPassword,
  }) async {
    final useCase = _completeRequiredPasswordChangeUseCase;
    if (useCase == null) {
      emit(
        state.copyWith(
          status: PasswordManagementStatus.failure,
          message: AuthErrorMessages.passwordChangeFailed,
        ),
      );
      return false;
    }

    emit(
      state.copyWith(
        status: PasswordManagementStatus.saving,
        clearMessage: true,
      ),
    );

    try {
      await useCase(
        companyId: companyId,
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      emit(
        state.copyWith(
          status: PasswordManagementStatus.success,
          clearMessage: true,
        ),
      );
      return true;
    } on AuthException catch (error) {
      emit(
        state.copyWith(
          status: PasswordManagementStatus.failure,
          message: error.message,
        ),
      );
      return false;
    } catch (_) {
      emit(
        state.copyWith(
          status: PasswordManagementStatus.failure,
          message: AuthErrorMessages.passwordChangeFailed,
        ),
      );
      return false;
    }
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    emit(
      state.copyWith(
        status: PasswordManagementStatus.saving,
        clearMessage: true,
      ),
    );

    try {
      await _changePasswordUseCase(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      emit(
        state.copyWith(
          status: PasswordManagementStatus.success,
          clearMessage: true,
        ),
      );
      return true;
    } on AuthException catch (error) {
      emit(
        state.copyWith(
          status: PasswordManagementStatus.failure,
          message: error.message,
        ),
      );
      return false;
    } catch (_) {
      emit(
        state.copyWith(
          status: PasswordManagementStatus.failure,
          message: AuthErrorMessages.passwordChangeFailed,
        ),
      );
      return false;
    }
  }
}
