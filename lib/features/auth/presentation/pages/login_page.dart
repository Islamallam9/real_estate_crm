import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/routing/route_names.dart';
import '../../../../core/utils/external_link_opener.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_feedback.dart';
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
                              const SizedBox(height: AppSpacing.md),
                              const _LoginSupportContactSection(),
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

class _LoginSupportContactSection extends StatelessWidget {
  const _LoginSupportContactSection();

  static const String _supportEmail = 'islamallam9@outlook.com';
  static const String _whatsAppPhone = '201208090241';

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final supportMessage = localizations.loginSupportWhatsAppMessage;
    final whatsAppUrl = Uri.https(
      'wa.me',
      '/$_whatsAppPhone',
      {'text': supportMessage},
    ).toString();
    final emailUrl = Uri(
      scheme: 'mailto',
      path: _supportEmail,
      queryParameters: {
        'subject': localizations.loginSupportEmailSubject,
        'body': localizations.loginSupportEmailBody,
      },
    ).toString();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Divider(height: 1, color: AppColors.borderColor(context)),
        const SizedBox(height: AppSpacing.sm),
        LayoutBuilder(
          builder: (context, constraints) {
            final stacked = constraints.maxWidth < 430;
            final title = Text(
              localizations.loginSupportTitle,
              style: textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            );
            final subtitle = Text(
              localizations.loginSupportSubtitle,
              softWrap: true,
              style: textTheme.labelSmall?.copyWith(
                color: AppColors.textSecondaryColor(context),
                fontWeight: FontWeight.w600,
                height: 1.25,
              ),
            );
            final actions = Wrap(
              spacing: AppSpacing.xs,
              runSpacing: 2,
              alignment: WrapAlignment.end,
              children: [
                _LoginSupportAction(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: localizations.whatsapp,
                  onPressed: () => _openLoginSupportUrl(context, whatsAppUrl),
                ),
                _LoginSupportAction(
                  icon: Icons.mail_outline_rounded,
                  label: localizations.email,
                  onPressed: () => _openLoginSupportUrl(context, emailUrl),
                ),
              ],
            );

            if (stacked) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  title,
                  const SizedBox(height: 2),
                  subtitle,
                  const SizedBox(height: AppSpacing.xs),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: actions,
                  ),
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      title,
                      const SizedBox(height: 2),
                      subtitle,
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Flexible(
                  child: Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: actions,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _LoginSupportAction extends StatelessWidget {
  const _LoginSupportAction({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: TextButton.styleFrom(
        visualDensity: VisualDensity.compact,
        foregroundColor: AppColors.primaryColor(context),
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 7,
        ),
        textStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.medium),
      ),
    );
  }
}

Future<void> _openLoginSupportUrl(BuildContext context, String url) async {
  final localizations = AppLocalizations.of(context)!;
  try {
    final launched = kIsWeb
        ? await openExternalLink(url)
        : await launchUrl(
            Uri.parse(url),
            mode: LaunchMode.externalApplication,
          );
    if (!launched && context.mounted) {
      AppFeedback.error(context, localizations.actionFailed);
    }
  } catch (_) {
    if (context.mounted) {
      AppFeedback.error(context, localizations.actionFailed);
    }
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
