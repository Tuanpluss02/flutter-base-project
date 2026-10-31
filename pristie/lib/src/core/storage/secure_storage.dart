/// Low-level secure key-value storage contract.
abstract interface class SecureStorage {
  /// Initializes underlying platform storage resources.
  Future<void> init();

  /// Reads the string value associated with [key].
  Future<String?> read(String key);

  /// Persists [value] securely under [key].
  Future<void> write(String key, String value);

  /// Deletes the entry stored under [key].
  Future<void> delete(String key);

  /// Clears all entries in secure storage.
  Future<void> clear();
}
