import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  static const primary = Color(0xFF4A5FC8);
  static const primaryDark = Color(0xFF172448);
  static const primaryLight = Color(0xFFE9EDFF);
  static const secondary = Color(0xFF2E8C8A);
  static const background = Color(0xFFF4F6FA);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceMuted = Color(0xFFF7F9FC);
  static const surfaceAlt = Color(0xFFEFF3F8);
  static const border = Color(0xFFDCE3EC);
  static const textPrimary = Color(0xFF111827);
  static const textSecondary = Color(0xFF64748B);
  static const textMuted = Color(0xFF8A97AA);
  static const success = Color(0xFF238554);
  static const warning = Color(0xFFB7791F);
  static const error = Color(0xFFBE3A34);
  static const info = Color(0xFF2F6FE4);
  static const shell = Color(0xFF0B1B31);
  static const shellRaised = Color(0xFF142740);
  static const shellText = Color(0xFFEAF1F8);
  static const shellTextMuted = Color(0xFF91A3B8);

  static const darkPrimary = Color(0xFF9AA8EF);
  static const darkPrimaryHover = Color(0xFFB1BDF8);
  static const darkBackground = Color(0xFF090F1B);
  static const darkSurface = Color(0xFF101A2A);
  static const darkCardSurface = Color(0xFF141F31);
  static const darkSurfaceAlt = Color(0xFF1A283E);
  static const darkSelectedSurface = Color(0xFF243457);
  static const darkBorder = Color(0xFF314056);
  static const darkTextPrimary = Color(0xFFF4F8FC);
  static const darkTextSecondary = Color(0xFFB7C4D4);
  static const darkTextMuted = Color(0xFF8EA0B6);
  static const darkSuccess = Color(0xFF58D08B);
  static const darkWarning = Color(0xFFE7B85C);
  static const darkError = Color(0xFFFF8A80);
  static const darkInfo = Color(0xFF88B5FF);

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
    return isDark(context) ? darkSelectedSurface : const Color(0x174058E8);
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
