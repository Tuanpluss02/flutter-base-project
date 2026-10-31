import 'dart:io';

import 'package:dio/dio.dart';
import 'package:pristie/src/core/error/app_failure.dart';

/// Maps [DioException] and transport failures to typed [AppFailure] instances.
final class AppFailureMapper {
  const AppFailureMapper._();

  /// Maps [exception] to a closed [AppFailure] domain variant.
  static AppFailure map(DioException exception) {
    if (exception.error is AppFailure) {
      return exception.error! as AppFailure;
    }

    if (exception.type == DioExceptionType.cancel) {
      return const AppFailure.cancelled();
    }

    if (exception.type == DioExceptionType.connectionTimeout ||
        exception.type == DioExceptionType.sendTimeout ||
        exception.type == DioExceptionType.receiveTimeout) {
      return const AppFailure.timeout();
    }

    if (exception.type == DioExceptionType.connectionError ||
        exception.error is SocketException) {
      return const AppFailure.network();
    }

    if (exception.error is FormatException || exception.error is TypeError) {
      return const AppFailure.parse();
    }

    final response = exception.response;
    if (response != null) {
      final statusCode = response.statusCode;
      if (statusCode != null) {
        if (statusCode == 401) {
          return const AppFailure.unauthorized();
        }
        if (statusCode == 403) {
          return const AppFailure.forbidden();
        }
        if (statusCode == 404) {
          return const AppFailure.notFound();
        }
        if (statusCode == 409 || statusCode == 412) {
          return const AppFailure.conflict();
        }
        if (statusCode == 413) {
          return const AppFailure.payloadTooLarge();
        }
        if (statusCode == 422) {
          final fields = _extractValidationIssues(response.data);
          return AppFailure.validation(fields);
        }
        if (statusCode == 400) {
          final fields = _extractValidationIssues(response.data);
          if (fields.isNotEmpty) {
            return AppFailure.validation(fields);
          }
          return const AppFailure.server(400);
        }
        if (statusCode == 429) {
          return AppFailure.rateLimit(_parseRetryAfter(response.headers));
        }
        if (statusCode >= 500 && statusCode <= 599) {
          return AppFailure.server(statusCode);
        }
      }
    }

    return const AppFailure.unknown();
  }

  static Duration? _parseRetryAfter(Headers headers) {
    final headerValue =
        headers.value('retry-after') ?? headers.value('Retry-After');
    if (headerValue == null || headerValue.trim().isEmpty) {
      return null;
    }
    final raw = headerValue.trim();
    final seconds = int.tryParse(raw);
    if (seconds != null) {
      return Duration(seconds: seconds < 0 ? 0 : seconds);
    }
    try {
      final date = HttpDate.parse(raw);
      final difference = date.difference(DateTime.now());
      return difference.isNegative ? Duration.zero : difference;
    } catch (_) {
      return null;
    }
  }

  static Map<String, ValidationIssue> _extractValidationIssues(dynamic data) {
    if (data is! Map) {
      return const {};
    }
    final map = data;
    Map<dynamic, dynamic>? targetDetails;

    if (map['error'] is Map && (map['error'] as Map)['details'] is Map) {
      targetDetails = (map['error'] as Map)['details'] as Map;
    } else if (map['details'] is Map) {
      targetDetails = map['details'] as Map;
    } else if (map['errors'] is Map) {
      targetDetails = map['errors'] as Map;
    } else if (map['fields'] is Map) {
      targetDetails = map['fields'] as Map;
    } else {
      final isPotentialDirectFieldMap = map.entries.any(
        (entry) =>
            entry.key != 'code' &&
            entry.key != 'message' &&
            entry.key != 'error' &&
            entry.key != 'trace_id' &&
            entry.key != 'status',
      );
      if (isPotentialDirectFieldMap) {
        targetDetails = map;
      }
    }

    if (targetDetails == null) {
      return const {};
    }

    final result = <String, ValidationIssue>{};
    for (final entry in targetDetails.entries) {
      final key = entry.key.toString();
      final value = entry.value;
      result[key] = _toValidationIssue(value);
    }
    return result;
  }

  static ValidationIssue _toValidationIssue(dynamic value) {
    if (value is ValidationIssue) {
      return value;
    }
    final text = value is List && value.isNotEmpty
        ? value.first.toString().toLowerCase()
        : value.toString().toLowerCase();

    if (text.contains('required') || text.contains('missing')) {
      return ValidationIssue.required;
    }
    if (text.contains('format') ||
        text.contains('invalid_format') ||
        text.contains('email') ||
        text.contains('regex')) {
      return ValidationIssue.invalidFormat;
    }
    if (text.contains('short') ||
        text.contains('min') ||
        text.contains('too_short')) {
      return ValidationIssue.tooShort;
    }
    if (text.contains('long') ||
        text.contains('max') ||
        text.contains('too_long')) {
      return ValidationIssue.tooLong;
    }
    if (text.contains('already_used') ||
        text.contains('unique') ||
        text.contains('conflict') ||
        text.contains('exists') ||
        text.contains('taken')) {
      return ValidationIssue.alreadyUsed;
    }
    return ValidationIssue.invalid;
  }
}
