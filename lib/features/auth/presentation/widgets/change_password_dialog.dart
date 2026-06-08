import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/utils/validators.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/datasources/auth_remote_data_source.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/errors/auth_exception.dart';
import '../../domain/usecases/change_password_usecase.dart';
import '../cubit/password_management_cubit.dart';
import '../cubit/password_management_state.dart';

Future<void> showChangePasswordDialog(BuildContext context) {
  final repository = AuthRepositoryImpl(
    remoteDataSource: FirebaseAuthRemoteDataSource(),
  );
  return showDialog<void>(
    context: context,
    builder: (_) => BlocProvider(
      create: (_) => PasswordManagementCubit(
        changePasswordUseCase: ChangePasswordUseCase(repository),
      ),
      child: const ChangePasswordDialog(),
    ),
  );
}

class ChangePasswordDialog extends StatefulWidget {
  const ChangePasswordDialog({super.key});

  @override
  State<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _currentPassword = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();

  @override
  void dispose() {
    _currentPassword.dispose();
    _newPassword.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return BlocBuilder<PasswordManagementCubit, PasswordManagementState>(
      builder: (context, state) {
        final saving = state.status == PasswordManagementStatus.saving;
        return AlertDialog(
            title: Text(l.changePassword),
            content: SizedBox(
              width: 440,
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppTextField(
                      controller: _currentPassword,
                      label: l.currentPassword,
                      obscureText: true,
                      enabled: !saving,
                      validator: (value) {
                        return (value ?? '').isEmpty
                            ? l.currentPasswordRequired
                            : null;
                      },
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      controller: _newPassword,
                      label: l.newPassword,
                      obscureText: true,
                      enabled: !saving,
                      validator: (value) => AppValidators.password(
                        value,
                        l,
                        requiredMessage: l.newPasswordRequired,
                      ),
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      controller: _confirmPassword,
                      label: l.confirmPassword,
                      obscureText: true,
                      enabled: !saving,
                      validator: (value) => AppValidators.confirmPassword(
                        value,
                        _newPassword.text,
                        l,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: saving ? null : () => Navigator.of(context).pop(),
                child: Text(l.cancel),
              ),
              AppButton(
                label: l.save,
                isLoading: saving,
                onPressed: saving ? null : _submit,
              ),
            ],
        );
      },
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final cubit = context.read<PasswordManagementCubit>();
    final success = await cubit.changePassword(
      currentPassword: _currentPassword.text,
      newPassword: _newPassword.text,
    );
    if (!mounted) {
      return;
    }
    final l = AppLocalizations.of(context)!;
    if (success) {
      AppFeedback.success(context, l.passwordChangedSuccessfully);
      Navigator.of(context).pop();
      return;
    }
    AppFeedback.error(context, _passwordErrorLabel(l, cubit.state.message));
  }
}

String _passwordErrorLabel(AppLocalizations l, String? message) {
  return switch (message) {
    AuthErrorMessages.currentPasswordIncorrect => l.currentPasswordIncorrect,
    AuthErrorMessages.recentLoginRequired => l.recentLoginRequired,
    AuthErrorMessages.weakPassword => l.weakPassword,
    AuthErrorMessages.passwordChangeFailed => l.passwordChangeFailed,
    _ => l.passwordChangeFailed,
  };
}
