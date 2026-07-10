import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../application/providers.dart';
import '../../core/money.dart';
import '../../domain/entities.dart';
import '../../domain/services/subscription_calculator.dart';
import '../../l10n/gen/app_localizations.dart';
import '../widgets/empty_state.dart';
import 'subscription_edit_screen.dart';
import 'subscription_sheet.dart';

class SubscriptionsScreen extends ConsumerWidget {
  const SubscriptionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final money = ref.watch(moneyFormatterProvider);
    final subsAsync = ref.watch(subscriptionsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l.subscriptions)),
      floatingActionButton: FloatingActionButton(
        key: const Key('add-subscription-fab'),
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => const SubscriptionEditScreen())),
        child: const Icon(Icons.add),
      ),
      body: subsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(l.errorWithMessage('$e'))),
        data: (subs) {
          if (subs.isEmpty) {
            return EmptyState(
              icon: Icons.autorenew,
              message: l.noSubscriptions,
              hint: l.addSubscriptionHint,
            );
          }
          return ListView(
            children: [
              for (final s in subs) _tile(context, l, money, s),
            ],
          );
        },
      ),
    );
  }

  Widget _tile(BuildContext context, AppLocalizations l, MoneyFormatter money,
      Subscription s) {
    final next =
        const SubscriptionCalculator().nextChargeDate(s, DateTime.now());
    return ListTile(
      key: Key('subscription-tile-${s.id}'),
      leading: CircleAvatar(
        child: Icon(s.active ? Icons.autorenew : Icons.cancel_outlined),
      ),
      title: Text(s.name),
      subtitle: Text(
        s.active && next != null
            ? l.nextCharge(DateFormat.yMMMd().format(next))
            : l.cancelledLabel,
      ),
      trailing: Text(
        l.perMonth(money.format(s.amountMinor)),
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      onTap: () => showSubscriptionSheet(context, s.id),
    );
  }
}