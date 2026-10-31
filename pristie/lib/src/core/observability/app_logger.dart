import 'package:logger/logger.dart';
import 'package:pristie/src/core/observability/redactor.dart';

/// Severity levels for application log entries.
enum AppLogLevel {
  /// Verbose diagnostic information for development.
  debug,

  /// General operational events.
  info,

  /// Potential issues or handled degraded conditions.
  warning,

  /// Unhandled or critical errors requiring investigation.
  error,
}

/// Callback signature for intercepting sanitized log outputs in tests and custom telemetry sinks.
typedef AppLogSink = void Function(
  AppLogLevel level,
  String event,
  Map<String, Object?> fields, {
  Object? error,
  StackTrace? stackTrace,
});

/// Production-hardened application logger wrapping [Logger] with deny-by-default redaction.
final class AppLogger {
  /// Creates an [AppLogger].
  ///
  /// When [enableDiagnostics] is `false` (e.g. in production), [debug] and [info] calls are no-ops,
  /// while [warning] and [error] are always processed through [Redactor.redact].
  AppLogger({required this.enableDiagnostics, Logger? logger, this.sink})
    : _logger = logger ?? Logger(printer: SimplePrinter(colors: false));

  /// Whether verbose diagnostic and info logs are active.
  final bool enableDiagnostics;

  /// Optional telemetry sink callback.
  final AppLogSink? sink;

  final Logger _logger;

  /// Logs a debug event when [enableDiagnostics] is enabled.
  void debug(String event, {Map<String, Object?>? fields}) {
    if (!enableDiagnostics) {
      return;
    }
    _dispatch(AppLogLevel.debug, event, fields);
  }

  /// Logs an operational event when [enableDiagnostics] is enabled.
  void info(String event, {Map<String, Object?>? fields}) {
    if (!enableDiagnostics) {
      return;
    }
    _dispatch(AppLogLevel.info, event, fields);
  }

  /// Logs a warning event through redaction across all environments.
  void warning(
    String event, {
    Map<String, Object?>? fields,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _dispatch(
      AppLogLevel.warning,
      event,
      fields,
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Logs an error event through redaction across all environments.
  void error(
    String event, {
    Map<String, Object?>? fields,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _dispatch(
      AppLogLevel.error,
      event,
      fields,
      error: error,
      stackTrace: stackTrace,
    );
  }

  void _dispatch(
    AppLogLevel level,
    String event,
    Map<String, Object?>? fields, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    final combined = <String, Object?>{'event': event, ...?fields};
    final redacted = Redactor.redact(combined);

    if (sink != null) {
      sink!(level, event, redacted, error: error, stackTrace: stackTrace);
      return;
    }

    final message = '$event: $redacted';
    switch (level) {
      case AppLogLevel.debug:
        _logger.d(message);
      case AppLogLevel.info:
        _logger.i(message);
      case AppLogLevel.warning:
        _logger.w(message, error: error, stackTrace: stackTrace);
      case AppLogLevel.error:
        _logger.e(message, error: error, stackTrace: stackTrace);
    }
  }
}
