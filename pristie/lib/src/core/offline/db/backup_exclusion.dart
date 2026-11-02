import 'package:pristie/src/core/result/result.dart';

/// Marks database files and directories as excluded from OS backups.
abstract interface class BackupExclusion {
  /// Excludes [path] from Android auto-backup and iOS cloud/device backups.
  Future<Result<void>> excludeFromBackup(String path);
}
