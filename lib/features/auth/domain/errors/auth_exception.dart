class AuthException implements Exception {
  const AuthException(this.message, {this.code = AuthErrorCode.unknown});

  final String message;
  final AuthErrorCode code;
}

enum AuthErrorCode {
  invalidCredentials,
  connection,
  signInFailed,
  signOutFailed,
  profileMissing,
  inactiveAccount,
  accountNotLinked,
  companyInactive,
  tooManyAttempts,
  unknown,
}

abstract final class AuthErrorMessages {
  static const invalidCredentials = 'Invalid email or password.';
  static const connection = 'Connection error. Check your internet connection.';
  static const signInFailed = 'Unable to sign in. Please try again.';
  static const signOutFailed = 'Unable to sign out. Please try again.';
  static const profileMissing = 'Unable to load your user profile.';
  static const inactiveAccount =
      'Your account is inactive. Please contact an administrator.';
  static const accountNotLinked =
      'This account is not linked to an active company.';
  static const companyInactive =
      'This company is inactive. Please contact platform support.';
  static const tooManyAttempts =
      'Too many failed sign-in attempts. Please wait before trying again.';
  static const currentPasswordIncorrect = 'Current password is incorrect.';
  static const recentLoginRequired =
      'Please sign in again before changing your password.';
  static const weakPassword = 'New password is too short.';
  static const passwordChangeFailed =
      'Unable to change password. Please try again.';
}

abstract final class AuthSuccessMessages {
  static const passwordResetSent =
      'Password reset email sent. Check your inbox.';
}
