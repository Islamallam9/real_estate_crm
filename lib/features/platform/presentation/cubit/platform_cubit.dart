import 'dart:async';

import 'package:bloc/bloc.dart';

import '../../../../core/constants/role_constants.dart';
import '../../domain/usecases/add_user_to_company_usecase.dart';
import '../../domain/usecases/backfill_assigned_record_snapshots_usecase.dart';
import '../../domain/usecases/create_company_with_admin_usecase.dart';
import '../../domain/usecases/get_company_data_health_report_usecase.dart';
import '../../domain/usecases/generate_company_user_password_reset_link_usecase.dart';
import '../../domain/usecases/set_company_active_status_usecase.dart';
import '../../domain/usecases/set_company_user_active_status_usecase.dart';
import '../../domain/usecases/set_company_user_email_usecase.dart';
import '../../domain/usecases/set_company_user_password_usecase.dart';
import '../../domain/usecases/update_company_platform_settings_usecase.dart';
import '../../domain/usecases/watch_platform_companies_usecase.dart';
import '../../domain/usecases/watch_platform_company_users_usecase.dart';
import 'platform_state.dart';

class PlatformCubit extends Cubit<PlatformState> {
  PlatformCubit({
    required WatchPlatformCompaniesUseCase watchCompaniesUseCase,
    required WatchPlatformCompanyUsersUseCase watchCompanyUsersUseCase,
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
  }) : _watchCompaniesUseCase = watchCompaniesUseCase,
       _watchCompanyUsersUseCase = watchCompanyUsersUseCase,
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
       super(const PlatformState.initial());

  final WatchPlatformCompaniesUseCase _watchCompaniesUseCase;
  final WatchPlatformCompanyUsersUseCase _watchCompanyUsersUseCase;
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

  StreamSubscription? _companiesSubscription;
  StreamSubscription? _companyUsersSubscription;

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
        }
      },
      onError: (Object error) {
        emit(
          state.copyWith(
            status: PlatformStatus.failure,
            message: error.toString(),
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
        clearDataHealthReport: true,
        clearMessage: true,
      ),
    );
    watchCompanyUsers(companyId);
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
                message: error.toString(),
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
          message: error.toString(),
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
          message: error.toString(),
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
          message: error.toString(),
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
          message: error.toString(),
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
          message: error.toString(),
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
          message: error.toString(),
          clearActiveDataHealthAction: true,
        ),
      );
      return false;
    }
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
          message: error.toString(),
        ),
      );
      return false;
    }
  }

  @override
  Future<void> close() {
    _companiesSubscription?.cancel();
    _companyUsersSubscription?.cancel();
    return super.close();
  }
}
