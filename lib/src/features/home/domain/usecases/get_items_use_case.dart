import 'package:base/src/core/presentation/paged_state.dart';
import 'package:base/src/core/result/result.dart';

import '../entities/demo_item.dart';
import '../repositories/demo_items_repository.dart';

final class GetItemsUseCase {
  const GetItemsUseCase(this._repository);

  final DemoItemsRepository _repository;

  Future<Result<PagedPage<DemoItem>>> call(int page) =>
      _repository.getPage(page);
}
