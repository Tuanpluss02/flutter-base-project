import 'package:base/src/core/result/result.dart';

/// Sink for triggering asynchronous session lifecycle transitions.
abstract interface class SessionStateSink {
  /// Initiates user logout and session credential clearance.
  Future<Result<void>> logout();

  /// Initiates session invalidation due to token rejection or expiration.
  Future<Result<void>> invalidateSession();
}
