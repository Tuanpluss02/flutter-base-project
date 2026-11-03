// ignore_for_file: prefer_initializing_formals

import 'dart:convert';

import 'package:base/src/core/error/app_failure.dart';
import 'package:base/src/core/offline/db/offline_database.dart';
import 'package:base/src/core/offline/db/tables.dart';
import 'package:base/src/core/offline/outbox/outbox_operation.dart';
import 'package:base/src/core/offline/outbox/outbox_worker.dart';
import 'package:base/src/core/offline/policy/offline_config.dart';
import 'package:base/src/core/offline/policy/offline_policy.dart';
import 'package:base/src/core/offline/scope/data_scope_store.dart';
import 'package:base/src/core/offline/sync/sync_dataset.dart';
import 'package:base/src/core/result/result.dart';
import 'package:base/src/core/scope/data_scope.dart';

/// Outcome counters for one push-then-pull cycle.
final class SyncCycleResult {
  const SyncCycleResult({
    this.pushed = 0,
    this.pulled = 0,
    this.conflicts = 0,
    this.needsAttention = 0,
    this.suspended = false,
    this.resyncPerformed = false,
    this.disabled = false,
  });

  /// Result reported when the offline module is disabled.
  const SyncCycleResult.disabled() : this(disabled: true);

  /// Operations acknowledged during the push phase.
  final int pushed;

  /// Records applied during the pull phase.
  final int pulled;

  /// Operations that entered durable conflict state.
  final int conflicts;

  /// Operations that need attention.
  final int needsAttention;

  /// Whether an auth failure stopped the cycle before pulling.
  final bool suspended;

  /// Whether the cycle performed a full baseline resync.
  final bool resyncPerformed;

  /// Whether OFFLINE_ENABLED is false.
  final bool disabled;
}

/// Orchestrates outbox push and delta pull for one [SyncDataset].
///
/// A full resync replaces the item pool of the active scope. The current
/// schema has no dataset column on `offline_items`, so a scope must use one
/// item pool per dataset until a dataset-aware migration is approved.
final class SyncCoordinator {
  SyncCoordinator({
    required OfflineDatabase database,
    required DataScopeStore scopeStore,
    required OutboxWorker worker,
    required SyncTransport transport,
    this.config = const OfflineConfig(),
    DateTime Function()? clock,
    int maxPages = 100,
  }) : _database = database,
       _scopeStore = scopeStore,
       _worker = worker,
       _transport = transport,
       _clock = clock ?? DateTime.now,
       _maxPages = maxPages;

  final OfflineDatabase _database;
  final DataScopeStore _scopeStore;
  final OutboxWorker _worker;
  final SyncTransport _transport;
  final DateTime Function() _clock;
  final int _maxPages;
  final Map<String, Future<Result<SyncCycleResult>>> _inFlight =
      <String, Future<Result<SyncCycleResult>>>{};
  Future<Result<int>>? _recoveryInFlight;
  DataScope? _recoveredScope;

  /// Feature flag for the offline module.
  final OfflineConfig config;

  /// Pushes pending work first, then pulls delta pages for [dataset].
  ///
  /// Concurrent calls for the same dataset share one cycle, so two triggers
  /// cannot pull the same cursor twice.
  Future<Result<SyncCycleResult>> sync(SyncDataset dataset) {
    if (!config.enabled) {
      return Future<Result<SyncCycleResult>>.value(
        const Result.ok(SyncCycleResult.disabled()),
      );
    }
    final inFlight = _inFlight[dataset.name];
    if (inFlight != null) return inFlight;
    final guarded = _sync(dataset).whenComplete(() {
      _inFlight.remove(dataset.name);
    });
    _inFlight[dataset.name] = guarded;
    return guarded;
  }

  Future<Result<SyncCycleResult>> _sync(SyncDataset dataset) async {
    if (!dataset.policy.mayPersistLocally) {
      return const Result.err(AppFailure.localPersistence());
    }
    final scope = _scopeStore.scope;
    if (scope == null) {
      return const Result.err(AppFailure.localPersistence());
    }
    final epoch = _scopeStore.epoch;

    final recovered = await _recoverIfNeeded(scope);
    if (recovered is Err<int>) return Result.err(recovered.failure);

    final push = await _worker.runOnce();
    if (push is Err<OutboxRunSummary>) {
      return Result.err(push.failure);
    }
    final pushed = (push as Ok<OutboxRunSummary>).data;
    if (pushed.aborted) {
      return const Result.err(AppFailure.localPersistence());
    }
    if (pushed.suspended) {
      return Result.ok(
        SyncCycleResult(
          pushed: pushed.synced,
          conflicts: pushed.conflicts,
          needsAttention: pushed.needsAttention,
          suspended: true,
        ),
      );
    }

    final state = await _readSyncState(scope, dataset.name);
    if (state is Err<Map<String, Object?>?>) {
      return Result.err(state.failure);
    }
    final row = (state as Ok<Map<String, Object?>?>).data;
    if (row != null && row['resync_required'] == 1) {
      final resync = await _resync(dataset, scope);
      if (resync is Err<SyncCycleResult>) {
        return Result.err(resync.failure);
      }
      final cycle = (resync as Ok<SyncCycleResult>).data;
      return Result.ok(
        SyncCycleResult(
          pushed: pushed.synced,
          pulled: cycle.pulled,
          conflicts: pushed.conflicts,
          needsAttention: pushed.needsAttention,
          resyncPerformed: true,
        ),
      );
    }

    final pull = await _pullDelta(dataset, scope, row);
    if (pull is Err<SyncCycleResult>) {
      return Result.err(pull.failure);
    }
    if (!_scopeStore.isCurrent(scope, epoch)) {
      return const Result.err(AppFailure.localPersistence());
    }
    final cycle = (pull as Ok<SyncCycleResult>).data;
    return Result.ok(
      SyncCycleResult(
        pushed: pushed.synced,
        pulled: cycle.pulled,
        conflicts: pushed.conflicts,
        needsAttention: pushed.needsAttention,
        resyncPerformed: cycle.resyncPerformed,
      ),
    );
  }

  Future<Result<int>> _recoverIfNeeded(DataScope scope) async {
    if (_recoveredScope == scope) return const Result.ok(0);
    final inFlight = _recoveryInFlight;
    if (inFlight != null) return inFlight;
    final future = _worker.recoverAfterRestart().then((result) {
      if (result is Ok<int> && _scopeStore.scope == scope) {
        _recoveredScope = scope;
      }
      return result;
    });
    _recoveryInFlight = future;
    try {
      return await future;
    } finally {
      _recoveryInFlight = null;
    }
  }

  Future<Result<SyncCycleResult>> _pullDelta(
    SyncDataset dataset,
    DataScope scope,
    Map<String, Object?>? state,
  ) async {
    var cursor = state?['cursor'] as String? ?? dataset.cursor;
    var pulled = 0;
    for (var pageIndex = 0; pageIndex < _maxPages; pageIndex++) {
      final response = await _transport.pull(
        dataset.copyWith(cursor: cursor),
        cursor: cursor,
      );
      if (response is Err<SyncPullPage>) {
        return Result.err(response.failure);
      }
      final page = (response as Ok<SyncPullPage>).data;
      if (page.resyncRequired) {
        return _resync(dataset, scope);
      }
      if (page.hasMore && page.nextCursor == null) {
        return const Result.err(AppFailure.parse());
      }
      final applied = await _applyPage(dataset, scope, page, page.nextCursor);
      if (applied is Err<int>) return Result.err(applied.failure);
      pulled += (applied as Ok<int>).data;
      if (!page.hasMore) {
        return Result.ok(
          SyncCycleResult(pulled: pulled, resyncPerformed: false),
        );
      }
      if (page.nextCursor == null) break;
      cursor = page.nextCursor;
    }
    return const Result.err(AppFailure.unknown());
  }

  Future<Result<int>> _applyPage(
    SyncDataset dataset,
    DataScope scope,
    SyncPullPage page,
    String? cursor,
  ) async {
    var applied = 0;
    final now = _clock().toUtc();
    final result = await _database.transaction((tx) async {
      for (final item in page.items) {
        if (await _applyPullItem(tx, scope, item, now)) applied++;
      }
      await _writeSyncState(
        tx,
        scope,
        dataset.name,
        cursor: cursor,
        lastSyncedAt: now,
        minSupportedCursor: page.minSupportedCursor,
        resyncRequired: false,
      );
    });
    if (result is Err<void>) return Result.err(result.failure);
    return Result.ok(applied);
  }

  Future<Result<SyncCycleResult>> _resync(
    SyncDataset dataset,
    DataScope scope,
  ) async {
    final marked = await _markResyncRequired(dataset, scope);
    if (marked is Err<void>) return Result.err(marked.failure);

    final baseline = <SyncPullItem>[];
    String? cursor;
    String? nextCursor;
    String? minSupportedCursor;
    for (var pageIndex = 0; pageIndex < _maxPages; pageIndex++) {
      final response = await _transport.pull(
        dataset.copyWith(cursor: cursor, resyncRequired: true),
        cursor: cursor,
      );
      if (response is Err<SyncPullPage>) {
        return Result.err(response.failure);
      }
      final page = (response as Ok<SyncPullPage>).data;
      baseline.addAll(page.items);
      nextCursor = page.nextCursor ?? nextCursor;
      minSupportedCursor = page.minSupportedCursor ?? minSupportedCursor;
      if (!page.hasMore) break;
      if (page.nextCursor == null) {
        return const Result.err(AppFailure.parse());
      }
      cursor = page.nextCursor;
      if (pageIndex == _maxPages - 1) {
        return const Result.err(AppFailure.unknown());
      }
    }

    final swapped = await _swapBaseline(
      dataset,
      scope,
      baseline,
      cursor: nextCursor,
      minSupportedCursor: minSupportedCursor,
    );
    if (swapped is Err<void>) return Result.err(swapped.failure);
    return Result.ok(
      SyncCycleResult(pulled: baseline.length, resyncPerformed: true),
    );
  }

  Future<Result<void>> _markResyncRequired(
    SyncDataset dataset,
    DataScope scope,
  ) async {
    return _database.transaction((tx) async {
      final existing = await _selectSyncState(tx, scope, dataset.name);
      final row = existing.isEmpty ? null : existing.single;
      await _writeSyncState(
        tx,
        scope,
        dataset.name,
        cursor: row?['cursor'] as String?,
        lastSyncedAt: _dateFrom(row?['last_synced_at']),
        minSupportedCursor: row?['min_supported_cursor'] as String?,
        resyncRequired: true,
      );
    });
  }

  Future<Result<void>> _swapBaseline(
    SyncDataset dataset,
    DataScope scope,
    List<SyncPullItem> baseline, {
    required String? cursor,
    required String? minSupportedCursor,
  }) async {
    final now = _clock().toUtc();
    return _database.transaction((tx) async {
      final existing = await tx.select(
        OfflineQuery(table: offlineItemsTable, scope: scope),
      );
      final baselineIds = <String>{for (final item in baseline) item.id};
      for (final item in baseline) {
        await _applyPullItem(tx, scope, item, now);
      }
      for (final row in existing) {
        final id = row['id']! as String;
        if (baselineIds.contains(id)) continue;
        if (row['deleted_at'] != null) continue;
        if (row['version'] == null) continue;
        if (await _hasPendingEntity(tx, scope, id)) continue;
        await tx.update(
          offlineItemsTable,
          <String, Object?>{
            'deleted_at': now.millisecondsSinceEpoch,
            'updated_at': now.millisecondsSinceEpoch,
          },
          whereSql: 'id = ?',
          whereArgs: <Object?>[id],
        );
      }
      await _writeSyncState(
        tx,
        scope,
        dataset.name,
        cursor: cursor,
        lastSyncedAt: now,
        minSupportedCursor: minSupportedCursor,
        resyncRequired: false,
      );
    });
  }

  Future<bool> _applyPullItem(
    OfflineTransaction tx,
    DataScope scope,
    SyncPullItem item,
    DateTime now,
  ) async {
    if (await _hasPendingEntity(tx, scope, item.id)) return false;
    final existing = await tx.select(
      OfflineQuery(
        table: offlineItemsTable,
        scope: scope,
        whereSql: 'id = ?',
        whereArgs: <Object?>[item.id],
        limit: 1,
      ),
    );
    final values = <String, Object?>{
      'data_json': jsonEncode(item.data),
      'version': item.version,
      'deleted_at': item.deleted
          ? (item.deletedAt ?? now).millisecondsSinceEpoch
          : null,
      'updated_at': (item.updatedAt ?? now).millisecondsSinceEpoch,
      'pending_overlay_json': null,
    };
    if (existing.isEmpty) {
      await tx.insert(offlineItemsTable, <String, Object?>{
        'id': item.id,
        ...values,
      });
    } else {
      await tx.update(
        offlineItemsTable,
        values,
        whereSql: 'id = ?',
        whereArgs: <Object?>[item.id],
      );
    }
    return true;
  }

  Future<bool> _hasPendingEntity(
    OfflineTransaction tx,
    DataScope scope,
    String entityKey,
  ) async {
    final items = await tx.select(
      OfflineQuery(
        table: offlineItemsTable,
        scope: scope,
        whereSql: 'id = ?',
        whereArgs: <Object?>[entityKey],
        limit: 1,
      ),
    );
    if (items.isNotEmpty && items.single['pending_overlay_json'] != null) {
      return true;
    }
    final operations = await tx.select(
      OfflineQuery(
        table: offlineOutboxTable,
        scope: scope,
        whereSql: 'entity_key = ?',
        whereArgs: <Object?>[entityKey],
        orderBy: 'sequence ASC',
      ),
    );
    for (final row in operations) {
      final operation = outboxOperationFromRow(row, scope);
      if (operation.state != OutboxState.synced &&
          operation.state != OutboxState.discarded) {
        return true;
      }
    }
    return false;
  }

  Future<Result<Map<String, Object?>?>> _readSyncState(
    DataScope scope,
    String dataset,
  ) async {
    final result = await _database.query(
      OfflineQuery(
        table: offlineSyncStateTable,
        scope: scope,
        whereSql: 'dataset = ?',
        whereArgs: <Object?>[dataset],
        limit: 1,
      ),
    );
    if (result is Err<List<Map<String, Object?>>>) {
      return Result.err(result.failure);
    }
    final rows = (result as Ok<List<Map<String, Object?>>>).data;
    return Result.ok(rows.isEmpty ? null : rows.single);
  }

  Future<List<Map<String, Object?>>> _selectSyncState(
    OfflineTransaction tx,
    DataScope scope,
    String dataset,
  ) {
    return tx.select(
      OfflineQuery(
        table: offlineSyncStateTable,
        scope: scope,
        whereSql: 'dataset = ?',
        whereArgs: <Object?>[dataset],
        limit: 1,
      ),
    );
  }

  Future<void> _writeSyncState(
    OfflineTransaction tx,
    DataScope scope,
    String dataset, {
    required String? cursor,
    required DateTime? lastSyncedAt,
    required String? minSupportedCursor,
    required bool resyncRequired,
  }) async {
    final existing = await _selectSyncState(tx, scope, dataset);
    final current = existing.isEmpty ? null : existing.single;
    final effectiveMinCursor =
        minSupportedCursor ?? (current?['min_supported_cursor'] as String?);
    final values = <String, Object?>{
      'cursor': cursor,
      'last_synced_at': lastSyncedAt?.millisecondsSinceEpoch,
      'min_supported_cursor': effectiveMinCursor,
      'resync_required': resyncRequired ? 1 : 0,
    };
    if (existing.isEmpty) {
      await tx.insert(offlineSyncStateTable, <String, Object?>{
        'dataset': dataset,
        ...values,
      });
    } else {
      await tx.update(
        offlineSyncStateTable,
        values,
        whereSql: 'dataset = ?',
        whereArgs: <Object?>[dataset],
      );
    }
  }
}

DateTime? _dateFrom(Object? value) {
  if (value == null) return null;
  if (value is num) {
    return DateTime.fromMillisecondsSinceEpoch(value.toInt(), isUtc: true);
  }
  throw const FormatException('Invalid timestamp');
}
