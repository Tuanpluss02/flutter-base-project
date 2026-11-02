import 'package:get_it/get_it.dart';
import 'package:pristie/src/features/home/data/repositories/in_memory_demo_items_repository.dart';
import 'package:pristie/src/features/home/domain/repositories/demo_items_repository.dart';
import 'package:pristie/src/features/home/domain/usecases/get_items_use_case.dart';
import 'package:pristie/src/features/home/presentation/cubit/home_cubit.dart';

void registerHome(GetIt getIt) {
  getIt.registerLazySingleton<DemoItemsRepository>(
    InMemoryDemoItemsRepository.new,
  );
  getIt.registerFactory<HomeCubit>(
    () => HomeCubit(GetItemsUseCase(getIt<DemoItemsRepository>())),
  );
}
