import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../application/providers.dart';
import '../../domain/services/subscription_calculator.dart';
import '../../l10n/gen/app_localizations.dart';
import '../widgets/money_text.dart';
import 'subscription_edit_screen.dart';

/// Bottom sheet showing a subscription: amount/month, next charge, history,
/// edit + cancel actions (FR-5, BR-SB7).
Future<void> showSubscriptionSheet(BuildContext context, int subscriptionId) {
  return showModalBottomSheet(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => SubscriptionSheet(subscriptionId: subscriptionId),
  );
}

class SubscriptionSheet extends ConsumerWidget {
  const SubscriptionSheet({super.key, required this.subscriptionId});

  final int subscriptionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final money = ref.watch(moneyFormatterProvider);
    final sub = ref.watch(subscriptionsByIdProvider)[subscriptionId];
    final charges =
        ref.watch(subscriptionChargesProvider(subscriptionId)).asData?.value ??
            const [];

    if (sub == null) return const SizedBox(height: 120);

    final next =
        const SubscriptionCalculator().nextChargeDate(sub, DateTime.now());

    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(sub.name,
                    style: Theme.of(context).textTheme.titleLarge),
              ),
              IconButton(
                key: const Key('edit-subscription-button'),
                icon: const Icon(Icons.edit_outlined),
                onPressed: sub.active
                    ? () {
                        Navigator.of(context).pop();
                        Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) =>
                                SubscriptionEditScreen(existing: sub)));
                      }
                    : null,
              ),
            ],
          ),
          Text(l.perMonth(money.format(sub.amountMinor)),
              style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 4),
          Text(
            sub.active && next != null
                ? l.nextCharge(DateFormat.yMMMd().format(next))
                : l.cancelledLabel,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const Divider(height: 24),
          Text(l.chargeHistory,
              style: Theme.of(context).textTheme.titleSmall),
          for (final t in charges)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.autorenew),
              title: Text(DateFormat.yMMMd().format(t.date)),
              trailing: MoneyText(t.amountMinor),
            ),
          const SizedBox(height: 8),
          if (sub.active)
            OutlinedButton.icon(
              key: const Key('cancel-subscription-button'),
              icon: const Icon(Icons.cancel_outlined),
              style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error),
              label: Text(l.cancelSubscription),
              onPressed: () => _confirmCancel(context, ref),
            ),
        ],
      ),
    );
  }

  Future<void> _confirmCancel(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.cancelSubscription),
        content: Text(l.cancelSubscriptionBody),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false), child: Text(l.keep)),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l.cancelSubscription)),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(subscriptionControllerProvider).cancel(subscriptionId);
    if (context.mounted) Navigator.of(context).pop();
  }
}