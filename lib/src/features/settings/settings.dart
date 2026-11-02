import 'package:get_it/get_it.dart';
import 'package:pristie/src/core/auth/auth_coordinator.dart';
import 'package:pristie/src/core/storage/local_storage.dart';
import 'package:pristie/src/features/settings/domain/usecases/logout_use_case.dart';
import 'package:pristie/src/features/settings/presentation/cubit/settings_cubit.dart';

void registerSettings(GetIt getIt) {
  getIt.registerLazySingleton<SettingsCubit>(
    () => SettingsCubit(
      getIt<LocalStorage>(),
      LogoutUseCase(getIt<AuthCoordinator>()),
    ),
  );
}
