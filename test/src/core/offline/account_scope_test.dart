import 'package:flutter_test/flutter_test.dart';
import 'package:base/src/core/offline/db/offline_database.dart';
import 'package:base/src/core/offline/db/tables.dart';
import 'package:base/src/core/offline/outbox/outbox_worker.dart';
import 'package:base/src/core/offline/policy/offline_config.dart';
import 'package:base/src/core/offline/sync/sync_send_outcome.dart';
import 'package:base/src/core/result/result.dart';

import 'offline_test_support.dart';
import 'sync_test_support.dart';

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

  OutboxWorker workerWith(OutboxSender send) => OutboxWorker(
    database: harness.database,
    scopeStore: harness.scopeStore,
    send: send,
    config: const OfflineConfig(enabled: true),
    clock: () => now,
  );

  test('account B cannot read or claim account A outbox rows', () async {
    final operation = await harness.enqueue(entityKey: 'item-a');
    await harness.insertItem('item-a');

    await harness.close();
    await harness.open(scopeB);

    expect(await harness.rows(offlineOutboxTable), isEmpty);
    expect(await harness.rows(offlineItemsTable), isEmpty);
    expect(await harness.rows(offlineConflictsTable), isEmpty);
    expect(
      await harness.database.query(
        OfflineQuery(table: offlineOutboxTable, scope: scopeA),
      ),
      isA<Err<List<Map<String, Object?>>>>(),
    );

    var sends = 0;
    final worker = workerWith((_) async {
      sends++;
      return const SyncSendOutcome.synced();
    });
    final run = await worker.runOnce();
    expectOk(run);
    expect((run as Ok<OutboxRunSummary>).data.processed, 0);
    expect(sends, 0);

    await harness.close();
    await harness.open(scopeA);
    final recovered = await harness.rows(offlineOutboxTable);
    expect(recovered.single['id'], operation.id);
    expect(recovered.single['idempotency_key'], operation.idempotencyKey);
    expect(recovered.single['state'], 'pending');
  });

  test(
    'session expiry keeps the database and outbox scoped to the account',
    () async {
      final operation = await harness.enqueue();
      harness.scopeStore.setScope(null);

      var sends = 0;
      final worker = workerWith((_) async {
        sends++;
        return const SyncSendOutcome.synced();
      });
      final blocked = await worker.runOnce();
      expectLocalPersistence(blocked);
      expect(sends, 0);

      await harness.close();
      await harness.open(scopeA);
      expect(
        (await harness.rows(offlineOutboxTable)).single['id'],
        operation.id,
      );

      final resumed = await worker.runOnce();
      expectOk(resumed);
      expect((resumed as Ok<OutboxRunSummary>).data.synced, 1);
      expect(sends, 1);
      expect(
        (await harness.rows(offlineOutboxTable)).single['state'],
        'synced',
      );
    },
  );
}
