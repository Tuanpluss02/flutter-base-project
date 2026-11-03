import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:base/src/app/app.dart';
import 'package:base/src/app/bootstrap.dart';
import 'package:base/src/core/auth/auth_state.dart';
import 'package:base/src/core/config/app_config.dart';
import 'package:base/src/core/storage/local_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final validConfig = AppConfig(
    environment: AppEnvironment.dev,
    apiBaseUrl: Uri.parse('https://api.dev.base.example'),
    appName: 'Base Dev',
    enableLogging: true,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    sendTimeout: const Duration(seconds: 10),
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    await GetIt.instance.reset();
  });

  tearDown(() async {
    await GetIt.instance.reset();
  });

  group('Bootstrap', () {
    testWidgets('boots cleanly on first install and clears session', (
      tester,
    ) async {
      Widget? renderedApp;

      await bootstrap(
        configProvider: () => validConfig,
        runner: (widget) => renderedApp = widget,
      );

      expect(renderedApp, isA<App>());
      final app = renderedApp! as App;
      expect(app.config.appName, 'Base Dev');
      expect(app.authState, AuthState.unauthenticated);

      // Verify install_marker was written
      final localStorage = GetIt.instance<LocalStorage>();
      expect(localStorage.getString('install_marker'), 'v1');
    });

    testWidgets(
      'subsequent launch does not clear session if install marker exists',
      (tester) async {
        Widget? renderedApp;

        // First run to set install_marker
        await bootstrap(
          configProvider: () => validConfig,
          runner: (widget) => renderedApp = widget,
        );

        expect(renderedApp, isA<App>());
        final localStorage = GetIt.instance<LocalStorage>();
        expect(localStorage.getString('install_marker'), 'v1');

        // Now run bootstrap again
        Widget? secondRenderedApp;
        await bootstrap(
          configProvider: () => validConfig,
          runner: (widget) => secondRenderedApp = widget,
        );

        expect(secondRenderedApp, isA<App>());
      },
    );

    testWidgets(
      'renders ConfigErrorApp displaying key name on missing config without leaking values',
      (tester) async {
        Widget? renderedApp;

        await bootstrap(
          configProvider: () =>
              throw const AppConfigException('API_BASE_URL', 'required'),
          runner: (widget) => renderedApp = widget,
        );

        expect(renderedApp, isA<ConfigErrorApp>());
        final errorApp = renderedApp! as ConfigErrorApp;
        expect(errorApp.failedKey, 'API_BASE_URL');

        await tester.pumpWidget(errorApp);
        expect(find.textContaining('API_BASE_URL'), findsOneWidget);
      },
    );

    testWidgets('storage failure fails closed to AuthState.locked', (
      tester,
    ) async {
      Widget? renderedApp;

      await bootstrap(
        configProvider: () => validConfig,
        storageInitializer: () => throw Exception('Secure storage corrupted'),
        runner: (widget) => renderedApp = widget,
      );

      expect(renderedApp, isA<App>());
      final app = renderedApp! as App;
      expect(app.authState, AuthState.locked);
    });
  });
}
