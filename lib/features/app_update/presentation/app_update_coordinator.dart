import 'package:flutter/foundation.dart';

import '../domain/entities/android_release_policy.dart';

class AppUpdateCoordinator {
  AppUpdateCoordinator._();

  static final AppUpdateCoordinator instance = AppUpdateCoordinator._();

  final ValueNotifier<AndroidReleasePolicy?> requestedPolicy =
      ValueNotifier<AndroidReleasePolicy?>(null);

  void showUpdate(AndroidReleasePolicy policy) {
    requestedPolicy.value = policy;
  }

  void clear() {
    requestedPolicy.value = null;
  }
}
