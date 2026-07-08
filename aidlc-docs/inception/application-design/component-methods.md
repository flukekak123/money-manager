# Component Methods — Money Manager App

Signatures are Dart-style. Detailed business rules finalized in Functional Design.

## Domain Services

### MoneyFormatter
```dart
String format(int amountMinor, {String currencyCode});   // 123456 -> "$1,234.56"
int parse(String input, {String currencyCode});          // "1,234.56" -> 123456
```

### BudgetCalculator
```dart
BudgetProgress compute(Budget budget, Iterable<TransactionEntry> monthExpenses);
// BudgetProgress { int spentMinor; int limitMinor; int remainingMinor; double percent; BudgetStatus status; }
// BudgetStatus = ok | warn (>=80%) | over (>=100%)
```

### SummaryCalculator
```dart
PeriodSummary summarize(Iterable<TransactionEntry> txns);
// PeriodSummary { int incomeMinor; int expenseMinor; int netMinor; }
List<CategorySpend> spendingByCategory(Iterable<TransactionEntry> expenses);
// CategorySpend { int categoryId; int totalMinor; }
List<TrendPoint> incomeExpenseTrend(Iterable<TransactionEntry> txns, DateRange range);
// TrendPoint { DateTime bucket; int incomeMinor; int expenseMinor; }
```

## Repository Interfaces

### TransactionRepository
```dart
Stream<List<TransactionEntry>> watchAll();
Stream<List<TransactionEntry>> watchByMonth(String yyyymm);
Future<TransactionEntry> add(TransactionEntry e);
Future<void> update(TransactionEntry e);
Future<void> delete(int id);
```

### CategoryRepository
```dart
Stream<List<Category>> watchAll();
Future<Category> add(Category c);
Future<void> update(Category c);
Future<void> delete(int id);      // block/soft-delete if referenced
```

### WalletRepository
```dart
Stream<List<Wallet>> watchAll();
Stream<int> watchBalanceMinor(int walletId);
Future<Wallet> add(Wallet w);
Future<void> update(Wallet w);
Future<void> delete(int id);
```

### BudgetRepository
```dart
Stream<List<Budget>> watchByMonth(String yyyymm);
Future<Budget> upsert(Budget b);
Future<void> delete(int id);
```

### SettingsRepository
```dart
Future<AppSettings> load();        // { currencyCode, themeMode, appLockEnabled }
Future<void> save(AppSettings s);
```

## Presentation — key provider surface (Riverpod)
```dart
final databaseProvider           = Provider<AppDatabase>(...);
final transactionRepoProvider    = Provider<TransactionRepository>(...);
final categoryRepoProvider       = Provider<CategoryRepository>(...);
final walletRepoProvider         = Provider<WalletRepository>(...);
final budgetRepoProvider         = Provider<BudgetRepository>(...);
final settingsProvider           = AsyncNotifierProvider<SettingsNotifier, AppSettings>(...);

final monthTransactionsProvider  = StreamProvider.family<List<TransactionEntry>, String>(...);
final monthSummaryProvider       = Provider.family<PeriodSummary, String>(...);
final budgetProgressProvider     = Provider.family<List<BudgetProgress>, String>(...);
final walletBalanceProvider      = StreamProvider.family<int, int>(...);
```

## App Lock
```dart
class AppLockService {
  Future<bool> isAvailable();
  Future<bool> authenticate();     // biometric / device credential via local_auth
}
```
