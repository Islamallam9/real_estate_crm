import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/error_mapper.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/errors/auth_exception.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final isLoading = state.status == AuthStatus.loading;

        return Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextField(
                controller: _emailController,
                label: localizations.email,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                enabled: !isLoading,
                validator: (value) => _validateEmail(value, localizations),
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _passwordController,
                label: localizations.password,
                obscureText: true,
                textInputAction: TextInputAction.done,
                enabled: !isLoading,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return localizations.passwordRequired;
                  }

                  return null;
                },
              ),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton(
                  onPressed: isLoading ? null : () {},
                  child: Text(localizations.forgotPassword),
                ),
              ),
              if (state.status == AuthStatus.failure && state.message != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: _LoginErrorMessage(
                    message: _localizedAuthError(
                      localizations,
                      state.errorCode,
                      state.message,
                    ),
                  ),
                ),
              AppButton(
                label: isLoading
                    ? localizations.signingIn
                    : localizations.signIn,
                onPressed: isLoading ? null : () => _submit(context),
                isLoading: isLoading,
              ),
            ],
          ),
        );
      },
    );
  }

  String? _validateEmail(String? value, AppLocalizations localizations) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) {
      return localizations.emailRequired;
    }

    final isValid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
    if (!isValid) {
      return localizations.invalidEmail;
    }

    return null;
  }

  void _submit(BuildContext context) {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    context.read<AuthBloc>().add(
      AuthSignInRequested(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      ),
    );
  }
}

String _localizedAuthError(
  AppLocalizations localizations,
  AuthErrorCode? code,
  String? fallback,
) {
  switch (code) {
    case AuthErrorCode.invalidCredentials:
      return localizations.authErrorInvalidCredentials;
    case AuthErrorCode.connection:
      return localizations.authErrorConnection;
    case AuthErrorCode.signInFailed:
      return localizations.authErrorSignInFailed;
    case AuthErrorCode.signOutFailed:
      return localizations.authErrorSignOutFailed;
    case AuthErrorCode.profileMissing:
      return localizations.authErrorProfileMissing;
    case AuthErrorCode.inactiveAccount:
      return localizations.authErrorInactiveAccount;
    case AuthErrorCode.unknown:
    case null:
      return localizeErrorMessage(
        localizations,
        fallback ?? localizations.authErrorSignInFailed,
      );
  }
}

class _LoginErrorMessage extends StatelessWidget {
  const _LoginErrorMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.errorColor(context).withValues(alpha: 0.08),
        border: Border.all(
          color: AppColors.errorColor(context).withValues(alpha: 0.32),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.error_outline,
            color: AppColors.errorColor(context),
            size: 20,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(
                color: AppColors.errorColor(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
