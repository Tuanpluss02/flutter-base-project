import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:base/src/app/network/api_token_refresher.dart';
import 'package:base/src/core/auth/auth_coordinator.dart';
import 'package:base/src/core/auth/auth_session_controller.dart';
import 'package:base/src/core/auth/session_service.dart';
import 'package:base/src/core/auth/session_state_sink.dart';
import 'package:base/src/core/config/app_config.dart';
import 'package:base/src/core/network/api_client.dart';
import 'package:base/src/core/network/dio_factory.dart';
import 'package:base/src/core/network/token_refresher.dart';
import 'package:base/src/core/observability/app_logger.dart';
import 'package:base/src/core/observability/crash_reporter.dart';
import 'package:base/src/core/storage/session_token_provider.dart';

@module
abstract class NetworkModule {
  @lazySingleton
  AppLogger appLogger(AppConfig config) =>
      AppLogger(enableDiagnostics: config.enableLogging);

  @lazySingleton
  CrashReporter get crashReporter => const NoopCrashReporter();

  @lazySingleton
  TokenRefresher tokenRefresher(AppConfig config) {
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
    return ApiTokenRefresher(dio: Dio(baseOptions));
  }

  @lazySingleton
  SessionService sessionService(SessionTokenProvider tokens) =>
      SessionService(tokens: tokens);

  @lazySingleton
  AuthSessionController authSessionController(SessionService service) =>
      service;

  @lazySingleton
  SessionStateSink sessionStateSink(SessionService service) => service;

  @lazySingleton
  AuthCoordinator authCoordinator(
    SessionTokenProvider tokens,
    AuthSessionController session,
    TokenRefresher refresher,
  ) => AuthCoordinator(tokens: tokens, session: session, refresher: refresher);

  @lazySingleton
  Dio dio(
    AppConfig config,
    SessionTokenProvider tokenProvider,
    AuthSessionController session,
    AuthCoordinator coordinator,
    AppLogger logger,
  ) => DioFactory.create(
    config: config,
    tokenProvider: tokenProvider,
    session: session,
    coordinator: coordinator,
    logger: logger,
  );

  @lazySingleton
  ApiClient apiClient(Dio dio) => ApiClient(dio);
}
