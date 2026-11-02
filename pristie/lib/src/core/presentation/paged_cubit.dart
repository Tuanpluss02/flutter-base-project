import 'package:flutter_bloc/flutter_bloc.dart';

import '../error/app_failure.dart';
import '../result/result.dart';
import 'paged_state.dart';

class PagedCubit<T> extends Cubit<PagedState<T>> {
  PagedCubit({
    required PagedLoader<T> loadPage,
    required String Function(T) idOf,
  })  : _loadPage = loadPage,
        _idOf = idOf,
        super(PagedState<T>());

  final PagedLoader<T> _loadPage;
  final String Function(T) _idOf;
  int _generation = 0;

  Future<void> loadFirst() async {
    final generation = ++_generation;
    emit(
      state.copyWith(
        isLoadingFirst: true,
        isLoadingMore: false,
        loadFirstFailure: null,
        loadMoreFailure: null,
        hasMore: true,
      ),
    );

    final result = await _loadPage(1);
    if (isClosed || generation != _generation) return;

    switch (result) {
      case Ok<PagedPage<T>>(:final data):
        emit(
          state.copyWith(
            items: _dedupe(data.items),
            page: 1,
            hasMore: data.hasMore && data.items.isNotEmpty,
            isLoadingFirst: false,
            loadFirstFailure: null,
          ),
        );
      case Err<PagedPage<T>>(failure: CancelledFailure()):
        emit(state.copyWith(isLoadingFirst: false));
      case Err<PagedPage<T>>(:final failure):
        emit(state.copyWith(isLoadingFirst: false, loadFirstFailure: failure));
    }
  }

  Future<void> loadMore() async {
    if (isClosed ||
        state.isLoadingFirst ||
        state.isLoadingMore ||
        !state.hasMore) {
      return;
    }
    final generation = _generation;
    final requestedPage = state.page + 1;
    emit(state.copyWith(isLoadingMore: true, loadMoreFailure: null));

    final result = await _loadPage(requestedPage);
    if (isClosed || generation != _generation) return;

    switch (result) {
      case Ok<PagedPage<T>>(:final data):
        emit(
          state.copyWith(
            items: _dedupe([...state.items, ...data.items]),
            page: requestedPage,
            hasMore: data.hasMore && data.items.isNotEmpty,
            isLoadingMore: false,
            loadMoreFailure: null,
          ),
        );
      case Err<PagedPage<T>>(failure: CancelledFailure()):
        emit(state.copyWith(isLoadingMore: false));
      case Err<PagedPage<T>>(:final failure):
        emit(state.copyWith(isLoadingMore: false, loadMoreFailure: failure));
    }
  }

  Future<void> refresh() => loadFirst();

  List<T> _dedupe(Iterable<T> items) {
    final seen = <String>{};
    return items.where((item) => seen.add(_idOf(item))).toList(growable: false);
  }
}
