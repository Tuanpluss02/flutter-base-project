import 'package:injectable/injectable.dart';
import 'package:base/src/app/app_router.dart';
import 'package:base/src/app/guards/auth_guard.dart';
import 'package:base/src/core/auth/auth_session_controller.dart';

@module
abstract class RouterModule {
  @lazySingleton
  AuthGuard authGuard(AuthSessionController sessionController) =>
      AuthGuard(sessionController: sessionController);

  @lazySingleton
  AppRouter appRouter(AuthGuard authGuard) => AppRouter(authGuard);
}
