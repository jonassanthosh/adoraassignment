import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

@lazySingleton
class SettingsDataSource {
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