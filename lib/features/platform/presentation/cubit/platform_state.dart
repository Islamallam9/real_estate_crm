import 'package:equatable/equatable.dart';

import '../../../users/domain/entities/company_metadata.dart';
import '../../../app_update/domain/entities/android_release_policy.dart';
import '../../domain/entities/android_version_adoption.dart';
import '../../domain/entities/company_data_health_report.dart';
import '../../domain/entities/platform_company_user.dart';
import '../../domain/entities/platform_login_activity.dart';
import '../../domain/entities/platform_payment_history.dart';
import '../../domain/entities/release_intelligence.dart';

enum PlatformStatus { initial, loading, ready, saving, failure }

enum PlatformCompanyFilter {
  all,
  active,
  inactive,
  trial,
  trialExpired,
  paid,
  dueSoon,
  overdue,
  gracePeriod,
  suspended,
}

class PlatformState extends Equatable {
  const PlatformState({
    required this.status,
    this.companies = const [],
    this.companyUsers = const [],
    this.loginActivities = const [],
    this.paymentHistory = const [],
    this.selectedCompanyId,
    this.searchQuery = '',
    this.companyFilter = PlatformCompanyFilter.all,
    this.activeCompanyActionId,
    this.activeUserActionId,
    this.activeSettingsActionId,
    this.activeStorageActionId,
    this.dataHealthReport,
    this.androidReleasePolicy,
    this.androidVersionAdoption,
    this.releaseIntelligenceSummary,
    this.releaseAdoptionRows = const [],
    this.releaseDeviceRows = const [],
    this.releaseVersionEvents = const [],
    this.releaseCompanyId,
    this.dataHealthLoading = false,
    this.activeDataHealthActionId,
    this.message,
  });

  const PlatformState.initial() : this(status: PlatformStatus.initial);

  final PlatformStatus status;
  final List<CompanyMetadata> companies;
  final List<PlatformCompanyUser> companyUsers;
  final List<PlatformLoginActivity> loginActivities;
  final List<PlatformPaymentHistory> paymentHistory;
  final String? selectedCompanyId;
  final String searchQuery;
  final PlatformCompanyFilter companyFilter;
  final String? activeCompanyActionId;
  final String? activeUserActionId;
  final String? activeSettingsActionId;
  final String? activeStorageActionId;
  final CompanyDataHealthReport? dataHealthReport;
  final AndroidReleasePolicy? androidReleasePolicy;
  final AndroidVersionAdoptionSummary? androidVersionAdoption;
  final ReleaseIntelligenceSummary? releaseIntelligenceSummary;
  final List<VersionAdoptionRow> releaseAdoptionRows;
  final List<PlatformDeviceInstallRow> releaseDeviceRows;
  final List<DeviceVersionEventRow> releaseVersionEvents;
  final String? releaseCompanyId;
  final bool dataHealthLoading;
  final String? activeDataHealthActionId;
  final String? message;

  CompanyMetadata? get selectedCompany {
    final id = selectedCompanyId;
    if (id == null) {
      return companies.isEmpty ? null : companies.first;
    }

    for (final company in companies) {
      if (company.id == id) {
        return company;
      }
    }

    return companies.isEmpty ? null : companies.first;
  }

  List<CompanyMetadata> get filteredCompanies {
    final query = searchQuery.trim().toLowerCase();
    return companies.where((company) {
      final matchesQuery =
          query.isEmpty ||
          company.id.toLowerCase().contains(query) ||
          company.name.toLowerCase().contains(query) ||
          company.displayName.toLowerCase().contains(query);
      final matchesFilter = switch (companyFilter) {
        PlatformCompanyFilter.all => true,
        PlatformCompanyFilter.active => company.isUsable && company.status == 'active',
        PlatformCompanyFilter.inactive =>
          !company.isUsable || company.status == 'inactive' || company.status == 'trialExpired',
        PlatformCompanyFilter.trial => company.status == 'trial',
        PlatformCompanyFilter.trialExpired => company.status == 'trialExpired',
        PlatformCompanyFilter.paid => company.paymentStatus == 'paid',
        PlatformCompanyFilter.dueSoon => company.paymentStatus == 'dueSoon',
        PlatformCompanyFilter.overdue => company.paymentStatus == 'overdue',
        PlatformCompanyFilter.gracePeriod => company.paymentStatus == 'gracePeriod',
        PlatformCompanyFilter.suspended => company.paymentStatus == 'suspended',
      };
      return matchesQuery && matchesFilter;
    }).toList();
  }

  PlatformState copyWith({
    PlatformStatus? status,
    List<CompanyMetadata>? companies,
    List<PlatformCompanyUser>? companyUsers,
    List<PlatformLoginActivity>? loginActivities,
    List<PlatformPaymentHistory>? paymentHistory,
    String? selectedCompanyId,
    String? searchQuery,
    PlatformCompanyFilter? companyFilter,
    String? activeCompanyActionId,
    String? activeUserActionId,
    String? activeSettingsActionId,
    String? activeStorageActionId,
    CompanyDataHealthReport? dataHealthReport,
    AndroidReleasePolicy? androidReleasePolicy,
    AndroidVersionAdoptionSummary? androidVersionAdoption,
    ReleaseIntelligenceSummary? releaseIntelligenceSummary,
    List<VersionAdoptionRow>? releaseAdoptionRows,
    List<PlatformDeviceInstallRow>? releaseDeviceRows,
    List<DeviceVersionEventRow>? releaseVersionEvents,
    String? releaseCompanyId,
    bool? dataHealthLoading,
    String? activeDataHealthActionId,
    String? message,
    bool clearMessage = false,
    bool clearActiveCompanyAction = false,
    bool clearActiveUserAction = false,
    bool clearActiveSettingsAction = false,
    bool clearActiveStorageAction = false,
    bool clearDataHealthReport = false,
    bool clearActiveDataHealthAction = false,
    bool clearReleaseCompanyId = false,
  }) {
    return PlatformState(
      status: status ?? this.status,
      companies: companies ?? this.companies,
      companyUsers: companyUsers ?? this.companyUsers,
      loginActivities: loginActivities ?? this.loginActivities,
      paymentHistory: paymentHistory ?? this.paymentHistory,
      selectedCompanyId: selectedCompanyId ?? this.selectedCompanyId,
      searchQuery: searchQuery ?? this.searchQuery,
      companyFilter: companyFilter ?? this.companyFilter,
      activeCompanyActionId: clearActiveCompanyAction
          ? null
          : activeCompanyActionId ?? this.activeCompanyActionId,
      activeUserActionId: clearActiveUserAction
          ? null
          : activeUserActionId ?? this.activeUserActionId,
      activeSettingsActionId: clearActiveSettingsAction
          ? null
          : activeSettingsActionId ?? this.activeSettingsActionId,
      activeStorageActionId: clearActiveStorageAction
          ? null
          : activeStorageActionId ?? this.activeStorageActionId,
      dataHealthReport:
          clearDataHealthReport ? null : dataHealthReport ?? this.dataHealthReport,
      androidReleasePolicy: androidReleasePolicy ?? this.androidReleasePolicy,
      androidVersionAdoption:
          androidVersionAdoption ?? this.androidVersionAdoption,
      releaseIntelligenceSummary:
          releaseIntelligenceSummary ?? this.releaseIntelligenceSummary,
      releaseAdoptionRows: releaseAdoptionRows ?? this.releaseAdoptionRows,
      releaseDeviceRows: releaseDeviceRows ?? this.releaseDeviceRows,
      releaseVersionEvents: releaseVersionEvents ?? this.releaseVersionEvents,
      releaseCompanyId: clearReleaseCompanyId
          ? null
          : releaseCompanyId ?? this.releaseCompanyId,
      dataHealthLoading: dataHealthLoading ?? this.dataHealthLoading,
      activeDataHealthActionId: clearActiveDataHealthAction
          ? null
          : activeDataHealthActionId ?? this.activeDataHealthActionId,
      message: clearMessage ? null : message ?? this.message,
    );
  }

  @override
  List<Object?> get props => [
    status,
    companies,
    companyUsers,
    loginActivities,
    paymentHistory,
    selectedCompanyId,
    searchQuery,
    companyFilter,
    activeCompanyActionId,
    activeUserActionId,
    activeSettingsActionId,
    activeStorageActionId,
    dataHealthReport,
    androidReleasePolicy,
    androidVersionAdoption,
    releaseIntelligenceSummary,
    releaseAdoptionRows,
    releaseDeviceRows,
    releaseVersionEvents,
    releaseCompanyId,
    dataHealthLoading,
    activeDataHealthActionId,
    message,
  ];
}
