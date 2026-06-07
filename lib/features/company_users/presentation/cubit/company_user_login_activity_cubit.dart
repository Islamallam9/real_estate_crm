import 'dart:async';

import 'package:bloc/bloc.dart';

import '../../data/datasources/company_users_remote_data_source.dart';
import '../../domain/entities/company_user_login_activity.dart';
import 'company_user_login_activity_state.dart';

class CompanyUserLoginActivityCubit
    extends Cubit<CompanyUserLoginActivityState> {
  CompanyUserLoginActivityCubit({
    required CompanyUsersRemoteDataSource remoteDataSource,
  })  : _remoteDataSource = remoteDataSource,
        super(const CompanyUserLoginActivityState.initial());

  final CompanyUsersRemoteDataSource _remoteDataSource;
  StreamSubscription<List<CompanyUserLoginActivity>>? _subscription;

  void watch({
    required String companyId,
    required String uid,
    int limit = 25,
  }) {
    _subscription?.cancel();
    emit(
      state.copyWith(
        status: CompanyUserLoginActivityStatus.loading,
        clearMessage: true,
      ),
    );
    _subscription = _remoteDataSource
        .watchUserLoginActivity(
          companyId: companyId,
          uid: uid,
          limit: limit,
        )
        .listen(
      (activities) {
        emit(
          state.copyWith(
            status: activities.isEmpty
                ? CompanyUserLoginActivityStatus.empty
                : CompanyUserLoginActivityStatus.loaded,
            activities: activities,
            clearMessage: true,
          ),
        );
      },
      onError: (error) {
        emit(
          state.copyWith(
            status: CompanyUserLoginActivityStatus.failure,
            activities: const <CompanyUserLoginActivity>[],
            message: _cleanLoginActivityError(error),
          ),
        );
      },
    );
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}

String _cleanLoginActivityError(Object error) {
  var text = error.toString().trim();
  const prefixes = [
    'Exception: ',
    'FirebaseException: ',
    'FirebaseFunctionsException: ',
  ];
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
