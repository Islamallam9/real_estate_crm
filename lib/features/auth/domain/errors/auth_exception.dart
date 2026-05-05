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
}
