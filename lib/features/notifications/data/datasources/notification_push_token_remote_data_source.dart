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
  Future<String?> currentToken();

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

  static const _webVapidKey = String.fromEnvironment(
    'FIREBASE_WEB_VAPID_KEY',
  );

  final FirebaseMessaging _messaging;
  final FirebaseFunctions _functions;

  @override
  Future<String?> currentToken() async {
    try {
      if (!_isSupportedPlatform()) {
        return null;
      }
      if (kIsWeb && _webVapidKey.trim().isEmpty) {
        return null;
      }

      final settings = await _ensurePermission();
      if (!_canUsePushToken(settings.authorizationStatus)) {
        return null;
      }

      return _messaging.getToken(vapidKey: kIsWeb ? _webVapidKey : null);
    } on FirebaseException catch (error) {
      throw NotificationException(_mapFirebaseError(error));
    } catch (_) {
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
    await _callTokenFunction(
      'registerCompanyNotificationToken',
      <String, dynamic>{
        'companyId': companyId,
        'token': token,
        'locale': locale,
        'role': role,
        ..._clientMetadata(),
      },
    );
  }

  @override
  Future<void> registerPlatformToken({
    required String token,
    required String locale,
  }) async {
    await _callTokenFunction(
      'registerPlatformNotificationToken',
      <String, dynamic>{
        'token': token,
        'locale': locale,
        ..._clientMetadata(),
      },
    );
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

  Future<void> _callTokenFunction(
    String functionName,
    Map<String, dynamic> payload,
  ) async {
    try {
      await _functions.httpsCallable(functionName).call(payload);
    } on FirebaseFunctionsException catch (error) {
      throw NotificationException(_mapFirebaseFunctionsError(error));
    } catch (_) {
      throw const NotificationException(AppErrorMessages.unknown);
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
    };
  }

  Future<NotificationSettings> _ensurePermission() async {
    final settings = await _messaging.getNotificationSettings();
    if (_canUsePushToken(settings.authorizationStatus) ||
        settings.authorizationStatus == AuthorizationStatus.denied) {
      return settings;
    }

    final prefs = await SharedPreferences.getInstance();
    final permissionKey = 'masar_fcm_permission_requested_${_platformName()}';
    if (prefs.getBool(permissionKey) == true) {
      return settings;
    }

    await prefs.setBool(permissionKey, true);
    return _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
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
