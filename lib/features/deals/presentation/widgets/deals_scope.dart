import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/datasources/deals_remote_data_source.dart';
import '../../data/repositories/deal_repository_impl.dart';
import '../../domain/usecases/archive_deal_usecase.dart';
import '../../domain/usecases/create_deal_usecase.dart';
import '../../domain/usecases/update_deal_stage_usecase.dart';
import '../../domain/usecases/update_deal_usecase.dart';
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

    return BlocProvider(
      create: (_) => DealsCubit(
        watchDealsUseCase: WatchDealsUseCase(repository),
        createDealUseCase: CreateDealUseCase(repository),
        updateDealUseCase: UpdateDealUseCase(repository),
        updateDealStageUseCase: UpdateDealStageUseCase(repository),
        archiveDealUseCase: ArchiveDealUseCase(repository),
      ),
      child: child,
    );
  }
}
