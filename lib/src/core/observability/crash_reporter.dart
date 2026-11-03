import 'package:base/src/core/observability/redactor.dart';

/// Contract for dispatching uncaught exceptions and crashes to telemetry providers.
abstract interface class CrashReporter {
  /// Reports [error] and [stackTrace] with optional sanitized [context] metadata.
  Future<void> report(
    Object error,
    StackTrace stackTrace, {
    Map<String, Object?>? context,
  });
}

/// Default no-op crash reporter active in baseline v1 before privacy evaluations.
final class NoopCrashReporter implements CrashReporter {
  /// Creates a [NoopCrashReporter].
  const NoopCrashReporter();

  @override
  Future<void> report(
    Object error,
    StackTrace stackTrace, {
    Map<String, Object?>? context,
  }) async {
    if (context != null) {
      Redactor.redact(context);
    }
  }
}
