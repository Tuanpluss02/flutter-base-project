import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_failure.freezed.dart';

/// Closed failure hierarchy representing all domain and infrastructure failures.
@freezed
sealed class AppFailure with _$AppFailure {
  /// Network connectivity failure.
  const factory AppFailure.network() = NetworkFailure;

  /// Network or gateway timeout.
  const factory AppFailure.timeout() = TimeoutFailure;

  /// Request or operation was cancelled.
  const factory AppFailure.cancelled() = CancelledFailure;

  /// Unauthenticated or session expired.
  const factory AppFailure.unauthorized() = UnauthorizedFailure;

  /// Access forbidden.
  const factory AppFailure.forbidden() = ForbiddenFailure;

  /// Requested resource was not found.
  const factory AppFailure.notFound() = NotFoundFailure;

  /// State conflict or optimistic concurrency violation.
  const factory AppFailure.conflict() = ConflictFailure;

  /// Validation failure with field-specific issues.
  const factory AppFailure.validation(Map<String, ValidationIssue> fields) =
      ValidationFailure;

  /// Rate limit exceeded with optional retry duration.
  const factory AppFailure.rateLimit(Duration? retryAfter) = RateLimitFailure;

  /// Server-side error.
  const factory AppFailure.server(int? statusCode) = ServerFailure;

  /// Request payload exceeds configured limits.
  const factory AppFailure.payloadTooLarge() = PayloadTooLargeFailure;

  /// Response body could not be parsed.
  const factory AppFailure.parse() = ParseFailure;

  /// Local database or secure storage operation failed.
  const factory AppFailure.localPersistence() = LocalPersistenceFailure;

  /// Unclassified or unexpected failure.
  const factory AppFailure.unknown() = UnknownFailure;
}

/// Validation issue types for fields.
enum ValidationIssue {
  /// Field is required but missing.
  required,

  /// Field format is invalid.
  invalidFormat,

  /// Field length is too short.
  tooShort,

  /// Field length is too long.
  tooLong,

  /// Value is already in use.
  alreadyUsed,

  /// General invalid value.
  invalid,
}
