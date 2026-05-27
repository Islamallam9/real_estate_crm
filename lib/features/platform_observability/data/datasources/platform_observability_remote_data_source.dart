import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../../../core/errors/error_mapper.dart';
import '../../domain/entities/client_error_report.dart';
import '../../domain/entities/platform_error_log.dart';
import '../models/platform_error_log_model.dart';

abstract interface class PlatformObservabilityRemoteDataSource {
  Stream<List<PlatformErrorLogModel>> watchErrorLogs({int limit});

  Future<void> reportClientError(ClientErrorReport report);

  Future<void> markResolved({required String logId});
}

class FirebasePlatformObservabilityRemoteDataSource
    implements PlatformObservabilityRemoteDataSource {
  FirebasePlatformObservabilityRemoteDataSource({
    FirebaseFunctions? functions,
  }) : _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFunctions _functions;

  @override
  Stream<List<PlatformErrorLogModel>> watchErrorLogs({int limit = 160}) {
    return Stream.fromFuture(_loadErrorLogs(limit));
  }

  Future<List<PlatformErrorLogModel>> _loadErrorLogs(int limit) async {
    final data = await _callMap('listPlatformErrorLogs', {'limit': limit});
    final logs = data['logs'];
    if (logs is! List) {
      return const [];
    }

    return logs
        .whereType<Map>()
        .map(
          (entry) => PlatformErrorLogModel.fromMap(
            Map<String, dynamic>.from(entry),
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<void> reportClientError(ClientErrorReport report) async {
    await _call('reportClientError', {
      'companyId': report.companyId,
      'companyName': report.companyName,
      'userId': report.userId,
      'userEmail': report.userEmail,
      'userRole': report.userRole,
      'route': report.route,
      'module': report.module,
      'source': platformErrorSourceValue(report.source),
      'severity': platformErrorSeverityValue(report.severity),
      'message': report.message,
      'errorCode': report.errorCode,
      'stackHash': report.stackHash,
      'shortStack': report.shortStack,
      'appVersion': report.appVersion,
      'buildNumber': report.buildNumber,
      'platform': report.platform,
      'deviceType': report.deviceType,
      'userAgent': report.userAgent,
      'timezone': report.timezone,
      'metadata': report.metadata,
    });
  }

  @override
  Future<void> markResolved({required String logId}) {
    return _call('markPlatformErrorResolved', {'logId': logId});
  }

  Future<void> _call(String name, Map<String, Object?> data) async {
    await _callMap(name, data);
  }

  Future<Map<String, dynamic>> _callMap(
    String name,
    Map<String, Object?> data,
  ) async {
    try {
      final result = await _functions.httpsCallable(name).call(data);
      final value = result.data;
      if (value is Map<String, dynamic>) {
        return value;
      }
      if (value is Map) {
        return Map<String, dynamic>.from(value);
      }
      return const {};
    } on FirebaseFunctionsException catch (error) {
      throw error.message ?? AppErrorMessages.permissionDenied;
    } on FirebaseException catch (error) {
      throw _mapFirebaseError(error);
    }
  }
}

String _mapFirebaseError(Object error) {
  if (error is FirebaseException) {
    switch (error.code) {
      case 'unavailable':
      case 'network-request-failed':
      case 'deadline-exceeded':
        return AppErrorMessages.unableToConnect;
      case 'permission-denied':
      case 'unauthenticated':
        return AppErrorMessages.permissionDenied;
      default:
        return AppErrorMessages.unknown;
    }
  }
  return AppErrorMessages.unknown;
}
