/// Feature flag for the Phase 2 offline module.
///
/// Offline storage is opt-in and disabled unless the app is built with
/// `--dart-define=OFFLINE_ENABLED=true`.
final class OfflineConfig {
  const OfflineConfig({
    this.enabled = const bool.fromEnvironment(
      'OFFLINE_ENABLED',
      defaultValue: false,
    ),
  });

  /// Whether the offline database may be opened.
  final bool enabled;
}
