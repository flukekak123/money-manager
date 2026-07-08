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
    this.onTap,
  });

  final TransactionEntry entry;
  final Category? category;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final title = category?.name ?? 'Uncategorized';
    final subtitle = [
      DateFormat.yMMMd().format(entry.date),
      if (entry.note != null && entry.note!.isNotEmpty) entry.note!,
    ].join(' · ');

    return ListTile(
      key: Key('transaction-tile-${entry.id}'),
      leading: category != null
          ? CategoryAvatar(category: category!)
          : const CircleAvatar(child: Icon(Icons.help_outline)),
      title: Text(title),
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
