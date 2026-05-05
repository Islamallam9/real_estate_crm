import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/firebase/firebase_initializer.dart';
import 'core/localization/locale_cubit.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final initialLocale = await _loadInitialLocale();
  await FirebaseInitializer.initialize();
  runApp(RealEstateCrmApp(initialLocale: initialLocale));
}

Future<Locale?> _loadInitialLocale() async {
  final preferences = await SharedPreferences.getInstance();
  final languageCode = preferences.getString(LocaleCubit.localeKey);

  if (languageCode != null && (languageCode == 'ar' || languageCode == 'en')) {
    return Locale(languageCode);
  }

  return null;
}
