import 'package:pristie/src/core/result/result.dart';
import 'package:pristie/src/core/storage/session.dart';

/// Contract providing atomic access and lifecycle mutations for session credentials.
abstract interface class SessionTokenProvider {
  /// Reads the active [Session], returning `null` if no active session exists.
  Future<Result<Session?>> readSession();

  /// Reads the refresh token for revocation only when status is [SessionStatus.logoutPending].
  Future<Result<String?>> readRefreshTokenForRevocation();

  /// Returns whether an active authenticated session currently exists.
  Future<Result<bool>> hasSession();

  /// Reads the persisted atomic [SessionRecord], or returns `null` if not found.
  Future<Result<SessionRecord?>> readRecord();

  /// Atomically writes a new active [Session].
  Future<Result<void>> writeSession(Session session);

  /// Atomically transitions the session record to [SessionStatus.logoutPending].
  Future<Result<void>> beginLogout();

  /// Atomically transitions the session record to [SessionStatus.sessionInvalidationPending].
  Future<Result<void>> beginInvalidation();

  /// Atomically records [SessionStatus.signedOut] and discards credential tokens.
  Future<Result<void>> clearSession();
}
