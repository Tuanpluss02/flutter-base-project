import 'package:injectable/injectable.dart';
import 'package:base/src/core/storage/adapters/flutter_secure_storage_adapter.dart';
import 'package:base/src/core/storage/adapters/shared_preferences_adapter.dart';
import 'package:base/src/core/storage/local_storage.dart';
import 'package:base/src/core/storage/secure_session_store.dart';
import 'package:base/src/core/storage/secure_storage.dart';
import 'package:base/src/core/storage/session_token_provider.dart';

@module
abstract class StorageModule {
  @lazySingleton
  SecureStorage get secureStorage => FlutterSecureStorageAdapter();

  @lazySingleton
  LocalStorage get localStorage => SharedPreferencesAdapter();

  @lazySingleton
  SessionTokenProvider sessionTokenProvider(SecureStorage secureStorage) =>
      SecureSessionStore(secureStorage: secureStorage);
}
