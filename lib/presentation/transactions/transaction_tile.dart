import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/entities.dart';
import '../widgets/category_avatar.dart';
import '../widgets/money_text.dart';

class TransactionTile extends StatelessWidget {
  const TransactionTile({
    super.key,
    required this.entry,
    this.category,
    this.plan,
    this.onTap,
  });

  final TransactionEntry entry;
  final Category? category;

  /// Installment plan this entry belongs to, when [entry.isInstallment].
  final InstallmentPlan? plan;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final title = category?.name ?? 'Uncategorized';
    final subtitle = [
      DateFormat.yMMMd().format(entry.date),
      if (entry.note != null && entry.note!.isNotEmpty) entry.note!,
    ].join(' · ');
    final months = plan?.months;

    return ListTile(
      key: Key('transaction-tile-${entry.id}'),
      leading: category != null
          ? CategoryAvatar(category: category!)
          : const CircleAvatar(child: Icon(Icons.help_outline)),
      title: entry.installmentNo == null
          ? Text(title)
          : Row(
              children: [
                Flexible(child: Text(title, overflow: TextOverflow.ellipsis)),
                const SizedBox(width: 6),
                // "k/N" installment badge (FR-5).
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    months == null
                        ? '${entry.installmentNo}'
                        : '${entry.installmentNo}/$months',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
              ],
            ),
      subtitle: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: MoneyText(
        entry.signedMinor,
        signed: true,
        colorBySign: true,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      onTap: onTap,
    );
  }
}
