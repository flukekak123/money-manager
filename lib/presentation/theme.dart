import 'package:flutter/material.dart';

import '../domain/entities.dart';

const _seed = Color(0xFF2E7D32); // green

ThemeData buildLightTheme() => ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: _seed),
      useMaterial3: true,
    );

ThemeData buildDarkTheme() => ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: _seed,
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
    );

ThemeMode toFlutterThemeMode(AppThemeMode mode) {
  switch (mode) {
    case AppThemeMode.system:
      return ThemeMode.system;
    case AppThemeMode.light:
      return ThemeMode.light;
    case AppThemeMode.dark:
      return ThemeMode.dark;
  }
}

/// Icon helper: rebuild an [IconData] from a stored code point.
IconData iconFromCodePoint(int codePoint) =>
    IconData(codePoint, fontFamily: 'MaterialIcons');

/// Colors for income (green) / expense (red) amounts.
class AmountColors {
  static Color of(BuildContext context, int signedMinor) {
    final scheme = Theme.of(context).colorScheme;
    if (signedMinor > 0) return Colors.green.shade600;
    if (signedMinor < 0) return scheme.error;
    return scheme.onSurface;
  }
}
