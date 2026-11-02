import 'package:auto_route/auto_route.dart';
import 'package:pristie/src/app/app_router.gr.dart';
import 'package:pristie/src/app/guards/auth_guard.dart';

@AutoRouterConfig(replaceInRouteName: 'Page,Route')
class AppRouter extends RootStackRouter {
  AppRouter(this.authGuard);

  final AuthGuard authGuard;

  @override
  List<AutoRoute> get routes => [
    AutoRoute(
      page: HomeRoute.page,
      path: '/',
      initial: true,
      guards: [authGuard],
    ),
    AutoRoute(page: LoginRoute.page, path: '/login', guards: [authGuard]),
    AutoRoute(page: SettingsRoute.page, path: '/settings', guards: [authGuard]),
    AutoRoute(page: NotFoundRoute.page, path: '*'),
  ];

  DeepLink? buildDeepLink(Uri uri) => DeepLink.defaultPath;
}
