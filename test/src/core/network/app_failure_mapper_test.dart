import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:base/src/core/error/app_failure.dart';
import 'package:base/src/core/network/app_failure_mapper.dart';

void main() {
  group('AppFailureMapper', () {
    final defaultOptions = RequestOptions(path: '/test');

    test('maps connectionError and SocketException to network failure', () {
      final connectionErr = DioException(
        requestOptions: defaultOptions,
        type: DioExceptionType.connectionError,
        error: const SocketException('Connection refused'),
      );
      expect(AppFailureMapper.map(connectionErr), const AppFailure.network());

      final socketErr = DioException(
        requestOptions: defaultOptions,
        type: DioExceptionType.unknown,
        error: const SocketException('Failed host lookup'),
      );
      expect(AppFailureMapper.map(socketErr), const AppFailure.network());
    });

    test('maps connect, send, and receive timeouts to timeout failure', () {
      final connectTimeout = DioException(
        requestOptions: defaultOptions,
        type: DioExceptionType.connectionTimeout,
      );
      expect(AppFailureMapper.map(connectTimeout), const AppFailure.timeout());

      final sendTimeout = DioException(
        requestOptions: defaultOptions,
        type: DioExceptionType.sendTimeout,
      );
      expect(AppFailureMapper.map(sendTimeout), const AppFailure.timeout());

      final receiveTimeout = DioException(
        requestOptions: defaultOptions,
        type: DioExceptionType.receiveTimeout,
      );
      expect(AppFailureMapper.map(receiveTimeout), const AppFailure.timeout());
    });

    test('maps cancel type to cancelled failure', () {
      final cancelErr = DioException(
        requestOptions: defaultOptions,
        type: DioExceptionType.cancel,
      );
      expect(AppFailureMapper.map(cancelErr), const AppFailure.cancelled());
    });

    test('maps 401 to unauthorized failure', () {
      final unauthorizedErr = DioException(
        requestOptions: defaultOptions,
        response: Response<dynamic>(
          requestOptions: defaultOptions,
          statusCode: 401,
        ),
      );
      expect(
        AppFailureMapper.map(unauthorizedErr),
        const AppFailure.unauthorized(),
      );
    });

    test('maps 403 to forbidden failure', () {
      final forbiddenErr = DioException(
        requestOptions: defaultOptions,
        response: Response<dynamic>(
          requestOptions: defaultOptions,
          statusCode: 403,
        ),
      );
      expect(AppFailureMapper.map(forbiddenErr), const AppFailure.forbidden());
    });

    test('maps 404 to notFound failure', () {
      final notFoundErr = DioException(
        requestOptions: defaultOptions,
        response: Response<dynamic>(
          requestOptions: defaultOptions,
          statusCode: 404,
        ),
      );
      expect(AppFailureMapper.map(notFoundErr), const AppFailure.notFound());
    });

    test('maps 409 and 412 to conflict failure', () {
      final conflict409 = DioException(
        requestOptions: defaultOptions,
        response: Response<dynamic>(
          requestOptions: defaultOptions,
          statusCode: 409,
        ),
      );
      expect(AppFailureMapper.map(conflict409), const AppFailure.conflict());

      final conflict412 = DioException(
        requestOptions: defaultOptions,
        response: Response<dynamic>(
          requestOptions: defaultOptions,
          statusCode: 412,
        ),
      );
      expect(AppFailureMapper.map(conflict412), const AppFailure.conflict());
    });

    test('maps 413 to payloadTooLarge failure', () {
      final payloadTooLarge = DioException(
        requestOptions: defaultOptions,
        response: Response<dynamic>(
          requestOptions: defaultOptions,
          statusCode: 413,
        ),
      );
      expect(
        AppFailureMapper.map(payloadTooLarge),
        const AppFailure.payloadTooLarge(),
      );
    });

    test('maps 422 with details to validation failure with typed issues', () {
      final validationErr = DioException(
        requestOptions: defaultOptions,
        response: Response<dynamic>(
          requestOptions: defaultOptions,
          statusCode: 422,
          data: <String, dynamic>{
            'error': <String, dynamic>{
              'details': <String, dynamic>{
                'email': 'invalid_format',
                'password': 'too_short',
                'name': 'required',
                'username': 'already_used',
                'bio': 'too_long',
                'role': 'unknown_value',
              },
            },
          },
        ),
      );

      final failure = AppFailureMapper.map(validationErr);
      expect(failure, isA<ValidationFailure>());
      final fields = (failure as ValidationFailure).fields;
      expect(fields['email'], ValidationIssue.invalidFormat);
      expect(fields['password'], ValidationIssue.tooShort);
      expect(fields['name'], ValidationIssue.required);
      expect(fields['username'], ValidationIssue.alreadyUsed);
      expect(fields['bio'], ValidationIssue.tooLong);
      expect(fields['role'], ValidationIssue.invalid);
    });

    test('maps 400 with details to validation failure', () {
      final badRequestWithFields = DioException(
        requestOptions: defaultOptions,
        response: Response<dynamic>(
          requestOptions: defaultOptions,
          statusCode: 400,
          data: <String, dynamic>{
            'details': <String, dynamic>{'email': 'missing email'},
          },
        ),
      );

      final failure = AppFailureMapper.map(badRequestWithFields);
      expect(failure, isA<ValidationFailure>());
      expect(
        (failure as ValidationFailure).fields['email'],
        ValidationIssue.required,
      );
    });

    test('maps 400 without recognized details to server(400)', () {
      final badRequestNoFields = DioException(
        requestOptions: defaultOptions,
        response: Response<dynamic>(
          requestOptions: defaultOptions,
          statusCode: 400,
          data: <String, dynamic>{'message': 'Malformed syntax'},
        ),
      );

      expect(
        AppFailureMapper.map(badRequestNoFields),
        const AppFailure.server(400),
      );
    });

    test('maps 429 with integer seconds Retry-After', () {
      final rateLimitInt = DioException(
        requestOptions: defaultOptions,
        response: Response<dynamic>(
          requestOptions: defaultOptions,
          statusCode: 429,
          headers: Headers.fromMap(<String, List<String>>{
            'retry-after': <String>['30'],
          }),
        ),
      );

      final failure = AppFailureMapper.map(rateLimitInt);
      expect(failure, const AppFailure.rateLimit(Duration(seconds: 30)));
    });

    test('maps 429 with HTTP Date Retry-After', () {
      final futureDate = DateTime.now().add(const Duration(seconds: 60));
      final httpDateStr = HttpDate.format(futureDate);

      final rateLimitDate = DioException(
        requestOptions: defaultOptions,
        response: Response<dynamic>(
          requestOptions: defaultOptions,
          statusCode: 429,
          headers: Headers.fromMap(<String, List<String>>{
            'Retry-After': <String>[httpDateStr],
          }),
        ),
      );

      final failure = AppFailureMapper.map(rateLimitDate);
      expect(failure, isA<RateLimitFailure>());
      final duration = (failure as RateLimitFailure).retryAfter;
      expect(duration, isNotNull);
      expect(duration!.inSeconds, greaterThanOrEqualTo(50));
      expect(duration.inSeconds, lessThanOrEqualTo(65));
    });

    test('maps 429 without header to rateLimit(null)', () {
      final rateLimitNoHeader = DioException(
        requestOptions: defaultOptions,
        response: Response<dynamic>(
          requestOptions: defaultOptions,
          statusCode: 429,
        ),
      );

      expect(
        AppFailureMapper.map(rateLimitNoHeader),
        const AppFailure.rateLimit(null),
      );
    });

    test('maps 5xx status codes to server(statusCode)', () {
      final server500 = DioException(
        requestOptions: defaultOptions,
        response: Response<dynamic>(
          requestOptions: defaultOptions,
          statusCode: 500,
        ),
      );
      expect(AppFailureMapper.map(server500), const AppFailure.server(500));

      final server503 = DioException(
        requestOptions: defaultOptions,
        response: Response<dynamic>(
          requestOptions: defaultOptions,
          statusCode: 503,
        ),
      );
      expect(AppFailureMapper.map(server503), const AppFailure.server(503));
    });

    test('maps FormatException and TypeError to parse failure', () {
      final formatErr = DioException(
        requestOptions: defaultOptions,
        error: const FormatException('Invalid JSON'),
      );
      expect(AppFailureMapper.map(formatErr), const AppFailure.parse());
    });

    test('returns existing AppFailure if already attached', () {
      final existingErr = DioException(
        requestOptions: defaultOptions,
        error: const AppFailure.forbidden(),
      );
      expect(AppFailureMapper.map(existingErr), const AppFailure.forbidden());
    });
  });
}
