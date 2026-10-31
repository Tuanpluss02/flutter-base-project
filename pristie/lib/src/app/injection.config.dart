// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'package:dio/dio.dart' as _i361;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;
import 'package:pristie/src/app/app_router.dart' as _i136;
import 'package:pristie/src/app/guards/auth_guard.dart' as _i982;
import 'package:pristie/src/app/modules/network_module.dart' as _i972;
import 'package:pristie/src/app/modules/router_module.dart' as _i196;
import 'package:pristie/src/app/modules/storage_module.dart' as _i794;
import 'package:pristie/src/core/auth/auth_coordinator.dart' as _i132;
import 'package:pristie/src/core/auth/auth_session_controller.dart' as _i1028;
import 'package:pristie/src/core/auth/session_service.dart' as _i102;
import 'package:pristie/src/core/auth/session_state_sink.dart' as _i545;
import 'package:pristie/src/core/config/app_config.dart' as _i118;
import 'package:pristie/src/core/network/api_client.dart' as _i863;
import 'package:pristie/src/core/network/token_refresher.dart' as _i393;
import 'package:pristie/src/core/observability/app_logger.dart' as _i350;
import 'package:pristie/src/core/observability/crash_reporter.dart' as _i1027;
import 'package:pristie/src/core/storage/local_storage.dart' as _i1;
import 'package:pristie/src/core/storage/secure_storage.dart' as _i472;
import 'package:pristie/src/core/storage/session_token_provider.dart' as _i451;

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
    gh.lazySingleton<_i1027.CrashReporter>(() => networkModule.crashReporter);
    gh.lazySingleton<_i472.SecureStorage>(() => storageModule.secureStorage);
    gh.lazySingleton<_i1.LocalStorage>(() => storageModule.localStorage);
    gh.lazySingleton<_i451.SessionTokenProvider>(
      () => storageModule.sessionTokenProvider(gh<_i472.SecureStorage>()),
    );
    gh.lazySingleton<_i350.AppLogger>(
      () => networkModule.appLogger(gh<_i118.AppConfig>()),
    );
    gh.lazySingleton<_i393.TokenRefresher>(
      () => networkModule.tokenRefresher(gh<_i118.AppConfig>()),
    );
    gh.lazySingleton<_i102.SessionService>(
      () => networkModule.sessionService(gh<_i451.SessionTokenProvider>()),
    );
    gh.lazySingleton<_i1028.AuthSessionController>(
      () => networkModule.authSessionController(gh<_i102.SessionService>()),
    );
    gh.lazySingleton<_i545.SessionStateSink>(
      () => networkModule.sessionStateSink(gh<_i102.SessionService>()),
    );
    gh.lazySingleton<_i982.AuthGuard>(
      () => routerModule.authGuard(gh<_i1028.AuthSessionController>()),
    );
    gh.lazySingleton<_i132.AuthCoordinator>(
      () => networkModule.authCoordinator(
        gh<_i451.SessionTokenProvider>(),
        gh<_i1028.AuthSessionController>(),
        gh<_i393.TokenRefresher>(),
      ),
    );
    gh.lazySingleton<_i361.Dio>(
      () => networkModule.dio(
        gh<_i118.AppConfig>(),
        gh<_i451.SessionTokenProvider>(),
        gh<_i1028.AuthSessionController>(),
        gh<_i132.AuthCoordinator>(),
        gh<_i350.AppLogger>(),
      ),
    );
    gh.lazySingleton<_i863.ApiClient>(
      () => networkModule.apiClient(gh<_i361.Dio>()),
    );
    gh.lazySingleton<_i136.AppRouter>(
      () => routerModule.appRouter(gh<_i982.AuthGuard>()),
    );
    return this;
  }
}

class _$NetworkModule extends _i972.NetworkModule {}

class _$StorageModule extends _i794.StorageModule {}

class _$RouterModule extends _i196.RouterModule {}
