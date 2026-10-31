import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:pristie/src/core/error/app_failure.dart';
import 'package:pristie/src/core/presentation/paged_cubit.dart';
import 'package:pristie/src/core/presentation/paged_state.dart';
import 'package:pristie/src/core/result/result.dart';

void main() {
  group('PagedCubit', () {
    test('loads first page and deduplicates subsequent pages', () async {
      final cubit = PagedCubit<int>(
        loadPage: (page) async => Result.ok(
          PagedPage<int>(items: page == 1 ? [1, 2] : [2, 3], hasMore: true),
        ),
        idOf: (item) => '$item',
      );

      await cubit.loadFirst();
      expect(cubit.state.items, [1, 2]);
      expect(cubit.state.page, 1);
      expect(cubit.state.hasMore, isTrue);

      await cubit.loadMore();
      expect(cubit.state.items, [1, 2, 3]);
      expect(cubit.state.page, 2);
      await cubit.close();
    });

    test('load more failure retains items and clears loading flag', () async {
      final cubit = PagedCubit<int>(
        loadPage: (page) async => page == 1
            ? const Result.ok(PagedPage<int>(items: [1], hasMore: true))
            : const Result.err(AppFailure.server(500)),
        idOf: (item) => '$item',
      );

      await cubit.loadFirst();
      await cubit.loadMore();

      expect(cubit.state.items, [1]);
      expect(cubit.state.loadMoreFailure, const AppFailure.server(500));
      expect(cubit.state.isLoadingMore, isFalse);
      await cubit.close();
    });

    test('refresh invalidates an in-flight load more', () async {
      final pendingPage = Completer<Result<PagedPage<int>>>();
      final cubit = PagedCubit<int>(
        loadPage: (page) async {
          if (page == 1) {
            return const Result.ok(PagedPage<int>(items: [1], hasMore: true));
          }
          return pendingPage.future;
        },
        idOf: (item) => '$item',
      );

      await cubit.loadFirst();
      final loadingMore = cubit.loadMore();
      await cubit.refresh();
      pendingPage.complete(
        const Result.ok(PagedPage<int>(items: [2], hasMore: false)),
      );
      await loadingMore;

      expect(cubit.state.items, [1]);
      expect(cubit.state.page, 1);
      await cubit.close();
    });
  });
}
