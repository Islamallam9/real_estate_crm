import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleCubit extends Cubit<Locale?> {
  LocaleCubit({Locale? initialLocale}) : super(initialLocale);

  static const localeKey = 'selected_locale';

  Future<void> loadSavedLocale() async {
    final preferences = await SharedPreferences.getInstance();
    final languageCode = preferences.getString(localeKey);

    if (languageCode != null &&
        (languageCode == 'ar' || languageCode == 'en')) {
      emit(Locale(languageCode));
    }
  }

  Future<void> setEnglish() {
    return _setLocale(const Locale('en'));
  }

  Future<void> setArabic() {
    return _setLocale(const Locale('ar'));
  }

  Future<void> toggle() {
    return state?.languageCode == 'ar' ? setEnglish() : setArabic();
  }

  Future<void> _setLocale(Locale locale) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(localeKey, locale.languageCode);
    emit(locale);
  }
}
