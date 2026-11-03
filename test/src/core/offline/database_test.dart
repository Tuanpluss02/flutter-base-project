import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:base/src/core/offline/db/database_key_manager.dart';
import 'package:base/src/core/offline/db/impl/sqlcipher_offline_database.dart';
import 'package:base/src/core/offline/db/migrations.dart';
import 'package:base/src/core/offline/db/offline_database.dart';
import 'package:base/src/core/offline/db/tables.dart';
import 'package:base/src/core/offline/policy/offline_config.dart';
import 'package:base/src/core/offline/scope/data_scope_store.dart';
import 'package:base/src/core/result/result.dart';
import 'package:base/src/core/scope/data_scope.dart';

import '../storage/fakes/in_memory_secure_storage.dart';
import 'fakes/fake_offline_database.dart';
import 'fakes/recording_backup_exclusion.dart';
import 'offline_test_support.dart';

const scopeA = DataScope(accountId: 'account-a', tenantId: 'tenant-1');

void main() {
  late Directory tempDir;
  late InMemorySecureStorage storage;
  late DatabaseKeyManager keyManager;
  late FakeOfflineDatabaseOpener opener;
  late RecordingBackupExclusion backup;
  late DataScopeStore scopeStore;
  late SqlcipherOfflineDatabase database;
  late String databasePath;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('base_offline_db_');
    databasePath =
        '${tempDir.path}/${SqlcipherOfflineDatabase.databaseFileName}';
    storage = InMemorySecureStorage();
    keyManager = DatabaseKeyManager(storage);
    opener = FakeOfflineDatabaseOpener();
    backup = RecordingBackupExclusion();
    scopeStore = DataScopeStore();
    database = SqlcipherOfflineDatabase(
      keyManager,
      backup,
      scopeStore,
      config: const OfflineConfig(enabled: true),
      directoryProvider: () async => tempDir,
      opener: opener.call,
    );
  });

  tearDown(() async {
    await database.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('creates every offline table with required scoped columns', () async {
    expectOk(await database.open(scopeA));
    final store = opener.stores[databasePath]!;
    expect(
      store.tables.keys,
      containsAll(<String>[
        offlineItemsTable,
        offlineOutboxTable,
        offlineConflictsTable,
        offlineSyncStateTable,
        offlineMetaTable,
      ]),
    );
    expect(
      store.tables[offlineItemsTable]!.columns,
      containsAll(offlineItemsColumns),
    );
    expect(
      store.tables[offlineOutboxTable]!.columns,
      containsAll(offlineOutboxColumns),
    );
    expect(
      store.tables[offlineConflictsTable]!.columns,
      containsAll(offlineConflictsColumns),
    );
    expect(
      store.tables[offlineSyncStateTable]!.columns,
      containsAll(offlineSyncStateColumns),
    );
  });

  test(
    'opens with a generated key and preserves rows across close/reopen',
    () async {
      expectOk(await database.open(scopeA));

      final storedKey = storage.entries[databaseKeyStorageKey];
      expect(storedKey, isNotNull);
      expect(base64Decode(storedKey!), hasLength(databaseKeyLength));
      expect(opener.lastPassword, base64Encode(base64Decode(storedKey)));
      expect(opener.createCount, 1);
      expect(backup.excludedPaths, contains(tempDir.path));
      expect(backup.excludedPaths, contains(databasePath));
      expect(File(databasePath).existsSync(), isTrue);

      await insertItem(database, 'item-1', data: '{"value":1}');
      final firstRead = await readItems(database, scopeA);
      expect(firstRead, hasLength(1));
      expect(firstRead.single['data_json'], '{"value":1}');

      expectOk(
        await database.transaction((tx) async {
          await tx.update(
            offlineItemsTable,
            <String, Object?>{'data_json': '{"value":2}', 'updated_at': 2000},
            whereSql: 'id = ?',
            whereArgs: <Object?>['item-1'],
          );
        }),
      );
      final updated = await readItems(database, scopeA);
      expect(updated.single['data_json'], '{"value":2}');

      expectOk(await database.close());
      expectOk(await database.open(scopeA));
      final reopened = await readItems(database, scopeA);
      expect(reopened, hasLength(1));
      expect(reopened.single['data_json'], '{"value":2}');
      expect(opener.createCount, 1);
    },
  );

  test(
    'wrong key returns typed failure, no crash loop and no key rewrite',
    () async {
      expectOk(await database.open(scopeA));
      await insertItem(database, 'item-1');
      expectOk(await database.close());

      final originalKey = storage.entries[databaseKeyStorageKey]!;
      final wrongKey = base64Encode(List<int>.filled(databaseKeyLength, 7));
      await storage.write(databaseKeyStorageKey, wrongKey);

      expectLocalPersistence(await database.open(scopeA));
      expect(storage.entries[databaseKeyStorageKey], wrongKey);
      expect(scopeStore.scope, isNull);

      await storage.write(databaseKeyStorageKey, originalKey);
      expectOk(await database.open(scopeA));
      expect(await readItems(database, scopeA), hasLength(1));
    },
  );

  test(
    'database file without key fails closed and can be reset/re-synced',
    () async {
      expectOk(await database.open(scopeA));
      await insertItem(database, 'item-1');
      expectOk(await database.close());
      await storage.delete(databaseKeyStorageKey);

      expectLocalPersistence(await database.open(scopeA));
      expect(opener.openAttempts, 1);

      expectOk(await database.resetForResync());
      expect(await File(databasePath).exists(), isFalse);
      expect(storage.entries.containsKey(databaseKeyStorageKey), isFalse);

      expectOk(await database.open(scopeA));
      expect(await readItems(database, scopeA), isEmpty);
      expect(opener.createCount, 2);
    },
  );

  test(
    'corrupt database returns typed failure and reset removes sidecars',
    () async {
      expectOk(await database.open(scopeA));
      await insertItem(database, 'item-1');
      expectOk(await database.close());
      await File('$databasePath-wal').writeAsString('wal');
      await File('$databasePath-shm').writeAsString('shm');
      await File('$databasePath-journal').writeAsString('journal');
      opener.corruptedPaths.add(databasePath);

      expectLocalPersistence(await database.open(scopeA));
      expectOk(await database.resetForResync());
      expect(await File(databasePath).exists(), isFalse);
      expect(await File('$databasePath-wal').exists(), isFalse);
      expect(await File('$databasePath-shm').exists(), isFalse);
      expect(await File('$databasePath-journal').exists(), isFalse);

      opener.corruptedPaths.clear();
      expectOk(await database.open(scopeA));
      expect(await readItems(database, scopeA), isEmpty);
    },
  );

  test(
    'migration from v1 to v2 keeps data and adds pending overlay column',
    () async {
      final key = keyManager.generate();
      await storage.write(databaseKeyStorageKey, base64Encode(key));
      await File(databasePath).writeAsBytes(const <int>[1]);
      final store = opener.seed(
        path: databasePath,
        password: base64Encode(key),
        schemaVersion: 1,
      );
      store.tables[offlineItemsTable] = FakeTable(<String>{
        'id',
        'account_id',
        'tenant_id',
        'data_json',
        'version',
        'deleted_at',
        'updated_at',
      });
      store.tables[offlineOutboxTable] = FakeTable(<String>{
        'id',
        'account_id',
        'tenant_id',
        'state',
        'sequence',
        'entity_key',
      });
      store.tables[offlineConflictsTable] = FakeTable(<String>{
        'id',
        'account_id',
        'tenant_id',
        'operation_id',
      });
      store.tables[offlineSyncStateTable] = FakeTable(<String>{
        'dataset',
        'account_id',
        'tenant_id',
      });
      store.tables[offlineMetaTable] = FakeTable(<String>{'key', 'value'});
      store.tables[offlineItemsTable]!.rows.add(<String, Object?>{
        'id': 'legacy-1',
        'account_id': scopeA.accountId,
        'tenant_id': scopeA.tenantId,
        'data_json': '{"legacy":true}',
        'version': '1',
        'deleted_at': null,
        'updated_at': 10,
      });

      expectOk(await database.open(scopeA));
      expect(opener.upgradeCount, 1);
      expect(opener.stores[databasePath]!.schemaVersion, offlineSchemaVersion);
      final rows = await readItems(database, scopeA);
      expect(rows, hasLength(1));
      expect(rows.single.containsKey('pending_overlay_json'), isTrue);
      expect(rows.single['data_json'], '{"legacy":true}');
      expect(rows.single['pending_overlay_json'], isNull);

      await insertItem(
        database,
        'new-1',
        extra: <String, Object?>{'pending_overlay_json': '{"overlay":true}'},
      );
      final newRows = await readItems(database, scopeA);
      final inserted = newRows.singleWhere((row) => row['id'] == 'new-1');
      expect(inserted['pending_overlay_json'], '{"overlay":true}');
    },
  );

  test('migration rejects downgrades and unknown versions', () async {
    final connection = FakeOfflineConnection(
      FakeDatabaseStore(password: 'key', schemaVersion: 2),
    );
    expect(() => upgradeOfflineSchema(connection, 2, 1), throwsStateError);
    expect(() => upgradeOfflineSchema(connection, 0, 2), throwsStateError);
    expect(() => upgradeOfflineSchema(connection, 2, 3), throwsStateError);
    await upgradeOfflineSchema(connection, 2, 2);
  });

  test(
    'backup exclusion failure aborts open and closes the connection',
    () async {
      backup.failingPaths.add(tempDir.path);
      expectLocalPersistence(await database.open(scopeA));
      expect(opener.openAttempts, 0);

      backup.failingPaths
        ..clear()
        ..add(databasePath);
      expectLocalPersistence(await database.open(scopeA));
      expect(opener.openAttempts, 1);
      expect(scopeStore.scope, isNull);
    },
  );

  test(
    'default OfflineConfig is disabled and never touches the database',
    () async {
      var directoryCalls = 0;
      final disabled = SqlcipherOfflineDatabase(
        keyManager,
        backup,
        DataScopeStore(),
        directoryProvider: () async {
          directoryCalls++;
          return tempDir;
        },
        opener: opener.call,
      );

      expect(const OfflineConfig().enabled, isFalse);
      expectLocalPersistence(await disabled.open(scopeA));
      expect(directoryCalls, 0);
      expect(opener.openAttempts, 0);
      expect(storage.entries, isEmpty);
    },
  );

  test('rejects empty or untrimmed scope identifiers', () async {
    expectLocalPersistence(await database.open(const DataScope(accountId: '')));
    expectLocalPersistence(
      await database.open(const DataScope(accountId: 'a', tenantId: '')),
    );
    expectLocalPersistence(
      await database.open(const DataScope(accountId: ' account-a')),
    );
    expectLocalPersistence(
      await database.open(
        const DataScope(accountId: 'account-a', tenantId: 'tenant-1 '),
      ),
    );
    expect(opener.openAttempts, 0);
  });

  test('rekey rotates the key and the old key fails closed', () async {
    expectOk(await database.open(scopeA));
    await insertItem(database, 'item-1');
    final oldKey = storage.entries[databaseKeyStorageKey]!;

    expectOk(await database.rekey());
    final newKey = storage.entries[databaseKeyStorageKey]!;
    expect(newKey, isNot(oldKey));
    await database.close();

    await storage.write(databaseKeyStorageKey, oldKey);
    expectLocalPersistence(await database.open(scopeA));

    await storage.write(databaseKeyStorageKey, newKey);
    expectOk(await database.open(scopeA));
    expect(await readItems(database, scopeA), hasLength(1));
  });

  test('rekey aborts when SecureStorage write fails', () async {
    expectOk(await database.open(scopeA));
    await insertItem(database, 'item-1');
    final originalKey = storage.entries[databaseKeyStorageKey]!;

    storage.shouldFailWrite = true;
    expectLocalPersistence(await database.rekey());
    storage.shouldFailWrite = false;

    expect(storage.entries[databaseKeyStorageKey], originalKey);
    expectOk(await database.close());
    expectOk(await database.open(scopeA));
    expect(await readItems(database, scopeA), hasLength(1));
  });

  test('pending key recovers a crash after PRAGMA rekey', () async {
    expectOk(await database.open(scopeA));
    await insertItem(database, 'item-1');
    final oldKey = storage.entries[databaseKeyStorageKey]!;
    await database.close();

    final nextKey = keyManager.generate();
    await storage.write(databaseKeyPendingStorageKey, base64Encode(nextKey));
    opener.stores[databasePath]!.password = base64Encode(nextKey);

    expectOk(await database.open(scopeA));
    expect(storage.entries[databaseKeyStorageKey], base64Encode(nextKey));
    expect(storage.entries.containsKey(databaseKeyPendingStorageKey), isFalse);
    expect(await readItems(database, scopeA), hasLength(1));
    expect(oldKey, isNot(storage.entries[databaseKeyStorageKey]));
  });

  test('stale pending key is cleared when the primary key works', () async {
    expectOk(await database.open(scopeA));
    await insertItem(database, 'item-1');
    await database.close();
    await storage.write(
      databaseKeyPendingStorageKey,
      base64Encode(keyManager.generate()),
    );

    expectOk(await database.open(scopeA));
    expect(storage.entries.containsKey(databaseKeyPendingStorageKey), isFalse);
    expect(await readItems(database, scopeA), hasLength(1));
  });

  test('concurrent rekeys are single-flight', () async {
    expectOk(await database.open(scopeA));
    await insertItem(database, 'item-1');
    final oldKey = storage.entries[databaseKeyStorageKey]!;

    final results = await Future.wait(<Future<Result<void>>>[
      database.rekey(),
      database.rekey(),
    ]);
    expectOk(results[0]);
    expectOk(results[1]);
    expect(storage.entries[databaseKeyStorageKey], isNot(oldKey));
    expect(storage.entries.containsKey(databaseKeyPendingStorageKey), isFalse);
    expectOk(await database.close());
    expectOk(await database.open(scopeA));
    expect(await readItems(database, scopeA), hasLength(1));
  });

  test('concurrent opens are single-flight', () async {
    final results = await Future.wait(<Future<Result<void>>>[
      database.open(scopeA),
      database.open(scopeA),
    ]);
    expectOk(results[0]);
    expectOk(results[1]);
    expect(opener.openAttempts, 1);
    expect(opener.createCount, 1);

    await database.close();
    const otherScope = DataScope(accountId: 'account-b');
    final conflicting = await Future.wait(<Future<Result<void>>>[
      database.open(scopeA),
      database.open(otherScope),
    ]);
    expectOk(conflicting[0]);
    expectLocalPersistence(conflicting[1]);
  });

  test('reset works after a failed directory backup exclusion', () async {
    expectOk(await database.open(scopeA));
    await insertItem(database, 'item-1');
    expectOk(await database.close());

    backup.failingPaths.add(tempDir.path);
    final restarted = SqlcipherOfflineDatabase(
      keyManager,
      backup,
      DataScopeStore(),
      config: const OfflineConfig(enabled: true),
      directoryProvider: () async => tempDir,
      opener: opener.call,
    );
    expectLocalPersistence(await restarted.open(scopeA));
    expectOk(await restarted.resetForResync());
    expect(await File(databasePath).exists(), isFalse);
    expect(storage.entries.containsKey(databaseKeyStorageKey), isFalse);
  });

  test('disguised scope columns are rejected', () async {
    expectOk(await database.open(scopeA));

    for (final key in const ['ACCOUNT_ID', 'account_id ', '"account_id"']) {
      final result = await database.transaction((tx) async {
        await tx.insert(offlineItemsTable, <String, Object?>{
          'id': 'bad-$key',
          key: 'account-b',
          'data_json': '{}',
          'updated_at': 1,
        });
      });
      expectLocalPersistence(result);
    }
    expect(await readItems(database, scopeA), isEmpty);
  });

  test('raw where fragments cannot escape the scope predicate', () async {
    expectOk(await database.open(scopeA));
    await insertItem(database, 'item-1');

    final escaped = await database.query(
      const OfflineQuery(
        table: offlineItemsTable,
        scope: scopeA,
        whereSql: '1=1) OR (1=1 --',
      ),
    );
    expectLocalPersistence(escaped);

    final union = await database.query(
      const OfflineQuery(
        table: offlineItemsTable,
        scope: scopeA,
        whereSql: 'id = ? UNION SELECT * FROM offline_items',
        whereArgs: <Object?>['item-1'],
      ),
    );
    expectLocalPersistence(union);

    final badOrder = await database.query(
      const OfflineQuery(
        table: offlineItemsTable,
        scope: scopeA,
        orderBy: 'id; DROP TABLE offline_items',
      ),
    );
    expectLocalPersistence(badOrder);

    final valid = await database.query(
      const OfflineQuery(
        table: offlineItemsTable,
        scope: scopeA,
        whereSql: 'id = ?',
        whereArgs: <Object?>['item-1'],
        orderBy: 'updated_at DESC',
        limit: 1,
      ),
    );
    expectOk(valid);
    expect((valid as Ok<List<Map<String, Object?>>>).data, hasLength(1));
  });

  test('nullable tenant scope persists and stays isolated', () async {
    const noTenant = DataScope(accountId: 'account-a');
    expectOk(await database.open(noTenant));
    await insertItem(database, 'single-tenant');
    final rows = await readItems(database, noTenant);
    expect(rows, hasLength(1));
    expect(rows.single['tenant_id'], '');
    expectOk(await database.close());

    expectOk(await database.open(noTenant));
    expect(await readItems(database, noTenant), hasLength(1));
    expectLocalPersistence(
      await database.query(
        const OfflineQuery(
          table: offlineItemsTable,
          scope: DataScope(accountId: 'account-a', tenantId: 'tenant-1'),
        ),
      ),
    );
  });
}
