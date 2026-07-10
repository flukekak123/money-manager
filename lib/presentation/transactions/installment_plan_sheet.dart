import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../application/providers.dart';
import '../../l10n/gen/app_localizations.dart';
import '../widgets/money_text.dart';

/// Bottom sheet showing an installment plan: total, progress and all its
/// installments, with whole-plan delete (FR-4/FR-5, BR-I9).
Future<void> showInstallmentPlanSheet(BuildContext context, int planId) {
  return showModalBottomSheet(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => InstallmentPlanSheet(planId: planId),
  );
}

class InstallmentPlanSheet extends ConsumerWidget {
  const InstallmentPlanSheet({super.key, required this.planId});

  final int planId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final plan = ref.watch(installmentPlansByIdProvider)[planId];
    final installments =
        ref.watch(planInstallmentsProvider(planId)).asData?.value ?? const [];
    final catsById = ref.watch(categoriesByIdProvider);

    if (plan == null) {
      // Plan was deleted while the sheet was open.
      return const SizedBox(height: 120);
    }

    final now = DateTime.now();
    // BR-I9: paid = installments due today or earlier.
    final paid = installments.where((t) => !t.date.isAfter(now)).length;
    final category = catsById[plan.categoryId];

    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Text(l.installmentPlanTitle,
              style: Theme.of(context).textTheme.titleLarge),
          if (category != null) ...[
            const SizedBox(height: 4),
            Text(category.name,
                style: Theme.of(context).textTheme.bodyMedium),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l.total),
              MoneyText(plan.totalMinor,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
              value: plan.months == 0 ? 0 : paid / plan.months),
          const SizedBox(height: 4),
          Text(l.installmentProgress('$paid', '${plan.months}'),
              style: Theme.of(context).textTheme.bodySmall),
          const Divider(height: 24),
          for (final t in installments)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                t.date.isAfter(now)
                    ? Icons.schedule
                    : Icons.check_circle_outline,
                color: t.date.isAfter(now)
                    ? Theme.of(context).colorScheme.outline
                    : Theme.of(context).colorScheme.primary,
              ),
              title: Text(l.installmentNoLabel('${t.installmentNo}')),
              subtitle: Text(DateFormat.yMMMd().format(t.date)),
              trailing: MoneyText(t.amountMinor),
            ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            key: const Key('delete-installment-plan-button'),
            icon: const Icon(Icons.delete_outline),
            style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error),
            label: Text(l.deletePlan),
            onPressed: () => _confirmDelete(context, ref, plan.months),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, int count) async {
    final l = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.deletePlan),
        content: Text(l.deletePlanBody('$count')),
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
    if (confirmed != true) return;
    await ref.read(transactionControllerProvider).deleteInstallmentPlan(planId);
    if (context.mounted) Navigator.of(context).pop(); // close the sheet
  }
}