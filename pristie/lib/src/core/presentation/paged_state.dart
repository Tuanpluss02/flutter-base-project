import 'package:freezed_annotation/freezed_annotation.dart';

import '../error/app_failure.dart';
import '../result/result.dart';

part 'paged_state.freezed.dart';

@freezed
abstract class PagedState<T> with _$PagedState<T> {
  const factory PagedState({
    @Default([]) List<T> items,
    @Default(1) int page,
    @Default(true) bool hasMore,
    @Default(false) bool isLoadingFirst,
    @Default(false) bool isLoadingMore,
    AppFailure? loadFirstFailure,
    AppFailure? loadMoreFailure,
  }) = _PagedState<T>;
}

@freezed
abstract class PagedPage<T> with _$PagedPage<T> {
  const factory PagedPage({@Default([]) List<T> items, required bool hasMore}) =
      _PagedPage<T>;
}

typedef PagedLoader<T> = Future<Result<PagedPage<T>>> Function(int page);
