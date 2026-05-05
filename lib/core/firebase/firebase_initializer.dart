import 'package:firebase_core/firebase_core.dart';

import '../../firebase_options.dart';

abstract final class FirebaseInitializer {
  static Future<void> initialize() {
    return Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
}
