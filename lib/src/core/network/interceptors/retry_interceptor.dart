import 'dart:io';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:base/src/core/error/app_failure.dart';

/// Signature for asynchronous delay function used during backoff.
typedef DelayFunction = Future<void> Function(Duration duration);

/// Interceptor applying a strict single-attempt retry budget with jitter for idempotent network failures.
class RetryInterceptor extends Interceptor {
  /// Creates a [RetryInterceptor].
  RetryInterceptor({this.dio, this.random, this.delay = Future.delayed});

  /// Associated Dio client used for issuing the retry attempt.
  Dio? dio;

  /// Injected random number generator for deterministic jitter in tests.
  final Random? random;

  /// Injected delay handler for fast asynchronous execution in tests.
  final DelayFunction delay;

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;
    final method = options.method.toUpperCase();
    final isGetOrHead = method == 'GET' || method == 'HEAD';

    if (!isGetOrHead) {
      return handler.next(err);
    }

    if (err.type == DioExceptionType.cancel || err.error is CancelledFailure) {
      return handler.next(err);
    }

    if (options.extra['followUpUsed'] == true) {
      return handler.next(err);
    }

    final isNetwork =
        err.type == DioExceptionType.connectionError ||
        err.error is NetworkFailure ||
        err.error is SocketException;
    final isTimeout =
        err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.error is TimeoutFailure;

    if (!isNetwork && !isTimeout) {
      return handler.next(err);
    }

    options.extra['followUpUsed'] = true;

    final rng = random ?? Random();
    final jitterMs = rng.nextInt(401) - 200;
    final duration = Duration(milliseconds: 1000 + jitterMs);

    await delay(duration);

    try {
      final targetDio = dio ?? Dio();
      final response = await targetDio.fetch(options);
      return handler.resolve(response);
    } on DioException catch (retryError) {
      return handler.next(retryError);
    } catch (e, st) {
      return handler.reject(
        DioException(requestOptions: options, error: e, stackTrace: st),
      );
    }
  }
}
