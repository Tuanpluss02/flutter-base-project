import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pristie/src/core/offline/db/impl/sqlcipher_offline_database.dart';
import 'package:pristie/src/core/offline/db/database_key_manager.dart';
import 'package:pristie/src/core/offline/db/offline_database.dart';
import 'package:pristie/src/core/offline/db/tables.dart';
import 'package:pristie/src/core/offline/policy/offline_config.dart';
import 'package:pristie/src/core/offline/scope/data_scope_store.dart';
import 'package:pristie/src/core/scope/data_scope.dart';

import '../storage/fakes/in_memory_secure_storage.dart';
import 'fakes/fake_offline_database.dart';
import 'fakes/recording_backup_exclusion.dart';
import 'offline_test_support.dart';

const scopeA = DataScope(accountId: 'account-a', tenantId: 'tenant-1');
const scopeATenant2 = DataScope(accountId: 'account-a', tenantId: 'tenant-2');
const scopeB = DataScope(accountId: 'account-b', tenantId: 'tenant-1');

void main() {
  late Directory tempDir;
  late DataScopeStore scopeStore;
  late SqlcipherOfflineDatabase database;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('pristie_scope_');
    scopeStore = DataScopeStore();
    database = SqlcipherOfflineDatabase(
      DatabaseKeyManager(InMemorySecureStorage()),
      RecordingBackupExclusion(),
      scopeStore,
      config: const OfflineConfig(enabled: true),
      directoryProvider: () async => tempDir,
      opener: FakeOfflineDatabaseOpener().call,
    );
  });

  tearDown(() async {
    await database.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('account A rows are invisible to account B', () async {
    expectOk(await database.open(scopeA));
    await insertItem(database, 'a-1');
    expectOk(await database.close());

    expectOk(await database.open(scopeB));
    await insertItem(database, 'b-1');
    final bRows = await readItems(database, scopeB);
    expect(bRows.map((row) => row['id']), <String>['b-1']);
    expectOk(await database.close());

    expectOk(await database.open(scopeA));
    final aRows = await readItems(database, scopeA);
    expect(aRows.map((row) => row['id']), <String>['a-1']);
  });

  test('tenant isolation stays inside the same account', () async {
    expectOk(await database.open(scopeA));
    await insertItem(database, 'tenant-1-row');
    expectOk(await database.close());

    expectOk(await database.open(scopeATenant2));
    await insertItem(database, 'tenant-2-row');
    final tenant2Rows = await readItems(database, scopeATenant2);
    expect(tenant2Rows.map((row) => row['id']), <String>['tenant-2-row']);
    expectOk(await database.close());

    expectOk(await database.open(scopeA));
    final tenant1Rows = await readItems(database, scopeA);
    expect(tenant1Rows.map((row) => row['id']), <String>['tenant-1-row']);
  });

  test('query with a non-active scope fails', () async {
    expectOk(await database.open(scopeA));
    final result = await database.query(
      const OfflineQuery(table: offlineItemsTable, scope: scopeB),
    );
    expectLocalPersistence(result);
  });

  test('opening a second scope while open fails closed', () async {
    expectOk(await database.open(scopeA));
    expectLocalPersistence(await database.open(scopeB));
    expectOk(
      await database.query(
        const OfflineQuery(table: offlineItemsTable, scope: scopeA),
      ),
    );
  });

  test('transactions cannot override scope columns', () async {
    expectOk(await database.open(scopeA));

    final inserted = await database.transaction((tx) async {
      await tx.insert(offlineItemsTable, <String, Object?>{
        'id': 'bad',
        'account_id': scopeB.accountId,
        'tenant_id': scopeA.tenantId,
        'data_json': '{}',
        'updated_at': 1,
      });
    });
    expectLocalPersistence(inserted);

    await insertItem(database, 'good');
    final updated = await database.transaction((tx) async {
      await tx.update(
        offlineItemsTable,
        <String, Object?>{'account_id': scopeB.accountId},
        whereSql: 'id = ?',
        whereArgs: <Object?>['good'],
      );
    });
    expectLocalPersistence(updated);

    final rows = await readItems(database, scopeA);
    expect(rows.map((row) => row['id']), <String>['good']);
    expect(rows.single['account_id'], scopeA.accountId);
  });

  test('transaction rolls back when scope changes mid-flight', () async {
    expectOk(await database.open(scopeA));
    final result = await database.transaction((tx) async {
      await tx.insert(offlineItemsTable, <String, Object?>{
        'id': 'rollback',
        'data_json': '{}',
        'updated_at': 1,
      });
      scopeStore.setScope(scopeB);
    });
    expectLocalPersistence(result);
    expectOk(await database.close());
    expectOk(await database.open(scopeA));
    expect(await readItems(database, scopeA), isEmpty);
  });

  test('unscoped tables cannot be queried through the scoped API', () async {
    expectOk(await database.open(scopeA));
    expectLocalPersistence(
      await database.query(
        const OfflineQuery(table: offlineMetaTable, scope: scopeA),
      ),
    );
  });

  test('transactions fail after the database is closed', () async {
    expectOk(await database.open(scopeA));
    expectOk(await database.close());
    final result = await database.transaction((tx) async {
      await tx.insert(offlineItemsTable, <String, Object?>{
        'id': 'late',
        'data_json': '{}',
        'updated_at': 1,
      });
    });
    expectLocalPersistence(result);
  });

  test('DataScopeStore advances the epoch and fences old work', () {
    final store = DataScopeStore();
    expect(store.scope, isNull);
    expect(store.epoch, 0);

    store.setScope(scopeA);
    expect(store.epoch, 1);
    expect(store.isCurrent(scopeA, 1), isTrue);

    store.setScope(scopeB);
    expect(store.epoch, 2);
    expect(store.isCurrent(scopeA, 1), isFalse);
    expect(store.isCurrent(scopeB, 2), isTrue);

    store.setScope(scopeB);
    expect(store.epoch, 2);

    store.setScope(null);
    expect(store.epoch, 3);
    expect(store.isCurrent(scopeB, 2), isFalse);
  });
}
