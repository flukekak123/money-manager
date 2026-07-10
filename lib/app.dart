import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'application/providers.dart';
import 'domain/entities.dart';
import 'l10n/gen/app_localizations.dart';
import 'presentation/app_lock_gate.dart';
import 'presentation/main_shell.dart';
import 'presentation/theme.dart';

class MoneyManagerApp extends ConsumerWidget {
  const MoneyManagerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Kick off subscription charge materialization once per launch (FR-2).
    // FutureProvider caches; errors stay contained in its AsyncValue.
    ref.watch(subscriptionMaterializeOnLaunchProvider);
    final settings = ref.watch(settingsProvider).asData?.value;
    final themeMode = settings?.themeMode ?? AppThemeMode.system;
    final languageCode = settings?.languageCode ?? 'en';

    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: toFlutterThemeMode(themeMode),
      locale: Locale(languageCode),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: const AppLockGate(child: MainShell()),
    );
  }
}
