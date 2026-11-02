import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:pristie/src/core/error/app_failure.dart';
import 'package:pristie/src/core/offline/db/tables.dart';
import 'package:pristie/src/core/offline/outbox/outbox_operation.dart';
import 'package:pristie/src/core/offline/outbox/outbox_worker.dart';
import 'package:pristie/src/core/offline/policy/offline_config.dart';
import 'package:pristie/src/core/offline/sync/sync_coordinator.dart';
import 'package:pristie/src/core/offline/sync/sync_dataset.dart';
import 'package:pristie/src/core/offline/sync/sync_send_outcome.dart';
import 'package:pristie/src/core/result/result.dart';

import 'fakes/fake_sync_server.dart';
import 'offline_test_support.dart';
import 'sync_test_support.dart';

void main() {
  late OfflineHarness harness;
  final now = DateTime.utc(2026, 1, 1, 12);
  const dataset = SyncDataset(name: 'home_items', policy: writablePolicy);

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
  }) => OutboxWorker(
    database: harness.database,
    scopeStore: harness.scopeStore,
    send: send,
    config: config,
    clock: () => now,
  );

  SyncCoordinator coordinatorWith(
    FakeSyncServer server, {
    OfflineConfig config = const OfflineConfig(enabled: true),
  }) => SyncCoordinator(
    database: harness.database,
    scopeStore: harness.scopeStore,
    worker: workerWith(server.send, config: config),
    transport: server,
    config: config,
    clock: () => now,
  );

  Future<void> seedSyncState({
    String? cursor,
    bool resyncRequired = false,
  }) async {
    expectOk(
      await harness.database.transaction((tx) async {
        await tx.insert(offlineSyncStateTable, <String, Object?>{
          'dataset': dataset.name,
          'cursor': cursor,
          'last_synced_at': null,
          'min_supported_cursor': null,
          'resync_required': resyncRequired ? 1 : 0,
        });
      }),
    );
  }

  Future<Map<String, Object?>> syncStateRow() async => (await harness.rows(
    offlineSyncStateTable,
    whereSql: 'dataset = ?',
    whereArgs: <Object?>[dataset.name],
  )).single;

  test('pushes pending work before pulling, then applies page and cursor '
      'in one transaction', () async {
    await harness.enqueue();
    final server = FakeSyncServer(
      pullHandler: (cursor, page) async => switch (cursor) {
        null => Result.ok(
          const SyncPullPage(
            items: <SyncPullItem>[
              SyncPullItem(
                id: 'server-1',
                version: '1',
                data: <String, Object?>{'title': 'A'},
                updatedAt: null,
              ),
            ],
            nextCursor: 'cursor-1',
            hasMore: true,
          ),
        ),
        'cursor-1' => Result.ok(
          const SyncPullPage(
            items: <SyncPullItem>[
              SyncPullItem(
                id: 'server-2',
                version: '1',
                data: <String, Object?>{'title': 'B'},
              ),
            ],
            nextCursor: 'cursor-2',
          ),
        ),
        _ => Result.err(const AppFailure.network()),
      },
    );
    final coordinator = coordinatorWith(server);

    final result = await coordinator.sync(dataset);
    expectOk(result);
    final cycle = (result as Ok<SyncCycleResult>).data;
    expect(cycle.pushed, 1);
    expect(cycle.pulled, 2);
    expect(server.calls, <String>['send', 'pull', 'pull']);
    expect(server.cursors, <String?>[null, 'cursor-1']);

    final items = await harness.rows(offlineItemsTable, orderBy: 'id ASC');
    expect(items.map((row) => row['id']), <Object?>['server-1', 'server-2']);
    expect(items.first['data_json'], '{"title":"A"}');

    final state = await syncStateRow();
    expect(state['cursor'], 'cursor-2');
    expect(state['last_synced_at'], now.millisecondsSinceEpoch);
    expect(state['resync_required'], 0);
  });

  test('concurrent triggers for one dataset share a single cycle', () async {
    await harness.enqueue();
    final gate = Completer<void>();
    final sendStarted = Completer<void>();
    var sends = 0;
    final server = FakeSyncServer(
      sendHandler: (operation, attempt) async {
        sends++;
        if (!sendStarted.isCompleted) sendStarted.complete();
        await gate.future;
        return const SyncSendOutcome.synced();
      },
      pullHandler: (cursor, page) async =>
          Result.ok(const SyncPullPage(nextCursor: 'cursor-1')),
    );
    final coordinator = coordinatorWith(server);

    final first = coordinator.sync(dataset);
    final second = coordinator.sync(dataset);
    await sendStarted.future;

    expect(sends, 1);
    gate.complete();
    final results = await Future.wait(<Future<Result<SyncCycleResult>>>[
      first,
      second,
    ]);
    for (final result in results) {
      expectOk(result);
    }
    expect(server.calls.where((call) => call == 'send'), hasLength(1));
    expect(server.calls.where((call) => call == 'pull'), hasLength(1));
  });

  test('a failed later page keeps the earlier page and its cursor', () async {
    final server = FakeSyncServer(
      pullHandler: (cursor, page) async => cursor == null
          ? Result.ok(
              const SyncPullPage(
                items: <SyncPullItem>[
                  SyncPullItem(
                    id: 'server-1',
                    data: <String, Object?>{'title': 'A'},
                  ),
                ],
                nextCursor: 'cursor-1',
                hasMore: true,
              ),
            )
          : Result.err(const AppFailure.network()),
    );
    final coordinator = coordinatorWith(server);

    final result = await coordinator.sync(dataset);
    expect(result, isA<Err<SyncCycleResult>>());
    expect(
      (result as Err<SyncCycleResult>).failure,
      const AppFailure.network(),
    );

    expect((await harness.rows(offlineItemsTable)).single['id'], 'server-1');
    expect((await syncStateRow())['cursor'], 'cursor-1');
  });

  test('a pending local overlay is not overwritten by a pulled row', () async {
    await harness.insertItem(
      'item-1',
      data: '{"value":1}',
      pendingOverlay: '{"value":2}',
    );
    await harness.enqueue(entityKey: 'item-1', localOverlayJson: '{"value":2}');
    final server = FakeSyncServer(
      sendHandler: (operation, attempt) async => fakeNetworkOutcome(),
      pullHandler: (cursor, page) async => Result.ok(
        const SyncPullPage(
          items: <SyncPullItem>[
            SyncPullItem(
              id: 'item-1',
              version: '5',
              data: <String, Object?>{'value': 99},
            ),
          ],
          nextCursor: 'cursor-1',
        ),
      ),
    );
    final coordinator = coordinatorWith(server);

    expectOk(await coordinator.sync(dataset));

    final item = (await harness.rows(offlineItemsTable)).single;
    expect(item['data_json'], '{"value":1}');
    expect(item['pending_overlay_json'], '{"value":2}');
    expect(item['version'], '1');
  });

  test('410 resync stages a full baseline and swaps atomically while '
      'preserving outbox and pending overlays', () async {
    await harness.insertItem('stale-1', data: '{"value":"old"}');
    await harness.insertItem('keep-1', data: '{"value":1}');
    await harness.insertItem('draft-1', version: null);
    await harness.insertItem(
      'pending-1',
      data: '{"value":1}',
      pendingOverlay: '{"value":2}',
    );
    await harness.enqueue(
      entityKey: 'pending-1',
      localOverlayJson: '{"value":2}',
    );
    await seedSyncState(cursor: 'old-cursor');

    final server = FakeSyncServer(
      sendHandler: (operation, attempt) async => fakeNetworkOutcome(),
      pullHandler: (cursor, page) async => switch (cursor) {
        'old-cursor' => Result.ok(
          const SyncPullPage(resyncRequired: true, nextCursor: 'old-cursor'),
        ),
        null => Result.ok(
          const SyncPullPage(
            items: <SyncPullItem>[
              SyncPullItem(
                id: 'keep-1',
                version: '2',
                data: <String, Object?>{'value': 2},
              ),
              SyncPullItem(
                id: 'new-1',
                version: '1',
                data: <String, Object?>{'value': 10},
              ),
            ],
            nextCursor: 'baseline-1',
            hasMore: true,
          ),
        ),
        'baseline-1' => Result.ok(
          const SyncPullPage(
            items: <SyncPullItem>[
              SyncPullItem(
                id: 'new-2',
                version: '1',
                data: <String, Object?>{'value': 20},
              ),
            ],
            nextCursor: 'baseline-2',
          ),
        ),
        _ => Result.err(const AppFailure.server(500)),
      },
    );
    final coordinator = coordinatorWith(server);

    final result = await coordinator.sync(dataset);
    expectOk(result);
    final cycle = (result as Ok<SyncCycleResult>).data;
    expect(cycle.resyncPerformed, isTrue);
    expect(server.cursors, <String?>['old-cursor', null, 'baseline-1']);

    final items = await harness.rows(offlineItemsTable, orderBy: 'id ASC');
    final byId = <String, Map<String, Object?>>{
      for (final row in items) row['id']! as String: row,
    };
    expect(
      byId.keys,
      containsAll(<String>['keep-1', 'new-1', 'new-2', 'draft-1']),
    );
    expect(byId['keep-1']!['data_json'], '{"value":2}');
    expect(byId['keep-1']!['version'], '2');
    expect(byId['stale-1']!['deleted_at'], isNotNull);
    expect(byId['draft-1']!['deleted_at'], isNull);
    expect(byId['pending-1']!['data_json'], '{"value":1}');
    expect(byId['pending-1']!['pending_overlay_json'], '{"value":2}');

    final outbox = await harness.rows(offlineOutboxTable);
    expect(outbox, hasLength(1));
    expect(outbox.single['state'], OutboxState.pending.name);

    final state = await syncStateRow();
    expect(state['cursor'], 'baseline-2');
    expect(state['resync_required'], 0);
  });

  test('a failed baseline download leaves the old cache intact and retries '
      'directly into resync', () async {
    await harness.insertItem('keep-1', data: '{"value":1}');
    await seedSyncState(cursor: 'old-cursor');

    final server = FakeSyncServer(
      pullHandler: (cursor, page) async => cursor == 'old-cursor'
          ? Result.ok(const SyncPullPage(resyncRequired: true))
          : Result.err(const AppFailure.network()),
    );
    final coordinator = coordinatorWith(server);

    final failed = await coordinator.sync(dataset);
    expect(failed, isA<Err<SyncCycleResult>>());
    final untouched = (await harness.rows(offlineItemsTable)).single;
    expect(untouched['data_json'], '{"value":1}');
    expect(untouched['deleted_at'], isNull);
    expect((await syncStateRow())['resync_required'], 1);

    server.cursors.clear();
    server.pullHandler = (cursor, page) async => Result.ok(
      const SyncPullPage(
        items: <SyncPullItem>[
          SyncPullItem(
            id: 'keep-1',
            version: '2',
            data: <String, Object?>{'value': 2},
          ),
        ],
        nextCursor: 'baseline-1',
      ),
    );
    final retried = await coordinator.sync(dataset);
    expectOk(retried);
    expect((retried as Ok<SyncCycleResult>).data.resyncPerformed, isTrue);
    expect(server.cursors.first, isNull);
    expect(
      (await harness.rows(offlineItemsTable)).single['data_json'],
      '{"value":2}',
    );
    expect((await syncStateRow())['resync_required'], 0);
  });

  test(
    'the first cycle recovers work stuck syncing from a previous process',
    () async {
      final operation = await harness.enqueue();
      expectOk(
        await harness.database.transaction((tx) async {
          await tx.update(
            offlineOutboxTable,
            <String, Object?>{
              'state': OutboxState.syncing.name,
              'lease_owner': 'previous-process',
              'lease_expires_at': now
                  .add(const Duration(minutes: 10))
                  .millisecondsSinceEpoch,
            },
            whereSql: 'id = ?',
            whereArgs: <Object?>[operation.id],
          );
        }),
      );
      final server = FakeSyncServer();
      final coordinator = coordinatorWith(server);

      final result = await coordinator.sync(dataset);
      expectOk(result);
      expect(
        (await harness.rows(offlineOutboxTable)).single['state'],
        OutboxState.synced.name,
      );
      expect(server.calls, <String>['send', 'pull']);
    },
  );

  test('401 stops the cycle before pulling', () async {
    await harness.enqueue();
    final server = FakeSyncServer(
      sendHandler: (operation, attempt) async => fakeOutcomeForStatus(401),
      pullHandler: (cursor, page) async =>
          Result.ok(const SyncPullPage(nextCursor: 'never')),
    );
    final coordinator = coordinatorWith(server);

    final result = await coordinator.sync(dataset);
    expectOk(result);
    expect((result as Ok<SyncCycleResult>).data.suspended, isTrue);
    expect(server.calls, <String>['send']);
    expect(
      (await harness.rows(offlineOutboxTable)).single['state'],
      OutboxState.pending.name,
    );
  });

  test('S2 datasets fail closed before any push or pull', () async {
    final server = FakeSyncServer();
    final coordinator = coordinatorWith(server);
    const personal = SyncDataset(name: 'personal', policy: personalPolicy);

    final result = await coordinator.sync(personal);
    expectLocalPersistence(result);
    expect(server.calls, isEmpty);
  });

  test('OFFLINE_ENABLED=false keeps the app online-only', () async {
    final server = FakeSyncServer();
    final coordinator = coordinatorWith(
      server,
      config: const OfflineConfig(enabled: false),
    );

    final result = await coordinator.sync(dataset);
    expectOk(result);
    expect((result as Ok<SyncCycleResult>).data.disabled, isTrue);
    expect(server.calls, isEmpty);
  });

  test('tombstones mark cached rows as deleted', () async {
    final server = FakeSyncServer(
      pullHandler: (cursor, page) async => Result.ok(
        SyncPullPage(
          items: <SyncPullItem>[
            SyncPullItem(
              id: 'gone-1',
              deleted: true,
              deletedAt: now,
              data: const <String, Object?>{},
            ),
          ],
          nextCursor: 'cursor-1',
        ),
      ),
    );
    final coordinator = coordinatorWith(server);

    expectOk(await coordinator.sync(dataset));
    final item = (await harness.rows(offlineItemsTable)).single;
    expect(item['deleted_at'], now.millisecondsSinceEpoch);
  });

  test('unknown 409 is needs-attention, not a fabricated conflict', () async {
    await harness.enqueue();
    final server = FakeSyncServer(
      sendHandler: (operation, attempt) async =>
          fakeOutcomeForStatus(409, code: 'SOMETHING_ELSE'),
    );
    final coordinator = coordinatorWith(server);

    expectOk(await coordinator.sync(dataset));
    expect(await harness.rows(offlineConflictsTable), isEmpty);
    expect(
      (await harness.rows(offlineOutboxTable)).single['state'],
      OutboxState.needsAttention.name,
    );
  });
}
