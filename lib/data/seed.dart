import 'package:drift/drift.dart';
import 'package:flutter/material.dart';

import '../domain/entities.dart';
import 'database.dart';

/// Inserts a default wallet and common categories on first run.
class SeedData {
  static Future<void> populate(AppDatabase db) async {
    await db.into(db.wallets).insert(
          WalletsCompanion.insert(
            name: 'Cash',
            type: WalletType.cash.index,
            iconCodePoint: Icons.account_balance_wallet.codePoint,
            colorValue: Colors.green.toARGB32(),
          ),
        );

    final expense = TransactionKind.expense.index;
    final income = TransactionKind.income.index;

    final defaults = <_SeedCat>[
      _SeedCat('Food', expense, Icons.restaurant, Colors.orange),
      _SeedCat('Transport', expense, Icons.directions_bus, Colors.blue),
      _SeedCat('Shopping', expense, Icons.shopping_bag, Colors.purple),
      _SeedCat('Bills', expense, Icons.receipt_long, Colors.teal),
      _SeedCat('Health', expense, Icons.local_hospital, Colors.red),
      _SeedCat('Entertainment', expense, Icons.movie, Colors.pink),
      _SeedCat('Other', expense, Icons.category, Colors.grey),
      _SeedCat('Salary', income, Icons.payments, Colors.green),
      _SeedCat('Other Income', income, Icons.savings, Colors.lightGreen),
    ];

    await db.batch((b) {
      for (final c in defaults) {
        b.insert(
          db.categories,
          CategoriesCompanion.insert(
            name: c.name,
            kind: c.kind,
            iconCodePoint: c.icon.codePoint,
            colorValue: c.color.toARGB32(),
            isDefault: const Value(true),
          ),
        );
      }
    });
  }
}

class _SeedCat {
  const _SeedCat(this.name, this.kind, this.icon, this.color);
  final String name;
  final int kind;
  final IconData icon;
  final Color color;
}
