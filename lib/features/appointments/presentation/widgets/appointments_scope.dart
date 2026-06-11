import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/datasources/appointments_remote_data_source.dart';
import '../../data/repositories/appointment_repository_impl.dart';
import '../../domain/usecases/get_appointment_related_record_options_usecase.dart';
import '../../domain/usecases/save_appointment_usecase.dart';
import '../../domain/usecases/watch_appointment_usecase.dart';
import '../../domain/usecases/watch_appointments_usecase.dart';
import '../../../audit_logs/data/datasources/audit_logs_remote_data_source.dart';
import '../../../audit_logs/data/repositories/audit_log_repository_impl.dart';
import '../../../audit_logs/domain/usecases/create_audit_log_usecase.dart';
import '../cubit/appointments_cubit.dart';

class AppointmentsScope extends StatelessWidget {
  const AppointmentsScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final repository = AppointmentRepositoryImpl(
      remoteDataSource: FirebaseAppointmentsRemoteDataSource(),
    );
    final auditLogRepository = AuditLogRepositoryImpl(
      remoteDataSource: FirestoreAuditLogsRemoteDataSource(),
    );

    return BlocProvider(
      create: (_) => AppointmentsCubit(
        watchAppointmentsUseCase: WatchAppointmentsUseCase(repository),
        watchAppointmentUseCase: WatchAppointmentUseCase(repository),
        saveAppointmentUseCase: SaveAppointmentUseCase(repository),
        createAuditLogUseCase: CreateAuditLogUseCase(auditLogRepository),
        getRelatedRecordOptionsUseCase:
            GetAppointmentRelatedRecordOptionsUseCase(repository),
      ),
      child: child,
    );
  }
}
