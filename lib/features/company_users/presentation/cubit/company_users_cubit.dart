import 'dart:async';

import 'package:bloc/bloc.dart';

import '../../data/datasources/company_users_remote_data_source.dart';
import 'company_users_state.dart';

class CompanyUsersCubit extends Cubit<CompanyUsersState> {
  CompanyUsersCubit({required CompanyUsersRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource,
        super(const CompanyUsersState.initial());

  final CompanyUsersRemoteDataSource _remoteDataSource;
  StreamSubscription? _subscription;

  void watch(String companyId) {
    _subscription?.cancel();
    emit(state.copyWith(status: CompanyUsersStatus.loading, clearMessage: true));
    _subscription = _remoteDataSource.watchUsers(companyId: companyId).listen(
      (users) {
        emit(state.copyWith(status: CompanyUsersStatus.ready, users: users));
      },
      onError: (error) {
        emit(
          state.copyWith(
            status: CompanyUsersStatus.failure,
            message: _cleanCompanyUserError(error),
          ),
        );
      },
    );
  }

  void updateQuery(String query) {
    emit(state.copyWith(query: query, clearMessage: true));
  }

  void applyRoleFilter(String? role) {
    emit(
      state.copyWith(
        roleFilter: role?.trim() ?? '',
        clearRoleFilter: role == null || role.trim().isEmpty,
        clearMessage: true,
      ),
    );
  }

  void applyActiveFilter(bool? isActive) {
    emit(
      state.copyWith(
        activeFilter: isActive,
        clearActiveFilter: isActive == null,
        clearMessage: true,
      ),
    );
  }

  void clearFilters() {
    emit(
      state.copyWith(
        query: '',
        clearRoleFilter: true,
        clearActiveFilter: true,
        clearMessage: true,
      ),
    );
  }

  void clearCreatedResult() {
    emit(state.copyWith(clearCreatedResult: true));
  }

  Future<bool> addUser({
    required String companyId,
    required String fullName,
    required String email,
    required String phone,
    required String role,
    String? temporaryPassword,
  }) async {
    emit(
      state.copyWith(
        status: CompanyUsersStatus.saving,
        clearMessage: true,
        clearCreatedResult: true,
      ),
    );
    try {
      final result = await _remoteDataSource.addUser(
        companyId: companyId,
        fullName: fullName,
        email: email,
        phone: phone,
        role: role,
        temporaryPassword: temporaryPassword,
      );
      emit(
        state.copyWith(
          status: CompanyUsersStatus.ready,
          createdResult: result,
        ),
      );
      return true;
    } catch (error) {
      emit(
        state.copyWith(
          status: CompanyUsersStatus.failure,
          message: _cleanCompanyUserError(error),
        ),
      );
      return false;
    }
  }

  Future<String?> generateSetupLink({
    required String companyId,
    required String uid,
  }) async {
    try {
      final link = await _remoteDataSource.generateSetupLink(
        companyId: companyId,
        uid: uid,
      );
      return link.trim().isEmpty ? null : link;
    } catch (error) {
      emit(state.copyWith(message: _cleanCompanyUserError(error)));
      return null;
    }
  }


  Future<bool> setUserActiveStatus({
    required String companyId,
    required String uid,
    required bool isActive,
  }) async {
    emit(state.copyWith(status: CompanyUsersStatus.saving, clearMessage: true));
    try {
      await _remoteDataSource.setUserActiveStatus(
        companyId: companyId,
        uid: uid,
        isActive: isActive,
      );
      emit(state.copyWith(status: CompanyUsersStatus.ready));
      return true;
    } catch (error) {
      emit(
        state.copyWith(
          status: CompanyUsersStatus.failure,
          message: _cleanCompanyUserError(error),
        ),
      );
      return false;
    }
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}

String _cleanCompanyUserError(Object error) {
  var text = error.toString().trim();
  const prefixes = ['Exception: ', 'FirebaseException: ', 'FirebaseFunctionsException: '];
  var changed = true;
  while (changed) {
    changed = false;
    for (final prefix in prefixes) {
      if (text.startsWith(prefix)) {
        text = text.substring(prefix.length).trim();
        changed = true;
      }
    }
  }
  return text.isEmpty ? 'unknown' : text;
}
