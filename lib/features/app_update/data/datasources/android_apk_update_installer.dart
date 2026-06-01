import 'package:flutter/services.dart';

class AndroidApkUpdateInstaller {
  AndroidApkUpdateInstaller({MethodChannel? channel})
      : _channel = channel ?? const MethodChannel('masarcrm/android_apk_updater');

  final MethodChannel _channel;

  Future<int> startDownload({
    required String url,
    required String fileName,
  }) async {
    final result = await _channel.invokeMethod<int>('startApkDownload', {
      'url': url,
      'fileName': fileName,
    });
    if (result == null || result <= 0) {
      throw PlatformException(
        code: 'download_not_started',
        message: 'The update download could not be started.',
      );
    }
    return result;
  }

  Future<AndroidApkDownloadStatus> getStatus(int downloadId) async {
    final result = await _channel.invokeMapMethod<String, Object?>(
      'getApkDownloadStatus',
      {'downloadId': downloadId},
    );
    return AndroidApkDownloadStatus.fromMap(result ?? const {});
  }

  Future<void> installDownloadedApk(int downloadId) async {
    await _channel.invokeMethod<void>('installDownloadedApk', {
      'downloadId': downloadId,
    });
  }
}

class AndroidApkDownloadStatus {
  const AndroidApkDownloadStatus({
    required this.status,
    required this.bytesDownloaded,
    required this.totalBytes,
    this.reason,
  });

  final String status;
  final int bytesDownloaded;
  final int totalBytes;
  final String? reason;

  bool get isPending => status == 'pending';
  bool get isRunning => status == 'running';
  bool get isPaused => status == 'paused';
  bool get isSuccessful => status == 'successful';
  bool get isFailed => status == 'failed';
  bool get isInvalidApk =>
      reason == 'invalid_apk_too_small' ||
      reason == 'invalid_apk_content' ||
      reason == 'missing_apk_file';

  double? get progress {
    if (totalBytes <= 0) return null;
    return (bytesDownloaded / totalBytes).clamp(0.0, 1.0).toDouble();
  }

  static AndroidApkDownloadStatus fromMap(Map<String, Object?> map) {
    return AndroidApkDownloadStatus(
      status: (map['status'] as String? ?? 'unknown').trim(),
      bytesDownloaded: _intValue(map['bytesDownloaded']),
      totalBytes: _intValue(map['totalBytes']),
      reason: map['reason']?.toString(),
    );
  }

  static int _intValue(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
