import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:pristie/src/app/app_router.dart';
import 'package:pristie/src/core/auth/auth_state.dart';
import 'package:pristie/src/core/config/app_config.dart';
import 'package:pristie/src/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:pristie/generated/l10n/strings.g.dart';
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
    this.settingsCubit,
    this.themeMode = ThemeMode.system,
    super.key,
  });

  /// The active application configuration.
  final AppConfig config;

  /// Root application router.
  final AppRouter router;

  /// Restored or resolved authentication state.
  final AuthState authState;

  /// Settings state driving theme and locale changes at runtime.
  final SettingsCubit? settingsCubit;

  /// Fallback theme mode when [settingsCubit] is not supplied.
  final ThemeMode themeMode;

  @override
  Widget build(BuildContext context) {
    return TranslationProvider(
      child: Builder(
        builder: (context) {
          final settings = settingsCubit;
          if (settings == null) {
            return _buildRouterApp(context, themeMode);
          }
          return BlocBuilder<SettingsCubit, SettingsState>(
            bloc: settings,
            builder: (context, state) =>
                _buildRouterApp(context, state.themeMode),
          );
        },
      ),
    );
  }

  Widget _buildRouterApp(BuildContext context, ThemeMode mode) {
    return MaterialApp.router(
      title: config.appName,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: mode,
      locale: TranslationProvider.of(context).flutterLocale,
      supportedLocales: AppLocaleUtils.supportedLocales,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      routerConfig: router.config(
        deepLinkBuilder: (_) => DeepLink.defaultPath,
        reevaluateListenable: router.authGuard,
      ),
    );
  }
}
