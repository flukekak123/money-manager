import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../domain/entities.dart';
import '../../l10n/gen/app_localizations.dart';
import '../widgets/empty_state.dart';
import '../widgets/money_text.dart';

class BudgetsScreen extends ConsumerWidget {
  const BudgetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(selectedMonthProvider);
    final progress = ref.watch(budgetProgressProvider(month));
    final catsById = ref.watch(categoriesByIdProvider);
    final l = AppLocalizations.of(context);

    return Column(
      children: [
        _MonthBar(month: month),
        Expanded(
          child: progress.isEmpty
              ? EmptyState(
                  icon: Icons.pie_chart_outline,
                  message: l.noBudgets,
                  hint: l.tapPlusBudget,
                )
              : ListView(
                  padding: const EdgeInsets.all(8),
                  children: progress
                      .map((p) => _BudgetRow(
                            progress: p,
                            category: catsById[p.budget.categoryId],
                          ))
                      .toList(),
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: FilledButton.icon(
            key: const Key('add-budget-button'),
            onPressed: () => _showBudgetDialog(context, ref, month),
            icon: const Icon(Icons.add),
            label: Text(l.addUpdateBudget),
          ),
        ),
      ],
    );
  }

  Future<void> _showBudgetDialog(
      BuildContext context, WidgetRef ref, String month) async {
    final expenseCats = (ref.read(categoriesProvider).asData?.value ??
            const <Category>[])
        .where((c) => c.kind == TransactionKind.expense)
        .toList();
    if (expenseCats.isEmpty) return;

    int? categoryId = expenseCats.first.id;
    final limitCtrl = TextEditingController();
    String? error;
    final l = AppLocalizations.of(context);

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(l.budget),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                initialValue: categoryId,
                decoration: InputDecoration(labelText: l.category),
                items: expenseCats
                    .map((c) =>
                        DropdownMenuItem(value: c.id, child: Text(c.name)))
                    .toList(),
                onChanged: (v) => categoryId = v,
              ),
              TextField(
                controller: limitCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: l.monthlyLimit),
              ),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(error!,
                      style: TextStyle(
                          color: Theme.of(ctx).colorScheme.error)),
                ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(l.cancel)),
            FilledButton(
              onPressed: () async {
                final cats = ref.read(categoriesByIdProvider);
                final category = cats[categoryId];
                if (category == null) return;
                try {
                  await ref.read(budgetControllerProvider).save(
                        category: category,
                        limitText: limitCtrl.text,
                        month: month,
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

class _MonthBar extends ConsumerWidget {
  const _MonthBar({required this.month});
  final String month;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(selectedMonthProvider.notifier);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => notifier.shift(-1),
          ),
          Text(month, style: Theme.of(context).textTheme.titleMedium),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => notifier.shift(1),
          ),
        ],
      ),
    );
  }
}

class _BudgetRow extends ConsumerWidget {
  const _BudgetRow({required this.progress, this.category});
  final BudgetProgress progress;
  final Category? category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pct = progress.percent.clamp(0.0, 1.0);
    final color = switch (progress.status) {
      BudgetStatus.ok => Colors.green,
      BudgetStatus.warn => Colors.orange,
      BudgetStatus.over => Colors.red,
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(category?.name ?? AppLocalizations.of(context).category,
                    style: Theme.of(context).textTheme.titleSmall),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  onPressed: () => ref
                      .read(budgetControllerProvider)
                      .delete(progress.budget.id),
                ),
              ],
            ),
            LinearProgressIndicator(value: pct, color: color, minHeight: 8),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
                  MoneyText(progress.spentMinor,
                      style: Theme.of(context).textTheme.bodyMedium),
                  Text(' / ',
                      style: Theme.of(context).textTheme.bodyMedium),
                  MoneyText(progress.limitMinor,
                      style: Theme.of(context).textTheme.bodyMedium),
                ]),
                Text(
                  progress.remainingMinor >= 0
                      ? '${(pct * 100).toStringAsFixed(0)}%'
                      : AppLocalizations.of(context).over,
                  style: TextStyle(color: color, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
