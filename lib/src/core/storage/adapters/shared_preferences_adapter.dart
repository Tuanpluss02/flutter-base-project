import 'package:pristie/src/core/storage/local_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local preferences storage adapter wrapping [SharedPreferences] for non-sensitive data.
final class SharedPreferencesAdapter implements LocalStorage {
  /// Creates a [SharedPreferencesAdapter] with an optional pre-initialized [preferences] instance.
  SharedPreferencesAdapter({this.preferences});

  /// The underlying [SharedPreferences] instance.
  SharedPreferences? preferences;

  @override
  Future<void> init() async {
    preferences ??= await SharedPreferences.getInstance();
  }

  @override
  String? getString(String key) => preferences?.getString(key);

  @override
  Future<void> setString(String key, String value) async {
    final prefs = preferences ?? await SharedPreferences.getInstance();
    preferences = prefs;
    await prefs.setString(key, value);
  }

  @override
  Future<void> remove(String key) async {
    final prefs = preferences ?? await SharedPreferences.getInstance();
    preferences = prefs;
    await prefs.remove(key);
  }
}
