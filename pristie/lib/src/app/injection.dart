import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:pristie/src/app/injection.config.dart';
import 'package:pristie/src/core/config/app_config.dart';

final getIt = GetIt.instance;

@InjectableInit()
Future<void> configureDependencies({required AppConfig config}) async {
  if (getIt.isRegistered<AppConfig>()) {
    await getIt.reset();
  }
  getIt.registerSingleton<AppConfig>(config);
  getIt.init();
}
