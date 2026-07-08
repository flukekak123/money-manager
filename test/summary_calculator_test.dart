import 'package:flutter_test/flutter_test.dart';
import 'package:money_manager/core/date_utils.dart';
import 'package:money_manager/domain/entities.dart';
import 'package:money_manager/domain/services/summary_calculator.dart';

TransactionEntry _tx(int amount, TransactionKind kind, int categoryId, DateTime d) {
  return TransactionEntry(
    id: 0,
    amountMinor: amount,
    kind: kind,
    categoryId: categoryId,
    walletId: 1,
    date: d,
  );
}

void main() {
  const calc = SummaryCalculator();

  test('summarize computes income, expense, net', () {
    final s = calc.summarize([
      _tx(5000, TransactionKind.income, 1, DateTime(2026, 7, 1)),
      _tx(2000, TransactionKind.expense, 2, DateTime(2026, 7, 2)),
      _tx(1000, TransactionKind.expense, 3, DateTime(2026, 7, 3)),
    ]);
    expect(s.incomeMinor, 5000);
    expect(s.expenseMinor, 3000);
    expect(s.netMinor, 2000);
  });

  test('spendingByCategory groups and sorts descending', () {
    final list = calc.spendingByCategory([
      _tx(1000, TransactionKind.expense, 1, DateTime(2026, 7, 1)),
      _tx(3000, TransactionKind.expense, 2, DateTime(2026, 7, 1)),
      _tx(500, TransactionKind.expense, 1, DateTime(2026, 7, 2)),
      _tx(9999, TransactionKind.income, 5, DateTime(2026, 7, 2)),
    ]);
    expect(list.length, 2);
    expect(list.first.categoryId, 2);
    expect(list.first.totalMinor, 3000);
    expect(list[1].categoryId, 1);
    expect(list[1].totalMinor, 1500);
  });

  test('trend buckets by day for short range', () {
    final range = DateRange.month('2026-07');
    final points = calc.incomeExpenseTrend([
      _tx(1000, TransactionKind.income, 1, DateTime(2026, 7, 1)),
      _tx(400, TransactionKind.expense, 2, DateTime(2026, 7, 1)),
      _tx(700, TransactionKind.expense, 2, DateTime(2026, 7, 5)),
    ], range);
    expect(points.length, 2);
    expect(points.first.incomeMinor, 1000);
    expect(points.first.expenseMinor, 400);
    expect(points[1].expenseMinor, 700);
  });

  test('trend ignores out-of-range transactions', () {
    final range = DateRange.month('2026-07');
    final points = calc.incomeExpenseTrend([
      _tx(1000, TransactionKind.income, 1, DateTime(2026, 6, 30)),
    ], range);
    expect(points, isEmpty);
  });
}
