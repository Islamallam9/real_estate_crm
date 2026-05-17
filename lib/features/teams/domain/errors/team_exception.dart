class TeamException implements Exception {
  const TeamException(this.message);

  final String message;

  @override
  String toString() => message;
}

abstract final class TeamErrorMessages {
  static const permissionDenied = 'team/permission-denied';
  static const unauthenticated = 'team/unauthenticated';
  static const inactiveUser = 'team/inactive-user';
  static const inactiveTeam = 'team/inactive-team';
  static const ineligibleMember = 'team/ineligible-member';
  static const managerUnavailable = 'team/manager-unavailable';
  static const managerAlreadyHasTeam = 'team/manager-already-has-team';
  static const userNotFound = 'team/user-not-found';
  static const teamNotFound = 'team/team-not-found';
  static const companyInactive = 'team/company-inactive';
  static const companyMismatch = 'team/company-mismatch';
  static const connection = 'team/connection';
  static const changed = 'team/changed';
  static const invalidInput = 'team/invalid-input';
  static const unknown = 'team/unknown';
}
