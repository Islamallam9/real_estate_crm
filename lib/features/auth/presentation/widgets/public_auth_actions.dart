import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/locale_cubit.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../../l10n/app_localizations.dart';

class PublicAuthActions extends StatelessWidget {
  const PublicAuthActions({super.key, this.alignment = AlignmentDirectional.topEnd});

  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Align(
      alignment: alignment,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.cardSurface(context).withValues(alpha: 0.92),
          border: Border.all(color: AppColors.borderColor(context)),
          borderRadius: AppRadius.large,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              PopupMenuButton<String>(
                tooltip: l.language,
                icon: const Icon(Icons.language),
                onSelected: (languageCode) {
                  final cubit = context.read<LocaleCubit>();
                  if (languageCode == 'ar') {
                    cubit.setArabic();
                  } else {
                    cubit.setEnglish();
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(value: 'en', child: Text(l.english)),
                  PopupMenuItem(value: 'ar', child: Text(l.arabic)),
                ],
              ),
              BlocBuilder<ThemeCubit, ThemeMode>(
                builder: (context, themeMode) {
                  final isDark = themeMode == ThemeMode.dark;
                  return IconButton(
                    tooltip: isDark ? l.lightMode : l.darkMode,
                    onPressed: () => context.read<ThemeCubit>().toggle(),
                    icon: Icon(
                      isDark
                          ? Icons.light_mode_outlined
                          : Icons.dark_mode_outlined,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
