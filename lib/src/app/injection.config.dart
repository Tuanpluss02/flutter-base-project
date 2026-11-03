// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'package:base/src/app/app_router.dart' as _i996;
import 'package:base/src/app/guards/auth_guard.dart' as _i1063;
import 'package:base/src/app/modules/network_module.dart' as _i1045;
import 'package:base/src/app/modules/router_module.dart' as _i448;
import 'package:base/src/app/modules/storage_module.dart' as _i509;
import 'package:base/src/core/auth/auth_coordinator.dart' as _i222;
import 'package:base/src/core/auth/auth_session_controller.dart' as _i205;
import 'package:base/src/core/auth/session_service.dart' as _i774;
import 'package:base/src/core/auth/session_state_sink.dart' as _i550;
import 'package:base/src/core/config/app_config.dart' as _i38;
import 'package:base/src/core/network/api_client.dart' as _i972;
import 'package:base/src/core/network/token_refresher.dart' as _i1064;
import 'package:base/src/core/observability/app_logger.dart' as _i874;
import 'package:base/src/core/observability/crash_reporter.dart' as _i332;
import 'package:base/src/core/storage/local_storage.dart' as _i256;
import 'package:base/src/core/storage/secure_storage.dart' as _i11;
import 'package:base/src/core/storage/session_token_provider.dart' as _i651;
import 'package:dio/dio.dart' as _i361;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final networkModule = _$NetworkModule();
    final storageModule = _$StorageModule();
    final routerModule = _$RouterModule();
    gh.lazySingleton<_i332.CrashReporter>(() => networkModule.crashReporter);
    gh.lazySingleton<_i11.SecureStorage>(() => storageModule.secureStorage);
    gh.lazySingleton<_i256.LocalStorage>(() => storageModule.localStorage);
    gh.lazySingleton<_i874.AppLogger>(
      () => networkModule.appLogger(gh<_i38.AppConfig>()),
    );
    gh.lazySingleton<_i1064.TokenRefresher>(
      () => networkModule.tokenRefresher(gh<_i38.AppConfig>()),
    );
    gh.lazySingleton<_i651.SessionTokenProvider>(
      () => storageModule.sessionTokenProvider(gh<_i11.SecureStorage>()),
    );
    gh.lazySingleton<_i774.SessionService>(
      () => networkModule.sessionService(gh<_i651.SessionTokenProvider>()),
    );
    gh.lazySingleton<_i205.AuthSessionController>(
      () => networkModule.authSessionController(gh<_i774.SessionService>()),
    );
    gh.lazySingleton<_i550.SessionStateSink>(
      () => networkModule.sessionStateSink(gh<_i774.SessionService>()),
    );
    gh.lazySingleton<_i1063.AuthGuard>(
      () => routerModule.authGuard(gh<_i205.AuthSessionController>()),
    );
    gh.lazySingleton<_i222.AuthCoordinator>(
      () => networkModule.authCoordinator(
        gh<_i651.SessionTokenProvider>(),
        gh<_i205.AuthSessionController>(),
        gh<_i1064.TokenRefresher>(),
      ),
    );
    gh.lazySingleton<_i996.AppRouter>(
      () => routerModule.appRouter(gh<_i1063.AuthGuard>()),
    );
    gh.lazySingleton<_i361.Dio>(
      () => networkModule.dio(
        gh<_i38.AppConfig>(),
        gh<_i651.SessionTokenProvider>(),
        gh<_i205.AuthSessionController>(),
        gh<_i222.AuthCoordinator>(),
        gh<_i874.AppLogger>(),
      ),
    );
    gh.lazySingleton<_i972.ApiClient>(
      () => networkModule.apiClient(gh<_i361.Dio>()),
    );
    return this;
  }
}

class _$NetworkModule extends _i1045.NetworkModule {}

class _$StorageModule extends _i509.StorageModule {}

class _$RouterModule extends _i448.RouterModule {}
