import 'dart:io';

import 'package:pristie/src/core/offline/db/database_key_manager.dart';
import 'package:pristie/src/core/offline/db/impl/sqlcipher_offline_database.dart';
import 'package:pristie/src/core/offline/db/offline_database.dart';
import 'package:pristie/src/core/offline/db/tables.dart';
import 'package:pristie/src/core/offline/outbox/outbox_operation.dart';
import 'package:pristie/src/core/offline/policy/offline_config.dart';
import 'package:pristie/src/core/offline/policy/offline_policy.dart';
import 'package:pristie/src/core/offline/scope/data_scope_store.dart';
import 'package:pristie/src/core/result/result.dart';
import 'package:pristie/src/core/scope/data_classification.dart';
import 'package:pristie/src/core/scope/data_scope.dart';

import '../storage/fakes/in_memory_secure_storage.dart';
import 'fakes/fake_offline_database.dart';
import 'fakes/recording_backup_exclusion.dart';
import 'offline_test_support.dart';

/// Default scope used by Task 9 tests.
const scopeA = DataScope(accountId: 'account-a', tenantId: 'tenant-1');

/// Second scope used to prove account isolation.
const scopeB = DataScope(accountId: 'account-b', tenantId: 'tenant-1');

/// S1 policy that permits every operation, used as the default in tests.
const writablePolicy = OfflinePolicy(
  dataset: 'home_items',
  classification: DataClassification.s1,
  ttl: Duration(minutes: 10),
  allowedOperations: {
    OfflineOperation.create,
    OfflineOperation.update,
    OfflineOperation.delete,
  },
  conflictPolicy: ConflictPolicy.manual,
);

/// S2 policy used to prove that personal data fails closed.
const personalPolicy = OfflinePolicy(
  dataset: 'personal_items',
  classification: DataClassification.s2,
  ttl: Duration(minutes: 10),
  allowedOperations: {
    OfflineOperation.create,
    OfflineOperation.update,
    OfflineOperation.delete,
  },
  conflictPolicy: ConflictPolicy.manual,
);

/// Wires a real database facade to the in-memory fake SQL engine.
final class OfflineHarness {
  late Directory tempDir;
  late InMemorySecureStorage storage;
  late DatabaseKeyManager keyManager;
  late FakeOfflineDatabaseOpener opener;
  late RecordingBackupExclusion backup;
  late DataScopeStore scopeStore;
  late SqlcipherOfflineDatabase database;
  late OutboxEnqueuer enqueuer;
  String? databasePath;

  Future<void> setUp() async {
    tempDir = await Directory.systemTemp.createTemp('pristie_sync_');
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
    enqueuer = OutboxEnqueuer();
    expectOk(await database.open(scopeA));
  }

  Future<void> tearDown() async {
    await database.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  }

  Future<void> close() => database.close();

  Future<void> open(DataScope scope) async {
    expectOk(await database.open(scope));
  }

  Future<void> insertItem(
    String id, {
    String data = '{"value":1}',
    String? version = '1',
    Object? deletedAt,
    int updatedAt = 1000,
    String? pendingOverlay,
  }) async {
    expectOk(
      await database.transaction((tx) async {
        await tx.insert(offlineItemsTable, <String, Object?>{
          'id': id,
          'data_json': data,
          'version': version,
          'deleted_at': deletedAt,
          'updated_at': updatedAt,
          'pending_overlay_json': pendingOverlay,
        });
      }),
    );
  }

  Future<OutboxOperation> enqueue({
    String entityKey = 'item-1',
    OfflineOperation operation = OfflineOperation.update,
    String payloadJson = '{"value":2}',
    String? baseVersion = '1',
    String? localOverlayJson,
    OfflinePolicy policy = writablePolicy,
    DataScope? dataScope,
    int? dataScopeEpoch,
  }) async {
    final scope = dataScope ?? scopeStore.scope ?? scopeA;
    final operationResult = await database.transaction((tx) async {
      await enqueuer.enqueue(
        tx,
        dataScope: scope,
        dataScopeEpoch: dataScopeEpoch ?? scopeStore.epoch,
        policy: policy,
        operation: operation,
        entityKey: entityKey,
        payloadVersion: 1,
        payloadJson: payloadJson,
        baseVersion: baseVersion,
        localOverlayJson: localOverlayJson,
      );
    });
    expectOk(operationResult);
    final rows = await this.rows(
      offlineOutboxTable,
      whereSql: 'entity_key = ?',
      whereArgs: <Object?>[entityKey],
      orderBy: 'sequence DESC',
      limit: 1,
    );
    return outboxOperationFromRow(rows.single, scope);
  }

  Future<List<Map<String, Object?>>> rows(
    String table, {
    String? whereSql,
    List<Object?> whereArgs = const <Object?>[],
    String? orderBy,
    int? limit,
    DataScope? dataScope,
  }) async {
    final scope = dataScope ?? scopeStore.scope ?? scopeA;
    final result = await database.query(
      OfflineQuery(
        table: table,
        scope: scope,
        whereSql: whereSql,
        whereArgs: whereArgs,
        orderBy: orderBy,
        limit: limit,
      ),
    );
    expectOk(result);
    return (result as Ok<List<Map<String, Object?>>>).data;
  }
}
