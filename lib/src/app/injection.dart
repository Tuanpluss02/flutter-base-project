import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:base/src/app/injection.config.dart';
import 'package:base/src/core/config/app_config.dart';
import 'package:base/src/features/auth_placeholder/auth_placeholder.dart';
import 'package:base/src/features/home/home.dart';
import 'package:base/src/features/settings/settings.dart';

final getIt = GetIt.instance;

@InjectableInit()
Future<void> configureDependencies({required AppConfig config}) async {
  if (getIt.isRegistered<AppConfig>()) {
    await getIt.reset();
  }
  getIt.registerSingleton<AppConfig>(config);
  getIt.init();
  registerAuthPlaceholder(getIt);
  registerHome(getIt);
  registerSettings(getIt);
}
