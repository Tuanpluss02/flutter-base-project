import 'package:flutter_test/flutter_test.dart';
import 'package:base/src/core/offline/db/tables.dart';
import 'package:base/src/core/offline/outbox/outbox_operation.dart';
import 'package:base/src/core/offline/outbox/outbox_worker.dart';
import 'package:base/src/core/offline/policy/offline_config.dart';
import 'package:base/src/core/offline/sync/sync_conflict.dart';
import 'package:base/src/core/offline/sync/sync_coordinator.dart';
import 'package:base/src/core/offline/sync/sync_dataset.dart';
import 'package:base/src/core/offline/sync/sync_send_outcome.dart';
import 'package:base/src/core/result/result.dart';

import 'fakes/fake_sync_server.dart';
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

  test(
    'VERSION_MISMATCH stores a durable conflict and keeps the overlay',
    () async {
      await harness.insertItem(
        'item-1',
        data: '{"value":1}',
        pendingOverlay: '{"value":2}',
      );
      final operation = await harness.enqueue(
        entityKey: 'item-1',
        payloadJson: '{"value":2}',
        baseVersion: '1',
        localOverlayJson: '{"value":2}',
      );
      final conflict = const SyncConflict(
        localOverlay: <String, Object?>{'value': 2},
        remoteSnapshot: <String, Object?>{'value': 9, 'version': 2},
        baseVersion: '1',
        serverVersion: '2',
      );
      final worker = workerWith(
        (_) async => SyncSendOutcome.versionConflict(conflict),
      );

      final run = await worker.runOnce();
      expectOk(run);
      expect((run as Ok<OutboxRunSummary>).data.conflicts, 1);

      final outbox = (await harness.rows(offlineOutboxTable)).single;
      expect(outbox['state'], OutboxState.conflict.name);
      final stored = (await harness.rows(offlineConflictsTable)).single;
      expect(stored['operation_id'], operation.id);
      expect(stored['local_json'], '{"value":2}');
      expect(stored['base_version'], '1');
      expect(stored['server_version'], '2');
      expect(stored['remote_json'], contains('"value":9'));

      final item = (await harness.rows(offlineItemsTable)).single;
      expect(item['data_json'], '{"value":1}');
      expect(item['pending_overlay_json'], '{"value":2}');

      await harness.close();
      await harness.open(scopeA);
      expect(await harness.rows(offlineConflictsTable), hasLength(1));
      expect(
        (await harness.rows(offlineOutboxTable)).single['state'],
        OutboxState.conflict.name,
      );
      expect(
        (await harness.rows(offlineItemsTable)).single['pending_overlay_json'],
        '{"value":2}',
      );
    },
  );

  test(
    'a pull cannot overwrite a row with a pending conflict overlay',
    () async {
      await harness.insertItem(
        'item-1',
        data: '{"value":1}',
        pendingOverlay: '{"value":2}',
      );
      await harness.enqueue(
        entityKey: 'item-1',
        localOverlayJson: '{"value":2}',
      );
      final conflict = const SyncConflict(
        localOverlay: <String, Object?>{'value': 2},
        remoteSnapshot: <String, Object?>{'value': 9},
        baseVersion: '1',
        serverVersion: '2',
      );
      final worker = workerWith(
        (_) async => SyncSendOutcome.versionConflict(conflict),
      );
      expectOk(await worker.runOnce());

      final server = FakeSyncServer(
        pullHandler: (cursor, page) async => Result.ok(
          const SyncPullPage(
            items: <SyncPullItem>[
              SyncPullItem(
                id: 'item-1',
                version: '3',
                data: <String, Object?>{'value': 99},
              ),
            ],
          ),
        ),
      );
      final coordinator = SyncCoordinator(
        database: harness.database,
        scopeStore: harness.scopeStore,
        worker: workerWith(server.send),
        transport: server,
        clock: () => now,
      );

      expectOk(
        await coordinator.sync(
          const SyncDataset(name: 'home_items', policy: writablePolicy),
        ),
      );

      final item = (await harness.rows(offlineItemsTable)).single;
      expect(item['data_json'], '{"value":1}');
      expect(item['pending_overlay_json'], '{"value":2}');
      expect(item['version'], '1');
    },
  );

  test('412 follows the same typed conflict path', () async {
    await harness.insertItem('item-1');
    await harness.enqueue();
    final conflict = const SyncConflict(
      localOverlay: <String, Object?>{'value': 2},
      remoteSnapshot: <String, Object?>{'value': 4},
      baseVersion: '1',
      serverVersion: '2',
    );
    final server = FakeSyncServer(
      sendHandler: (operation, attempt) async =>
          fakeOutcomeForStatus(412, conflict: conflict),
    );
    final worker = workerWith(server.send);

    final run = await worker.runOnce();
    expectOk(run);
    expect((run as Ok<OutboxRunSummary>).data.conflicts, 1);
    expect(
      (await harness.rows(offlineOutboxTable)).single['state'],
      OutboxState.conflict.name,
    );

    final outcome = SyncSendOutcome.versionConflict(conflict);
    expect(outcome, isA<SyncVersionConflict>());
  });
}
