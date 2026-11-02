import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:pristie/src/core/error/app_failure.dart';
import 'package:pristie/src/core/offline/sync/sync_dataset.dart';

import '../../domain/entities/demo_item.dart';

part 'offline_home_state.freezed.dart';

/// Local-first home state. Cached [items] stay visible while a background
/// refresh runs or fails.
@freezed
abstract class OfflineHomeState with _$OfflineHomeState {
  const factory OfflineHomeState({
    @Default(<DemoItem>[]) List<DemoItem> items,
    @Default(SyncStatus.online) SyncStatus status,
    @Default(false) bool isLoading,
    AppFailure? failure,
    DateTime? lastSyncedAt,
  }) = _OfflineHomeState;
}
