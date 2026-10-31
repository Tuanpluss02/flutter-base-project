import 'package:flutter_test/flutter_test.dart';
import 'package:pristie/src/core/auth/auth_state.dart';
import 'package:pristie/src/core/auth/session_service.dart';
import 'package:pristie/src/core/error/app_failure.dart';
import 'package:pristie/src/core/result/result.dart';
import 'package:pristie/src/core/storage/secure_session_store.dart';
import 'package:pristie/src/core/storage/session.dart';

import '../storage/fakes/in_memory_secure_storage.dart';

void main() {
  group('SessionService', () {
    late InMemorySecureStorage secureStorage;
    late SecureSessionStore tokenStore;
    late SessionService sessionService;

    final testSession = Session(
      accessToken: 'acc_token',
      refreshToken: 'ref_token',
      tokenType: 'Bearer',
      expiresAt: DateTime.utc(2026, 12, 31),
    );

    setUp(() {
      secureStorage = InMemorySecureStorage();
      tokenStore = SecureSessionStore(secureStorage: secureStorage);
      sessionService = SessionService(tokens: tokenStore);
    });

    tearDown(() async {
      await sessionService.dispose();
    });

    test(
      'restore with no stored record returns unauthenticated with closed gate',
      () async {
        final state = await sessionService.restore();

        expect(state, AuthState.unauthenticated);
        expect(sessionService.isRequestGateOpen, isFalse);
        expect(sessionService.currentAuthState, AuthState.unauthenticated);
      },
    );

    test(
      'restore with active record returns authenticated and opens gate',
      () async {
        await tokenStore.writeSession(testSession);

        final state = await sessionService.restore();

        expect(state, AuthState.authenticated);
        expect(sessionService.isRequestGateOpen, isTrue);
        expect(sessionService.currentAuthState, AuthState.authenticated);
      },
    );

    test('restore with pending logout clears to signedOut and returns unauthenticated', () async {
      await tokenStore.writeSession(testSession);
      await tokenStore.beginLogout();

      final state = await sessionService.restore();

      expect(state, AuthState.unauthenticated);
      expect(sessionService.isRequestGateOpen, isFalse);
      expect(sessionService.currentAuthState, AuthState.unauthenticated);

      final hasSession = await tokenStore.hasSession();
      expect(hasSession, const Result<bool>.ok(false));
    });

    test('restore with pending invalidation clears to signedOut and returns unauthenticated', () async {
      await tokenStore.writeSession(testSession);
      await tokenStore.beginInvalidation();

      final state = await sessionService.restore();

      expect(state, AuthState.unauthenticated);
      expect(sessionService.isRequestGateOpen, isFalse);
      expect(sessionService.currentAuthState, AuthState.unauthenticated);
    });

    test(
      'restore when storage fails returns locked with closed gate',
      () async {
        secureStorage.shouldFailRead = true;

        final state = await sessionService.restore();

        expect(state, AuthState.locked);
        expect(sessionService.isRequestGateOpen, isFalse);
        expect(sessionService.currentAuthState, AuthState.locked);
      },
    );

    test('login writes session, increments epoch, opens gate, and emits authenticated', () async {
      final initialEpoch = sessionService.sessionEpoch;

      final states = <AuthState>[];
      final subscription = sessionService.authStateStream.listen(states.add);

      final result = await sessionService.login(testSession);

      expect(result, const Result<void>.ok(null));
      expect(sessionService.sessionEpoch, initialEpoch + 1);
      expect(sessionService.isRequestGateOpen, isTrue);
      expect(sessionService.currentAuthState, AuthState.authenticated);

      await pumpEventQueue();
      expect(states, <AuthState>[AuthState.authenticated]);
      await subscription.cancel();
    });

    test('login storage failure locks auth state and closes gate', () async {
      secureStorage.shouldFailWrite = true;

      final result = await sessionService.login(testSession);

      expect(result, const Result<void>.err(AppFailure.localPersistence()));
      expect(sessionService.isRequestGateOpen, isFalse);
      expect(sessionService.currentAuthState, AuthState.locked);
    });

    test('logout closes gate, increments epoch, clears session, and emits unauthenticated', () async {
      await sessionService.login(testSession);
      final loginEpoch = sessionService.sessionEpoch;

      final states = <AuthState>[];
      final subscription = sessionService.authStateStream.listen(states.add);

      final logoutResult = await sessionService.logout();

      expect(logoutResult, const Result<void>.ok(null));
      expect(sessionService.sessionEpoch, loginEpoch + 1);
      expect(sessionService.isRequestGateOpen, isFalse);
      expect(sessionService.currentAuthState, AuthState.unauthenticated);

      await pumpEventQueue();
      expect(states, contains(AuthState.unauthenticated));
      await subscription.cancel();
    });

    test('invalidateSession closes gate, increments epoch, and emits unauthenticated', () async {
      await sessionService.login(testSession);
      final loginEpoch = sessionService.sessionEpoch;

      final invalidateResult = await sessionService.invalidateSession();

      expect(invalidateResult, const Result<void>.ok(null));
      expect(sessionService.sessionEpoch, loginEpoch + 1);
      expect(sessionService.isRequestGateOpen, isFalse);
      expect(sessionService.currentAuthState, AuthState.unauthenticated);
    });
  });
}
