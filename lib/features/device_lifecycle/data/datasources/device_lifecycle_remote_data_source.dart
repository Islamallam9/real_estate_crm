import 'dart:math';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/observability/device_metadata.dart';

abstract interface class DeviceLifecycleRemoteDataSource {
  Future<void> registerCompanyInstall({
    required String companyId,
    required String uid,
    required String role,
    required String locale,
    required String source,
  });

  Future<void> recordHeartbeat({
    required String companyId,
    required String uid,
    required String role,
    required String locale,
  });
}

class FirebaseDeviceLifecycleRemoteDataSource
    implements DeviceLifecycleRemoteDataSource {
  FirebaseDeviceLifecycleRemoteDataSource({FirebaseFunctions? functions})
      : _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFunctions _functions;

  @override
  Future<void> registerCompanyInstall({
    required String companyId,
    required String uid,
    required String role,
    required String locale,
    required String source,
  }) async {
    await _call('registerDeviceInstall', {
      ...await _payload(
        companyId: companyId,
        uid: uid,
        role: role,
        locale: locale,
      ),
      'source': source,
    });
  }

  @override
  Future<void> recordHeartbeat({
    required String companyId,
    required String uid,
    required String role,
    required String locale,
  }) async {
    await _call('recordAppSessionHeartbeat', await _payload(
      companyId: companyId,
      uid: uid,
      role: role,
      locale: locale,
    ));
  }

  Future<Map<String, Object?>> _payload({
    required String companyId,
    required String uid,
    required String role,
    required String locale,
  }) async {
    final installId = await _installId();
    final device = platformDeviceMetadata();
    return {
      'companyId': companyId,
      'uid': uid,
      'role': role,
      'locale': locale,
      'installId': installId,
      'platform': _platformName(),
      'appVersion': AppConstants.appVersion,
      'buildNumber': AppConstants.appBuildNumber,
      'timezone': DateTime.now().timeZoneName,
      'notificationPermission': 'unknown',
      'notificationTokenStatus': 'unknown',
      if ((device['userAgent'] ?? '').trim().isNotEmpty)
        'browser': _browserLabel(device['userAgent']!),
      if ((device['userAgent'] ?? '').trim().isNotEmpty)
        'os': _osLabel(device['userAgent']!),
      if ((device['userAgent'] ?? '').trim().isNotEmpty)
        'deviceModel': device['userAgent']!,
      ..._webLocationMetadata(),
    };
  }

  Future<String> _installId() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'masar_device_install_id_v1:${_platformIdentity()}';
    final existing = prefs.getString(key);
    if (existing != null && existing.length >= 20) {
      return existing;
    }
    final random = Random.secure();
    final bytes = List<int>.generate(24, (_) => random.nextInt(256));
    final id = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    await prefs.setString(key, id);
    return id;
  }

  Future<void> _call(String name, Map<String, Object?> data) async {
    await _functions.httpsCallable(name).call(data);
  }

  Map<String, Object?> _webLocationMetadata() {
    if (!kIsWeb) {
      return const {};
    }
    try {
      return {
        'webOrigin': Uri.base.origin,
        'webHref': Uri.base.toString(),
      };
    } catch (_) {
      return const {};
    }
  }

  String _platformIdentity() {
    if (!kIsWeb) {
      return _platformName();
    }
    try {
      final origin = Uri.base.origin.trim();
      if (origin.isNotEmpty) {
        return 'web:$origin';
      }
    } catch (_) {}
    return 'web';
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

  String _browserLabel(String userAgent) {
    final value = userAgent.toLowerCase();
    if (value.contains('edg/')) return 'Edge';
    if (value.contains('chrome/')) return 'Chrome';
    if (value.contains('firefox/')) return 'Firefox';
    if (value.contains('safari/') && !value.contains('chrome/')) return 'Safari';
    return '';
  }

  String _osLabel(String userAgent) {
    final value = userAgent.toLowerCase();
    if (value.contains('android')) return 'Android';
    if (value.contains('windows')) return 'Windows';
    if (value.contains('mac os')) return 'macOS';
    if (value.contains('iphone') || value.contains('ipad')) return 'iOS';
    if (value.contains('linux')) return 'Linux';
    return '';
  }
}
