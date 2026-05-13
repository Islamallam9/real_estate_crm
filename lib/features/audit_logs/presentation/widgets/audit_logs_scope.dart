import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/datasources/audit_logs_remote_data_source.dart';
import '../../data/repositories/audit_log_repository_impl.dart';
import '../../domain/usecases/watch_audit_logs_usecase.dart';
import '../cubit/audit_logs_cubit.dart';

class AuditLogsScope extends StatelessWidget {
  const AuditLogsScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final repository = AuditLogRepositoryImpl(
      remoteDataSource: FirestoreAuditLogsRemoteDataSource(),
    );

    return BlocProvider(
      create: (_) => AuditLogsCubit(
        watchAuditLogsUseCase: WatchAuditLogsUseCase(repository),
      ),
      child: child,
    );
  }
}
