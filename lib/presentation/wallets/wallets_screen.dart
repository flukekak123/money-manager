import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../domain/entities.dart';
import '../../l10n/gen/app_localizations.dart';
import '../theme.dart';
import '../widgets/money_text.dart';

/// Localized label for a wallet type.
String walletTypeLabel(AppLocalizations l, WalletType type) => switch (type) {
      WalletType.cash => l.walletTypeCash,
      WalletType.bank => l.walletTypeBank,
      WalletType.card => l.walletTypeCard,
      WalletType.other => l.walletTypeOther,
    };

class WalletsScreen extends ConsumerWidget {
  const WalletsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallets = ref.watch(walletsProvider);
    final l = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l.wallets)),
      floatingActionButton: FloatingActionButton(
        key: const Key('add-wallet-fab'),
        onPressed: () => _showWalletDialog(context, ref),
        child: const Icon(Icons.add),
      ),
      body: wallets.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(l.errorWithMessage('$e'))),
        data: (list) => ListView(
          children: list
              .map((w) => _WalletTile(wallet: w))
              .toList(),
        ),
      ),
    );
  }

  Future<void> _showWalletDialog(BuildContext context, WidgetRef ref,
      {Wallet? existing}) async {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    var type = existing?.type ?? WalletType.cash;
    String? error;
    final l = AppLocalizations.of(context);

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(existing == null ? l.newWallet : l.editWallet),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(labelText: l.name),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<WalletType>(
                initialValue: type,
                decoration: InputDecoration(labelText: l.type),
                items: WalletType.values
                    .map((t) => DropdownMenuItem(
                        value: t, child: Text(walletTypeLabel(l, t))))
                    .toList(),
                onChanged: (v) => type = v ?? WalletType.cash,
              ),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(error!,
                      style:
                          TextStyle(color: Theme.of(ctx).colorScheme.error)),
                ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(l.cancel)),
            FilledButton(
              onPressed: () async {
                try {
                  await ref.read(walletControllerProvider).save(
                        id: existing?.id,
                        name: nameCtrl.text,
                        type: type,
                        iconCodePoint:
                            Icons.account_balance_wallet.codePoint,
                        colorValue: Colors.blue.toARGB32(),
                      );
                  if (ctx.mounted) Navigator.pop(ctx);
                } on DomainException catch (e) {
                  setLocal(() => error = e.message);
                }
              },
              child: Text(l.save),
            ),
          ],
        ),
      ),
    );
  }
}

class _WalletTile extends ConsumerWidget {
  const _WalletTile({required this.wallet});
  final Wallet wallet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balance = ref.watch(walletBalanceProvider(wallet.id));
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Color(wallet.colorValue).withValues(alpha: 0.18),
        child: Icon(iconFromCodePoint(wallet.iconCodePoint),
            color: Color(wallet.colorValue)),
      ),
      title: Text(wallet.name),
      subtitle: Text(walletTypeLabel(AppLocalizations.of(context), wallet.type)),
      trailing: balance.when(
        loading: () => const SizedBox(
            width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
        error: (_, _) => const Text('-'),
        data: (b) => MoneyText(b,
            colorBySign: true,
            style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
      onLongPress: () => _confirmDelete(context, ref),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context);
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.archive_outlined),
              title: Text(l.archive),
              onTap: () => Navigator.pop(ctx, 'archive'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: Text(l.delete),
              onTap: () => Navigator.pop(ctx, 'delete'),
            ),
          ],
        ),
      ),
    );
    if (action == null) return;
    try {
      if (action == 'archive') {
        await ref.read(walletControllerProvider).archive(wallet.id);
      } else {
        await ref.read(walletControllerProvider).delete(wallet.id);
      }
    } on DomainException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }
}
