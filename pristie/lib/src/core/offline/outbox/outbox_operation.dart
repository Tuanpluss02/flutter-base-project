import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:pristie/src/core/offline/db/offline_database.dart';
import 'package:pristie/src/core/offline/db/tables.dart';
import 'package:pristie/src/core/offline/policy/offline_policy.dart';
import 'package:pristie/src/core/scope/data_scope.dart';
import 'package:uuid/uuid.dart';

part 'outbox_operation.freezed.dart';

/// Lifecycle state of one durable outbox operation.
enum OutboxState {
  /// Waiting to be claimed.
  pending,

  /// Claimed by a worker with an active lease.
  syncing,

  /// Acknowledged by the server.
  synced,

  /// Rejected by optimistic concurrency and awaiting resolution.
  conflict,

  /// Rejected in a way that requires user or feature action.
  needsAttention,

  /// Explicitly discarded by a feature policy.
  discarded,
}

/// One durable local mutation waiting to be sent to the server.
@freezed
abstract class OutboxOperation with _$OutboxOperation {
  const factory OutboxOperation({
    required String id,
    required DataScope dataScope,
    required int dataScopeEpoch,
    required String entityKey,
    required OfflineOperation operation,
    required int payloadVersion,
    required String payloadJson,
    String? baseVersion,
    required int sequence,
    required OutboxState state,
    @Default(0) int attemptCount,
    DateTime? nextAttemptAt,
    String? leaseOwner,
    DateTime? leaseExpiresAt,
    required String idempotencyKey,
    required DateTime createdAt,
  }) = _OutboxOperation;
}

/// Serializes an operation to the scoped outbox table.
extension OutboxOperationRow on OutboxOperation {
  /// Row values for [offlineOutboxTable]. Scope columns are added by the
  /// database transaction, never by callers.
  Map<String, Object?> toRow() {
    return <String, Object?>{
      'id': id,
      'data_scope_epoch': dataScopeEpoch,
      'entity_key': entityKey,
      'operation': operation.name,
      'payload_version': payloadVersion,
      'payload_json': payloadJson,
      'base_version': baseVersion,
      'sequence': sequence,
      'state': state.name,
      'attempt_count': attemptCount,
      'next_attempt_at': nextAttemptAt?.millisecondsSinceEpoch,
      'lease_owner': leaseOwner,
      'lease_expires_at': leaseExpiresAt?.millisecondsSinceEpoch,
      'idempotency_key': idempotencyKey,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }
}

/// Rebuilds an operation from a scoped database row.
OutboxOperation outboxOperationFromRow(
  Map<String, Object?> row,
  DataScope dataScope,
) {
  try {
    return OutboxOperation(
      id: row['id']! as String,
      dataScope: dataScope,
      dataScopeEpoch: (row['data_scope_epoch']! as num).toInt(),
      entityKey: row['entity_key']! as String,
      operation: OfflineOperation.values.byName(row['operation']! as String),
      payloadVersion: (row['payload_version']! as num).toInt(),
      payloadJson: row['payload_json']! as String,
      baseVersion: row['base_version'] as String?,
      sequence: (row['sequence']! as num).toInt(),
      state: OutboxState.values.byName(row['state']! as String),
      attemptCount: ((row['attempt_count'] as num?) ?? 0).toInt(),
      nextAttemptAt: _dateFrom(row['next_attempt_at']),
      leaseOwner: row['lease_owner'] as String?,
      leaseExpiresAt: _dateFrom(row['lease_expires_at']),
      idempotencyKey: row['idempotency_key']! as String,
      createdAt: _requiredDateFrom(row['created_at']!),
    );
  } on Object catch (error) {
    throw FormatException('Invalid outbox row: $error');
  }
}

DateTime? _dateFrom(Object? value) {
  if (value == null) return null;
  if (value is num) {
    return DateTime.fromMillisecondsSinceEpoch(value.toInt(), isUtc: true);
  }
  throw const FormatException('Invalid timestamp');
}

DateTime _requiredDateFrom(Object value) => _dateFrom(value)!;

/// Writes outbox operations and matching local overlays inside the caller's
/// transaction.
final class OutboxEnqueuer {
  OutboxEnqueuer({Uuid? uuid, DateTime Function()? clock})
    : _uuid = uuid ?? const Uuid(),
      _clock = clock ?? DateTime.now;

  final Uuid _uuid;
  final DateTime Function() _clock;

  /// Inserts a pending operation and, when supplied, the matching pending
  /// overlay on the local row.
  ///
  /// Throws [OfflinePolicyViolation] before writing anything when the dataset
  /// is not allowed to persist locally. The surrounding transaction then rolls
  /// back the local row as well.
  Future<OutboxOperation> enqueue(
    OfflineTransaction tx, {
    required DataScope dataScope,
    required int dataScopeEpoch,
    required OfflinePolicy policy,
    required OfflineOperation operation,
    required String entityKey,
    required int payloadVersion,
    required String payloadJson,
    String? baseVersion,
    String? localOverlayJson,
  }) async {
    if (!policy.mayPersistLocally) {
      throw OfflinePolicyViolation(
        'Dataset ${policy.dataset} is ${policy.classification.name} and must '
        'stay online-only.',
      );
    }
    if (!policy.allowedOperations.contains(operation)) {
      throw OfflinePolicyViolation(
        'Dataset ${policy.dataset} does not allow ${operation.name}.',
      );
    }
    if (entityKey.isEmpty || entityKey.trim() != entityKey) {
      throw const OfflinePolicyViolation('Entity key must be non-empty.');
    }
    if (payloadVersion < 1) {
      throw const OfflinePolicyViolation('Payload version must be positive.');
    }
    if (payloadJson.isEmpty) {
      throw const OfflinePolicyViolation('Payload must not be empty.');
    }

    final now = _clock().toUtc();
    final tail = await tx.select(
      OfflineQuery(
        table: offlineOutboxTable,
        scope: dataScope,
        orderBy: 'sequence DESC',
        limit: 1,
      ),
    );
    final lastSequence = tail.isEmpty
        ? 0
        : (tail.single['sequence']! as num).toInt();
    final operationId = _uuid.v4();
    final queued = OutboxOperation(
      id: operationId,
      dataScope: dataScope,
      dataScopeEpoch: dataScopeEpoch,
      entityKey: entityKey,
      operation: operation,
      payloadVersion: payloadVersion,
      payloadJson: payloadJson,
      baseVersion: baseVersion,
      sequence: lastSequence + 1,
      state: OutboxState.pending,
      idempotencyKey: _uuid.v4(),
      createdAt: now,
    );

    await tx.insert(offlineOutboxTable, queued.toRow());
    if (localOverlayJson != null) {
      await tx.update(
        offlineItemsTable,
        <String, Object?>{
          'pending_overlay_json': localOverlayJson,
          'updated_at': now.millisecondsSinceEpoch,
        },
        whereSql: 'id = ?',
        whereArgs: <Object?>[entityKey],
      );
    }
    return queued;
  }
}
