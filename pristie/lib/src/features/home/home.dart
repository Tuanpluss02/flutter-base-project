import 'package:get_it/get_it.dart';
import 'package:pristie/src/core/offline/policy/offline_config.dart';
import 'package:pristie/src/features/home/data/repositories/in_memory_demo_items_repository.dart';
import 'package:pristie/src/features/home/data/repositories/offline_home_repository.dart';
import 'package:pristie/src/features/home/domain/repositories/demo_items_repository.dart';
import 'package:pristie/src/features/home/domain/usecases/get_items_use_case.dart';
import 'package:pristie/src/features/home/presentation/cubit/home_cubit.dart';
import 'package:pristie/src/features/home/presentation/cubit/offline_home_cubit.dart';

void registerHome(GetIt getIt) {
  getIt.registerLazySingleton<DemoItemsRepository>(
    InMemoryDemoItemsRepository.new,
  );
  getIt.registerFactory<HomeCubit>(
    () => HomeCubit(GetItemsUseCase(getIt<DemoItemsRepository>())),
  );
}

/// Opts the home feature into the local-first read path.
///
/// The offline cubit is never registered when `OFFLINE_ENABLED` is false, so
/// the regular online-only [HomeCubit] remains the only path.
void registerOfflineHome(
  GetIt getIt, {
  required OfflineHomeDataSource source,
  required OfflineConfig config,
}) {
  if (!config.enabled) return;
  getIt.registerFactory<OfflineHomeCubit>(() => OfflineHomeCubit(source));
}
