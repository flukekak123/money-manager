// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Money Manager';

  @override
  String get navHome => 'Home';

  @override
  String get navTransactions => 'Transactions';

  @override
  String get navBudgets => 'Budgets';

  @override
  String get navReports => 'Reports';

  @override
  String get navSettings => 'Settings';

  @override
  String get add => 'Add';

  @override
  String get recent => 'Recent';

  @override
  String get thisMonth => 'This month';

  @override
  String get income => 'Income';

  @override
  String get expense => 'Expense';

  @override
  String get balance => 'Balance';

  @override
  String get net => 'Net';

  @override
  String get category => 'Category';

  @override
  String get noTransactionsYet => 'No transactions yet';

  @override
  String get tapAddToRecord => 'Tap Add to record income or an expense.';

  @override
  String get tapAddFirst => 'Tap Add to record your first transaction.';

  @override
  String errorWithMessage(Object message) {
    return 'Error: $message';
  }

  @override
  String get deleteTransactionTitle => 'Delete transaction?';

  @override
  String get cannotBeUndone => 'This cannot be undone.';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get save => 'Save';

  @override
  String get editTransaction => 'Edit Transaction';

  @override
  String get addTransaction => 'Add Transaction';

  @override
  String get amount => 'Amount';

  @override
  String get enterAmount => 'Enter an amount';

  @override
  String get selectCategory => 'Select a category';

  @override
  String get wallet => 'Wallet';

  @override
  String get selectWallet => 'Select a wallet';

  @override
  String get noteOptional => 'Note (optional)';

  @override
  String get selectCategoryAndWallet => 'Select a category and wallet.';

  @override
  String get noBudgets => 'No budgets for this month';

  @override
  String get tapPlusBudget => 'Tap + to set a monthly limit for a category.';

  @override
  String get addUpdateBudget => 'Add / Update Budget';

  @override
  String get budget => 'Budget';

  @override
  String get monthlyLimit => 'Monthly limit';

  @override
  String get over => 'Over';

  @override
  String get spendingByCategory => 'Spending by category';

  @override
  String get noExpensesThisMonth => 'No expenses this month';

  @override
  String get incomeVsExpense => 'Income vs expense';

  @override
  String get noDataThisMonth => 'No data this month';

  @override
  String get categories => 'Categories';

  @override
  String get newCategory => 'New Category';

  @override
  String get editCategory => 'Edit Category';

  @override
  String get name => 'Name';

  @override
  String get defaultLabel => 'default';

  @override
  String get wallets => 'Wallets';

  @override
  String get newWallet => 'New Wallet';

  @override
  String get editWallet => 'Edit Wallet';

  @override
  String get type => 'Type';

  @override
  String get archive => 'Archive';

  @override
  String get manage => 'Manage';

  @override
  String get preferences => 'Preferences';

  @override
  String get currency => 'Currency';

  @override
  String get theme => 'Theme';

  @override
  String get language => 'Language';

  @override
  String get appLock => 'App lock';

  @override
  String get appLockSubtitle => 'Require biometric/device unlock on launch';

  @override
  String get dataSection => 'Data';

  @override
  String get exportData => 'Export data';

  @override
  String get exportDataSubtitle => 'Save a JSON backup of all your data';

  @override
  String get importData => 'Import data';

  @override
  String get importDataSubtitle =>
      'Restore from a JSON backup (replaces all data)';

  @override
  String get backupExported => 'Backup exported.';

  @override
  String get backupRestored => 'Backup restored.';

  @override
  String exportFailed(Object message) {
    return 'Export failed: $message';
  }

  @override
  String importFailed(Object message) {
    return 'Import failed: $message';
  }

  @override
  String get replaceAllData => 'Replace all data?';

  @override
  String get replaceAllDataBody =>
      'Importing a backup will permanently replace all current wallets, categories, transactions, and budgets. This cannot be undone.';

  @override
  String get replace => 'Replace';

  @override
  String get aboutBody =>
      'Offline-first personal finance app. Data stays on device.';

  @override
  String get appLockedTitle => 'Money Manager is locked';

  @override
  String get unlock => 'Unlock';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get payInInstallments => 'Pay in installments';

  @override
  String get installmentMonthsLabel => 'Months';

  @override
  String installmentPreview(Object months, Object amount, Object lastAmount) {
    return '$months monthly payments of $amount (last $lastAmount)';
  }

  @override
  String get installmentPlanTitle => 'Installment plan';

  @override
  String installmentProgress(Object paid, Object total) {
    return '$paid of $total paid';
  }

  @override
  String installmentNoLabel(Object no) {
    return 'Installment $no';
  }

  @override
  String installmentCreated(Object months) {
    return 'Installment plan created ($months monthly payments).';
  }

  @override
  String get total => 'Total';

  @override
  String get deletePlan => 'Delete plan';

  @override
  String deletePlanBody(Object count) {
    return 'This deletes all $count installment transactions. This cannot be undone.';
  }

  @override
  String get subscriptions => 'Subscriptions';

  @override
  String get newSubscription => 'New Subscription';

  @override
  String get editSubscription => 'Edit Subscription';

  @override
  String get subscriptionName => 'Name (e.g. Netflix)';

  @override
  String perMonth(Object amount) {
    return '$amount/month';
  }

  @override
  String nextCharge(Object date) {
    return 'Next charge $date';
  }

  @override
  String get cancelledLabel => 'Cancelled';

  @override
  String get cancelSubscription => 'Cancel subscription';

  @override
  String get cancelSubscriptionBody =>
      'No more charges will be recorded. Past transactions are kept.';

  @override
  String get keep => 'Keep';

  @override
  String get startDate => 'Start date';

  @override
  String get noSubscriptions => 'No subscriptions yet';

  @override
  String get addSubscriptionHint => 'Tap + to add a monthly subscription.';

  @override
  String get chargeHistory => 'Charge history';

  @override
  String get walletTypeCash => 'Cash';

  @override
  String get walletTypeBank => 'Bank';

  @override
  String get walletTypeCard => 'Card';

  @override
  String get walletTypeOther => 'Other';
}
