import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_radius.dart';
import 'app_text_styles.dart';

abstract final class AppTheme {
  static ThemeData get light {
    return _build(
      brightness: Brightness.light,
      primary: AppColors.primary,
      background: AppColors.background,
      surface: AppColors.surface,
      surfaceAlt: AppColors.surfaceAlt,
      border: AppColors.border,
      textPrimary: AppColors.textPrimary,
      textSecondary: AppColors.textSecondary,
      error: AppColors.error,
    );
  }

  static ThemeData get dark {
    return _build(
      brightness: Brightness.dark,
      primary: AppColors.darkPrimary,
      background: AppColors.darkBackground,
      surface: AppColors.darkCardSurface,
      surfaceAlt: AppColors.darkSurfaceAlt,
      border: AppColors.darkBorder,
      textPrimary: AppColors.darkTextPrimary,
      textSecondary: AppColors.darkTextSecondary,
      error: AppColors.darkError,
    );
  }

  static ThemeData _build({
    required Brightness brightness,
    required Color primary,
    required Color background,
    required Color surface,
    required Color surfaceAlt,
    required Color border,
    required Color textPrimary,
    required Color textSecondary,
    required Color error,
  }) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: brightness,
      primary: primary,
      surface: surface,
      error: error,
      onPrimary: Colors.white,
      onSurface: textPrimary,
      onSurfaceVariant: textSecondary,
      outline: border,
      outlineVariant: border,
    );

    final isDark = brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      canvasColor: background,
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? AppColors.darkSurface : surface,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: false,
      ),
      dividerTheme: DividerThemeData(color: border),
      dividerColor: border,
      popupMenuTheme: PopupMenuThemeData(
        color: surface,
        surfaceTintColor: surface,
        textStyle: TextStyle(color: textPrimary),
      ),
      iconTheme: IconThemeData(color: isDark ? textSecondary : null),
      textTheme: TextTheme(
        displayMedium: AppTextStyles.display.copyWith(color: textPrimary),
        headlineMedium: AppTextStyles.headline.copyWith(color: textPrimary),
        titleMedium: AppTextStyles.title.copyWith(color: textPrimary),
        bodyLarge: AppTextStyles.body.copyWith(color: textPrimary),
        bodyMedium: AppTextStyles.body.copyWith(color: textPrimary),
        bodySmall: AppTextStyles.bodyMuted.copyWith(color: textSecondary),
        labelMedium: AppTextStyles.label.copyWith(color: textSecondary),
        labelLarge: AppTextStyles.label.copyWith(color: textSecondary),
        labelSmall: AppTextStyles.label.copyWith(color: textSecondary),
      ),
      cardTheme: CardThemeData(
        color: surface,
        surfaceTintColor: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.medium,
          side: BorderSide(color: border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppColors.darkSurfaceAlt : surface,
        labelStyle: TextStyle(color: textSecondary),
        hintStyle: TextStyle(color: textSecondary),
        prefixIconColor: textSecondary,
        suffixIconColor: textSecondary,
        border: OutlineInputBorder(
          borderRadius: AppRadius.medium,
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.medium,
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.medium,
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: surfaceAlt,
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
        ),
        iconTheme: WidgetStatePropertyAll(IconThemeData(color: textSecondary)),
      ),
      dataTableTheme: DataTableThemeData(
        headingTextStyle: TextStyle(
          color: textSecondary,
          fontWeight: FontWeight.w700,
        ),
        dataTextStyle: TextStyle(color: textPrimary),
        headingRowColor: WidgetStatePropertyAll(
          isDark ? AppColors.darkSurfaceAlt : AppColors.surfaceMuted,
        ),
        dataRowColor: WidgetStateProperty.resolveWith((states) {
          if (!isDark) {
            return null;
          }
          if (states.contains(WidgetState.selected) ||
              states.contains(WidgetState.hovered)) {
            return AppColors.darkSelectedSurface;
          }
          return AppColors.darkCardSurface;
        }),
        dividerThickness: 0.7,
        decoration: BoxDecoration(
          color: surface,
          border: Border.all(color: border),
          borderRadius: AppRadius.medium,
        ),
      ),
      listTileTheme: ListTileThemeData(
        textColor: textPrimary,
        iconColor: textSecondary,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 44),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.medium),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: BorderSide(color: border),
          minimumSize: const Size(0, 44),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.medium),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: primary),
      ),
    );
  }
}
