import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/observability/device_metadata.dart';
import '../../domain/errors/notification_exception.dart';

abstract interface class NotificationPushTokenRemoteDataSource {
  Future<String?> currentToken({bool requestPermission = false});

  Stream<String> watchTokenRefreshes();

  Future<void> registerCompanyToken({
    required String companyId,
    required String token,
    required String locale,
    required String role,
  });

  Future<void> registerPlatformToken({
    required String token,
    required String locale,
  });

  Future<void> deactivateCompanyToken({
    required String companyId,
    required String token,
  });

  Future<void> deactivatePlatformToken({required String token});
}

class FirebaseNotificationPushTokenRemoteDataSource
    implements NotificationPushTokenRemoteDataSource {
  FirebaseNotificationPushTokenRemoteDataSource({
    FirebaseMessaging? messaging,
    FirebaseFunctions? functions,
  })  : _messaging = messaging ?? FirebaseMessaging.instance,
        _functions =
            functions ?? FirebaseFunctions.instanceFor(region: 'us-east1');

  // FCM Web requires a VAPID key. It should come from
  // --dart-define-from-file=config/firebase.local.json. The fallback below is
  // the public Web Push key for the current Firebase project, so local runs
  // still work if the developer forgets the dart-define file.
  static const _webVapidKey = String.fromEnvironment(
    'FIREBASE_WEB_VAPID_KEY',
    defaultValue:
        'BMJxnIOuiZcPYJekEx_CQitzBdHlbq6xH4RLZdpeO7T-jXhhOvd7a6a-VtMgNACLFI6ud-8RCYxu1iIgRm4tW-A',
  );

  final FirebaseMessaging _messaging;
  final FirebaseFunctions _functions;

  @override
  Future<String?> currentToken({bool requestPermission = false}) async {
    try {
      if (!_isSupportedPlatform()) {
        _debugTokenStatus('unsupported-platform');
        return null;
      }
      if (kIsWeb && _webVapidKey.trim().isEmpty) {
        _debugTokenStatus('missing-web-vapid-key');
        throw const NotificationException('missing-web-vapid-key');
      }

      final settings = await _ensurePermission(requestPermission: requestPermission);
      _debugTokenStatus(
        'permission-${settings.authorizationStatus.name}',
      );
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        throw const NotificationException('notification-permission-denied');
      }
      if (!_canUsePushToken(settings.authorizationStatus)) {
        return null;
      }

      final token = await _messaging.getToken(
        vapidKey: kIsWeb ? _webVapidKey : null,
      );
      _debugTokenStatus(
        token == null || token.trim().isEmpty ? 'token-empty' : 'token-obtained',
      );
      return token;
    } on FirebaseException catch (error) {
      _debugTokenStatus('firebase-error-${error.code}');
      throw NotificationException(_mapFirebaseError(error));
    } catch (_) {
      _debugTokenStatus('token-error');
      return null;
    }
  }

  @override
  Stream<String> watchTokenRefreshes() {
    return _messaging.onTokenRefresh.where((token) => token.trim().isNotEmpty);
  }

  @override
  Future<void> registerCompanyToken({
    required String companyId,
    required String token,
    required String locale,
    required String role,
  }) async {
    final payload = <String, dynamic>{
      'companyId': companyId,
      'token': token,
      'locale': locale,
      'role': role,
      ..._clientMetadata(),
    };
    final result = await _callTokenFunction(
      'registerCompanyNotificationToken',
      payload,
    );
    if (_requiresCachedWebTokenRefresh(result)) {
      final refreshedToken = await _refreshCachedWebTokenAfterServerRejection();
      if (refreshedToken == null || refreshedToken.trim().isEmpty) {
        throw const NotificationException('web-token-refresh-failed');
      }
      if (refreshedToken == token) {
        throw const NotificationException('web-token-refresh-returned-same-token');
      }
      final refreshedResult = await _callTokenFunction(
        'registerCompanyNotificationToken',
        <String, dynamic>{
          ...payload,
          'token': refreshedToken,
          ..._clientMetadata(),
        },
      );
      _ensureTokenRegistrationAccepted(refreshedResult);
      if (_requiresCachedWebTokenRefresh(refreshedResult)) {
        _debugTokenStatus('company-token-refresh-rejected-${refreshedResult['reason'] ?? 'unknown'}');
        throw NotificationException(
          refreshedResult['reason']?.toString() ?? 'web-token-refresh-failed',
        );
      }
      _debugTokenStatus('company-token-save-success-refreshed');
      return;
    }
    _ensureTokenRegistrationAccepted(result);
    _debugTokenStatus('company-token-save-success');
  }

  @override
  Future<void> registerPlatformToken({
    required String token,
    required String locale,
  }) async {
    final payload = <String, dynamic>{
      'token': token,
      'locale': locale,
      ..._clientMetadata(),
    };
    final result = await _callTokenFunction(
      'registerPlatformNotificationToken',
      payload,
    );
    if (_requiresCachedWebTokenRefresh(result)) {
      final refreshedToken = await _refreshCachedWebTokenAfterServerRejection();
      if (refreshedToken == null || refreshedToken.trim().isEmpty) {
        throw const NotificationException('web-token-refresh-failed');
      }
      if (refreshedToken == token) {
        throw const NotificationException('web-token-refresh-returned-same-token');
      }
      final refreshedResult = await _callTokenFunction(
        'registerPlatformNotificationToken',
        <String, dynamic>{
          ...payload,
          'token': refreshedToken,
          ..._clientMetadata(),
        },
      );
      _ensureTokenRegistrationAccepted(refreshedResult);
      if (_requiresCachedWebTokenRefresh(refreshedResult)) {
        _debugTokenStatus('platform-token-refresh-rejected-${refreshedResult['reason'] ?? 'unknown'}');
        throw NotificationException(
          refreshedResult['reason']?.toString() ?? 'web-token-refresh-failed',
        );
      }
      _debugTokenStatus('platform-token-save-success-refreshed');
      return;
    }
    _ensureTokenRegistrationAccepted(result);
    _debugTokenStatus('platform-token-save-success');
  }

  @override
  Future<void> deactivateCompanyToken({
    required String companyId,
    required String token,
  }) async {
    await _callTokenFunction(
      'removeNotificationToken',
      <String, dynamic>{
        'companyId': companyId,
        'token': token,
        'scope': 'company',
      },
    );
  }

  @override
  Future<void> deactivatePlatformToken({required String token}) async {
    await _callTokenFunction(
      'removeNotificationToken',
      <String, dynamic>{
        'token': token,
        'scope': 'platformOwner',
      },
    );
  }

  Future<Map<String, dynamic>> _callTokenFunction(
    String functionName,
    Map<String, dynamic> payload,
  ) async {
    try {
      final result = await _functions.httpsCallable(functionName).call(payload);
      final data = result.data;
      if (data is Map) {
        return data.map(
          (key, value) => MapEntry(key.toString(), value),
        );
      }
      return const <String, dynamic>{};
    } on FirebaseFunctionsException catch (error) {
      _debugTokenStatus('callable-$functionName-failed-${error.code}');
      throw NotificationException(_mapFirebaseFunctionsError(error));
    } catch (error) {
      _debugTokenStatus('callable-$functionName-failed-unknown');
      throw const NotificationException(AppErrorMessages.unknown);
    }
  }

  bool _requiresCachedWebTokenRefresh(Map<String, dynamic> result) {
    if (!kIsWeb || result['refreshRequired'] != true) {
      return false;
    }
    final reason = result['reason']?.toString();
    return reason == 'cached-invalid-web-token' ||
        reason == 'web-token-probe-failed';
  }

  void _ensureTokenRegistrationAccepted(Map<String, dynamic> result) {
    if (result['registered'] == false) {
      final reason = result['reason']?.toString().trim();
      throw NotificationException(
        reason == null || reason.isEmpty
            ? 'notification-token-registration-rejected'
            : reason,
      );
    }
  }

  Future<String?> _refreshCachedWebTokenAfterServerRejection() async {
    if (!kIsWeb) {
      return null;
    }
    try {
      _debugTokenStatus('web-token-refresh-required');
      await _messaging.deleteToken();
      await Future<void>.delayed(const Duration(milliseconds: 350));
      final token = await _messaging.getToken(vapidKey: _webVapidKey);
      _debugTokenStatus(
        token == null || token.trim().isEmpty
            ? 'web-token-refresh-empty'
            : 'web-token-refresh-obtained',
      );
      return token;
    } on FirebaseException catch (error) {
      _debugTokenStatus('web-token-refresh-failed-${error.code}');
      throw NotificationException(_mapFirebaseError(error));
    } catch (error) {
      _debugTokenStatus('web-token-refresh-failed-${error.runtimeType}');
      return null;
    }
  }

  Map<String, dynamic> _clientMetadata() {
    final device = platformDeviceMetadata();
    return <String, dynamic>{
      'platform': _platformName(),
      'appVersion': AppConstants.appVersion,
      'buildNumber': AppConstants.appBuildNumber,
      'timezone': DateTime.now().timeZoneName,
      if ((device['userAgent'] ?? '').trim().isNotEmpty)
        'userAgent': device['userAgent'],
      ..._webLocationMetadata(),
    };
  }

  Map<String, dynamic> _webLocationMetadata() {
    if (!kIsWeb) {
      return const <String, dynamic>{};
    }
    try {
      return <String, dynamic>{
        'webOrigin': Uri.base.origin,
        'webHref': Uri.base.toString(),
      };
    } catch (_) {
      return const <String, dynamic>{};
    }
  }

  Future<NotificationSettings> _ensurePermission({
    required bool requestPermission,
  }) async {
    final settings = await _messaging.getNotificationSettings();
    if (_canUsePushToken(settings.authorizationStatus)) {
      return settings;
    }

    // Professional UX rule:
    // - Automatic background sync must not trigger browser/OS prompts.
    // - The native prompt is requested only after the user taps Enable notifications.
    if (!requestPermission) {
      return settings;
    }

    final requested = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'masar_fcm_permission_last_requested_${_platformName()}',
      DateTime.now().toIso8601String(),
    );
    return requested;
  }

  bool _canUsePushToken(AuthorizationStatus status) {
    return status == AuthorizationStatus.authorized ||
        status == AuthorizationStatus.provisional;
  }

  bool _isSupportedPlatform() {
    return kIsWeb || defaultTargetPlatform == TargetPlatform.android;
  }

  String _platformName() {
    if (kIsWeb) {
      return 'web';
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'android';
    }
    return defaultTargetPlatform.name;
  }

  void _debugTokenStatus(String status) {
    if (!kDebugMode) {
      return;
    }
    debugPrint(
      'MasarFCM: status=$status '
      'platform=${_platformName()} '
      'hasVapidKey=${!kIsWeb || _webVapidKey.trim().isNotEmpty}',
    );
  }

  String _mapFirebaseError(FirebaseException error) {
    return _mapFirebaseCode(error.code);
  }

  String _mapFirebaseFunctionsError(FirebaseFunctionsException error) {
    return _mapFirebaseCode(error.code);
  }

  String _mapFirebaseCode(String code) {
    switch (code) {
      case 'permission-denied':
        return AppErrorMessages.permissionDenied;
      case 'unauthenticated':
        return AppErrorMessages.unauthenticated;
      case 'not-found':
        return AppErrorMessages.notFound;
      case 'cancelled':
        return AppErrorMessages.cancelled;
      case 'deadline-exceeded':
      case 'unavailable':
        return AppErrorMessages.unableToConnect;
      default:
        return AppErrorMessages.unknown;
    }
  }
}
