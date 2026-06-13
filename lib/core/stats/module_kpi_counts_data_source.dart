import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../archive/archive_filter.dart';
import '../constants/firebase_paths.dart';
import '../constants/role_constants.dart';

class ModuleKpiCounts {
  const ModuleKpiCounts(
    this.values, {
    this.failedKeys = const <String>{},
  });

  const ModuleKpiCounts.empty()
      : values = const <String, int>{},
        failedKeys = const <String>{};

  final Map<String, int> values;
  final Set<String> failedKeys;

  int value(String key, {int fallback = 0}) => values[key] ?? fallback;

  int? valueOrNull(String key) => values[key];

  String display(
    String key, {
    String unavailableLabel = '--',
    String? failureLabel,
  }) {
    if (values.containsKey(key)) {
      return (values[key] ?? 0).toString();
    }
    if (failedKeys.contains(key)) {
      return failureLabel ?? unavailableLabel;
    }
    return '…';
  }

  bool hasValue(String key) => values.containsKey(key);

  bool hasFailed(String key) => failedKeys.contains(key);

  bool hasAll(Iterable<String> keys) =>
      keys.every((key) => values.containsKey(key) || failedKeys.contains(key));

  bool get hasFailures => failedKeys.isNotEmpty;

  bool get isEmpty => values.isEmpty;
}

void debugCheckModuleKpiInvariant({
  required String module,
  required int loadedRows,
  required int? totalCount,
  required bool hasLocalFilters,
  required String scopeLabel,
}) {
  return;
}

class _CountDiagnostics {
  const _CountDiagnostics({
    required this.module,
    required this.collectionPath,
    required this.companyIdPresent,
    required this.roleScope,
    required this.archiveScope,
  });

  final String module;
  final String collectionPath;
  final bool companyIdPresent;
  final String roleScope;
  final String archiveScope;
}

class _ModuleKpiCountsCacheEntry {
  const _ModuleKpiCountsCacheEntry({
    required this.counts,
    required this.createdAt,
  });

  final ModuleKpiCounts counts;
  final DateTime createdAt;
}

class FirestoreModuleKpiCountsDataSource {
  FirestoreModuleKpiCountsDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  static const int _stuckDealDays = 14;
  static const int _leadFollowUpScanLimit = 1000;
  static const Duration _kpiCountsCacheTtl = Duration(seconds: 30);
  static final Set<String> _reportedCountFailures = <String>{};
  static final Map<String, _ModuleKpiCountsCacheEntry> _kpiCountsCache =
      <String, _ModuleKpiCountsCacheEntry>{};

  Future<ModuleKpiCounts> leadCounts({
    required String companyId,
    String? assignedTo,
    String? managerId,
    String? teamId,
    ArchiveFilter archiveFilter = ArchiveFilter.active,
    bool bypassCache = false,
  }) async {
    final collectionPath = FirebasePaths.companyLeads(companyId);
    final diagnostics = _CountDiagnostics(
      module: 'leads',
      collectionPath: collectionPath,
      companyIdPresent: companyId.trim().isNotEmpty,
      roleScope: _peopleScopeLabel(
        assignedTo: assignedTo,
        managerId: managerId,
        teamId: teamId,
      ),
      archiveScope: archiveFilter.name,
    );
    final now = DateTime.now();
    final cacheKey = _kpiCountsCacheKey(
      module: 'leads',
      companyId: companyId,
      assignedTo: assignedTo,
      managerId: managerId,
      teamId: teamId,
      archiveFilter: archiveFilter,
      dateBucket: _dateCacheBucket(now),
    );
    if (!bypassCache) {
      final cachedCounts = _readKpiCountsCache(
        cacheKey: cacheKey,
        label: 'leads.kpiCache',
        diagnostics: diagnostics,
      );
      if (cachedCounts != null) {
        return cachedCounts;
      }
    }

    ModuleKpiCounts cacheResult(ModuleKpiCounts counts) {
      _writeKpiCountsCache(
        cacheKey: cacheKey,
        counts: counts,
        label: 'leads.kpiCache',
        diagnostics: diagnostics,
      );
      return counts;
    }

    final activeStatuses = <String>[
      'new',
      'contacted',
      'interested',
      'visitScheduled',
      'negotiation',
    ];
    final startToday = _startOfDay(now);
    final startTomorrow = startToday.add(const Duration(days: 1));
    final base = _applyPeopleScope(
      _applyArchive(
        _firestore.collection(collectionPath),
        archiveFilter,
      ),
      assignedTo: assignedTo,
      managerId: managerId,
      teamId: teamId,
    );
    final scopedFallback = !_isBlank(assignedTo) ||
        !_isBlank(managerId) ||
        !_isBlank(teamId);
    final values = <String, int>{};
    final failedKeys = <String>{};

    final countQueryCounts = await _safeLeadCountQueryCounts(
      base,
      activeStatuses: activeStatuses,
      today: startToday,
      tomorrow: startTomorrow,
      includeUnassigned: _isBlank(assignedTo),
      diagnostics: diagnostics,
    );
    if (countQueryCounts != null) {
      values.addAll(countQueryCounts);
      return cacheResult(ModuleKpiCounts(values, failedKeys: failedKeys));
    }

    if (scopedFallback) {
      final snapshotCounts = await _safeLeadSnapshotCounts(
        base,
        activeStatuses: activeStatuses,
        today: startToday,
        tomorrow: startTomorrow,
        includeUnassigned: _isBlank(assignedTo),
        diagnostics: diagnostics,
      );
      if (snapshotCounts == null) {
        values.addAll(const <String, int>{
          'total': 0,
          'new': 0,
          'active': 0,
          'overdue': 0,
          'upcoming': 0,
          'unassigned': 0,
        });
      } else {
        values.addAll(snapshotCounts);
      }
      return cacheResult(ModuleKpiCounts(values, failedKeys: failedKeys));
    }

    final activeBase = base.where('status', whereIn: activeStatuses);
    final unassignedFuture = _isBlank(assignedTo)
        ? _safeBlankOrNullStringCount(
            base,
            field: 'assignedTo',
            label: 'leads.unassigned',
            diagnostics: diagnostics,
          )
        : Future<int?>.value(0);
    final results = await Future.wait<int?>([
      _safeCount(base, label: 'leads.total', diagnostics: diagnostics),
      _safeCount(
        base.where('status', isEqualTo: 'new'),
        label: 'leads.new',
        diagnostics: diagnostics,
      ),
      _safeCount(activeBase, label: 'leads.active', diagnostics: diagnostics),
      _safeLeadFollowUpSnapshotCount(
        base,
        activeStatuses: activeStatuses,
        isLessThan: Timestamp.fromDate(startToday),
        label: 'leads.overdue',
        diagnostics: diagnostics,
      ),
      _safeLeadFollowUpSnapshotCount(
        base,
        activeStatuses: activeStatuses,
        isGreaterThanOrEqualTo: Timestamp.fromDate(startTomorrow),
        label: 'leads.upcoming',
        diagnostics: diagnostics,
      ),
      unassignedFuture,
    ]);
    _putCount(values, failedKeys, 'total', results[0]);
    _putCount(values, failedKeys, 'new', results[1]);
    _putCount(values, failedKeys, 'active', results[2]);
    _putCount(values, failedKeys, 'overdue', results[3]);
    _putCount(values, failedKeys, 'upcoming', results[4]);
    _putCount(values, failedKeys, 'unassigned', results[5]);
    return cacheResult(ModuleKpiCounts(values, failedKeys: failedKeys));
  }

  Future<ModuleKpiCounts> taskCounts({
    required String companyId,
    String? assignedTo,
    String? managerId,
    String? teamId,
  }) async {
    final collectionPath = FirebasePaths.companyTasks(companyId);
    final diagnostics = _CountDiagnostics(
      module: 'tasks',
      collectionPath: collectionPath,
      companyIdPresent: companyId.trim().isNotEmpty,
      roleScope: _peopleScopeLabel(
        assignedTo: assignedTo,
        managerId: managerId,
        teamId: teamId,
      ),
      archiveScope: 'activeOnly',
    );
    final today = _startOfDay(DateTime.now());
    final base = _applyPeopleScope(
      _firestore.collection(collectionPath).where('isActive', isEqualTo: true),
      assignedTo: assignedTo,
      managerId: managerId,
      teamId: teamId,
    );
    final scopedFallback = !_isBlank(assignedTo) ||
        !_isBlank(managerId) ||
        !_isBlank(teamId);
    final values = <String, int>{};
    final failedKeys = <String>{};

    final countQueryCounts = await _safeTaskCountQueryCounts(
      base,
      today: today,
      diagnostics: diagnostics,
    );
    if (countQueryCounts != null) {
      values.addAll(countQueryCounts);
      return ModuleKpiCounts(values, failedKeys: failedKeys);
    }

    if (scopedFallback) {
      final snapshotCounts = await _safeTaskSnapshotCounts(
        base,
        today: today,
        diagnostics: diagnostics,
        useOrderedSnapshot: false,
      );
      if (snapshotCounts == null) {
        values.addAll(const <String, int>{
          'total': 0,
          'overdue': 0,
          'today': 0,
          'upcoming': 0,
          'completed': 0,
          'cancelled': 0,
        });
      } else {
        values.addAll(snapshotCounts);
      }
      return ModuleKpiCounts(values, failedKeys: failedKeys);
    }

    final total = await _safeCount(
      base,
      label: 'tasks.total',
      diagnostics: diagnostics,
    );
    final snapshotCounts = await _safeTaskSnapshotCounts(
      base,
      today: today,
      diagnostics: diagnostics,
    );
    _putCount(values, failedKeys, 'total', total);
    if (snapshotCounts == null) {
      failedKeys.addAll(const <String>[
        'overdue',
        'today',
        'upcoming',
        'completed',
        'cancelled',
      ]);
    } else {
      values.addAll(Map<String, int>.of(snapshotCounts)..remove('total'));
    }
    return ModuleKpiCounts(values, failedKeys: failedKeys);
  }

  Future<ModuleKpiCounts> appointmentCounts({
    required String companyId,
    String? assignedTo,
    String? managerId,
    String? teamId,
    DateTime? rangeStart,
    DateTime? rangeEnd,
  }) async {
    final collectionPath = FirebasePaths.companyAppointments(companyId);
    final diagnostics = _CountDiagnostics(
      module: 'appointments',
      collectionPath: collectionPath,
      companyIdPresent: companyId.trim().isNotEmpty,
      roleScope: _peopleScopeLabel(
        assignedTo: assignedTo,
        managerId: managerId,
        teamId: teamId,
      ),
      archiveScope: 'all',
    );
    final now = DateTime.now();
    final today = _startOfDay(now);
    final tomorrow = today.add(const Duration(days: 1));
    final scopedBase = _applyPeopleScope(
      _firestore.collection(collectionPath),
      assignedTo: assignedTo,
      managerId: managerId,
      teamId: teamId,
    );
    final scopedFallback = !_isBlank(assignedTo) ||
        !_isBlank(managerId) ||
        !_isBlank(teamId);
    final values = <String, int>{};
    final failedKeys = <String>{};

    if (scopedFallback) {
      final snapshotCounts = await _safeAppointmentSnapshotCounts(
        scopedBase,
        now: now,
        today: today,
        tomorrow: tomorrow,
        rangeStart: rangeStart,
        rangeEnd: rangeEnd,
        diagnostics: diagnostics,
      );
      if (snapshotCounts == null) {
        values.addAll(const <String, int>{
          'total': 0,
          'listTotal': 0,
          'today': 0,
          'upcoming': 0,
          'missed': 0,
          'completed': 0,
          'cancelled': 0,
        });
      } else {
        values.addAll(snapshotCounts);
      }
      return ModuleKpiCounts(values, failedKeys: failedKeys);
    }

    if (rangeStart != null || rangeEnd != null) {
      final snapshotCounts = await _safeAppointmentSnapshotCounts(
        scopedBase,
        now: now,
        today: today,
        tomorrow: tomorrow,
        rangeStart: rangeStart,
        rangeEnd: rangeEnd,
        diagnostics: diagnostics,
      );
      if (snapshotCounts != null) {
        return ModuleKpiCounts(snapshotCounts, failedKeys: failedKeys);
      }
    }

    Query<Map<String, dynamic>> listBase = scopedBase;
    if (rangeStart != null) {
      listBase = listBase.where(
        'scheduledAt',
        isGreaterThanOrEqualTo: Timestamp.fromDate(rangeStart),
      );
    }
    if (rangeEnd != null) {
      listBase = listBase.where(
        'scheduledAt',
        isLessThan: Timestamp.fromDate(rangeEnd),
      );
    }
    final results = await Future.wait<int?>([
      _safeCount(
        scopedBase,
        label: 'appointments.total',
        diagnostics: diagnostics,
      ),
      _safeCount(
        listBase,
        label: 'appointments.listTotal',
        diagnostics: diagnostics,
      ),
      _safeCount(
        _rangeQuery(
          scopedBase,
          'scheduledAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(today),
          isLessThan: Timestamp.fromDate(tomorrow),
        ),
        label: 'appointments.today',
        diagnostics: diagnostics,
      ),
      _safeStatusRangeCount(
        scopedBase,
        statusField: 'status',
        statuses: const <String>['scheduled', 'rescheduled'],
        rangeField: 'scheduledAt',
        isGreaterThanOrEqualTo: Timestamp.fromDate(now),
        label: 'appointments.upcoming',
        diagnostics: diagnostics,
      ),
      _safeAppointmentMissedCount(
        scopedBase,
        now: now,
        diagnostics: diagnostics,
      ),
      _safeCount(
        scopedBase.where('status', isEqualTo: 'completed'),
        label: 'appointments.completed',
        diagnostics: diagnostics,
      ),
      _safeCount(
        scopedBase.where('status', isEqualTo: 'cancelled'),
        label: 'appointments.cancelled',
        diagnostics: diagnostics,
      ),
    ]);
    _putCount(values, failedKeys, 'total', results[0]);
    _putCount(values, failedKeys, 'listTotal', results[1]);
    _putCount(values, failedKeys, 'today', results[2]);
    _putCount(values, failedKeys, 'upcoming', results[3]);
    _putCount(values, failedKeys, 'missed', results[4]);
    _putCount(values, failedKeys, 'completed', results[5]);
    _putCount(values, failedKeys, 'cancelled', results[6]);
    return ModuleKpiCounts(values, failedKeys: failedKeys);
  }

  Future<ModuleKpiCounts> dealCounts({
    required String companyId,
    required UserRole role,
    required String currentUserId,
    String? teamId,
    ArchiveFilter archiveFilter = ArchiveFilter.active,
  }) async {
    final now = DateTime.now();
    final today = _startOfDay(now);
    final tomorrow = today.add(const Duration(days: 1));
    final startMonth = DateTime(now.year, now.month);
    final nextMonth = DateTime(now.year, now.month + 1);
    final staleExclusiveEnd =
        today.subtract(Duration(days: _stuckDealDays - 1));
    final collectionPath = FirebasePaths.companyDeals(companyId);
    final diagnostics = _CountDiagnostics(
      module: 'deals',
      collectionPath: collectionPath,
      companyIdPresent: companyId.trim().isNotEmpty,
      roleScope: _dealScopeLabel(
        role: role,
        teamId: teamId,
      ),
      archiveScope: archiveFilter.name,
    );
    final openStages = const <String>['new', 'qualified', 'proposal', 'negotiation'];
    final base = _applyDealScope(
      _applyArchive(
        _firestore.collection(collectionPath),
        archiveFilter,
        activeField: 'isActive',
      ),
      role: role,
      currentUserId: currentUserId,
      teamId: teamId,
    );
    final scopedFallback = role == UserRole.manager ||
        role == UserRole.salesAgent ||
        role == UserRole.marketing ||
        role == UserRole.viewer;
    if (scopedFallback) {
      final values = <String, int>{};
      final failedKeys = <String>{};
      final snapshotCounts = await _safeDealSnapshotCounts(
        base,
        tomorrow: tomorrow,
        startMonth: startMonth,
        nextMonth: nextMonth,
        staleExclusiveEnd: staleExclusiveEnd,
        openStages: openStages,
        diagnostics: diagnostics,
        useOrderedSnapshot: false,
      );
      if (snapshotCounts == null) {
        values.addAll(const <String, int>{
          'total': 0,
          'open': 0,
          'atRisk': 0,
          'wonThisMonth': 0,
          'lost': 0,
        });
      } else {
        values.addAll(snapshotCounts);
      }
      return ModuleKpiCounts(values, failedKeys: failedKeys);
    }

    final openBase = base.where('stage', whereIn: openStages);
    final atRiskQuery = openBase.where(
      Filter.or(
        Filter('closingDate', isLessThan: Timestamp.fromDate(tomorrow)),
        Filter('updatedAt', isLessThan: Timestamp.fromDate(staleExclusiveEnd)),
        Filter.and(
          Filter('updatedAt', isNull: true),
          Filter(
            'createdAt',
            isLessThan: Timestamp.fromDate(staleExclusiveEnd),
          ),
        ),
      ),
    );
    final results = await Future.wait<int?>([
      _safeCount(base, label: 'deals.total', diagnostics: diagnostics),
      _safeCount(openBase, label: 'deals.open', diagnostics: diagnostics),
      _safeCount(atRiskQuery, label: 'deals.atRisk', diagnostics: diagnostics),
      _safeCount(
        _rangeQuery(
          base.where('stage', isEqualTo: 'won'),
          'updatedAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startMonth),
          isLessThan: Timestamp.fromDate(nextMonth),
        ),
        label: 'deals.wonThisMonth',
        diagnostics: diagnostics,
      ),
      _safeCount(
        base.where('stage', isEqualTo: 'lost'),
        label: 'deals.lost',
        diagnostics: diagnostics,
      ),
    ]);
    final values = <String, int>{};
    final failedKeys = <String>{};
    if (results.any((value) => value == null)) {
      final snapshotCounts = await _safeDealSnapshotCounts(
        base,
        tomorrow: tomorrow,
        startMonth: startMonth,
        nextMonth: nextMonth,
        staleExclusiveEnd: staleExclusiveEnd,
        openStages: openStages,
        diagnostics: diagnostics,
      );
      if (snapshotCounts != null) {
        values.addAll(snapshotCounts);
        return ModuleKpiCounts(values, failedKeys: failedKeys);
      }
    }
    _putCount(values, failedKeys, 'total', results[0]);
    _putCount(values, failedKeys, 'open', results[1]);
    _putCount(values, failedKeys, 'atRisk', results[2]);
    _putCount(values, failedKeys, 'wonThisMonth', results[3]);
    _putCount(values, failedKeys, 'lost', results[4]);
    return ModuleKpiCounts(values, failedKeys: failedKeys);
  }

  Future<ModuleKpiCounts> clientCounts({
    required String companyId,
    String? assignedTo,
    String? managerId,
    String? teamId,
    ArchiveFilter archiveFilter = ArchiveFilter.active,
    bool bypassCache = false,
  }) async {
    final collectionPath = FirebasePaths.companyClients(companyId);
    final diagnostics = _CountDiagnostics(
      module: 'clients',
      collectionPath: collectionPath,
      companyIdPresent: companyId.trim().isNotEmpty,
      roleScope: _peopleScopeLabel(
        assignedTo: assignedTo,
        managerId: managerId,
        teamId: teamId,
      ),
      archiveScope: archiveFilter.name,
    );
    final cacheKey = _kpiCountsCacheKey(
      module: 'clients',
      companyId: companyId,
      assignedTo: assignedTo,
      managerId: managerId,
      teamId: teamId,
      archiveFilter: archiveFilter,
    );
    if (!bypassCache) {
      final cachedCounts = _readKpiCountsCache(
        cacheKey: cacheKey,
        label: 'clients.kpiCache',
        diagnostics: diagnostics,
      );
      if (cachedCounts != null) {
        return cachedCounts;
      }
    }

    ModuleKpiCounts cacheResult(ModuleKpiCounts counts) {
      _writeKpiCountsCache(
        cacheKey: cacheKey,
        counts: counts,
        label: 'clients.kpiCache',
        diagnostics: diagnostics,
      );
      return counts;
    }

    final base = _applyPeopleScope(
      _applyArchive(
        _firestore.collection(collectionPath),
        archiveFilter,
        activeField: 'isActive',
      ),
      assignedTo: assignedTo,
      managerId: managerId,
      teamId: teamId,
    );
    final includeUnassigned = _isBlank(assignedTo);
    final scopedFallback = !_isBlank(assignedTo) ||
        !_isBlank(managerId) ||
        !_isBlank(teamId);
    final values = <String, int>{};
    final failedKeys = <String>{};

    final countQueryCounts = await _safeClientCountQueryCounts(
      base,
      includeUnassigned: includeUnassigned,
      diagnostics: diagnostics,
    );
    if (countQueryCounts != null) {
      values.addAll(countQueryCounts);
      return cacheResult(ModuleKpiCounts(values, failedKeys: failedKeys));
    }

    final snapshotCounts = await _safeClientSnapshotCounts(
      base,
      includeUnassigned: includeUnassigned,
      diagnostics: diagnostics,
      useOrderedSnapshot: !scopedFallback,
    );
    if (snapshotCounts == null) {
      if (scopedFallback) {
        values.addAll(const <String, int>{
          'total': 0,
          'assigned': 0,
          'unassigned': 0,
        });
        return cacheResult(ModuleKpiCounts(values, failedKeys: failedKeys));
      }
      failedKeys.addAll(const <String>['total', 'assigned', 'unassigned']);
      return cacheResult(ModuleKpiCounts(values, failedKeys: failedKeys));
    }
    values.addAll(snapshotCounts);
    return cacheResult(ModuleKpiCounts(values, failedKeys: failedKeys));
  }
  Future<ModuleKpiCounts> propertyCounts({required String companyId}) async {
    final collectionPath = FirebasePaths.companyProperties(companyId);
    final diagnostics = _CountDiagnostics(
      module: 'properties',
      collectionPath: collectionPath,
      companyIdPresent: companyId.trim().isNotEmpty,
      roleScope: 'company',
      archiveScope: 'matchesGridScope',
    );
    final base = _firestore.collection(collectionPath);
    final results = await Future.wait<int?>([
      _safeCount(base, label: 'properties.total', diagnostics: diagnostics),
      _safeCount(
        base.where('status', isEqualTo: 'available'),
        label: 'properties.available',
        diagnostics: diagnostics,
      ),
      _safeCount(
        base.where('status', isEqualTo: 'reserved'),
        label: 'properties.reserved',
        diagnostics: diagnostics,
      ),
      _safeCount(
        base.where('status', isEqualTo: 'sold'),
        label: 'properties.sold',
        diagnostics: diagnostics,
      ),
      _safeCount(
        base.where('status', isEqualTo: 'rented'),
        label: 'properties.rented',
        diagnostics: diagnostics,
      ),
    ]);
    final values = <String, int>{};
    final failedKeys = <String>{};
    if (results.any((value) => value == null)) {
      final snapshotCounts = await _safePropertySnapshotCounts(
        base,
        diagnostics: diagnostics,
      );
      if (snapshotCounts != null) {
        values.addAll(snapshotCounts);
        return ModuleKpiCounts(values, failedKeys: failedKeys);
      }
      values.addAll(const <String, int>{
        'total': 0,
        'available': 0,
        'reserved': 0,
        'sold': 0,
        'rented': 0,
      });
      return ModuleKpiCounts(values, failedKeys: failedKeys);
    }
    _putCount(values, failedKeys, 'total', results[0]);
    _putCount(values, failedKeys, 'available', results[1]);
    _putCount(values, failedKeys, 'reserved', results[2]);
    _putCount(values, failedKeys, 'sold', results[3]);
    _putCount(values, failedKeys, 'rented', results[4]);
    return ModuleKpiCounts(values, failedKeys: failedKeys);
  }


  Future<Map<String, int>?> _safePropertySnapshotCounts(
    Query<Map<String, dynamic>> base, {
    _CountDiagnostics? diagnostics,
  }) async {
    const scanLimit = 1000;
    final query = base.limit(scanLimit);
    final snapshot = await _safeSnapshotScan(
      query,
      label: 'properties.snapshotScan',
      diagnostics: diagnostics,
    );
    if (snapshot == null) {
      return null;
    }
    final counts = <String, int>{
      'total': 0,
      'available': 0,
      'reserved': 0,
      'sold': 0,
      'rented': 0,
    };
    for (final document in snapshot.docs) {
      final data = document.data();
      counts['total'] = (counts['total'] ?? 0) + 1;
      final rawStatus = data['status'];
      final status = rawStatus is String ? rawStatus.trim() : '';
      if (counts.containsKey(status)) {
        counts[status] = (counts[status] ?? 0) + 1;
      }
    }
    return counts;
  }

  Future<int?> notificationTotal({
    required String companyId,
    required String recipientUid,
  }) {
    final collectionPath = FirebasePaths.companyNotifications(companyId);
    final diagnostics = _CountDiagnostics(
      module: 'notifications',
      collectionPath: collectionPath,
      companyIdPresent: companyId.trim().isNotEmpty,
      roleScope: 'recipient',
      archiveScope: 'all',
    );
    final query = _firestore
        .collection(collectionPath)
        .where('recipientUid', isEqualTo: recipientUid);
    return _safeCount(
      query,
      label: 'notifications.total',
      diagnostics: diagnostics,
    );
  }

  Future<int?> _safeBlankOrNullStringCount(
    Query<Map<String, dynamic>> base, {
    required String field,
    required String label,
    _CountDiagnostics? diagnostics,
  }) async {
    final results = await Future.wait<int?>([
      _safeCount(
        base.where(field, isEqualTo: ''),
        label: '$label.blank',
        diagnostics: diagnostics,
      ),
      _safeCount(
        base.where(field, isNull: true),
        label: '$label.null',
        diagnostics: diagnostics,
      ),
    ]);
    if (results.any((value) => value == null)) {
      return null;
    }
    return results.fold<int>(0, (sum, value) => sum + (value ?? 0));
  }

  Future<Map<String, int>?> _safeLeadCountQueryCounts(
    Query<Map<String, dynamic>> base, {
    required Iterable<String> activeStatuses,
    required DateTime today,
    required DateTime tomorrow,
    required bool includeUnassigned,
    _CountDiagnostics? diagnostics,
  }) async {
    final cleanStatuses = activeStatuses
        .map((status) => status.trim())
        .where((status) => status.isNotEmpty)
        .toList(growable: false);
    if (cleanStatuses.isEmpty || cleanStatuses.length > 10) {
      return null;
    }

    final activeBase = base.where('status', whereIn: cleanStatuses);
    final unassignedFuture = includeUnassigned
        ? _safeBlankOrNullStringCount(
            base,
            field: 'assignedTo',
            label: 'leads.unassigned.countQuery',
            diagnostics: diagnostics,
          )
        : Future<int?>.value(0);
    final results = await Future.wait<int?>([
      _safeCount(
        base,
        label: 'leads.total.countQuery',
        diagnostics: diagnostics,
      ),
      _safeCount(
        base.where('status', isEqualTo: 'new'),
        label: 'leads.new.countQuery',
        diagnostics: diagnostics,
      ),
      _safeCount(
        activeBase,
        label: 'leads.active.countQuery',
        diagnostics: diagnostics,
      ),
      _safeLeadFollowUpSnapshotCount(
        base,
        activeStatuses: cleanStatuses,
        isLessThan: Timestamp.fromDate(today),
        label: 'leads.overdue.countQueryFallback',
        diagnostics: diagnostics,
      ),
      _safeLeadFollowUpSnapshotCount(
        base,
        activeStatuses: cleanStatuses,
        isGreaterThanOrEqualTo: Timestamp.fromDate(tomorrow),
        label: 'leads.upcoming.countQueryFallback',
        diagnostics: diagnostics,
      ),
      unassignedFuture,
    ]);
    if (results.any((value) => value == null)) {
      return null;
    }
    return <String, int>{
      'total': results[0] ?? 0,
      'new': results[1] ?? 0,
      'active': results[2] ?? 0,
      'overdue': results[3] ?? 0,
      'upcoming': results[4] ?? 0,
      'unassigned': results[5] ?? 0,
    };
  }

  Future<Map<String, int>?> _safeLeadSnapshotCounts(
    Query<Map<String, dynamic>> base, {
    required Iterable<String> activeStatuses,
    required DateTime today,
    required DateTime tomorrow,
    required bool includeUnassigned,
    _CountDiagnostics? diagnostics,
  }) async {
    final cleanStatuses = activeStatuses
        .map((status) => status.trim())
        .where((status) => status.isNotEmpty)
        .toSet();
    const scanLimit = _leadFollowUpScanLimit;
    final query = base.limit(scanLimit);
    try {
      final snapshot = await query.get();
      final counts = <String, int>{
        'total': 0,
        'new': 0,
        'active': 0,
        'overdue': 0,
        'upcoming': 0,
        'unassigned': 0,
      };
      for (final document in snapshot.docs) {
        final data = document.data();
        counts['total'] = (counts['total'] ?? 0) + 1;
        final rawStatus = data['status'];
        final status = rawStatus is String ? rawStatus.trim() : '';
        if (status == 'new') {
          counts['new'] = (counts['new'] ?? 0) + 1;
        }
        final isActiveStatus = cleanStatuses.contains(status);
        if (isActiveStatus) {
          counts['active'] = (counts['active'] ?? 0) + 1;
          final nextFollowUpAt = _documentDate(data['nextFollowUpAt']);
          if (nextFollowUpAt != null) {
            final followUpDay = _startOfDay(nextFollowUpAt);
            if (followUpDay.isBefore(today)) {
              counts['overdue'] = (counts['overdue'] ?? 0) + 1;
            } else if (!followUpDay.isBefore(tomorrow)) {
              counts['upcoming'] = (counts['upcoming'] ?? 0) + 1;
            }
          }
        }
        if (includeUnassigned) {
          final rawAssignedTo = data['assignedTo'];
          final assignedTo = rawAssignedTo is String ? rawAssignedTo.trim() : '';
          if (assignedTo.isEmpty) {
            counts['unassigned'] = (counts['unassigned'] ?? 0) + 1;
          }
        }
      }
      if (!includeUnassigned) {
        counts['unassigned'] = 0;
      }
      return counts;
    } on FirebaseException catch (error) {
      _logCountFailure(
        query: query,
        label: 'leads.snapshotScan',
        diagnostics: diagnostics,
        code: error.code,
        message: error.message ?? '',
      );
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, int>?> _safeClientCountQueryCounts(
    Query<Map<String, dynamic>> base, {
    required bool includeUnassigned,
    _CountDiagnostics? diagnostics,
  }) async {
    final unassignedFuture = includeUnassigned
        ? _safeBlankOrNullStringCount(
            base,
            field: 'assignedTo',
            label: 'clients.unassigned.countQuery',
            diagnostics: diagnostics,
          )
        : Future<int?>.value(0);
    final results = await Future.wait<int?>([
      _safeCount(
        base,
        label: 'clients.total.countQuery',
        diagnostics: diagnostics,
      ),
      unassignedFuture,
    ]);
    if (results.any((value) => value == null)) {
      return null;
    }
    final total = results[0] ?? 0;
    final unassigned = results[1] ?? 0;
    return <String, int>{
      'total': total,
      'assigned': total - unassigned,
      'unassigned': unassigned,
    };
  }

  Future<Map<String, int>?> _safeClientSnapshotCounts(
    Query<Map<String, dynamic>> base, {
    required bool includeUnassigned,
    _CountDiagnostics? diagnostics,
    bool useOrderedSnapshot = true,
  }) async {
    const scanLimit = 1000;
    final query = useOrderedSnapshot
        ? base
            .orderBy('createdAt', descending: true)
            .orderBy(FieldPath.documentId, descending: true)
            .limit(scanLimit)
        : base.limit(scanLimit);
    final snapshot = await _safeSnapshotScan(
      query,
      label: 'clients.snapshotScan',
      diagnostics: diagnostics,
      fallback: useOrderedSnapshot ? base.limit(scanLimit) : null,
    );
    if (snapshot == null) {
      return null;
    }
    try {
      var total = 0;
      var unassigned = 0;
      for (final document in snapshot.docs) {
        total++;
        final rawAssignedTo = document.data()['assignedTo'];
        final assignedTo = rawAssignedTo is String ? rawAssignedTo.trim() : '';
        if (includeUnassigned && assignedTo.isEmpty) {
          unassigned++;
        }
      }
      if (!includeUnassigned) {
        unassigned = 0;
      }
      return <String, int>{
        'total': total,
        'assigned': total - unassigned,
        'unassigned': unassigned,
      };
    } on FirebaseException catch (error) {
      _logCountFailure(
        query: query,
        label: 'clients.snapshotScan',
        diagnostics: diagnostics,
        code: error.code,
        message: error.message ?? '',
      );
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<int?> _safeStatusRangeCount(
    Query<Map<String, dynamic>> base, {
    required String statusField,
    required Iterable<String> statuses,
    required String rangeField,
    Object? isLessThan,
    Object? isGreaterThan,
    Object? isGreaterThanOrEqualTo,
    required String label,
    _CountDiagnostics? diagnostics,
  }) async {
    final futures = <Future<int?>>[];
    for (final status in statuses) {
      final cleanStatus = status.trim();
      if (cleanStatus.isEmpty) {
        continue;
      }
      futures.add(
        _safeCount(
          _rangeQuery(
            base.where(statusField, isEqualTo: cleanStatus),
            rangeField,
            isLessThan: isLessThan,
            isGreaterThan: isGreaterThan,
            isGreaterThanOrEqualTo: isGreaterThanOrEqualTo,
          ),
          label: '$label.$cleanStatus',
          diagnostics: diagnostics,
        ),
      );
    }
    if (futures.isEmpty) {
      return 0;
    }
    final results = await Future.wait<int?>(futures);
    if (results.any((value) => value == null)) {
      return null;
    }
    return results.fold<int>(0, (sum, value) => sum + (value ?? 0));
  }

  Future<int?> _safeAppointmentMissedCount(
    Query<Map<String, dynamic>> base, {
    required DateTime now,
    _CountDiagnostics? diagnostics,
  }) async {
    final missedByStatus = await _safeCount(
      base.where('status', isEqualTo: 'missed'),
      label: 'appointments.missedStatus',
      diagnostics: diagnostics,
    );
    final openStatuses = const <String>['scheduled', 'rescheduled'];
    final openFutures = <Future<int?>>[];
    for (final status in openStatuses) {
      openFutures.add(
        _safeCount(
          base.where('status', isEqualTo: status).where(
                Filter.or(
                  Filter('endAt', isLessThan: Timestamp.fromDate(now)),
                  Filter.and(
                    Filter('endAt', isNull: true),
                    Filter(
                      'scheduledAt',
                      isLessThan: Timestamp.fromDate(now),
                    ),
                  ),
                ),
              ),
          label: 'appointments.missedEffective.$status',
          diagnostics: diagnostics,
        ),
      );
    }
    final openResults = await Future.wait<int?>(openFutures);
    if (missedByStatus == null || openResults.any((value) => value == null)) {
      return null;
    }
    return missedByStatus +
        openResults.fold<int>(0, (sum, value) => sum + (value ?? 0));
  }

  Future<Map<String, int>?> _safeAppointmentSnapshotCounts(
    Query<Map<String, dynamic>> base, {
    required DateTime now,
    required DateTime today,
    required DateTime tomorrow,
    DateTime? rangeStart,
    DateTime? rangeEnd,
    _CountDiagnostics? diagnostics,
    bool useScheduledRangeQuery = true,
  }) async {
    const scanLimit = 1000;
    final primaryBase = useScheduledRangeQuery
        ? _applyScheduledSnapshotRange(
            base,
            rangeStart: rangeStart,
            rangeEnd: rangeEnd,
          )
        : base;
    final query = primaryBase.limit(scanLimit);
    final snapshot = await _safeSnapshotScan(
      query,
      label: 'appointments.snapshotScan',
      diagnostics: diagnostics,
      fallback: useScheduledRangeQuery ? base.limit(scanLimit) : null,
    );
    if (snapshot == null) {
      return null;
    }
    try {
      final counts = <String, int>{
        'total': 0,
        'listTotal': 0,
        'today': 0,
        'upcoming': 0,
        'missed': 0,
        'completed': 0,
        'cancelled': 0,
      };
      for (final document in snapshot.docs) {
        final data = document.data();
        counts['total'] = (counts['total'] ?? 0) + 1;
        final rawStatus = data['status'];
        final status = rawStatus is String ? rawStatus.trim() : '';
        final scheduledAt = _documentDate(data['scheduledAt']);
        final endAt = _documentDate(data['endAt']);
        final inListRange = _dateInRange(
          scheduledAt,
          rangeStart: rangeStart,
          rangeEnd: rangeEnd,
        );
        if (inListRange) {
          counts['listTotal'] = (counts['listTotal'] ?? 0) + 1;
        }
        if (scheduledAt != null) {
          final scheduledDay = _startOfDay(scheduledAt);
          if (scheduledDay == today) {
            counts['today'] = (counts['today'] ?? 0) + 1;
          }
        }
        if (status == 'completed') {
          counts['completed'] = (counts['completed'] ?? 0) + 1;
        }
        if (status == 'cancelled') {
          counts['cancelled'] = (counts['cancelled'] ?? 0) + 1;
        }
        final isOpen = status == 'scheduled' || status == 'rescheduled';
        if (isOpen && scheduledAt != null && !scheduledAt.isBefore(now)) {
          counts['upcoming'] = (counts['upcoming'] ?? 0) + 1;
        }
        final isMissed = status == 'missed' ||
            (isOpen &&
                ((endAt != null && endAt.isBefore(now)) ||
                    (endAt == null &&
                        scheduledAt != null &&
                        scheduledAt.isBefore(now))));
        if (isMissed) {
          counts['missed'] = (counts['missed'] ?? 0) + 1;
        }
      }
      return counts;
    } on FirebaseException catch (error) {
      _logCountFailure(
        query: query,
        label: 'appointments.snapshotScan',
        diagnostics: diagnostics,
        code: error.code,
        message: error.message ?? '',
      );
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, int>?> _safeDealSnapshotCounts(
    Query<Map<String, dynamic>> base, {
    required DateTime tomorrow,
    required DateTime startMonth,
    required DateTime nextMonth,
    required DateTime staleExclusiveEnd,
    required Iterable<String> openStages,
    _CountDiagnostics? diagnostics,
    bool useOrderedSnapshot = true,
  }) async {
    const scanLimit = 1000;
    final query = useOrderedSnapshot
        ? base.orderBy('updatedAt', descending: true).limit(scanLimit)
        : base.limit(scanLimit);
    final openStageSet = openStages.map((stage) => stage.trim()).toSet();
    final snapshot = await _safeSnapshotScan(
      query,
      label: 'deals.snapshotScan',
      diagnostics: diagnostics,
      fallback: useOrderedSnapshot ? base.limit(scanLimit) : null,
    );
    if (snapshot == null) {
      return null;
    }
    try {
      final counts = <String, int>{
        'total': 0,
        'open': 0,
        'atRisk': 0,
        'wonThisMonth': 0,
        'lost': 0,
      };
      for (final document in snapshot.docs) {
        final data = document.data();
        counts['total'] = (counts['total'] ?? 0) + 1;
        final rawStage = data['stage'];
        final stage = rawStage is String ? rawStage.trim() : '';
        final updatedAt = _documentDate(data['updatedAt']);
        final createdAt = _documentDate(data['createdAt']);
        final closingDate = _documentDate(data['closingDate']);
        final isOpen = openStageSet.contains(stage);
        if (isOpen) {
          counts['open'] = (counts['open'] ?? 0) + 1;
          final activityDate = updatedAt ?? createdAt;
          final staleByActivity = activityDate != null &&
              activityDate.isBefore(staleExclusiveEnd);
          final overdueClosing = closingDate != null &&
              closingDate.isBefore(tomorrow);
          if (staleByActivity || overdueClosing) {
            counts['atRisk'] = (counts['atRisk'] ?? 0) + 1;
          }
        }
        if (stage == 'won' &&
            updatedAt != null &&
            !updatedAt.isBefore(startMonth) &&
            updatedAt.isBefore(nextMonth)) {
          counts['wonThisMonth'] = (counts['wonThisMonth'] ?? 0) + 1;
        }
        if (stage == 'lost') {
          counts['lost'] = (counts['lost'] ?? 0) + 1;
        }
      }
      return counts;
    } on FirebaseException catch (error) {
      _logCountFailure(
        query: query,
        label: 'deals.snapshotScan',
        diagnostics: diagnostics,
        code: error.code,
        message: error.message ?? '',
      );
      return null;
    } catch (_) {
      return null;
    }
  }

  bool _dateInRange(
    DateTime? value, {
    DateTime? rangeStart,
    DateTime? rangeEnd,
  }) {
    if (value == null) {
      return false;
    }
    if (rangeStart != null && value.isBefore(rangeStart)) {
      return false;
    }
    if (rangeEnd != null && !value.isBefore(rangeEnd)) {
      return false;
    }
    return true;
  }

  Future<Map<String, int>?> _safeTaskCountQueryCounts(
    Query<Map<String, dynamic>> base, {
    required DateTime today,
    _CountDiagnostics? diagnostics,
  }) async {
    final tomorrow = today.add(const Duration(days: 1));
    final openBase = base.where(
      'status',
      whereIn: const <String>['pending', 'inProgress'],
    );
    final results = await Future.wait<int?>([
      _safeCount(base, label: 'tasks.total', diagnostics: diagnostics),
      _safeCount(
        _rangeQuery(
          openBase,
          'dueDate',
          isLessThan: Timestamp.fromDate(today),
        ),
        label: 'tasks.overdue.countQuery',
        diagnostics: diagnostics,
      ),
      _safeCount(
        _rangeQuery(
          openBase,
          'dueDate',
          isGreaterThanOrEqualTo: Timestamp.fromDate(today),
          isLessThan: Timestamp.fromDate(tomorrow),
        ),
        label: 'tasks.today.countQuery',
        diagnostics: diagnostics,
      ),
      _safeCount(
        _rangeQuery(
          openBase,
          'dueDate',
          isGreaterThanOrEqualTo: Timestamp.fromDate(tomorrow),
        ),
        label: 'tasks.upcoming.countQuery',
        diagnostics: diagnostics,
      ),
      _safeCount(
        base.where('status', isEqualTo: 'completed'),
        label: 'tasks.completed.countQuery',
        diagnostics: diagnostics,
      ),
      _safeCount(
        base.where('status', isEqualTo: 'cancelled'),
        label: 'tasks.cancelled.countQuery',
        diagnostics: diagnostics,
      ),
    ]);
    if (results.any((value) => value == null)) {
      return null;
    }
    return <String, int>{
      'total': results[0] ?? 0,
      'overdue': results[1] ?? 0,
      'today': results[2] ?? 0,
      'upcoming': results[3] ?? 0,
      'completed': results[4] ?? 0,
      'cancelled': results[5] ?? 0,
    };
  }

  Future<Map<String, int>?> _safeTaskSnapshotCounts(
    Query<Map<String, dynamic>> base, {
    required DateTime today,
    _CountDiagnostics? diagnostics,
    bool useOrderedSnapshot = true,
  }) async {
    const scanLimit = 1000;
    final query = useOrderedSnapshot
        ? base.orderBy('dueDate').limit(scanLimit)
        : base.limit(scanLimit);
    final snapshot = await _safeSnapshotScan(
      query,
      label: 'tasks.snapshotScan',
      diagnostics: diagnostics,
      fallback: useOrderedSnapshot ? base.limit(scanLimit) : null,
    );
    if (snapshot == null) {
      return null;
    }
    try {
      final counts = <String, int>{
        'total': 0,
        'overdue': 0,
        'today': 0,
        'upcoming': 0,
        'completed': 0,
        'cancelled': 0,
      };
      for (final document in snapshot.docs) {
        final data = document.data();
        counts['total'] = (counts['total'] ?? 0) + 1;
        final rawStatus = data['status'];
        final status = rawStatus is String ? rawStatus.trim() : '';
        final dueDate = _documentDate(data['dueDate']);
        if (status == 'completed') {
          counts['completed'] = (counts['completed'] ?? 0) + 1;
          continue;
        }
        if (status == 'cancelled') {
          counts['cancelled'] = (counts['cancelled'] ?? 0) + 1;
          continue;
        }
        if (status != 'pending' && status != 'inProgress') {
          continue;
        }
        if (dueDate == null) {
          continue;
        }
        final dueDay = _startOfDay(dueDate);
        if (dueDay.isBefore(today)) {
          counts['overdue'] = (counts['overdue'] ?? 0) + 1;
        } else if (dueDay == today) {
          counts['today'] = (counts['today'] ?? 0) + 1;
        } else {
          counts['upcoming'] = (counts['upcoming'] ?? 0) + 1;
        }
      }
      return counts;
    } on FirebaseException catch (error) {
      _logCountFailure(
        query: query,
        label: 'tasks.snapshotScan',
        diagnostics: diagnostics,
        code: error.code,
        message: error.message ?? '',
      );
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<int?> _safeLeadFollowUpSnapshotCount(
    Query<Map<String, dynamic>> base, {
    required Iterable<String> activeStatuses,
    Object? isLessThan,
    Object? isGreaterThanOrEqualTo,
    required String label,
    _CountDiagnostics? diagnostics,
  }) async {
    final cleanStatuses = activeStatuses
        .map((status) => status.trim())
        .where((status) => status.isNotEmpty)
        .toSet();
    if (cleanStatuses.isEmpty) {
      return 0;
    }

    // Do not add the nextFollowUpAt range to Firestore here.
    // Leads KPI cards must not depend on every assignee/status/follow-up
    // composite index being present before the page can render. The scoped
    // base query is intentionally small enough for KPI fallback scanning, and
    // the actual overdue/upcoming truth is applied locally with the same active
    // status set used by the business rules.
    final query = base.limit(_leadFollowUpScanLimit);
    final lessThan = _dateBoundary(isLessThan);
    final greaterThanOrEqualTo = _dateBoundary(isGreaterThanOrEqualTo);

    try {
      final snapshot = await query.get();
      var count = 0;
      for (final document in snapshot.docs) {
        final data = document.data();
        final rawStatus = data['status'];
        final status = rawStatus is String ? rawStatus.trim() : '';
        if (!cleanStatuses.contains(status)) {
          continue;
        }
        final nextFollowUpAt = _documentDate(data['nextFollowUpAt']);
        if (nextFollowUpAt == null) {
          continue;
        }
        if (lessThan != null && !nextFollowUpAt.isBefore(lessThan)) {
          continue;
        }
        if (greaterThanOrEqualTo != null &&
            nextFollowUpAt.isBefore(greaterThanOrEqualTo)) {
          continue;
        }
        count++;
      }
      return count;
    } on FirebaseException catch (error) {
      _logCountFailure(
        query: query,
        label: '$label.followUpSnapshotScan',
        diagnostics: diagnostics,
        code: error.code,
        message: error.message ?? '',
      );
      return null;
    } catch (_) {
      return null;
    }
  }

  DateTime? _dateBoundary(Object? value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    return null;
  }

  DateTime? _documentDate(Object? value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  Query<Map<String, dynamic>> _applyScheduledSnapshotRange(
    Query<Map<String, dynamic>> query, {
    DateTime? rangeStart,
    DateTime? rangeEnd,
  }) {
    if (rangeStart == null && rangeEnd == null) {
      return query;
    }
    var ranged = query.orderBy('scheduledAt');
    if (rangeStart != null) {
      ranged = ranged.where(
        'scheduledAt',
        isGreaterThanOrEqualTo: Timestamp.fromDate(rangeStart.toUtc()),
      );
    }
    if (rangeEnd != null) {
      ranged = ranged.where(
        'scheduledAt',
        isLessThan: Timestamp.fromDate(rangeEnd.toUtc()),
      );
    }
    return ranged;
  }

  Future<QuerySnapshot<Map<String, dynamic>>?> _safeSnapshotScan(
    Query<Map<String, dynamic>> query, {
    required String label,
    _CountDiagnostics? diagnostics,
    Query<Map<String, dynamic>>? fallback,
  }) async {
    try {
      final snapshot = await query.get();
      _logSnapshotSuccess(
        query: query,
        label: label,
        diagnostics: diagnostics,
        docs: snapshot.docs.length,
        source: 'primary',
      );
      return snapshot;
    } on FirebaseException catch (error) {
      if (fallback == null) {
        _logCountFailure(
          query: query,
          label: label,
          diagnostics: diagnostics,
          code: error.code,
          message: error.message ?? '',
        );
        return null;
      }
      _logSnapshotFallback(
        query: query,
        label: label,
        diagnostics: diagnostics,
        code: error.code,
        message: error.message ?? '',
      );
      try {
        final fallbackSnapshot = await fallback.get();
        _logSnapshotSuccess(
          query: fallback,
          label: '$label.fallback',
          diagnostics: diagnostics,
          docs: fallbackSnapshot.docs.length,
          source: 'fallback',
        );
        return fallbackSnapshot;
      } on FirebaseException catch (fallbackError) {
        _logCountFailure(
          query: query,
          label: label,
          diagnostics: diagnostics,
          code: error.code,
          message: error.message ?? '',
        );
        _logCountFailure(
          query: fallback,
          label: '$label.fallback',
          diagnostics: diagnostics,
          code: fallbackError.code,
          message: fallbackError.message ?? '',
        );
        return null;
      } catch (_) {
        return null;
      }
    } catch (_) {
      return null;
    }
  }

  Query<Map<String, dynamic>> _rangeQuery(
    Query<Map<String, dynamic>> query,
    String field, {
    Object? isLessThan,
    Object? isGreaterThan,
    Object? isGreaterThanOrEqualTo,
  }) {
    var ranged = query;
    if (isGreaterThan != null) {
      ranged = ranged.where(field, isGreaterThan: isGreaterThan);
    }
    if (isGreaterThanOrEqualTo != null) {
      ranged = ranged.where(field, isGreaterThanOrEqualTo: isGreaterThanOrEqualTo);
    }
    if (isLessThan != null) {
      ranged = ranged.where(field, isLessThan: isLessThan);
    }
    return ranged;
  }

  ModuleKpiCounts? _readKpiCountsCache({
    required String cacheKey,
    required String label,
    required _CountDiagnostics? diagnostics,
  }) {
    final entry = _kpiCountsCache[cacheKey];
    if (entry == null) {
      return null;
    }
    final age = DateTime.now().difference(entry.createdAt);
    if (age > _kpiCountsCacheTtl) {
      _kpiCountsCache.remove(cacheKey);
      _logKpiCountsCache(
        label: label,
        diagnostics: diagnostics,
        status: 'cacheExpired',
        ageMs: age.inMilliseconds,
      );
      return null;
    }
    _logKpiCountsCache(
      label: label,
      diagnostics: diagnostics,
      status: 'cacheHit',
      ageMs: age.inMilliseconds,
    );
    return entry.counts;
  }

  void _writeKpiCountsCache({
    required String cacheKey,
    required ModuleKpiCounts counts,
    required String label,
    required _CountDiagnostics? diagnostics,
  }) {
    if (!counts.hasFailures) {
      _kpiCountsCache[cacheKey] = _ModuleKpiCountsCacheEntry(
        counts: counts,
        createdAt: DateTime.now(),
      );
      _logKpiCountsCache(
        label: label,
        diagnostics: diagnostics,
        status: 'cacheStore',
        ageMs: 0,
      );
    }
  }

  String _kpiCountsCacheKey({
    required String module,
    required String companyId,
    required String? assignedTo,
    required String? managerId,
    required String? teamId,
    required ArchiveFilter archiveFilter,
    String? dateBucket,
  }) {
    return <String>[
      module,
      companyId.trim(),
      assignedTo?.trim() ?? '',
      managerId?.trim() ?? '',
      teamId?.trim() ?? '',
      archiveFilter.name,
      dateBucket ?? '',
    ].join('|');
  }

  String _dateCacheBucket(DateTime value) {
    final local = _startOfDay(value);
    final year = local.year.toString().padLeft(4, '0');
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  void _logKpiCountsCache({
    required String label,
    required _CountDiagnostics? diagnostics,
    required String status,
    required int ageMs,
  }) {
    if (!kDebugMode) {
      return;
    }
    final module = diagnostics?.module ?? 'unknown';
    final roleScope = diagnostics?.roleScope ?? 'unknown';
    final archiveScope = diagnostics?.archiveScope ?? 'unknown';
    debugPrint(
      'MasarKpiCountDebug: module=$module label=$label status=$status '
      'ageMs=$ageMs ttlMs=${_kpiCountsCacheTtl.inMilliseconds} '
      'role=$roleScope archive=$archiveScope',
    );
  }

  Future<int?> _safeCount(
    Query<Map<String, dynamic>> query, {
    required String label,
    _CountDiagnostics? diagnostics,
  }) async {
    try {
      final snapshot = await query.count().get();
      final count = snapshot.count ?? 0;
      _logCountSuccess(
        query: query,
        label: label,
        diagnostics: diagnostics,
        count: count,
      );
      return count;
    } on FirebaseException catch (error) {
      _logCountFailure(
        query: query,
        label: label,
        diagnostics: diagnostics,
        code: error.code,
        message: error.message ?? '',
      );
      return null;
    } catch (_) {
      return null;
    }
  }

  void _putCount(
    Map<String, int> values,
    Set<String> failedKeys,
    String key,
    int? value,
  ) {
    if (value != null) {
      values[key] = value;
    } else {
      failedKeys.add(key);
    }
  }

  void _logCountSuccess({
    required Query<Map<String, dynamic>> query,
    required String label,
    required _CountDiagnostics? diagnostics,
    required int count,
  }) {
    if (!kDebugMode) {
      return;
    }
    final collectionPath = diagnostics?.collectionPath ?? 'unknown';
    final module = diagnostics?.module ?? 'unknown';
    final roleScope = diagnostics?.roleScope ?? 'unknown';
    final archiveScope = diagnostics?.archiveScope ?? 'unknown';
    final querySignature = _querySignature(query, collectionPath);
    debugPrint(
      'MasarKpiCountDebug: module=$module label=$label status=success '
      'count=$count role=$roleScope archive=$archiveScope '
      'query=$querySignature',
    );
  }

  void _logSnapshotSuccess({
    required Query<Map<String, dynamic>> query,
    required String label,
    required _CountDiagnostics? diagnostics,
    required int docs,
    required String source,
  }) {
    if (!kDebugMode) {
      return;
    }
    final collectionPath = diagnostics?.collectionPath ?? 'unknown';
    final module = diagnostics?.module ?? 'unknown';
    final roleScope = diagnostics?.roleScope ?? 'unknown';
    final archiveScope = diagnostics?.archiveScope ?? 'unknown';
    final querySignature = _querySignature(query, collectionPath);
    debugPrint(
      'MasarKpiCountDebug: module=$module label=$label '
      'status=snapshotSuccess source=$source docs=$docs '
      'role=$roleScope archive=$archiveScope query=$querySignature',
    );
  }

  void _logSnapshotFallback({
    required Query<Map<String, dynamic>> query,
    required String label,
    required _CountDiagnostics? diagnostics,
    required String code,
    required String message,
  }) {
    if (!kDebugMode) {
      return;
    }
    final collectionPath = diagnostics?.collectionPath ?? 'unknown';
    final module = diagnostics?.module ?? 'unknown';
    final roleScope = diagnostics?.roleScope ?? 'unknown';
    final archiveScope = diagnostics?.archiveScope ?? 'unknown';
    final querySignature = _querySignature(query, collectionPath);
    final sanitizedMessage = message
        .replaceAll(RegExp(r'[\r\n\t]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    debugPrint(
      'MasarKpiCountDebug: module=$module label=$label '
      'status=snapshotFallback code=$code role=$roleScope '
      'archive=$archiveScope query=$querySignature message=$sanitizedMessage',
    );
  }

  void _logCountFailure({
    required Query<Map<String, dynamic>> query,
    required String label,
    required _CountDiagnostics? diagnostics,
    required String code,
    required String message,
  }) {
    if (!kDebugMode) {
      return;
    }
    final collectionPath = diagnostics?.collectionPath ?? 'unknown';
    final signature = [
      label,
      code,
      diagnostics?.roleScope ?? 'unknown',
      diagnostics?.archiveScope ?? 'unknown',
      _querySignature(query, collectionPath),
    ].join('|');
    if (!_reportedCountFailures.add(signature)) {
      return;
    }
    final sanitizedMessage = message
        .replaceAll(RegExp(r'[\r\n\t]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final module = diagnostics?.module ?? 'unknown';
    final roleScope = diagnostics?.roleScope ?? 'unknown';
    final archiveScope = diagnostics?.archiveScope ?? 'unknown';
    final querySignature = _querySignature(query, collectionPath);
    debugPrint(
      'MasarKpiCountFailure: module=$module '
      'label=$label code=$code role=$roleScope '
      'archive=$archiveScope query=$querySignature '
      'message=$sanitizedMessage',
    );
  }

  String _querySignature(
    Query<Map<String, dynamic>> query,
    String collectionPath,
  ) {
    try {
      final dynamic parameters = (query as dynamic).parameters;
      if (parameters is! Map) {
        return 'collectionPath=$collectionPath whereFields=unknown orderFields=unknown';
      }
      final whereFields = _whereFieldSignatures(parameters['where']);
      final orderFields = _orderFieldSignatures(parameters['orderBy']);
      final hasLimit = parameters['limit'] != null ||
          parameters['limitToLast'] != null;
      return 'collectionPath=$collectionPath '
          'whereFields=${whereFields.isEmpty ? 'none' : whereFields.join(',')} '
          'orderFields=${orderFields.isEmpty ? 'none' : orderFields.join(',')} '
          'hasLimit=$hasLimit';
    } catch (error) {
      return 'collectionPath=$collectionPath whereFields=unavailable orderFields=unavailable';
    }
  }

  List<String> _whereFieldSignatures(Object? where) {
    final fields = <String>{};

    void visit(Object? item) {
      if (item is List && item.length >= 2 && item[1] is String) {
        fields.add('${_fieldName(item[0])} ${item[1]}');
        return;
      }
      if (item is Map) {
        final fieldPath = item['fieldPath'];
        final op = item['op'];
        if (fieldPath != null && op != null && item.containsKey('value')) {
          fields.add('${_fieldName(fieldPath)} $op');
        }
        visit(item['queries']);
        return;
      }
      if (item is Iterable) {
        for (final nested in item) {
          visit(nested);
        }
      }
    }

    visit(where);
    final sortedFields = fields.toList()..sort();
    return sortedFields;
  }

  List<String> _orderFieldSignatures(Object? orderBy) {
    if (orderBy is! Iterable) {
      return const <String>[];
    }
    final fields = <String>[];
    for (final order in orderBy) {
      if (order is List && order.isNotEmpty) {
        fields.add(_fieldName(order.first));
      }
    }
    fields.sort();
    return fields;
  }

  String _fieldName(Object? field) {
    final value = field.toString();
    final fieldPathMatch = RegExp(r'FieldPath\(\[(.*)\]\)').firstMatch(value);
    if (fieldPathMatch != null) {
      return fieldPathMatch.group(1) ?? value;
    }
    return value;
  }

  String? _missingIndexLink(String message) {
    final match = RegExp(
      r'https://console\.firebase\.google\.com/[^\s]+',
    ).firstMatch(message);
    return match?.group(0);
  }

  String _moduleFromLabel(String label) {
    final index = label.indexOf('.');
    return index <= 0 ? label : label.substring(0, index);
  }

  Query<Map<String, dynamic>> _applyArchive(
    Query<Map<String, dynamic>> query,
    ArchiveFilter archiveFilter, {
    String? activeField,
  }) {
    if (archiveFilter == ArchiveFilter.archived) {
      return query.where('isArchived', isEqualTo: true);
    }
    if (archiveFilter == ArchiveFilter.active) {
      var scoped = query.where('isArchived', isEqualTo: false);
      if (activeField != null) {
        scoped = scoped.where(activeField, isEqualTo: true);
      }
      return scoped;
    }
    return query;
  }

  Query<Map<String, dynamic>> _applyPeopleScope(
    Query<Map<String, dynamic>> query, {
    String? assignedTo,
    String? managerId,
    String? teamId,
  }) {
    if (!_isBlank(assignedTo)) {
      return query.where('assignedTo', isEqualTo: assignedTo!.trim());
    }
    if (!_isBlank(teamId)) {
      return query.where('teamId', isEqualTo: teamId!.trim());
    }
    if (!_isBlank(managerId)) {
      return query.where('managerId', isEqualTo: managerId!.trim());
    }
    return query;
  }

  Query<Map<String, dynamic>> _applyDealScope(
    Query<Map<String, dynamic>> query, {
    required UserRole role,
    required String currentUserId,
    String? teamId,
  }) {
    if (role == UserRole.manager) {
      if (!_isBlank(teamId)) {
        return query.where('teamId', isEqualTo: teamId!.trim());
      }
      return query.where('managerId', isEqualTo: currentUserId);
    }
    if (role == UserRole.salesAgent ||
        role == UserRole.marketing ||
        role == UserRole.viewer) {
      return query.where('assignedTo', isEqualTo: currentUserId);
    }
    return query;
  }

  String _peopleScopeLabel({
    String? assignedTo,
    String? managerId,
    String? teamId,
  }) {
    if (!_isBlank(assignedTo)) {
      return 'assigned';
    }
    if (!_isBlank(teamId)) {
      return 'team';
    }
    if (!_isBlank(managerId)) {
      return 'manager';
    }
    return 'company';
  }

  String _dealScopeLabel({
    required UserRole role,
    String? teamId,
  }) {
    if (role == UserRole.manager) {
      return _isBlank(teamId) ? 'manager' : 'team';
    }
    if (role == UserRole.salesAgent ||
        role == UserRole.marketing ||
        role == UserRole.viewer) {
      return 'assigned';
    }
    return 'company';
  }

  DateTime _startOfDay(DateTime value) => DateTime(value.year, value.month, value.day);

  bool _isBlank(String? value) => (value ?? '').trim().isEmpty;
}
