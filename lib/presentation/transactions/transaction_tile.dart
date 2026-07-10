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
    this.subscription,
    this.onTap,
  });

  final TransactionEntry entry;
  final Category? category;

  /// Installment plan this entry belongs to, when [entry.isInstallment].
  final InstallmentPlan? plan;

  /// Subscription this entry was charged by, when [entry.isSubscriptionCharge].
  final Subscription? subscription;
  final VoidCallback? onTap;

  Widget _badge(BuildContext context, Widget child) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: child,
      );

  @override
  Widget build(BuildContext context) {
    final title = category?.name ?? 'Uncategorized';
    final subtitle = [
      DateFormat.yMMMd().format(entry.date),
      if (entry.note != null && entry.note!.isNotEmpty) entry.note!,
    ].join(' · ');
    final months = plan?.months;
    final labelSmall = Theme.of(context).textTheme.labelSmall;

    Widget titleWidget = Text(title);
    if (entry.installmentNo != null) {
      // "k/N" installment badge (FR-5).
      titleWidget = Row(children: [
        Flexible(child: Text(title, overflow: TextOverflow.ellipsis)),
        const SizedBox(width: 6),
        _badge(
          context,
          Text(
            months == null
                ? '${entry.installmentNo}'
                : '${entry.installmentNo}/$months',
            style: labelSmall,
          ),
        ),
      ]);
    } else if (entry.isSubscriptionCharge) {
      // Subscription charge badge (Cycle 5 FR-5).
      titleWidget = Row(children: [
        Flexible(child: Text(title, overflow: TextOverflow.ellipsis)),
        const SizedBox(width: 6),
        _badge(
          context,
          Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.autorenew,
                size: 12, color: labelSmall?.color),
            if (subscription != null) ...[
              const SizedBox(width: 2),
              Text(subscription!.name, style: labelSmall),
            ],
          ]),
        ),
      ]);
    }

    return ListTile(
      key: Key('transaction-tile-${entry.id}'),
      leading: category != null
          ? CategoryAvatar(category: category!)
          : const CircleAvatar(child: Icon(Icons.help_outline)),
      title: titleWidget,
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
