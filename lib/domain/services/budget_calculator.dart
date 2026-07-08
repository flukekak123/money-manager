import '../entities.dart';

/// Computes budget progress from a budget and the month's expense transactions.
/// Thresholds are fixed: warn at >= 80%, over at >= 100%.
class BudgetCalculator {
  const BudgetCalculator();

  BudgetProgress compute(
    Budget budget,
    Iterable<TransactionEntry> monthTransactions,
  ) {
    var spent = 0;
    for (final t in monthTransactions) {
      if (t.kind == TransactionKind.expense &&
          t.categoryId == budget.categoryId) {
        spent += t.amountMinor;
      }
    }
    return BudgetProgress(budget: budget, spentMinor: spent);
  }

  List<BudgetProgress> computeAll(
    Iterable<Budget> budgets,
    Iterable<TransactionEntry> monthTransactions,
  ) {
    final txns = monthTransactions.toList(growable: false);
    return budgets.map((b) => compute(b, txns)).toList();
  }
}
