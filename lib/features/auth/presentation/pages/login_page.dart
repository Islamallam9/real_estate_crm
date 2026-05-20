import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/masar_brand.dart';
import '../../../../l10n/app_localizations.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_state.dart';
import '../widgets/login_form.dart';
import '../widgets/public_auth_actions.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _LoginView();
  }
}

class _LoginView extends StatefulWidget {
  const _LoginView();

  @override
  State<_LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<_LoginView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.maybeOf(context)?.clearSnackBars();
    });
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;

    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (previous, current) {
        return previous.status != current.status &&
            current.status == AuthStatus.authenticated;
      },
      listener: (context, state) {
        if (state.isPlatformAdmin && state.userProfile == null) {
          context.go(RouteNames.platform);
          return;
        }
        context.go(RouteNames.dashboard);
      },
      child: Scaffold(
        backgroundColor: AppColors.appBackground(context),
        body: SafeArea(
          child: Stack(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: AlignmentDirectional.topEnd.resolve(
                      Directionality.of(context),
                    ),
                    radius: 1.1,
                    colors: [
                      AppColors.primaryColor(context).withValues(alpha: 0.13),
                      AppColors.appBackground(context),
                    ],
                  ),
                ),
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppColors.cardSurface(context),
                          border: Border.all(
                            color: AppColors.borderColor(context),
                          ),
                          borderRadius: AppRadius.xLarge,
                          boxShadow:
                              Theme.of(context).brightness == Brightness.dark
                                  ? null
                                  : AppShadows.subtle,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 46,
                                    height: 46,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryColor(
                                        context,
                                      ).withValues(alpha: 0.10),
                                      borderRadius: AppRadius.large,
                                      border: Border.all(
                                        color: AppColors.primaryColor(
                                          context,
                                        ).withValues(alpha: 0.22),
                                      ),
                                    ),
                                    child: const MasarBrandMark(size: 32),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Expanded(
                                    child: Text(
                                      localizations.loginBrandName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.xl),
                              Text(
                                localizations.welcomeBack,
                                style: textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                localizations.loginSubtitle,
                                style: textTheme.bodyMedium?.copyWith(
                                  color: AppColors.textSecondaryColor(context),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              const LoginForm(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              PositionedDirectional(
                top: AppSpacing.md,
                start: AppSpacing.md,
                child: _PublicBackButton(
                  tooltip: localizations.back,
                  onPressed: () => context.go(RouteNames.onboarding),
                ),
              ),
              const PositionedDirectional(
                top: AppSpacing.md,
                end: AppSpacing.md,
                child: PublicAuthActions(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PublicBackButton extends StatelessWidget {
  const _PublicBackButton({required this.tooltip, required this.onPressed});

  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.cardSurface(context).withValues(alpha: 0.92),
        border: Border.all(color: AppColors.borderColor(context)),
        borderRadius: AppRadius.large,
      ),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: const Icon(Icons.arrow_back),
      ),
    );
  }
}
