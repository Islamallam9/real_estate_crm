import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../audit_logs/data/datasources/audit_logs_remote_data_source.dart';
import '../../../audit_logs/data/repositories/audit_log_repository_impl.dart';
import '../../../audit_logs/domain/usecases/create_audit_log_usecase.dart';
import '../../data/datasources/properties_remote_data_source.dart';
import '../../data/repositories/property_repository_impl.dart';
import '../../domain/usecases/create_property_usecase.dart';
import '../../domain/usecases/deactivate_property_usecase.dart';
import '../../domain/usecases/update_property_usecase.dart';
import '../../domain/usecases/watch_property_usecase.dart';
import '../../domain/usecases/watch_properties_usecase.dart';
import '../cubit/properties_cubit.dart';

class PropertiesScope extends StatelessWidget {
  const PropertiesScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final repository = PropertyRepositoryImpl(
      remoteDataSource: FirestorePropertiesRemoteDataSource(),
    );
    final auditLogRepository = AuditLogRepositoryImpl(
      remoteDataSource: FirestoreAuditLogsRemoteDataSource(),
    );

    return BlocProvider(
      create: (_) => PropertiesCubit(
        watchPropertyUseCase: WatchPropertyUseCase(repository),
        watchPropertiesUseCase: WatchPropertiesUseCase(repository),
        createPropertyUseCase: CreatePropertyUseCase(repository),
        updatePropertyUseCase: UpdatePropertyUseCase(repository),
        deactivatePropertyUseCase: DeactivatePropertyUseCase(repository),
        createAuditLogUseCase: CreateAuditLogUseCase(auditLogRepository),
      ),
      child: child,
    );
  }
}
