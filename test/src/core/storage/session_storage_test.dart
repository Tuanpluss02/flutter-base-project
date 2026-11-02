import 'package:flutter_test/flutter_test.dart';
import 'package:pristie/src/core/error/app_failure.dart';
import 'package:pristie/src/core/result/result.dart';
import 'package:pristie/src/core/storage/secure_session_store.dart';
import 'package:pristie/src/core/storage/session.dart';

import 'fakes/in_memory_secure_storage.dart';

void main() {
  group('SecureSessionStore', () {
    late InMemorySecureStorage secureStorage;
    late SecureSessionStore store;

    final testSession = Session(
      accessToken: 'test_access_token',
      refreshToken: 'test_refresh_token',
      tokenType: 'Bearer',
      expiresAt: DateTime.utc(2026, 12, 31, 23, 59, 59),
    );

    setUp(() {
      secureStorage = InMemorySecureStorage();
      store = SecureSessionStore(secureStorage: secureStorage);
    });

    test('writes session pair atomically and reads active session', () async {
      final writeResult = await store.writeSession(testSession);
      expect(writeResult, const Result<void>.ok(null));

      final readResult = await store.readSession();
      expect(readResult, Result<Session?>.ok(testSession));

      final hasSessionResult = await store.hasSession();
      expect(hasSessionResult, const Result<bool>.ok(true));
    });

    test('stores record under single key without splitting tokens', () async {
      await store.writeSession(testSession);

      expect(secureStorage.entries.keys.toList(), <String>[
        SecureSessionStore.sessionRecordKey,
      ]);
      expect(secureStorage.entries.containsKey('accessToken'), isFalse);
      expect(secureStorage.entries.containsKey('refreshToken'), isFalse);
    });

    test(
      'writeSession failure returns localPersistence and cleans up',
      () async {
        secureStorage.shouldFailWrite = true;
        final writeResult = await store.writeSession(testSession);

        expect(
          writeResult,
          const Result<void>.err(AppFailure.localPersistence()),
        );

        secureStorage.shouldFailWrite = false;
        final readResult = await store.readSession();
        expect(readResult, const Result<Session?>.ok(null));
      },
    );

    test(
      'beginLogout transitions to logoutPending and clearSession to signedOut',
      () async {
        await store.writeSession(testSession);

        final logoutResult = await store.beginLogout();
        expect(logoutResult, const Result<void>.ok(null));

        final readSessionResult = await store.readSession();
        expect(readSessionResult, const Result<Session?>.ok(null));

        final readRevokeResult = await store.readRefreshTokenForRevocation();
        expect(
          readRevokeResult,
          const Result<String?>.ok('test_refresh_token'),
        );

        final hasSessionResult = await store.hasSession();
        expect(hasSessionResult, const Result<bool>.ok(false));

        final clearResult = await store.clearSession();
        expect(clearResult, const Result<void>.ok(null));

        final readRevokeAfterClear = await store
            .readRefreshTokenForRevocation();
        expect(readRevokeAfterClear, const Result<String?>.ok(null));

        final readSessionAfterClear = await store.readSession();
        expect(readSessionAfterClear, const Result<Session?>.ok(null));
      },
    );

    test('beginLogout write failure calls clearSession and returns localPersistence', () async {
      await store.writeSession(testSession);

      secureStorage.shouldFailWrite = true;
      final beginLogoutResult = await store.beginLogout();

      expect(
        beginLogoutResult,
        const Result<void>.err(AppFailure.localPersistence()),
      );

      secureStorage.shouldFailWrite = false;
      final readResult = await store.readSession();
      expect(readResult, const Result<Session?>.ok(null));
    });

    test(
      'beginInvalidation marks sessionInvalidationPending and denies tokens',
      () async {
        await store.writeSession(testSession);

        final invalidationResult = await store.beginInvalidation();
        expect(invalidationResult, const Result<void>.ok(null));

        final readSessionResult = await store.readSession();
        expect(readSessionResult, const Result<Session?>.ok(null));

        final readRevokeResult = await store.readRefreshTokenForRevocation();
        expect(readRevokeResult, const Result<String?>.ok(null));

        final hasSessionResult = await store.hasSession();
        expect(hasSessionResult, const Result<bool>.ok(false));
      },
    );

    test(
      'reinitialized store with pending status does not restore active session',
      () async {
        await store.writeSession(testSession);
        await store.beginLogout();

        final reinitializedStore = SecureSessionStore(
          secureStorage: secureStorage,
        );
        final readResult = await reinitializedStore.readSession();
        expect(readResult, const Result<Session?>.ok(null));

        final hasResult = await reinitializedStore.hasSession();
        expect(hasResult, const Result<bool>.ok(false));
      },
    );

    test(
      'malformed json in storage maps to localPersistence failure',
      () async {
        await secureStorage.write(
          SecureSessionStore.sessionRecordKey,
          '{not_valid_json}',
        );

        final readResult = await store.readSession();
        expect(
          readResult,
          const Result<Session?>.err(AppFailure.localPersistence()),
        );
      },
    );
  });
}
