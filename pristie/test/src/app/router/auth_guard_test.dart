import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pristie/src/app/app_router.dart';
import 'package:pristie/src/app/app_router.gr.dart';
import 'package:pristie/src/app/guards/auth_guard.dart';
import 'package:pristie/src/app/injection.dart';
import 'package:pristie/src/app/pages/not_found_page.dart';
import 'package:pristie/src/core/auth/auth_session_controller.dart';
import 'package:pristie/src/core/auth/auth_state.dart';
import 'package:pristie/src/core/result/result.dart';
import 'package:pristie/src/core/storage/session.dart';
import 'package:pristie/src/features/auth_placeholder/domain/usecases/login_use_case.dart';
import 'package:pristie/src/features/auth_placeholder/presentation/cubit/login_cubit.dart';
import 'package:pristie/src/features/auth_placeholder/presentation/pages/login_page.dart';
import 'package:pristie/src/features/home/data/repositories/in_memory_demo_items_repository.dart';
import 'package:pristie/src/features/home/domain/usecases/get_items_use_case.dart';
import 'package:pristie/src/features/home/presentation/cubit/home_cubit.dart';
import 'package:pristie/src/features/home/presentation/pages/home_page.dart';
import 'package:pristie/src/l10n/strings.g.dart';

class FakeAuthSessionController implements AuthSessionController {
  FakeAuthSessionController({AuthState initialState = AuthState.unknown})
    : _currentAuthState = initialState;

  final StreamController<AuthState> _controller =
      StreamController<AuthState>.broadcast();

  AuthState _currentAuthState;
  int _sessionEpoch = 0;
  bool _isRequestGateOpen = false;

  @override
  Stream<AuthState> get authStateStream => _controller.stream;

  @override
  AuthState get currentAuthState => _currentAuthState;

  @override
  int get sessionEpoch => _sessionEpoch;

  @override
  bool get isRequestGateOpen => _isRequestGateOpen;

  void emitState(AuthState state) {
    _currentAuthState = state;
    _controller.add(state);
  }

  @override
  Future<AuthState> restore() async => _currentAuthState;

  @override
  Future<Result<void>> login(Session session) async {
    _sessionEpoch++;
    _isRequestGateOpen = true;
    emitState(AuthState.authenticated);
    return const Result.ok(null);
  }

  @override
  Future<Result<void>> logout() async {
    _sessionEpoch++;
    _isRequestGateOpen = false;
    emitState(AuthState.unauthenticated);
    return const Result.ok(null);
  }

  @override
  Future<Result<void>> invalidateSession() async {
    _sessionEpoch++;
    _isRequestGateOpen = false;
    emitState(AuthState.unauthenticated);
    return const Result.ok(null);
  }

  void dispose() {
    _controller.close();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuthGuard Unit Tests', () {
    late FakeAuthSessionController fakeController;
    late AuthGuard guard;

    setUp(() {
      fakeController = FakeAuthSessionController(
        initialState: AuthState.unknown,
      );
      guard = AuthGuard(sessionController: fakeController);
    });

    tearDown(() {
      guard.dispose();
      fakeController.dispose();
    });

    test(
      'AuthState.unknown defers navigation until auth state is resolved',
      () async {
        final completer = Completer<ResolverResult>();
        final route = RouteMatch(
          config: AutoRoute(page: HomeRoute.page, path: '/'),
          segments: const ['/'],
          stringMatch: '/',
          key: const ValueKey('home'),
        );
        final router = AppRouter(guard);
        final resolver = NavigationResolver(router, completer, route);

        unawaited(Future.sync(() => guard.onNavigation(resolver, router)));

        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(completer.isCompleted, isFalse);

        fakeController.emitState(AuthState.authenticated);
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(completer.isCompleted, isTrue);
        final result = await completer.future;
        expect(result.continueNavigation, isTrue);
      },
    );

    test('unauthenticated on protected route replaces with /login', () async {
      fakeController.emitState(AuthState.unauthenticated);
      final completer = Completer<ResolverResult>();
      final route = RouteMatch(
        config: AutoRoute(page: HomeRoute.page, path: '/'),
        segments: const ['/'],
        stringMatch: '/',
        key: const ValueKey('home'),
      );
      final router = AppRouter(guard);
      final resolver = NavigationResolver(router, completer, route);

      await guard.onNavigation(resolver, router);

      expect(completer.isCompleted, isTrue);
      final result = await completer.future;
      expect(result.continueNavigation, isFalse);
    });

    test('locked on protected route replaces with /login', () async {
      fakeController.emitState(AuthState.locked);
      final completer = Completer<ResolverResult>();
      final route = RouteMatch(
        config: AutoRoute(page: HomeRoute.page, path: '/'),
        segments: const ['/'],
        stringMatch: '/',
        key: const ValueKey('home'),
      );
      final router = AppRouter(guard);
      final resolver = NavigationResolver(router, completer, route);

      await guard.onNavigation(resolver, router);

      expect(completer.isCompleted, isTrue);
      final result = await completer.future;
      expect(result.continueNavigation, isFalse);
    });

    test('authenticated on /login replaces with /', () async {
      fakeController.emitState(AuthState.authenticated);
      final completer = Completer<ResolverResult>();
      final route = RouteMatch(
        config: AutoRoute(page: LoginRoute.page, path: '/login'),
        segments: const ['login'],
        stringMatch: '/login',
        key: const ValueKey('login'),
      );
      final router = AppRouter(guard);
      final resolver = NavigationResolver(router, completer, route);

      await guard.onNavigation(resolver, router);

      expect(completer.isCompleted, isTrue);
      final result = await completer.future;
      expect(result.continueNavigation, isFalse);
    });

    test('unauthenticated on /login allows navigation', () async {
      fakeController.emitState(AuthState.unauthenticated);
      final completer = Completer<ResolverResult>();
      final route = RouteMatch(
        config: AutoRoute(page: LoginRoute.page, path: '/login'),
        segments: const ['login'],
        stringMatch: '/login',
        key: const ValueKey('login'),
      );
      final router = AppRouter(guard);
      final resolver = NavigationResolver(router, completer, route);

      await guard.onNavigation(resolver, router);

      expect(completer.isCompleted, isTrue);
      final result = await completer.future;
      expect(result.continueNavigation, isTrue);
    });

    test(
      'reevaluateListenable notifies listeners when authState changes',
      () async {
        var notified = 0;
        guard.addListener(() {
          notified++;
        });

        fakeController.emitState(AuthState.authenticated);
        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(notified, 1);

        fakeController.emitState(AuthState.unauthenticated);
        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(notified, 2);
      },
    );
  });

  group('AppRouter Widget Tests', () {
    late FakeAuthSessionController fakeController;
    late AuthGuard guard;
    late AppRouter router;

    setUp(() async {
      await getIt.reset();
      await LocaleSettings.setLocale(AppLocale.en);
      fakeController = FakeAuthSessionController(
        initialState: AuthState.unauthenticated,
      );
      getIt.registerFactory<LoginCubit>(
        () => LoginCubit(LoginUseCase(fakeController)),
      );
      getIt.registerFactory<HomeCubit>(
        () => HomeCubit(GetItemsUseCase(InMemoryDemoItemsRepository())),
      );
      guard = AuthGuard(sessionController: fakeController);
      router = AppRouter(guard);
    });

    tearDown(() async {
      guard.dispose();
      fakeController.dispose();
      await getIt.reset();
    });

    testWidgets('unauthenticated on initial / redirects to LoginPage', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router.config(
            reevaluateListenable: guard,
            deepLinkBuilder: (_) => DeepLink.defaultPath,
          ),
          builder: (context, child) =>
              TranslationProvider(child: child ?? const SizedBox.shrink()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(LoginPage), findsOneWidget);
      expect(find.byType(HomePage), findsNothing);
    });

    testWidgets('authenticated on initial / shows HomePage', (tester) async {
      fakeController.emitState(AuthState.authenticated);

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router.config(
            reevaluateListenable: guard,
            deepLinkBuilder: (_) => DeepLink.defaultPath,
          ),
          builder: (context, child) =>
              TranslationProvider(child: child ?? const SizedBox.shrink()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(HomePage), findsOneWidget);
      expect(find.byType(LoginPage), findsNothing);
    });

    testWidgets(
      'authenticated user navigating to /login redirects to HomePage',
      (tester) async {
        fakeController.emitState(AuthState.authenticated);

        await tester.pumpWidget(
          MaterialApp.router(
            routerConfig: router.config(
              reevaluateListenable: guard,
              deepLinkBuilder: (_) => DeepLink.defaultPath,
            ),
            builder: (context, child) =>
                TranslationProvider(child: child ?? const SizedBox.shrink()),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(HomePage), findsOneWidget);

        await router.push(const LoginRoute());
        await tester.pumpAndSettle();

        expect(find.byType(HomePage), findsOneWidget);
        expect(find.byType(LoginPage), findsNothing);
      },
    );

    testWidgets(
      'logout transitions stack to LoginPage and back cannot reach HomePage',
      (tester) async {
        fakeController.emitState(AuthState.authenticated);

        await tester.pumpWidget(
          MaterialApp.router(
            routerConfig: router.config(
              reevaluateListenable: guard,
              deepLinkBuilder: (_) => DeepLink.defaultPath,
            ),
            builder: (context, child) =>
                TranslationProvider(child: child ?? const SizedBox.shrink()),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(HomePage), findsOneWidget);

        // Perform logout
        fakeController.emitState(AuthState.unauthenticated);
        await tester.runAsync(() async {
          await Future<void>.delayed(const Duration(milliseconds: 50));
        });
        await tester.pumpAndSettle();

        expect(find.byType(LoginPage), findsOneWidget);
        expect(find.byType(HomePage), findsNothing);
        expect(router.canPop(), isFalse);
      },
    );

    testWidgets('unknown in-app route displays NotFoundPage', (tester) async {
      fakeController.emitState(AuthState.authenticated);

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router.config(
            reevaluateListenable: guard,
            deepLinkBuilder: (_) => DeepLink.defaultPath,
          ),
          builder: (context, child) =>
              TranslationProvider(child: child ?? const SizedBox.shrink()),
        ),
      );
      await tester.pumpAndSettle();

      unawaited(router.pushPath('/unknown-path-1234'));
      await tester.pumpAndSettle();

      expect(find.byType(NotFoundPage), findsOneWidget);
    });

    testWidgets(
      'buildDeepLink defaults to defaultPath and ignores platform deep link path',
      (tester) async {
        final deepLink = router.buildDeepLink(
          Uri.parse('https://example.com/some/random/path'),
        );
        expect(deepLink, equals(DeepLink.defaultPath));
      },
    );
  });
}
