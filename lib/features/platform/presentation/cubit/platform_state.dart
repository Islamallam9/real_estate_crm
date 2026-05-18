import 'package:equatable/equatable.dart';

import '../../../users/domain/entities/company_metadata.dart';
import '../../domain/entities/company_data_health_report.dart';
import '../../domain/entities/platform_company_user.dart';

enum PlatformStatus { initial, loading, ready, saving, failure }

enum PlatformCompanyFilter { all, active, inactive, trial }

class PlatformState extends Equatable {
  const PlatformState({
    required this.status,
    this.companies = const [],
    this.companyUsers = const [],
    this.selectedCompanyId,
    this.searchQuery = '',
    this.companyFilter = PlatformCompanyFilter.all,
    this.activeCompanyActionId,
    this.activeUserActionId,
    this.activeSettingsActionId,
    this.dataHealthReport,
    this.dataHealthLoading = false,
    this.activeDataHealthActionId,
    this.message,
  });

  const PlatformState.initial() : this(status: PlatformStatus.initial);

  final PlatformStatus status;
  final List<CompanyMetadata> companies;
  final List<PlatformCompanyUser> companyUsers;
  final String? selectedCompanyId;
  final String searchQuery;
  final PlatformCompanyFilter companyFilter;
  final String? activeCompanyActionId;
  final String? activeUserActionId;
  final String? activeSettingsActionId;
  final CompanyDataHealthReport? dataHealthReport;
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
        PlatformCompanyFilter.active =>
          company.isActive && company.status != 'inactive',
        PlatformCompanyFilter.inactive =>
          !company.isActive || company.status == 'inactive',
        PlatformCompanyFilter.trial => company.status == 'trial',
      };
      return matchesQuery && matchesFilter;
    }).toList();
  }

  PlatformState copyWith({
    PlatformStatus? status,
    List<CompanyMetadata>? companies,
    List<PlatformCompanyUser>? companyUsers,
    String? selectedCompanyId,
    String? searchQuery,
    PlatformCompanyFilter? companyFilter,
    String? activeCompanyActionId,
    String? activeUserActionId,
    String? activeSettingsActionId,
    CompanyDataHealthReport? dataHealthReport,
    bool? dataHealthLoading,
    String? activeDataHealthActionId,
    String? message,
    bool clearMessage = false,
    bool clearActiveCompanyAction = false,
    bool clearActiveUserAction = false,
    bool clearActiveSettingsAction = false,
    bool clearDataHealthReport = false,
    bool clearActiveDataHealthAction = false,
  }) {
    return PlatformState(
      status: status ?? this.status,
      companies: companies ?? this.companies,
      companyUsers: companyUsers ?? this.companyUsers,
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
      dataHealthReport:
          clearDataHealthReport ? null : dataHealthReport ?? this.dataHealthReport,
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
    selectedCompanyId,
    searchQuery,
    companyFilter,
    activeCompanyActionId,
    activeUserActionId,
    activeSettingsActionId,
    dataHealthReport,
    dataHealthLoading,
    activeDataHealthActionId,
    message,
  ];
}
