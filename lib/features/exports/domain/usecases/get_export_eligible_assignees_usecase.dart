import '../entities/export_assignee.dart';
import '../entities/export_request.dart';
import '../repositories/export_repository.dart';

class GetExportEligibleAssigneesUseCase {
  const GetExportEligibleAssigneesUseCase(this._repository);

  final ExportRepository _repository;

  Future<List<ExportAssignee>> call(ExportActor actor) {
    return _repository.getEligibleAssignees(actor);
  }
}
