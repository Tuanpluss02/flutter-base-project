/// High-level authentication states of the application runtime.
enum AuthState {
  /// Initial state before session inspection has concluded.
  unknown,

  /// Active valid session restored or authenticated.
  authenticated,

  /// No active session exists.
  unauthenticated,

  /// Session store failed closed or transition error requires re-authentication.
  locked,
}
