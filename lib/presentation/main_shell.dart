import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import 'budgets/budgets_screen.dart';
import 'home/home_screen.dart';
import 'reports/reports_screen.dart';
import 'settings/settings_screen.dart';
import 'transactions/transaction_edit_screen.dart';
import 'transactions/transactions_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  final _screens = const [
    HomeScreen(),
    TransactionsScreen(),
    BudgetsScreen(),
    ReportsScreen(),
    SettingsScreen(),
  ];

  void _addTransaction() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const TransactionEditScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final titles = [
      l.navHome,
      l.navTransactions,
      l.navBudgets,
      l.navReports,
      l.navSettings,
    ];
    final showFab = _index == 0 || _index == 1;
    return Scaffold(
      appBar: AppBar(title: Text(titles[_index])),
      body: IndexedStack(index: _index, children: _screens),
      floatingActionButton: showFab
          ? FloatingActionButton.extended(
              key: const Key('add-transaction-fab'),
              onPressed: _addTransaction,
              icon: const Icon(Icons.add),
              label: Text(l.add),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          NavigationDestination(icon: const Icon(Icons.home_outlined), selectedIcon: const Icon(Icons.home), label: l.navHome),
          NavigationDestination(icon: const Icon(Icons.receipt_long_outlined), selectedIcon: const Icon(Icons.receipt_long), label: l.navTransactions),
          NavigationDestination(icon: const Icon(Icons.pie_chart_outline), selectedIcon: const Icon(Icons.pie_chart), label: l.navBudgets),
          NavigationDestination(icon: const Icon(Icons.bar_chart_outlined), selectedIcon: const Icon(Icons.bar_chart), label: l.navReports),
          NavigationDestination(icon: const Icon(Icons.settings_outlined), selectedIcon: const Icon(Icons.settings), label: l.navSettings),
        ],
      ),
    );
  }
}
