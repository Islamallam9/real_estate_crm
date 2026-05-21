import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../audit_logs/data/datasources/audit_logs_remote_data_source.dart';
import '../../../audit_logs/data/repositories/audit_log_repository_impl.dart';
import '../../../audit_logs/domain/usecases/create_audit_log_usecase.dart';
import '../../data/datasources/clients_remote_data_source.dart';
import '../../data/repositories/client_repository_impl.dart';
import '../../domain/usecases/archive_client_usecase.dart';
import '../../domain/usecases/assign_client_usecase.dart';
import '../../domain/usecases/create_client_usecase.dart';
import '../../domain/usecases/restore_client_usecase.dart';
import '../../domain/usecases/update_client_usecase.dart';
import '../../domain/usecases/watch_client_usecase.dart';
import '../../domain/usecases/watch_clients_usecase.dart';
import '../cubit/clients_cubit.dart';

class ClientsScope extends StatelessWidget {
  const ClientsScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final repository = ClientRepositoryImpl(
      remoteDataSource: FirestoreClientsRemoteDataSource(),
    );
    final auditLogRepository = AuditLogRepositoryImpl(
      remoteDataSource: FirestoreAuditLogsRemoteDataSource(),
    );

    return BlocProvider(
      create: (_) => ClientsCubit(
        watchClientsUseCase: WatchClientsUseCase(repository),
        watchClientUseCase: WatchClientUseCase(repository),
        createClientUseCase: CreateClientUseCase(repository),
        updateClientUseCase: UpdateClientUseCase(repository),
        assignClientUseCase: AssignClientUseCase(repository),
        archiveClientUseCase: ArchiveClientUseCase(repository),
        restoreClientUseCase: RestoreClientUseCase(repository),
        createAuditLogUseCase: CreateAuditLogUseCase(auditLogRepository),
      ),
      child: child,
    );
  }
}
