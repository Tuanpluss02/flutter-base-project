/// Durable description of a version conflict between a local overlay and the
/// server record.
///
/// This type is intentionally separate from `AppFailure.conflict()`: a sync
/// conflict carries payloads that must survive a restart, while the generic
/// failure is only a transport-level signal for online-only flows.
final class SyncConflict {
  const SyncConflict({
    required this.localOverlay,
    required this.remoteSnapshot,
    required this.baseVersion,
    required this.serverVersion,
  });

  /// Local pending overlay that was rejected by optimistic concurrency.
  final Object? localOverlay;

  /// Latest server record returned with `VERSION_MISMATCH`/412, or resolved by
  /// a feature GET resolver.
  final Object? remoteSnapshot;

  /// Server version the local mutation was based on.
  final String? baseVersion;

  /// Current server version at the time of the conflict.
  final String? serverVersion;
}
