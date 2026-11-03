import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:base/src/core/auth/auth_coordinator.dart';
import 'package:base/src/core/auth/session_service.dart';
import 'package:base/src/core/config/app_config.dart';
import 'package:base/src/core/error/app_failure.dart';
import 'package:base/src/core/network/dio_factory.dart';
import 'package:base/src/core/network/token_refresher.dart';
import 'package:base/src/core/observability/app_logger.dart';
import 'package:base/src/core/result/result.dart';
import 'package:base/src/core/storage/secure_session_store.dart';
import 'package:base/src/core/storage/session.dart';

import '../storage/fakes/in_memory_secure_storage.dart';

class MockHttpClientAdapter implements HttpClientAdapter {
  final List<RequestOptions> recordedRequests = <RequestOptions>[];
  ResponseBody Function(RequestOptions options)? handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    recordedRequests.add(options);
    if (handler != null) {
      return handler!(options);
    }
    if (cancelFuture != null) {
      final completer = Completer<ResponseBody>();
      cancelFuture.then((_) {
        if (!completer.isCompleted) {
          completer.completeError(
            DioException(
              requestOptions: options,
              type: DioExceptionType.cancel,
              error: 'User navigated away',
            ),
          );
        }
      });
      return completer.future;
    }
    return ResponseBody.fromString(
      jsonEncode(<String, dynamic>{'status': 'ok'}),
      200,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>[Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class FakeRefresher implements TokenRefresher {
  int refreshCount = 0;
  Session? sessionToReturn;
  Result<Session>? nextResult;

  @override
  Future<Result<Session>> refresh(String refreshToken) async {
    refreshCount++;
    return nextResult ??
        Result.ok(
          sessionToReturn ??
              Session(
                accessToken: 'refreshed_access_$refreshCount',
                refreshToken: 'refreshed_refresh_$refreshCount',
                tokenType: 'Bearer',
                expiresAt: DateTime.utc(2026, 12, 31),
              ),
        );
  }
}

void main() {
  group('Dio pipeline, Retry, Auth, and Cancellation', () {
    late AppConfig devConfig;
    late InMemorySecureStorage storage;
    late SecureSessionStore tokens;
    late SessionService sessionService;
    late FakeRefresher refresher;
    late AuthCoordinator coordinator;
    late MockHttpClientAdapter adapter;
    late List<Map<String, Object?>> capturedLogEntries;
    late AppLogger logger;

    final testSession = Session(
      accessToken: 'initial_access_token',
      refreshToken: 'initial_refresh_token',
      tokenType: 'Bearer',
      expiresAt: DateTime.utc(2026, 12, 31),
    );

    setUp(() async {
      devConfig = AppConfig(
        environment: AppEnvironment.dev,
        apiBaseUrl: Uri.parse('https://api.dev.base.example'),
        appName: 'Base Dev',
        enableLogging: true,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
      );

      storage = InMemorySecureStorage();
      tokens = SecureSessionStore(secureStorage: storage);
      sessionService = SessionService(tokens: tokens);
      refresher = FakeRefresher();
      coordinator = AuthCoordinator(
        tokens: tokens,
        session: sessionService,
        refresher: refresher,
      );
      adapter = MockHttpClientAdapter();
      capturedLogEntries = <Map<String, Object?>>[];

      logger = AppLogger(
        enableDiagnostics: true,
        sink: (level, event, fields, {error, stackTrace}) {
          capturedLogEntries.add(<String, Object?>{
            'level': level,
            'event': event,
            ...fields,
          });
        },
      );

      await sessionService.login(testSession);
    });

    tearDown(() async {
      await sessionService.dispose();
    });

    test(
      'attaches Bearer token and disables followRedirects on same origin',
      () async {
        final dio = DioFactory.create(
          config: devConfig,
          tokenProvider: tokens,
          session: sessionService,
          coordinator: coordinator,
          logger: logger,
          httpClientAdapter: adapter,
        );

        await dio.get<dynamic>('/api/v1/items');

        expect(adapter.recordedRequests, hasLength(1));
        final recorded = adapter.recordedRequests.first;
        expect(
          recorded.headers['Authorization'],
          'Bearer initial_access_token',
        );
        expect(recorded.followRedirects, isFalse);
      },
    );

    test('cross-origin request with credentials throws forbidden before transmission', () async {
      final dio = DioFactory.create(
        config: devConfig,
        tokenProvider: tokens,
        session: sessionService,
        coordinator: coordinator,
        logger: logger,
        httpClientAdapter: adapter,
      );

      expect(
        () => dio.get<dynamic>('https://malicious.example.com/steal'),
        throwsA(
          isA<DioException>().having(
            (e) => e.error,
            'error',
            const AppFailure.forbidden(),
          ),
        ),
      );
      expect(adapter.recordedRequests, isEmpty);
    });

    test(
      'cross-origin public request with no_auth: true succeeds without token',
      () async {
        final dio = DioFactory.create(
          config: devConfig,
          tokenProvider: tokens,
          session: sessionService,
          coordinator: coordinator,
          logger: logger,
          httpClientAdapter: adapter,
        );

        await dio.get<dynamic>(
          'https://cdn.example.com/public.json',
          options: Options(extra: <String, Object>{'no_auth': true}),
        );

        expect(adapter.recordedRequests, hasLength(1));
        final recorded = adapter.recordedRequests.first;
        expect(recorded.headers.containsKey('Authorization'), isFalse);
      },
    );

    test('logging records method, routeTemplate, statusCode, durationMs, and correlationId without body or headers', () async {
      final dio = DioFactory.create(
        config: devConfig,
        tokenProvider: tokens,
        session: sessionService,
        coordinator: coordinator,
        logger: logger,
        httpClientAdapter: adapter,
      );

      await dio.get<dynamic>(
        '/api/v1/items?filter=secret_filter',
        options: Options(
          extra: <String, Object>{'routeTemplate': '/api/v1/items'},
          headers: <String, Object>{'X-Secret-Header': 'super_sensitive'},
        ),
      );

      expect(capturedLogEntries, isNotEmpty);
      final logEntry = capturedLogEntries.first;

      expect(logEntry['method'], 'GET');
      expect(logEntry['routeTemplate'], '/api/v1/items');
      expect(logEntry['statusCode'], 200);
      expect(logEntry['durationMs'], isA<int>());
      expect(logEntry['correlationId'], isNotNull);

      expect(logEntry.containsKey('headers'), isFalse);
      expect(logEntry.containsKey('X-Secret-Header'), isFalse);
      expect(logEntry.containsKey('filter'), isFalse);
      expect(logEntry.containsKey('body'), isFalse);
      expect(logEntry.containsKey('path'), isFalse);
    });

    test('logging defaults to unknown_route when routeTemplate is missing from extra', () async {
      final dio = DioFactory.create(
        config: devConfig,
        tokenProvider: tokens,
        session: sessionService,
        coordinator: coordinator,
        logger: logger,
        httpClientAdapter: adapter,
      );

      await dio.get<dynamic>('/api/v1/items');

      expect(capturedLogEntries, isNotEmpty);
      final logEntry = capturedLogEntries.first;
      expect(logEntry['routeTemplate'], 'unknown_route');
    });

    test(
      'retries GET on network error exactly once with jitter backoff',
      () async {
        var callCount = 0;
        var delayCalled = false;
        Duration? capturedDelay;

        adapter.handler = (opts) {
          callCount++;
          if (callCount == 1) {
            throw DioException.connectionError(
              requestOptions: opts,
              reason: 'Connection dropped',
            );
          }
          return ResponseBody.fromString(
            jsonEncode(<String, dynamic>{'status': 'recovered'}),
            200,
            headers: <String, List<String>>{
              Headers.contentTypeHeader: <String>[Headers.jsonContentType],
            },
          );
        };

        final dio = DioFactory.create(
          config: devConfig,
          tokenProvider: tokens,
          session: sessionService,
          coordinator: coordinator,
          logger: logger,
          httpClientAdapter: adapter,
          retryRandom: Random(42),
          retryDelay: (d) async {
            delayCalled = true;
            capturedDelay = d;
          },
        );

        final response = await dio.get<dynamic>('/api/v1/items');

        expect(callCount, 2);
        expect(delayCalled, isTrue);
        expect(capturedDelay!.inMilliseconds, greaterThanOrEqualTo(800));
        expect(capturedDelay!.inMilliseconds, lessThanOrEqualTo(1200));
        expect(response.statusCode, 200);
      },
    );

    test('does not retry when followUpUsed is already true', () async {
      var callCount = 0;

      adapter.handler = (opts) {
        callCount++;
        throw DioException.connectionError(
          requestOptions: opts,
          reason: 'Network dead',
        );
      };

      final dio = DioFactory.create(
        config: devConfig,
        tokenProvider: tokens,
        session: sessionService,
        coordinator: coordinator,
        logger: logger,
        httpClientAdapter: adapter,
        retryDelay: (_) async {},
      );

      await expectLater(
        dio.get<dynamic>('/api/v1/items'),
        throwsA(
          isA<DioException>().having(
            (e) => e.error,
            'error',
            const AppFailure.network(),
          ),
        ),
      );

      expect(callCount, 2);
    });

    test('does not retry mutation methods (POST, PUT, DELETE)', () async {
      var callCount = 0;

      adapter.handler = (opts) {
        callCount++;
        throw DioException.connectionError(
          requestOptions: opts,
          reason: 'Network glitch',
        );
      };

      final dio = DioFactory.create(
        config: devConfig,
        tokenProvider: tokens,
        session: sessionService,
        coordinator: coordinator,
        logger: logger,
        httpClientAdapter: adapter,
        retryDelay: (_) async {},
      );

      await expectLater(
        dio.post<dynamic>('/api/v1/items', data: <String, dynamic>{'a': 1}),
        throwsA(
          isA<DioException>().having(
            (e) => e.error,
            'error',
            const AppFailure.network(),
          ),
        ),
      );

      expect(callCount, 1);
    });

    test(
      'does not retry 4xx or 5xx server errors at transport layer',
      () async {
        var callCount = 0;

        adapter.handler = (opts) {
          callCount++;
          return ResponseBody.fromString(
            jsonEncode(<String, dynamic>{'error': 'Internal Server Error'}),
            500,
            headers: <String, List<String>>{
              Headers.contentTypeHeader: <String>[Headers.jsonContentType],
            },
          );
        };

        final dio = DioFactory.create(
          config: devConfig,
          tokenProvider: tokens,
          session: sessionService,
          coordinator: coordinator,
          logger: logger,
          httpClientAdapter: adapter,
          retryDelay: (_) async {},
        );

        await expectLater(
          dio.get<dynamic>('/api/v1/items'),
          throwsA(
            isA<DioException>().having(
              (e) => e.error,
              'error',
              const AppFailure.server(500),
            ),
          ),
        );

        expect(callCount, 1);
      },
    );

    test(
      'GET 401 triggers token refresh and replays with new token once',
      () async {
        var callCount = 0;

        adapter.handler = (opts) {
          callCount++;
          if (callCount == 1) {
            return ResponseBody.fromString(
              jsonEncode(<String, dynamic>{'error': 'Unauthorized'}),
              401,
              headers: <String, List<String>>{
                Headers.contentTypeHeader: <String>[Headers.jsonContentType],
              },
            );
          }
          return ResponseBody.fromString(
            jsonEncode(<String, dynamic>{'data': 'replayed_success'}),
            200,
            headers: <String, List<String>>{
              Headers.contentTypeHeader: <String>[Headers.jsonContentType],
            },
          );
        };

        final dio = DioFactory.create(
          config: devConfig,
          tokenProvider: tokens,
          session: sessionService,
          coordinator: coordinator,
          logger: logger,
          httpClientAdapter: adapter,
        );

        final response = await dio.get<dynamic>('/api/v1/items');

        expect(callCount, 2);
        expect(refresher.refreshCount, 1);
        expect(response.statusCode, 200);

        final secondRequest = adapter.recordedRequests.last;
        expect(
          secondRequest.headers['Authorization'],
          'Bearer refreshed_access_1',
        );
        expect(secondRequest.extra['followUpUsed'], isTrue);
      },
    );

    test('mutation 401 triggers refresh but does not replay and returns unauthorized', () async {
      var callCount = 0;

      adapter.handler = (opts) {
        callCount++;
        return ResponseBody.fromString(
          jsonEncode(<String, dynamic>{'error': 'Unauthorized'}),
          401,
          headers: <String, List<String>>{
            Headers.contentTypeHeader: <String>[Headers.jsonContentType],
          },
        );
      };

      final dio = DioFactory.create(
        config: devConfig,
        tokenProvider: tokens,
        session: sessionService,
        coordinator: coordinator,
        logger: logger,
        httpClientAdapter: adapter,
      );

      await expectLater(
        dio.post<dynamic>(
          '/api/v1/items',
          data: <String, dynamic>{'title': 'New Item'},
        ),
        throwsA(
          isA<DioException>().having(
            (e) => e.error,
            'error',
            const AppFailure.unauthorized(),
          ),
        ),
      );

      expect(callCount, 1);
      expect(refresher.refreshCount, 1);
    });

    test('in-flight cancellation maps to AppFailure.cancelled()', () async {
      final cancelToken = CancelToken();

      final dio = DioFactory.create(
        config: devConfig,
        tokenProvider: tokens,
        session: sessionService,
        coordinator: coordinator,
        logger: logger,
        httpClientAdapter: adapter,
      );

      final future = dio.get<dynamic>(
        '/api/v1/items',
        cancelToken: cancelToken,
      );
      await pumpEventQueue();
      cancelToken.cancel('User navigated away');

      await expectLater(
        future,
        throwsA(
          isA<DioException>().having(
            (e) => e.error,
            'error',
            const AppFailure.cancelled(),
          ),
        ),
      );
    });
  });
}
