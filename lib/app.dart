import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'application/providers.dart';
import 'domain/entities.dart';
import 'presentation/app_lock_gate.dart';
import 'presentation/main_shell.dart';
import 'presentation/theme.dart';

class MoneyManagerApp extends ConsumerWidget {
  const MoneyManagerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(settingsProvider).asData?.value.themeMode ??
        AppThemeMode.system;
    return MaterialApp(
      title: 'Money Manager',
      debugShowCheckedModeBanner: false,
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: toFlutterThemeMode(themeMode),
      home: const AppLockGate(child: MainShell()),
    );
  }
}
