import 'package:freezed_annotation/freezed_annotation.dart';

import '../error/app_failure.dart';

part 'base_state.freezed.dart';

@freezed
sealed class BaseState<T> with _$BaseState<T> {
  const factory BaseState.initial() = Initial<T>;
  const factory BaseState.loading() = Loading<T>;
  const factory BaseState.data(T data) = Data<T>;
  const factory BaseState.error(AppFailure failure) = ErrorState<T>;
}
