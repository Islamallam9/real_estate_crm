import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/datasources/clients_remote_data_source.dart';
import '../../data/repositories/client_repository_impl.dart';
import '../../domain/usecases/archive_client_usecase.dart';
import '../../domain/usecases/create_client_usecase.dart';
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

    return BlocProvider(
      create: (_) => ClientsCubit(
        watchClientsUseCase: WatchClientsUseCase(repository),
        watchClientUseCase: WatchClientUseCase(repository),
        createClientUseCase: CreateClientUseCase(repository),
        updateClientUseCase: UpdateClientUseCase(repository),
        archiveClientUseCase: ArchiveClientUseCase(repository),
      ),
      child: child,
    );
  }
}
