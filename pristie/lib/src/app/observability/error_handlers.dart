import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pristie/src/core/error/app_failure.dart';
import 'package:pristie/src/core/observability/crash_reporter.dart';

/// Installs top-level error boundaries routing uncaught exceptions to [reporter].
void installErrorHandlers(CrashReporter reporter) {
  FlutterError.onError = (FlutterErrorDetails details) {
    if (_isCancellation(details.exception)) {
      return;
    }
    FlutterError.presentError(details);
    reporter.report(
      details.exception,
      details.stack ?? StackTrace.current,
      context: const {'stage': 'flutter_error'},
    );
  };

  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    if (_isCancellation(error)) {
      return true;
    }
    reporter.report(error, stack, context: const {'stage': 'platform_error'});
    return true;
  };
}

bool _isCancellation(Object error) {
  if (error is CancelledFailure) {
    return true;
  }
  if (error is AppFailure && error is CancelledFailure) {
    return true;
  }
  if (error is DioException && error.type == DioExceptionType.cancel) {
    return true;
  }
  return false;
}
