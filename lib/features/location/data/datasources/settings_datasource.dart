import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persistence adapter for user preferences. Wraps `SharedPreferences` so
/// the rest of the app talks in domain language (`isBackgroundEnabled`)
/// rather than raw string keys.
@lazySingleton
class SettingsDataSource {
  /// Namespaced key — the `tracking.` prefix is a soft convention so we
  /// can grep all tracking-related prefs at once when we add more.
  static const _kBackgroundEnabled = 'tracking.background_enabled';

  Future<bool> isBackgroundEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kBackgroundEnabled) ?? false;
  }

  Future<void> setBackgroundEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kBackgroundEnabled, value);
  }
}