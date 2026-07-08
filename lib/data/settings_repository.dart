import 'package:shared_preferences/shared_preferences.dart';

import '../domain/entities.dart';
import '../domain/repositories.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  static const _kCurrency = 'currencyCode';
  static const _kTheme = 'themeMode';
  static const _kLock = 'appLockEnabled';

  @override
  Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    return AppSettings(
      currencyCode: prefs.getString(_kCurrency) ?? 'USD',
      themeMode: AppThemeMode
          .values[prefs.getInt(_kTheme) ?? AppThemeMode.system.index],
      appLockEnabled: prefs.getBool(_kLock) ?? false,
    );
  }

  @override
  Future<void> save(AppSettings s) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kCurrency, s.currencyCode);
    await prefs.setInt(_kTheme, s.themeMode.index);
    await prefs.setBool(_kLock, s.appLockEnabled);
  }
}
