import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/localization/locale_cubit.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/crm_app_shell.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return CrmAppShell(
      selectedItem: CrmNavigationItem.more,
      title: l.settings,
      child: ListView(
        primary: true,
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: const [
                _AppearanceSection(),
                SizedBox(height: AppSpacing.md),
                _LanguageSection(),
                SizedBox(height: AppSpacing.md),
                _AccountSection(),
                SizedBox(height: AppSpacing.md),
                _AboutSection(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AppearanceSection extends StatelessWidget {
  const _AppearanceSection();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return _SettingsSection(
      title: l.appearance,
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) {
          final isDark = themeMode == ThemeMode.dark;
          return SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l.theme),
            subtitle: Text(isDark ? l.darkMode : l.lightMode),
            value: isDark,
            activeThumbColor: Colors.white,
            activeTrackColor: AppColors.primaryColor(context),
            inactiveThumbColor: AppColors.cardSurface(context),
            inactiveTrackColor: AppColors.isDark(context)
                ? AppColors.darkSurfaceAlt
                : AppColors.surfaceMuted,
            trackOutlineColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return AppColors.primaryBorder;
              }
              return AppColors.borderColor(context);
            }),
            onChanged: (_) => context.read<ThemeCubit>().toggle(),
          );
        },
      ),
    );
  }
}

class _LanguageSection extends StatelessWidget {
  const _LanguageSection();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return _SettingsSection(
      title: l.language,
      child: BlocBuilder<LocaleCubit, Locale?>(
        builder: (context, locale) {
          final selected = locale?.languageCode ?? 'en';
          return Column(
            children: [
              RadioListTile<String>(
                contentPadding: EdgeInsets.zero,
                title: Text(l.english),
                value: 'en',
                groupValue: selected,
                onChanged: (_) => context.read<LocaleCubit>().setEnglish(),
              ),
              RadioListTile<String>(
                contentPadding: EdgeInsets.zero,
                title: Text(l.arabic),
                value: 'ar',
                groupValue: selected,
                onChanged: (_) => context.read<LocaleCubit>().setArabic(),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AccountSection extends StatelessWidget {
  const _AccountSection();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return _SettingsSection(
      title: l.account,
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          final isLoggingOut = authState.status == AuthStatus.loading;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppButton(
                label: l.myProfile,
                icon: Icons.person_outline,
                variant: AppButtonVariant.secondary,
                onPressed: isLoggingOut
                    ? null
                    : () => context.go(RouteNames.profile),
              ),
              const SizedBox(height: AppSpacing.sm),
              AppButton(
                label: l.logout,
                icon: Icons.logout,
                variant: AppButtonVariant.danger,
                isLoading: isLoggingOut,
                onPressed: isLoggingOut
                    ? null
                    : () => context
                        .read<AuthBloc>()
                        .add(const AuthSignOutRequested()),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AboutSection extends StatelessWidget {
  const _AboutSection();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return _SettingsSection(
      title: l.aboutApp,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.loginBrandName,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${l.version} ${AppConstants.appVersion}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondaryColor(context),
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.cardSurface(context),
        border: Border.all(color: AppColors.borderColor(context)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}
