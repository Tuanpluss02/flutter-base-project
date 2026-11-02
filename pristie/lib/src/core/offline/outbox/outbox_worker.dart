// ignore_for_file: prefer_initializing_formals

import 'dart:convert';
import 'dart:math';

import 'package:pristie/src/core/error/app_failure.dart';
import 'package:pristie/src/core/offline/db/offline_database.dart';
import 'package:pristie/src/core/offline/db/tables.dart';
import 'package:pristie/src/core/offline/outbox/outbox_operation.dart';
import 'package:pristie/src/core/offline/policy/offline_config.dart';
import 'package:pristie/src/core/offline/policy/offline_policy.dart';
import 'package:pristie/src/core/offline/scope/data_scope_store.dart';
import 'package:pristie/src/core/offline/sync/sync_conflict.dart';
import 'package:pristie/src/core/offline/sync/sync_send_outcome.dart';
import 'package:pristie/src/core/result/result.dart';
import 'package:pristie/src/core/scope/data_scope.dart';
import 'package:uuid/uuid.dart';

/// Sends one claimed operation to the backend adapter.
typedef OutboxSender = Future<SyncSendOutcome> Function(
  OutboxOperation operation,
);

/// Counters produced by one outbox drain.
final class OutboxRunSummary {
  const OutboxRunSummary({
    this.disabled = false,
    this.suspended = false,
    this.aborted = false,
    this.processed = 0,
    this.synced = 0,
    this.retryable = 0,
    this.conflicts = 0,
    this.needsAttention = 0,
    this.cancelled = 0,
  });

  /// Result reported when the offline module is disabled.
  const OutboxRunSummary.disabled() : this(disabled: true);

  /// Whether the worker refused to run because OFFLINE_ENABLED is false.
  final bool disabled;

  /// Whether an auth failure stopped the queue for the current session.
  final bool suspended;

  /// Whether a scope change fenced the run before it finished.
  final bool aborted;

  /// Number of claimed operations.
  final int processed;

  /// Number acknowledged by the server.
  final int synced;

  /// Number left pending for a later retry.
  final int retryable;

  /// Number moved to durable conflict state.
  final int conflicts;

  /// Number moved to needs-attention state.
  final int needsAttention;

  /// Number of cancelled sends that were not treated as business failures.
  final int cancelled;
}

/// Claims and drains durable outbox operations for the active [DataScope].
///
/// The worker never deletes pending or conflict rows, never sends an operation
/// from another scope, and never changes the idempotency key of an operation.
final class OutboxWorker {
  OutboxWorker({
    required OfflineDatabase database,
    required DataScopeStore scopeStore,
    required OutboxSender send,
    this.config = const OfflineConfig(),
    DateTime Function()? clock,
    Duration leaseDuration = const Duration(seconds: 30),
    int batchSize = 20,
    double jitterRatio = 0.2,
    Random? random,
    String Function()? leaseIdGenerator,
    String Function()? conflictIdGenerator,
  }) : _clock = clock ?? DateTime.now,
       _leaseDuration = leaseDuration,
       _batchSize = batchSize,
       _jitterRatio = jitterRatio,
       _random = random ?? Random(),
       _leaseIdGenerator = leaseIdGenerator,
       _conflictIdGenerator = conflictIdGenerator,
       _database = database,
       _scopeStore = scopeStore,
       _send = send;

  final OfflineDatabase _database;
  final DataScopeStore _scopeStore;
  final OutboxSender _send;
  final DateTime Function() _clock;
  final Duration _leaseDuration;
  final int _batchSize;
  final double _jitterRatio;
  final Random _random;
  final String Function()? _leaseIdGenerator;
  final String Function()? _conflictIdGenerator;
  Future<Result<OutboxRunSummary>>? _running;
  bool _started = false;

  /// Feature flag for the offline module.
  final OfflineConfig config;

  /// Whether the worker may run at all.
  bool get isEnabled => config.enabled;

  /// Whether a sync trigger has started this worker.
  bool get isStarted => _started;

  /// Marks the worker as active; a disabled worker stays stopped.
  void start() {
    if (!config.enabled) return;
    _started = true;
  }

  /// Stops future triggers from using this worker.
  void stop() {
    _started = false;
  }

  /// Drains one batch of pending operations.
  ///
  /// Concurrent calls share the same future, so two triggers in one process
  /// cannot send the same operation twice.
  Future<Result<OutboxRunSummary>> runOnce() {
    if (!config.enabled) {
      return Future<Result<OutboxRunSummary>>.value(
        const Result.ok(OutboxRunSummary.disabled()),
      );
    }
    final inFlight = _running;
    if (inFlight != null) return inFlight;
    final guarded = _run().whenComplete(() => _running = null);
    _running = guarded;
    return guarded;
  }

  /// Resets every `syncing` row to `pending` after a process restart.
  Future<Result<int>> recoverAfterRestart() async {
    if (!config.enabled) return const Result.ok(0);
    final scope = _scopeStore.scope;
    if (scope == null) {
      return const Result.err(AppFailure.localPersistence());
    }
    try {
      return Result.ok(await _recoverSyncing(scope, force: true));
    } catch (_) {
      return const Result.err(AppFailure.localPersistence());
    }
  }

  Future<Result<OutboxRunSummary>> _run() async {
    final scope = _scopeStore.scope;
    if (scope == null) {
      return const Result.err(AppFailure.localPersistence());
    }
    final epoch = _scopeStore.epoch;
    try {
      await _recoverSyncing(scope, force: false);
      final pending = await _database.query(
        OfflineQuery(
          table: offlineOutboxTable,
          scope: scope,
          whereSql: 'state = ?',
          whereArgs: <Object?>[OutboxState.pending.name],
          orderBy: 'sequence ASC',
          limit: _batchSize,
        ),
      );
      if (pending is Err<List<Map<String, Object?>>>) {
        return Result.err(pending.failure);
      }
      final rows = (pending as Ok<List<Map<String, Object?>>>).data;

      var processed = 0;
      var synced = 0;
      var retryable = 0;
      var conflicts = 0;
      var needsAttention = 0;
      var cancelled = 0;
      var suspended = false;
      var aborted = false;

      for (final row in rows) {
        final operation = outboxOperationFromRow(row, scope);
        final now = _clock().toUtc();
        if (!_scopeStore.isCurrent(scope, epoch)) {
          aborted = true;
          break;
        }
        if (operation.nextAttemptAt != null &&
            operation.nextAttemptAt!.isAfter(now)) {
          continue;
        }
        if (await _blockedByEarlierOperation(operation, scope)) continue;

        final leaseId = _leaseIdGenerator?.call() ?? const Uuid().v4();
        final claimed = await _claim(operation, scope, leaseId, now);
        if (!claimed) continue;
        processed++;

        final claimedOperation = operation.copyWith(
          state: OutboxState.syncing,
          leaseOwner: leaseId,
          leaseExpiresAt: now.add(_leaseDuration),
        );
        final outcome = await _send(claimedOperation);

        if (!_scopeStore.isCurrent(scope, epoch)) {
          aborted = true;
          break;
        }

        switch (outcome) {
          case SyncSent(:final serverVersion, :final serverRecord):
            await _applySynced(
              claimedOperation,
              scope,
              serverVersion: serverVersion,
              serverRecord: serverRecord,
            );
            synced++;
          case SyncRetryable(:final failure, :final retryAfter):
            if (failure is CancelledFailure) {
              await _releaseCancelled(claimedOperation);
              cancelled++;
            } else if (failure is UnauthorizedFailure) {
              await _releaseForAuth(claimedOperation);
              retryable++;
              suspended = true;
            } else {
              await _scheduleRetry(claimedOperation, retryAfter: retryAfter);
              retryable++;
            }
          case SyncRequestInProgress(:final retryAfter):
            await _scheduleRetry(claimedOperation, retryAfter: retryAfter);
            retryable++;
          case SyncVersionConflict(:final conflict):
            await _storeConflict(claimedOperation, conflict);
            conflicts++;
          case SyncNeedsAttention():
            await _markNeedsAttention(claimedOperation);
            needsAttention++;
        }

        if (suspended) break;
      }

      return Result.ok(
        OutboxRunSummary(
          suspended: suspended,
          aborted: aborted,
          processed: processed,
          synced: synced,
          retryable: retryable,
          conflicts: conflicts,
          needsAttention: needsAttention,
          cancelled: cancelled,
        ),
      );
    } catch (_) {
      return const Result.err(AppFailure.localPersistence());
    }
  }

  Future<int> _recoverSyncing(DataScope scope, {required bool force}) async {
    final result = await _database.query(
      OfflineQuery(
        table: offlineOutboxTable,
        scope: scope,
        whereSql: 'state = ?',
        whereArgs: <Object?>[OutboxState.syncing.name],
      ),
    );
    if (result is Err<List<Map<String, Object?>>>) {
      throw StateError('Unable to read syncing operations');
    }
    final rows = (result as Ok<List<Map<String, Object?>>>).data;
    final now = _clock().toUtc();
    var recovered = 0;
    for (final row in rows) {
      final expiresAt = _dateFrom(row['lease_expires_at']);
      if (!force && expiresAt != null && expiresAt.isAfter(now)) continue;
      await _database.transaction((tx) async {
        await tx.update(
          offlineOutboxTable,
          <String, Object?>{
            'state': OutboxState.pending.name,
            'lease_owner': null,
            'lease_expires_at': null,
          },
          whereSql: 'id = ?',
          whereArgs: <Object?>[row['id']],
        );
      });
      recovered++;
    }
    return recovered;
  }

  Future<bool> _blockedByEarlierOperation(
    OutboxOperation operation,
    DataScope scope,
  ) async {
    final result = await _database.query(
      OfflineQuery(
        table: offlineOutboxTable,
        scope: scope,
        whereSql: 'entity_key = ?',
        whereArgs: <Object?>[operation.entityKey],
        orderBy: 'sequence ASC',
      ),
    );
    if (result is Err<List<Map<String, Object?>>>) {
      throw StateError('Unable to read entity operations');
    }
    final rows = (result as Ok<List<Map<String, Object?>>>).data;
    for (final row in rows) {
      final earlier = outboxOperationFromRow(row, scope);
      if (earlier.sequence >= operation.sequence) continue;
      if (earlier.state != OutboxState.synced &&
          earlier.state != OutboxState.discarded) {
        return true;
      }
    }
    return false;
  }

  Future<bool> _claim(
    OutboxOperation operation,
    DataScope scope,
    String leaseId,
    DateTime now,
  ) async {
    final result = await _database.transaction((tx) async {
      await tx.update(
        offlineOutboxTable,
        <String, Object?>{
          'state': OutboxState.syncing.name,
          'lease_owner': leaseId,
          'lease_expires_at': now.add(_leaseDuration).millisecondsSinceEpoch,
        },
        whereSql: 'id = ? AND state = ?',
        whereArgs: <Object?>[operation.id, OutboxState.pending.name],
      );
    });
    if (result is Err<void>) return false;
    final check = await _database.query(
      OfflineQuery(
        table: offlineOutboxTable,
        scope: scope,
        whereSql: 'id = ?',
        whereArgs: <Object?>[operation.id],
      ),
    );
    if (check is Err<List<Map<String, Object?>>>) return false;
    final rows = (check as Ok<List<Map<String, Object?>>>).data;
    return rows.length == 1 &&
        rows.single['state'] == OutboxState.syncing.name &&
        rows.single['lease_owner'] == leaseId;
  }

  Future<void> _applySynced(
    OutboxOperation operation,
    DataScope scope, {
    String? serverVersion,
    Map<String, Object?>? serverRecord,
  }) async {
    final now = _clock().toUtc();
    await _database.transaction((tx) async {
      await tx.update(
        offlineOutboxTable,
        <String, Object?>{
          'state': OutboxState.synced.name,
          'lease_owner': null,
          'lease_expires_at': null,
          'next_attempt_at': null,
        },
        whereSql: 'id = ?',
        whereArgs: <Object?>[operation.id],
      );
      final items = await tx.select(
        OfflineQuery(
          table: offlineItemsTable,
          scope: scope,
          whereSql: 'id = ?',
          whereArgs: <Object?>[operation.entityKey],
          limit: 1,
        ),
      );
      if (items.isEmpty) return;
      final item = items.single;
      final overlay = item['pending_overlay_json'] as String?;
      final values = <String, Object?>{
        'updated_at': now.millisecondsSinceEpoch,
        'pending_overlay_json': null,
      };
      if (operation.operation == OfflineOperation.delete) {
        values['deleted_at'] = now.millisecondsSinceEpoch;
      } else if (serverRecord != null) {
        values['data_json'] = jsonEncode(serverRecord);
        values['version'] =
            serverVersion ??
            serverRecord['version']?.toString() ??
            item['version'];
      } else if (overlay != null) {
        values['data_json'] = _mergeOverlay(
          item['data_json'] as String?,
          overlay,
        );
        values['version'] = serverVersion ?? item['version'];
      } else if (serverVersion != null) {
        values['version'] = serverVersion;
      }
      await tx.update(
        offlineItemsTable,
        values,
        whereSql: 'id = ?',
        whereArgs: <Object?>[operation.entityKey],
      );
    });
  }

  Future<void> _scheduleRetry(
    OutboxOperation operation, {
    Duration? retryAfter,
  }) async {
    final delay = retryAfter ?? _backoff(operation.attemptCount);
    final next = _clock().toUtc().add(delay);
    await _database.transaction((tx) async {
      await tx.update(
        offlineOutboxTable,
        <String, Object?>{
          'state': OutboxState.pending.name,
          'attempt_count': operation.attemptCount + 1,
          'next_attempt_at': next.millisecondsSinceEpoch,
          'lease_owner': null,
          'lease_expires_at': null,
        },
        whereSql: 'id = ?',
        whereArgs: <Object?>[operation.id],
      );
    });
  }

  Future<void> _releaseForAuth(OutboxOperation operation) async {
    await _database.transaction((tx) async {
      await tx.update(
        offlineOutboxTable,
        <String, Object?>{
          'state': OutboxState.pending.name,
          'attempt_count': operation.attemptCount + 1,
          'next_attempt_at': null,
          'lease_owner': null,
          'lease_expires_at': null,
        },
        whereSql: 'id = ?',
        whereArgs: <Object?>[operation.id],
      );
    });
  }

  Future<void> _releaseCancelled(OutboxOperation operation) async {
    await _database.transaction((tx) async {
      await tx.update(
        offlineOutboxTable,
        <String, Object?>{
          'state': OutboxState.pending.name,
          'next_attempt_at': null,
          'lease_owner': null,
          'lease_expires_at': null,
        },
        whereSql: 'id = ?',
        whereArgs: <Object?>[operation.id],
      );
    });
  }

  Future<void> _markNeedsAttention(OutboxOperation operation) async {
    await _database.transaction((tx) async {
      await tx.update(
        offlineOutboxTable,
        <String, Object?>{
          'state': OutboxState.needsAttention.name,
          'attempt_count': operation.attemptCount + 1,
          'next_attempt_at': null,
          'lease_owner': null,
          'lease_expires_at': null,
        },
        whereSql: 'id = ?',
        whereArgs: <Object?>[operation.id],
      );
    });
  }

  Future<void> _storeConflict(
    OutboxOperation operation,
    SyncConflict conflict,
  ) async {
    final now = _clock().toUtc();
    await _database.transaction((tx) async {
      final items = await tx.select(
        OfflineQuery(
          table: offlineItemsTable,
          scope: operation.dataScope,
          whereSql: 'id = ?',
          whereArgs: <Object?>[operation.entityKey],
          limit: 1,
        ),
      );
      final overlay = items.isEmpty
          ? null
          : items.single['pending_overlay_json'] as String?;
      final localJson = overlay ?? operation.payloadJson;
      final remoteJson = conflict.remoteSnapshot is String
          ? conflict.remoteSnapshot! as String
          : jsonEncode(conflict.remoteSnapshot);
      final conflictId = _conflictIdGenerator?.call() ?? const Uuid().v4();
      await tx.insert(offlineConflictsTable, <String, Object?>{
        'id': conflictId,
        'operation_id': operation.id,
        'local_json': localJson,
        'remote_json': remoteJson,
        'base_version': conflict.baseVersion,
        'server_version': conflict.serverVersion,
        'created_at': now.millisecondsSinceEpoch,
      });
      await tx.update(
        offlineOutboxTable,
        <String, Object?>{
          'state': OutboxState.conflict.name,
          'next_attempt_at': null,
          'lease_owner': null,
          'lease_expires_at': null,
        },
        whereSql: 'id = ?',
        whereArgs: <Object?>[operation.id],
      );
    });
  }

  Duration _backoff(int attemptCount) {
    final exponent = attemptCount.clamp(0, 10);
    final baseMs = 1000 * (1 << exponent);
    final capped = baseMs.clamp(1000, 5 * 60 * 1000);
    final jitter = (capped * _jitterRatio * (_random.nextDouble() * 2 - 1))
        .round();
    final delay = (capped + jitter).clamp(1000, 5 * 60 * 1000);
    return Duration(milliseconds: delay);
  }
}

String _mergeOverlay(String? baseJson, String overlayJson) {
  if (baseJson == null) return overlayJson;
  try {
    final base = jsonDecode(baseJson);
    final overlay = jsonDecode(overlayJson);
    if (base is Map<String, Object?> && overlay is Map<String, Object?>) {
      return jsonEncode(<String, Object?>{...base, ...overlay});
    }
  } on Object {
    return overlayJson;
  }
  return overlayJson;
}

DateTime? _dateFrom(Object? value) {
  if (value == null) return null;
  if (value is num) {
    return DateTime.fromMillisecondsSinceEpoch(value.toInt(), isUtc: true);
  }
  throw const FormatException('Invalid timestamp');
}
