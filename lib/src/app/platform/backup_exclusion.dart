import 'package:flutter/services.dart';
import 'package:base/src/core/error/app_failure.dart';
import 'package:base/src/core/offline/db/backup_exclusion.dart';
import 'package:base/src/core/result/result.dart';

/// Platform-channel implementation of [BackupExclusion].
///
/// Android disables application backup in the manifest, while iOS sets
/// `NSURLIsExcludedFromBackupKey` on the requested file or directory.
final class PlatformBackupExclusion implements BackupExclusion {
  const PlatformBackupExclusion();

  static const _channel = MethodChannel('com.stormx.base/backup_exclusion');

  @override
  Future<Result<void>> excludeFromBackup(String path) async {
    try {
      await _channel.invokeMethod<void>('excludeFromBackup', {'path': path});
      return const Result.ok(null);
    } catch (_) {
      return const Result.err(AppFailure.localPersistence());
    }
  }
}
