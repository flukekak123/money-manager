import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../domain/entities.dart';
import '../categories/categories_screen.dart';
import '../wallets/wallets_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static const _currencies = ['USD', 'EUR', 'GBP', 'JPY', 'THB', 'INR', 'AUD', 'CAD'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return settingsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (settings) => ListView(
        children: [
          const _SectionHeader('Manage'),
          ListTile(
            leading: const Icon(Icons.account_balance_wallet_outlined),
            title: const Text('Wallets'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const WalletsScreen())),
          ),
          ListTile(
            leading: const Icon(Icons.category_outlined),
            title: const Text('Categories'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CategoriesScreen())),
          ),
          const Divider(),
          const _SectionHeader('Preferences'),
          ListTile(
            leading: const Icon(Icons.attach_money),
            title: const Text('Currency'),
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
            title: const Text('Theme'),
            trailing: DropdownButton<AppThemeMode>(
              value: settings.themeMode,
              items: AppThemeMode.values
                  .map((m) => DropdownMenuItem(value: m, child: Text(m.name)))
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
              title: const Text('App lock'),
              subtitle: const Text('Require biometric/device unlock on launch'),
              value: settings.appLockEnabled,
              onChanged: (v) => notifier.setAppLockEnabled(v),
            ),
          const Divider(),
          const _SectionHeader('Data'),
          _BackupTiles(),
          const Divider(),
          const AboutListTile(
            icon: Icon(Icons.info_outline),
            applicationName: 'Money Manager',
            applicationVersion: '1.0.0',
            aboutBoxChildren: [
              Text('Offline-first personal finance app. Data stays on device.'),
            ],
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
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.download_outlined),
          title: const Text('Export data'),
          subtitle: const Text('Save a JSON backup of all your data'),
          onTap: () => _export(context, ref),
        ),
        ListTile(
          leading: const Icon(Icons.upload_outlined),
          title: const Text('Import data'),
          subtitle: const Text('Restore from a JSON backup (replaces all data)'),
          onTap: () => _import(context, ref),
        ),
      ],
    );
  }

  Future<void> _export(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(backupControllerProvider).export();
      messenger.showSnackBar(
        const SnackBar(content: Text('Backup exported.')),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Export failed: $e')));
    }
  }

  Future<void> _import(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Replace all data?'),
        content: const Text(
            'Importing a backup will permanently replace all current wallets, '
            'categories, transactions, and budgets. This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Replace'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final done = await ref.read(backupControllerProvider).import();
      if (done) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Backup restored.')),
        );
      }
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Import failed: $e')));
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
