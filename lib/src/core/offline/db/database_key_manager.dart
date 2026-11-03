import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:base/src/core/error/app_failure.dart';
import 'package:base/src/core/result/result.dart';
import 'package:base/src/core/storage/secure_storage.dart';

/// SecureStorage entry that holds the current database encryption key.
const databaseKeyStorageKey = 'db_key_v1';

/// SecureStorage entry staged before a key rotation is committed.
const databaseKeyPendingStorageKey = 'db_key_v1_pending';

/// Required database encryption key length in bytes.
const databaseKeyLength = 32;

/// Keys available when opening an existing database.
///
/// [pending] is set while a `PRAGMA rekey` has completed but the new key has
/// not yet been promoted to [primary], for example after a process kill.
final class DatabaseKeyCandidates {
  const DatabaseKeyCandidates({this.primary, this.pending});

  /// The normal, promoted key.
  final Uint8List? primary;

  /// A key staged by an interrupted rotation.
  final Uint8List? pending;

  /// Whether neither candidate is readable.
  bool get isEmpty => primary == null && pending == null;
}

/// Loads, creates and rotates the SQLCipher key stored in SecureStorage.
final class DatabaseKeyManager {
  const DatabaseKeyManager(this._storage);

  final SecureStorage _storage;

  /// Returns the stored key, generating and persisting a new one when absent.
  Future<Result<Uint8List>> loadOrCreate() async {
    try {
      final stored = await _storage.read(databaseKeyStorageKey);
      if (stored != null) return _decode(stored);
      final key = generate();
      final persisted = await _persistTo(databaseKeyStorageKey, key);
      if (persisted is Err<void>) return Result.err(persisted.failure);
      return Result.ok(key);
    } catch (_) {
      return const Result.err(AppFailure.localPersistence());
    }
  }

  /// Returns the stored key without ever creating a replacement.
  Future<Result<Uint8List>> loadExisting() async {
    try {
      final stored = await _storage.read(databaseKeyStorageKey);
      if (stored == null) {
        return const Result.err(AppFailure.localPersistence());
      }
      return _decode(stored);
    } catch (_) {
      return const Result.err(AppFailure.localPersistence());
    }
  }

  /// Returns the primary and pending keys that can still be decoded.
  Future<Result<DatabaseKeyCandidates>> loadCandidates() async {
    try {
      final primaryValue = await _storage.read(databaseKeyStorageKey);
      final pendingValue = await _storage.read(databaseKeyPendingStorageKey);
      return Result.ok(
        DatabaseKeyCandidates(
          primary: primaryValue == null ? null : _decodeOrNull(primaryValue),
          pending: pendingValue == null ? null : _decodeOrNull(pendingValue),
        ),
      );
    } catch (_) {
      return const Result.err(AppFailure.localPersistence());
    }
  }

  /// Stores [key] as the pending key before `PRAGMA rekey` runs.
  Future<Result<void>> stage(Uint8List key) =>
      _persistTo(databaseKeyPendingStorageKey, key);

  /// Promotes [key] to the primary key and removes a stale pending key.
  ///
  /// A failed pending-key deletion is not fatal: the primary key is already
  /// durable and the next open retries cleanup.
  Future<Result<void>> promote(Uint8List key) async {
    final written = await _persistTo(databaseKeyStorageKey, key);
    if (written is Err<void>) return written;
    await _delete(databaseKeyPendingStorageKey);
    return const Result.ok(null);
  }

  /// Removes a staged key after a failed or abandoned rotation.
  Future<Result<void>> clearPending() => _delete(databaseKeyPendingStorageKey);

  /// Replaces the primary key without touching any pending key.
  Future<Result<void>> replace(Uint8List key) =>
      _persistTo(databaseKeyStorageKey, key);

  /// Deletes both primary and pending keys as part of a controlled reset.
  Future<Result<void>> clear() async {
    try {
      await _storage.delete(databaseKeyStorageKey);
      await _storage.delete(databaseKeyPendingStorageKey);
      final primary = await _storage.read(databaseKeyStorageKey);
      final pending = await _storage.read(databaseKeyPendingStorageKey);
      if (primary != null || pending != null) {
        return const Result.err(AppFailure.localPersistence());
      }
      return const Result.ok(null);
    } catch (_) {
      return const Result.err(AppFailure.localPersistence());
    }
  }

  /// Generates a cryptographically secure 256-bit key.
  Uint8List generate() {
    final random = Random.secure();
    return Uint8List.fromList(
      List<int>.generate(databaseKeyLength, (_) => random.nextInt(256)),
    );
  }

  Future<Result<void>> _persistTo(String storageKey, Uint8List key) async {
    if (key.length != databaseKeyLength) {
      return const Result.err(AppFailure.localPersistence());
    }
    try {
      final encoded = base64Encode(key);
      await _storage.write(storageKey, encoded);
      final readBack = await _storage.read(storageKey);
      if (readBack != encoded) {
        return const Result.err(AppFailure.localPersistence());
      }
      return const Result.ok(null);
    } catch (_) {
      return const Result.err(AppFailure.localPersistence());
    }
  }

  Future<Result<void>> _delete(String storageKey) async {
    try {
      await _storage.delete(storageKey);
      final remaining = await _storage.read(storageKey);
      if (remaining != null) {
        return const Result.err(AppFailure.localPersistence());
      }
      return const Result.ok(null);
    } catch (_) {
      return const Result.err(AppFailure.localPersistence());
    }
  }

  Result<Uint8List> _decode(String value) {
    final key = _decodeOrNull(value);
    if (key == null) return const Result.err(AppFailure.localPersistence());
    return Result.ok(key);
  }

  Uint8List? _decodeOrNull(String value) {
    try {
      final key = base64Decode(value);
      if (key.length == databaseKeyLength) return key;
    } catch (_) {
      return null;
    }
    return null;
  }
}
