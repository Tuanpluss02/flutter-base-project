import 'dart:async';

import 'package:pristie/src/core/auth/auth_coordinator.dart';
import 'package:pristie/src/core/auth/auth_session_controller.dart';
import 'package:pristie/src/core/auth/auth_state.dart';
import 'package:pristie/src/core/result/result.dart';
import 'package:pristie/src/core/storage/session.dart';
import 'package:pristie/src/core/storage/session_token_provider.dart';

/// Concrete implementation of [AuthSessionController] managing session epochs and authentication lifecycle.
final class SessionService implements AuthSessionController {
  /// Creates a [SessionService] backed by [SessionTokenProvider].
  SessionService({required this.tokens});

  /// The underlying [SessionTokenProvider] managing token persistence.
  final SessionTokenProvider tokens;

  final StreamController<AuthState> _stateController =
      StreamController<AuthState>.broadcast();

  AuthState _currentAuthState = AuthState.unknown;
  int _sessionEpoch = 0;
  bool _isRequestGateOpen = false;

  @override
  Stream<AuthState> get authStateStream => _stateController.stream;

  @override
  AuthState get currentAuthState => _currentAuthState;

  @override
  int get sessionEpoch => _sessionEpoch;

  @override
  bool get isRequestGateOpen => _isRequestGateOpen;

  @override
  Future<AuthState> restore() async {
    final recordResult = await tokens.readRecord();
    switch (recordResult) {
      case Err():
        _sessionEpoch++;
        _isRequestGateOpen = false;
        _updateState(AuthState.locked);
        return AuthState.locked;
      case Ok(:final data):
        final status = data?.status ?? SessionStatus.signedOut;
        switch (status) {
          case SessionStatus.active:
            if (data?.session != null) {
              _isRequestGateOpen = true;
              _updateState(AuthState.authenticated);
              return AuthState.authenticated;
            }
            _sessionEpoch++;
            _isRequestGateOpen = false;
            _updateState(AuthState.unauthenticated);
            return AuthState.unauthenticated;
          case SessionStatus.logoutPending:
          case SessionStatus.sessionInvalidationPending:
            _sessionEpoch++;
            _isRequestGateOpen = false;
            final clearResult = await tokens.clearSession();
            switch (clearResult) {
              case Ok():
                _updateState(AuthState.unauthenticated);
                return AuthState.unauthenticated;
              case Err():
                _updateState(AuthState.locked);
                return AuthState.locked;
            }
          case SessionStatus.signedOut:
            _isRequestGateOpen = false;
            _updateState(AuthState.unauthenticated);
            return AuthState.unauthenticated;
        }
    }
  }

  @override
  Future<Result<void>> login(Session session) async {
    final writeResult = await tokens.writeSession(session);
    switch (writeResult) {
      case Ok():
        _sessionEpoch++;
        _isRequestGateOpen = true;
        _updateState(AuthState.authenticated);
        return const Result.ok(null);
      case Err(:final failure):
        _sessionEpoch++;
        _isRequestGateOpen = false;
        _updateState(AuthState.locked);
        return Result.err(failure);
    }
  }

  @override
  Future<Result<void>> logout([LogoutRevoker? revoker]) async {
    _sessionEpoch++;
    _isRequestGateOpen = false;
    final beginResult = await tokens.beginLogout();
    switch (beginResult) {
      case Err(:final failure):
        _updateState(AuthState.locked);
        final clearResult = await tokens.clearSession();
        switch (clearResult) {
          case Ok():
            return Result.err(failure);
          case Err(failure: final clearFailure):
            return Result.err(clearFailure);
        }
      case Ok():
        _updateState(AuthState.locked);
        if (revoker != null) {
          final tokenResult = await tokens.readRefreshTokenForRevocation();
          if (tokenResult is Ok<String?> && tokenResult.data != null) {
            final revokeResult = await revoker.revoke(tokenResult.data!);
            if (revokeResult is Err) {
              return revokeResult;
            }
          }
        }
        final clearResult = await tokens.clearSession();
        switch (clearResult) {
          case Ok():
            _updateState(AuthState.unauthenticated);
            return const Result.ok(null);
          case Err(:final failure):
            _updateState(AuthState.locked);
            return Result.err(failure);
        }
    }
  }

  @override
  Future<Result<void>> invalidateSession() async {
    _sessionEpoch++;
    _isRequestGateOpen = false;
    final beginResult = await tokens.beginInvalidation();
    switch (beginResult) {
      case Err(:final failure):
        _updateState(AuthState.locked);
        final clearResult = await tokens.clearSession();
        switch (clearResult) {
          case Ok():
            return Result.err(failure);
          case Err(failure: final clearFailure):
            return Result.err(clearFailure);
        }
      case Ok():
        _updateState(AuthState.locked);
        final clearResult = await tokens.clearSession();
        switch (clearResult) {
          case Ok():
            _updateState(AuthState.unauthenticated);
            return const Result.ok(null);
          case Err(:final failure):
            _updateState(AuthState.locked);
            return Result.err(failure);
        }
    }
  }

  /// Closes internal stream controllers.
  Future<void> dispose() async {
    await _stateController.close();
  }

  void _updateState(AuthState newState) {
    _currentAuthState = newState;
    _stateController.add(newState);
  }
}
