import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/export_request.dart';
import '../../domain/usecases/generate_export_usecase.dart';
import '../../domain/usecases/get_export_eligible_assignees_usecase.dart';
import 'export_state.dart';

class ExportCubit extends Cubit<ExportState> {
  ExportCubit({
    required GenerateExportUseCase generateExportUseCase,
    required GetExportEligibleAssigneesUseCase getEligibleAssigneesUseCase,
  })  : _generateExportUseCase = generateExportUseCase,
        _getEligibleAssigneesUseCase = getEligibleAssigneesUseCase,
        super(const ExportState());

  final GenerateExportUseCase _generateExportUseCase;
  final GetExportEligibleAssigneesUseCase _getEligibleAssigneesUseCase;

  Future<void> loadAssignees(ExportActor actor) async {
    try {
      final assignees = await _getEligibleAssigneesUseCase(actor);
      emit(state.copyWith(assignees: assignees, clearMessage: true));
    } catch (_) {
      emit(state.copyWith(assignees: const []));
    }
  }

  void setModule(ExportModule module) {
    emit(
      state.copyWith(
        module: module,
        filters: state.filters.copyWith(status: '', assigneeId: ''),
        selectedColumns: const <String>[],
        clearResult: true,
        clearMessage: true,
      ),
    );
  }

  void setDateRange(ExportDateRangePreset dateRange) {
    emit(
      state.copyWith(
        filters: state.filters.copyWith(
          dateRange: dateRange,
          clearCustomDates: dateRange != ExportDateRangePreset.custom,
        ),
        clearResult: true,
        clearMessage: true,
      ),
    );
  }

  void setAssignee(String assigneeId) {
    emit(
      state.copyWith(
        filters: state.filters.copyWith(assigneeId: assigneeId),
        clearResult: true,
        clearMessage: true,
      ),
    );
  }

  void setStatus(String status) {
    emit(
      state.copyWith(
        filters: state.filters.copyWith(status: status),
        clearResult: true,
        clearMessage: true,
      ),
    );
  }

  void setIncludeArchived(bool includeArchived) {
    emit(
      state.copyWith(
        filters: state.filters.copyWith(includeArchived: includeArchived),
        clearResult: true,
        clearMessage: true,
      ),
    );
  }

  void setOutputLanguage(ExportOutputLanguage language) {
    emit(
      state.copyWith(
        filters: state.filters.copyWith(outputLanguage: language),
        clearResult: true,
        clearMessage: true,
      ),
    );
  }

  void toggleAdvancedColumns(bool value) {
    emit(
      state.copyWith(
        advancedColumns: value,
        selectedColumns: value ? state.selectedColumns : const <String>[],
        clearResult: true,
        clearMessage: true,
      ),
    );
  }

  void toggleColumn(String columnId, bool selected) {
    final next = state.selectedColumns.toSet();
    if (selected) {
      next.add(columnId);
    } else {
      next.remove(columnId);
    }
    emit(
      state.copyWith(
        selectedColumns: next.toList(growable: false),
        clearResult: true,
        clearMessage: true,
      ),
    );
  }

  Future<void> generate(ExportRequest request) async {
    emit(state.copyWith(status: ExportStatus.generating, clearMessage: true));
    try {
      final result = await _generateExportUseCase(request);
      emit(state.copyWith(status: ExportStatus.success, result: result));
    } catch (error) {
      emit(
        state.copyWith(
          status: ExportStatus.failure,
          message: error.toString(),
        ),
      );
    }
  }
}
