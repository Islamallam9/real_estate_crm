import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/auth/protected_company_session.dart';
import '../../../../core/constants/role_constants.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_pagination_footer.dart';
import '../../../../core/widgets/app_dropdown.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_search_field.dart';
import '../../../../core/widgets/app_status_badge.dart';
import '../../../../core/widgets/crm_app_shell.dart';
import '../../../../core/widgets/module_kpi_card.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../users/data/datasources/user_profile_remote_data_source.dart';
import '../../../users/data/repositories/user_profile_repository_impl.dart';
import '../../../users/domain/entities/user_profile.dart';
import '../../../users/domain/usecases/watch_active_users_usecase.dart';
import '../../domain/entities/audit_log.dart';
import '../cubit/audit_logs_cubit.dart';
import '../cubit/audit_logs_state.dart';
import '../widgets/audit_logs_scope.dart';

enum _AuditDateRangePreset { today, last7Days, last30Days, custom }

const List<_AuditModuleFilterOption> _auditModuleFilterOptions =
    <_AuditModuleFilterOption>[
  _AuditModuleFilterOption.all(),
  _AuditModuleFilterOption(AuditLogModule.leads),
  _AuditModuleFilterOption(AuditLogModule.clients),
  _AuditModuleFilterOption(AuditLogModule.properties),
  _AuditModuleFilterOption(AuditLogModule.tasks),
  _AuditModuleFilterOption(AuditLogModule.deals),
  _AuditModuleFilterOption(AuditLogModule.appointments),
  _AuditModuleFilterOption(AuditLogModule.users),
  _AuditModuleFilterOption(AuditLogModule.teams),
  _AuditModuleFilterOption(AuditLogModule.reports),
  _AuditModuleFilterOption(AuditLogModule.exports),
  _AuditModuleFilterOption(AuditLogModule.auditLogs),
  _AuditModuleFilterOption(AuditLogModule.other),
];

const List<_AuditActionFilterOption> _auditActionFilterOptions =
    <_AuditActionFilterOption>[
  _AuditActionFilterOption.all(),
  _AuditActionFilterOption(AuditLogAction.create),
  _AuditActionFilterOption(AuditLogAction.update),
  _AuditActionFilterOption(AuditLogAction.assign),
  _AuditActionFilterOption(AuditLogAction.statusChange),
  _AuditActionFilterOption(AuditLogAction.stageChange),
  _AuditActionFilterOption(AuditLogAction.archive),
  _AuditActionFilterOption(AuditLogAction.deactivate),
  _AuditActionFilterOption(AuditLogAction.complete),
  _AuditActionFilterOption(AuditLogAction.cancel),
  _AuditActionFilterOption(AuditLogAction.exported),
  _AuditActionFilterOption(AuditLogAction.exportGenerated),
];

class _AuditModuleFilterOption {
  const _AuditModuleFilterOption(this.module);
  const _AuditModuleFilterOption.all() : module = null;

  final AuditLogModule? module;
  bool get isAll => module == null;
}

class _AuditActionFilterOption {
  const _AuditActionFilterOption(this.action);
  const _AuditActionFilterOption.all() : action = null;

  final AuditLogAction? action;
  bool get isAll => action == null;
}

class _AuditFilterSelection {
  const _AuditFilterSelection({
    required this.dateRange,
    required this.customRange,
    required this.module,
    required this.action,
    required this.actorId,
  });

  const _AuditFilterSelection.defaults()
      : dateRange = _AuditDateRangePreset.last7Days,
        customRange = null,
        module = null,
        action = null,
        actorId = '';

  final _AuditDateRangePreset dateRange;
  final DateTimeRange? customRange;
  final AuditLogModule? module;
  final AuditLogAction? action;
  final String actorId;
}

class AuditLogsPage extends StatelessWidget {
  const AuditLogsPage({super.key, this.initialFocusAuditId = ''});

  final String initialFocusAuditId;

  static Widget withDependencies({String? initialFocusAuditId}) {
    return AuditLogsScope(
      child: AuditLogsPage(initialFocusAuditId: initialFocusAuditId ?? ''),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return CrmAppShell(
      selectedItem: CrmNavigationItem.auditLogs,
      title: l.auditLogs,
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          if (authState.isWaitingForProtectedCompanySession) {
            return const AppLoading();
          }

          final session = authState.protectedCompanySession;
          if (session == null) {
            return const AppLoading();
          }

          final profile = session.profile;
          if (!_canViewAuditLogs(profile.role)) {
            return AppErrorView(
              title: l.auditLogs,
              message: l.auditLogPermissionMessage,
              onRetry: () => context.go(RouteNames.dashboard),
            );
          }

          return _AuditLogsContent(
            key: ValueKey(session.scopeKey('audit-logs')),
            profile: profile,
            companyId: session.companyId,
            initialFocusAuditId: initialFocusAuditId,
          );
        },
      ),
    );
  }
}

class _AuditLogsContent extends StatefulWidget {
  const _AuditLogsContent({
    super.key,
    required this.profile,
    required this.companyId,
    required this.initialFocusAuditId,
  });

  final UserProfile profile;
  final String companyId;
  final String initialFocusAuditId;

  @override
  State<_AuditLogsContent> createState() => _AuditLogsContentState();
}

class _AuditLogsContentState extends State<_AuditLogsContent> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<List<UserProfile>> _filterUsersNotifier =
      ValueNotifier<List<UserProfile>>(const <UserProfile>[]);
  _AuditDateRangePreset _dateRange = _AuditDateRangePreset.last7Days;
  DateTimeRange? _customRange;
  AuditLogModule? _module;
  AuditLogAction? _action;
  String _actorId = '';
  String _search = '';
  bool _showImportantOnly = false;
  String _openedFocusAuditId = '';
  String _watchKey = '';
  String _usersStreamKey = '';
  StreamSubscription<List<UserProfile>>? _usersSubscription;
  List<UserProfile> _filterUsers = const <UserProfile>[];
  int _initialWatchGeneration = 0;
  bool _showBackToTop = false;
  Timer? _searchFetchTimer;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScrollPosition);
    _scheduleInitialWatch();
  }

  @override
  void didUpdateWidget(covariant _AuditLogsContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.companyId != widget.companyId ||
        oldWidget.profile.uid != widget.profile.uid ||
        oldWidget.profile.role != widget.profile.role ||
        oldWidget.profile.teamId != widget.profile.teamId ||
        oldWidget.profile.managerId != widget.profile.managerId) {
      _watchKey = '';
      _resetFilterUsersWatch();
      _scheduleInitialWatch();
    }
  }

  @override
  void dispose() {
    _initialWatchGeneration++;
    _searchFetchTimer?.cancel();
    unawaited(_usersSubscription?.cancel());
    _scrollController.removeListener(_handleScrollPosition);
    _scrollController.dispose();
    _searchController.dispose();
    _filterUsersNotifier.dispose();
    super.dispose();
  }

  void _handleScrollPosition() {
    if (!_scrollController.hasClients) {
      return;
    }
    final shouldShow = _scrollController.offset > 720;
    if (shouldShow != _showBackToTop && mounted) {
      setState(() => _showBackToTop = shouldShow);
    }
  }

  void _scrollToTop() {
    if (!_scrollController.hasClients) {
      return;
    }
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  void _scheduleInitialWatch() {
    final generation = ++_initialWatchGeneration;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(
        Future<void>.delayed(const Duration(milliseconds: 120), () {
          if (!mounted || generation != _initialWatchGeneration) {
            return;
          }
          _watchLogs();
        }),
      );
    });
  }

  void _resetFilterUsersWatch() {
    _usersStreamKey = '';
    unawaited(_usersSubscription?.cancel());
    _usersSubscription = null;
    _filterUsers = const <UserProfile>[];
    _filterUsersNotifier.value = const <UserProfile>[];
  }

  void _startFilterUsersWatch() {
    if (widget.profile.role != UserRole.admin) {
      return;
    }
    final key =
        '${widget.companyId}:${widget.profile.uid}:${widget.profile.role.name}:${widget.profile.teamId}';
    if (_usersStreamKey == key && _usersSubscription != null) {
      return;
    }
    _resetFilterUsersWatch();
    _usersStreamKey = key;
    final repository = UserProfileRepositoryImpl(
      remoteDataSource: FirestoreUserProfileRemoteDataSource(),
    );
    _usersSubscription = WatchActiveUsersUseCase(repository)(
      companyId: widget.companyId,
    ).listen(
      (users) {
        if (!mounted || _usersStreamKey != key) {
          return;
        }
        _filterUsers = users;
        _filterUsersNotifier.value = users;
      },
      onError: (_, __) {
        if (!mounted || _usersStreamKey != key) {
          return;
        }
        _usersSubscription = null;
        _filterUsers = const <UserProfile>[];
        _filterUsersNotifier.value = const <UserProfile>[];
      },
      onDone: () {
        if (!mounted || _usersStreamKey != key) {
          return;
        }
        _usersSubscription = null;
      },
    );
  }

  void _watchLogs({bool force = false}) {
    if (!mounted || widget.companyId.trim().isEmpty) {
      return;
    }
    final isManager = widget.profile.role == UserRole.manager;
    final hasSearchFilter = _search.trim().isNotEmpty;
    final searchAffectsFetchLimit = _adminSearchAffectsFetchLimit;
    final window = _dateWindow();
    final key = [
      widget.companyId,
      widget.profile.uid,
      widget.profile.role.name,
      widget.profile.teamId,
      _dateRange.name,
      window?.start.toIso8601String() ?? '',
      window?.end.toIso8601String() ?? '',
      _module?.name ?? '',
      _action?.name ?? '',
      _actorId,
      searchAffectsFetchLimit && hasSearchFilter ? 'search' : '',
    ].join('|');
    if (!force && _watchKey == key) {
      return;
    }
    _watchKey = key;
    context.read<AuditLogsCubit>().watchAuditLogs(
          companyId: widget.companyId,
          managerId: isManager ? widget.profile.uid : null,
          teamId: isManager ? widget.profile.teamId : null,
          module: _module,
          action: _action,
          actorId: _actorId,
          hasSearchFilter: hasSearchFilter,
          startAt: window?.start,
          endAt: window?.end,
          limit: AuditLogsCubit.defaultPageLimit,
          resetPage: true,
          force: force,
        );
  }

  void _loadMoreLogs() {
    context.read<AuditLogsCubit>().loadMoreAuditLogs();
  }

  bool get _adminSearchAffectsFetchLimit {
    return widget.profile.role == UserRole.admin &&
        _module == null &&
        _action == null &&
        _actorId.trim().isEmpty;
  }

  _AuditDateWindow? _dateWindow() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return switch (_dateRange) {
      _AuditDateRangePreset.today =>
        _AuditDateWindow(today, today.add(const Duration(days: 1))),
      _AuditDateRangePreset.last7Days => _AuditDateWindow(
          today.subtract(const Duration(days: 6)),
          today.add(const Duration(days: 1)),
        ),
      _AuditDateRangePreset.last30Days => _AuditDateWindow(
          today.subtract(const Duration(days: 29)),
          today.add(const Duration(days: 1)),
        ),
      _AuditDateRangePreset.custom => _customRange == null
          ? _AuditDateWindow(
              today.subtract(const Duration(days: 6)),
              today.add(const Duration(days: 1)),
            )
          : _AuditDateWindow(
              DateTime(
                _customRange!.start.year,
                _customRange!.start.month,
                _customRange!.start.day,
              ),
              DateTime(
                _customRange!.end.year,
                _customRange!.end.month,
                _customRange!.end.day,
              ).add(const Duration(days: 1)),
            ),
    };
  }

  List<AuditLog> _visibleLogs(List<AuditLog> logs) {
    final importantFiltered = _showImportantOnly
        ? logs.where(_isImportantLog).toList(growable: false)
        : logs;
    final query = _search.trim().toLowerCase();
    if (query.isEmpty) {
      return importantFiltered;
    }
    final l = AppLocalizations.of(context)!;
    return importantFiltered.where((log) {
      final haystack = [
        log.recordTitle,
        log.recordSubtitle,
        log.actorName,
        log.actorEmail,
        _moduleLabel(l, log.module),
        _actionLabel(l, log.action),
        _detailsSummary(l, log),
      ].join(' ').toLowerCase();
      return haystack.contains(query);
    }).toList(growable: false);
  }

  void _handleSearchChanged(String value) {
    final hadSearchFilter = _search.trim().isNotEmpty;
    final hasSearchFilter = value.trim().isNotEmpty;
    final shouldRefreshFetchLimit =
        _adminSearchAffectsFetchLimit && hadSearchFilter != hasSearchFilter;
    setState(() => _search = value);
    if (shouldRefreshFetchLimit) {
      _searchFetchTimer?.cancel();
      _searchFetchTimer = Timer(const Duration(milliseconds: 250), () {
        if (mounted) {
          _watchLogs();
        }
      });
    }
  }

  void _clearSearch() {
    final hadSearchFilter = _search.trim().isNotEmpty;
    final shouldRefreshFetchLimit =
        _adminSearchAffectsFetchLimit && hadSearchFilter;
    _searchFetchTimer?.cancel();
    _searchController.clear();
    setState(() => _search = '');
    if (shouldRefreshFetchLimit) {
      _watchLogs();
    }
  }

  void _applyFilterSelection(_AuditFilterSelection selection) {
    _searchFetchTimer?.cancel();
    setState(() {
      _dateRange = selection.dateRange;
      _customRange = selection.customRange;
      _module = selection.module;
      _action = selection.action;
      _actorId = selection.actorId;
      _showImportantOnly = false;
    });
    _watchLogs();
  }

  void _clearFilters() {
    _searchFetchTimer?.cancel();
    setState(() {
      _dateRange = _AuditDateRangePreset.last7Days;
      _customRange = null;
      _module = null;
      _action = null;
      _actorId = '';
      _search = '';
      _showImportantOnly = false;
      _searchController.clear();
    });
    _watchLogs();
  }

  void _showTodayActivity() {
    _applyFilterSelection(
      const _AuditFilterSelection(dateRange: _AuditDateRangePreset.today, customRange: null, module: null, action: null, actorId: ''),
    );
  }

  void _showExportActivity() {
    _applyFilterSelection(
      const _AuditFilterSelection(
        dateRange: _AuditDateRangePreset.last7Days,
        customRange: null,
        module: AuditLogModule.exports,
        action: null,
        actorId: '',
      ),
    );
  }

  void _showImportantActivity() {
    _searchFetchTimer?.cancel();
    setState(() {
      _dateRange = _AuditDateRangePreset.last7Days;
      _customRange = null;
      _module = null;
      _action = null;
      _actorId = '';
      _search = '';
      _showImportantOnly = true;
      _searchController.clear();
    });
    _watchLogs();
  }

  void _maybeOpenFocusedLog(List<AuditLog> logs, bool isAdmin) {
    final focusId = widget.initialFocusAuditId.trim();
    if (focusId.isEmpty || _openedFocusAuditId == focusId) {
      return;
    }
    AuditLog? focused;
    for (final log in logs) {
      if (log.id == focusId) {
        focused = log;
        break;
      }
    }
    if (focused == null) {
      return;
    }
    _openedFocusAuditId = focusId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _showAuditDetails(context, focused!, isAdmin: isAdmin);
      }
    });
  }

  Future<DateTimeRange?> _pickCustomRange(DateTimeRange? initialRange) async {
    final now = DateTime.now();
    final initial = initialRange ??
        DateTimeRange(
          start: now.subtract(const Duration(days: 6)),
          end: now,
        );
    final selected = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
      initialDateRange: initial,
    );
    if (!mounted) {
      return null;
    }
    return selected;
  }

  Future<void> _openFilters(List<AuditLog> logs) async {
    final isAdmin = widget.profile.role == UserRole.admin;
    if (isAdmin) {
      _startFilterUsersWatch();
    }
    final baseUsers = isAdmin ? _filterUsers : <UserProfile>[widget.profile];
    final selection = await _showAuditFiltersSheet(
      context,
      dateRange: _dateRange,
      customRange: _customRange,
      module: _module,
      action: _action,
      actorId: _actorId,
      users: _mergeUsersWithLogActors(baseUsers, logs),
      usersListenable: isAdmin ? _filterUsersNotifier : null,
      logs: logs,
      onPickCustomRange: _pickCustomRange,
    );
    if (!mounted || selection == null) {
      return;
    }
    _applyFilterSelection(selection);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return BlocBuilder<AuditLogsCubit, AuditLogsState>(
      builder: (context, state) {
        final visibleLogs = _visibleLogs(state.logs);
        final hasLocalVisibleFilter =
            _search.trim().isNotEmpty || _showImportantOnly;
        final showLoadMore = state.canLoadMore &&
            !hasLocalVisibleFilter &&
            visibleLogs.length >= AuditLogsCubit.defaultPageLimit;
        final isInitialLoading = state.status == AuditLogsStatus.initial ||
            state.status == AuditLogsStatus.loading && state.logs.isEmpty;
        if (state.status == AuditLogsStatus.failure && state.logs.isEmpty) {
          return AppErrorView(
            title: l.auditLogs,
            message: l.auditLogsLoadFailed,
            onRetry: () => _watchLogs(force: true),
          );
        }

        _maybeOpenFocusedLog(
          visibleLogs,
          widget.profile.role == UserRole.admin,
        );

        return Stack(
          children: [
            ListView(
              controller: _scrollController,
              padding: EdgeInsets.zero,
              children: [
                _AuditHeader(
                  logs: visibleLogs,
                  dateRangeLabel: _dateRangeLabel(l),
                  onVisibleTap: _clearFilters,
                  onTodayTap: _showTodayActivity,
                  onExportTap: _showExportActivity,
                  onImportantTap: _showImportantActivity,
                ),
                const SizedBox(height: AppSpacing.sm),
                _AuditFilters(
                  dateRange: _dateRange,
                  module: _module,
                  action: _action,
                  actorId: _actorId,
                  showImportantOnly: _showImportantOnly,
                  searchController: _searchController,
                  search: _search,
                  onOpenFilters: () => _openFilters(state.logs),
                  onSearchChanged: _handleSearchChanged,
                  onClearSearch: _clearSearch,
                  onClearFilters: _clearFilters,
                ),
                const SizedBox(height: AppSpacing.sm),
                if (state.status == AuditLogsStatus.loading)
                  const LinearProgressIndicator(minHeight: 2),
                if (isInitialLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                    child: AppLoading(),
                  )
                else if (visibleLogs.isEmpty)
                  AppEmptyState(
                    icon: Icons.manage_search_outlined,
                    title: l.noAuditLogsFound,
                    message: l.noAuditLogsFoundMessage,
                  )
                else ...[
                  _AuditLogList(
                    logs: visibleLogs,
                    isAdmin: widget.profile.role == UserRole.admin,
                  ),
                  if (showLoadMore) ...[
                    const SizedBox(height: AppSpacing.md),
                    _LoadMoreAuditLogsButton(
                      loadedCount: visibleLogs.length,
                      pageSize: AuditLogsCubit.defaultPageLimit,
                      isLoading: state.status == AuditLogsStatus.loadingMore,
                      onPressed: _loadMoreLogs,
                    ),
                  ],
                ],
                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
            PositionedDirectional(
              end: AppSpacing.md,
              bottom: AppSpacing.md,
              child: AnimatedScale(
                duration: const Duration(milliseconds: 180),
                scale: _showBackToTop ? 1 : 0,
                child: IgnorePointer(
                  ignoring: !_showBackToTop,
                  child: FloatingActionButton.small(
                    heroTag: 'audit-logs-scroll-top',
                    onPressed: _scrollToTop,
                    tooltip:
                        MaterialLocalizations.of(context).backButtonTooltip,
                    child: const Icon(Icons.keyboard_arrow_up_rounded),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  String _dateRangeLabel(AppLocalizations l) {
    return switch (_dateRange) {
      _AuditDateRangePreset.today => l.today,
      _AuditDateRangePreset.last7Days => l.last7Days,
      _AuditDateRangePreset.last30Days => l.last30Days,
      _AuditDateRangePreset.custom => _customRange == null
          ? l.customRange
          : _customRangeLabel(context),
    };
  }

  String _customRangeLabel(BuildContext context) {
    final range = _customRange;
    if (range == null) {
      return AppLocalizations.of(context)!.customRange;
    }
    return _customRangeText(AppLocalizations.of(context)!, range);
  }
}

class _LoadMoreAuditLogsButton extends StatelessWidget {
  const _LoadMoreAuditLogsButton({
    required this.loadedCount,
    required this.pageSize,
    required this.isLoading,
    required this.onPressed,
    this.totalCount,
  });

  final int loadedCount;
  final int pageSize;
  final bool isLoading;
  final VoidCallback onPressed;
  final int? totalCount;

  @override
  Widget build(BuildContext context) {
    return AppPaginationFooter(
      loadedCount: loadedCount,
      pageSize: pageSize,
      isLoading: isLoading,
      onLoadMore: onPressed,
      totalCount: totalCount,
    );
  }
}

class _AuditHeader extends StatelessWidget {
  const _AuditHeader({
    required this.logs,
    required this.dateRangeLabel,
    required this.onVisibleTap,
    required this.onTodayTap,
    required this.onExportTap,
    required this.onImportantTap,
  });

  final List<AuditLog> logs;
  final String dateRangeLabel;
  final VoidCallback onVisibleTap;
  final VoidCallback onTodayTap;
  final VoidCallback onExportTap;
  final VoidCallback onImportantTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final todayEnd = todayStart.add(const Duration(days: 1));
    final todayCount = logs
        .where((log) =>
            !log.createdAt.isBefore(todayStart) &&
            log.createdAt.isBefore(todayEnd))
        .length;
    final exportCount = logs.where(_isExportLog).length;
    final importantCount = logs.where(_isImportantLog).length;
    final stats = [
      ModuleKpiCardData(
        label: l.visibleAuditLogs,
        value: logs.length.toString(),
        icon: Icons.history,
        tone: AppStatusTone.info,
        onTap: onVisibleTap,
      ),
      ModuleKpiCardData(
        label: l.todayActivityCount,
        value: todayCount.toString(),
        icon: Icons.today,
        tone: AppStatusTone.info,
        onTap: onTodayTap,
      ),
      ModuleKpiCardData(
        label: l.exportActivity,
        value: exportCount.toString(),
        icon: Icons.ios_share,
        tone: AppStatusTone.warning,
        onTap: onExportTap,
      ),
      ModuleKpiCardData(
        label: l.importantActivity,
        value: importantCount.toString(),
        icon: Icons.priority_high,
        tone: AppStatusTone.error,
        onTap: onImportantTap,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.cardSurface(context),
        border: Border.all(color: AppColors.borderColor(context)),
        borderRadius: AppRadius.xLarge,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primaryColor(context)
                      .withValues(alpha: 0.12),
                  borderRadius: AppRadius.medium,
                ),
                child: Icon(
                  Icons.manage_search_outlined,
                  color: AppColors.primaryColor(context),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.auditLogs,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    Text(
                      '${l.activityHistory} - $dateRangeLabel',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondaryColor(context),
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ModuleKpiStrip(cards: stats),
        ],
      ),
    );
  }
}

class _AuditFilters extends StatelessWidget {
  const _AuditFilters({
    required this.dateRange,
    required this.module,
    required this.action,
    required this.actorId,
    required this.showImportantOnly,
    required this.searchController,
    required this.search,
    required this.onOpenFilters,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onClearFilters,
  });

  final _AuditDateRangePreset dateRange;
  final AuditLogModule? module;
  final AuditLogAction? action;
  final String actorId;
  final bool showImportantOnly;
  final TextEditingController searchController;
  final String search;
  final VoidCallback onOpenFilters;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final VoidCallback onClearFilters;

  bool get _hasStructuredFilters {
    return dateRange != _AuditDateRangePreset.last7Days ||
        module != null ||
        action != null ||
        actorId.trim().isNotEmpty ||
        showImportantOnly;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.cardSurface(context),
        border: Border.all(color: AppColors.borderColor(context)),
        borderRadius: AppRadius.xLarge,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 720;
          final searchField = AppSearchField(
            controller: searchController,
            hint: l.searchAuditLogs,
            onChanged: onSearchChanged,
            onClear: search.trim().isEmpty ? null : onClearSearch,
          );
          return Row(
            children: [
              Expanded(child: searchField),
              const SizedBox(width: AppSpacing.sm),
              AppButton(
                label: l.filters,
                icon: Icons.tune,
                variant: AppButtonVariant.secondary,
                onPressed: onOpenFilters,
              ),
              if (_hasStructuredFilters && !narrow) ...[
                const SizedBox(width: AppSpacing.sm),
                AppButton(
                  label: l.clearFilters,
                  icon: Icons.filter_alt_off_outlined,
                  variant: AppButtonVariant.secondary,
                  onPressed: onClearFilters,
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

Future<_AuditFilterSelection?> _showAuditFiltersSheet(
  BuildContext context, {
  required _AuditDateRangePreset dateRange,
  required DateTimeRange? customRange,
  required AuditLogModule? module,
  required AuditLogAction? action,
  required String actorId,
  required List<UserProfile> users,
  ValueListenable<List<UserProfile>>? usersListenable,
  required List<AuditLog> logs,
  required Future<DateTimeRange?> Function(DateTimeRange? initialRange)
      onPickCustomRange,
}) async {
  final l = AppLocalizations.of(context)!;
  var selectedDateRange = dateRange;
  var selectedCustomRange = customRange;
  var selectedModule = module;
  var selectedAction = action;
  var selectedActorId = actorId;

  return showModalBottomSheet<_AuditFilterSelection>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetContext) {
      Widget buildSheet(List<UserProfile> sheetUsers) {
        final usersById = <String, UserProfile>{
          for (final user in sheetUsers) user.uid: user,
        };
        final actorIds = <String>{'', ...usersById.keys}.toList();

        String actorLabel(String value) {
          if (value.isEmpty) {
            return l.allUsers;
          }
          final user = usersById[value];
          if (user == null) {
            return value;
          }
          return _displayUser(user, l);
        }

        return StatefulBuilder(
          builder: (context, setSheetState) {
            final customLabel = selectedCustomRange == null
                ? l.customRange
                : _customRangeText(l, selectedCustomRange!);
            return Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md + MediaQuery.paddingOf(sheetContext).bottom,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            l.filters,
                            style: Theme.of(sheetContext)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(sheetContext).pop(),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Wrap(
                      spacing: AppSpacing.md,
                      runSpacing: AppSpacing.md,
                      children: [
                        SizedBox(
                          width: 220,
                          child: AppDropdown<_AuditDateRangePreset>(
                            label: l.dateRange,
                            value: selectedDateRange,
                            items: _AuditDateRangePreset.values,
                            itemLabelBuilder: (value) =>
                                value == _AuditDateRangePreset.custom
                                    ? customLabel
                                    : _dateRangeOptionLabel(l, value),
                            onChanged: (value) async {
                              if (value == _AuditDateRangePreset.custom) {
                                final picked =
                                    await onPickCustomRange(selectedCustomRange);
                                if (picked == null) {
                                  return;
                                }
                                setSheetState(() {
                                  selectedDateRange =
                                      _AuditDateRangePreset.custom;
                                  selectedCustomRange = picked;
                                });
                                return;
                              }
                              setSheetState(() {
                                selectedDateRange = value;
                                selectedCustomRange = null;
                              });
                            },
                          ),
                        ),
                        SizedBox(
                          width: 220,
                          child: AppDropdown<_AuditModuleFilterOption>(
                            label: l.module,
                            value: _moduleFilterOption(selectedModule),
                            items: _auditModuleFilterOptions,
                            itemLabelBuilder: (option) => option.isAll
                                ? l.allModules
                                : _moduleLabel(l, option.module!),
                            onChanged: (option) =>
                                setSheetState(() => selectedModule = option.module),
                          ),
                        ),
                        SizedBox(
                          width: 220,
                          child: AppDropdown<_AuditActionFilterOption>(
                            label: l.action,
                            value: _actionFilterOption(selectedAction),
                            items: _auditActionFilterOptions,
                            itemLabelBuilder: (option) => option.isAll
                                ? l.allActions
                                : _actionLabel(l, option.action!),
                            onChanged: (option) =>
                                setSheetState(() => selectedAction = option.action),
                          ),
                        ),
                        SizedBox(
                          width: 260,
                          child: AppDropdown<String>(
                            label: l.actor,
                            value: actorIds.contains(selectedActorId)
                                ? selectedActorId
                                : '',
                            items: actorIds,
                            itemLabelBuilder: actorLabel,
                            onChanged: (value) =>
                                setSheetState(() => selectedActorId = value),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: AppButton(
                            label: l.clearFilters,
                            variant: AppButtonVariant.secondary,
                            onPressed: () {
                              Navigator.of(sheetContext).pop(
                                const _AuditFilterSelection.defaults(),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: AppButton(
                            label: l.applyFilters,
                            icon: Icons.check,
                            onPressed: () {
                              Navigator.of(sheetContext).pop(
                                _AuditFilterSelection(
                                  dateRange: selectedDateRange,
                                  customRange: selectedDateRange ==
                                          _AuditDateRangePreset.custom
                                      ? selectedCustomRange
                                      : null,
                                  module: selectedModule,
                                  action: selectedAction,
                                  actorId: selectedActorId,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }

      if (usersListenable == null) {
        return buildSheet(users);
      }
      return ValueListenableBuilder<List<UserProfile>>(
        valueListenable: usersListenable,
        builder: (context, baseUsers, _) {
          return buildSheet(_mergeUsersWithLogActors(baseUsers, logs));
        },
      );
    },
  );
}

class _AuditLogList extends StatelessWidget {
  const _AuditLogList({
    required this.logs,
    required this.isAdmin,
  });

  final List<AuditLog> logs;
  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 820;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardSurface(context),
        border: Border.all(color: AppColors.borderColor(context)),
        borderRadius: AppRadius.xLarge,
      ),
      child: narrow
          ? ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              padding: const EdgeInsets.all(AppSpacing.xs),
              itemCount: logs.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.xs),
              itemBuilder: (context, index) => _AuditLogCard(
                log: logs[index],
                isAdmin: isAdmin,
              ),
            )
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                showCheckboxColumn: false,
                headingRowHeight: 42,
                dataRowMinHeight: 56,
                dataRowMaxHeight: 72,
                columns: [
                  DataColumn(label: Text(AppLocalizations.of(context)!.time)),
                  DataColumn(label: Text(AppLocalizations.of(context)!.actor)),
                  DataColumn(label: Text(AppLocalizations.of(context)!.role)),
                  DataColumn(label: Text(AppLocalizations.of(context)!.module)),
                  DataColumn(label: Text(AppLocalizations.of(context)!.action)),
                  DataColumn(label: Text(AppLocalizations.of(context)!.relatedRecord)),
                  DataColumn(label: Text(AppLocalizations.of(context)!.details)),
                ],
                rows: [
                  for (final log in logs)
                    DataRow(
                      onSelectChanged: (_) =>
                          _showAuditDetails(context, log, isAdmin: isAdmin),
                      cells: [
                        DataCell(
                          Text(_formatDateTime(context, log.createdAt)),
                          onTap: () => _showAuditDetails(context, log, isAdmin: isAdmin),
                        ),
                        DataCell(
                          _ActorCell(log: log),
                          onTap: () => _showAuditDetails(context, log, isAdmin: isAdmin),
                        ),
                        DataCell(
                          Text(_roleLabel(AppLocalizations.of(context)!, log.actorRole)),
                          onTap: () => _showAuditDetails(context, log, isAdmin: isAdmin),
                        ),
                        DataCell(
                          Text(_moduleLabel(AppLocalizations.of(context)!, log.module)),
                          onTap: () => _showAuditDetails(context, log, isAdmin: isAdmin),
                        ),
                        DataCell(
                          AppStatusBadge(
                            label: _actionLabel(AppLocalizations.of(context)!, log.action),
                            tone: _actionTone(log.action),
                          ),
                          onTap: () => _showAuditDetails(context, log, isAdmin: isAdmin),
                        ),
                        DataCell(
                          _RecordCell(log: log),
                          onTap: () => _showAuditDetails(context, log, isAdmin: isAdmin),
                        ),
                        DataCell(
                          SizedBox(
                            width: 280,
                            child: Text(
                              _detailsSummary(AppLocalizations.of(context)!, log),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          onTap: () => _showAuditDetails(context, log, isAdmin: isAdmin),
                        ),
                      ],
                    ),
                ],
              ),
            ),
    );
  }
}

class _AuditLogCard extends StatelessWidget {
  const _AuditLogCard({
    required this.log,
    required this.isAdmin,
  });

  final AuditLog log;
  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final details = _detailsSummary(l, log);
    return InkWell(
      borderRadius: AppRadius.large,
      onTap: () => _showAuditDetails(context, log, isAdmin: isAdmin),
      child: Container(
        padding: const EdgeInsetsDirectional.fromSTEB(10, 8, 10, 8),
        decoration: BoxDecoration(
          color: _surfaceAltColor(context),
          border: Border.all(color: AppColors.borderColor(context)),
          borderRadius: AppRadius.large,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(_moduleIcon(log.module), size: 18, color: AppColors.primaryColor(context)),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _recordTitle(l, log),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      AppStatusBadge(
                        label: _actionLabel(l, log.action),
                        tone: _actionTone(log.action),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_moduleLabel(l, log.module)} - ${_actorLine(l, log)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondaryColor(context),
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  Text(
                    details.trim().isEmpty
                        ? _formatDateTime(context, log.createdAt)
                        : '${_formatDateTime(context, log.createdAt)} - $details',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActorCell extends StatelessWidget {
  const _ActorCell({required this.log});

  final AuditLog log;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _fallback(log.actorName, AppLocalizations.of(context)!.unknownUser),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            log.actorEmail,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondaryColor(context),
                ),
          ),
        ],
      ),
    );
  }
}

class _RecordCell extends StatelessWidget {
  const _RecordCell({required this.log});

  final AuditLog log;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return SizedBox(
      width: 220,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _recordTitle(l, log),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (log.recordSubtitle.trim().isNotEmpty)
            Text(
              log.recordSubtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondaryColor(context),
                  ),
            ),
        ],
      ),
    );
  }
}

void _showAuditDetails(
  BuildContext context,
  AuditLog log, {
  required bool isAdmin,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    isDismissible: true,
    enableDrag: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return _AuditDetailSheet(log: log, isAdmin: isAdmin);
    },
  );
}

class _AuditDetailSheet extends StatelessWidget {
  const _AuditDetailSheet({
    required this.log,
    required this.isAdmin,
  });

  final AuditLog log;
  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final route = _relatedRoute(log, isAdmin: isAdmin);
    final mediaSize = MediaQuery.sizeOf(context);
    final maxHeight = mediaSize.height * 0.88;
    final sheetWidth = mediaSize.width < 760 ? mediaSize.width : 760.0;
    final exportRows = _exportDetailRows(l, log, isAdmin: isAdmin);

    return Align(
      alignment: Alignment.bottomCenter,
      child: SizedBox(
        width: sheetWidth,
        child: Material(
          color: AppColors.cardSurface(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          clipBehavior: Clip.antiAlias,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: DraggableScrollableSheet(
            expand: false,
          initialChildSize: 0.88,
          minChildSize: 0.35,
          maxChildSize: 0.88,
          builder: (context, scrollController) {
            return ListView(
              controller: scrollController,
              padding: EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                AppSpacing.md + MediaQuery.paddingOf(context).bottom,
              ),
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.textSecondaryColor(context),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Icon(
                      _moduleIcon(log.module),
                      color: AppColors.primaryColor(context),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        l.auditDetails,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                    ),
                    AppStatusBadge(
                      label: _actionLabel(l, log.action),
                      tone: _actionTone(log.action),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                _DetailGrid(
                  rows: [
                    _DetailRow(l.actor, _actorLine(l, log)),
                    _DetailRow(l.time, _formatDateTime(context, log.createdAt)),
                    _DetailRow(l.role, _roleLabel(l, log.actorRole)),
                    _DetailRow(l.module, _moduleLabel(l, log.module)),
                    _DetailRow(l.action, _actionLabel(l, log.action)),
                    _DetailRow(l.relatedRecord, _recordTitle(l, log)),
                    if (log.teamName.trim().isNotEmpty)
                      _DetailRow(l.team, log.teamName),
                    if (log.managerName.trim().isNotEmpty)
                      _DetailRow(l.manager, log.managerName),
                    ...exportRows,
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                _ChangesPanel(log: log),
                if (route != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  AppButton(
                    label: l.openRelatedRecord,
                    icon: Icons.open_in_new,
                    onPressed: () {
                      Navigator.of(context).pop();
                      context.go(route);
                    },
                  ),
                ],
              ],
            );
          },
        ),
      ),
    ),
  ),
);
  }
}

class _DetailRow {
  const _DetailRow(this.label, this.value);

  final String label;
  final String value;
}

class _DetailGrid extends StatelessWidget {
  const _DetailGrid({required this.rows});

  final List<_DetailRow> rows;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final row in rows.where((item) => item.value.trim().isNotEmpty))
          SizedBox(
            width: MediaQuery.sizeOf(context).width < 640
                ? double.infinity
                : 260,
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: _surfaceAltColor(context),
                border: Border.all(color: AppColors.borderColor(context)),
                borderRadius: AppRadius.large,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    row.label,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: AppColors.textSecondaryColor(context),
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    row.value,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _ChangesPanel extends StatelessWidget {
  const _ChangesPanel({required this.log});

  final AuditLog log;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final changes = _changeRows(l, log);
    final summary = _detailsSummary(l, log);
    if (changes.isEmpty && summary.trim().isEmpty) {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: _surfaceAltColor(context),
        border: Border.all(color: AppColors.borderColor(context)),
        borderRadius: AppRadius.large,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.detailsSummary,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: AppSpacing.xs),
          if (changes.isEmpty)
            Text(summary)
          else
            for (final change in changes)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Text(change),
              ),
        ],
      ),
    );
  }
}

List<_DetailRow> _exportDetailRows(
  AppLocalizations l,
  AuditLog log, {
  required bool isAdmin,
}) {
  if (!_isExportLog(log)) {
    return const <_DetailRow>[];
  }
  final metadata = log.metadata;
  return [
    _DetailRow(l.exportType, _exportTypeLabel(l, metadata['exportType'])),
    _DetailRow(l.exportReportType, _exportedModulesLabel(metadata, log.recordTitle)),
    _DetailRow(l.exportScope, _exportScopeLabel(l, metadata['exportScope'] ?? metadata['scope'])),
    _DetailRow(l.fileFormat, (metadata['fileFormat'] ?? metadata['format'] ?? '').toString()),
    _DetailRow(l.exportedRows, (metadata['rowCount'] ?? metadata['recordCount'] ?? '').toString()),
    _DetailRow(l.exportedColumns, _columnsLabel(l, metadata)),
    _DetailRow(l.filterSummary, (metadata['filtersSummary'] ?? metadata['filters'] ?? '').toString()),
  ];
}

List<String> _changeRows(AppLocalizations l, AuditLog log) {
  final changedFields = log.metadata['changedFields'];
  if (changedFields is! Iterable) {
    return const <String>[];
  }
  final details = <String>[];
  for (final entry in changedFields) {
    if (entry is! Map) {
      continue;
    }
    final field = (entry['field'] ?? '').toString();
    final oldValue = (entry['oldValue'] ?? '').toString();
    final newValue = (entry['newValue'] ?? '').toString();
    if (field.trim().isEmpty || oldValue == newValue) {
      continue;
    }
    details.add(
      '${_fieldLabel(l, field)}: ${l.changedFromTo(
        _isolate(_valueLabel(l, field, oldValue)),
        _isolate(_valueLabel(l, field, newValue)),
      )}',
    );
  }
  return details.take(8).toList(growable: false);
}

String _detailsSummary(AppLocalizations l, AuditLog log) {
  if (_isExportLog(log)) {
    final metadata = log.metadata;
    final report = _exportedModulesLabel(metadata, log.recordTitle);
    final scope = _exportScopeLabel(l, metadata['exportScope'] ?? metadata['scope']);
    final rows = (metadata['rowCount'] ?? metadata['recordCount'] ?? '').toString();
    return [
      if (report.isNotEmpty) report,
      if (scope.isNotEmpty) scope,
      if (rows.isNotEmpty) '${l.exportedRows}: $rows',
    ].join(' - ');
  }

  final changes = _changeRows(l, log);
  if (changes.isNotEmpty) {
    return changes.take(3).join(' | ');
  }

  final previousStatus = (log.metadata['previousStatus'] ?? '').toString();
  final newStatus = (log.metadata['newStatus'] ?? '').toString();
  if (previousStatus.isNotEmpty && newStatus.isNotEmpty) {
    return l.changedFromTo(
      _isolate(_valueLabel(l, 'status', previousStatus)),
      _isolate(_valueLabel(l, 'status', newStatus)),
    );
  }

  final assignedToName = (log.metadata['assignedToName'] ?? '').toString();
  if (assignedToName.isNotEmpty) {
    return '${l.assignedToLabel}: $assignedToName';
  }

  return _localizedAuditText(l, log.recordSubtitle);
}

String _localizedAuditText(AppLocalizations l, String value) {
  var text = value.trim();
  if (text.isEmpty || !l.localeName.toLowerCase().startsWith('ar')) {
    return text;
  }
  const replacements = <String, String>{
    'newLead': 'جديد',
    'contacted': 'تم التواصل',
    'interested': 'مهتم',
    'visitScheduled': 'تم تحديد زيارة',
    'negotiation': 'تفاوض',
    'won': 'مكتسب',
    'lost': 'مفقود',
    'pending': 'معلّقة',
    'inProgress': 'قيد التنفيذ',
    'completed': 'مكتملة',
    'cancelled': 'ملغاة',
    'canceled': 'ملغاة',
    'scheduled': 'مجدولة',
    'rescheduled': 'أُعيدت جدولته',
    'missed': 'فائتة',
    'high': 'عالية',
    'medium': 'متوسطة',
    'low': 'منخفضة',
  };
  replacements.forEach((key, label) {
    text = text.replaceAll(key, label);
  });
  return text;
}

String? _relatedRoute(AuditLog log, {required bool isAdmin}) {
  if (log.recordId.trim().isEmpty) {
    return null;
  }
  return switch (log.module) {
    AuditLogModule.leads => RouteNames.leadDetails(log.recordId),
    AuditLogModule.clients => RouteNames.clientDetails(log.recordId),
    AuditLogModule.properties => RouteNames.propertyDetails(log.recordId),
    AuditLogModule.tasks => RouteNames.taskEdit(log.recordId),
    AuditLogModule.deals => RouteNames.dealDetails(log.recordId),
    AuditLogModule.appointments => RouteNames.appointmentEdit(log.recordId),
    AuditLogModule.users => isAdmin ? RouteNames.users : null,
    AuditLogModule.teams => RouteNames.teams,
    AuditLogModule.reports => RouteNames.reports,
    AuditLogModule.exports => RouteNames.auditLogs,
    AuditLogModule.auditLogs => RouteNames.auditLogs,
    AuditLogModule.other => null,
  };
}

bool _canViewAuditLogs(UserRole role) {
  return role == UserRole.admin || role == UserRole.manager;
}

bool _isExportLog(AuditLog log) {
  return log.action == AuditLogAction.exported ||
      log.action == AuditLogAction.exportGenerated ||
      log.module == AuditLogModule.exports ||
      log.metadata['exportType'] != null;
}

bool _isImportantLog(AuditLog log) {
  return log.action == AuditLogAction.archive ||
      log.action == AuditLogAction.deactivate ||
      log.action == AuditLogAction.cancel ||
      log.action == AuditLogAction.exported ||
      log.action == AuditLogAction.exportGenerated ||
      log.module == AuditLogModule.users ||
      log.module == AuditLogModule.teams;
}

String _recordTitle(AppLocalizations l, AuditLog log) {
  return _fallback(log.recordTitle, _moduleLabel(l, log.module));
}

String _actorLine(AppLocalizations l, AuditLog log) {
  final actor = _fallback(log.actorName, _fallback(log.actorEmail, l.unknownUser));
  final role = _roleLabel(l, log.actorRole);
  return '$actor - $role';
}

List<UserProfile> _mergeUsersWithLogActors(
  List<UserProfile> users,
  List<AuditLog> logs,
) {
  final byId = <String, UserProfile>{
    for (final user in users) user.uid: user,
  };
  for (final log in logs) {
    final actorId = log.actorId.trim();
    if (actorId.isEmpty || byId.containsKey(actorId)) {
      continue;
    }
    UserRole role;
    try {
      role = RoleConstants.fromValue(log.actorRole);
    } catch (_) {
      role = UserRole.viewer;
    }
    byId[actorId] = UserProfile(
      uid: actorId,
      companyId: log.companyId,
      fullName: log.actorName,
      email: log.actorEmail,
      phone: '',
      role: role,
      isActive: true,
      teamId: log.teamId,
      teamName: log.teamName,
      managerId: log.managerId,
      managerName: log.managerName,
      createdAt: DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
      createdBy: '',
    );
  }
  final values = byId.values.toList()
    ..sort((a, b) => _displayUserSortLabel(a).compareTo(_displayUserSortLabel(b)));
  return values;
}

String _displayUserSortLabel(UserProfile user) {
  final name = user.fullName.trim();
  if (name.isNotEmpty) {
    return name.toLowerCase();
  }
  final email = user.email.trim();
  if (email.isNotEmpty) {
    return email.toLowerCase();
  }
  return user.uid.toLowerCase();
}

String _displayUser(UserProfile user, AppLocalizations l) {
  final name = _fallback(user.fullName, _fallback(user.email, user.uid));
  return '$name - ${_roleLabel(l, RoleConstants.toValue(user.role))}';
}

String _moduleLabel(AppLocalizations l, AuditLogModule module) {
  return switch (module) {
    AuditLogModule.leads => l.leads,
    AuditLogModule.clients => l.clients,
    AuditLogModule.properties => l.properties,
    AuditLogModule.tasks => l.tasks,
    AuditLogModule.deals => l.deals,
    AuditLogModule.appointments => l.appointments,
    AuditLogModule.users => l.userManagement,
    AuditLogModule.teams => l.teamManagement,
    AuditLogModule.reports => l.reports,
    AuditLogModule.exports => l.exportActivity,
    AuditLogModule.auditLogs => l.auditLogs,
    AuditLogModule.other => l.other,
  };
}

String _actionLabel(AppLocalizations l, AuditLogAction action) {
  return switch (action) {
    AuditLogAction.create => l.dashboardAuditCreated,
    AuditLogAction.update => l.dashboardAuditUpdated,
    AuditLogAction.archive => l.dashboardAuditArchived,
    AuditLogAction.restore => l.dashboardAuditRestored,
    AuditLogAction.deactivate => l.dashboardAuditDeactivated,
    AuditLogAction.assign => l.dashboardAuditAssigned,
    AuditLogAction.statusChange => l.dashboardAuditStatusChanged,
    AuditLogAction.stageChange => l.dashboardAuditStageChanged,
    AuditLogAction.complete => l.dashboardAuditCompleted,
    AuditLogAction.cancel => l.dashboardAuditCancelled,
    AuditLogAction.imageAdded => l.dashboardAuditImageAdded,
    AuditLogAction.imageRemoved => l.dashboardAuditImageRemoved,
    AuditLogAction.exportGenerated || AuditLogAction.exported => l.dashboardAuditExportGenerated,
  };
}

String _roleLabel(AppLocalizations l, String role) {
  return switch (role) {
    RoleConstants.admin => l.admin,
    RoleConstants.manager => l.manager,
    RoleConstants.salesAgent => l.salesAgent,
    RoleConstants.marketing => l.marketing,
    RoleConstants.viewer => l.viewer,
    _ => role,
  };
}

String _fieldLabel(AppLocalizations l, String field) {
  return switch (field) {
    'fullName' => l.fullNameUpdated,
    'phone' => l.phoneUpdated,
    'email' => l.emailUpdated,
    'source' => l.sourceUpdated,
    'sourceDetails' => l.sourceDetails,
    'status' => l.statusUpdated,
    'priority' => l.priorityUpdated,
    'budget' => l.budgetUpdated,
    'budgetMin' => l.budgetMin,
    'budgetMax' => l.budgetMax,
    'preferredLocation' => l.preferredLocationUpdated,
    'preferredPropertyType' => l.preferredPropertyTypeUpdated,
    'assignedTo' => l.assignedToLabel,
    'notes' => l.notes,
    'lastContactAt' => l.lastContact,
    'nextFollowUpAt' => l.nextFollowUp,
    _ => field,
  };
}

String _valueLabel(AppLocalizations l, String field, String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return l.notAvailable;
  }
  if (field == 'lastContactAt' || field == 'nextFollowUpAt') {
    final parsed = DateTime.tryParse(trimmed) ??
        DateTime.tryParse(trimmed.replaceFirst(' ', 'T'));
    if (parsed != null) {
      return DateFormat.yMMMd(l.localeName).add_jm().format(parsed.toLocal());
    }
  }
  return switch (field) {
    'status' || 'stage' || 'taskStatus' || 'appointmentStatus' =>
      _statusValueLabel(l, trimmed),
    'source' => _sourceValueLabel(l, trimmed),
    'priority' => _priorityValueLabel(l, trimmed),
    _ => _genericAuditValueLabel(l, trimmed),
  };
}

String _statusValueLabel(AppLocalizations l, String value) {
  return switch (value) {
    'newLead' || 'new' => l.newLeadStatus,
    'contacted' => l.contactedLeadStatus,
    'interested' => l.interestedLeadStatus,
    'visitScheduled' => l.visitScheduledLeadStatus,
    'negotiation' => l.negotiationLeadStatus,
    'won' => l.wonLeadStatus,
    'lost' => l.lostLeadStatus,
    'pending' => l.pending,
    'inProgress' => l.inProgress,
    'completed' => l.completed,
    'cancelled' || 'canceled' => l.cancelled,
    'scheduled' => l.localeName.toLowerCase().startsWith('ar') ? 'مجدولة' : 'Scheduled',
    'rescheduled' => l.localeName.toLowerCase().startsWith('ar') ? 'أُعيدت جدولته' : 'Rescheduled',
    'missed' => l.localeName.toLowerCase().startsWith('ar') ? 'فائتة' : 'Missed',
    _ => _genericAuditValueLabel(l, value),
  };
}

String _sourceValueLabel(AppLocalizations l, String value) {
  return switch (value) {
    'facebook' => l.facebook,
    'website' => l.website,
    'phoneCall' => l.phoneCall,
    'whatsapp' => l.whatsapp,
    'referral' => l.referral,
    'walkIn' => l.walkIn,
    'other' => l.other,
    _ => value,
  };
}

String _priorityValueLabel(AppLocalizations l, String value) {
  return switch (value) {
    'low' => l.low,
    'medium' => l.medium,
    'high' => l.high,
    _ => value,
  };
}

String _genericAuditValueLabel(AppLocalizations l, String value) {
  if (!l.localeName.toLowerCase().startsWith('ar')) {
    return value;
  }
  return switch (value) {
    'newLead' || 'new' => 'جديد',
    'contacted' => 'تم التواصل',
    'interested' => 'مهتم',
    'visitScheduled' => 'تم تحديد زيارة',
    'negotiation' => 'تفاوض',
    'won' => 'مكتسب',
    'lost' => 'مفقود',
    'qualified' => 'مؤهل',
    'proposal' => 'عرض',
    'pending' => 'معلّقة',
    'inProgress' => 'قيد التنفيذ',
    'completed' => 'مكتملة',
    'cancelled' || 'canceled' => 'ملغاة',
    'scheduled' => 'مجدولة',
    'rescheduled' => 'أُعيدت جدولته',
    'missed' => 'فائتة',
    'facebook' => l.facebook,
    'website' => l.website,
    'phoneCall' => l.phoneCall,
    'whatsapp' => l.whatsapp,
    'referral' => l.referral,
    'walkIn' => l.walkIn,
    'other' => l.other,
    'low' => l.low,
    'medium' => l.medium,
    'high' => l.high,
    _ => value,
  };
}

IconData _moduleIcon(AuditLogModule module) {
  return switch (module) {
    AuditLogModule.leads => Icons.person_search_outlined,
    AuditLogModule.clients => Icons.person_outline_rounded,
    AuditLogModule.properties => Icons.business_outlined,
    AuditLogModule.tasks => Icons.checklist_rtl_rounded,
    AuditLogModule.deals => Icons.handshake_outlined,
    AuditLogModule.appointments => Icons.event_note_outlined,
    AuditLogModule.users => Icons.manage_accounts_outlined,
    AuditLogModule.teams => Icons.groups_outlined,
    AuditLogModule.reports => Icons.bar_chart_outlined,
    AuditLogModule.exports => Icons.ios_share_outlined,
    AuditLogModule.auditLogs => Icons.manage_search_outlined,
    AuditLogModule.other => Icons.history_toggle_off_outlined,
  };
}

AppStatusTone _actionTone(AuditLogAction action) {
  return switch (action) {
    AuditLogAction.create ||
    AuditLogAction.imageAdded ||
    AuditLogAction.complete ||
    AuditLogAction.restore => AppStatusTone.success,
    AuditLogAction.archive ||
    AuditLogAction.deactivate ||
    AuditLogAction.cancel ||
    AuditLogAction.imageRemoved => AppStatusTone.neutral,
    AuditLogAction.statusChange ||
    AuditLogAction.stageChange => AppStatusTone.warning,
    AuditLogAction.assign ||
    AuditLogAction.update ||
    AuditLogAction.exportGenerated ||
    AuditLogAction.exported => AppStatusTone.info,
  };
}

String _dateRangeOptionLabel(AppLocalizations l, _AuditDateRangePreset value) {
  return switch (value) {
    _AuditDateRangePreset.today => l.today,
    _AuditDateRangePreset.last7Days => l.last7Days,
    _AuditDateRangePreset.last30Days => l.last30Days,
    _AuditDateRangePreset.custom => l.customRange,
  };
}

_AuditModuleFilterOption _moduleFilterOption(AuditLogModule? module) {
  for (final option in _auditModuleFilterOptions) {
    if (option.module == module) {
      return option;
    }
  }
  return _auditModuleFilterOptions.first;
}

_AuditActionFilterOption _actionFilterOption(AuditLogAction? action) {
  for (final option in _auditActionFilterOptions) {
    if (option.action == action) {
      return option;
    }
  }
  return _auditActionFilterOptions.first;
}

String _customRangeText(AppLocalizations l, DateTimeRange range) {
  final formatter = DateFormat.yMMMd(l.localeName);
  return '${formatter.format(range.start)} - ${formatter.format(range.end)}';
}

String _exportTypeLabel(AppLocalizations l, Object? value) {
  return switch (value.toString()) {
    'auditLogsExport' => l.auditLogsExport,
    'platformCompanyExport' => l.platformCompanyExport,
    _ => l.reportsExport,
  };
}

String _exportScopeLabel(AppLocalizations l, Object? value) {
  return switch (value.toString()) {
    'companyWide' => l.companyWideExportScope,
    'teamOnly' || 'myTeam' => l.myTeamExportScope,
    'assignedOnly' || 'myRecords' => l.myRecordsExportScope,
    _ => value?.toString() ?? '',
  };
}


String _exportedModulesLabel(Map<String, Object?> metadata, String fallback) {
  final labels = metadata['exportedModuleLabels'];
  if (labels is Iterable) {
    final clean = labels
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
    if (clean.isNotEmpty) {
      return clean.join(', ');
    }
  }
  final report = (metadata['exportedModulesLabel'] ??
          metadata['reportTypeLabel'] ??
          metadata['exportedModuleLabel'] ??
          fallback)
      .toString()
      .trim();
  return report;
}

String _columnsLabel(AppLocalizations l, Map<String, Object?> metadata) {
  final count = (metadata['selectedColumnsCount'] ??
          metadata['columnCount'] ??
          '')
      .toString();
  final columns = metadata['selectedColumns'];
  if (columns is Iterable && columns.isNotEmpty) {
    return columns.map((item) => item.toString()).take(12).join(', ');
  }
  return count;
}

String _notificationSummary(AppLocalizations l, Map<String, Object?> metadata) {
  final adminCount = (metadata['notifiedAdminCount'] ?? '').toString();
  final managerCount = (metadata['notifiedManagerCount'] ?? '').toString();
  final parts = <String>[
    if (adminCount.isNotEmpty) '${l.admin}: $adminCount',
    if (managerCount.isNotEmpty) '${l.manager}: $managerCount',
  ];
  return parts.join(' - ');
}

String _formatDateTime(BuildContext context, DateTime value) {
  return DateFormat.yMMMd(AppLocalizations.of(context)!.localeName)
      .add_Hm()
      .format(value.toLocal());
}

String _fallback(String value, String fallback) {
  final clean = value.trim();
  return clean.isEmpty ? fallback : clean;
}

Color _surfaceAltColor(BuildContext context) {
  return AppColors.isDark(context) ? AppColors.darkSurfaceAlt : AppColors.surfaceAlt;
}

String _isolate(String value) => '\u2068$value\u2069';

String _safeMetadataValue(Object? value) {
  if (value == null) {
    return '';
  }
  if (value is Iterable) {
    return value.map(_safeMetadataValue).join(', ');
  }
  if (value is Map) {
    return value.entries
        .where((entry) => !_isSensitiveMetadataKey(entry.key.toString()))
        .map((entry) => '${entry.key}: ${_safeMetadataValue(entry.value)}')
        .join(', ');
  }
  var text = value.toString();
  text = text.replaceAll(
    RegExp(
      r'https?:\/\/\S*(token|secret|signature|alt=media)\S*',
      caseSensitive: false,
    ),
    '[redacted-url]',
  );
  text = text.replaceAll(
    RegExp(
      r'(password|token|secret|reset[_-]?link|invite[_-]?code)\s*[:=]\s*[^\s,;]+',
      caseSensitive: false,
    ),
    '[redacted]',
  );
  if (text.length <= 240) {
    return text;
  }
  return '${text.substring(0, 240)}...';
}

bool _isSensitiveMetadataKey(String key) {
  final lower = key.toLowerCase();
  return lower.contains('token') ||
      lower.contains('secret') ||
      lower.contains('password') ||
      lower.contains('reset') ||
      lower.contains('invite') ||
      lower.contains('storagepath') ||
      lower.contains('downloadurl') ||
      lower.contains('signedurl');
}

class _AuditDateWindow {
  const _AuditDateWindow(this.start, this.end);

  final DateTime start;
  final DateTime end;
}
