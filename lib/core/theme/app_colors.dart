import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  static const primary = Color(0xFFF2B84B);
  static const primaryDark = Color(0xFFD99A1E);
  static const primaryLight = Color(0xFFFFF4DB);
  static const primaryPressed = Color(0xFFD99A1E);
  static const primaryDeep = Color(0xFFC97900);
  static const primaryBorder = Color(0xFFF7D27A);
  static const secondary = Color(0xFFA67C35);
  static const background = Color(0xFFF7F2E8);
  static const backgroundSoft = Color(0xFFFBF6EC);
  static const backgroundHighlight = Color(0xFFFFF8EA);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceMuted = Color(0xFFF4EBD8);
  static const surfaceAlt = Color(0xFFFBF6EC);
  static const border = Color(0xFFE7DDCC);
  static const divider = Color(0xFFEFE3CC);
  static const textPrimary = Color(0xFF181818);
  static const textStrong = Color(0xFF111111);
  static const textSecondary = Color(0xFF6F6A5F);
  static const textMuted = Color(0xFF8A8173);
  static const success = Color(0xFF15803D);
  static const successSoft = Color(0xFFDCFCE7);
  static const warning = Color(0xFFF59E0B);
  static const warningSoft = Color(0xFFFEF3C7);
  static const error = Color(0xFFDC2626);
  static const errorSoft = Color(0xFFFEE2E2);
  static const info = Color(0xFF2563EB);
  static const infoSoft = Color(0xFFDBEAFE);
  static const shell = Color(0xFFEFE3CC);
  static const shellRaised = Color(0xFFF7EDD9);
  static const shellActive = Color(0xFFF2B84B);
  static const shellActiveHover = Color(0xFFFFD47A);
  static const shellText = Color(0xFF2B2418);
  static const shellTextMuted = Color(0xFF756B5A);
  static const shellIconMuted = Color(0xFF8A8173);
  static const shellBorder = Color(0xFFE0D1B8);

  static const darkPrimary = Color(0xFFF59E0B);
  static const darkPrimaryHover = Color(0xFFFBBF24);
  static const darkBackground = Color(0xFF151A1F);
  static const darkSurface = Color(0xFF1E252C);
  static const darkCardSurface = Color(0xFF242C35);
  static const darkSurfaceAlt = Color(0xFF2B3542);
  static const darkShell = Color(0xFF1F2933);
  static const darkShellRaised = Color(0xFF2B3542);
  static const darkSelectedSurface = Color(0xFF3A2D17);
  static const darkBorder = Color(0xFF3A4553);
  static const darkTextPrimary = Color(0xFFF8F3EA);
  static const darkTextSecondary = Color(0xFFB8AE9E);
  static const darkTextMuted = Color(0xFF948A7C);
  static const darkSuccess = Color(0xFF4ADE80);
  static const darkWarning = Color(0xFFF59E0B);
  static const darkError = Color(0xFFF87171);
  static const darkInfo = Color(0xFF93C5FD);

  static bool isDark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  static Color appBackground(BuildContext context) {
    return isDark(context) ? darkBackground : background;
  }

  static Color chromeSurface(BuildContext context) {
    return isDark(context) ? darkSurface : surfaceAlt;
  }

  static Color cardSurface(BuildContext context) {
    return isDark(context) ? darkCardSurface : surface;
  }

  static Color inputSurface(BuildContext context) {
    return isDark(context) ? darkSurfaceAlt : surface;
  }

  static Color selectedSurface(BuildContext context) {
    return isDark(context) ? darkSelectedSurface : primaryLight;
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
