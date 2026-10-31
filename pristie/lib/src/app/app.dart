import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:pristie/src/app/app_router.dart';
import 'package:pristie/src/core/auth/auth_state.dart';
import 'package:pristie/src/core/config/app_config.dart';
import 'package:pristie/src/l10n/strings.g.dart';
import 'package:pristie/src/shared/theme/app_theme.dart';

/// Minimal fail-closed application presented when startup configuration fails.
class ConfigErrorApp extends StatelessWidget {
  /// Creates a [ConfigErrorApp] displaying only the invalid or missing [failedKey] name.
  const ConfigErrorApp({required this.failedKey, super.key});

  /// Name of the configuration key causing startup failure.
  final String failedKey;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(child: Text('Configuration error: $failedKey')),
      ),
    );
  }
}

/// Root application widget configuring routing, theming, and localization.
class App extends StatelessWidget {
  /// Creates an [App] with runtime [config], [router], and initial [authState].
  const App({
    required this.config,
    required this.router,
    required this.authState,
    this.themeMode = ThemeMode.system,
    super.key,
  });

  /// The active application configuration.
  final AppConfig config;

  /// Root application router.
  final AppRouter router;

  /// Restored or resolved authentication state.
  final AuthState authState;

  /// Initial or dynamic theme mode.
  final ThemeMode themeMode;

  @override
  Widget build(BuildContext context) {
    return TranslationProvider(
      child: Builder(
        builder: (context) {
          return MaterialApp.router(
            title: config.appName,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: themeMode,
            locale: TranslationProvider.of(context).flutterLocale,
            supportedLocales: AppLocaleUtils.supportedLocales,
            routerConfig: router.config(
              deepLinkBuilder: (_) => DeepLink.defaultPath,
              reevaluateListenable: router.authGuard,
            ),
          );
        },
      ),
    );
  }
}
