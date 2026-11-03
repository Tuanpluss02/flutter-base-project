import 'dart:convert';

import 'package:base/src/core/error/app_failure.dart';
import 'package:base/src/core/result/result.dart';
import 'package:base/src/core/storage/secure_storage.dart';
import 'package:base/src/core/storage/session.dart';
import 'package:base/src/core/storage/session_token_provider.dart';

/// Secure storage implementation of [SessionTokenProvider] storing an atomic [SessionRecord].
final class SecureSessionStore implements SessionTokenProvider {
  /// Creates a [SecureSessionStore] backed by [SecureStorage].
  SecureSessionStore({required this.secureStorage});

  /// Single storage key hosting the entire atomic session record.
  static const String sessionRecordKey = 'session_record_v1';

  /// Backing secure storage mechanism.
  final SecureStorage secureStorage;

  @override
  Future<Result<SessionRecord?>> readRecord() async {
    try {
      final rawJson = await secureStorage.read(sessionRecordKey);
      if (rawJson == null || rawJson.trim().isEmpty) {
        return const Result.ok(null);
      }
      final decoded = jsonDecode(rawJson);
      if (decoded is! Map<String, dynamic>) {
        return const Result.err(AppFailure.localPersistence());
      }
      final record = SessionRecord.fromJson(decoded);
      return Result.ok(record);
    } catch (_) {
      return const Result.err(AppFailure.localPersistence());
    }
  }

  @override
  Future<Result<Session?>> readSession() async {
    final recordResult = await readRecord();
    switch (recordResult) {
      case Err(:final failure):
        return Result.err(failure);
      case Ok(:final data):
        if (data == null) {
          return const Result.ok(null);
        }
        if (data.status == SessionStatus.active) {
          return Result.ok(data.session);
        }
        return const Result.ok(null);
    }
  }

  @override
  Future<Result<String?>> readRefreshTokenForRevocation() async {
    final recordResult = await readRecord();
    switch (recordResult) {
      case Err(:final failure):
        return Result.err(failure);
      case Ok(:final data):
        if (data == null) {
          return const Result.ok(null);
        }
        if (data.status == SessionStatus.logoutPending) {
          return Result.ok(data.session?.refreshToken);
        }
        return const Result.ok(null);
    }
  }

  @override
  Future<Result<bool>> hasSession() async {
    final recordResult = await readRecord();
    switch (recordResult) {
      case Err(:final failure):
        return Result.err(failure);
      case Ok(:final data):
        if (data == null) {
          return const Result.ok(false);
        }
        final isActive =
            data.status == SessionStatus.active && data.session != null;
        return Result.ok(isActive);
    }
  }

  @override
  Future<Result<void>> writeSession(Session session) async {
    try {
      final record = SessionRecord(
        status: SessionStatus.active,
        session: session,
      );
      final rawJson = jsonEncode(record.toJson());
      await secureStorage.write(sessionRecordKey, rawJson);
      return const Result.ok(null);
    } catch (_) {
      try {
        await clearSession();
      } catch (_) {
        try {
          await secureStorage.delete(sessionRecordKey);
        } catch (_) {}
      }
      return const Result.err(AppFailure.localPersistence());
    }
  }

  @override
  Future<Result<void>> beginLogout() async {
    Session? existingSession;
    final currentRecordResult = await readRecord();
    if (currentRecordResult case Ok(:final data)) {
      existingSession = data?.session;
    }

    try {
      final record = SessionRecord(
        status: SessionStatus.logoutPending,
        session: existingSession,
      );
      final rawJson = jsonEncode(record.toJson());
      await secureStorage.write(sessionRecordKey, rawJson);
      return const Result.ok(null);
    } catch (_) {
      try {
        await clearSession();
      } catch (_) {
        try {
          await secureStorage.delete(sessionRecordKey);
        } catch (_) {}
      }
      return const Result.err(AppFailure.localPersistence());
    }
  }

  @override
  Future<Result<void>> beginInvalidation() async {
    try {
      const record = SessionRecord(
        status: SessionStatus.sessionInvalidationPending,
      );
      final rawJson = jsonEncode(record.toJson());
      await secureStorage.write(sessionRecordKey, rawJson);
      return const Result.ok(null);
    } catch (_) {
      try {
        await clearSession();
      } catch (_) {
        try {
          await secureStorage.delete(sessionRecordKey);
        } catch (_) {}
      }
      return const Result.err(AppFailure.localPersistence());
    }
  }

  @override
  Future<Result<void>> clearSession() async {
    try {
      const record = SessionRecord(status: SessionStatus.signedOut);
      final rawJson = jsonEncode(record.toJson());
      await secureStorage.write(sessionRecordKey, rawJson);
      return const Result.ok(null);
    } catch (_) {
      try {
        await secureStorage.delete(sessionRecordKey);
      } catch (_) {}
      return const Result.err(AppFailure.localPersistence());
    }
  }
}
