import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pristie/src/core/error/app_failure.dart';
import 'package:pristie/src/core/offline/sync/sync_dataset.dart';
import 'package:pristie/src/core/result/result.dart';

import '../../data/repositories/offline_home_repository.dart';
import 'offline_home_state.dart';

/// Reads cached home content first, then refreshes it in the background.
///
/// The cubit never replaces cached data with a loading or error state; only an
/// empty cache may surface a failure.
final class OfflineHomeCubit extends Cubit<OfflineHomeState> {
  OfflineHomeCubit(this._source, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now,
      super(const OfflineHomeState());

  final OfflineHomeDataSource _source;
  final DateTime Function() _clock;

  /// Loads the cache and then starts one background refresh.
  Future<void> load() async {
    emit(state.copyWith(isLoading: true, failure: null));
    final cached = await _source.readCached();
    switch (cached) {
      case Err<HomeOfflineSnapshot>(:final failure):
        emit(state.copyWith(isLoading: false, failure: failure));
        return;
      case Ok<HomeOfflineSnapshot>(:final data):
        emit(
          OfflineHomeState(
            items: data.items,
            status: _status(data, online: true),
            lastSyncedAt: data.lastSyncedAt,
          ),
        );
    }
    await refresh();
  }

  /// Runs one push-then-pull cycle while keeping cached data visible.
  Future<void> refresh() async {
    final hadItems = state.items.isNotEmpty;
    emit(
      state.copyWith(
        isLoading: !hadItems,
        status: hadItems ? SyncStatus.syncing : state.status,
        failure: null,
      ),
    );
    final refreshed = await _source.refresh();
    switch (refreshed) {
      case Err<HomeOfflineSnapshot>(:final failure):
        if (state.items.isNotEmpty) {
          emit(
            state.copyWith(
              isLoading: false,
              status: _failureStatus(failure),
              failure: null,
            ),
          );
        } else {
          emit(
            state.copyWith(
              isLoading: false,
              status: _failureStatus(failure),
              failure: failure,
            ),
          );
        }
      case Ok<HomeOfflineSnapshot>(:final data):
        emit(
          OfflineHomeState(
            items: data.items,
            status: _status(data, online: true),
            lastSyncedAt: data.lastSyncedAt,
          ),
        );
    }
  }

  SyncStatus _status(HomeOfflineSnapshot snapshot, {required bool online}) {
    return syncStatusFor(
      conflicts: snapshot.conflictCount,
      needsAttention: snapshot.needsAttentionCount,
      pending: snapshot.pendingCount,
      syncing: false,
      offline: !online,
      stale: _isStale(snapshot.lastSyncedAt),
    );
  }

  bool _isStale(DateTime? lastSyncedAt) {
    if (lastSyncedAt == null) return true;
    return _clock().isAfter(lastSyncedAt.add(_source.policy.ttl));
  }

  SyncStatus _failureStatus(AppFailure failure) {
    return switch (failure) {
      NetworkFailure() || TimeoutFailure() => SyncStatus.offline,
      UnauthorizedFailure() => SyncStatus.needsAttention,
      _ => SyncStatus.stale,
    };
  }
}
