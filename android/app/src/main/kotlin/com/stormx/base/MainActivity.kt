package com.stormx.base

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

/**
 * Registers the backup-exclusion channel. Android backup is disabled for the
 * entire application in AndroidManifest.xml, so this handler only validates
 * that the requested path stays inside the app sandbox.
 */
class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.stormx.base/backup_exclusion")
            .setMethodCallHandler { call, result ->
                if (call.method != "excludeFromBackup") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val path = call.argument<String>("path")
                val root = filesDir.parentFile?.canonicalPath
                if (path == null || root == null || !File(path).canonicalPath.startsWith(root + File.separator)) {
                    result.error("invalid_path", "Path outside application storage", null)
                    return@setMethodCallHandler
                }
                result.success(null)
            }
    }
}
