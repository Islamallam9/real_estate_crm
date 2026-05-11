import '../repositories/client_repository.dart';

class AssignClientUseCase {
  const AssignClientUseCase(this._repository);

  final ClientRepository _repository;

  Future<void> call({
    required String companyId,
    required String clientId,
    required String assignedTo,
    required String assignedToName,
    required String assignedToEmail,
    required String updatedBy,
  }) {
    return _repository.assignClient(
      companyId: companyId,
      clientId: clientId,
      assignedTo: assignedTo,
      assignedToName: assignedToName,
      assignedToEmail: assignedToEmail,
      updatedBy: updatedBy,
    );
  }
}
