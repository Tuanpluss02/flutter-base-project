import 'package:freezed_annotation/freezed_annotation.dart';

import '../error/app_failure.dart';

part 'result.freezed.dart';

@freezed
sealed class Result<T> with _$Result<T> {
  const factory Result.ok(T data) = Ok<T>;
  const factory Result.err(AppFailure failure) = Err<T>;
}

typedef AsyncResult<T> = Future<Result<T>>;
