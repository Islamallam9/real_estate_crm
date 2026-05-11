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
        titleTextStyle: AppTextStyles.title.copyWith(color: textPrimary),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? AppColors.darkSurfaceAlt : AppColors.shell,
        contentTextStyle: AppTextStyles.body.copyWith(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.medium),
      ),
      dividerTheme: DividerThemeData(color: border),
      dividerColor: border,
      popupMenuTheme: PopupMenuThemeData(
        color: surface,
        surfaceTintColor: surface,
        textStyle: AppTextStyles.body.copyWith(color: textPrimary),
        elevation: 10,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.large,
          side: BorderSide(color: border),
        ),
      ),
      iconTheme: IconThemeData(color: isDark ? textSecondary : null),
      textTheme: TextTheme(
        displayMedium: AppTextStyles.display.copyWith(color: textPrimary),
        headlineMedium: AppTextStyles.headline.copyWith(color: textPrimary),
        titleMedium: AppTextStyles.title.copyWith(color: textPrimary),
        titleSmall: AppTextStyles.title.copyWith(
          color: textPrimary,
          fontSize: 15,
        ),
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
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.large,
          side: BorderSide(color: border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppColors.darkSurfaceAlt : surface,
        labelStyle: AppTextStyles.label.copyWith(color: textSecondary),
        hintStyle: AppTextStyles.body.copyWith(
          color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
          fontWeight: FontWeight.w400,
        ),
        prefixIconColor: textSecondary,
        suffixIconColor: textSecondary,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 13,
        ),
        border: OutlineInputBorder(
          borderRadius: AppRadius.large,
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.large,
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.large,
          borderSide: BorderSide(color: primary, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.large,
          borderSide: BorderSide(color: error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.large,
          borderSide: BorderSide(color: error, width: 1.4),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        surfaceTintColor: surface,
        indicatorColor: isDark ? AppColors.darkSelectedSurface : AppColors.primaryLight,
        labelTextStyle: WidgetStatePropertyAll(
          AppTextStyles.label.copyWith(color: textPrimary),
        ),
        iconTheme: WidgetStatePropertyAll(IconThemeData(color: textSecondary)),
      ),
      dataTableTheme: DataTableThemeData(
        headingTextStyle: TextStyle(
          color: textSecondary,
          fontWeight: FontWeight.w700,
          fontSize: 12.5,
        ),
        dataTextStyle: AppTextStyles.body.copyWith(color: textPrimary),
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
          borderRadius: AppRadius.large,
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
          disabledBackgroundColor: isDark
              ? AppColors.darkSurfaceAlt
              : const Color(0xFFE0E6EF),
          disabledForegroundColor: textSecondary,
          elevation: 0,
          minimumSize: const Size(0, 42),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: AppTextStyles.label.copyWith(
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.large),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: BorderSide(color: border),
          minimumSize: const Size(0, 42),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: AppTextStyles.label.copyWith(
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.large),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: AppTextStyles.label.copyWith(fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.medium),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: textSecondary,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.medium),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: surface,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.xLarge),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: surface,
        modalBackgroundColor: surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
      ),
    );
  }
}
