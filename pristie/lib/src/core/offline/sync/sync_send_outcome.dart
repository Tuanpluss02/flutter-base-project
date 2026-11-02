import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:pristie/src/core/error/app_failure.dart';

import 'sync_conflict.dart';

part 'sync_send_outcome.freezed.dart';

/// Typed result of sending one outbox operation.
///
/// The outbox worker consumes this instead of raw `AppFailure` values so that
/// in-flight idempotent requests and durable version conflicts cannot be
/// confused with transport failures.
@freezed
sealed class SyncSendOutcome with _$SyncSendOutcome {
  /// The server accepted the operation.
  const factory SyncSendOutcome.synced({
    String? serverVersion,
    Map<String, Object?>? serverRecord,
  }) = SyncSent;

  /// A transient failure that should be retried with backoff.
  const factory SyncSendOutcome.retryable(
    AppFailure failure,
    Duration? retryAfter,
  ) = SyncRetryable;

  /// Another request with the same idempotency key is still in flight.
  const factory SyncSendOutcome.requestInProgress([Duration? retryAfter]) =
      SyncRequestInProgress;

  /// The server rejected an optimistic concurrency check and supplied a
  /// snapshot or the feature resolved one.
  const factory SyncSendOutcome.versionConflict(SyncConflict conflict) =
      SyncVersionConflict;

  /// The operation needs user or feature attention before retrying.
  const factory SyncSendOutcome.needsAttention(AppFailure failure) =
      SyncNeedsAttention;
}
