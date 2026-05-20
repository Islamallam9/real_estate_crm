import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/error_mapper.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/routing/route_names.dart';
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
        final isLocked = state.lockoutSecondsRemaining > 0;

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
                validator: (value) => AppValidators.email(value, localizations),
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
              const SizedBox(height: AppSpacing.md),
              if (state.status == AuthStatus.failure && state.message != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: _LoginErrorMessage(
                    message: _localizedAuthError(
                      localizations,
                      state.errorCode,
                      state.message,
                      state.lockoutSecondsRemaining,
                    ),
                  ),
                ),
              AppButton(
                label: isLoading
                    ? localizations.signingIn
                    : isLocked
                        ? localizations.authRetryCountdown(
                            state.lockoutSecondsRemaining,
                          )
                        : localizations.signIn,
                onPressed: isLoading || isLocked ? null : () => _submit(context),
                isLoading: isLoading,
              ),
              const SizedBox(height: AppSpacing.sm),
              TextButton.icon(
                onPressed: isLoading ? null : () => context.go(RouteNames.registerCompany),
                icon: const Icon(Icons.add_circle_outline),
                label: Text(localizations.registerYourCompany),
              ),
            ],
          ),
        );
      },
    );
  }

  void _submit(BuildContext context) {
    FocusScope.of(context).unfocus();
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
  int lockoutSecondsRemaining,
) {
  switch (code) {
    case AuthErrorCode.invalidCredentials:
      if (lockoutSecondsRemaining > 0) {
        return '${localizations.authErrorInvalidCredentials} ${localizations.authRetryCountdown(lockoutSecondsRemaining)}';
      }
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
    case AuthErrorCode.accountNotLinked:
      return localizations.authErrorAccountNotLinked;
    case AuthErrorCode.companyInactive:
      return localizations.authErrorCompanyInactive;
    case AuthErrorCode.tooManyAttempts:
      return localizations.authRetryCountdown(lockoutSecondsRemaining);
    case AuthErrorCode.unknown:
    case null:
      return localizeErrorMessage(
        localizations,
        fallback ?? localizations.authErrorSignInFailed,
      );
  }
}


class _LoginInfoMessage extends StatelessWidget {
  const _LoginInfoMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.successColor(context).withValues(alpha: 0.08),
        border: Border.all(
          color: AppColors.successColor(context).withValues(alpha: 0.32),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle_outline,
            color: AppColors.successColor(context),
            size: 20,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.successColor(context),
                  ),
            ),
          ),
        ],
      ),
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
