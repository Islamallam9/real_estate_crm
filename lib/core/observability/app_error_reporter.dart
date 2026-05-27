import 'dart:async';
import 'dart:ui';

import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';

import '../../features/platform_observability/domain/entities/client_error_report.dart';
import '../../features/platform_observability/domain/entities/platform_error_log.dart';
import '../../features/platform_observability/domain/usecases/report_client_error_usecase.dart';
import '../constants/app_constants.dart';
import 'device_metadata.dart';

class MasarObservabilityContext {
  const MasarObservabilityContext({
    this.companyId = '',
    this.companyName = '',
    this.userId = '',
    this.userEmail = '',
    this.userRole = '',
    this.route = '',
  });

  final String companyId;
  final String companyName;
  final String userId;
  final String userEmail;
  final String userRole;
  final String route;
}

class MasarObservabilityReporter {
  MasarObservabilityReporter._();

  static final MasarObservabilityReporter instance =
      MasarObservabilityReporter._();

  ReportClientErrorUseCase? _reportClientErrorUseCase;
  MasarObservabilityContext Function()? _contextProvider;
  bool _handlersInstalled = false;
  bool _isReporting = false;
  final Map<String, _ErrorBucket> _buckets = {};

  void configure({
    required ReportClientErrorUseCase reportClientErrorUseCase,
    required MasarObservabilityContext Function() contextProvider,
  }) {
    _reportClientErrorUseCase = reportClientErrorUseCase;
    _contextProvider = contextProvider;
  }

  void installGlobalErrorHandlers() {
    if (_handlersInstalled) {
      return;
    }
    _handlersInstalled = true;
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      unawaited(reportFlutterError(details));
    };
    PlatformDispatcher.instance.onError = (error, stackTrace) {
      unawaited(
        reportUnhandledError(
          error,
          stackTrace,
          module: 'runtime',
          fatal: true,
        ),
      );
      return false;
    };
  }

  Future<void> reportFlutterError(FlutterErrorDetails details) {
    return _reportError(
      details.exception,
      details.stack,
      module: 'flutter',
      fatal: false,
      metadata: {
        'library': details.library ?? '',
        'context': details.context?.toDescription() ?? '',
        'silent': details.silent,
      },
    );
  }

  Future<void> reportUnhandledError(
    Object error,
    StackTrace stackTrace, {
    String module = 'runtime',
    bool fatal = true,
  }) {
    return _reportError(
      error,
      stackTrace,
      module: module,
      fatal: fatal,
    );
  }

  Future<void> reportBlocError({
    required BlocBase<dynamic> bloc,
    required Object error,
    required StackTrace stackTrace,
  }) {
    return _reportError(
      error,
      stackTrace,
      module: bloc.runtimeType.toString(),
      fatal: false,
      metadata: {
        'bloc': bloc.runtimeType.toString(),
      },
    );
  }

  Future<void> _reportError(
    Object error,
    StackTrace? stackTrace, {
    required String module,
    required bool fatal,
    Map<String, Object?> metadata = const {},
  }) async {
    final useCase = _reportClientErrorUseCase;
    if (useCase == null || _isReporting) {
      return;
    }

    final context = _safeContext();
    final message = _sanitizeText('${error.runtimeType}: $error', 500);
    final shortStack = _shortStack(stackTrace);
    final stackHash = _hashText('$message\n$shortStack');
    final fingerprint = _hashText('${context.route}|$module|$stackHash');
    final bucket = _buckets.update(
      fingerprint,
      (value) => value.next(),
      ifAbsent: () => _ErrorBucket.first(),
    );

    final lowerMessage = message.toLowerCase();
    final isPermissionIssue = lowerMessage.contains('permission-denied') ||
        lowerMessage.contains('permission denied');
    final isNetworkIssue = lowerMessage.contains('network') ||
        lowerMessage.contains('unavailable') ||
        lowerMessage.contains('deadline-exceeded') ||
        lowerMessage.contains('timeout');
    final threshold = fatal
        ? 1
        : isNetworkIssue
            ? 5
            : 3;
    if (bucket.count < threshold) {
      return;
    }
    if (bucket.lastReportedAt != null &&
        DateTime.now().difference(bucket.lastReportedAt!) <
            const Duration(minutes: 5)) {
      return;
    }
    _buckets[fingerprint] = bucket.markReported();

    final severity = fatal
        ? PlatformErrorSeverity.fatal
        : isPermissionIssue || isNetworkIssue
            ? PlatformErrorSeverity.warning
            : PlatformErrorSeverity.error;

    final device = _deviceMetadata();
    final report = ClientErrorReport(
      companyId: context.companyId,
      companyName: context.companyName,
      userId: context.userId,
      userEmail: context.userEmail,
      userRole: context.userRole,
      route: context.route,
      module: _sanitizeText(module, 80),
      source: kIsWeb
          ? PlatformErrorSource.flutterWeb
          : PlatformErrorSource.flutterMobile,
      severity: severity,
      message: message,
      errorCode: _errorCodeFromMessage(message),
      stackHash: stackHash,
      shortStack: shortStack,
      appVersion: AppConstants.appVersion,
      buildNumber: AppConstants.appBuildNumber,
      platform: defaultTargetPlatform.name,
      deviceType: kIsWeb ? 'web' : defaultTargetPlatform.name,
      userAgent: _sanitizeText(device['userAgent'] ?? '', 600),
      timezone: DateTime.now().timeZoneName,
      metadata: {
        ..._sanitizeMetadata(metadata),
        'errorType': error.runtimeType.toString(),
        'repeatCount': bucket.count,
      },
    );

    _isReporting = true;
    try {
      await useCase(report);
    } catch (_) {
      // Observability must never break the user-facing workflow.
    } finally {
      _isReporting = false;
    }
  }

  MasarObservabilityContext _safeContext() {
    try {
      return _contextProvider?.call() ?? const MasarObservabilityContext();
    } catch (_) {
      return const MasarObservabilityContext();
    }
  }

  Map<String, String> _deviceMetadata() {
    try {
      return platformDeviceMetadata();
    } catch (_) {
      return const {'userAgent': ''};
    }
  }
}

class MasarBlocObserver extends BlocObserver {
  const MasarBlocObserver(this._reporter);

  final MasarObservabilityReporter _reporter;

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    unawaited(
      _reporter.reportBlocError(
        bloc: bloc,
        error: error,
        stackTrace: stackTrace,
      ),
    );
    super.onError(bloc, error, stackTrace);
  }
}

class _ErrorBucket {
  const _ErrorBucket({required this.count, this.lastReportedAt});

  factory _ErrorBucket.first() {
    return const _ErrorBucket(count: 1);
  }

  final int count;
  final DateTime? lastReportedAt;

  _ErrorBucket next() {
    return _ErrorBucket(count: count + 1, lastReportedAt: lastReportedAt);
  }

  _ErrorBucket markReported() {
    return _ErrorBucket(count: count, lastReportedAt: DateTime.now());
  }
}

String _shortStack(StackTrace? stackTrace) {
  final source = stackTrace?.toString() ?? '';
  if (source.isEmpty) {
    return '';
  }
  return _sanitizeText(source.split('\n').take(18).join('\n'), 1800);
}

String _sanitizeText(String value, int maxLength) {
  var clean = value.trim();
  clean = clean.replaceAll(RegExp(r'[<>]'), '');
  clean = clean.replaceAllMapped(
    RegExp(
      r'(password|token|secret|reset[_-]?link|invitation[_-]?code)\s*[:=]\s*[^\s,;]+',
      caseSensitive: false,
    ),
    (match) => '${match.group(1) ?? 'secret'}=[redacted]',
  );
  clean = clean.replaceAll(
    RegExp(
      r'(https?://[^\s]+(?:token|secret|signature|alt=media)[^\s]*)',
      caseSensitive: false,
    ),
    '[redacted-url]',
  );
  if (clean.length <= maxLength) {
    return clean;
  }
  return clean.substring(0, maxLength);
}

Map<String, Object?> _sanitizeMetadata(Map<String, Object?> metadata) {
  final clean = <String, Object?>{};
  for (final entry in metadata.entries) {
    final key = _sanitizeText(entry.key, 80);
    if (key.isEmpty) {
      continue;
    }
    final value = entry.value;
    if (value is String) {
      clean[key] = _sanitizeText(value, 240);
    } else if (value is num || value is bool || value == null) {
      clean[key] = value;
    }
  }
  return clean;
}

String _hashText(String value) {
  var hash = 0x811c9dc5;
  for (final unit in value.codeUnits) {
    hash ^= unit;
    hash = (hash * 0x01000193) & 0xffffffff;
  }
  return hash.toRadixString(16).padLeft(8, '0');
}

String _errorCodeFromMessage(String message) {
  final codeMatch = RegExp(r'\[(.*?)\]').firstMatch(message);
  if (codeMatch != null) {
    return _sanitizeText(codeMatch.group(1) ?? '', 80);
  }
  if (message.toLowerCase().contains('permission-denied')) {
    return 'permission-denied';
  }
  return '';
}
