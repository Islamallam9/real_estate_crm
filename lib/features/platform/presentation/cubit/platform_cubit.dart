import 'dart:async';

import 'package:bloc/bloc.dart';

import '../../../../core/constants/role_constants.dart';
import '../../domain/usecases/add_user_to_company_usecase.dart';
import '../../domain/usecases/backfill_assigned_record_snapshots_usecase.dart';
import '../../domain/usecases/create_company_with_admin_usecase.dart';
import '../../domain/usecases/export_company_data_usecase.dart';
import '../../domain/usecases/extend_company_payment_due_date_usecase.dart';
import '../../domain/usecases/get_company_data_health_report_usecase.dart';
import '../../domain/usecases/generate_company_user_password_reset_link_usecase.dart';
import '../../domain/usecases/mark_company_payment_paid_usecase.dart';
import '../../domain/usecases/refresh_company_storage_usage_usecase.dart';
import '../../domain/usecases/set_company_active_status_usecase.dart';
import '../../domain/usecases/set_company_user_active_status_usecase.dart';
import '../../domain/usecases/set_company_user_email_usecase.dart';
import '../../domain/usecases/set_company_user_password_usecase.dart';
import '../../domain/usecases/update_company_platform_settings_usecase.dart';
import '../../domain/usecases/update_company_payment_status_usecase.dart';
import '../../domain/usecases/watch_platform_companies_usecase.dart';
import '../../domain/usecases/watch_platform_company_users_usecase.dart';
import '../../domain/usecases/watch_platform_payment_history_usecase.dart';
import 'platform_state.dart';

class PlatformCubit extends Cubit<PlatformState> {
  PlatformCubit({
    required WatchPlatformCompaniesUseCase watchCompaniesUseCase,
    required WatchPlatformCompanyUsersUseCase watchCompanyUsersUseCase,
    required WatchPlatformPaymentHistoryUseCase watchPaymentHistoryUseCase,
    required CreateCompanyWithAdminUseCase createCompanyWithAdminUseCase,
    required AddUserToCompanyUseCase addUserToCompanyUseCase,
    required SetCompanyActiveStatusUseCase setCompanyActiveStatusUseCase,
    required SetCompanyUserActiveStatusUseCase setCompanyUserActiveStatusUseCase,
    required SetCompanyUserEmailUseCase setCompanyUserEmailUseCase,
    required SetCompanyUserPasswordUseCase setCompanyUserPasswordUseCase,
    required GenerateCompanyUserPasswordResetLinkUseCase
        generateCompanyUserPasswordResetLinkUseCase,
    required UpdateCompanyPlatformSettingsUseCase
        updateCompanyPlatformSettingsUseCase,
    required GetCompanyDataHealthReportUseCase
        getCompanyDataHealthReportUseCase,
    required BackfillAssignedRecordSnapshotsUseCase
        backfillAssignedRecordSnapshotsUseCase,
    required RefreshCompanyStorageUsageUseCase refreshCompanyStorageUsageUseCase,
    required ExportCompanyDataUseCase exportCompanyDataUseCase,
    required MarkCompanyPaymentPaidUseCase markCompanyPaymentPaidUseCase,
    required ExtendCompanyPaymentDueDateUseCase
        extendCompanyPaymentDueDateUseCase,
    required UpdateCompanyPaymentStatusUseCase
        updateCompanyPaymentStatusUseCase,
  }) : _watchCompaniesUseCase = watchCompaniesUseCase,
       _watchCompanyUsersUseCase = watchCompanyUsersUseCase,
       _watchPaymentHistoryUseCase = watchPaymentHistoryUseCase,
       _createCompanyWithAdminUseCase = createCompanyWithAdminUseCase,
       _addUserToCompanyUseCase = addUserToCompanyUseCase,
       _setCompanyActiveStatusUseCase = setCompanyActiveStatusUseCase,
       _setCompanyUserActiveStatusUseCase = setCompanyUserActiveStatusUseCase,
       _setCompanyUserEmailUseCase = setCompanyUserEmailUseCase,
       _setCompanyUserPasswordUseCase = setCompanyUserPasswordUseCase,
       _generateCompanyUserPasswordResetLinkUseCase =
           generateCompanyUserPasswordResetLinkUseCase,
       _updateCompanyPlatformSettingsUseCase =
           updateCompanyPlatformSettingsUseCase,
       _getCompanyDataHealthReportUseCase = getCompanyDataHealthReportUseCase,
       _backfillAssignedRecordSnapshotsUseCase =
           backfillAssignedRecordSnapshotsUseCase,
       _refreshCompanyStorageUsageUseCase = refreshCompanyStorageUsageUseCase,
       _exportCompanyDataUseCase = exportCompanyDataUseCase,
       _markCompanyPaymentPaidUseCase = markCompanyPaymentPaidUseCase,
       _extendCompanyPaymentDueDateUseCase =
           extendCompanyPaymentDueDateUseCase,
       _updateCompanyPaymentStatusUseCase = updateCompanyPaymentStatusUseCase,
       super(const PlatformState.initial());

  final WatchPlatformCompaniesUseCase _watchCompaniesUseCase;
  final WatchPlatformCompanyUsersUseCase _watchCompanyUsersUseCase;
  final WatchPlatformPaymentHistoryUseCase _watchPaymentHistoryUseCase;
  final CreateCompanyWithAdminUseCase _createCompanyWithAdminUseCase;
  final AddUserToCompanyUseCase _addUserToCompanyUseCase;
  final SetCompanyActiveStatusUseCase _setCompanyActiveStatusUseCase;
  final SetCompanyUserActiveStatusUseCase _setCompanyUserActiveStatusUseCase;
  final SetCompanyUserEmailUseCase _setCompanyUserEmailUseCase;
  final SetCompanyUserPasswordUseCase _setCompanyUserPasswordUseCase;
  final GenerateCompanyUserPasswordResetLinkUseCase
      _generateCompanyUserPasswordResetLinkUseCase;
  final UpdateCompanyPlatformSettingsUseCase
      _updateCompanyPlatformSettingsUseCase;
  final GetCompanyDataHealthReportUseCase _getCompanyDataHealthReportUseCase;
  final BackfillAssignedRecordSnapshotsUseCase
      _backfillAssignedRecordSnapshotsUseCase;
  final RefreshCompanyStorageUsageUseCase _refreshCompanyStorageUsageUseCase;
  final ExportCompanyDataUseCase _exportCompanyDataUseCase;
  final MarkCompanyPaymentPaidUseCase _markCompanyPaymentPaidUseCase;
  final ExtendCompanyPaymentDueDateUseCase _extendCompanyPaymentDueDateUseCase;
  final UpdateCompanyPaymentStatusUseCase _updateCompanyPaymentStatusUseCase;

  StreamSubscription? _companiesSubscription;
  StreamSubscription? _companyUsersSubscription;
  StreamSubscription? _paymentHistorySubscription;

  void watchCompanies() {
    emit(state.copyWith(status: PlatformStatus.loading, clearMessage: true));
    _companiesSubscription?.cancel();
    _companiesSubscription = _watchCompaniesUseCase().listen(
      (companies) {
        final selectedId = state.selectedCompanyId;
        final nextSelectedId =
            selectedId != null && companies.any((company) => company.id == selectedId)
            ? selectedId
            : (companies.isEmpty ? null : companies.first.id);

        emit(
          state.copyWith(
            status: PlatformStatus.ready,
            companies: companies,
            selectedCompanyId: nextSelectedId,
            clearMessage: true,
          ),
        );

        if (nextSelectedId != null) {
          watchCompanyUsers(nextSelectedId);
          watchPaymentHistory(nextSelectedId);
        }
      },
      onError: (Object error) {
        emit(
          state.copyWith(
            status: PlatformStatus.failure,
            message: _cleanError(error),
          ),
        );
      },
    );
  }

  void selectCompany(String companyId) {
    emit(
      state.copyWith(
        selectedCompanyId: companyId,
        companyUsers: const [],
        paymentHistory: const [],
        clearDataHealthReport: true,
        clearMessage: true,
      ),
    );
    watchCompanyUsers(companyId);
    watchPaymentHistory(companyId);
  }

  void updateSearchQuery(String query) {
    emit(state.copyWith(searchQuery: query, clearMessage: true));
  }

  void updateCompanyFilter(PlatformCompanyFilter filter) {
    emit(state.copyWith(companyFilter: filter, clearMessage: true));
  }

  void watchCompanyUsers(String companyId) {
    _companyUsersSubscription?.cancel();
    _companyUsersSubscription = _watchCompanyUsersUseCase(companyId: companyId)
        .listen(
          (users) {
            emit(
              state.copyWith(
                status: PlatformStatus.ready,
                companyUsers: users,
                clearMessage: true,
              ),
            );
          },
          onError: (Object error) {
            emit(
              state.copyWith(
                status: PlatformStatus.failure,
                message: _cleanError(error),
              ),
            );
          },
        );
  }

  void watchPaymentHistory(String companyId) {
    _paymentHistorySubscription?.cancel();
    _paymentHistorySubscription = _watchPaymentHistoryUseCase(companyId: companyId)
        .listen(
          (history) {
            emit(
              state.copyWith(
                status: PlatformStatus.ready,
                paymentHistory: history,
                clearMessage: true,
              ),
            );
          },
          onError: (Object error) {
            emit(
              state.copyWith(
                status: PlatformStatus.failure,
                message: _cleanError(error),
              ),
            );
          },
        );
  }

  Future<bool> createCompanyWithAdmin({
    required String companyId,
    required String companyName,
    required String adminFullName,
    required String adminEmail,
    required String adminPhone,
    required String locale,
    required String timezone,
    int? trialDays,
    String trialDurationUnit = 'days',
  }) async {
    final success = await _save(() {
      return _createCompanyWithAdminUseCase(
        companyId: companyId,
        companyName: companyName,
        adminFullName: adminFullName,
        adminEmail: adminEmail,
        adminPhone: adminPhone,
        locale: locale,
        timezone: timezone,
        trialDays: trialDays,
        trialDurationUnit: trialDurationUnit,
      );
    });
    if (success) {
      selectCompany(companyId);
    }
    return success;
  }

  Future<bool> addUserToCompany({
    required String companyId,
    required String fullName,
    required String email,
    required String phone,
    required UserRole role,
  }) async {
    return _save(() {
      return _addUserToCompanyUseCase(
        companyId: companyId,
        fullName: fullName,
        email: email,
        phone: phone,
        role: role,
      );
    });
  }

  Future<bool> setCompanyActiveStatus({
    required String companyId,
    required bool isActive,
  }) async {
    emit(
      state.copyWith(
        status: PlatformStatus.saving,
        activeCompanyActionId: companyId,
        clearMessage: true,
      ),
    );
    try {
      await _setCompanyActiveStatusUseCase(
        companyId: companyId,
        isActive: isActive,
      );
      emit(
        state.copyWith(
          status: PlatformStatus.ready,
          clearMessage: true,
          clearActiveCompanyAction: true,
        ),
      );
      return true;
    } catch (error) {
      emit(
        state.copyWith(
          status: PlatformStatus.failure,
          message: _cleanError(error),
          clearActiveCompanyAction: true,
        ),
      );
      return false;
    }
  }

  Future<bool> setCompanyUserActiveStatus({
    required String companyId,
    required String uid,
    required bool isActive,
  }) async {
    emit(
      state.copyWith(
        status: PlatformStatus.saving,
        activeUserActionId: uid,
        clearMessage: true,
      ),
    );
    try {
      await _setCompanyUserActiveStatusUseCase(
        companyId: companyId,
        uid: uid,
        isActive: isActive,
      );
      emit(
        state.copyWith(
          status: PlatformStatus.ready,
          clearMessage: true,
          clearActiveUserAction: true,
        ),
      );
      return true;
    } catch (error) {
      emit(
        state.copyWith(
          status: PlatformStatus.failure,
          message: _cleanError(error),
          clearActiveUserAction: true,
        ),
      );
      return false;
    }
  }

  Future<bool> setCompanyUserPassword({
    required String companyId,
    required String uid,
    required String newPassword,
  }) async {
    return _save(() {
      return _setCompanyUserPasswordUseCase(
        companyId: companyId,
        uid: uid,
        newPassword: newPassword,
      );
    });
  }

  Future<bool> setCompanyUserEmail({
    required String companyId,
    required String uid,
    required String newEmail,
  }) async {
    return _save(() {
      return _setCompanyUserEmailUseCase(
        companyId: companyId,
        uid: uid,
        newEmail: newEmail,
      );
    });
  }

  Future<String?> generateCompanyUserPasswordResetLink({
    required String companyId,
    required String uid,
  }) async {
    emit(state.copyWith(status: PlatformStatus.saving, clearMessage: true));
    try {
      final result = await _generateCompanyUserPasswordResetLinkUseCase(
        companyId: companyId,
        uid: uid,
      );
      emit(state.copyWith(status: PlatformStatus.ready, clearMessage: true));
      return result.passwordResetLink;
    } catch (error) {
      emit(
        state.copyWith(
          status: PlatformStatus.failure,
          message: _cleanError(error),
        ),
      );
      return null;
    }
  }

  Future<bool> updateCompanyPlatformSettings({
    required String companyId,
    String? name,
    String? displayName,
    String? status,
    bool? isActive,
    Map<String, Object?>? settings,
    Map<String, Object?>? limits,
    Map<String, Object?>? features,
    DateTime? trialEndsAt,
    int? trialDurationValue,
    String? trialDurationUnit,
    String? actionId,
  }) async {
    emit(
      state.copyWith(
        status: PlatformStatus.saving,
        activeSettingsActionId: actionId ?? companyId,
        clearMessage: true,
      ),
    );
    try {
      await _updateCompanyPlatformSettingsUseCase(
        companyId: companyId,
        name: name,
        displayName: displayName,
        status: status,
        isActive: isActive,
        settings: settings,
        limits: limits,
        features: features,
        trialEndsAt: trialEndsAt,
        trialDurationValue: trialDurationValue,
        trialDurationUnit: trialDurationUnit,
      );
      emit(
        state.copyWith(
          status: PlatformStatus.ready,
          clearMessage: true,
          clearActiveSettingsAction: true,
        ),
      );
      return true;
    } catch (error) {
      emit(
        state.copyWith(
          status: PlatformStatus.failure,
          message: _cleanError(error),
          clearActiveSettingsAction: true,
        ),
      );
      return false;
    }
  }

  Future<void> loadDataHealthReport(String companyId) async {
    emit(
      state.copyWith(
        dataHealthLoading: true,
        clearDataHealthReport: true,
        clearMessage: true,
      ),
    );
    try {
      final report = await _getCompanyDataHealthReportUseCase(
        companyId: companyId,
      );
      emit(
        state.copyWith(
          status: PlatformStatus.ready,
          dataHealthReport: report,
          dataHealthLoading: false,
          clearMessage: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: PlatformStatus.failure,
          dataHealthLoading: false,
          message: _cleanError(error),
        ),
      );
    }
  }

  Future<bool> backfillAssignedRecordSnapshots({
    required String companyId,
    required String module,
    required String recordId,
  }) async {
    final actionId = '$module/$recordId';
    emit(
      state.copyWith(
        status: PlatformStatus.saving,
        activeDataHealthActionId: actionId,
        clearMessage: true,
      ),
    );
    try {
      await _backfillAssignedRecordSnapshotsUseCase(
        companyId: companyId,
        module: module,
        recordId: recordId,
      );
      final report = await _getCompanyDataHealthReportUseCase(
        companyId: companyId,
      );
      emit(
        state.copyWith(
          status: PlatformStatus.ready,
          dataHealthReport: report,
          clearActiveDataHealthAction: true,
          clearMessage: true,
        ),
      );
      return true;
    } catch (error) {
      emit(
        state.copyWith(
          status: PlatformStatus.failure,
          message: _cleanError(error),
          clearActiveDataHealthAction: true,
        ),
      );
      return false;
    }
  }

  Future<bool> refreshCompanyStorageUsage({required String companyId}) async {
    emit(
      state.copyWith(
        status: PlatformStatus.saving,
        activeStorageActionId: companyId,
        clearMessage: true,
      ),
    );
    try {
      await _refreshCompanyStorageUsageUseCase(companyId: companyId);
      emit(
        state.copyWith(
          status: PlatformStatus.ready,
          clearActiveStorageAction: true,
          clearMessage: true,
        ),
      );
      return true;
    } catch (error) {
      emit(
        state.copyWith(
          status: PlatformStatus.failure,
          message: _cleanError(error),
          clearActiveStorageAction: true,
        ),
      );
      return false;
    }
  }

  Future<bool> markCompanyPaymentPaid({
    required String companyId,
    required double amount,
    required String currency,
    required DateTime paymentDate,
    required DateTime nextPaymentDueAt,
    required String paymentCycle,
    required String notes,
  }) {
    return _paymentSave(companyId, () {
      return _markCompanyPaymentPaidUseCase(
        companyId: companyId,
        amount: amount,
        currency: currency,
        paymentDate: paymentDate,
        nextPaymentDueAt: nextPaymentDueAt,
        paymentCycle: paymentCycle,
        notes: notes,
      );
    });
  }

  Future<bool> extendCompanyPaymentDueDate({
    required String companyId,
    required DateTime nextPaymentDueAt,
    required String notes,
  }) {
    return _paymentSave(companyId, () {
      return _extendCompanyPaymentDueDateUseCase(
        companyId: companyId,
        nextPaymentDueAt: nextPaymentDueAt,
        notes: notes,
      );
    });
  }

  Future<bool> updateCompanyPaymentStatus({
    required String companyId,
    required String paymentStatus,
    DateTime? nextPaymentDueAt,
    DateTime? gracePeriodEndsAt,
    String? suspendedReason,
    String? notes,
  }) {
    return _paymentSave(companyId, () {
      return _updateCompanyPaymentStatusUseCase(
        companyId: companyId,
        paymentStatus: paymentStatus,
        nextPaymentDueAt: nextPaymentDueAt,
        gracePeriodEndsAt: gracePeriodEndsAt,
        suspendedReason: suspendedReason,
        notes: notes,
      );
    });
  }

  String _cleanError(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }

  Future<bool> _save(Future<void> Function() action) async {
    emit(state.copyWith(status: PlatformStatus.saving, clearMessage: true));
    try {
      await action();
      emit(state.copyWith(status: PlatformStatus.ready, clearMessage: true));
      return true;
    } catch (error) {
      emit(
        state.copyWith(
          status: PlatformStatus.failure,
          message: _cleanError(error),
        ),
      );
      return false;
    }
  }

  Future<bool> _paymentSave(
    String companyId,
    Future<void> Function() action,
  ) async {
    emit(
      state.copyWith(
        status: PlatformStatus.saving,
        activeSettingsActionId: 'payment:$companyId',
        clearMessage: true,
      ),
    );
    try {
      await action();
      emit(
        state.copyWith(
          status: PlatformStatus.ready,
          clearMessage: true,
          clearActiveSettingsAction: true,
        ),
      );
      return true;
    } catch (error) {
      emit(
        state.copyWith(
          status: PlatformStatus.failure,
          message: _cleanError(error),
          clearActiveSettingsAction: true,
        ),
      );
      return false;
    }
  }

  Future<Map<String, dynamic>?> exportCompanyData({
    required String companyId,
    List<String>? collections,
  }) async {
    final actionId = 'export:$companyId';
    emit(
      state.copyWith(
        status: PlatformStatus.saving,
        activeCompanyActionId: actionId,
        clearMessage: true,
      ),
    );
    try {
      final data = await _exportCompanyDataUseCase(
        companyId: companyId,
        collections: collections,
      );
      emit(
        state.copyWith(
          status: PlatformStatus.ready,
          clearMessage: true,
          clearActiveCompanyAction: true,
        ),
      );
      return data;
    } catch (error) {
      emit(
        state.copyWith(
          status: PlatformStatus.failure,
          message: _cleanError(error),
          clearActiveCompanyAction: true,
        ),
      );
      return null;
    }
  }

  @override
  Future<void> close() {
    _companiesSubscription?.cancel();
    _companyUsersSubscription?.cancel();
    _paymentHistorySubscription?.cancel();
    return super.close();
  }
}
