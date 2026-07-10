import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_manager/app.dart';
import 'package:money_manager/application/providers.dart';
import 'package:money_manager/domain/entities.dart';
import 'package:money_manager/domain/repositories.dart';

// Lightweight in-memory fakes so the widget tree resolves synchronously
// (no native DB, no fakeAsync timer stalls).

class _FakeTransactionRepo implements TransactionRepository {
  final List<TransactionEntry> items;
  _FakeTransactionRepo(this.items);
  @override
  Stream<List<TransactionEntry>> watchAll() => Stream.value(items);
  @override
  Stream<List<TransactionEntry>> watchByMonth(String yyyymm) =>
      Stream.value(items);
  @override
  Future<int> add(TransactionEntry e) async => 0;
  @override
  Future<void> update(TransactionEntry e) async {}
  @override
  Future<void> delete(int id) async {}
}

class _FakeCategoryRepo implements CategoryRepository {
  final List<Category> items;
  _FakeCategoryRepo(this.items);
  @override
  Stream<List<Category>> watchAll({bool includeArchived = false}) =>
      Stream.value(items);
  @override
  Future<int> add(Category c) async => 0;
  @override
  Future<void> update(Category c) async {}
  @override
  Future<void> archive(int id) async {}
  @override
  Future<void> delete(int id) async {}
}

class _FakeWalletRepo implements WalletRepository {
  final List<Wallet> items;
  _FakeWalletRepo(this.items);
  @override
  Stream<List<Wallet>> watchAll({bool includeArchived = false}) =>
      Stream.value(items);
  @override
  Stream<int> watchBalanceMinor(int walletId) => Stream.value(0);
  @override
  Future<int> add(Wallet w) async => 0;
  @override
  Future<void> update(Wallet w) async {}
  @override
  Future<void> archive(int id) async {}
  @override
  Future<void> delete(int id) async {}
}

class _FakeInstallmentRepo implements InstallmentRepository {
  @override
  Stream<List<InstallmentPlan>> watchAll() =>
      Stream.value(const <InstallmentPlan>[]);
  @override
  Future<InstallmentPlan?> getById(int id) async => null;
  @override
  Stream<List<TransactionEntry>> watchInstallments(int planId) =>
      Stream.value(const <TransactionEntry>[]);
  @override
  Future<int> createPlan(InstallmentPlan plan) async => 0;
  @override
  Future<void> deletePlan(int id) async {}
}

class _FakeBudgetRepo implements BudgetRepository {
  @override
  Stream<List<Budget>> watchByMonth(String yyyymm) =>
      Stream.value(const <Budget>[]);
  @override
  Future<void> upsert(Budget b) async {}
  @override
  Future<void> delete(int id) async {}
}

class _FakeSettingsRepo implements SettingsRepository {
  @override
  Future<AppSettings> load() async => const AppSettings(
        currencyCode: 'USD',
        themeMode: AppThemeMode.system,
        appLockEnabled: false,
      );
  @override
  Future<void> save(AppSettings settings) async {}
}

Category _cat(int id, String name, TransactionKind kind) => Category(
      id: id,
      name: name,
      kind: kind,
      iconCodePoint: Icons.category.codePoint,
      colorValue: 0xFF00FF00,
    );

Wallet _wallet(int id, String name) => Wallet(
      id: id,
      name: name,
      type: WalletType.cash,
      iconCodePoint: Icons.account_balance_wallet.codePoint,
      colorValue: 0xFF00FF00,
    );

// ignore: strict_top_level_inference
_overrides({
  List<TransactionEntry> txns = const [],
  List<Category>? categories,
  List<Wallet>? wallets,
}) {
  return [
    transactionRepositoryProvider
        .overrideWithValue(_FakeTransactionRepo(txns)),
    categoryRepositoryProvider.overrideWithValue(_FakeCategoryRepo(categories ??
        [
          _cat(1, 'Food', TransactionKind.expense),
          _cat(2, 'Salary', TransactionKind.income),
        ])),
    walletRepositoryProvider
        .overrideWithValue(_FakeWalletRepo(wallets ?? [_wallet(1, 'Cash')])),
    budgetRepositoryProvider.overrideWithValue(_FakeBudgetRepo()),
    installmentRepositoryProvider.overrideWithValue(_FakeInstallmentRepo()),
    settingsRepositoryProvider.overrideWithValue(_FakeSettingsRepo()),
  ];
}

void main() {
  testWidgets('app boots to home dashboard with navigation', (tester) async {
    await tester.pumpWidget(
      ProviderScope(overrides: _overrides(), child: const MoneyManagerApp()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsWidgets);
    expect(find.text('Transactions'), findsWidgets);
    expect(find.text('Budgets'), findsWidgets);
    expect(find.text('Reports'), findsWidgets);
    expect(find.text('This month'), findsOneWidget);
    expect(find.byKey(const Key('add-transaction-fab')), findsOneWidget);
    expect(find.text('No transactions yet'), findsOneWidget);
  });

  testWidgets('tapping Add opens the transaction form', (tester) async {
    await tester.pumpWidget(
      ProviderScope(overrides: _overrides(), child: const MoneyManagerApp()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('add-transaction-fab')));
    await tester.pumpAndSettle();

    expect(find.text('Add Transaction'), findsOneWidget);
    expect(find.byKey(const Key('amount-field')), findsOneWidget);
    expect(find.byKey(const Key('save-transaction-button')), findsOneWidget);
  });

  testWidgets('navigating to Reports shows empty chart state', (tester) async {
    await tester.pumpWidget(
      ProviderScope(overrides: _overrides(), child: const MoneyManagerApp()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Reports').last);
    await tester.pumpAndSettle();

    expect(find.text('Spending by category'), findsOneWidget);
    expect(find.text('No expenses this month'), findsOneWidget);
  });
}
