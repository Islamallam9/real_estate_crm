import 'package:equatable/equatable.dart';

enum NotificationPushTokenScopeKind { none, company, platformOwner }

class NotificationPushTokenState extends Equatable {
  const NotificationPushTokenState({
    this.scope = NotificationPushTokenScopeKind.none,
    this.companyId = '',
    this.uid = '',
    this.token = '',
    this.isSyncing = false,
  });

  final NotificationPushTokenScopeKind scope;
  final String companyId;
  final String uid;
  final String token;
  final bool isSyncing;

  NotificationPushTokenState copyWith({
    NotificationPushTokenScopeKind? scope,
    String? companyId,
    String? uid,
    String? token,
    bool? isSyncing,
  }) {
    return NotificationPushTokenState(
      scope: scope ?? this.scope,
      companyId: companyId ?? this.companyId,
      uid: uid ?? this.uid,
      token: token ?? this.token,
      isSyncing: isSyncing ?? this.isSyncing,
    );
  }

  @override
  List<Object?> get props => [scope, companyId, uid, token, isSyncing];
}
