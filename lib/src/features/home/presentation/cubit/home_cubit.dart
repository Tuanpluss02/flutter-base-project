import 'package:base/src/core/presentation/paged_cubit.dart';

import '../../domain/entities/demo_item.dart';
import '../../domain/usecases/get_items_use_case.dart';

final class HomeCubit extends PagedCubit<DemoItem> {
  HomeCubit(GetItemsUseCase getItems)
    : super(loadPage: getItems.call, idOf: (item) => item.id.toString());
}
