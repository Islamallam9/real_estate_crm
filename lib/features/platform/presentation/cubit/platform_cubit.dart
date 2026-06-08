import 'dart:async';

import 'package:bloc/bloc.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/role_constants.dart';
import '../../../app_update/domain/entities/android_release_policy.dart';
import '../../domain/entities/android_version_adoption.dart';
import '../../domain/entities/platform_company_user.dart';
import '../../domain/entities/platform_login_activity.dart';
import '../../domain/entities/platform_payment_history.dart';
import '../../domain/usecases/add_user_to_company_usecase.dart';
import '../../domain/usecases/backfill_assigned_record_snapshots_usecase.dart';
import '../../domain/usecases/create_platform_release_record_usecase.dart';
import '../../domain/usecases/create_company_with_admin_usecase.dart';
import '../../domain/usecases/export_company_data_usecase.dart';
import '../../domain/usecases/extend_company_payment_due_date_usecase.dart';
import '../../domain/usecases/get_android_release_policy_usecase.dart';
import '../../domain/usecases/get_android_version_adoption_usecase.dart';
import '../../domain/entities/release_intelligence.dart';
import '../../domain/usecases/get_platform_device_list_usecase.dart';
import '../../domain/usecases/get_platform_version_adoption_usecase.dart';
import '../../domain/usecases/get_platform_version_history_usecase.dart';
import '../../domain/usecases/get_release_intelligence_summary_usecase.dart';
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
import '../../domain/usecases/update_android_release_policy_usecase.dart';
import '../../domain/usecases/watch_platform_companies_usecase.dart';
import '../../domain/usecases/watch_platform_company_users_usecase.dart';
import '../../domain/usecases/watch_platform_login_activity_usecase.dart';
import '../../domain/usecases/watch_platform_payment_history_usecase.dart';
import 'platform_state.dart';

class PlatformCubit extends Cubit<PlatformState> {
  PlatformCubit({
    required WatchPlatformCompaniesUseCase watchCompaniesUseCase,
    required WatchPlatformCompanyUsersUseCase watchCompanyUsersUseCase,
    required WatchPlatformPaymentHistoryUseCase watchPaymentHistoryUseCase,
    required WatchPlatformLoginActivityUseCase watchLoginActivityUseCase,
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
    required UpdateAndroidReleasePolicyUseCase updateAndroidReleasePolicyUseCase,
    required GetAndroidReleasePolicyUseCase getAndroidReleasePolicyUseCase,
    required GetAndroidVersionAdoptionUseCase
        getAndroidVersionAdoptionUseCase,
    required GetReleaseIntelligenceSummaryUseCase
        getReleaseIntelligenceSummaryUseCase,
    required GetPlatformVersionAdoptionUseCase
        getPlatformVersionAdoptionUseCase,
    required GetPlatformDeviceListUseCase getPlatformDeviceListUseCase,
    required GetPlatformVersionHistoryUseCase getPlatformVersionHistoryUseCase,
    required CreatePlatformReleaseRecordUseCase createPlatformReleaseRecordUseCase,
  }) : _watchCompaniesUseCase = watchCompaniesUseCase,
       _watchCompanyUsersUseCase = watchCompanyUsersUseCase,
       _watchPaymentHistoryUseCase = watchPaymentHistoryUseCase,
       _watchLoginActivityUseCase = watchLoginActivityUseCase,
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
       _updateAndroidReleasePolicyUseCase = updateAndroidReleasePolicyUseCase,
       _getAndroidReleasePolicyUseCase = getAndroidReleasePolicyUseCase,
       _getAndroidVersionAdoptionUseCase = getAndroidVersionAdoptionUseCase,
       _getReleaseIntelligenceSummaryUseCase =
           getReleaseIntelligenceSummaryUseCase,
       _getPlatformVersionAdoptionUseCase = getPlatformVersionAdoptionUseCase,
       _getPlatformDeviceListUseCase = getPlatformDeviceListUseCase,
       _getPlatformVersionHistoryUseCase = getPlatformVersionHistoryUseCase,
       _createPlatformReleaseRecordUseCase = createPlatformReleaseRecordUseCase,
       super(const PlatformState.initial());

  final WatchPlatformCompaniesUseCase _watchCompaniesUseCase;
  final WatchPlatformCompanyUsersUseCase _watchCompanyUsersUseCase;
  final WatchPlatformPaymentHistoryUseCase _watchPaymentHistoryUseCase;
  final WatchPlatformLoginActivityUseCase _watchLoginActivityUseCase;
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
  final UpdateAndroidReleasePolicyUseCase _updateAndroidReleasePolicyUseCase;
  final GetAndroidReleasePolicyUseCase _getAndroidReleasePolicyUseCase;
  final GetAndroidVersionAdoptionUseCase _getAndroidVersionAdoptionUseCase;
  final GetReleaseIntelligenceSummaryUseCase
      _getReleaseIntelligenceSummaryUseCase;
  final GetPlatformVersionAdoptionUseCase _getPlatformVersionAdoptionUseCase;
  final GetPlatformDeviceListUseCase _getPlatformDeviceListUseCase;
  final GetPlatformVersionHistoryUseCase _getPlatformVersionHistoryUseCase;
  final CreatePlatformReleaseRecordUseCase _createPlatformReleaseRecordUseCase;

  StreamSubscription? _companiesSubscription;
  StreamSubscription? _companyUsersSubscription;
  StreamSubscription? _paymentHistorySubscription;
  StreamSubscription? _loginActivitySubscription;
  String? _companyUsersSubscriptionCompanyId;
  String? _paymentHistorySubscriptionCompanyId;
  String? _loginActivitySubscriptionCompanyId;
  final Map<String, List<PlatformCompanyUser>> _companyUsersCache = {};
  final Map<String, List<PlatformPaymentHistory>> _paymentHistoryCache = {};
  final Map<String, List<PlatformLoginActivity>> _loginActivityCache = {};

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
        final selectedChanged = selectedId != nextSelectedId;
        if (selectedChanged) {
          _cancelSelectedCompanyStreams();
        }
        final cachedUsers = _companyUsersCache[nextSelectedId];
        final cachedPayments = _paymentHistoryCache[nextSelectedId];
        final cachedLogins = _loginActivityCache[nextSelectedId];

        emit(
          state.copyWith(
            status: PlatformStatus.ready,
            companies: companies,
            selectedCompanyId: nextSelectedId,
            clearSelectedCompanyId: nextSelectedId == null,
            companyUsers: selectedChanged ? cachedUsers ?? const [] : null,
            paymentHistory: selectedChanged ? cachedPayments ?? const [] : null,
            loginActivities: selectedChanged ? cachedLogins ?? const [] : null,
            companyUsersCompanyId:
                selectedChanged && cachedUsers != null ? nextSelectedId : null,
            paymentHistoryCompanyId:
                selectedChanged && cachedPayments != null ? nextSelectedId : null,
            loginActivitiesCompanyId:
                selectedChanged && cachedLogins != null ? nextSelectedId : null,
            clearCompanyUsersCompanyId: selectedChanged && cachedUsers == null,
            clearPaymentHistoryCompanyId: selectedChanged && cachedPayments == null,
            clearLoginActivitiesCompanyId: selectedChanged && cachedLogins == null,
            companyUsersLoading: selectedChanged ? false : null,
            paymentHistoryLoading: selectedChanged ? false : null,
            loginActivitiesLoading: selectedChanged ? false : null,
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

  void selectCompany(String companyId) {
    if (state.selectedCompanyId == companyId) {
      return;
    }
    _cancelSelectedCompanyStreams();
    final cachedUsers = _companyUsersCache[companyId];
    final cachedPayments = _paymentHistoryCache[companyId];
    final cachedLogins = _loginActivityCache[companyId];
    emit(
      state.copyWith(
        selectedCompanyId: companyId,
        companyUsers: cachedUsers ?? const [],
        loginActivities: cachedLogins ?? const [],
        paymentHistory: cachedPayments ?? const [],
        companyUsersCompanyId: cachedUsers == null ? null : companyId,
        loginActivitiesCompanyId: cachedLogins == null ? null : companyId,
        paymentHistoryCompanyId: cachedPayments == null ? null : companyId,
        clearCompanyUsersCompanyId: cachedUsers == null,
        clearLoginActivitiesCompanyId: cachedLogins == null,
        clearPaymentHistoryCompanyId: cachedPayments == null,
        companyUsersLoading: false,
        loginActivitiesLoading: false,
        paymentHistoryLoading: false,
        clearDataHealthReport: true,
        clearMessage: true,
      ),
    );
    if (state.androidReleasePolicy != null) {
      unawaited(loadReleaseCenter());
    }
  }

  void updateSearchQuery(String query) {
    emit(state.copyWith(searchQuery: query, clearMessage: true));
  }

  void updateCompanyFilter(PlatformCompanyFilter filter) {
    emit(state.copyWith(companyFilter: filter, clearMessage: true));
  }

  void watchCompanyUsers(String companyId) {
    ensureCompanyUsersLoaded(companyId);
  }

  void ensureCompanyUsersLoaded(String companyId) {
    if (state.selectedCompanyId != companyId ||
        _companyUsersSubscriptionCompanyId == companyId) {
      return;
    }
    _companyUsersSubscription?.cancel();
    _companyUsersSubscriptionCompanyId = companyId;
    final cachedUsers = _companyUsersCache[companyId];
    emit(
      state.copyWith(
        companyUsers: cachedUsers ?? const [],
        companyUsersCompanyId: cachedUsers == null ? null : companyId,
        clearCompanyUsersCompanyId: cachedUsers == null,
        companyUsersLoading: cachedUsers == null,
        clearMessage: true,
      ),
    );
    _companyUsersSubscription = _watchCompanyUsersUseCase(companyId: companyId)
        .listen(
          (users) {
            _companyUsersCache[companyId] = users;
            if (state.selectedCompanyId == companyId) {
              emit(
                state.copyWith(
                  status: PlatformStatus.ready,
                  companyUsers: users,
                  companyUsersCompanyId: companyId,
                  companyUsersLoading: false,
                  clearMessage: true,
                ),
              );
            }
          },
          onError: (Object error) {
            if (state.selectedCompanyId == companyId) {
              emit(
                state.copyWith(
                  status: PlatformStatus.failure,
                  companyUsersLoading: false,
                  message: _cleanError(error),
                ),
              );
            }
          },
        );
  }

  void watchPaymentHistory(String companyId) {
    ensurePaymentHistoryLoaded(companyId);
  }

  void ensurePaymentHistoryLoaded(String companyId) {
    if (state.selectedCompanyId != companyId ||
        _paymentHistorySubscriptionCompanyId == companyId) {
      return;
    }
    _paymentHistorySubscription?.cancel();
    _paymentHistorySubscriptionCompanyId = companyId;
    final cachedHistory = _paymentHistoryCache[companyId];
    emit(
      state.copyWith(
        paymentHistory: cachedHistory ?? const [],
        paymentHistoryCompanyId: cachedHistory == null ? null : companyId,
        clearPaymentHistoryCompanyId: cachedHistory == null,
        paymentHistoryLoading: cachedHistory == null,
        clearMessage: true,
      ),
    );
    _paymentHistorySubscription = _watchPaymentHistoryUseCase(companyId: companyId)
        .listen(
          (history) {
            _paymentHistoryCache[companyId] = history;
            if (state.selectedCompanyId == companyId) {
              emit(
                state.copyWith(
                  status: PlatformStatus.ready,
                  paymentHistory: history,
                  paymentHistoryCompanyId: companyId,
                  paymentHistoryLoading: false,
                  clearMessage: true,
                ),
              );
            }
          },
          onError: (Object error) {
            if (state.selectedCompanyId == companyId) {
              emit(
                state.copyWith(
                  status: PlatformStatus.failure,
                  paymentHistoryLoading: false,
                  message: _cleanError(error),
                ),
              );
            }
          },
        );
  }

  void watchLoginActivity(String companyId) {
    ensureLoginActivityLoaded(companyId);
  }

  void ensureLoginActivityLoaded(String companyId) {
    if (state.selectedCompanyId != companyId ||
        _loginActivitySubscriptionCompanyId == companyId) {
      return;
    }
    _loginActivitySubscription?.cancel();
    _loginActivitySubscriptionCompanyId = companyId;
    final cachedActivities = _loginActivityCache[companyId];
    emit(
      state.copyWith(
        loginActivities: cachedActivities ?? const [],
        loginActivitiesCompanyId: cachedActivities == null ? null : companyId,
        clearLoginActivitiesCompanyId: cachedActivities == null,
        loginActivitiesLoading: cachedActivities == null,
        clearMessage: true,
      ),
    );
    _loginActivitySubscription = _watchLoginActivityUseCase(companyId: companyId)
        .listen(
          (activities) {
            _loginActivityCache[companyId] = activities;
            if (state.selectedCompanyId == companyId) {
              emit(
                state.copyWith(
                  status: PlatformStatus.ready,
                  loginActivities: activities,
                  loginActivitiesCompanyId: companyId,
                  loginActivitiesLoading: false,
                  clearMessage: true,
                ),
              );
            }
          },
          onError: (Object error) {
            if (state.selectedCompanyId == companyId) {
              emit(
                state.copyWith(
                  status: PlatformStatus.failure,
                  loginActivitiesLoading: false,
                  message: _cleanError(error),
                ),
              );
            }
          },
        );
  }

  void clearOwnerSessionCache() {
    _cancelSelectedCompanyStreams();
    _companyUsersCache.clear();
    _paymentHistoryCache.clear();
    _loginActivityCache.clear();
    emit(
      state.copyWith(
        companyUsers: const [],
        paymentHistory: const [],
        loginActivities: const [],
        companyUsersLoading: false,
        paymentHistoryLoading: false,
        loginActivitiesLoading: false,
        clearCompanyUsersCompanyId: true,
        clearPaymentHistoryCompanyId: true,
        clearLoginActivitiesCompanyId: true,
        clearMessage: true,
      ),
    );
  }

  void _cancelSelectedCompanyStreams() {
    _companyUsersSubscription?.cancel();
    _paymentHistorySubscription?.cancel();
    _loginActivitySubscription?.cancel();
    _companyUsersSubscription = null;
    _paymentHistorySubscription = null;
    _loginActivitySubscription = null;
    _companyUsersSubscriptionCompanyId = null;
    _paymentHistorySubscriptionCompanyId = null;
    _loginActivitySubscriptionCompanyId = null;
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
    final success = await _save(() {
      return _addUserToCompanyUseCase(
        companyId: companyId,
        fullName: fullName,
        email: email,
        phone: phone,
        role: role,
      );
    });
    if (success) {
      _companyUsersCache.remove(companyId);
    }
    return success;
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
      _companyUsersCache.remove(companyId);
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
    final success = await _save(() {
      return _setCompanyUserEmailUseCase(
        companyId: companyId,
        uid: uid,
        newEmail: newEmail,
      );
    });
    if (success) {
      _companyUsersCache.remove(companyId);
    }
    return success;
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

  Future<void> loadAndroidReleasePolicy() => loadReleaseCenter();

  Future<void> loadReleaseCenter() async {
    emit(
      state.copyWith(
        activeSettingsActionId: 'androidRelease:load',
        clearMessage: true,
      ),
    );
    try {
      final companyId = state.releaseCompanyId;
      final results = await Future.wait([
        _getAndroidReleasePolicyUseCase(),
        _getAndroidVersionAdoptionUseCase(),
        _getReleaseIntelligenceSummaryUseCase(),
        _getPlatformVersionAdoptionUseCase(companyId: companyId),
        _getPlatformDeviceListUseCase(companyId: companyId),
        _getPlatformVersionHistoryUseCase(companyId: companyId),
      ]);
      emit(
        state.copyWith(
          status: PlatformStatus.ready,
          androidReleasePolicy: results[0] as AndroidReleasePolicy,
          androidVersionAdoption:
              results[1] as AndroidVersionAdoptionSummary,
          releaseIntelligenceSummary:
              results[2] as ReleaseIntelligenceSummary,
          releaseAdoptionRows: results[3] as List<VersionAdoptionRow>,
          releaseDeviceRows: results[4] as List<PlatformDeviceInstallRow>,
          releaseVersionEvents: results[5] as List<DeviceVersionEventRow>,
          clearActiveSettingsAction: true,
          clearMessage: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: PlatformStatus.failure,
          message: _cleanError(error),
          clearActiveSettingsAction: true,
        ),
      );
    }
  }

  Future<void> updateReleaseCompanyFilter(String? companyId) async {
    emit(
      state.copyWith(
        releaseCompanyId:
            companyId == null || companyId.trim().isEmpty ? null : companyId,
        clearReleaseCompanyId: companyId == null || companyId.trim().isEmpty,
        clearMessage: true,
      ),
    );
    await loadReleaseCenter();
  }

  Future<bool> createReleaseRecordFromAndroidPolicy() async {
    final policy = state.androidReleasePolicy;
    if (policy == null) {
      return false;
    }
    emit(
      state.copyWith(
        status: PlatformStatus.saving,
        activeSettingsActionId: 'releaseRecord:androidPolicy',
        clearMessage: true,
      ),
    );
    try {
      await _createPlatformReleaseRecordUseCase(
        platform: 'android',
        appVersion: AppConstants.appVersion,
        buildNumber: policy.latestBuildNumber,
        minimumSupportedBuildNumber: policy.minimumSupportedBuildNumber,
        latestBuildNumber: policy.latestBuildNumber,
        updateUrl: policy.updateUrl,
        enabled: policy.enabled,
        releaseReady: policy.releaseReady,
        status: policy.releaseReady ? 'ready' : 'draft',
      );
      emit(
        state.copyWith(
          status: PlatformStatus.ready,
          clearActiveSettingsAction: true,
          clearMessage: true,
        ),
      );
      await loadReleaseCenter();
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

  Future<bool> updateAndroidReleasePolicy({
    required bool enabled,
    required bool releaseReady,
    required int minimumSupportedBuildNumber,
    required int latestBuildNumber,
    required String updateUrl,
    required String titleEn,
    required String titleAr,
    required String bodyEn,
    required String bodyAr,
  }) async {
    emit(
      state.copyWith(
        status: PlatformStatus.saving,
        activeSettingsActionId: 'androidRelease',
        clearMessage: true,
      ),
    );
    try {
      await _updateAndroidReleasePolicyUseCase(
        enabled: enabled,
        releaseReady: releaseReady,
        minimumSupportedBuildNumber: minimumSupportedBuildNumber,
        latestBuildNumber: latestBuildNumber,
        updateUrl: updateUrl,
        titleEn: titleEn,
        titleAr: titleAr,
        bodyEn: bodyEn,
        bodyAr: bodyAr,
      );
      final results = await Future.wait([
        _getAndroidReleasePolicyUseCase(),
        _getAndroidVersionAdoptionUseCase(),
        _getReleaseIntelligenceSummaryUseCase(),
        _getPlatformVersionAdoptionUseCase(companyId: state.releaseCompanyId),
        _getPlatformDeviceListUseCase(companyId: state.releaseCompanyId),
        _getPlatformVersionHistoryUseCase(companyId: state.releaseCompanyId),
      ]);
      emit(
        state.copyWith(
          status: PlatformStatus.ready,
          androidReleasePolicy: results[0] as AndroidReleasePolicy,
          androidVersionAdoption:
              results[1] as AndroidVersionAdoptionSummary,
          releaseIntelligenceSummary:
              results[2] as ReleaseIntelligenceSummary,
          releaseAdoptionRows: results[3] as List<VersionAdoptionRow>,
          releaseDeviceRows: results[4] as List<PlatformDeviceInstallRow>,
          releaseVersionEvents: results[5] as List<DeviceVersionEventRow>,
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
      _paymentHistoryCache.remove(companyId);
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
    _cancelSelectedCompanyStreams();
    _companyUsersCache.clear();
    _paymentHistoryCache.clear();
    _loginActivityCache.clear();
    return super.close();
  }
}
