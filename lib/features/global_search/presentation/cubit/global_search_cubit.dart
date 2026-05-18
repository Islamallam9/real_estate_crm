import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/role_constants.dart';
import '../../domain/entities/global_search_result.dart';
import '../../domain/usecases/search_global_data_usecase.dart';
import 'global_search_state.dart';

class GlobalSearchCubit extends Cubit<GlobalSearchState> {
  GlobalSearchCubit({
    required SearchGlobalDataUseCase searchGlobalDataUseCase,
    required String companyId,
    required String currentUserId,
    required UserRole role,
    required bool includeUsers,
    required Set<GlobalSearchModule> enabledModules,
  })  : _searchGlobalDataUseCase = searchGlobalDataUseCase,
        _companyId = companyId,
        _currentUserId = currentUserId,
        _role = role,
        _includeUsers = includeUsers,
        _enabledModules = enabledModules,
        super(const GlobalSearchState());

  final SearchGlobalDataUseCase _searchGlobalDataUseCase;
  final String _companyId;
  final String _currentUserId;
  final UserRole _role;
  final bool _includeUsers;
  final Set<GlobalSearchModule> _enabledModules;

  Timer? _debounce;
  int _searchVersion = 0;

  void queryChanged(String value) {
    final query = value.trim();
    _debounce?.cancel();

    if (query.length < 2) {
      _searchVersion++;
      emit(GlobalSearchState(query: query));
      return;
    }

    emit(state.copyWith(
      status: GlobalSearchStatus.loading,
      query: query,
      results: const [],
      message: '',
    ));

    final version = ++_searchVersion;
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _search(query, version);
    });
  }

  Future<void> _search(String query, int version) async {
    try {
      final results = await _searchGlobalDataUseCase(
        companyId: _companyId,
        currentUserId: _currentUserId,
        role: _role,
        query: query,
        includeUsers: _includeUsers,
      );
      if (isClosed || version != _searchVersion) {
        return;
      }
      emit(state.copyWith(
        status: GlobalSearchStatus.ready,
        query: query,
        results: results
            .where((result) => _enabledModules.contains(result.module))
            .toList(growable: false),
        message: '',
      ));
    } catch (_) {
      if (isClosed || version != _searchVersion) {
        return;
      }
      emit(state.copyWith(
        status: GlobalSearchStatus.failure,
        query: query,
        results: const [],
        message: 'search-failed',
      ));
    }
  }

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }
}
