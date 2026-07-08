import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/entities.dart';
import 'providers.dart';

class SettingsNotifier extends AsyncNotifier<AppSettings> {
  @override
  Future<AppSettings> build() {
    return ref.watch(settingsRepositoryProvider).load();
  }

  Future<void> _persist(AppSettings s) async {
    state = AsyncData(s);
    await ref.read(settingsRepositoryProvider).save(s);
  }

  Future<void> setCurrency(String code) async {
    final current = state.asData?.value;
    if (current == null) return;
    await _persist(current.copyWith(currencyCode: code));
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    final current = state.asData?.value;
    if (current == null) return;
    await _persist(current.copyWith(themeMode: mode));
  }

  Future<void> setAppLockEnabled(bool enabled) async {
    final current = state.asData?.value;
    if (current == null) return;
    await _persist(current.copyWith(appLockEnabled: enabled));
  }
}
