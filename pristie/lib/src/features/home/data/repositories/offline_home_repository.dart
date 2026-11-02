// ignore_for_file: prefer_initializing_formals

import 'dart:convert';

import 'package:pristie/src/core/error/app_failure.dart';
import 'package:pristie/src/core/offline/db/offline_database.dart';
import 'package:pristie/src/core/offline/db/tables.dart';
import 'package:pristie/src/core/offline/outbox/outbox_operation.dart';
import 'package:pristie/src/core/offline/policy/offline_policy.dart';
import 'package:pristie/src/core/offline/scope/data_scope_store.dart';
import 'package:pristie/src/core/offline/sync/sync_coordinator.dart';
import 'package:pristie/src/core/offline/sync/sync_dataset.dart';
import 'package:pristie/src/core/result/result.dart';
import 'package:pristie/src/core/scope/data_classification.dart';

import '../../domain/entities/demo_item.dart';

/// Sample home dataset contract. The dataset is read-only, so no mutation is
/// allowed while offline.
const homeOfflinePolicy = OfflinePolicy(
  dataset: 'home_items',
  classification: DataClassification.s1,
  ttl: Duration(minutes: 10),
  allowedOperations: <OfflineOperation>{},
  conflictPolicy: ConflictPolicy.serverWins,
);

/// Cached home content plus the metadata needed to derive a [SyncStatus].
final class HomeOfflineSnapshot {
  const HomeOfflineSnapshot({
    required this.items,
    required this.pendingCount,
    required this.conflictCount,
    required this.needsAttentionCount,
    required this.lastSyncedAt,
  });

  /// Locally cached demo items.
  final List<DemoItem> items;

  /// Operations waiting to be sent.
  final int pendingCount;

  /// Operations in durable conflict state.
  final int conflictCount;

  /// Operations rejected and awaiting user action.
  final int needsAttentionCount;

  /// Last successful delta sync, when known.
  final DateTime? lastSyncedAt;
}

/// Read-first contract used by the offline home cubit.
abstract interface class OfflineHomeDataSource {
  /// Dataset policy, including the TTL used for stale detection.
  OfflinePolicy get policy;

  /// Reads cached data without touching the network.
  Future<Result<HomeOfflineSnapshot>> readCached();

  /// Pushes pending work, pulls delta pages, then reads the cache again.
  Future<Result<HomeOfflineSnapshot>> refresh();
}

/// Local-first home repository backed by the encrypted offline database.
final class OfflineHomeRepository implements OfflineHomeDataSource {
  OfflineHomeRepository({
    required OfflineDatabase database,
    required DataScopeStore scopeStore,
    required SyncCoordinator coordinator,
    SyncDataset dataset = const SyncDataset(
      name: 'home_items',
      policy: homeOfflinePolicy,
    ),
  }) : _database = database,
       _scopeStore = scopeStore,
       _coordinator = coordinator,
       _dataset = dataset;

  final OfflineDatabase _database;
  final DataScopeStore _scopeStore;
  final SyncCoordinator _coordinator;
  final SyncDataset _dataset;

  @override
  OfflinePolicy get policy => _dataset.policy;

  @override
  Future<Result<HomeOfflineSnapshot>> readCached() async {
    final scope = _scopeStore.scope;
    if (scope == null) {
      return const Result.err(AppFailure.localPersistence());
    }
    final itemsResult = await _database.query(
      OfflineQuery(
        table: offlineItemsTable,
        scope: scope,
        orderBy: 'updated_at DESC',
      ),
    );
    if (itemsResult is Err<List<Map<String, Object?>>>) {
      return Result.err(itemsResult.failure);
    }
    final items = <DemoItem>[];
    for (final row in (itemsResult as Ok<List<Map<String, Object?>>>).data) {
      if (row['deleted_at'] != null) continue;
      final id = _itemId(row);
      if (id != null) items.add(DemoItem(id: id));
    }

    final outboxResult = await _database.query(
      OfflineQuery(table: offlineOutboxTable, scope: scope),
    );
    if (outboxResult is Err<List<Map<String, Object?>>>) {
      return Result.err(outboxResult.failure);
    }
    var pending = 0;
    var needsAttention = 0;
    for (final row in (outboxResult as Ok<List<Map<String, Object?>>>).data) {
      final state = row['state'];
      if (state == OutboxState.pending.name ||
          state == OutboxState.syncing.name) {
        pending++;
      } else if (state == OutboxState.needsAttention.name) {
        needsAttention++;
      }
    }

    final conflictResult = await _database.query(
      OfflineQuery(table: offlineConflictsTable, scope: scope),
    );
    if (conflictResult is Err<List<Map<String, Object?>>>) {
      return Result.err(conflictResult.failure);
    }
    final conflicts =
        (conflictResult as Ok<List<Map<String, Object?>>>).data.length;

    final stateResult = await _database.query(
      OfflineQuery(
        table: offlineSyncStateTable,
        scope: scope,
        whereSql: 'dataset = ?',
        whereArgs: <Object?>[_dataset.name],
        limit: 1,
      ),
    );
    if (stateResult is Err<List<Map<String, Object?>>>) {
      return Result.err(stateResult.failure);
    }
    final stateRows = (stateResult as Ok<List<Map<String, Object?>>>).data;
    final lastSyncedAt = stateRows.isEmpty
        ? null
        : _dateFrom(stateRows.single['last_synced_at']);

    return Result.ok(
      HomeOfflineSnapshot(
        items: items,
        pendingCount: pending,
        conflictCount: conflicts,
        needsAttentionCount: needsAttention,
        lastSyncedAt: lastSyncedAt,
      ),
    );
  }

  @override
  Future<Result<HomeOfflineSnapshot>> refresh() async {
    final result = await _coordinator.sync(_dataset);
    if (result is Err<SyncCycleResult>) {
      return Result.err(result.failure);
    }
    return readCached();
  }

  int? _itemId(Map<String, Object?> row) {
    final id = int.tryParse(row['id']?.toString() ?? '');
    if (id != null) return id;
    final raw = row['data_json'];
    if (raw is! String) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        final value = decoded['item_id'] ?? decoded['id'];
        if (value is num) return value.toInt();
        if (value is String) return int.tryParse(value);
      }
    } on Object {
      return null;
    }
    return null;
  }
}

DateTime? _dateFrom(Object? value) {
  if (value == null) return null;
  if (value is num) {
    return DateTime.fromMillisecondsSinceEpoch(value.toInt(), isUtc: true);
  }
  return null;
}
