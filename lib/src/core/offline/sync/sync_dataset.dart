import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:base/src/core/offline/outbox/outbox_operation.dart';
import 'package:base/src/core/offline/policy/offline_policy.dart';
import 'package:base/src/core/offline/sync/sync_send_outcome.dart';
import 'package:base/src/core/result/result.dart';

part '../../../../generated/src/core/offline/sync/sync_dataset.freezed.dart';

/// UI-facing sync state for one offline-enabled feature.
enum SyncStatus {
  /// Local data is current and no work is pending.
  online,

  /// The last refresh failed because the device is offline.
  offline,

  /// Cached data is older than the dataset TTL.
  stale,

  /// A push or pull cycle is running.
  syncing,

  /// Local operations are waiting to be sent.
  pending,

  /// At least one operation needs conflict resolution.
  conflict,

  /// At least one operation was rejected and needs user action.
  needsAttention,
}

/// Dataset registration for the sync coordinator.
@freezed
abstract class SyncDataset with _$SyncDataset {
  const factory SyncDataset({
    required String name,
    required OfflinePolicy policy,
    String? cursor,
    DateTime? lastSuccessfulSyncAt,
    String? minSupportedCursor,
    @Default(false) bool resyncRequired,
  }) = _SyncDataset;
}

/// One record in a delta page.
final class SyncPullItem {
  const SyncPullItem({
    required this.id,
    this.data = const <String, Object?>{},
    this.version,
    this.deleted = false,
    this.deletedAt,
    this.updatedAt,
  });

  /// Stable server identifier.
  final String id;

  /// Server record payload.
  final Map<String, Object?> data;

  /// Server version or ETag.
  final String? version;

  /// Whether this row is a tombstone.
  final bool deleted;

  /// Tombstone timestamp.
  final DateTime? deletedAt;

  /// Server update timestamp.
  final DateTime? updatedAt;
}

/// One page of a delta sync response.
final class SyncPullPage {
  const SyncPullPage({
    this.items = const <SyncPullItem>[],
    this.nextCursor,
    this.hasMore = false,
    this.minSupportedCursor,
    this.resyncRequired = false,
    this.serverTime,
  });

  /// Records in this page.
  final List<SyncPullItem> items;

  /// Opaque cursor to send on the next page.
  final String? nextCursor;

  /// Whether another page is available.
  final bool hasMore;

  /// Oldest cursor the server still supports.
  final String? minSupportedCursor;

  /// Whether the server requires a full baseline resync.
  final bool resyncRequired;

  /// Server clock at response time.
  final DateTime? serverTime;
}

/// Data-plane contract implemented by the backend adapter or a test fake.
///
/// The core never hard-codes an endpoint path; the adapter maps this contract
/// to the approved backend routes.
abstract interface class SyncTransport {
  /// Sends one outbox operation idempotently.
  Future<SyncSendOutcome> send(OutboxOperation operation);

  /// Pulls one delta page for [dataset].
  Future<Result<SyncPullPage>> pull(
    SyncDataset dataset, {
    String? cursor,
    int limit = 100,
  });
}

/// Resolves the single UI status from independent sync signals.
SyncStatus syncStatusFor({
  required int conflicts,
  required int needsAttention,
  required int pending,
  required bool syncing,
  required bool offline,
  required bool stale,
}) {
  if (conflicts > 0) return SyncStatus.conflict;
  if (needsAttention > 0) return SyncStatus.needsAttention;
  if (pending > 0) return SyncStatus.pending;
  if (syncing) return SyncStatus.syncing;
  if (offline) return SyncStatus.offline;
  if (stale) return SyncStatus.stale;
  return SyncStatus.online;
}
