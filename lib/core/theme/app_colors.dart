import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  static const primary = Color(0xFF123047);
  static const primaryDark = Color(0xFF0B1F2F);
  static const primaryLight = Color(0xFFE7EEF3);
  static const background = Color(0xFFF6F7F9);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceMuted = Color(0xFFF1F4F6);
  static const surfaceAlt = Color(0xFFF1F4F6);
  static const border = Color(0xFFDDE3EA);
  static const textPrimary = Color(0xFF17212B);
  static const textSecondary = Color(0xFF667085);
  static const success = Color(0xFF16803C);
  static const warning = Color(0xFFD18B00);
  static const error = Color(0xFFC2410C);
  static const info = Color(0xFF2563EB);

  static const darkPrimary = Color(0xFF5BA7C8);
  static const darkPrimaryHover = Color(0xFF79B8D3);
  static const darkBackground = Color(0xFF0F172A);
  static const darkSurface = Color(0xFF111827);
  static const darkCardSurface = Color(0xFF182235);
  static const darkSurfaceAlt = Color(0xFF1E293B);
  static const darkSelectedSurface = Color(0xFF263449);
  static const darkBorder = Color(0xFF334155);
  static const darkTextPrimary = Color(0xFFF8FAFC);
  static const darkTextSecondary = Color(0xFFCBD5E1);
  static const darkTextMuted = Color(0xFF94A3B8);
  static const darkSuccess = Color(0xFF22C55E);
  static const darkWarning = Color(0xFFF59E0B);
  static const darkError = Color(0xFFF87171);
  static const darkInfo = Color(0xFF60A5FA);

  static bool isDark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  static Color appBackground(BuildContext context) {
    return isDark(context) ? darkBackground : background;
  }

  static Color chromeSurface(BuildContext context) {
    return isDark(context) ? darkSurface : surface;
  }

  static Color cardSurface(BuildContext context) {
    return isDark(context) ? darkCardSurface : surface;
  }

  static Color inputSurface(BuildContext context) {
    return isDark(context) ? darkSurfaceAlt : surface;
  }

  static Color selectedSurface(BuildContext context) {
    return isDark(context) ? darkSelectedSurface : const Color(0x14123047);
  }

  static Color borderColor(BuildContext context) {
    return isDark(context) ? darkBorder : border;
  }

  static Color primaryColor(BuildContext context) {
    return isDark(context) ? darkPrimary : primary;
  }

  static Color textPrimaryColor(BuildContext context) {
    return isDark(context) ? darkTextPrimary : textPrimary;
  }

  static Color textSecondaryColor(BuildContext context) {
    return isDark(context) ? darkTextSecondary : textSecondary;
  }

  static Color textMutedColor(BuildContext context) {
    return isDark(context) ? darkTextMuted : textSecondary;
  }

  static Color successColor(BuildContext context) {
    return isDark(context) ? darkSuccess : success;
  }

  static Color warningColor(BuildContext context) {
    return isDark(context) ? darkWarning : warning;
  }

  static Color errorColor(BuildContext context) {
    return isDark(context) ? darkError : error;
  }

  static Color infoColor(BuildContext context) {
    return isDark(context) ? darkInfo : info;
  }
}
