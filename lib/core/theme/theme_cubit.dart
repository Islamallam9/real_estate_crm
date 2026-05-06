import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeCubit extends Cubit<ThemeMode> {
  ThemeCubit() : super(ThemeMode.light);

  static const themeModeKey = 'selected_theme_mode';

  Future<void> loadSavedThemeMode() async {
    final preferences = await SharedPreferences.getInstance();
    final themeMode = preferences.getString(themeModeKey);

    if (themeMode == 'dark') {
      emit(ThemeMode.dark);
      return;
    }

    emit(ThemeMode.light);
  }

  Future<void> setLight() {
    return _setThemeMode(ThemeMode.light);
  }

  Future<void> setDark() {
    return _setThemeMode(ThemeMode.dark);
  }

  Future<void> toggle() {
    return state == ThemeMode.dark ? setLight() : setDark();
  }

  Future<void> _setThemeMode(ThemeMode themeMode) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      themeModeKey,
      themeMode == ThemeMode.dark ? 'dark' : 'light',
    );
    emit(themeMode);
  }
}
