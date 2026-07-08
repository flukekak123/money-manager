import 'package:flutter_test/flutter_test.dart';
import 'package:money_manager/domain/entities.dart';
import 'package:money_manager/domain/services/budget_calculator.dart';

TransactionEntry _tx(int amount, int categoryId,
    {TransactionKind kind = TransactionKind.expense}) {
  return TransactionEntry(
    id: 0,
    amountMinor: amount,
    kind: kind,
    categoryId: categoryId,
    walletId: 1,
    date: DateTime(2026, 7, 1),
  );
}

void main() {
  const calc = BudgetCalculator();
  const budget = Budget(id: 1, categoryId: 10, limitMinor: 10000, month: '2026-07');

  test('sums only matching-category expenses', () {
    final p = calc.compute(budget, [
      _tx(3000, 10),
      _tx(2000, 10),
      _tx(5000, 99), // other category
      _tx(1000, 10, kind: TransactionKind.income), // income ignored
    ]);
    expect(p.spentMinor, 5000);
    expect(p.remainingMinor, 5000);
    expect(p.percent, 0.5);
    expect(p.status, BudgetStatus.ok);
  });

  test('status warn at >= 80%', () {
    final p = calc.compute(budget, [_tx(8000, 10)]);
    expect(p.status, BudgetStatus.warn);
  });

  test('status over at >= 100%', () {
    final p = calc.compute(budget, [_tx(10000, 10)]);
    expect(p.status, BudgetStatus.over);
    expect(p.remainingMinor, 0);
  });

  test('over budget yields negative remaining', () {
    final p = calc.compute(budget, [_tx(12000, 10)]);
    expect(p.remainingMinor, -2000);
    expect(p.status, BudgetStatus.over);
  });

  test('zero limit does not divide by zero', () {
    const b0 = Budget(id: 2, categoryId: 10, limitMinor: 0, month: '2026-07');
    final p = calc.compute(b0, [_tx(500, 10)]);
    expect(p.percent, 0);
  });
}
