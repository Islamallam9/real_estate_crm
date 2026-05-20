import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/datasources/auth_remote_data_source.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/errors/auth_exception.dart';
import '../../domain/usecases/change_password_usecase.dart';
import '../../domain/usecases/complete_required_password_change_usecase.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../cubit/password_management_cubit.dart';
import '../cubit/password_management_state.dart';

class ForceChangePasswordPage extends StatelessWidget {
  const ForceChangePasswordPage({super.key});

  static Widget withDependencies() {
    final repository = AuthRepositoryImpl(
      remoteDataSource: FirebaseAuthRemoteDataSource(),
    );

    return BlocProvider(
      create: (_) => PasswordManagementCubit(
        changePasswordUseCase: ChangePasswordUseCase(repository),
        completeRequiredPasswordChangeUseCase:
            CompleteRequiredPasswordChangeUseCase(repository),
      ),
      child: const ForceChangePasswordPage(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const _ForceChangePasswordView();
  }
}

class _ForceChangePasswordView extends StatefulWidget {
  const _ForceChangePasswordView();

  @override
  State<_ForceChangePasswordView> createState() => _ForceChangePasswordViewState();
}

class _ForceChangePasswordViewState extends State<_ForceChangePasswordView> {
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
    final authState = context.watch<AuthBloc>().state;
    final companyId = authState.userProfile?.companyId ?? '';

    return BlocListener<PasswordManagementCubit, PasswordManagementState>(
      listener: (context, state) {
        if (state.status == PasswordManagementStatus.success) {
          final profile = context.read<AuthBloc>().state.userProfile;
          if (profile != null) {
            context.read<AuthBloc>().add(
              AuthProfileUpdated(
                profile: profile.copyWith(
                  mustChangePassword: false,
                  passwordSetupMethod: 'changed',
                ),
              ),
            );
          }
          AppFeedback.success(context, l.passwordChangedSuccessfully);
          context.go(RouteNames.dashboard);
        }
        if (state.status == PasswordManagementStatus.failure) {
          AppFeedback.error(context, _passwordErrorLabel(l, state.message));
        }
      },
      child: BlocBuilder<PasswordManagementCubit, PasswordManagementState>(
        builder: (context, state) {
          final saving = state.status == PasswordManagementStatus.saving;
          return Scaffold(
            body: SafeArea(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: AlignmentDirectional.topStart,
                    end: AlignmentDirectional.bottomEnd,
                    colors: [
                      AppColors.appBackground(context),
                      AppColors.primaryColor(context).withOpacity(0.12),
                    ],
                  ),
                ),
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: Card(
                        elevation: 0,
                        color: AppColors.cardSurface(context),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.xl),
                          side: BorderSide(color: AppColors.borderColor(context)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.xl),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Icon(
                                  Icons.lock_reset_outlined,
                                  size: 44,
                                  color: AppColors.primaryColor(context),
                                ),
                                const SizedBox(height: AppSpacing.md),
                                Text(
                                  l.temporaryPasswordChangeRequiredTitle,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  l.temporaryPasswordChangeRequiredMessage,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: AppColors.textMutedColor(context),
                                      ),
                                ),
                                const SizedBox(height: AppSpacing.xl),
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
                                const SizedBox(height: AppSpacing.md),
                                AppTextField(
                                  controller: _newPassword,
                                  label: l.newPassword,
                                  obscureText: true,
                                  enabled: !saving,
                                  validator: (value) => _newPasswordValidator(value, l),
                                ),
                                const SizedBox(height: AppSpacing.md),
                                AppTextField(
                                  controller: _confirmPassword,
                                  label: l.confirmPassword,
                                  obscureText: true,
                                  enabled: !saving,
                                  validator: (value) {
                                    if ((value ?? '') != _newPassword.text) {
                                      return l.passwordsDoNotMatch;
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: AppSpacing.xl),
                                AppButton(
                                  label: l.updatePasswordAndContinue,
                                  icon: Icons.check_circle_outline,
                                  isLoading: saving,
                                  onPressed: saving || companyId.isEmpty ? null : _submit,
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                TextButton(
                                  onPressed: saving
                                      ? null
                                      : () => context.read<AuthBloc>().add(
                                            const AuthSignOutRequested(),
                                          ),
                                  child: Text(l.logout),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final companyId = context.read<AuthBloc>().state.userProfile?.companyId ?? '';
    if (companyId.isEmpty) {
      return;
    }
    context.read<PasswordManagementCubit>().completeRequiredPasswordChange(
          companyId: companyId,
          currentPassword: _currentPassword.text,
          newPassword: _newPassword.text,
        );
  }
}

String? _newPasswordValidator(String? value, AppLocalizations l) {
  final text = value ?? '';
  if (text.isEmpty) {
    return l.newPasswordRequired;
  }
  if (text.length < 8) {
    return l.newPasswordTooShort;
  }
  return null;
}

String _passwordErrorLabel(AppLocalizations l, String? message) {
  return switch (message) {
    AuthErrorMessages.currentPasswordIncorrect => l.currentPasswordIncorrect,
    AuthErrorMessages.recentLoginRequired => l.recentLoginRequired,
    AuthErrorMessages.weakPassword => l.newPasswordTooShort,
    AuthErrorMessages.passwordChangeFailed => l.passwordChangeFailed,
    _ => l.passwordChangeFailed,
  };
}
