import '../../../../core/constants/role_constants.dart';
import '../entities/attention_reminder.dart';
import '../repositories/notification_repository.dart';

class WatchAttentionRemindersUseCase {
  const WatchAttentionRemindersUseCase(this._repository);

  final NotificationRepository _repository;

  Stream<List<AttentionReminder>> call({
    required String companyId,
    required String currentUserId,
    required UserRole role,
    String? managerTeamId,
    int limit = 60,
  }) {
    return _repository.watchAttentionReminders(
      companyId: companyId,
      currentUserId: currentUserId,
      role: role,
      managerTeamId: managerTeamId,
      limit: limit,
    );
  }
}
