import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pristie/src/app/app.dart';
import 'package:pristie/src/app/app_router.dart';
import 'package:pristie/src/app/injection.dart';
import 'package:pristie/src/app/observability/app_bloc_observer.dart';
import 'package:pristie/src/app/observability/error_handlers.dart';
import 'package:pristie/src/core/auth/auth_state.dart';
import 'package:pristie/src/core/auth/session_service.dart';
import 'package:pristie/src/core/config/app_config.dart';
import 'package:pristie/src/core/observability/app_logger.dart';
import 'package:pristie/src/core/observability/crash_reporter.dart';
import 'package:pristie/src/core/storage/local_storage.dart';
import 'package:pristie/src/core/storage/secure_storage.dart';
import 'package:pristie/src/core/storage/session_token_provider.dart';

/// Initializes application infrastructure, executes fail-closed checks, and launches root UI.
Future<void> bootstrap({
  AppConfig Function()? configProvider,
  Future<void> Function()? storageInitializer,
  void Function(Widget)? runner,
}) async {
  WidgetsFlutterBinding.ensureInitialized();

  final AppConfig config;
  try {
    config = (configProvider != null)
        ? configProvider()
        : AppConfig.fromEnvironment();
  } on AppConfigException catch (e) {
    (runner ?? runApp)(ConfigErrorApp(failedKey: e.key));
    return;
  }

  await configureDependencies(config: config);

  var authState = AuthState.locked;
  try {
    if (storageInitializer != null) {
      await storageInitializer();
    } else {
      await getIt<SecureStorage>().init();
      await getIt<LocalStorage>().init();
      final installMarker = getIt<LocalStorage>().getString('install_marker');
      if (installMarker == null) {
        await getIt<SessionTokenProvider>().clearSession();
        await getIt<LocalStorage>().setString('install_marker', 'v1');
      }
      authState = await getIt<SessionService>().restore();
    }
  } catch (error, stackTrace) {
    authState = AuthState.locked;
    if (getIt.isRegistered<AppLogger>()) {
      getIt<AppLogger>().error(
        'bootstrap_storage_failure',
        fields: const {'stage': 'storage_init'},
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  final router = getIt<AppRouter>();
  Bloc.observer = AppBlocObserver(logger: getIt<AppLogger>());
  installErrorHandlers(getIt<CrashReporter>());

  (runner ?? runApp)(App(config: config, router: router, authState: authState));
}
