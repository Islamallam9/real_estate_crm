import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/archive/archive_filter.dart';
import '../../../../core/constants/role_constants.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/utils/initial_load_timeout.dart';
import '../../../audit_logs/domain/entities/audit_log.dart';
import '../../../audit_logs/domain/usecases/create_audit_log_usecase.dart';
import '../../../dashboard/domain/services/dashboard_truth_rules.dart';
import '../../data/datasources/deals_remote_data_source.dart';
import '../../data/models/deal_model.dart';
import '../../domain/entities/deal.dart';
import '../../domain/usecases/archive_deal_usecase.dart';
import '../../domain/usecases/create_deal_usecase.dart';
import '../../domain/usecases/restore_deal_usecase.dart';
import '../../domain/usecases/update_deal_stage_usecase.dart';
import '../../domain/usecases/update_deal_usecase.dart';
import '../../domain/usecases/watch_deal_usecase.dart';
import '../../domain/usecases/watch_deals_usecase.dart';
import 'deals_state.dart';

class DealsCubit extends Cubit<DealsState> {
  DealsCubit({
    required WatchDealUseCase watchDealUseCase,
    required WatchDealsUseCase watchDealsUseCase,
    required CreateDealUseCase createDealUseCase,
    required UpdateDealUseCase updateDealUseCase,
    required UpdateDealStageUseCase updateDealStageUseCase,
    required ArchiveDealUseCase archiveDealUseCase,
    required RestoreDealUseCase restoreDealUseCase,
    required CreateAuditLogUseCase createAuditLogUseCase,
  }) : _watchDealUseCase = watchDealUseCase,
       _watchDealsUseCase = watchDealsUseCase,
       _createDealUseCase = createDealUseCase,
       _updateDealUseCase = updateDealUseCase,
       _updateDealStageUseCase = updateDealStageUseCase,
       _archiveDealUseCase = archiveDealUseCase,
       _restoreDealUseCase = restoreDealUseCase,
       _createAuditLogUseCase = createAuditLogUseCase,
       super(const DealsState.initial());

  final WatchDealUseCase _watchDealUseCase;
  final WatchDealsUseCase _watchDealsUseCase;
  final CreateDealUseCase _createDealUseCase;
  final UpdateDealUseCase _updateDealUseCase;
  final UpdateDealStageUseCase _updateDealStageUseCase;
  final ArchiveDealUseCase _archiveDealUseCase;
  final RestoreDealUseCase _restoreDealUseCase;
  final CreateAuditLogUseCase _createAuditLogUseCase;

  StreamSubscription<dynamic>? _dealsSubscription;
  final InitialLoadTimeout _dealsInitialLoadTimeout = InitialLoadTimeout();

  void watchDeal({
    required String companyId,
    required String dealId,
  }) {
    emit(
      state.copyWith(
        status: DealsStatus.loading,
        clearMessage: true,
        clearLastAction: true,
      ),
    );
    _dealsSubscription?.cancel();
    _dealsInitialLoadTimeout.start(() {
      if (isClosed ||
          state.status != DealsStatus.loading ||
          state.deals.isNotEmpty) {
        return;
      }
      emit(
        state.copyWith(
          status: DealsStatus.failure,
          message: AppErrorMessages.connectionTimeout,
        ),
      );
    });
    _dealsSubscription = _watchDealUseCase(
      companyId: companyId,
      dealId: dealId,
    ).listen(
      (deal) {
        if (isClosed) {
          return;
        }
        _dealsInitialLoadTimeout.complete();
        final deals = deal == null ? const <Deal>[] : <Deal>[deal];
        emit(
          state.copyWith(
            status: deal == null ? DealsStatus.empty : DealsStatus.loaded,
            deals: deals,
            filteredDeals: deals,
            clearMessage: true,
          ),
        );
      },
      onError: (error) {
        if (isClosed) {
          return;
        }
        _dealsInitialLoadTimeout.complete();
        emit(
          state.copyWith(
            status: DealsStatus.failure,
            message: _dealErrorMessage(error),
          ),
        );
      },
    );
  }

  void watchDeals({
    required String companyId,
    required UserRole role,
    required String currentUserId,
    String? teamId,
    ArchiveFilter archiveFilter = ArchiveFilter.active,
  }) {
    emit(
      state.copyWith(
        status: DealsStatus.loading,
        clearMessage: true,
        clearLastAction: true,
      ),
    );
    _dealsSubscription?.cancel();
    _dealsInitialLoadTimeout.start(() {
      if (isClosed ||
          state.status != DealsStatus.loading ||
          state.deals.isNotEmpty) {
        return;
      }
      emit(
        state.copyWith(
          status: DealsStatus.failure,
          message: AppErrorMessages.connectionTimeout,
        ),
      );
    });
    _dealsSubscription = _watchDealsUseCase(
      companyId: companyId,
      role: role,
      currentUserId: currentUserId,
      teamId: teamId,
      archiveFilter: archiveFilter,
    ).listen(
      (deals) {
        if (isClosed) {
          return;
        }
        _dealsInitialLoadTimeout.complete();
        emit(
          state.copyWith(
            status: deals.isEmpty ? DealsStatus.empty : DealsStatus.loaded,
            deals: deals,
            filteredDeals: _applyFilters(deals),
            archiveFilter: archiveFilter,
            clearMessage: true,
          ),
        );
      },
      onError: (error) {
        if (isClosed) {
          return;
        }
        _dealsInitialLoadTimeout.complete();
        emit(
          state.copyWith(
            status: DealsStatus.failure,
            message: _dealErrorMessage(error),
          ),
        );
      },
    );
  }

  void setArchiveFilter(
    ArchiveFilter archiveFilter, {
    required String companyId,
    required UserRole role,
    required String currentUserId,
    String? teamId,
  }) {
    emit(state.copyWith(archiveFilter: archiveFilter));
    watchDeals(
      companyId: companyId,
      role: role,
      currentUserId: currentUserId,
      teamId: teamId,
      archiveFilter: archiveFilter,
    );
  }

  void setSearchQuery(String query) {
    emit(
      state.copyWith(
        searchQuery: query,
        filteredDeals: _applyFilters(state.deals, searchQuery: query),
      ),
    );
  }

  void setStageFilter(DealStage? stage) {
    emit(
      state.copyWith(
        stageFilter: stage,
        clearStageFilter: stage == null,
        filteredDeals: _applyFilters(
          state.deals,
          stageFilter: stage,
          overrideStageFilter: true,
        ),
      ),
    );
  }

  void setAssignedToFilter(String assignedTo) {
    emit(
      state.copyWith(
        assignedToFilter: assignedTo,
        filteredDeals: _applyFilters(state.deals, assignedToFilter: assignedTo),
      ),
    );
  }

  void setClosingDateFilter(DealClosingDateFilter? filter) {
    emit(
      state.copyWith(
        closingDateFilter: filter,
        clearClosingDateFilter: filter == null,
        filteredDeals: _applyFilters(
          state.deals,
          closingDateFilter: filter,
          overrideClosingDateFilter: true,
        ),
      ),
    );
  }

  void setWorkQueueFilter(DealWorkQueueFilter? filter) {
    emit(
      state.copyWith(
        workQueueFilter: filter,
        clearWorkQueueFilter: filter == null,
        filteredDeals: _applyFilters(
          state.deals,
          workQueueFilter: filter,
          overrideWorkQueueFilter: true,
        ),
      ),
    );
  }

  void clearFilters() {
    emit(
      state.copyWith(
        searchQuery: '',
        assignedToFilter: '',
        clearStageFilter: true,
        clearClosingDateFilter: true,
        clearWorkQueueFilter: true,
        filteredDeals: _applyFilters(
          state.deals,
          searchQuery: '',
          stageFilter: null,
          assignedToFilter: '',
          closingDateFilter: null,
          workQueueFilter: null,
          overrideStageFilter: true,
          overrideClosingDateFilter: true,
          overrideWorkQueueFilter: true,
        ),
      ),
    );
  }

  Future<bool> createDeal({
    required String companyId,
    required Deal deal,
  }) {
    return _save(
      action: DealsAction.createDeal,
      operation: () => _createDealUseCase(companyId: companyId, deal: deal),
      afterSuccess: (result) {
        final createdDeal = result as Deal;
        unawaited(
          _writeAuditLog(
            companyId: companyId,
            actorId: createdDeal.createdBy,
            action: AuditLogAction.create,
            recordId: createdDeal.id,
            recordTitle: _dealTitle(createdDeal),
            recordSubtitle: _dealSubtitle(createdDeal),
            metadata: {
              'newStage': dealStageToValue(createdDeal.stage),
              'assignedTo': createdDeal.assignedTo,
              'assignedToName': createdDeal.assignedToName,
              'teamId': createdDeal.teamId,
              'teamName': createdDeal.teamName,
              'managerId': createdDeal.managerId,
              'managerName': createdDeal.managerName,
            },
          ),
        );
      },
    );
  }

  Future<bool> updateDeal({
    required String companyId,
    required Deal deal,
  }) {
    final previousDeal = dealById(deal.id);
    return _save(
      action: DealsAction.updateDeal,
      operation: () => _updateDealUseCase(companyId: companyId, deal: deal),
      afterSuccess: (result) {
        final updatedDeal = result as Deal;
        final stageChanged =
            previousDeal != null && previousDeal.stage != updatedDeal.stage;
        unawaited(
          _writeAuditLog(
            companyId: companyId,
            actorId: updatedDeal.updatedBy,
            action: stageChanged
                ? AuditLogAction.stageChange
                : AuditLogAction.update,
            recordId: updatedDeal.id,
            recordTitle: _dealTitle(updatedDeal),
            recordSubtitle: _dealSubtitle(updatedDeal),
            metadata: {
              if (previousDeal != null) ...{
                'previousStage': dealStageToValue(previousDeal.stage),
                'newStage': dealStageToValue(updatedDeal.stage),
              },
              'assignedTo': updatedDeal.assignedTo,
              'assignedToName': updatedDeal.assignedToName,
              'teamId': updatedDeal.teamId,
              'teamName': updatedDeal.teamName,
              'managerId': updatedDeal.managerId,
              'managerName': updatedDeal.managerName,
            },
          ),
        );
      },
    );
  }

  Future<bool> updateDealStage({
    required String companyId,
    required String dealId,
    required DealStage stage,
    required String lostReason,
    required String updatedBy,
  }) {
    final previousDeal = dealById(dealId);
    return _save(
      action: DealsAction.updateStage,
      operation: () => _updateDealStageUseCase(
        companyId: companyId,
        dealId: dealId,
        stage: stage,
        lostReason: lostReason,
        updatedBy: updatedBy,
      ),
      afterSuccess: (_) {
        unawaited(
          _writeAuditLog(
            companyId: companyId,
            actorId: updatedBy,
            action: AuditLogAction.stageChange,
            recordId: dealId,
            recordTitle: previousDeal == null ? 'Deal' : _dealTitle(previousDeal),
            recordSubtitle: previousDeal == null
                ? ''
                : _dealSubtitle(previousDeal),
            metadata: {
              if (previousDeal != null)
                'previousStage': dealStageToValue(previousDeal.stage),
              'newStage': dealStageToValue(stage),
              if (previousDeal != null) ...{
                'assignedTo': previousDeal.assignedTo,
                'assignedToName': previousDeal.assignedToName,
                'teamId': previousDeal.teamId,
                'teamName': previousDeal.teamName,
                'managerId': previousDeal.managerId,
                'managerName': previousDeal.managerName,
              },
            },
          ),
        );
      },
    );
  }

  Future<bool> archiveDeal({
    required String companyId,
    required String dealId,
    required String updatedBy,
    String reason = '',
  }) {
    final deal = dealById(dealId);
    return _save(
      action: DealsAction.archiveDeal,
      operation: () => _archiveDealUseCase(
        companyId: companyId,
        dealId: dealId,
        updatedBy: updatedBy,
        reason: reason,
      ),
      afterSuccess: (_) {
        unawaited(
          _writeAuditLog(
            companyId: companyId,
            actorId: updatedBy,
            action: AuditLogAction.archive,
            recordId: dealId,
            recordTitle: deal == null ? 'Deal' : _dealTitle(deal),
            recordSubtitle: deal == null ? '' : _dealSubtitle(deal),
            metadata: {
              if (deal != null) ...{
                'assignedTo': deal.assignedTo,
                'assignedToName': deal.assignedToName,
                'teamId': deal.teamId,
                'teamName': deal.teamName,
                'managerId': deal.managerId,
                'managerName': deal.managerName,
              },
            },
          ),
        );
      },
    );
  }

  Future<bool> restoreDeal({
    required String companyId,
    required String dealId,
    required String updatedBy,
  }) {
    final deal = dealById(dealId);
    return _save(
      action: DealsAction.restoreDeal,
      operation: () => _restoreDealUseCase(
        companyId: companyId,
        dealId: dealId,
        updatedBy: updatedBy,
      ),
      afterSuccess: (_) {
        unawaited(
          _writeAuditLog(
            companyId: companyId,
            actorId: updatedBy,
            action: AuditLogAction.restore,
            recordId: dealId,
            recordTitle: deal == null ? 'Deal' : _dealTitle(deal),
            recordSubtitle: deal == null ? '' : _dealSubtitle(deal),
            metadata: {
              if (deal != null) ...{
                'assignedTo': deal.assignedTo,
                'assignedToName': deal.assignedToName,
                'teamId': deal.teamId,
                'teamName': deal.teamName,
                'managerId': deal.managerId,
                'managerName': deal.managerName,
              },
            },
          ),
        );
      },
    );
  }

  Future<bool> _save({
    required DealsAction action,
    required Future<dynamic> Function() operation,
    void Function(dynamic result)? afterSuccess,
  }) async {
    emit(
      state.copyWith(
        status: DealsStatus.saving,
        clearMessage: true,
        clearLastAction: true,
      ),
    );
    try {
      final result = await operation();
      afterSuccess?.call(result);
      if (isClosed) {
        return false;
      }
      final updatedDeals = result is Deal
          ? _upsertDealInCurrentList(result)
          : state.deals;
      emit(
        state.copyWith(
          status: DealsStatus.saved,
          deals: updatedDeals,
          filteredDeals: result is Deal
              ? _applyFilters(
                  updatedDeals,
                  searchQuery: state.searchQuery,
                  stageFilter: state.stageFilter,
                  assignedToFilter: state.assignedToFilter,
                  closingDateFilter: state.closingDateFilter,
                  workQueueFilter: state.workQueueFilter,
                )
              : state.filteredDeals,
          clearMessage: true,
          lastAction: action,
        ),
      );
      return true;
    } on DealException catch (error) {
      if (!isClosed) {
        emit(
          state.copyWith(
            status: DealsStatus.failure,
            message: error.message,
            lastAction: action,
          ),
        );
      }
      return false;
    } catch (_) {
      if (!isClosed) {
        emit(
          state.copyWith(
            status: DealsStatus.failure,
            message: AppErrorMessages.unknown,
            lastAction: action,
          ),
        );
      }
      return false;
    }
  }

  void clearAction() {
    emit(state.copyWith(clearLastAction: true));
  }

  Deal? dealById(String dealId) {
    for (final deal in state.deals) {
      if (deal.id == dealId) {
        return deal;
      }
    }
    return null;
  }


  List<Deal> _upsertDealInCurrentList(Deal updated) {
    final next = List<Deal>.of(state.deals);
    final index = next.indexWhere((deal) => deal.id == updated.id);
    if (index < 0) {
      next.insert(0, updated);
    } else {
      next[index] = updated;
    }
    return next;
  }

  List<Deal> _applyFilters(
    List<Deal> deals, {
    String? searchQuery,
    DealStage? stageFilter,
    String? assignedToFilter,
    DealClosingDateFilter? closingDateFilter,
    DealWorkQueueFilter? workQueueFilter,
    bool overrideStageFilter = false,
    bool overrideClosingDateFilter = false,
    bool overrideWorkQueueFilter = false,
  }) {
    final query = (searchQuery ?? state.searchQuery).trim().toLowerCase();
    final selectedStage = overrideStageFilter
        ? stageFilter
        : stageFilter ?? state.stageFilter;
    final selectedAssignedTo = (assignedToFilter ?? state.assignedToFilter).trim();
    final selectedClosingFilter = overrideClosingDateFilter
        ? closingDateFilter
        : closingDateFilter ?? state.closingDateFilter;
    final selectedWorkQueueFilter = overrideWorkQueueFilter
        ? workQueueFilter
        : workQueueFilter ?? state.workQueueFilter;
    final now = DateTime.now();

    return deals.where((deal) {
      final searchText = [
        deal.clientName,
        deal.clientEmail,
        deal.clientPhone,
        deal.leadName,
        deal.leadPhone,
        deal.propertyTitle,
        deal.propertyLocation,
        deal.assignedToName,
        deal.assignedToEmail,
        deal.notes,
        deal.stage.name,
      ].join(' ').toLowerCase();
      final matchesSearch = query.isEmpty || searchText.contains(query);
      final matchesStage = selectedStage == null || deal.stage == selectedStage;
      final matchesAssignee =
          selectedAssignedTo.isEmpty || deal.assignedTo == selectedAssignedTo;
      final matchesClosingDate = selectedClosingFilter == null ||
          _matchesClosingDate(deal, selectedClosingFilter, now);
      final matchesWorkQueue = selectedWorkQueueFilter == null ||
          _matchesWorkQueue(deal, selectedWorkQueueFilter, now);
      return matchesSearch &&
          matchesStage &&
          matchesAssignee &&
          matchesClosingDate &&
          matchesWorkQueue;
    }).toList();
  }

  bool _matchesWorkQueue(
    Deal deal,
    DealWorkQueueFilter filter,
    DateTime now,
  ) {
    final open = DashboardTruthRules.isOpenDeal(deal);
    switch (filter) {
      case DealWorkQueueFilter.open:
        return open;
      case DealWorkQueueFilter.atRisk:
        if (!open) {
          return false;
        }
        return DashboardTruthRules.isDealAtRisk(deal, now);
      case DealWorkQueueFilter.wonThisMonth:
        final closedAt = (deal.closingDate ?? deal.updatedAt ?? deal.createdAt)?.toLocal();
        return deal.stage == DealStage.won &&
            closedAt != null &&
            closedAt.year == now.year &&
            closedAt.month == now.month;
    }
  }

  bool _matchesClosingDate(
    Deal deal,
    DealClosingDateFilter filter,
    DateTime now,
  ) {
    final closingDate = deal.closingDate;
    if (closingDate == null) {
      return false;
    }
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(closingDate.year, closingDate.month, closingDate.day);
    switch (filter) {
      case DealClosingDateFilter.past:
        return day.isBefore(today);
      case DealClosingDateFilter.thisWeek:
        final weekEnd = today.add(Duration(days: 7 - today.weekday));
        return !day.isBefore(today) && !day.isAfter(weekEnd);
      case DealClosingDateFilter.thisMonth:
        return day.year == today.year && day.month == today.month;
    }
  }

  DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  String _dealErrorMessage(Object error) {
    if (error is DealException) {
      return error.message;
    }
    return AppErrorMessages.unknown;
  }

  Future<void> _writeAuditLog({
    required String companyId,
    required String actorId,
    required AuditLogAction action,
    required String recordId,
    required String recordTitle,
    required String recordSubtitle,
    required Map<String, Object?> metadata,
  }) async {
    try {
      await _createAuditLogUseCase(
        companyId: companyId,
        auditLog: AuditLog(
          id: '',
          companyId: companyId,
          actorId: actorId,
          actorName: '',
          actorEmail: '',
          actorRole: '',
          action: action,
          module: AuditLogModule.deals,
          recordId: recordId,
          recordTitle: recordTitle,
          recordSubtitle: recordSubtitle,
          createdAt: DateTime.now(),
          metadata: metadata,
        ),
      );
    } catch (_) {
      // Audit logging is best-effort and must not block deal workflows.
    }
  }

  @override
  Future<void> close() {
    _dealsInitialLoadTimeout.cancel();
    _dealsSubscription?.cancel();
    return super.close();
  }
}

String _dealTitle(Deal deal) {
  final clientName = deal.clientName.trim();
  final propertyTitle = deal.propertyTitle.trim();
  if (clientName.isNotEmpty && propertyTitle.isNotEmpty) {
    return '$clientName - $propertyTitle';
  }
  if (clientName.isNotEmpty) {
    return clientName;
  }
  if (propertyTitle.isNotEmpty) {
    return propertyTitle;
  }
  return 'Deal';
}

String _dealSubtitle(Deal deal) {
  final location = deal.propertyLocation.trim();
  if (location.isNotEmpty) {
    return location;
  }
  return dealStageToValue(deal.stage);
}
