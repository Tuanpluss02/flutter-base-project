import 'package:base/src/core/auth/auth_session_controller.dart';
import 'package:base/src/core/auth/session_service.dart';
import 'package:base/src/core/error/app_failure.dart';
import 'package:base/src/core/network/token_refresher.dart';
import 'package:base/src/core/result/result.dart';
import 'package:base/src/core/storage/session.dart';
import 'package:base/src/core/storage/session_token_provider.dart';

/// Contract for revoking a refresh token with the remote authorization server on logout.
abstract interface class LogoutRevoker {
  /// Revokes [refreshToken] remotely.
  Future<Result<void>> revoke(String refreshToken);
}

/// Coordinates single-flight token refresh, session invalidation, and logout workflows.
final class AuthCoordinator {
  /// Creates an [AuthCoordinator] managing session authentication lifecycle.
  AuthCoordinator({
    required this.tokens,
    required this.session,
    required this.refresher,
    this.revoker,
  });

  /// Storage provider accessing and updating persistent session tokens.
  final SessionTokenProvider tokens;

  /// Authentication controller managing state, gate, and epochs.
  final AuthSessionController session;

  /// Dedicated service exchanging refresh tokens for active sessions.
  final TokenRefresher refresher;

  /// Optional remote revocation service executed during logout.
  final LogoutRevoker? revoker;

  Future<Result<Session>>? _inFlight;

  /// Ensures a valid session is active for the current [requestEpoch].
  Future<Result<Session>> ensureSession(int requestEpoch) async {
    if (session.sessionEpoch != requestEpoch || !session.isRequestGateOpen) {
      return const Result.err(AppFailure.unauthorized());
    }

    if (_inFlight != null) {
      return _inFlight!;
    }

    final future = _performRefresh(requestEpoch);
    _inFlight = future;
    try {
      return await future;
    } finally {
      if (identical(_inFlight, future)) {
        _inFlight = null;
      }
    }
  }

  Future<Result<Session>> _performRefresh(int requestEpoch) async {
    final recordResult = await tokens.readRecord();
    if (recordResult is Err) {
      return const Result.err(AppFailure.localPersistence());
    }
    final record = (recordResult as Ok<SessionRecord?>).data;
    if (record == null ||
        record.status != SessionStatus.active ||
        record.session == null) {
      return const Result.err(AppFailure.unauthorized());
    }

    final currentRefreshToken = record.session!.refreshToken;
    final refreshResult = await refresher.refresh(currentRefreshToken);

    if (session.sessionEpoch != requestEpoch) {
      return const Result.err(AppFailure.unauthorized());
    }

    switch (refreshResult) {
      case Ok(:final data):
        final writeResult = await tokens.writeSession(data);
        switch (writeResult) {
          case Ok():
            return Result.ok(data);
          case Err():
            await session.invalidateSession();
            return const Result.err(AppFailure.localPersistence());
        }

      case Err(:final failure):
        switch (failure) {
          case ValidationFailure() ||
              UnauthorizedFailure() ||
              ForbiddenFailure():
            final invResult = await session.invalidateSession();
            switch (invResult) {
              case Ok():
                return const Result.err(AppFailure.unauthorized());
              case Err(:final failure):
                return Result.err(failure);
            }

          case RateLimitFailure():
            return Result.err(failure);

          default:
            return Result.err(failure);
        }
    }
  }

  /// Initiates user logout, revoking tokens when a revoker is provided and clearing session state.
  Future<Result<void>> logout() async {
    if (session is SessionService) {
      return (session as SessionService).logout(revoker);
    }
    return session.logout();
  }

  /// Invalidates the current session due to credential expiry or revocation.
  Future<Result<void>> invalidateSession() async {
    return session.invalidateSession();
  }
}
