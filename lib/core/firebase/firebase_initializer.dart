import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../firebase_options.dart';

abstract final class FirebaseInitializer {
  static Future<void> initialize() async {
    try {
      if (Firebase.apps.isEmpty) {
        if (kIsWeb) {
          _validateWebOptions();
          await Firebase.initializeApp(
            options: DefaultFirebaseOptions.currentPlatform,
          );
        } else {
          await Firebase.initializeApp();
        }
      }
    } on FirebaseException catch (error) {
      if (error.code != 'duplicate-app') {
        rethrow;
      }
    }
  }

  static void _validateWebOptions() {
    const webApiKey = String.fromEnvironment('FIREBASE_WEB_API_KEY');
    const webAppId = String.fromEnvironment('FIREBASE_WEB_APP_ID');
    const messagingSenderId = String.fromEnvironment(
      'FIREBASE_MESSAGING_SENDER_ID',
    );
    const projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
    const authDomain = String.fromEnvironment('FIREBASE_AUTH_DOMAIN');
    const storageBucket = String.fromEnvironment('FIREBASE_STORAGE_BUCKET');

    final missingDefines = <String>[
      if (webApiKey.isEmpty) 'FIREBASE_WEB_API_KEY',
      if (webAppId.isEmpty) 'FIREBASE_WEB_APP_ID',
      if (messagingSenderId.isEmpty) 'FIREBASE_MESSAGING_SENDER_ID',
      if (projectId.isEmpty) 'FIREBASE_PROJECT_ID',
      if (authDomain.isEmpty) 'FIREBASE_AUTH_DOMAIN',
      if (storageBucket.isEmpty) 'FIREBASE_STORAGE_BUCKET',
    ];

    if (missingDefines.isEmpty) {
      return;
    }

    throw StateError(
      'Missing Firebase dart defines for web: ${missingDefines.join(', ')}. '
      'Launch with: flutter run -d edge '
      '--dart-define-from-file=config/firebase.local.json. '
      'Build with: flutter build web --release '
      '--dart-define-from-file=config/firebase.local.json.',
    );
  }
}
