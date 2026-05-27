import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

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
import '../../../auth/presentation/widgets/change_password_dialog.dart';

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
                _SecuritySection(),
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
                label: l.changePassword,
                icon: Icons.lock_reset,
                variant: AppButtonVariant.secondary,
                onPressed: isLoggingOut
                    ? null
                    : () => showChangePasswordDialog(context),
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



class _SecuritySection extends StatelessWidget {
  const _SecuritySection();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return _SettingsSection(
      title: l.security,
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          final profile = authState.userProfile;
          if (profile == null) {
            final user = authState.user;
            if (authState.isPlatformAdmin && user != null) {
              return _PlatformOwnerSecurityDetails(uid: user.uid);
            }
            return Text(
              l.missingCompanyProfile,
              style: TextStyle(color: AppColors.textSecondaryColor(context)),
            );
          }

          return Column(
            children: [
              _SettingsDetail(
                label: l.lastLogin,
                value: _lastLoginValue(context, profile.lastLoginAt),
              ),
              if (authState.isPlatformAdmin)
                _SettingsDetail(
                  label: l.ipAddress,
                  value: _safeValue(l, profile.lastLoginIp),
                ),
              _SettingsDetail(
                label: l.device,
                value: _safeValue(l, profile.lastLoginDeviceType),
              ),
              _SettingsDetail(
                label: l.browser,
                value: _safeValue(l, profile.lastLoginBrowser),
              ),
              _SettingsDetail(
                label: l.platform,
                value: _safeValue(l, profile.lastLoginPlatform),
              ),
              _SettingsDetail(
                label: l.timezone,
                value: _safeValue(l, profile.lastLoginTimezone),
              ),
            ],
          );
        },
      ),
    );
  }
}


class _PlatformOwnerSecurityDetails extends StatelessWidget {
  const _PlatformOwnerSecurityDetails({required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('platform_admins')
          .doc(uid)
          .snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() ?? const <String, dynamic>{};
        return Column(
          children: [
            _SettingsDetail(
              label: l.lastLogin,
              value: _lastLoginValue(context, _nullableDateTimeFromValue(data['lastLoginAt'])),
            ),
            _SettingsDetail(
              label: l.ipAddress,
              value: _safeValue(l, data['lastLoginIp'] as String? ?? ''),
            ),
            _SettingsDetail(
              label: l.device,
              value: _safeValue(l, data['lastLoginDeviceType'] as String? ?? ''),
            ),
            _SettingsDetail(
              label: l.browser,
              value: _safeValue(l, data['lastLoginBrowser'] as String? ?? ''),
            ),
            _SettingsDetail(
              label: l.platform,
              value: _safeValue(l, data['lastLoginPlatform'] as String? ?? ''),
            ),
            _SettingsDetail(
              label: l.timezone,
              value: _safeValue(l, data['lastLoginTimezone'] as String? ?? ''),
            ),
          ],
        );
      },
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
            '${l.version} ${AppConstants.appVersion}+${AppConstants.appBuildNumber}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondaryColor(context),
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Divider(color: AppColors.borderColor(context)),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l.developedAndDesignedBy,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
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


class _SettingsDetail extends StatelessWidget {
  const _SettingsDetail({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondaryColor(context),
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.end,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

String _safeValue(AppLocalizations l, String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? l.notAvailable : trimmed;
}


DateTime? _nullableDateTimeFromValue(Object? value) {
  if (value == null) {
    return null;
  }
  if (value is Timestamp) {
    return value.toDate();
  }
  if (value is DateTime) {
    return value;
  }
  return null;
}

String _lastLoginValue(BuildContext context, DateTime? value) {
  if (value == null) {
    return AppLocalizations.of(context)!.noLoginActivityYet;
  }
  final localeName = Localizations.localeOf(context).toString();
  return DateFormat.yMd(localeName).add_jm().format(value.toLocal());
}
