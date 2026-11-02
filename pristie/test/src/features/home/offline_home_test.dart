import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:pristie/src/core/error/app_failure.dart';
import 'package:pristie/src/core/offline/policy/offline_config.dart';
import 'package:pristie/src/core/offline/policy/offline_policy.dart';
import 'package:pristie/src/core/offline/sync/sync_dataset.dart';
import 'package:pristie/src/core/result/result.dart';
import 'package:pristie/src/features/home/data/repositories/offline_home_repository.dart';
import 'package:pristie/src/features/home/domain/entities/demo_item.dart';
import 'package:pristie/src/features/home/home.dart';
import 'package:pristie/src/features/home/presentation/cubit/offline_home_cubit.dart';
import 'package:pristie/src/features/home/presentation/pages/offline_home_view.dart';

import '../../core/offline/sync_test_support.dart';
import '../support/test_app.dart';

final class _FakeOfflineHomeSource implements OfflineHomeDataSource {
  _FakeOfflineHomeSource({
    required this.snapshot,
    this.refreshResult,
    this.refreshGate,
  });

  HomeOfflineSnapshot snapshot;
  Result<HomeOfflineSnapshot>? refreshResult;
  Completer<void>? refreshGate;
  int reads = 0;
  int refreshes = 0;

  @override
  OfflinePolicy get policy => writablePolicy;

  @override
  Future<Result<HomeOfflineSnapshot>> readCached() async {
    reads++;
    return Result.ok(snapshot);
  }

  @override
  Future<Result<HomeOfflineSnapshot>> refresh() async {
    refreshes++;
    final gate = refreshGate;
    if (gate != null) await gate.future;
    return refreshResult ?? Result.ok(snapshot);
  }
}

HomeOfflineSnapshot _snapshot({
  List<int> ids = const <int>[1, 2],
  int pending = 0,
  int conflicts = 0,
  int needsAttention = 0,
  DateTime? lastSyncedAt,
}) {
  return HomeOfflineSnapshot(
    items: ids.map((id) => DemoItem(id: id)).toList(),
    pendingCount: pending,
    conflictCount: conflicts,
    needsAttentionCount: needsAttention,
    lastSyncedAt: lastSyncedAt ?? DateTime.utc(2026, 1, 1, 12),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final now = DateTime.utc(2026, 1, 1, 12);

  group('OfflineHomeCubit', () {
    test('emits cached data before the background refresh completes', () async {
      final gate = Completer<void>();
      final source = _FakeOfflineHomeSource(
        snapshot: _snapshot(),
        refreshGate: gate,
      );
      final cubit = OfflineHomeCubit(source, clock: () => now);

      final loading = cubit.load();
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.items.map((item) => item.id), <int>[1, 2]);
      expect(cubit.state.isLoading, isFalse);
      expect(cubit.state.status, SyncStatus.syncing);

      gate.complete();
      await loading;
      expect(cubit.state.items.map((item) => item.id), <int>[1, 2]);
      expect(cubit.state.status, SyncStatus.online);
      expect(cubit.state.failure, isNull);
      await cubit.close();
    });

    test(
      'a background network failure keeps cached data and marks offline',
      () async {
        final source = _FakeOfflineHomeSource(
          snapshot: _snapshot(),
          refreshResult: const Result.err(AppFailure.network()),
        );
        final cubit = OfflineHomeCubit(source, clock: () => now);

        await cubit.load();

        expect(cubit.state.items.map((item) => item.id), <int>[1, 2]);
        expect(cubit.state.status, SyncStatus.offline);
        expect(cubit.state.failure, isNull);
        await cubit.close();
      },
    );

    test('pending and conflict counts select the attention state', () async {
      final pendingSource = _FakeOfflineHomeSource(
        snapshot: _snapshot(pending: 1),
      );
      final pending = OfflineHomeCubit(pendingSource, clock: () => now);
      await pending.load();
      expect(pending.state.status, SyncStatus.pending);
      await pending.close();

      final conflictSource = _FakeOfflineHomeSource(
        snapshot: _snapshot(conflicts: 1, pending: 1),
      );
      final conflict = OfflineHomeCubit(conflictSource, clock: () => now);
      await conflict.load();
      expect(conflict.state.status, SyncStatus.conflict);
      await conflict.close();
    });

    test('old cached data is stale', () async {
      final source = _FakeOfflineHomeSource(
        snapshot: _snapshot(
          lastSyncedAt: now.subtract(const Duration(hours: 2)),
        ),
      );
      final cubit = OfflineHomeCubit(source, clock: () => now);
      await cubit.load();
      expect(cubit.state.status, SyncStatus.stale);
      await cubit.close();
    });
  });

  group('offline home opt-in', () {
    tearDown(() async {
      await GetIt.instance.reset();
    });

    test('disabled OFFLINE_ENABLED does not register the offline cubit', () {
      final getIt = GetIt.instance;
      final source = _FakeOfflineHomeSource(snapshot: _snapshot());

      registerOfflineHome(
        getIt,
        source: source,
        config: const OfflineConfig(enabled: false),
      );

      expect(getIt.isRegistered<OfflineHomeCubit>(), isFalse);
    });

    test('enabled OFFLINE_ENABLED registers the offline cubit', () {
      final getIt = GetIt.instance;
      final source = _FakeOfflineHomeSource(snapshot: _snapshot());

      registerOfflineHome(
        getIt,
        source: source,
        config: const OfflineConfig(enabled: true),
      );

      expect(getIt.isRegistered<OfflineHomeCubit>(), isTrue);
    });

    testWidgets('renders cached data and the localized pending banner', (
      tester,
    ) async {
      final source = _FakeOfflineHomeSource(snapshot: _snapshot(pending: 1));
      final cubit = OfflineHomeCubit(source, clock: () => now);
      addTearDown(cubit.close);

      await pumpFeaturePage(
        tester,
        BlocProvider<OfflineHomeCubit>.value(
          value: cubit..load(),
          child: const OfflineHomeView(),
        ),
      );

      expect(find.text('Demo item 1'), findsOneWidget);
      expect(find.text('Demo item 2'), findsOneWidget);
      expect(find.text('Waiting to sync'), findsOneWidget);
      expect(find.byKey(const Key('home.offlineBanner')), findsOneWidget);
    });

    testWidgets('renders the offline banner without replacing cached data', (
      tester,
    ) async {
      final source = _FakeOfflineHomeSource(
        snapshot: _snapshot(),
        refreshResult: const Result.err(AppFailure.network()),
      );
      final cubit = OfflineHomeCubit(source, clock: () => now);
      addTearDown(cubit.close);

      await pumpFeaturePage(
        tester,
        BlocProvider<OfflineHomeCubit>.value(
          value: cubit..load(),
          child: const OfflineHomeView(),
        ),
      );

      expect(find.text('Demo item 1'), findsOneWidget);
      expect(find.text('Offline'), findsOneWidget);
    });
  });
}
