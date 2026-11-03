import 'package:get_it/get_it.dart';
import 'package:base/src/core/auth/auth_session_controller.dart';
import 'package:base/src/features/auth_placeholder/domain/usecases/login_use_case.dart';
import 'package:base/src/features/auth_placeholder/presentation/cubit/login_cubit.dart';

void registerAuthPlaceholder(GetIt getIt) {
  getIt.registerFactory<LoginCubit>(
    () => LoginCubit(LoginUseCase(getIt<AuthSessionController>())),
  );
}
