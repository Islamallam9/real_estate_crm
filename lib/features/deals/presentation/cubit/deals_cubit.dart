import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/role_constants.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/utils/initial_load_timeout.dart';
import '../../../audit_logs/domain/entities/audit_log.dart';
import '../../../audit_logs/domain/usecases/create_audit_log_usecase.dart';
import '../../data/datasources/deals_remote_data_source.dart';
import '../../data/models/deal_model.dart';
import '../../domain/entities/deal.dart';
import '../../domain/usecases/archive_deal_usecase.dart';
import '../../domain/usecases/create_deal_usecase.dart';
import '../../domain/usecases/update_deal_stage_usecase.dart';
import '../../domain/usecases/update_deal_usecase.dart';
import '../../domain/usecases/watch_deals_usecase.dart';
import 'deals_state.dart';

class DealsCubit extends Cubit<DealsState> {
  DealsCubit({
    required WatchDealsUseCase watchDealsUseCase,
    required CreateDealUseCase createDealUseCase,
    required UpdateDealUseCase updateDealUseCase,
    required UpdateDealStageUseCase updateDealStageUseCase,
    required ArchiveDealUseCase archiveDealUseCase,
    required CreateAuditLogUseCase createAuditLogUseCase,
  }) : _watchDealsUseCase = watchDealsUseCase,
       _createDealUseCase = createDealUseCase,
       _updateDealUseCase = updateDealUseCase,
       _updateDealStageUseCase = updateDealStageUseCase,
       _archiveDealUseCase = archiveDealUseCase,
       _createAuditLogUseCase = createAuditLogUseCase,
       super(const DealsState.initial());

  final WatchDealsUseCase _watchDealsUseCase;
  final CreateDealUseCase _createDealUseCase;
  final UpdateDealUseCase _updateDealUseCase;
  final UpdateDealStageUseCase _updateDealStageUseCase;
  final ArchiveDealUseCase _archiveDealUseCase;
  final CreateAuditLogUseCase _createAuditLogUseCase;

  StreamSubscription<List<Deal>>? _dealsSubscription;
  final InitialLoadTimeout _dealsInitialLoadTimeout = InitialLoadTimeout();

  void watchDeals({
    required String companyId,
    required UserRole role,
    required String currentUserId,
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

  void clearFilters() {
    emit(
      state.copyWith(
        searchQuery: '',
        assignedToFilter: '',
        clearStageFilter: true,
        clearClosingDateFilter: true,
        filteredDeals: _applyFilters(
          state.deals,
          searchQuery: '',
          stageFilter: null,
          assignedToFilter: '',
          closingDateFilter: null,
          overrideStageFilter: true,
          overrideClosingDateFilter: true,
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
  }) {
    final deal = dealById(dealId);
    return _save(
      action: DealsAction.archiveDeal,
      operation: () => _archiveDealUseCase(
        companyId: companyId,
        dealId: dealId,
        updatedBy: updatedBy,
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
            metadata: const {},
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
      emit(
        state.copyWith(
          status: DealsStatus.saved,
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

  List<Deal> _applyFilters(
    List<Deal> deals, {
    String? searchQuery,
    DealStage? stageFilter,
    String? assignedToFilter,
    DealClosingDateFilter? closingDateFilter,
    bool overrideStageFilter = false,
    bool overrideClosingDateFilter = false,
  }) {
    final query = (searchQuery ?? state.searchQuery).trim().toLowerCase();
    final selectedStage = overrideStageFilter
        ? stageFilter
        : stageFilter ?? state.stageFilter;
    final selectedAssignedTo = (assignedToFilter ?? state.assignedToFilter).trim();
    final selectedClosingFilter = overrideClosingDateFilter
        ? closingDateFilter
        : closingDateFilter ?? state.closingDateFilter;
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
      return matchesSearch &&
          matchesStage &&
          matchesAssignee &&
          matchesClosingDate;
    }).toList();
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
