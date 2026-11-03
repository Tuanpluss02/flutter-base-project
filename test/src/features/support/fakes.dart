import 'dart:async';

import 'package:base/src/core/auth/auth_session_controller.dart';
import 'package:base/src/core/auth/auth_state.dart';
import 'package:base/src/core/network/token_refresher.dart';
import 'package:base/src/core/result/result.dart';
import 'package:base/src/core/storage/local_storage.dart';
import 'package:base/src/core/storage/session.dart';
import 'package:base/src/core/storage/session_token_provider.dart';

/// Controllable auth controller used by feature widget and cubit tests.
final class FakeAuthSessionController implements AuthSessionController {
  FakeAuthSessionController({
    AuthState initialState = AuthState.unauthenticated,
  }) : _currentAuthState = initialState;

  final StreamController<AuthState> _controller =
      StreamController<AuthState>.broadcast();

  AuthState _currentAuthState;
  int _sessionEpoch = 0;
  bool _isRequestGateOpen = false;

  /// Session captured by the latest successful login call.
  Session? lastSession;

  /// Number of login invocations.
  int loginCalls = 0;

  /// Number of logout invocations.
  int logoutCalls = 0;

  /// Number of invalidation invocations.
  int invalidateCalls = 0;

  /// Result returned by [login].
  Result<void> loginResult = const Result.ok(null);

  /// Result returned by [logout].
  Result<void> logoutResult = const Result.ok(null);

  /// Result returned by [invalidateSession].
  Result<void> invalidateResult = const Result.ok(null);

  @override
  Stream<AuthState> get authStateStream => _controller.stream;

  @override
  AuthState get currentAuthState => _currentAuthState;

  @override
  int get sessionEpoch => _sessionEpoch;

  @override
  bool get isRequestGateOpen => _isRequestGateOpen;

  /// Emits [state] to listeners and updates the current state.
  void emitState(AuthState state) {
    _currentAuthState = state;
    _controller.add(state);
  }

  @override
  Future<AuthState> restore() async => _currentAuthState;

  @override
  Future<Result<void>> login(Session session) async {
    loginCalls++;
    lastSession = session;
    if (loginResult is Ok) {
      _sessionEpoch++;
      _isRequestGateOpen = true;
      emitState(AuthState.authenticated);
    }
    return loginResult;
  }

  @override
  Future<Result<void>> logout() async {
    logoutCalls++;
    if (logoutResult is Ok) {
      _sessionEpoch++;
      _isRequestGateOpen = false;
      emitState(AuthState.unauthenticated);
    }
    return logoutResult;
  }

  @override
  Future<Result<void>> invalidateSession() async {
    invalidateCalls++;
    if (invalidateResult is Ok) {
      _sessionEpoch++;
      _isRequestGateOpen = false;
      emitState(AuthState.unauthenticated);
    }
    return invalidateResult;
  }

  /// Closes the underlying auth state stream.
  Future<void> dispose() => _controller.close();
}

/// Token refresher double that returns a fixed session without network access.
final class FakeTokenRefresher implements TokenRefresher {
  /// Number of refresh calls.
  int refreshCalls = 0;

  @override
  Future<Result<Session>> refresh(String refreshToken) async {
    refreshCalls++;
    return Result.ok(
      Session(
        accessToken: 'refreshed-access',
        refreshToken: 'refreshed-refresh',
        tokenType: 'Bearer',
        expiresAt: DateTime.utc(2030),
      ),
    );
  }
}

/// Session provider double recording writes without touching secure storage.
final class RecordingSessionTokenProvider implements SessionTokenProvider {
  /// Number of session writes.
  int writeCalls = 0;

  /// Latest session passed to [writeSession].
  Session? writtenSession;

  /// Result returned by [writeSession].
  Result<void> writeResult = const Result.ok(null);

  /// Result returned by [clearSession].
  Result<void> clearResult = const Result.ok(null);

  @override
  Future<Result<SessionRecord?>> readRecord() async => const Result.ok(null);

  @override
  Future<Result<Session?>> readSession() async => const Result.ok(null);

  @override
  Future<Result<String?>> readRefreshTokenForRevocation() async =>
      const Result.ok(null);

  @override
  Future<Result<bool>> hasSession() async => const Result.ok(false);

  @override
  Future<Result<void>> writeSession(Session session) async {
    writeCalls++;
    writtenSession = session;
    return writeResult;
  }

  @override
  Future<Result<void>> beginLogout() async => const Result.ok(null);

  @override
  Future<Result<void>> beginInvalidation() async => const Result.ok(null);

  @override
  Future<Result<void>> clearSession() async => clearResult;
}

/// Local storage double with injectable write and removal failures.
final class TestLocalStorage implements LocalStorage {
  final Map<String, String> _storage = <String, String>{};

  /// Whether [setString] should throw.
  bool failWrites = false;

  /// Whether [remove] should throw.
  bool failRemovals = false;

  /// Reads the current entries for assertions.
  Map<String, String> get entries => Map<String, String>.unmodifiable(_storage);

  @override
  Future<void> init() async {}

  @override
  String? getString(String key) => _storage[key];

  @override
  Future<void> setString(String key, String value) async {
    if (failWrites) {
      throw StateError('write failed');
    }
    _storage[key] = value;
  }

  @override
  Future<void> remove(String key) async {
    if (failRemovals) {
      throw StateError('remove failed');
    }
    _storage.remove(key);
  }
}
