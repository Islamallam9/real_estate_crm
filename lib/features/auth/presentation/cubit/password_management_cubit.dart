import 'package:bloc/bloc.dart';

import '../../domain/errors/auth_exception.dart';
import '../../domain/usecases/change_password_usecase.dart';
import 'password_management_state.dart';

class PasswordManagementCubit extends Cubit<PasswordManagementState> {
  PasswordManagementCubit({required ChangePasswordUseCase changePasswordUseCase})
    : _changePasswordUseCase = changePasswordUseCase,
      super(const PasswordManagementState());

  final ChangePasswordUseCase _changePasswordUseCase;

  Future<void> changePassword({
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
    } on AuthException catch (error) {
      emit(
        state.copyWith(
          status: PasswordManagementStatus.failure,
          message: error.message,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: PasswordManagementStatus.failure,
          message: AuthErrorMessages.passwordChangeFailed,
        ),
      );
    }
  }
}
