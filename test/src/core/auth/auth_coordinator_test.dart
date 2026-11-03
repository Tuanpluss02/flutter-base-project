import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:base/src/core/auth/auth_coordinator.dart';
import 'package:base/src/core/auth/auth_state.dart';
import 'package:base/src/core/auth/session_service.dart';
import 'package:base/src/core/error/app_failure.dart';
import 'package:base/src/core/network/token_refresher.dart';
import 'package:base/src/core/result/result.dart';
import 'package:base/src/core/storage/secure_session_store.dart';
import 'package:base/src/core/storage/session.dart';

import '../storage/fakes/in_memory_secure_storage.dart';

class FakeTokenRefresher implements TokenRefresher {
  int refreshCallCount = 0;
  Completer<Result<Session>>? activeCompleter;
  Result<Session>? nextResult;

  @override
  Future<Result<Session>> refresh(String refreshToken) async {
    refreshCallCount++;
    if (activeCompleter != null) {
      return activeCompleter!.future;
    }
    return nextResult ??
        Result.ok(
          Session(
            accessToken: 'refreshed_access_$refreshCallCount',
            refreshToken: 'refreshed_refresh_$refreshCallCount',
            tokenType: 'Bearer',
            expiresAt: DateTime.utc(2026, 12, 31),
          ),
        );
  }
}

class FakeLogoutRevoker implements LogoutRevoker {
  int revokeCallCount = 0;
  Result<void> result = const Result<void>.ok(null);

  @override
  Future<Result<void>> revoke(String refreshToken) async {
    revokeCallCount++;
    return result;
  }
}

void main() {
  group('AuthCoordinator', () {
    late InMemorySecureStorage storage;
    late SecureSessionStore tokens;
    late SessionService sessionService;
    late FakeTokenRefresher refresher;
    late AuthCoordinator coordinator;

    final initialSession = Session(
      accessToken: 'initial_access',
      refreshToken: 'initial_refresh',
      tokenType: 'Bearer',
      expiresAt: DateTime.utc(2026, 12, 31),
    );

    setUp(() async {
      storage = InMemorySecureStorage();
      tokens = SecureSessionStore(secureStorage: storage);
      sessionService = SessionService(tokens: tokens);
      refresher = FakeTokenRefresher();
      coordinator = AuthCoordinator(
        tokens: tokens,
        session: sessionService,
        refresher: refresher,
      );

      await sessionService.login(initialSession);
    });

    tearDown(() async {
      await sessionService.dispose();
    });

    test(
      '5 concurrent 401 requests trigger exactly 1 refresher.refresh call',
      () async {
        final completer = Completer<Result<Session>>();
        refresher.activeCompleter = completer;

        final currentEpoch = sessionService.sessionEpoch;
        final futures = List.generate(
          5,
          (_) => coordinator.ensureSession(currentEpoch),
        );

        await pumpEventQueue();
        expect(refresher.refreshCallCount, 1);

        final newSession = Session(
          accessToken: 'single_flight_access',
          refreshToken: 'single_flight_refresh',
          tokenType: 'Bearer',
          expiresAt: DateTime.utc(2026, 12, 31),
        );
        completer.complete(Result.ok(newSession));

        final results = await Future.wait(futures);
        for (final result in results) {
          expect(result, isA<Ok<Session>>());
          expect(
            (result as Ok<Session>).data.accessToken,
            'single_flight_access',
          );
        }

        final storedSession = await tokens.readSession();
        expect(
          (storedSession as Ok<Session?>).data?.accessToken,
          'single_flight_access',
        );
      },
    );

    test('refresh 200 but writeSession fails yields localPersistence and locks auth state', () async {
      final completer = Completer<Result<Session>>();
      refresher.activeCompleter = completer;

      final currentEpoch = sessionService.sessionEpoch;
      final future1 = coordinator.ensureSession(currentEpoch);
      final future2 = coordinator.ensureSession(currentEpoch);

      await pumpEventQueue();
      storage.shouldFailWrite = true;

      completer.complete(
        Result.ok(
          Session(
            accessToken: 'never_written',
            refreshToken: 'never_written',
            tokenType: 'Bearer',
            expiresAt: DateTime.utc(2026, 12, 31),
          ),
        ),
      );

      final res1 = await future1;
      final res2 = await future2;

      expect(res1, const Result<Session>.err(AppFailure.localPersistence()));
      expect(res2, const Result<Session>.err(AppFailure.localPersistence()));
      expect(sessionService.currentAuthState, AuthState.locked);
    });

    test('refresh 400/401/403 invalidates session before clear and returns unauthorized', () async {
      refresher.nextResult = const Result.err(AppFailure.unauthorized());

      final result = await coordinator.ensureSession(
        sessionService.sessionEpoch,
      );

      expect(result, const Result<Session>.err(AppFailure.unauthorized()));
      expect(sessionService.currentAuthState, AuthState.unauthenticated);
      expect(sessionService.isRequestGateOpen, isFalse);
    });

    test('refresh 429 preserves session and returns rateLimit', () async {
      const retryDuration = Duration(seconds: 45);
      refresher.nextResult = const Result.err(
        AppFailure.rateLimit(retryDuration),
      );

      final result = await coordinator.ensureSession(
        sessionService.sessionEpoch,
      );

      expect(
        result,
        const Result<Session>.err(AppFailure.rateLimit(retryDuration)),
      );
      expect(sessionService.currentAuthState, AuthState.authenticated);
      expect(sessionService.isRequestGateOpen, isTrue);

      final stored = await tokens.readSession();
      expect((stored as Ok<Session?>).data?.accessToken, 'initial_access');
    });

    test('refresh 500 or network failure preserves session and returns infrastructure failure', () async {
      refresher.nextResult = const Result.err(AppFailure.server(500));

      final result = await coordinator.ensureSession(
        sessionService.sessionEpoch,
      );

      expect(result, const Result<Session>.err(AppFailure.server(500)));
      expect(sessionService.currentAuthState, AuthState.authenticated);
      expect(sessionService.isRequestGateOpen, isTrue);
    });

    test(
      'refresh completing under stale epoch after logout is discarded',
      () async {
        final completer = Completer<Result<Session>>();
        refresher.activeCompleter = completer;

        final initialEpoch = sessionService.sessionEpoch;
        final refreshFuture = coordinator.ensureSession(initialEpoch);

        await pumpEventQueue();
        await coordinator.logout();

        expect(sessionService.sessionEpoch, greaterThan(initialEpoch));

        completer.complete(
          Result.ok(
            Session(
              accessToken: 'stale_token',
              refreshToken: 'stale_token',
              tokenType: 'Bearer',
              expiresAt: DateTime.utc(2026, 12, 31),
            ),
          ),
        );

        final result = await refreshFuture;
        expect(result, const Result<Session>.err(AppFailure.unauthorized()));

        final stored = await tokens.readSession();
        expect((stored as Ok<Session?>).data, isNull);
      },
    );

    test('logout pending write fail attempts clear and returns localPersistence on failure', () async {
      storage.shouldFailWrite = true;

      final logoutResult = await coordinator.logout();

      expect(
        logoutResult,
        const Result<void>.err(AppFailure.localPersistence()),
      );
      expect(sessionService.currentAuthState, AuthState.locked);
    });

    test(
      'logout with revoker executes remote revocation before clearSession',
      () async {
        final revoker = FakeLogoutRevoker();
        final coordinatorWithRevoker = AuthCoordinator(
          tokens: tokens,
          session: sessionService,
          refresher: refresher,
          revoker: revoker,
        );

        final logoutResult = await coordinatorWithRevoker.logout();

        expect(logoutResult, const Result<void>.ok(null));
        expect(revoker.revokeCallCount, 1);
        expect(sessionService.currentAuthState, AuthState.unauthenticated);

        final stored = await tokens.readSession();
        expect((stored as Ok<Session?>).data, isNull);
      },
    );

    test('logout with revoker network failure keeps logoutPending and returns retryable failure', () async {
      final revoker = FakeLogoutRevoker()
        ..result = const Result<void>.err(AppFailure.network());
      final coordinatorWithRevoker = AuthCoordinator(
        tokens: tokens,
        session: sessionService,
        refresher: refresher,
        revoker: revoker,
      );

      final logoutResult = await coordinatorWithRevoker.logout();

      expect(logoutResult, const Result<void>.err(AppFailure.network()));
      expect(revoker.revokeCallCount, 1);
      expect(sessionService.currentAuthState, AuthState.locked);

      final record = await tokens.readRecord();
      expect(
        (record as Ok<SessionRecord?>).data?.status,
        SessionStatus.logoutPending,
      );
    });
  });
}
