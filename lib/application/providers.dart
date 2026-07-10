import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/date_utils.dart';
import '../core/money.dart';
import '../data/database.dart' show AppDatabase;
import '../data/repositories/budget_repository_impl.dart';
import '../data/repositories/category_repository_impl.dart';
import '../data/repositories/installment_repository_impl.dart';
import '../data/repositories/transaction_repository_impl.dart';
import '../data/repositories/wallet_repository_impl.dart';
import '../data/backup_service.dart';
import '../data/settings_repository.dart';
import '../domain/entities.dart';
import '../domain/repositories.dart';
import '../domain/services/budget_calculator.dart';
import '../domain/services/summary_calculator.dart';
import 'app_lock_service.dart';
import 'controllers/backup_controller.dart';
import 'controllers/budget_controller.dart';
import 'controllers/category_controller.dart';
import 'controllers/transaction_controller.dart';
import 'controllers/wallet_controller.dart';
import 'settings_notifier.dart';

// --- Composition root -------------------------------------------------------

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final settingsRepositoryProvider =
    Provider<SettingsRepository>((ref) => SettingsRepositoryImpl());

final transactionRepositoryProvider = Provider<TransactionRepository>(
    (ref) => TransactionRepositoryImpl(ref.watch(databaseProvider)));

final categoryRepositoryProvider = Provider<CategoryRepository>(
    (ref) => CategoryRepositoryImpl(ref.watch(databaseProvider)));

final walletRepositoryProvider = Provider<WalletRepository>(
    (ref) => WalletRepositoryImpl(ref.watch(databaseProvider)));

final budgetRepositoryProvider = Provider<BudgetRepository>(
    (ref) => BudgetRepositoryImpl(ref.watch(databaseProvider)));

final installmentRepositoryProvider = Provider<InstallmentRepository>(
    (ref) => InstallmentRepositoryImpl(ref.watch(databaseProvider)));

// --- Settings ---------------------------------------------------------------

final settingsProvider =
    AsyncNotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);

final appLockServiceProvider = Provider<AppLockService>((ref) => AppLockService());

/// Money formatter derived from the active currency (falls back to USD).
final moneyFormatterProvider = Provider<MoneyFormatter>((ref) {
  final currency =
      ref.watch(settingsProvider).asData?.value.currencyCode ?? 'USD';
  return MoneyFormatter(currency);
});

// --- Selected month ---------------------------------------------------------

class SelectedMonthNotifier extends Notifier<String> {
  @override
  String build() => MonthKey.current();

  void set(String yyyymm) => state = yyyymm;

  void shift(int months) {
    final s = MonthKey.start(state);
    state = MonthKey.of(DateTime(s.year, s.month + months, 1));
  }
}

final selectedMonthProvider =
    NotifierProvider<SelectedMonthNotifier, String>(SelectedMonthNotifier.new);

// --- Reactive data streams --------------------------------------------------

final walletsProvider = StreamProvider<List<Wallet>>(
    (ref) => ref.watch(walletRepositoryProvider).watchAll());

final categoriesProvider = StreamProvider<List<Category>>(
    (ref) => ref.watch(categoryRepositoryProvider).watchAll());

final allTransactionsProvider = StreamProvider<List<TransactionEntry>>(
    (ref) => ref.watch(transactionRepositoryProvider).watchAll());

final monthTransactionsProvider =
    StreamProvider.family<List<TransactionEntry>, String>(
        (ref, month) =>
            ref.watch(transactionRepositoryProvider).watchByMonth(month));

final monthBudgetsProvider = StreamProvider.family<List<Budget>, String>(
    (ref, month) => ref.watch(budgetRepositoryProvider).watchByMonth(month));

final installmentPlansProvider = StreamProvider<List<InstallmentPlan>>(
    (ref) => ref.watch(installmentRepositoryProvider).watchAll());

/// Installments (transactions) of one plan, ordered by installmentNo.
final planInstallmentsProvider =
    StreamProvider.family<List<TransactionEntry>, int>((ref, planId) =>
        ref.watch(installmentRepositoryProvider).watchInstallments(planId));

/// Lookup map planId -> InstallmentPlan (for "k/N" badges).
final installmentPlansByIdProvider = Provider<Map<int, InstallmentPlan>>((ref) {
  final plans = ref.watch(installmentPlansProvider).asData?.value ??
      const <InstallmentPlan>[];
  return {for (final p in plans) p.id: p};
});

final walletBalanceProvider = StreamProvider.family<int, int>(
    (ref, walletId) =>
        ref.watch(walletRepositoryProvider).watchBalanceMinor(walletId));

// --- Derived (pure) read models --------------------------------------------

final monthSummaryProvider = Provider.family<PeriodSummary, String>((ref, month) {
  final txns = ref.watch(monthTransactionsProvider(month)).asData?.value ??
      const <TransactionEntry>[];
  return const SummaryCalculator().summarize(txns);
});

final budgetProgressProvider =
    Provider.family<List<BudgetProgress>, String>((ref, month) {
  final budgets =
      ref.watch(monthBudgetsProvider(month)).asData?.value ?? const <Budget>[];
  final txns = ref.watch(monthTransactionsProvider(month)).asData?.value ??
      const <TransactionEntry>[];
  return const BudgetCalculator().computeAll(budgets, txns);
});

final spendingByCategoryProvider =
    Provider.family<List<CategorySpend>, String>((ref, month) {
  final txns = ref.watch(monthTransactionsProvider(month)).asData?.value ??
      const <TransactionEntry>[];
  return const SummaryCalculator().spendingByCategory(txns);
});

final trendProvider = Provider.family<List<TrendPoint>, String>((ref, month) {
  final txns = ref.watch(monthTransactionsProvider(month)).asData?.value ??
      const <TransactionEntry>[];
  return const SummaryCalculator()
      .incomeExpenseTrend(txns, DateRange.month(month));
});

/// Lookup map categoryId -> Category for the current (non-archived) set.
final categoriesByIdProvider = Provider<Map<int, Category>>((ref) {
  final cats = ref.watch(categoriesProvider).asData?.value ?? const <Category>[];
  return {for (final c in cats) c.id: c};
});

final walletsByIdProvider = Provider<Map<int, Wallet>>((ref) {
  final wallets = ref.watch(walletsProvider).asData?.value ?? const <Wallet>[];
  return {for (final w in wallets) w.id: w};
});

// --- Controllers ------------------------------------------------------------

final transactionControllerProvider = Provider<TransactionController>(
  (ref) => TransactionController(
    repository: ref.watch(transactionRepositoryProvider),
    installments: ref.watch(installmentRepositoryProvider),
    money: ref.watch(moneyFormatterProvider),
  ),
);

final budgetControllerProvider = Provider<BudgetController>(
  (ref) => BudgetController(
    repository: ref.watch(budgetRepositoryProvider),
    money: ref.watch(moneyFormatterProvider),
  ),
);

final walletControllerProvider = Provider<WalletController>(
    (ref) => WalletController(ref.watch(walletRepositoryProvider)));

final categoryControllerProvider = Provider<CategoryController>(
    (ref) => CategoryController(ref.watch(categoryRepositoryProvider)));

// --- Backup ------------------------------------------------------------------

final backupServiceProvider = Provider<BackupService>(
    (ref) => BackupService(ref.watch(databaseProvider)));

final backupControllerProvider = Provider<BackupController>(
    (ref) => BackupController(ref.watch(backupServiceProvider)));
