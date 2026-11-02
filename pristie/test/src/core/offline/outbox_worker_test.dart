import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pristie/src/core/error/app_failure.dart';
import 'package:pristie/src/core/offline/db/tables.dart';
import 'package:pristie/src/core/offline/outbox/outbox_operation.dart';
import 'package:pristie/src/core/offline/outbox/outbox_worker.dart';
import 'package:pristie/src/core/offline/policy/offline_config.dart';
import 'package:pristie/src/core/offline/policy/offline_policy.dart';
import 'package:pristie/src/core/offline/sync/sync_send_outcome.dart';
import 'package:pristie/src/core/result/result.dart';

import 'fakes/fake_sync_server.dart';
import 'offline_test_support.dart';
import 'sync_test_support.dart';

final _uuidPattern = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
);

void main() {
  late OfflineHarness harness;
  final now = DateTime.utc(2026, 1, 1, 12);

  setUp(() async {
    harness = OfflineHarness();
    await harness.setUp();
  });

  tearDown(() async {
    await harness.tearDown();
  });

  OutboxWorker workerWith(
    OutboxSender send, {
    OfflineConfig config = const OfflineConfig(enabled: true),
    DateTime Function()? clock,
    String Function()? leaseIdGenerator,
  }) {
    return OutboxWorker(
      database: harness.database,
      scopeStore: harness.scopeStore,
      send: send,
      config: config,
      clock: clock ?? () => now,
      leaseIdGenerator: leaseIdGenerator ?? () => 'lease-owner-1',
    );
  }

  Future<Map<String, Object?>> outboxRow(String id) async {
    final rows = await harness.rows(
      offlineOutboxTable,
      whereSql: 'id = ?',
      whereArgs: <Object?>[id],
    );
    return rows.single;
  }

  test(
    'enqueue writes the outbox row in the same transaction as the '
    'local row and keeps its idempotency key across retry and restart',
    () async {
      expectOk(
        await harness.database.transaction((tx) async {
          await tx.insert(offlineItemsTable, <String, Object?>{
            'id': 'item-1',
            'data_json': '{"value":1}',
            'version': '1',
            'deleted_at': null,
            'updated_at': 1000,
            'pending_overlay_json': null,
          });
          await harness.enqueuer.enqueue(
            tx,
            dataScope: scopeA,
            dataScopeEpoch: harness.scopeStore.epoch,
            policy: writablePolicy,
            operation: OfflineOperation.update,
            entityKey: 'item-1',
            payloadVersion: 1,
            payloadJson: '{"value":2}',
            baseVersion: '1',
            localOverlayJson: '{"value":2}',
          );
        }),
      );

      final first = (await harness.rows(offlineOutboxTable)).single;
      expect(first['state'], OutboxState.pending.name);
      expect(first['sequence'], 1);
      final key = first['idempotency_key']! as String;
      expect(_uuidPattern.hasMatch(key), isTrue);
      expect(first['lease_owner'], isNull);
      final item = (await harness.rows(offlineItemsTable)).single;
      expect(item['pending_overlay_json'], '{"value":2}');

      final worker = workerWith(
        (_) async =>
            const SyncSendOutcome.retryable(AppFailure.server(500), null),
      );
      final run = await worker.runOnce();
      expectOk(run);
      expect((run as Ok<OutboxRunSummary>).data.retryable, 1);
      final retried = await outboxRow(first['id']! as String);
      expect(retried['idempotency_key'], key);
      expect(retried['attempt_count'], 1);
      expect(retried['state'], OutboxState.pending.name);

      await harness.close();
      await harness.open(scopeA);
      final reopened = await outboxRow(first['id']! as String);
      expect(reopened['idempotency_key'], key);
      expect(reopened['attempt_count'], 1);
    },
  );

  test(
    'enqueue fails closed for S2 data and rolls back the local row',
    () async {
      final result = await harness.database.transaction((tx) async {
        await tx.insert(offlineItemsTable, <String, Object?>{
          'id': 'personal-1',
          'data_json': '{"value":1}',
          'version': '1',
          'deleted_at': null,
          'updated_at': 1000,
          'pending_overlay_json': null,
        });
        await harness.enqueuer.enqueue(
          tx,
          dataScope: scopeA,
          dataScopeEpoch: harness.scopeStore.epoch,
          policy: personalPolicy,
          operation: OfflineOperation.update,
          entityKey: 'personal-1',
          payloadVersion: 1,
          payloadJson: '{"value":2}',
        );
      });

      expectLocalPersistence(result);
      expect(await harness.rows(offlineItemsTable), isEmpty);
      expect(await harness.rows(offlineOutboxTable), isEmpty);
    },
  );

  test(
    'a synced overlay patches the confirmed row instead of replacing it',
    () async {
      await harness.insertItem(
        'item-1',
        data: '{"value":1,"title":"base"}',
        pendingOverlay: '{"value":2}',
      );
      await harness.enqueue(
        entityKey: 'item-1',
        payloadJson: '{"value":2}',
        localOverlayJson: '{"value":2}',
      );
      final worker = workerWith((_) async => const SyncSendOutcome.synced());

      expectOk(await worker.runOnce());
      final item = (await harness.rows(offlineItemsTable)).single;
      final data =
          jsonDecode(item['data_json']! as String) as Map<String, Object?>;
      expect(data['value'], 2);
      expect(data['title'], 'base');
      expect(item['pending_overlay_json'], isNull);
    },
  );

  test('concurrent triggers share one claim and only send once', () async {
    final operation = await harness.enqueue();
    final gate = Completer<void>();
    var sends = 0;
    Map<String, Object?>? observed;
    final worker = workerWith((_) async {
      sends++;
      observed = await outboxRow(operation.id);
      await gate.future;
      return const SyncSendOutcome.synced();
    });

    final first = worker.runOnce();
    final second = worker.runOnce();
    await Future<void>.delayed(Duration.zero);

    expect(sends, 1);
    expect(observed!['state'], OutboxState.syncing.name);
    expect(observed!['lease_owner'], 'lease-owner-1');
    expect(
      observed!['lease_expires_at']! as int,
      greaterThan(now.millisecondsSinceEpoch),
    );

    gate.complete();
    final results = await Future.wait(<Future<Result<OutboxRunSummary>>>[
      first,
      second,
    ]);
    for (final result in results) {
      expectOk(result);
      expect((result as Ok<OutboxRunSummary>).data.synced, 1);
    }
    expect(sends, 1);
    final synced = await outboxRow(operation.id);
    expect(synced['state'], OutboxState.synced.name);
    expect(synced['lease_owner'], isNull);
  });

  test('401 suspends the queue without losing pending operations', () async {
    final first = await harness.enqueue(entityKey: 'item-1');
    final second = await harness.enqueue(entityKey: 'item-2');
    var sends = 0;
    final worker = workerWith((_) async {
      sends++;
      return const SyncSendOutcome.retryable(AppFailure.unauthorized(), null);
    });

    final run = await worker.runOnce();
    expectOk(run);
    final summary = (run as Ok<OutboxRunSummary>).data;
    expect(summary.suspended, isTrue);
    expect(summary.retryable, 1);
    expect(sends, 1);
    expect((await outboxRow(first.id))['state'], OutboxState.pending.name);
    expect((await outboxRow(second.id))['state'], OutboxState.pending.name);
  });

  test('403 and 422 require attention and keep the operation', () async {
    final forbidden = await harness.enqueue(entityKey: 'item-1');
    final invalid = await harness.enqueue(entityKey: 'item-2');
    final worker = workerWith(
      (operation) async => operation.entityKey == 'item-1'
          ? const SyncSendOutcome.needsAttention(AppFailure.forbidden())
          : const SyncSendOutcome.needsAttention(
              AppFailure.validation(<String, ValidationIssue>{}),
            ),
    );

    final run = await worker.runOnce();
    expectOk(run);
    expect((run as Ok<OutboxRunSummary>).data.needsAttention, 2);
    expect(
      (await outboxRow(forbidden.id))['state'],
      OutboxState.needsAttention.name,
    );
    expect(
      (await outboxRow(invalid.id))['state'],
      OutboxState.needsAttention.name,
    );
  });

  test('DELETE 404 is acknowledged as synced and tombstones the row', () async {
    await harness.insertItem('item-1');
    final operation = await harness.enqueue(operation: OfflineOperation.delete);
    final server = FakeSyncServer(
      sendHandler: (outbox, attempt) async =>
          fakeOutcomeForStatus(404, methodIsDelete: true),
    );
    final worker = workerWith(server.send);

    final run = await worker.runOnce();
    expectOk(run);
    expect((run as Ok<OutboxRunSummary>).data.synced, 1);
    expect((await outboxRow(operation.id))['state'], OutboxState.synced.name);
    expect(
      (await harness.rows(offlineItemsTable)).single['deleted_at'],
      isNotNull,
    );
  });

  test(
    '409 REQUEST_IN_PROGRESS keeps the same key and retries later',
    () async {
      final operation = await harness.enqueue();
      final worker = workerWith(
        (_) async =>
            const SyncSendOutcome.requestInProgress(Duration(seconds: 2)),
      );

      final run = await worker.runOnce();
      expectOk(run);
      expect((run as Ok<OutboxRunSummary>).data.retryable, 1);
      final row = await outboxRow(operation.id);
      expect(row['state'], OutboxState.pending.name);
      expect(row['idempotency_key'], operation.idempotencyKey);
      expect(
        row['next_attempt_at']! as int,
        now.add(const Duration(seconds: 2)).millisecondsSinceEpoch,
      );
    },
  );

  test('429 honours Retry-After and 5xx/network back off', () async {
    final rateLimited = await harness.enqueue(entityKey: 'item-1');
    final failing = await harness.enqueue(entityKey: 'item-2');
    final offline = await harness.enqueue(entityKey: 'item-3');
    final worker = workerWith(
      (operation) async => switch (operation.entityKey) {
        'item-1' => const SyncSendOutcome.retryable(
          AppFailure.rateLimit(Duration(seconds: 30)),
          Duration(seconds: 30),
        ),
        'item-2' => const SyncSendOutcome.retryable(
          AppFailure.server(503),
          null,
        ),
        _ => fakeNetworkOutcome(),
      },
    );

    final run = await worker.runOnce();
    expectOk(run);
    expect((run as Ok<OutboxRunSummary>).data.retryable, 3);

    final limited = await outboxRow(rateLimited.id);
    expect(limited['state'], OutboxState.pending.name);
    expect(
      limited['next_attempt_at']! as int,
      now.add(const Duration(seconds: 30)).millisecondsSinceEpoch,
    );
    final serverRow = await outboxRow(failing.id);
    expect(
      serverRow['next_attempt_at']! as int,
      greaterThan(now.millisecondsSinceEpoch),
    );
    final networkRow = await outboxRow(offline.id);
    expect(networkRow['state'], OutboxState.pending.name);
    expect(networkRow['attempt_count'], 1);
  });

  test('restart recovers syncing operations to pending', () async {
    final operation = await harness.enqueue();
    expectOk(
      await harness.database.transaction((tx) async {
        await tx.update(
          offlineOutboxTable,
          <String, Object?>{
            'state': OutboxState.syncing.name,
            'lease_owner': 'stale-worker',
            'lease_expires_at': now
                .add(const Duration(minutes: 10))
                .millisecondsSinceEpoch,
          },
          whereSql: 'id = ?',
          whereArgs: <Object?>[operation.id],
        );
      }),
    );

    final worker = workerWith((_) async => const SyncSendOutcome.synced());
    final recovered = await worker.recoverAfterRestart();
    expectOk(recovered);
    expect((recovered as Ok<int>).data, 1);
    final row = await outboxRow(operation.id);
    expect(row['state'], OutboxState.pending.name);
    expect(row['lease_owner'], isNull);
  });

  test('OFFLINE_ENABLED=false never claims or sends operations', () async {
    await harness.enqueue();
    var sends = 0;
    final worker = workerWith((_) async {
      sends++;
      return const SyncSendOutcome.synced();
    }, config: const OfflineConfig(enabled: false));

    worker.start();
    expect(worker.isStarted, isFalse);
    expect(worker.isEnabled, isFalse);

    final run = await worker.runOnce();
    expectOk(run);
    expect((run as Ok<OutboxRunSummary>).data.disabled, isTrue);
    expect(sends, 0);
    expect(
      (await harness.rows(offlineOutboxTable)).single['state'],
      OutboxState.pending.name,
    );
  });

  test(
    'operations for an entity wait behind an earlier pending operation',
    () async {
      final first = await harness.enqueue(entityKey: 'item-1');
      final second = await harness.enqueue(entityKey: 'item-1');
      final sent = <String>[];
      final worker = workerWith((operation) async {
        sent.add(operation.id);
        return operation.id == first.id
            ? const SyncSendOutcome.retryable(AppFailure.server(500), null)
            : const SyncSendOutcome.synced();
      });

      final run = await worker.runOnce();
      expectOk(run);
      expect(sent, <String>[first.id]);
      expect((await outboxRow(second.id))['state'], OutboxState.pending.name);
    },
  );
}
