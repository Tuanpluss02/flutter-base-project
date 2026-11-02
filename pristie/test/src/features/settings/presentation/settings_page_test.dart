import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pristie/src/app/injection.dart';
import 'package:pristie/src/core/auth/auth_coordinator.dart';
import 'package:pristie/src/core/auth/auth_state.dart';
import 'package:pristie/src/core/error/app_failure.dart';
import 'package:pristie/src/core/result/result.dart';
import 'package:pristie/src/features/settings/domain/usecases/logout_use_case.dart';
import 'package:pristie/src/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:pristie/src/features/settings/presentation/pages/settings_page.dart';
import 'package:pristie/src/l10n/strings.g.dart';
import 'package:pristie/src/shared/widgets/app_error_view.dart';

import '../../support/fakes.dart';
import '../../support/test_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SettingsPage', () {
    late TestLocalStorage storage;
    late FakeAuthSessionController session;
    late SettingsCubit cubit;

    setUp(() async {
      await getIt.reset();
      await LocaleSettings.setLocale(AppLocale.en);
      storage = TestLocalStorage();
      session = FakeAuthSessionController(
        initialState: AuthState.authenticated,
      );
      final coordinator = AuthCoordinator(
        tokens: RecordingSessionTokenProvider(),
        session: session,
        refresher: FakeTokenRefresher(),
      );
      cubit = SettingsCubit(storage, LogoutUseCase(coordinator));
      getIt.registerSingleton<SettingsCubit>(cubit);
    });

    tearDown(() async {
      await getIt.reset();
      await cubit.close();
      await session.dispose();
      await LocaleSettings.setLocale(AppLocale.en);
    });

    testWidgets('theme change writes the stable key and updates state', (
      tester,
    ) async {
      await pumpFeaturePage(tester, const SettingsPage());

      await tester.tap(find.byKey(const Key('settings.themeMode')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dark').last);
      await tester.pumpAndSettle();

      expect(storage.entries[SettingsCubit.themeModeKey], 'dark');
      expect(cubit.state.themeMode, ThemeMode.dark);
    });

    testWidgets('locale change writes the key and swaps localized copy', (
      tester,
    ) async {
      await pumpFeaturePage(tester, const SettingsPage());

      await tester.tap(find.byKey(const Key('settings.locale')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Vietnamese').last);
      await tester.pumpAndSettle();

      expect(storage.entries[SettingsCubit.localeKey], 'vi');
      expect(LocaleSettings.currentLocale, AppLocale.vi);
      expect(cubit.state.locale, AppLocale.vi);
      expect(find.text('Cài đặt'), findsOneWidget);
    });

    testWidgets('logout asks for confirmation and cancel keeps settings open', (
      tester,
    ) async {
      await pumpFeaturePage(tester, const SettingsPage());

      await tester.tap(find.byKey(const Key('settings.logout')));
      await tester.pumpAndSettle();

      expect(find.text('Are you sure you want to sign out?'), findsOneWidget);
      await tester.tap(find.byKey(const Key('settings.logoutCancel')));
      await tester.pumpAndSettle();

      expect(session.logoutCalls, 0);
      expect(find.byType(SettingsPage), findsOneWidget);
    });

    testWidgets('confirmed logout calls the coordinator once', (tester) async {
      await pumpFeaturePage(tester, const SettingsPage());

      await tester.tap(find.byKey(const Key('settings.logout')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('settings.logoutConfirm')));
      await tester.pumpAndSettle();

      expect(session.logoutCalls, 1);
      expect(cubit.state.isLoggingOut, isFalse);
      expect(cubit.state.failure, isNull);
    });

    testWidgets('logout persistence failure shows localized error and stays', (
      tester,
    ) async {
      session.logoutResult = const Result.err(AppFailure.localPersistence());
      await pumpFeaturePage(tester, const SettingsPage());

      await tester.tap(find.byKey(const Key('settings.logout')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('settings.logoutConfirm')));
      await tester.pumpAndSettle();

      expect(session.logoutCalls, 1);
      expect(find.byType(AppErrorView), findsOneWidget);
      expect(find.textContaining('could not save'), findsOneWidget);
      expect(find.byType(SettingsPage), findsOneWidget);
    });

    testWidgets('logout cancellation is not presented as an error', (
      tester,
    ) async {
      session.logoutResult = const Result.err(AppFailure.cancelled());
      await pumpFeaturePage(tester, const SettingsPage());

      await tester.tap(find.byKey(const Key('settings.logout')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('settings.logoutConfirm')));
      await tester.pumpAndSettle();

      expect(session.logoutCalls, 1);
      expect(find.byType(AppErrorView), findsNothing);
      expect(cubit.state.failure, isNull);
    });

    testWidgets('logout control exposes a localized accessible name', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpFeaturePage(tester, const SettingsPage());

      final data = tester
          .getSemantics(find.byKey(const Key('settings.logout')))
          .getSemanticsData();
      expect(data.label, 'Sign out');
      expect(data.flagsCollection.isButton, isTrue);

      handle.dispose();
    });

    testWidgets('does not overflow at 360dp and text scale 2.0', (
      tester,
    ) async {
      await pumpFeaturePage(
        tester,
        const SettingsPage(),
        size: const Size(360, 800),
        textScaler: const TextScaler.linear(2),
      );

      expect(find.byType(SettingsPage), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
