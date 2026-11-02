import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pristie/src/app/app_router.dart';
import 'package:pristie/src/app/guards/auth_guard.dart';
import 'package:pristie/src/app/injection.dart';
import 'package:pristie/src/core/auth/auth_session_controller.dart';
import 'package:pristie/src/core/auth/auth_state.dart';
import 'package:pristie/src/core/error/app_failure.dart';
import 'package:pristie/src/core/presentation/paged_state.dart';
import 'package:pristie/src/core/result/result.dart';
import 'package:pristie/src/features/home/domain/entities/demo_item.dart';
import 'package:pristie/src/features/home/domain/repositories/demo_items_repository.dart';
import 'package:pristie/src/features/home/domain/usecases/get_items_use_case.dart';
import 'package:pristie/src/features/home/presentation/cubit/home_cubit.dart';
import 'package:pristie/src/features/home/presentation/pages/home_page.dart';
import 'package:pristie/generated/l10n/strings.g.dart';
import 'package:pristie/src/shared/widgets/app_empty_view.dart';
import 'package:pristie/src/shared/widgets/app_error_view.dart';

import '../../support/fakes.dart';
import '../../support/test_app.dart';

final class _ScriptedRepository implements DemoItemsRepository {
  _ScriptedRepository(this.handler);

  final Future<Result<PagedPage<DemoItem>>> Function(int page) handler;

  @override
  Future<Result<PagedPage<DemoItem>>> getPage(int page) => handler(page);
}

PagedPage<DemoItem> _page(List<int> ids, {required bool hasMore}) =>
    PagedPage<DemoItem>(
      items: ids.map((id) => DemoItem(id: id)).toList(),
      hasMore: hasMore,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HomePage', () {
    late FakeAuthSessionController session;
    late _ScriptedRepository repository;
    late AuthGuard guard;
    late AppRouter router;

    setUp(() async {
      await getIt.reset();
      await LocaleSettings.setLocale(AppLocale.en);
      session = FakeAuthSessionController(
        initialState: AuthState.authenticated,
      );
      repository = _ScriptedRepository(
        (page) async => page == 1
            ? Result.ok(_page([1, 2], hasMore: true))
            : Result.ok(_page([3], hasMore: false)),
      );
      getIt.registerSingleton<AuthSessionController>(session);
      getIt.registerFactory<HomeCubit>(
        () => HomeCubit(GetItemsUseCase(repository)),
      );
      guard = AuthGuard(sessionController: session);
      router = AppRouter(guard);
    });

    tearDown(() async {
      guard.dispose();
      await session.dispose();
      await getIt.reset();
      await LocaleSettings.setLocale(AppLocale.en);
    });

    testWidgets('loads page one and appends page two on load more', (
      tester,
    ) async {
      await pumpRouterApp(tester, router);

      expect(find.byType(HomePage), findsOneWidget);
      expect(find.text('Demo item 1'), findsOneWidget);
      expect(find.text('Demo item 2'), findsOneWidget);
      expect(find.text('Demo item 3'), findsNothing);

      await tester.tap(find.byKey(const Key('home.loadMore')));
      await tester.pumpAndSettle();

      expect(find.text('Demo item 3'), findsOneWidget);
      expect(find.byKey(const Key('home.loadMore')), findsNothing);
    });

    testWidgets('load more failure keeps items and retries from the footer', (
      tester,
    ) async {
      var pageTwoAttempts = 0;
      repository = _ScriptedRepository((page) async {
        if (page == 1) {
          return Result.ok(_page([1, 2], hasMore: true));
        }
        pageTwoAttempts++;
        if (pageTwoAttempts == 1) {
          return const Result.err(AppFailure.server(500));
        }
        return Result.ok(_page([3], hasMore: false));
      });

      await pumpRouterApp(tester, router);
      await tester.tap(find.byKey(const Key('home.loadMore')));
      await tester.pumpAndSettle();

      expect(find.byType(AppErrorView), findsOneWidget);
      expect(find.text('Demo item 1'), findsOneWidget);
      expect(find.text('Demo item 3'), findsNothing);
      expect(pageTwoAttempts, 1);

      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(pageTwoAttempts, 2);
      expect(find.byType(AppErrorView), findsNothing);
      expect(find.text('Demo item 3'), findsOneWidget);
    });

    testWidgets('cancelled load more is not shown as an error', (tester) async {
      repository = _ScriptedRepository(
        (page) async => page == 1
            ? Result.ok(_page([1], hasMore: true))
            : const Result.err(AppFailure.cancelled()),
      );

      await pumpRouterApp(tester, router);
      await tester.tap(find.byKey(const Key('home.loadMore')));
      await tester.pumpAndSettle();

      expect(find.byType(AppErrorView), findsNothing);
      expect(find.text('Demo item 1'), findsOneWidget);
      expect(find.byKey(const Key('home.loadMore')), findsOneWidget);
    });

    testWidgets('empty first page shows the localized empty state', (
      tester,
    ) async {
      repository = _ScriptedRepository(
        (page) async => Result.ok(_page(const [], hasMore: false)),
      );

      await pumpRouterApp(tester, router);

      expect(find.byType(AppEmptyView), findsOneWidget);
      expect(find.byKey(const Key('home.loadMore')), findsNothing);
    });

    testWidgets('load more control exposes a localized accessible name', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpRouterApp(tester, router);

      final data = tester
          .getSemantics(find.byKey(const Key('home.loadMore')))
          .getSemanticsData();
      expect(data.label, 'Load more');
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

      expect(find.byType(HomePage), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
