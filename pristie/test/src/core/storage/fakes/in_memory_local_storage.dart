import 'package:pristie/src/core/storage/local_storage.dart';

/// In-memory fake implementation of [LocalStorage] for testing.
final class InMemoryLocalStorage implements LocalStorage {
  final Map<String, String> _storage = <String, String>{};

  /// When true, [init] throws an exception.
  bool shouldFailInit = false;

  /// Direct inspection of stored entries.
  Map<String, String> get entries => Map<String, String>.unmodifiable(_storage);

  @override
  Future<void> init() async {
    if (shouldFailInit) {
      throw Exception('Local storage init failed');
    }
  }

  @override
  String? getString(String key) => _storage[key];

  @override
  Future<void> setString(String key, String value) async {
    _storage[key] = value;
  }

  @override
  Future<void> remove(String key) async {
    _storage.remove(key);
  }
}
