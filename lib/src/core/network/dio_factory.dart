import 'dart:math';

import 'package:dio/dio.dart';
import 'package:base/src/core/auth/auth_coordinator.dart';
import 'package:base/src/core/auth/auth_session_controller.dart';
import 'package:base/src/core/config/app_config.dart';
import 'package:base/src/core/network/interceptors/auth_interceptor.dart';
import 'package:base/src/core/network/interceptors/error_mapping_interceptor.dart';
import 'package:base/src/core/network/interceptors/logging_interceptor.dart';
import 'package:base/src/core/network/interceptors/retry_interceptor.dart';
import 'package:base/src/core/network/token_refresher.dart';
import 'package:base/src/core/observability/app_logger.dart';
import 'package:base/src/core/storage/session_token_provider.dart';

/// Factory assembling resilient, interceptor-secured [Dio] HTTP clients.
final class DioFactory {
  const DioFactory._();

  /// Creates a configured [Dio] instance adhering to the architecture pipeline.
  static Dio create({
    required AppConfig config,
    required SessionTokenProvider tokenProvider,
    required AuthSessionController session,
    TokenRefresher? refresher,
    AuthCoordinator? coordinator,
    AppLogger? logger,
    List<Interceptor>? additionalInterceptors,
    HttpClientAdapter? httpClientAdapter,
    Random? retryRandom,
    DelayFunction? retryDelay,
  }) {
    final effectiveCoordinator =
        coordinator ??
        (refresher != null
            ? AuthCoordinator(
                tokens: tokenProvider,
                session: session,
                refresher: refresher,
              )
            : null);

    final baseOptions = BaseOptions(
      baseUrl: config.apiBaseUrl.toString(),
      connectTimeout: config.connectTimeout,
      sendTimeout: config.sendTimeout,
      receiveTimeout: config.receiveTimeout,
      contentType: Headers.jsonContentType,
      validateStatus: (statusCode) =>
          statusCode != null && statusCode >= 200 && statusCode < 300,
      receiveDataWhenStatusError: true,
    );

    final dio = Dio(baseOptions);
    if (httpClientAdapter != null) {
      dio.httpClientAdapter = httpClientAdapter;
    }

    final authInterceptor = AuthInterceptor(
      config: config,
      tokenProvider: tokenProvider,
      session: session,
      coordinator: effectiveCoordinator,
      dio: dio,
    );

    final loggingInterceptor = LoggingInterceptor(
      logger: logger ?? AppLogger(enableDiagnostics: config.enableLogging),
      enableLogging: config.enableLogging,
    );

    const errorMappingInterceptor = ErrorMappingInterceptor();

    final retryInterceptor = RetryInterceptor(
      dio: dio,
      random: retryRandom,
      delay: retryDelay ?? Future.delayed,
    );

    dio.interceptors.addAll(<Interceptor>[
      authInterceptor,
      loggingInterceptor,
      errorMappingInterceptor,
      retryInterceptor,
      ...?additionalInterceptors,
    ]);

    return dio;
  }
}
