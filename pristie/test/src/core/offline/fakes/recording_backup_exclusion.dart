import 'package:pristie/src/core/error/app_failure.dart';
import 'package:pristie/src/core/offline/db/backup_exclusion.dart';
import 'package:pristie/src/core/result/result.dart';

/// Records backup-exclusion calls and can inject failures.
final class RecordingBackupExclusion implements BackupExclusion {
  final List<String> excludedPaths = <String>[];
  final Set<String> failingPaths = <String>{};

  @override
  Future<Result<void>> excludeFromBackup(String path) async {
    excludedPaths.add(path);
    if (failingPaths.contains(path)) {
      return const Result.err(AppFailure.localPersistence());
    }
    return const Result.ok(null);
  }
}
