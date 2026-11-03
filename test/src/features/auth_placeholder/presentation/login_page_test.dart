import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:base/src/app/app_router.dart';
import 'package:base/src/app/guards/auth_guard.dart';
import 'package:base/src/app/injection.dart';
import 'package:base/src/core/auth/auth_session_controller.dart';
import 'package:base/src/core/auth/session_service.dart';
import 'package:base/src/core/error/app_failure.dart';
import 'package:base/src/core/result/result.dart';
import 'package:base/src/features/auth_placeholder/domain/usecases/login_use_case.dart';
import 'package:base/src/features/auth_placeholder/presentation/cubit/login_cubit.dart';
import 'package:base/src/features/auth_placeholder/presentation/pages/login_page.dart';
import 'package:base/src/features/home/data/repositories/in_memory_demo_items_repository.dart';
import 'package:base/src/features/home/domain/usecases/get_items_use_case.dart';
import 'package:base/src/features/home/presentation/cubit/home_cubit.dart';
import 'package:base/src/features/home/presentation/pages/home_page.dart';
import 'package:base/generated/l10n/strings.g.dart';

import '../../support/fakes.dart';
import '../../support/test_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LoginPage', () {
    late RecordingSessionTokenProvider tokens;
    late SessionService sessionService;
    late AuthGuard guard;
    late AppRouter router;

    setUp(() async {
      await getIt.reset();
      await LocaleSettings.setLocale(AppLocale.en);
      tokens = RecordingSessionTokenProvider();
      sessionService = SessionService(tokens: tokens);
      await sessionService.restore();
      getIt.registerSingleton<AuthSessionController>(sessionService);
      getIt.registerFactory<LoginCubit>(
        () => LoginCubit(LoginUseCase(sessionService)),
      );
      getIt.registerFactory<HomeCubit>(
        () => HomeCubit(GetItemsUseCase(InMemoryDemoItemsRepository())),
      );
      guard = AuthGuard(sessionController: sessionService);
      router = AppRouter(guard);
    });

    tearDown(() async {
      guard.dispose();
      await sessionService.dispose();
      await getIt.reset();
      await LocaleSettings.setLocale(AppLocale.en);
    });

    testWidgets('empty submit shows localized field validation without login', (
      tester,
    ) async {
      await pumpRouterApp(tester, router);

      expect(find.byType(LoginPage), findsOneWidget);
      await tester.tap(find.byKey(const Key('login.submit')));
      await tester.pumpAndSettle();

      expect(find.text('This field is required'), findsNWidgets(2));
      expect(tokens.writeCalls, 0);
      expect(find.byType(HomePage), findsNothing);
    });

    testWidgets(
      'valid submit writes demo session once and replaces with home',
      (tester) async {
        await pumpRouterApp(tester, router);

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

        expect(tokens.writeCalls, 1);
        expect(tokens.writtenSession?.accessToken, 'demo-access');
        expect(tokens.writtenSession?.refreshToken, 'demo-refresh');
        expect(find.byType(HomePage), findsOneWidget);
        expect(find.byType(LoginPage), findsNothing);
      },
    );

    testWidgets(
      'persistence failure shows localized error and stays on login',
      (tester) async {
        tokens.writeResult = const Result.err(AppFailure.localPersistence());
        await pumpRouterApp(tester, router);

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

        expect(tokens.writeCalls, 1);
        expect(find.textContaining('could not save'), findsOneWidget);
        expect(find.byType(LoginPage), findsOneWidget);
        expect(find.byType(HomePage), findsNothing);
      },
    );

    testWidgets('submit button exposes a localized accessible name', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpRouterApp(tester, router);

      final data = tester
          .getSemantics(find.byKey(const Key('login.submit')))
          .getSemanticsData();
      expect(data.label, 'Sign in');
      expect(data.flagsCollection.isButton, isTrue);

      handle.dispose();
    });

    testWidgets('does not overflow at 360dp and text scale 2.0', (
      tester,
    ) async {
      await pumpRouterApp(
        tester,
        router,
        size: const Size(360, 800),
        textScaler: const TextScaler.linear(2),
      );

      expect(find.byType(LoginPage), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
