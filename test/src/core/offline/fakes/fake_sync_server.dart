// ignore_for_file: prefer_initializing_formals

import 'package:base/src/core/error/app_failure.dart';
import 'package:base/src/core/offline/outbox/outbox_operation.dart';
import 'package:base/src/core/offline/sync/sync_conflict.dart';
import 'package:base/src/core/offline/sync/sync_dataset.dart';
import 'package:base/src/core/offline/sync/sync_send_outcome.dart';
import 'package:base/src/core/result/result.dart';

/// Handler invoked for one outbox mutation.
typedef FakeSendHandler = Future<SyncSendOutcome> Function(
  OutboxOperation operation,
  int attempt,
);

/// Handler invoked for one delta page.
typedef FakePullHandler = Future<Result<SyncPullPage>> Function(
  String? cursor,
  int pageIndex,
);

/// Deterministic in-process replacement for the sync HTTP contract.
///
/// It never opens a socket. Every scenario in the API contract is modelled as
/// a typed [SyncSendOutcome] or a [SyncPullPage] so tests can assert the client
/// state machine without inventing backend endpoints.
final class FakeSyncServer implements SyncTransport {
  FakeSyncServer({FakeSendHandler? sendHandler, FakePullHandler? pullHandler})
    : _sendHandler = sendHandler,
      _pullHandler = pullHandler;

  FakeSendHandler? _sendHandler;
  FakePullHandler? _pullHandler;

  /// Ordered call log containing `send` and `pull` entries.
  final List<String> calls = <String>[];

  /// Cursors received by pull requests, in call order.
  final List<String?> cursors = <String?>[];

  /// Idempotency keys received by send requests, in call order.
  final List<String> idempotencyKeys = <String>[];

  /// Number of send calls.
  int sendCount = 0;

  /// Number of pull calls.
  int pullCount = 0;

  /// Replaces the send handler between assertions when a test needs to change
  /// the server behaviour mid-cycle.
  set sendHandler(FakeSendHandler handler) => _sendHandler = handler;

  /// Replaces the pull handler between assertions.
  set pullHandler(FakePullHandler handler) => _pullHandler = handler;

  @override
  Future<SyncSendOutcome> send(OutboxOperation operation) async {
    calls.add('send');
    idempotencyKeys.add(operation.idempotencyKey);
    final handler = _sendHandler;
    final attempt = sendCount++;
    if (handler == null) return const SyncSendOutcome.synced();
    return handler(operation, attempt);
  }

  @override
  Future<Result<SyncPullPage>> pull(
    SyncDataset dataset, {
    String? cursor,
    int limit = 100,
  }) async {
    calls.add('pull');
    cursors.add(cursor);
    final handler = _pullHandler;
    final pageIndex = pullCount++;
    if (handler == null) {
      return Result.ok(SyncPullPage(nextCursor: cursor));
    }
    return handler(cursor, pageIndex);
  }
}

/// Maps an HTTP status/code pair to the typed outcome the transport adapter
/// must produce before the worker sees it.
SyncSendOutcome fakeOutcomeForStatus(
  int statusCode, {
  String? code,
  Duration? retryAfter,
  SyncConflict? conflict,
  bool methodIsDelete = false,
}) {
  switch (statusCode) {
    case 200:
    case 204:
      return const SyncSendOutcome.synced();
    case 401:
      return SyncSendOutcome.retryable(
        const AppFailure.unauthorized(),
        retryAfter,
      );
    case 403:
      return const SyncSendOutcome.needsAttention(AppFailure.forbidden());
    case 404:
      return methodIsDelete
          ? const SyncSendOutcome.synced()
          : const SyncSendOutcome.needsAttention(AppFailure.notFound());
    case 409:
      switch (code) {
        case 'REQUEST_IN_PROGRESS':
          return SyncSendOutcome.requestInProgress(retryAfter);
        case 'VERSION_MISMATCH':
          if (conflict == null) {
            return const SyncSendOutcome.needsAttention(AppFailure.server(409));
          }
          return SyncSendOutcome.versionConflict(conflict);
        default:
          return const SyncSendOutcome.needsAttention(AppFailure.server(409));
      }
    case 412:
      if (conflict == null) {
        return const SyncSendOutcome.needsAttention(AppFailure.server(412));
      }
      return SyncSendOutcome.versionConflict(conflict);
    case 422:
      return const SyncSendOutcome.needsAttention(
        AppFailure.validation(<String, ValidationIssue>{}),
      );
    case 429:
      return SyncSendOutcome.retryable(
        AppFailure.rateLimit(retryAfter),
        retryAfter,
      );
    default:
      if (statusCode >= 500) {
        return SyncSendOutcome.retryable(
          AppFailure.server(statusCode),
          retryAfter,
        );
      }
      return const SyncSendOutcome.needsAttention(AppFailure.unknown());
  }
}

/// Network failure scenario; no HTTP status exists for this case.
SyncSendOutcome fakeNetworkOutcome() =>
    const SyncSendOutcome.retryable(AppFailure.network(), null);
