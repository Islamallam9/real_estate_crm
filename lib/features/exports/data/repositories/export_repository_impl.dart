import '../../domain/entities/export_assignee.dart';
import '../../domain/entities/export_request.dart';
import '../../domain/entities/export_result.dart';
import '../../domain/repositories/export_repository.dart';
import '../datasources/export_file_data_source.dart';
import '../datasources/export_remote_data_source.dart';

class ExportRepositoryImpl implements ExportRepository {
  const ExportRepositoryImpl({
    required ExportRemoteDataSource remoteDataSource,
    required ExportFileDataSource fileDataSource,
  })  : _remoteDataSource = remoteDataSource,
        _fileDataSource = fileDataSource;

  final ExportRemoteDataSource _remoteDataSource;
  final ExportFileDataSource _fileDataSource;

  @override
  Future<ExportResult> generateExport(ExportRequest request) async {
    final dataset = await _remoteDataSource.buildDataset(request);
    final result = _fileDataSource.generateFile(
      request: request,
      dataset: dataset,
    );
    await _remoteDataSource.logExportGenerated(
      request: request,
      dataset: dataset,
    );
    return result;
  }

  @override
  Future<List<ExportAssignee>> getEligibleAssignees(ExportActor actor) {
    return _remoteDataSource.getEligibleAssignees(actor);
  }
}
