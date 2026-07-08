// Pure domain entities and value objects. No Flutter or DB imports.

enum TransactionKind { income, expense }

enum WalletType { cash, bank, card, other }

enum BudgetStatus { ok, warn, over }

enum AppThemeMode { system, light, dark }

class Wallet {
  const Wallet({
    required this.id,
    required this.name,
    required this.type,
    required this.iconCodePoint,
    required this.colorValue,
    this.archived = false,
  });

  final int id;
  final String name;
  final WalletType type;
  final int iconCodePoint;
  final int colorValue;
  final bool archived;

  Wallet copyWith({
    String? name,
    WalletType? type,
    int? iconCodePoint,
    int? colorValue,
    bool? archived,
  }) =>
      Wallet(
        id: id,
        name: name ?? this.name,
        type: type ?? this.type,
        iconCodePoint: iconCodePoint ?? this.iconCodePoint,
        colorValue: colorValue ?? this.colorValue,
        archived: archived ?? this.archived,
      );
}

class Category {
  const Category({
    required this.id,
    required this.name,
    required this.kind,
    required this.iconCodePoint,
    required this.colorValue,
    this.isDefault = false,
    this.archived = false,
  });

  final int id;
  final String name;
  final TransactionKind kind;
  final int iconCodePoint;
  final int colorValue;
  final bool isDefault;
  final bool archived;

  Category copyWith({
    String? name,
    TransactionKind? kind,
    int? iconCodePoint,
    int? colorValue,
    bool? archived,
  }) =>
      Category(
        id: id,
        name: name ?? this.name,
        kind: kind ?? this.kind,
        iconCodePoint: iconCodePoint ?? this.iconCodePoint,
        colorValue: colorValue ?? this.colorValue,
        isDefault: isDefault,
        archived: archived ?? this.archived,
      );
}

class TransactionEntry {
  const TransactionEntry({
    required this.id,
    required this.amountMinor,
    required this.kind,
    required this.categoryId,
    required this.walletId,
    required this.date,
    this.note,
  });

  final int id;
  final int amountMinor;
  final TransactionKind kind;
  final int categoryId;
  final int walletId;
  final DateTime date;
  final String? note;

  /// Signed value: positive for income, negative for expense.
  int get signedMinor => kind == TransactionKind.income ? amountMinor : -amountMinor;
}

class Budget {
  const Budget({
    required this.id,
    required this.categoryId,
    required this.limitMinor,
    required this.month,
  });

  final int id;
  final int categoryId;
  final int limitMinor;
  final String month; // YYYY-MM
}

/// Derived: budget vs actual for a period.
class BudgetProgress {
  const BudgetProgress({
    required this.budget,
    required this.spentMinor,
  });

  final Budget budget;
  final int spentMinor;

  int get limitMinor => budget.limitMinor;
  int get remainingMinor => limitMinor - spentMinor;
  double get percent => limitMinor <= 0 ? 0 : spentMinor / limitMinor;

  BudgetStatus get status {
    if (percent >= 1.0) return BudgetStatus.over;
    if (percent >= 0.8) return BudgetStatus.warn;
    return BudgetStatus.ok;
  }
}

class PeriodSummary {
  const PeriodSummary({
    required this.incomeMinor,
    required this.expenseMinor,
  });

  final int incomeMinor;
  final int expenseMinor;
  int get netMinor => incomeMinor - expenseMinor;

  static const empty = PeriodSummary(incomeMinor: 0, expenseMinor: 0);
}

class CategorySpend {
  const CategorySpend({required this.categoryId, required this.totalMinor});
  final int categoryId;
  final int totalMinor;
}

class TrendPoint {
  const TrendPoint({
    required this.bucket,
    required this.incomeMinor,
    required this.expenseMinor,
  });
  final DateTime bucket;
  final int incomeMinor;
  final int expenseMinor;
}

class AppSettings {
  const AppSettings({
    required this.currencyCode,
    required this.themeMode,
    required this.appLockEnabled,
    this.languageCode = 'en',
  });

  final String currencyCode;
  final AppThemeMode themeMode;
  final bool appLockEnabled;

  /// UI language: 'en' or 'th'.
  final String languageCode;

  AppSettings copyWith({
    String? currencyCode,
    AppThemeMode? themeMode,
    bool? appLockEnabled,
    String? languageCode,
  }) =>
      AppSettings(
        currencyCode: currencyCode ?? this.currencyCode,
        themeMode: themeMode ?? this.themeMode,
        appLockEnabled: appLockEnabled ?? this.appLockEnabled,
        languageCode: languageCode ?? this.languageCode,
      );
}

/// Raised when a domain business rule is violated.
class DomainException implements Exception {
  const DomainException(this.message);
  final String message;
  @override
  String toString() => message;
}
