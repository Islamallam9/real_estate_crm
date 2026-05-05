import '../entities/lead.dart';
import '../repositories/leads_repository.dart';

class WatchLeadsUseCase {
  const WatchLeadsUseCase(this._repository);

  final LeadsRepository _repository;

  Stream<List<Lead>> call({required String companyId, int limit = 30}) {
    return _repository.watchLeads(companyId: companyId, limit: limit);
  }
}
