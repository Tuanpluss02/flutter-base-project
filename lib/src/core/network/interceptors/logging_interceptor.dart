import 'package:dio/dio.dart';
import 'package:base/src/core/observability/app_logger.dart';
import 'package:uuid/uuid.dart';

/// Interceptor recording request performance and response status without logging payloads or credentials.
class LoggingInterceptor extends Interceptor {
  /// Creates a [LoggingInterceptor].
  LoggingInterceptor({required this.logger, this.enableLogging = true});

  /// Application logger receiving redacted diagnostic events.
  final AppLogger logger;

  /// Whether diagnostic info logging is enabled.
  final bool enableLogging;

  static const Uuid _uuid = Uuid();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final correlationId =
        options.extra['correlationId'] as String? ?? _uuid.v4();
    options.extra['correlationId'] = correlationId;
    options.extra['startTime'] = DateTime.now().millisecondsSinceEpoch;
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    final options = response.requestOptions;
    final startTime = options.extra['startTime'] as int?;
    final durationMs = startTime != null
        ? DateTime.now().millisecondsSinceEpoch - startTime
        : 0;
    final routeTemplate =
        options.extra['routeTemplate'] as String? ?? 'unknown_route';
    final correlationId = options.extra['correlationId'] as String?;
    final statusCode = response.statusCode;
    final method = options.method.toUpperCase();

    if (enableLogging) {
      logger.info(
        'http_response',
        fields: <String, Object?>{
          'method': method,
          'routeTemplate': routeTemplate,
          'statusCode': ?statusCode,
          'durationMs': durationMs,
          'correlationId': ?correlationId,
        },
      );
    }

    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final options = err.requestOptions;
    final startTime = options.extra['startTime'] as int?;
    final durationMs = startTime != null
        ? DateTime.now().millisecondsSinceEpoch - startTime
        : 0;
    final routeTemplate =
        options.extra['routeTemplate'] as String? ?? 'unknown_route';
    final correlationId = options.extra['correlationId'] as String?;
    final statusCode = err.response?.statusCode;
    final method = options.method.toUpperCase();

    final event = (statusCode != null && statusCode >= 500)
        ? 'http_error'
        : 'http_warning';

    logger.warning(
      event,
      fields: <String, Object?>{
        'method': method,
        'routeTemplate': routeTemplate,
        'statusCode': ?statusCode,
        'durationMs': durationMs,
        'correlationId': ?correlationId,
      },
    );

    handler.next(err);
  }
}
