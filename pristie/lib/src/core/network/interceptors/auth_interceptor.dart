import 'package:dio/dio.dart';
import 'package:pristie/src/core/auth/auth_coordinator.dart';
import 'package:pristie/src/core/auth/auth_session_controller.dart';
import 'package:pristie/src/core/config/app_config.dart';
import 'package:pristie/src/core/error/app_failure.dart';
import 'package:pristie/src/core/result/result.dart';
import 'package:pristie/src/core/storage/session.dart';
import 'package:pristie/src/core/storage/session_token_provider.dart';

/// Interceptor managing authorization headers, cross-origin protection, and 401 single-flight replay.
class AuthInterceptor extends Interceptor {
  /// Creates an [AuthInterceptor].
  AuthInterceptor({
    required this.config,
    required this.tokenProvider,
    required this.session,
    this.coordinator,
    this.dio,
  });

  /// Application configuration containing the trusted canonical API origin.
  final AppConfig config;

  /// Provider for reading persistent session records.
  final SessionTokenProvider tokenProvider;

  /// Controller managing authentication state and session epoch.
  final AuthSessionController session;

  /// Coordinator for single-flight token refresh.
  final AuthCoordinator? coordinator;

  /// Associated Dio client used for request replay.
  Dio? dio;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.extra['no_auth'] == true) {
      return handler.next(options);
    }

    final requestUri = options.uri;
    final baseUri = config.apiBaseUrl;
    final isSameOrigin = _isSameOrigin(requestUri, baseUri);
    final hasExplicitAuth = options.headers.containsKey('Authorization');

    final recordResult = await tokenProvider.readRecord();
    final hasActiveSession =
        recordResult is Ok<SessionRecord?> &&
        recordResult.data?.status == SessionStatus.active &&
        recordResult.data?.session != null;

    if (!isSameOrigin) {
      if (hasExplicitAuth || hasActiveSession) {
        return handler.reject(
          DioException(
            requestOptions: options,
            error: const AppFailure.forbidden(),
            type: DioExceptionType.badResponse,
          ),
          true,
        );
      }
      return handler.next(options);
    }

    options.extra['sessionEpoch'] = session.sessionEpoch;

    if (hasActiveSession) {
      final token = recordResult.data!.session!.accessToken;
      options.headers['Authorization'] = 'Bearer $token';
      options.followRedirects = false;
    }

    return handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode != 401 ||
        err.requestOptions.extra['no_auth'] == true ||
        coordinator == null) {
      return handler.next(err);
    }

    final options = err.requestOptions;
    final requestEpoch =
        options.extra['sessionEpoch'] as int? ?? session.sessionEpoch;
    final method = options.method.toUpperCase();
    final isGetOrHead = method == 'GET' || method == 'HEAD';

    final refreshResult = await coordinator!.ensureSession(requestEpoch);

    switch (refreshResult) {
      case Err(:final failure):
        return handler.reject(
          DioException(
            requestOptions: options,
            response: err.response,
            error: failure,
            type: DioExceptionType.badResponse,
          ),
        );
      case Ok(:final data):
        if (!isGetOrHead) {
          return handler.next(err);
        }

        final followUpUsed = options.extra['followUpUsed'] == true;
        if (followUpUsed) {
          return handler.next(err);
        }

        options.extra['followUpUsed'] = true;
        options.headers['Authorization'] = 'Bearer ${data.accessToken}';

        try {
          final targetDio = dio ?? Dio();
          final response = await targetDio.fetch(options);
          return handler.resolve(response);
        } on DioException catch (replayError) {
          return handler.next(replayError);
        } catch (e, st) {
          return handler.reject(
            DioException(requestOptions: options, error: e, stackTrace: st),
          );
        }
    }
  }

  static bool _isSameOrigin(Uri a, Uri b) {
    final aPort = a.hasPort ? a.port : (a.scheme == 'http' ? 80 : 443);
    final bPort = b.hasPort ? b.port : (b.scheme == 'http' ? 80 : 443);
    return a.scheme.toLowerCase() == b.scheme.toLowerCase() &&
        a.host.toLowerCase() == b.host.toLowerCase() &&
        aPort == bPort;
  }
}
