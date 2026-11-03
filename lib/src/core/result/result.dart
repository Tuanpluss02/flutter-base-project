import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:base/src/core/error/app_failure.dart';

part '../../../generated/src/core/result/result.freezed.dart';

/// Typed result container representing either success with [data] or failure with [failure].
@freezed
sealed class Result<T> with _$Result<T> {
  /// Successful computation producing [data].
  const factory Result.ok(T data) = Ok<T>;

  /// Failed computation producing [failure].
  const factory Result.err(AppFailure failure) = Err<T>;
}

/// Asynchronous result type alias.
typedef AsyncResult<T> = Future<Result<T>>;
