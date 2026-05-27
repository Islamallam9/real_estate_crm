import 'package:equatable/equatable.dart';

import '../../domain/entities/platform_error_log.dart';

enum PlatformObservabilityStatus { initial, loading, ready, failure }

enum PlatformErrorResolvedFilter { all, unresolved, resolved }

enum PlatformErrorDateFilter { all, last24Hours, last7Days, last30Days }

class PlatformObservabilityState extends Equatable {
  const PlatformObservabilityState({
    required this.status,
    this.logs = const [],
    this.companyId = '',
    this.severity,
    this.source,
    this.module = '',
    this.resolvedFilter = PlatformErrorResolvedFilter.unresolved,
    this.dateFilter = PlatformErrorDateFilter.last7Days,
    this.resolvingLogId = '',
    this.message,
  });

  const PlatformObservabilityState.initial()
      : this(status: PlatformObservabilityStatus.initial);

  final PlatformObservabilityStatus status;
  final List<PlatformErrorLog> logs;
  final String companyId;
  final PlatformErrorSeverity? severity;
  final PlatformErrorSource? source;
  final String module;
  final PlatformErrorResolvedFilter resolvedFilter;
  final PlatformErrorDateFilter dateFilter;
  final String resolvingLogId;
  final String? message;

  List<String> get modules {
    final values = logs
        .map((log) => log.module.trim())
        .where((module) => module.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return values;
  }

  List<PlatformErrorLog> get filteredLogs {
    final cutoff = _cutoffFor(dateFilter);
    return logs.where((log) {
      if (companyId.isNotEmpty && log.companyId != companyId) {
        return false;
      }
      if (severity != null && log.severity != severity) {
        return false;
      }
      if (source != null && log.source != source) {
        return false;
      }
      if (module.isNotEmpty && log.module != module) {
        return false;
      }
      if (resolvedFilter == PlatformErrorResolvedFilter.unresolved &&
          log.resolved) {
        return false;
      }
      if (resolvedFilter == PlatformErrorResolvedFilter.resolved &&
          !log.resolved) {
        return false;
      }
      if (cutoff != null) {
        final lastSeen = log.lastSeenAt;
        if (lastSeen == null || lastSeen.isBefore(cutoff)) {
          return false;
        }
      }
      return true;
    }).toList(growable: false);
  }

  int get activeIncidentCount => logs.where((log) => !log.resolved).length;

  int get fatalErrorCount => logs
      .where((log) => !log.resolved && log.severity == PlatformErrorSeverity.fatal)
      .length;

  int get errorsTodayCount {
    final startOfDay = DateTime.now();
    final today = DateTime(startOfDay.year, startOfDay.month, startOfDay.day);
    return logs.where((log) {
      final lastSeen = log.lastSeenAt?.toLocal();
      if (lastSeen == null || lastSeen.isBefore(today)) {
        return false;
      }
      return log.severity == PlatformErrorSeverity.error ||
          log.severity == PlatformErrorSeverity.fatal;
    }).length;
  }

  int get affectedCompanyCount => logs
      .where((log) => !log.resolved && log.companyId.trim().isNotEmpty)
      .map((log) => log.companyId)
      .toSet()
      .length;

  PlatformObservabilityState copyWith({
    PlatformObservabilityStatus? status,
    List<PlatformErrorLog>? logs,
    String? companyId,
    PlatformErrorSeverity? severity,
    PlatformErrorSource? source,
    String? module,
    PlatformErrorResolvedFilter? resolvedFilter,
    PlatformErrorDateFilter? dateFilter,
    String? resolvingLogId,
    String? message,
    bool clearSeverity = false,
    bool clearSource = false,
    bool clearMessage = false,
    bool clearResolvingLogId = false,
  }) {
    return PlatformObservabilityState(
      status: status ?? this.status,
      logs: logs ?? this.logs,
      companyId: companyId ?? this.companyId,
      severity: clearSeverity ? null : severity ?? this.severity,
      source: clearSource ? null : source ?? this.source,
      module: module ?? this.module,
      resolvedFilter: resolvedFilter ?? this.resolvedFilter,
      dateFilter: dateFilter ?? this.dateFilter,
      resolvingLogId:
          clearResolvingLogId ? '' : resolvingLogId ?? this.resolvingLogId,
      message: clearMessage ? null : message ?? this.message,
    );
  }

  @override
  List<Object?> get props => [
        status,
        logs,
        companyId,
        severity,
        source,
        module,
        resolvedFilter,
        dateFilter,
        resolvingLogId,
        message,
      ];
}

DateTime? _cutoffFor(PlatformErrorDateFilter filter) {
  final now = DateTime.now();
  return switch (filter) {
    PlatformErrorDateFilter.all => null,
    PlatformErrorDateFilter.last24Hours => now.subtract(const Duration(days: 1)),
    PlatformErrorDateFilter.last7Days => now.subtract(const Duration(days: 7)),
    PlatformErrorDateFilter.last30Days => now.subtract(const Duration(days: 30)),
  };
}
