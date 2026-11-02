import 'package:flutter_test/flutter_test.dart';
import 'package:pristie/src/app/app_router.dart';
import 'package:pristie/src/app/injection.dart';
import 'package:pristie/src/core/config/app_config.dart';
import 'package:pristie/src/features/auth_placeholder/presentation/cubit/login_cubit.dart';
import 'package:pristie/src/features/home/domain/repositories/demo_items_repository.dart';
import 'package:pristie/src/features/home/presentation/cubit/home_cubit.dart';
import 'package:pristie/src/features/settings/presentation/cubit/settings_cubit.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final config = AppConfig(
    environment: AppEnvironment.dev,
    apiBaseUrl: Uri.parse('https://api.dev.pristie.example'),
    appName: 'Pristie Test',
    enableLogging: false,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    sendTimeout: const Duration(seconds: 10),
  );

  setUp(() async {
    await getIt.reset();
    await configureDependencies(config: config);
  });

  tearDown(() async {
    await getIt.reset();
  });

  group('Feature composition', () {
    test('registers all feature cubits and repositories', () {
      expect(getIt.isRegistered<LoginCubit>(), isTrue);
      expect(getIt.isRegistered<HomeCubit>(), isTrue);
      expect(getIt.isRegistered<SettingsCubit>(), isTrue);
      expect(getIt.isRegistered<DemoItemsRepository>(), isTrue);
      expect(getIt<LoginCubit>(), isA<LoginCubit>());
      expect(getIt<HomeCubit>(), isA<HomeCubit>());
      expect(getIt<SettingsCubit>(), isA<SettingsCubit>());
    });

    test('aggregates home, login, settings, and catch-all routes', () {
      final router = getIt<AppRouter>();

      expect(
        router.routes.map((route) => route.path),
        containsAll(['/', '/login', '/settings', '*']),
      );
    });

    test('feature registration is repeatable after dependency reset', () async {
      await configureDependencies(config: config);
      await configureDependencies(config: config);

      expect(getIt<LoginCubit>(), isA<LoginCubit>());
      expect(getIt<HomeCubit>(), isA<HomeCubit>());
      expect(getIt<SettingsCubit>(), isA<SettingsCubit>());
    });
  });
}
