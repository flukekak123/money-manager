import 'package:flutter_test/flutter_test.dart';
import 'package:money_manager/domain/entities.dart';
import 'package:money_manager/domain/services/installment_calculator.dart';

void main() {
  const calc = InstallmentCalculator();

  group('splitAmounts', () {
    test('even split when divisible', () {
      expect(calc.splitAmounts(30000, 3), [10000, 10000, 10000]);
      expect(calc.splitAmounts(120000, 12), List.filled(12, 10000));
    });

    test('last installment absorbs remainder (BR-I3)', () {
      expect(calc.splitAmounts(100000, 3), [33333, 33333, 33334]);
      expect(calc.splitAmounts(100000, 6),
          [16666, 16666, 16666, 16666, 16666, 16670]);
      expect(calc.splitAmounts(1000, 12).last, 1000 - 83 * 11);
    });

    test('sum is always exact for all allowed month counts', () {
      for (final months in InstallmentCalculator.allowedMonths) {
        for (final total in [999, 1000, 12345, 99999999]) {
          final amounts = calc.splitAmounts(total, months);
          expect(amounts.length, months);
          expect(amounts.reduce((a, b) => a + b), total,
              reason: 'total=$total months=$months');
        }
      }
    });

    test('rejects unsupported month counts (BR-I1)', () {
      for (final months in [0, 1, 2, 4, 5, 24, -3]) {
        expect(() => calc.splitAmounts(10000, months),
            throwsA(isA<DomainException>()));
      }
    });

    test('rejects zero/negative and too-small totals (BR-I2)', () {
      expect(() => calc.splitAmounts(0, 3), throwsA(isA<DomainException>()));
      expect(() => calc.splitAmounts(-100, 3), throwsA(isA<DomainException>()));
      expect(() => calc.splitAmounts(2, 3), throwsA(isA<DomainException>()));
      expect(calc.splitAmounts(3, 3), [1, 1, 1]); // minimum allowed
    });
  });

  group('dueDates', () {
    test('same day of consecutive months', () {
      final dates = calc.dueDates(DateTime(2026, 7, 10), 3);
      expect(dates, [
        DateTime(2026, 7, 10),
        DateTime(2026, 8, 10),
        DateTime(2026, 9, 10),
      ]);
    });

    test('clamps day 31 to shorter months', () {
      final dates = calc.dueDates(DateTime(2026, 1, 31), 3);
      expect(dates, [
        DateTime(2026, 1, 31),
        DateTime(2026, 2, 28), // 2026 not a leap year
        DateTime(2026, 3, 31),
      ]);
    });

    test('clamps to Feb 29 in a leap year', () {
      final dates = calc.dueDates(DateTime(2028, 1, 31), 3);
      expect(dates[1], DateTime(2028, 2, 29));
    });

    test('crosses year boundary', () {
      final dates = calc.dueDates(DateTime(2026, 10, 31), 6);
      expect(dates.last, DateTime(2027, 3, 31));
      expect(dates[4], DateTime(2027, 2, 28));
    });

    test('returns one date per month', () {
      for (final months in InstallmentCalculator.allowedMonths) {
        expect(calc.dueDates(DateTime(2026, 7, 10), months).length, months);
      }
    });
  });
}