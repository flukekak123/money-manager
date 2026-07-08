import 'package:flutter/material.dart';

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

  static const _titles = [
    'Home',
    'Transactions',
    'Budgets',
    'Reports',
    'Settings',
  ];

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
    final showFab = _index == 0 || _index == 1;
    return Scaffold(
      appBar: AppBar(title: Text(_titles[_index])),
      body: IndexedStack(index: _index, children: _screens),
      floatingActionButton: showFab
          ? FloatingActionButton.extended(
              key: const Key('add-transaction-fab'),
              onPressed: _addTransaction,
              icon: const Icon(Icons.add),
              label: const Text('Add'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Transactions'),
          NavigationDestination(icon: Icon(Icons.pie_chart_outline), selectedIcon: Icon(Icons.pie_chart), label: 'Budgets'),
          NavigationDestination(icon: Icon(Icons.bar_chart_outlined), selectedIcon: Icon(Icons.bar_chart), label: 'Reports'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}
