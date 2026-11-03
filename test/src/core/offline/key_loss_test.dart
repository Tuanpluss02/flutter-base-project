import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:base/src/core/offline/db/database_key_manager.dart';
import 'package:base/src/core/result/result.dart';

import '../storage/fakes/in_memory_secure_storage.dart';
import 'offline_test_support.dart';

void main() {
  late InMemorySecureStorage storage;
  late DatabaseKeyManager keyManager;

  setUp(() {
    storage = InMemorySecureStorage();
    keyManager = DatabaseKeyManager(storage);
  });

  test('loadOrCreate generates a 32-byte key stored under db_key_v1', () async {
    final result = await keyManager.loadOrCreate();
    expectOk(result);
    final key = (result as Ok<Uint8List>).data;
    expect(key, hasLength(databaseKeyLength));

    final stored = storage.entries[databaseKeyStorageKey];
    expect(stored, isNotNull);
    final decoded = base64Decode(stored!);
    expect(decoded, hasLength(databaseKeyLength));
    expect(decoded, key);
  });

  test('loadOrCreate returns the existing key without rotating it', () async {
    final first = await keyManager.loadOrCreate();
    final second = await keyManager.loadOrCreate();
    expectOk(first);
    expectOk(second);
    expect((second as Ok<Uint8List>).data, (first as Ok<Uint8List>).data);
    expect(storage.entries, hasLength(1));
  });

  test('invalid stored key fails closed and is not overwritten', () async {
    await storage.write(databaseKeyStorageKey, 'not-base64!!!');
    expectLocalPersistence(await keyManager.loadOrCreate());
    expect(storage.entries[databaseKeyStorageKey], 'not-base64!!!');

    await storage.write(
      databaseKeyStorageKey,
      base64Encode(const <int>[1, 2, 3]),
    );
    expectLocalPersistence(await keyManager.loadOrCreate());
    expect(
      storage.entries[databaseKeyStorageKey],
      base64Encode(const <int>[1, 2, 3]),
    );
  });

  test('loadExisting never creates a missing key', () async {
    expectLocalPersistence(await keyManager.loadExisting());
    expect(storage.entries, isEmpty);
  });

  test('SecureStorage read failure becomes localPersistence', () async {
    storage.shouldFailRead = true;
    expectLocalPersistence(await keyManager.loadOrCreate());
    expectLocalPersistence(await keyManager.loadExisting());
    expect(storage.entries, isEmpty);
  });

  test('SecureStorage write failure becomes localPersistence', () async {
    storage.shouldFailWrite = true;
    expectLocalPersistence(await keyManager.loadOrCreate());
    expect(storage.entries, isEmpty);
  });

  test('replace rejects keys with the wrong length', () async {
    expectLocalPersistence(
      await keyManager.replace(Uint8List.fromList(const <int>[1, 2, 3])),
    );
    expect(storage.entries, isEmpty);

    final key = keyManager.generate();
    expectOk(await keyManager.replace(key));
    expect(base64Decode(storage.entries[databaseKeyStorageKey]!), key);
  });

  test('clear removes the key and the next load creates a new one', () async {
    final first = await keyManager.loadOrCreate();
    expectOk(first);
    final firstBytes = (first as Ok<Uint8List>).data;

    expectOk(await keyManager.clear());
    expect(storage.entries.containsKey(databaseKeyStorageKey), isFalse);

    final second = await keyManager.loadOrCreate();
    expectOk(second);
    expect((second as Ok<Uint8List>).data, isNot(firstBytes));
  });

  test('generated keys are not all zero or repeated', () {
    final first = keyManager.generate();
    final second = keyManager.generate();
    expect(first, hasLength(databaseKeyLength));
    expect(first.any((byte) => byte != 0), isTrue);
    expect(first, isNot(second));
  });

  test('staged key becomes a candidate until promoted', () async {
    final primary = keyManager.generate();
    expectOk(await keyManager.replace(primary));
    final pending = keyManager.generate();
    expectOk(await keyManager.stage(pending));

    final candidatesResult = await keyManager.loadCandidates();
    expectOk(candidatesResult);
    final candidates = (candidatesResult as Ok<DatabaseKeyCandidates>).data;
    expect(candidates.primary, orderedEquals(primary));
    expect(candidates.pending, orderedEquals(pending));

    expectOk(await keyManager.promote(pending));
    final promotedResult = await keyManager.loadCandidates();
    expectOk(promotedResult);
    final promoted = (promotedResult as Ok<DatabaseKeyCandidates>).data;
    expect(promoted.primary, orderedEquals(pending));
    expect(promoted.pending, isNull);
  });

  test('loadCandidates skips an unreadable primary key', () async {
    await storage.write(databaseKeyStorageKey, 'not-base64!!!');
    final pending = keyManager.generate();
    expectOk(await keyManager.stage(pending));

    final result = await keyManager.loadCandidates();
    expectOk(result);
    final candidates = (result as Ok<DatabaseKeyCandidates>).data;
    expect(candidates.primary, isNull);
    expect(candidates.pending, orderedEquals(pending));
    expect(candidates.isEmpty, isFalse);
  });

  test('clearPending removes only the staged key', () async {
    final primary = keyManager.generate();
    expectOk(await keyManager.replace(primary));
    expectOk(await keyManager.stage(keyManager.generate()));

    expectOk(await keyManager.clearPending());
    expect(storage.entries[databaseKeyStorageKey], base64Encode(primary));
    expect(storage.entries.containsKey(databaseKeyPendingStorageKey), isFalse);
  });
}
