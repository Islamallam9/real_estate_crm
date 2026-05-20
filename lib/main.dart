import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:visibility_detector/visibility_detector.dart';

import 'app.dart';
import 'core/firebase/firebase_initializer.dart';
import 'core/localization/locale_cubit.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  VisibilityDetectorController.instance.updateInterval =
      const Duration(milliseconds: 500);

  runApp(const _MasarBootstrapApp());
}

class _MasarBootstrapApp extends StatefulWidget {
  const _MasarBootstrapApp();

  @override
  State<_MasarBootstrapApp> createState() => _MasarBootstrapAppState();
}

class _MasarBootstrapAppState extends State<_MasarBootstrapApp> {
  late Future<Locale?> _startupFuture;
  Locale? _startupLocale;

  @override
  void initState() {
    super.initState();
    _startupFuture = _startAppWithTimeout();
  }

  void _retryStartup() {
    setState(() {
      _startupLocale = null;
      _startupFuture = _startAppWithTimeout();
    });
  }

  Future<Locale?> _startAppWithTimeout() {
    return _startApp().timeout(const Duration(seconds: 18));
  }

  Future<Locale?> _startApp() async {
    final initialLocale = await _loadInitialLocale();
    _startupLocale = initialLocale;
    await FirebaseInitializer.initialize();
    return initialLocale;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Locale?>(
      future: _startupFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            !snapshot.hasError) {
          return RealEstateCrmApp(initialLocale: snapshot.data);
        }

        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.hasError) {
          return _MasarStartupFallback(
            locale: _startupLocale,
            onRetry: _retryStartup,
          );
        }

        return const _MasarStartupLoading();
      },
    );
  }
}

class _MasarStartupLoading extends StatelessWidget {
  const _MasarStartupLoading();

  static const _background = Color(0xFFFFFBF4);
  static const _primary = Color(0xFFD9952E);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Theme(
        data: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: _primary),
          fontFamily: 'Plus Jakarta Sans',
        ),
        child: const ColoredBox(
          color: _background,
          child: Center(
            child: SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.8,
                color: _primary,
                backgroundColor: Color(0x24D9952E),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MasarStartupFallback extends StatelessWidget {
  const _MasarStartupFallback({required this.locale, required this.onRetry});

  final Locale? locale;
  final VoidCallback onRetry;

  static const _background = Color(0xFFFFFBF4);
  static const _primary = Color(0xFFD9952E);
  static const _text = Color(0xFF102235);
  static const _muted = Color(0xFF756B5A);
  static const _border = Color(0xFFE7DDCC);

  @override
  Widget build(BuildContext context) {
    final systemLocale = WidgetsBinding.instance.platformDispatcher.locale;
    final isArabic = (locale ?? systemLocale).languageCode == 'ar';
    final title = isArabic
        ? 'تعذر إكمال تشغيل مسار CRM.'
        : 'Masar CRM could not finish startup.';
    final message = isArabic
        ? 'تحقق من الاتصال ثم حاول مرة أخرى.'
        : 'Check the connection and try again.';
    final retry = isArabic ? 'إعادة المحاولة' : 'Retry';

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Theme(
        data: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: _primary),
          fontFamily: isArabic ? 'IBM Plex Sans Arabic' : 'Plus Jakarta Sans',
        ),
        child: ColoredBox(
            color: _background,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: Container(
                  margin: const EdgeInsets.all(24),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: _border),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: _primary,
                        size: 30,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: _text,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: _muted,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 18),
                      FilledButton(
                        onPressed: onRetry,
                        style: FilledButton.styleFrom(
                          backgroundColor: _primary,
                          foregroundColor: _text,
                        ),
                        child: Text(retry),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
    );
  }
}

Future<Locale?> _loadInitialLocale() async {
  final preferences = await SharedPreferences.getInstance();
  final languageCode = preferences.getString(LocaleCubit.localeKey);

  if (languageCode != null && (languageCode == 'ar' || languageCode == 'en')) {
    return Locale(languageCode);
  }

  return null;
}
