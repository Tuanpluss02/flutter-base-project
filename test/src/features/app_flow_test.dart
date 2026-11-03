import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:base/src/app/app.dart';
import 'package:base/src/app/app_router.dart';
import 'package:base/src/app/guards/auth_guard.dart';
import 'package:base/src/app/injection.dart';
import 'package:base/src/core/auth/auth_coordinator.dart';
import 'package:base/src/core/auth/auth_session_controller.dart';
import 'package:base/src/core/auth/auth_state.dart';
import 'package:base/src/core/auth/session_service.dart';
import 'package:base/src/core/config/app_config.dart';
import 'package:base/src/core/result/result.dart';
import 'package:base/src/core/storage/local_storage.dart';
import 'package:base/src/core/storage/secure_session_store.dart';
import 'package:base/src/features/auth_placeholder/auth_placeholder.dart';
import 'package:base/src/features/auth_placeholder/presentation/pages/login_page.dart';
import 'package:base/src/features/home/home.dart';
import 'package:base/src/features/home/presentation/pages/home_page.dart';
import 'package:base/src/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:base/src/features/settings/presentation/pages/settings_page.dart';
import 'package:base/src/features/settings/settings.dart';
import 'package:base/generated/l10n/strings.g.dart';

import '../core/storage/fakes/in_memory_secure_storage.dart';
import 'support/fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final config = AppConfig(
    environment: AppEnvironment.dev,
    apiBaseUrl: Uri.parse('https://api.dev.base.example'),
    appName: 'Base Test',
    enableLogging: false,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    sendTimeout: const Duration(seconds: 10),
  );

  group('Sample feature app flow', () {
    late TestLocalStorage localStorage;
    late SecureSessionStore sessionStore;
    late SessionService sessionService;
    late AuthGuard guard;
    late AppRouter router;

    setUp(() async {
      await getIt.reset();
      await LocaleSettings.setLocale(AppLocale.en);
      localStorage = TestLocalStorage();
      sessionStore = SecureSessionStore(secureStorage: InMemorySecureStorage());
      sessionService = SessionService(tokens: sessionStore);
      await sessionService.restore();
      final coordinator = AuthCoordinator(
        tokens: sessionStore,
        session: sessionService,
        refresher: FakeTokenRefresher(),
      );
      getIt.registerSingleton<AppConfig>(config);
      getIt.registerSingleton<LocalStorage>(localStorage);
      getIt.registerSingleton<AuthSessionController>(sessionService);
      getIt.registerSingleton<AuthCoordinator>(coordinator);
      registerAuthPlaceholder(getIt);
      registerHome(getIt);
      registerSettings(getIt);
      await getIt<SettingsCubit>().load();
      guard = AuthGuard(sessionController: sessionService);
      router = AppRouter(guard);
    });

    tearDown(() async {
      guard.dispose();
      await sessionService.dispose();
      await getIt.reset();
      await LocaleSettings.setLocale(AppLocale.en);
    });

    testWidgets(
      'login, paged home, theme/locale settings, and logout work end to end',
      (tester) async {
        addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));

        await tester.pumpWidget(
          App(
            config: config,
            router: router,
            authState: AuthState.unauthenticated,
            settingsCubit: getIt<SettingsCubit>(),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(LoginPage), findsOneWidget);

        await tester.enterText(
          find.byKey(const Key('login.email')),
          'demo@example.com',
        );
        await tester.enterText(
          find.byKey(const Key('login.password')),
          'password',
        );
        await tester.tap(find.byKey(const Key('login.submit')));
        await tester.pumpAndSettle();

        expect(find.byType(HomePage), findsOneWidget);
        final sessionResult = await sessionStore.readSession();
        final session = switch (sessionResult) {
          Ok(:final data) => data,
          Err() => null,
        };
        expect(session?.accessToken, 'demo-access');
        expect(find.text('Demo item 1'), findsOneWidget);

        await tester.tap(find.byKey(const Key('home.settings')));
        await tester.pumpAndSettle();
        expect(find.byType(SettingsPage), findsOneWidget);

        await tester.tap(find.byKey(const Key('settings.themeMode')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Dark').last);
        await tester.pumpAndSettle();

        expect(localStorage.entries[SettingsCubit.themeModeKey], 'dark');
        expect(
          tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
          ThemeMode.dark,
        );

        await tester.tap(find.byKey(const Key('settings.locale')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Vietnamese').last);
        await tester.pumpAndSettle();

        expect(localStorage.entries[SettingsCubit.localeKey], 'vi');
        expect(find.text('Cài đặt'), findsOneWidget);

        await tester.tap(find.byKey(const Key('settings.logout')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('settings.logoutConfirm')));
        await tester.pumpAndSettle();
        await tester.runAsync(() async {
          await Future<void>.delayed(const Duration(milliseconds: 50));
        });
        await tester.pumpAndSettle();

        expect(sessionService.currentAuthState, AuthState.unauthenticated);
        expect(guard.currentAuthState, AuthState.unauthenticated);
        expect(getIt<SettingsCubit>().state.failure, isNull);
        expect(find.byType(SettingsPage), findsNothing);
        expect(find.byType(LoginPage), findsOneWidget);
        expect(find.byType(HomePage), findsNothing);
        expect(sessionService.currentAuthState, AuthState.unauthenticated);
        final hasSession = await sessionStore.hasSession();
        expect(hasSession, const Result.ok(false));
      },
    );
  });
}
