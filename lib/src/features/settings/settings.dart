import 'package:get_it/get_it.dart';
import 'package:base/src/core/auth/auth_coordinator.dart';
import 'package:base/src/core/storage/local_storage.dart';
import 'package:base/src/features/settings/domain/usecases/logout_use_case.dart';
import 'package:base/src/features/settings/presentation/cubit/settings_cubit.dart';

void registerSettings(GetIt getIt) {
  getIt.registerLazySingleton<SettingsCubit>(
    () => SettingsCubit(
      getIt<LocalStorage>(),
      LogoutUseCase(getIt<AuthCoordinator>()),
    ),
  );
}
