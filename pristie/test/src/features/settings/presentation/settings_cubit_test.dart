import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pristie/src/core/auth/auth_coordinator.dart';
import 'package:pristie/src/core/auth/auth_state.dart';
import 'package:pristie/src/core/error/app_failure.dart';
import 'package:pristie/src/core/result/result.dart';
import 'package:pristie/src/features/settings/domain/usecases/logout_use_case.dart';
import 'package:pristie/src/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:pristie/generated/l10n/strings.g.dart';

import '../../support/fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SettingsCubit', () {
    late TestLocalStorage storage;
    late FakeAuthSessionController session;
    late AuthCoordinator coordinator;
    late SettingsCubit cubit;

    setUp(() async {
      await LocaleSettings.setLocale(AppLocale.en);
      storage = TestLocalStorage();
      session = FakeAuthSessionController(
        initialState: AuthState.authenticated,
      );
      coordinator = AuthCoordinator(
        tokens: RecordingSessionTokenProvider(),
        session: session,
        refresher: FakeTokenRefresher(),
      );
      cubit = SettingsCubit(storage, LogoutUseCase(coordinator));
    });

    tearDown(() async {
      await cubit.close();
      await session.dispose();
      await LocaleSettings.setLocale(AppLocale.en);
    });

    test(
      'loads system theme and English defaults from empty storage',
      () async {
        await cubit.load();

        expect(cubit.state.themeMode, ThemeMode.system);
        expect(cubit.state.locale, AppLocale.en);
        expect(cubit.state.failure, isNull);
      },
    );

    test('loads persisted theme and locale', () async {
      await storage.setString(SettingsCubit.themeModeKey, 'dark');
      await storage.setString(SettingsCubit.localeKey, 'vi');

      await cubit.load();

      expect(cubit.state.themeMode, ThemeMode.dark);
      expect(cubit.state.locale, AppLocale.vi);
      expect(LocaleSettings.currentLocale, AppLocale.vi);
    });

    test('falls back on unknown persisted values', () async {
      await storage.setString(SettingsCubit.themeModeKey, 'sepia');
      await storage.setString(SettingsCubit.localeKey, 'fr');

      await cubit.load();

      expect(cubit.state.themeMode, ThemeMode.system);
      expect(cubit.state.locale, AppLocale.en);
    });

    test('changeTheme writes the stable key before updating state', () async {
      await cubit.changeTheme(ThemeMode.dark);

      expect(storage.entries[SettingsCubit.themeModeKey], 'dark');
      expect(cubit.state.themeMode, ThemeMode.dark);
      expect(cubit.state.failure, isNull);
    });

    test(
      'changeTheme storage failure is localized and leaves theme unchanged',
      () async {
        storage.failWrites = true;

        await cubit.changeTheme(ThemeMode.dark);

        expect(cubit.state.themeMode, ThemeMode.system);
        expect(cubit.state.failure, const AppFailure.localPersistence());
      },
    );

    test(
      'changeLocale writes the locale key and applies translations',
      () async {
        await cubit.changeLocale(AppLocale.vi);

        expect(storage.entries[SettingsCubit.localeKey], 'vi');
        expect(cubit.state.locale, AppLocale.vi);
        expect(LocaleSettings.currentLocale, AppLocale.vi);
        expect(cubit.state.failure, isNull);
      },
    );

    test('changeLocale storage failure leaves locale unchanged', () async {
      storage.failWrites = true;

      await cubit.changeLocale(AppLocale.vi);

      expect(cubit.state.locale, AppLocale.en);
      expect(LocaleSettings.currentLocale, AppLocale.en);
      expect(cubit.state.failure, const AppFailure.localPersistence());
    });

    test('logout calls the coordinator once and returns to idle', () async {
      await cubit.logout();

      expect(session.logoutCalls, 1);
      expect(cubit.state.isLoggingOut, isFalse);
      expect(cubit.state.failure, isNull);
    });

    test(
      'logout persistence failure stays on settings with localized failure',
      () async {
        session.logoutResult = const Result.err(AppFailure.localPersistence());

        await cubit.logout();

        expect(session.logoutCalls, 1);
        expect(cubit.state.isLoggingOut, isFalse);
        expect(cubit.state.failure, const AppFailure.localPersistence());
      },
    );

    test('logout cancellation is not presented as a failure', () async {
      session.logoutResult = const Result.err(AppFailure.cancelled());

      await cubit.logout();

      expect(session.logoutCalls, 1);
      expect(cubit.state.failure, isNull);
    });
  });
}
