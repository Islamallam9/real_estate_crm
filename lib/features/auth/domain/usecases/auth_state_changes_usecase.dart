import '../entities/app_user.dart';
import '../repositories/auth_repository.dart';

class AuthStateChangesUseCase {
  const AuthStateChangesUseCase(this._repository);

  final AuthRepository _repository;

  Stream<AppUser?> call() {
    return _repository.authStateChanges();
  }
}
