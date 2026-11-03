import 'package:base/src/core/scope/data_scope.dart';

/// Tracks the active [DataScope] and fences work started under a previous one.
final class DataScopeStore {
  DataScope? _scope;
  int _epoch = 0;

  /// Currently active scope, or null when the database is closed.
  DataScope? get scope => _scope;

  /// Monotonic epoch incremented whenever the scope changes.
  int get epoch => _epoch;

  /// Switches to [scope] and advances the epoch on an actual change.
  void setScope(DataScope? scope) {
    if (_scope == scope) return;
    _scope = scope;
    _epoch++;
  }

  /// Returns true when [scope] and [epoch] still describe the active scope.
  bool isCurrent(DataScope scope, int epoch) =>
      _scope == scope && _epoch == epoch;
}
