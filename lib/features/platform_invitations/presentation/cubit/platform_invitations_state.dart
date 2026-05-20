import 'package:equatable/equatable.dart';

import '../../domain/entities/platform_invitation.dart';

enum PlatformInvitationsStatus { initial, loading, ready, saving, failure }

enum PlatformInvitationFilter { all, active, used, expired, revoked }

class PlatformInvitationsState extends Equatable {
  const PlatformInvitationsState({
    required this.status,
    this.invitations = const [],
    this.filter = PlatformInvitationFilter.all,
    this.createdInvitation,
    this.activeActionId,
    this.message,
  });

  const PlatformInvitationsState.initial()
    : this(status: PlatformInvitationsStatus.initial);

  final PlatformInvitationsStatus status;
  final List<PlatformInvitation> invitations;
  final PlatformInvitationFilter filter;
  final CreatedCompanyInvitation? createdInvitation;
  final String? activeActionId;
  final String? message;

  List<PlatformInvitation> get filteredInvitations {
    if (filter == PlatformInvitationFilter.all) {
      return invitations;
    }
    final statusName = filter.name;
    return invitations
        .where((invitation) => invitation.status == statusName)
        .toList();
  }

  PlatformInvitationsState copyWith({
    PlatformInvitationsStatus? status,
    List<PlatformInvitation>? invitations,
    PlatformInvitationFilter? filter,
    CreatedCompanyInvitation? createdInvitation,
    String? activeActionId,
    String? message,
    bool clearCreatedInvitation = false,
    bool clearActiveAction = false,
    bool clearMessage = false,
  }) {
    return PlatformInvitationsState(
      status: status ?? this.status,
      invitations: invitations ?? this.invitations,
      filter: filter ?? this.filter,
      createdInvitation: clearCreatedInvitation
          ? null
          : createdInvitation ?? this.createdInvitation,
      activeActionId:
          clearActiveAction ? null : activeActionId ?? this.activeActionId,
      message: clearMessage ? null : message ?? this.message,
    );
  }

  @override
  List<Object?> get props => [
    status,
    invitations,
    filter,
    createdInvitation,
    activeActionId,
    message,
  ];
}
