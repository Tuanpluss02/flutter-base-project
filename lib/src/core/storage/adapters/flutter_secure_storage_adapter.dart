import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:base/src/core/storage/secure_storage.dart';

/// Secure storage adapter wrapping [FlutterSecureStorage] with hardened options.
final class FlutterSecureStorageAdapter implements SecureStorage {
  /// Creates a [FlutterSecureStorageAdapter] configured with device-bound keychain access and safe error reset options.
  FlutterSecureStorageAdapter({FlutterSecureStorage? storage})
    : _storage =
          storage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(resetOnError: false),
            iOptions: IOSOptions(
              accessibility: KeychainAccessibility.unlocked_this_device,
            ),
          );

  final FlutterSecureStorage _storage;

  @override
  Future<void> init() async {}

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);

  @override
  Future<void> clear() => _storage.deleteAll();
}
