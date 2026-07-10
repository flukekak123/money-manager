import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../application/providers.dart';
import '../../domain/entities.dart';
import '../../l10n/gen/app_localizations.dart';
import '../subscriptions/subscription_sheet.dart';
import '../widgets/empty_state.dart';
import 'installment_plan_sheet.dart';
import 'transaction_edit_screen.dart';
import 'transaction_tile.dart';

class TransactionsScreen extends ConsumerWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txnsAsync = ref.watch(allTransactionsProvider);
    final catsById = ref.watch(categoriesByIdProvider);
    final plansById = ref.watch(installmentPlansByIdProvider);
    final subsById = ref.watch(subscriptionsByIdProvider);
    final l = AppLocalizations.of(context);

    return txnsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(l.errorWithMessage('$e'))),
      data: (txns) {
        if (txns.isEmpty) {
          return EmptyState(
            icon: Icons.receipt_long_outlined,
            message: l.noTransactionsYet,
            hint: l.tapAddFirst,
          );
        }
        // Group by day.
        final groups = <String, List<TransactionEntry>>{};
        for (final t in txns) {
          final key = DateFormat.yMMMEd().format(t.date);
          groups.putIfAbsent(key, () => []).add(t);
        }
        final dayKeys = groups.keys.toList();

        return ListView.builder(
          itemCount: dayKeys.length,
          itemBuilder: (context, i) {
            final day = dayKeys[i];
            final items = groups[day]!;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                  child: Text(day,
                      style: Theme.of(context).textTheme.labelLarge),
                ),
                ...items.map((t) => Dismissible(
                      key: Key('dismiss-${t.id}'),
                      // Generated rows (installments BR-I4, subscription
                      // charges BR-SB4) are managed via plan/subscription:
                      // no swipe-delete, tap opens the sheet.
                      direction: t.isInstallment || t.isSubscriptionCharge
                          ? DismissDirection.none
                          : DismissDirection.endToStart,
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      confirmDismiss: (_) => _confirmDelete(context),
                      onDismissed: (_) => ref
                          .read(transactionControllerProvider)
                          .delete(t.id),
                      child: TransactionTile(
                        entry: t,
                        category: catsById[t.categoryId],
                        plan: t.installmentPlanId == null
                            ? null
                            : plansById[t.installmentPlanId],
                        subscription: t.subscriptionId == null
                            ? null
                            : subsById[t.subscriptionId],
                        onTap: () {
                          if (t.isInstallment) {
                            showInstallmentPlanSheet(
                                context, t.installmentPlanId!);
                          } else if (t.isSubscriptionCharge) {
                            showSubscriptionSheet(context, t.subscriptionId!);
                          } else {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    TransactionEditScreen(existing: t),
                              ),
                            );
                          }
                        },
                      ),
                    )),
              ],
            );
          },
        );
      },
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final l = AppLocalizations.of(context);
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.deleteTransactionTitle),
        content: Text(l.cannotBeUndone),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l.cancel)),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l.delete)),
        ],
      ),
    );
    return result ?? false;
  }
}
