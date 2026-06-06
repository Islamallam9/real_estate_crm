import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../audit_logs/data/datasources/audit_logs_remote_data_source.dart';
import '../../../audit_logs/data/repositories/audit_log_repository_impl.dart';
import '../../../audit_logs/domain/usecases/create_audit_log_usecase.dart';
import '../../data/datasources/deals_remote_data_source.dart';
import '../../data/repositories/deal_repository_impl.dart';
import '../../domain/usecases/archive_deal_usecase.dart';
import '../../domain/usecases/create_deal_usecase.dart';
import '../../domain/usecases/restore_deal_usecase.dart';
import '../../domain/usecases/update_deal_stage_usecase.dart';
import '../../domain/usecases/update_deal_usecase.dart';
import '../../domain/usecases/watch_deal_usecase.dart';
import '../../domain/usecases/watch_deals_usecase.dart';
import '../cubit/deals_cubit.dart';

class DealsScope extends StatelessWidget {
  const DealsScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final repository = DealRepositoryImpl(
      remoteDataSource: FirestoreDealsRemoteDataSource(),
    );
    final auditLogRepository = AuditLogRepositoryImpl(
      remoteDataSource: FirestoreAuditLogsRemoteDataSource(),
    );

    return BlocProvider(
      create: (_) => DealsCubit(
        watchDealUseCase: WatchDealUseCase(repository),
        watchDealsUseCase: WatchDealsUseCase(repository),
        createDealUseCase: CreateDealUseCase(repository),
        updateDealUseCase: UpdateDealUseCase(repository),
        updateDealStageUseCase: UpdateDealStageUseCase(repository),
        archiveDealUseCase: ArchiveDealUseCase(repository),
        restoreDealUseCase: RestoreDealUseCase(repository),
        createAuditLogUseCase: CreateAuditLogUseCase(auditLogRepository),
      ),
      child: child,
    );
  }
}
