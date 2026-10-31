import 'package:pristie/src/core/storage/secure_storage.dart';

/// In-memory fake implementation of [SecureStorage] with error injection for testing.
final class InMemorySecureStorage implements SecureStorage {
  final Map<String, String> _storage = <String, String>{};

  /// When true, [init] throws an exception.
  bool shouldFailInit = false;

  /// When true, [read] throws an exception.
  bool shouldFailRead = false;

  /// When true, [write] throws an exception.
  bool shouldFailWrite = false;

  /// When true, [delete] throws an exception.
  bool shouldFailDelete = false;

  /// When true, [clear] throws an exception.
  bool shouldFailClear = false;

  /// Direct inspection of stored entries.
  Map<String, String> get entries => Map<String, String>.unmodifiable(_storage);

  @override
  Future<void> init() async {
    if (shouldFailInit) {
      throw Exception('Secure storage init failed');
    }
  }

  @override
  Future<String?> read(String key) async {
    if (shouldFailRead) {
      throw Exception('Secure storage read failed');
    }
    return _storage[key];
  }

  @override
  Future<void> write(String key, String value) async {
    if (shouldFailWrite) {
      throw Exception('Secure storage write failed');
    }
    _storage[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    if (shouldFailDelete) {
      throw Exception('Secure storage delete failed');
    }
    _storage.remove(key);
  }

  @override
  Future<void> clear() async {
    if (shouldFailClear) {
      throw Exception('Secure storage clear failed');
    }
    _storage.clear();
  }
}
