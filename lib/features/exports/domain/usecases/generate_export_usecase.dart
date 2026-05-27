import '../entities/export_request.dart';
import '../entities/export_result.dart';
import '../repositories/export_repository.dart';

class GenerateExportUseCase {
  const GenerateExportUseCase(this._repository);

  final ExportRepository _repository;

  Future<ExportResult> call(ExportRequest request) {
    return _repository.generateExport(request);
  }
}
