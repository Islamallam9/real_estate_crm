import '../entities/export_assignee.dart';
import '../entities/export_request.dart';
import '../entities/export_result.dart';

abstract interface class ExportRepository {
  Future<ExportResult> generateExport(ExportRequest request);

  Future<List<ExportAssignee>> getEligibleAssignees(ExportActor actor);
}
