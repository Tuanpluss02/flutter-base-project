import 'package:base/src/core/presentation/paged_state.dart';
import 'package:base/src/core/result/result.dart';

import '../entities/demo_item.dart';

abstract interface class DemoItemsRepository {
  Future<Result<PagedPage<DemoItem>>> getPage(int page);
}
