import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/role_constants.dart';
import '../../domain/usecases/backfill_operational_record_snapshots_usecase.dart';
import '../../domain/usecases/get_data_health_eligible_assignees_usecase.dart';
import '../../domain/usecases/get_operational_data_health_report_usecase.dart';
import '../../domain/usecases/notify_data_health_manager_usecase.dart';
import '../../domain/usecases/reassign_data_health_record_usecase.dart';
import '../../../platform/domain/entities/company_data_health_report.dart';
import 'data_health_state.dart';

class DataHealthCubit extends Cubit<DataHealthState> {
  static final Map<String, DataHealthState> _cachedReportsByCompany = <String, DataHealthState>{};

  DataHealthCubit({
    required GetOperationalDataHealthReportUseCase getReportUseCase,
    required BackfillOperationalRecordSnapshotsUseCase backfillUseCase,
    required ReassignDataHealthRecordUseCase reassignUseCase,
    required GetDataHealthEligibleAssigneesUseCase eligibleAssigneesUseCase,
    required NotifyDataHealthManagerUseCase notifyManagerUseCase,
  })  : _getReportUseCase = getReportUseCase,
        _backfillUseCase = backfillUseCase,
        _reassignUseCase = reassignUseCase,
        _eligibleAssigneesUseCase = eligibleAssigneesUseCase,
        _notifyManagerUseCase = notifyManagerUseCase,
        super(const DataHealthState.initial());

  final GetOperationalDataHealthReportUseCase _getReportUseCase;
  final BackfillOperationalRecordSnapshotsUseCase _backfillUseCase;
  final ReassignDataHealthRecordUseCase _reassignUseCase;
  final GetDataHealthEligibleAssigneesUseCase _eligibleAssigneesUseCase;
  final NotifyDataHealthManagerUseCase _notifyManagerUseCase;

  Future<void> restoreCachedReport(String companyId) async {
    final cached = _cachedReportsByCompany[companyId];
    if (cached != null && state.report == null) {
      emit(cached.copyWith(clearActiveAction: true, clearMessage: true));
      return;
    }

    if (state.report != null) {
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey(companyId));
      if (raw == null || raw.isEmpty || isClosed) {
        return;
      }
      final data = jsonDecode(raw);
      if (data is! Map) {
        return;
      }
      final report = _reportFromJson(Map<String, dynamic>.from(data));
      final nextState = DataHealthState(status: DataHealthStatus.ready, report: report);
      _cachedReportsByCompany[companyId] = nextState;
      emit(nextState);
    } catch (_) {
      // Ignore corrupt local cache; the user can run a fresh check.
    }
  }

  Future<void> loadReport(String companyId) async {
    emit(state.copyWith(status: DataHealthStatus.loading, clearMessage: true));
    try {
      final report = await _getReportUseCase(companyId: companyId);
      final nextState = state.copyWith(status: DataHealthStatus.ready, report: report, clearMessage: true);
      await _cacheState(companyId, nextState);
      emit(nextState);
    } catch (error) {
      emit(state.copyWith(status: DataHealthStatus.failure, message: error.toString()));
    }
  }

  Future<bool> backfill({
    required String companyId,
    required String module,
    required String recordId,
  }) async {
    final actionId = '$module/$recordId/backfill';
    emit(state.copyWith(status: DataHealthStatus.saving, activeActionId: actionId, clearMessage: true));
    try {
      await _backfillUseCase(companyId: companyId, module: module, recordId: recordId);
      final nextState = _stateAfterResolvedIssue(
        state.copyWith(status: DataHealthStatus.ready, clearActiveAction: true, clearMessage: true),
        companyId: companyId,
        module: module,
        recordId: recordId,
      );
      await _cacheState(companyId, nextState);
      emit(nextState);
      return true;
    } catch (error) {
      emit(state.copyWith(status: DataHealthStatus.failure, message: error.toString(), clearActiveAction: true));
      return false;
    }
  }

  Future<void> loadEligibleAssignees({
    required String companyId,
    required String module,
    required UserRole currentRole,
    required String currentUid,
    required String currentTeamId,
  }) async {
    emit(state.copyWith(status: DataHealthStatus.loading, clearMessage: true));
    try {
      final users = await _eligibleAssigneesUseCase(
        companyId: companyId,
        module: module,
        currentRole: currentRole,
        currentUid: currentUid,
        currentTeamId: currentTeamId,
      );
      emit(state.copyWith(status: DataHealthStatus.ready, eligibleAssignees: users, clearMessage: true));
    } catch (error) {
      emit(state.copyWith(status: DataHealthStatus.failure, message: error.toString()));
    }
  }

  Future<bool> reassign({
    required String companyId,
    required String module,
    required String recordId,
    required String newAssigneeUid,
  }) async {
    final actionId = '$module/$recordId/reassign';
    emit(state.copyWith(status: DataHealthStatus.saving, activeActionId: actionId, clearMessage: true));
    try {
      await _reassignUseCase(
        companyId: companyId,
        module: module,
        recordId: recordId,
        newAssigneeUid: newAssigneeUid,
      );
      final nextState = _stateAfterResolvedIssue(
        state.copyWith(status: DataHealthStatus.ready, clearActiveAction: true, clearMessage: true),
        companyId: companyId,
        module: module,
        recordId: recordId,
      );
      await _cacheState(companyId, nextState);
      emit(nextState);
      return true;
    } catch (error) {
      emit(state.copyWith(status: DataHealthStatus.failure, message: error.toString(), clearActiveAction: true));
      return false;
    }
  }

  Future<bool> notifyManager({
    required String companyId,
    required String module,
    required String recordId,
    required String issueType,
  }) async {
    final actionId = '$module/$recordId/notifyManager';
    emit(state.copyWith(status: DataHealthStatus.saving, activeActionId: actionId, clearMessage: true));
    try {
      await _notifyManagerUseCase(
        companyId: companyId,
        module: module,
        recordId: recordId,
        issueType: issueType,
      );
      emit(state.copyWith(status: DataHealthStatus.ready, clearActiveAction: true, clearMessage: true));
      return true;
    } catch (error) {
      emit(state.copyWith(status: DataHealthStatus.failure, message: error.toString(), clearActiveAction: true));
      return false;
    }
  }

  DataHealthState _stateAfterResolvedIssue(
    DataHealthState baseState, {
    required String companyId,
    required String module,
    required String recordId,
  }) {
    final report = baseState.report;
    if (report == null) {
      return baseState;
    }

    final remainingIssues = report.issues
        .where((issue) => !(issue.module == module && issue.recordId == recordId))
        .toList(growable: false);
    final nextReport = _reportWithIssues(report, remainingIssues);
    final nextState = baseState.copyWith(report: nextReport);
    _cachedReportsByCompany[companyId] = nextState;
    return nextState;
  }

  Future<void> _cacheState(String companyId, DataHealthState nextState) async {
    _cachedReportsByCompany[companyId] = nextState;
    final report = nextState.report;
    if (report == null) {
      return;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey(companyId), jsonEncode(_reportToJson(report)));
    } catch (_) {
      // Local persistence is best-effort only.
    }
  }

  static String _cacheKey(String companyId) => 'masar_data_health_report_$companyId';

  static CompanyDataHealthReport _reportWithIssues(
    CompanyDataHealthReport report,
    List<DataHealthIssue> issues,
  ) {
    return CompanyDataHealthReport(
      companyId: report.companyId,
      generatedAt: report.generatedAt,
      missingSnapshots: issues.where((issue) => issue.issueType == 'missingSnapshots').length,
      invalidAssignees: issues.where((issue) =>
          issue.issueType == 'missingAssignee' ||
          issue.issueType == 'ineligibleAssignee').length,
      inactiveAssignees: issues.where((issue) => issue.issueType == 'inactiveAssignee').length,
      staleTeamSnapshots: issues.where((issue) => issue.issueType == 'staleSnapshots').length,
      issues: issues,
    );
  }

  static Map<String, Object?> _reportToJson(CompanyDataHealthReport report) {
    return <String, Object?>{
      'companyId': report.companyId,
      'generatedAt': report.generatedAt?.toIso8601String(),
      'missingSnapshots': report.missingSnapshots,
      'invalidAssignees': report.invalidAssignees,
      'inactiveAssignees': report.inactiveAssignees,
      'staleTeamSnapshots': report.staleTeamSnapshots,
      'issues': report.issues.map((issue) => <String, Object?>{
            'module': issue.module,
            'recordId': issue.recordId,
            'title': issue.title,
            'assignedTo': issue.assignedTo,
            'assignedToName': issue.assignedToName,
            'managerId': issue.managerId,
            'managerName': issue.managerName,
            'issueType': issue.issueType,
            'suggestedAction': issue.suggestedAction,
            'canBackfill': issue.canBackfill,
          }).toList(growable: false),
    };
  }

  static CompanyDataHealthReport _reportFromJson(Map<String, dynamic> data) {
    final rawIssues = data['issues'];
    final issues = rawIssues is List
        ? rawIssues
            .whereType<Map>()
            .map((issue) {
              final map = Map<String, dynamic>.from(issue);
              return DataHealthIssue(
                module: map['module'] as String? ?? '',
                recordId: map['recordId'] as String? ?? '',
                title: map['title'] as String? ?? '',
                assignedTo: map['assignedTo'] as String? ?? '',
                assignedToName: map['assignedToName'] as String? ?? '',
                managerId: map['managerId'] as String? ?? '',
                managerName: map['managerName'] as String? ?? '',
                issueType: map['issueType'] as String? ?? '',
                suggestedAction: map['suggestedAction'] as String? ?? '',
                canBackfill: map['canBackfill'] as bool? ?? false,
              );
            })
            .toList(growable: false)
        : const <DataHealthIssue>[];
    return CompanyDataHealthReport(
      companyId: data['companyId'] as String? ?? '',
      generatedAt: DateTime.tryParse(data['generatedAt'] as String? ?? ''),
      missingSnapshots: data['missingSnapshots'] as int? ??
          issues.where((issue) => issue.issueType == 'missingSnapshots').length,
      invalidAssignees: data['invalidAssignees'] as int? ??
          issues.where((issue) =>
              issue.issueType == 'missingAssignee' ||
              issue.issueType == 'ineligibleAssignee').length,
      inactiveAssignees: data['inactiveAssignees'] as int? ??
          issues.where((issue) => issue.issueType == 'inactiveAssignee').length,
      staleTeamSnapshots: data['staleTeamSnapshots'] as int? ??
          issues.where((issue) => issue.issueType == 'staleSnapshots').length,
      issues: issues,
    );
  }

}
