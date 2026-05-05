import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/datasources/leads_remote_data_source.dart';
import '../../data/repositories/leads_repository_impl.dart';
import '../../domain/usecases/create_lead_usecase.dart';
import '../../domain/usecases/archive_lead_usecase.dart';
import '../../domain/usecases/get_lead_by_id_usecase.dart';
import '../../domain/usecases/update_lead_usecase.dart';
import '../../domain/usecases/watch_leads_usecase.dart';
import '../cubit/leads_cubit.dart';

class LeadsScope extends StatelessWidget {
  const LeadsScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final remoteDataSource = FirestoreLeadsRemoteDataSource();
    final repository = LeadsRepositoryImpl(remoteDataSource: remoteDataSource);

    return BlocProvider(
      create: (_) => LeadsCubit(
        createLeadUseCase: CreateLeadUseCase(repository),
        archiveLeadUseCase: ArchiveLeadUseCase(repository),
        updateLeadUseCase: UpdateLeadUseCase(repository),
        getLeadByIdUseCase: GetLeadByIdUseCase(repository),
        watchLeadsUseCase: WatchLeadsUseCase(repository),
      ),
      child: child,
    );
  }
}
