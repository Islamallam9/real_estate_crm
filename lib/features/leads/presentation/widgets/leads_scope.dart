import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../audit_logs/data/datasources/audit_logs_remote_data_source.dart';
import '../../../audit_logs/data/repositories/audit_log_repository_impl.dart';
import '../../../audit_logs/domain/usecases/create_audit_log_usecase.dart';
import '../../data/datasources/leads_remote_data_source.dart';
import '../../data/datasources/lead_notes_remote_data_source.dart';
import '../../data/datasources/lead_timeline_remote_data_source.dart';
import '../../data/repositories/lead_notes_repository_impl.dart';
import '../../data/repositories/lead_timeline_repository_impl.dart';
import '../../data/repositories/leads_repository_impl.dart';
import '../../domain/usecases/add_lead_note_usecase.dart';
import '../../domain/usecases/add_lead_timeline_event_usecase.dart';
import '../../domain/usecases/create_lead_usecase.dart';
import '../../domain/usecases/archive_lead_usecase.dart';
import '../../domain/usecases/get_lead_by_id_usecase.dart';
import '../../domain/usecases/restore_lead_usecase.dart';
import '../../domain/usecases/update_lead_usecase.dart';
import '../../domain/usecases/watch_lead_notes_usecase.dart';
import '../../domain/usecases/watch_lead_timeline_usecase.dart';
import '../../domain/usecases/watch_leads_usecase.dart';
import '../cubit/leads_cubit.dart';

class LeadsScope extends StatelessWidget {
  const LeadsScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final remoteDataSource = FirestoreLeadsRemoteDataSource();
    final repository = LeadsRepositoryImpl(remoteDataSource: remoteDataSource);
    final notesRepository = LeadNotesRepositoryImpl(
      remoteDataSource: FirestoreLeadNotesRemoteDataSource(),
    );
    final timelineRepository = LeadTimelineRepositoryImpl(
      remoteDataSource: FirestoreLeadTimelineRemoteDataSource(),
    );
    final auditLogRepository = AuditLogRepositoryImpl(
      remoteDataSource: FirestoreAuditLogsRemoteDataSource(),
    );

    return BlocProvider(
      create: (_) => LeadsCubit(
        createLeadUseCase: CreateLeadUseCase(
          repository,
          CheckDuplicateLeadUseCase(repository),
        ),
        archiveLeadUseCase: ArchiveLeadUseCase(repository),
        restoreLeadUseCase: RestoreLeadUseCase(repository),
        updateLeadUseCase: UpdateLeadUseCase(
          repository,
          CheckDuplicateLeadUseCase(repository),
        ),
        getLeadByIdUseCase: GetLeadByIdUseCase(repository),
        watchLeadsUseCase: WatchLeadsUseCase(repository),
        addLeadNoteUseCase: AddLeadNoteUseCase(notesRepository),
        watchLeadNotesUseCase: WatchLeadNotesUseCase(notesRepository),
        addLeadTimelineEventUseCase: AddLeadTimelineEventUseCase(
          timelineRepository,
        ),
        watchLeadTimelineUseCase: WatchLeadTimelineUseCase(timelineRepository),
        createAuditLogUseCase: CreateAuditLogUseCase(auditLogRepository),
      ),
      child: child,
    );
  }
}
