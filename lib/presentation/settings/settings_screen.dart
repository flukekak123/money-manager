import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../domain/entities.dart';
import '../../l10n/gen/app_localizations.dart';
import '../categories/categories_screen.dart';
import '../wallets/wallets_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static const _currencies = ['USD', 'EUR', 'GBP', 'JPY', 'THB', 'INR', 'AUD', 'CAD'];

  // Language names are shown in their own script (self-endonyms).
  static const _languages = {'en': 'English', 'th': 'ไทย'};

  String _themeLabel(AppLocalizations l, AppThemeMode m) => switch (m) {
        AppThemeMode.system => l.themeSystem,
        AppThemeMode.light => l.themeLight,
        AppThemeMode.dark => l.themeDark,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final l = AppLocalizations.of(context);

    return settingsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(l.errorWithMessage('$e'))),
      data: (settings) => ListView(
        children: [
          _SectionHeader(l.manage),
          ListTile(
            leading: const Icon(Icons.account_balance_wallet_outlined),
            title: Text(l.wallets),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const WalletsScreen())),
          ),
          ListTile(
            leading: const Icon(Icons.category_outlined),
            title: Text(l.categories),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CategoriesScreen())),
          ),
          const Divider(),
          _SectionHeader(l.preferences),
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(l.language),
            trailing: DropdownButton<String>(
              value: settings.languageCode,
              items: _languages.entries
                  .map((e) =>
                      DropdownMenuItem(value: e.key, child: Text(e.value)))
                  .toList(),
              onChanged: (v) {
                if (v != null) notifier.setLanguage(v);
              },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.attach_money),
            title: Text(l.currency),
            trailing: DropdownButton<String>(
              value: _currencies.contains(settings.currencyCode)
                  ? settings.currencyCode
                  : null,
              hint: Text(settings.currencyCode),
              items: _currencies
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) {
                if (v != null) notifier.setCurrency(v);
              },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.brightness_6_outlined),
            title: Text(l.theme),
            trailing: DropdownButton<AppThemeMode>(
              value: settings.themeMode,
              items: AppThemeMode.values
                  .map((m) => DropdownMenuItem(
                      value: m, child: Text(_themeLabel(l, m))))
                  .toList(),
              onChanged: (v) {
                if (v != null) notifier.setThemeMode(v);
              },
            ),
          ),
          // App lock relies on biometric/device auth, unavailable on web.
          if (!kIsWeb)
            SwitchListTile(
              secondary: const Icon(Icons.lock_outline),
              title: Text(l.appLock),
              subtitle: Text(l.appLockSubtitle),
              value: settings.appLockEnabled,
              onChanged: (v) => notifier.setAppLockEnabled(v),
            ),
          const Divider(),
          _SectionHeader(l.dataSection),
          _BackupTiles(),
          const Divider(),
          AboutListTile(
            icon: const Icon(Icons.info_outline),
            applicationName: l.appTitle,
            applicationVersion: '1.0.0',
            aboutBoxChildren: [Text(l.aboutBody)],
          ),
        ],
      ),
    );
  }
}

/// Export / import tiles for the "Data" section. Restore replaces all current
/// data, so it is guarded by a confirmation dialog.
class _BackupTiles extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.download_outlined),
          title: Text(l.exportData),
          subtitle: Text(l.exportDataSubtitle),
          onTap: () => _export(context, ref),
        ),
        ListTile(
          leading: const Icon(Icons.upload_outlined),
          title: Text(l.importData),
          subtitle: Text(l.importDataSubtitle),
          onTap: () => _import(context, ref),
        ),
      ],
    );
  }

  Future<void> _export(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(backupControllerProvider).export();
      messenger.showSnackBar(SnackBar(content: Text(l.backupExported)));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(l.exportFailed('$e'))));
    }
  }

  Future<void> _import(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.replaceAllData),
        content: Text(l.replaceAllDataBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l.replace),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final done = await ref.read(backupControllerProvider).import();
      if (done) {
        messenger.showSnackBar(SnackBar(content: Text(l.backupRestored)));
      }
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(l.importFailed('$e'))));
    }
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(title,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary)),
    );
  }
}
