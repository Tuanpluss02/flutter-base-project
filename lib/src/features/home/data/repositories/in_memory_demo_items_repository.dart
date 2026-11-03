import 'package:base/src/core/presentation/paged_state.dart';
import 'package:base/src/core/result/result.dart';

import '../../domain/entities/demo_item.dart';
import '../../domain/repositories/demo_items_repository.dart';

final class InMemoryDemoItemsRepository implements DemoItemsRepository {
  static const pageSize = 20;
  static const pageCount = 3;

  @override
  Future<Result<PagedPage<DemoItem>>> getPage(int page) async {
    if (page < 1 || page > pageCount) {
      return const Result.ok(PagedPage(items: [], hasMore: false));
    }
    final firstId = (page - 1) * pageSize + 1;
    return Result.ok(
      PagedPage(
        items: List.generate(
          pageSize,
          (index) => DemoItem(id: firstId + index),
        ),
        hasMore: page < pageCount,
      ),
    );
  }
}
