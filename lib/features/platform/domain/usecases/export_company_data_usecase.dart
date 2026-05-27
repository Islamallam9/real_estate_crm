import '../repositories/platform_repository.dart';

class ExportCompanyDataUseCase {
  const ExportCompanyDataUseCase(this._repository);

  final PlatformRepository _repository;

  Future<Map<String, dynamic>> call({
    required String companyId,
    List<String>? collections,
  }) {
    return _repository.exportCompanyData(
      companyId: companyId,
      collections: collections,
    );
  }
}
