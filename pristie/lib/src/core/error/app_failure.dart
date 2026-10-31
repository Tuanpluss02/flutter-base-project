import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_failure.freezed.dart';

@freezed
sealed class AppFailure with _$AppFailure {
  const factory AppFailure.network() = NetworkFailure;
  const factory AppFailure.timeout() = TimeoutFailure;
  const factory AppFailure.cancelled() = CancelledFailure;
  const factory AppFailure.unauthorized() = UnauthorizedFailure;
  const factory AppFailure.forbidden() = ForbiddenFailure;
  const factory AppFailure.notFound() = NotFoundFailure;
  const factory AppFailure.conflict() = ConflictFailure;
  const factory AppFailure.validation(Map<String, ValidationIssue> fields) =
      ValidationFailure;
  const factory AppFailure.rateLimit(Duration? retryAfter) = RateLimitFailure;
  const factory AppFailure.server(int? statusCode) = ServerFailure;
  const factory AppFailure.payloadTooLarge() = PayloadTooLargeFailure;
  const factory AppFailure.parse() = ParseFailure;
  const factory AppFailure.localPersistence() = LocalPersistenceFailure;
  const factory AppFailure.unknown() = UnknownFailure;
}

enum ValidationIssue {
  required,
  invalidFormat,
  tooShort,
  tooLong,
  alreadyUsed,
  invalid,
}
