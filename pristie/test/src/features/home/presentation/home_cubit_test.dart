import 'package:flutter_test/flutter_test.dart';
import 'package:pristie/src/core/error/app_failure.dart';
import 'package:pristie/src/core/presentation/paged_state.dart';
import 'package:pristie/src/core/result/result.dart';
import 'package:pristie/src/features/home/domain/entities/demo_item.dart';
import 'package:pristie/src/features/home/domain/repositories/demo_items_repository.dart';
import 'package:pristie/src/features/home/domain/usecases/get_items_use_case.dart';
import 'package:pristie/src/features/home/presentation/cubit/home_cubit.dart';

final class _ScriptedRepository implements DemoItemsRepository {
  _ScriptedRepository(this.handler);

  final Future<Result<PagedPage<DemoItem>>> Function(int page) handler;
  final List<int> requestedPages = <int>[];

  @override
  Future<Result<PagedPage<DemoItem>>> getPage(int page) {
    requestedPages.add(page);
    return handler(page);
  }
}

PagedPage<DemoItem> _page(List<int> ids, {required bool hasMore}) =>
    PagedPage<DemoItem>(
      items: ids.map((id) => DemoItem(id: id)).toList(),
      hasMore: hasMore,
    );

void main() {
  group('HomeCubit', () {
    test('loads first page and appends the next page', () async {
      final repository = _ScriptedRepository(
        (page) async => Result.ok(
          page == 1
              ? _page([1, 2], hasMore: true)
              : _page([3, 4], hasMore: false),
        ),
      );
      final cubit = HomeCubit(GetItemsUseCase(repository));

      await cubit.loadFirst();
      await cubit.loadMore();

      expect(repository.requestedPages, [1, 2]);
      expect(cubit.state.items.map((item) => item.id), [1, 2, 3, 4]);
      expect(cubit.state.page, 2);
      expect(cubit.state.hasMore, isFalse);
      await cubit.close();
    });

    test(
      'load more failure retains items and exposes retryable footer state',
      () async {
        final repository = _ScriptedRepository(
          (page) async => page == 1
              ? Result.ok(_page([1, 2], hasMore: true))
              : const Result.err(AppFailure.server(500)),
        );
        final cubit = HomeCubit(GetItemsUseCase(repository));

        await cubit.loadFirst();
        await cubit.loadMore();

        expect(cubit.state.items.map((item) => item.id), [1, 2]);
        expect(cubit.state.loadMoreFailure, const AppFailure.server(500));
        expect(cubit.state.isLoadingMore, isFalse);
        expect(cubit.state.hasMore, isTrue);
        await cubit.close();
      },
    );

    test('cancellation clears loading without surfacing an error', () async {
      final repository = _ScriptedRepository(
        (page) async => page == 1
            ? Result.ok(_page([1], hasMore: true))
            : const Result.err(AppFailure.cancelled()),
      );
      final cubit = HomeCubit(GetItemsUseCase(repository));

      await cubit.loadFirst();
      await cubit.loadMore();

      expect(cubit.state.items.map((item) => item.id), [1]);
      expect(cubit.state.loadMoreFailure, isNull);
      expect(cubit.state.isLoadingMore, isFalse);
      await cubit.close();
    });
  });
}
