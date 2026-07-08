import '../../core/date_utils.dart';
import '../entities.dart';

/// Pure aggregation over transactions: totals, per-category spend, trend.
class SummaryCalculator {
  const SummaryCalculator();

  PeriodSummary summarize(Iterable<TransactionEntry> txns) {
    var income = 0;
    var expense = 0;
    for (final t in txns) {
      if (t.kind == TransactionKind.income) {
        income += t.amountMinor;
      } else {
        expense += t.amountMinor;
      }
    }
    return PeriodSummary(incomeMinor: income, expenseMinor: expense);
  }

  /// Total expense per category, sorted descending by amount.
  List<CategorySpend> spendingByCategory(Iterable<TransactionEntry> txns) {
    final map = <int, int>{};
    for (final t in txns) {
      if (t.kind == TransactionKind.expense) {
        map.update(t.categoryId, (v) => v + t.amountMinor,
            ifAbsent: () => t.amountMinor);
      }
    }
    final list = map.entries
        .map((e) => CategorySpend(categoryId: e.key, totalMinor: e.value))
        .toList();
    list.sort((a, b) => b.totalMinor.compareTo(a.totalMinor));
    return list;
  }

  /// Income/expense totals bucketed by day (range <= 31d) or by month.
  List<TrendPoint> incomeExpenseTrend(
    Iterable<TransactionEntry> txns,
    DateRange range,
  ) {
    final byMonth = range.days > 31;
    final income = <DateTime, int>{};
    final expense = <DateTime, int>{};

    DateTime bucketOf(DateTime d) =>
        byMonth ? DateTime(d.year, d.month) : DateTime(d.year, d.month, d.day);

    for (final t in txns) {
      if (!range.contains(t.date)) continue;
      final b = bucketOf(t.date);
      if (t.kind == TransactionKind.income) {
        income.update(b, (v) => v + t.amountMinor, ifAbsent: () => t.amountMinor);
      } else {
        expense.update(b, (v) => v + t.amountMinor, ifAbsent: () => t.amountMinor);
      }
    }

    final buckets = {...income.keys, ...expense.keys}.toList()..sort();
    return buckets
        .map((b) => TrendPoint(
              bucket: b,
              incomeMinor: income[b] ?? 0,
              expenseMinor: expense[b] ?? 0,
            ))
        .toList();
  }
}
