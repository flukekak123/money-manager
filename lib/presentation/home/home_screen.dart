import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../core/date_utils.dart';
import '../../domain/entities.dart';
import '../../l10n/gen/app_localizations.dart';
import '../subscriptions/subscription_sheet.dart';
import '../transactions/installment_plan_sheet.dart';
import '../transactions/transaction_edit_screen.dart';
import '../transactions/transaction_tile.dart';
import '../widgets/empty_state.dart';
import '../widgets/money_text.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = MonthKey.current();
    final summary = ref.watch(monthSummaryProvider(month));
    final budgets = ref.watch(budgetProgressProvider(month));
    final txnsAsync = ref.watch(monthTransactionsProvider(month));
    final catsById = ref.watch(categoriesByIdProvider);
    final l = AppLocalizations.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SummaryCard(summary: summary),
        const SizedBox(height: 16),
        if (budgets.isNotEmpty) ...[
          Text(l.navBudgets, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...budgets.take(3).map((p) => _BudgetMiniRow(
                progress: p,
                category: catsById[p.budget.categoryId],
              )),
          const SizedBox(height: 16),
        ],
        Text(l.recent, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        txnsAsync.when(
          loading: () => const Center(child: Padding(
            padding: EdgeInsets.all(24), child: CircularProgressIndicator())),
          error: (e, _) => Text(l.errorWithMessage('$e')),
          data: (txns) {
            if (txns.isEmpty) {
              return EmptyState(
                icon: Icons.receipt_long_outlined,
                message: l.noTransactionsYet,
                hint: l.tapAddToRecord,
              );
            }
            return Column(
              children: txns
                  .take(10)
                  .map((t) => TransactionTile(
                        entry: t,
                        category: catsById[t.categoryId],
                        plan: t.installmentPlanId == null
                            ? null
                            : ref.watch(installmentPlansByIdProvider)[
                                t.installmentPlanId],
                        subscription: t.subscriptionId == null
                            ? null
                            : ref.watch(
                                subscriptionsByIdProvider)[t.subscriptionId],
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
                      ))
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.summary});
  final PeriodSummary summary;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.thisMonth, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _Metric(label: l.income, amountMinor: summary.incomeMinor),
                _Metric(label: l.expense, amountMinor: -summary.expenseMinor),
                _Metric(label: l.balance, amountMinor: summary.netMinor, bold: true),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.amountMinor, this.bold = false});
  final String label;
  final int amountMinor;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 4),
        MoneyText(
          amountMinor,
          colorBySign: true,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: bold ? FontWeight.bold : FontWeight.w600,
              ),
        ),
      ],
    );
  }
}

class _BudgetMiniRow extends StatelessWidget {
  const _BudgetMiniRow({required this.progress, this.category});
  final BudgetProgress progress;
  final Category? category;

  @override
  Widget build(BuildContext context) {
    final pct = progress.percent.clamp(0.0, 1.0);
    final color = switch (progress.status) {
      BudgetStatus.ok => Colors.green,
      BudgetStatus.warn => Colors.orange,
      BudgetStatus.over => Colors.red,
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(category?.name ?? AppLocalizations.of(context).category),
              MoneyText(progress.spentMinor,
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(value: pct, color: color),
        ],
      ),
    );
  }
}
