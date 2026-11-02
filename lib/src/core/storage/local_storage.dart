/// Local non-sensitive key-value preferences storage contract.
abstract interface class LocalStorage {
  /// Initializes underlying platform storage resources.
  Future<void> init();

  /// Retrieves the string value associated with [key].
  String? getString(String key);

  /// Persists [value] under [key].
  Future<void> setString(String key, String value);

  /// Removes the entry associated with [key].
  Future<void> remove(String key);
}
