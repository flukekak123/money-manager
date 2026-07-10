import 'package:flutter_test/flutter_test.dart';
import 'package:money_manager/domain/entities.dart';
import 'package:money_manager/domain/services/subscription_calculator.dart';

void main() {
  const calc = SubscriptionCalculator();

  Subscription sub({
    required DateTime start,
    required DateTime created,
    DateTime? lastCharged,
    bool active = true,
  }) =>
      Subscription(
        id: 1,
        name: 'Netflix',
        amountMinor: 41900,
        categoryId: 1,
        walletId: 1,
        startDate: start,
        createdAt: created,
        lastChargedDate: lastCharged,
        active: active,
      );

  group('dueDatesBetween', () {
    test('start today: single charge today', () {
      final today = DateTime(2026, 7, 10);
      final s = sub(start: today, created: today);
      expect(calc.dueDatesBetween(s, today), [DateTime(2026, 7, 10)]);
    });

    test('future start date: nothing due yet', () {
      final s = sub(
          start: DateTime(2026, 7, 15), created: DateTime(2026, 7, 10));
      expect(calc.dueDatesBetween(s, DateTime(2026, 7, 10)), isEmpty);
      expect(calc.dueDatesBetween(s, DateTime(2026, 7, 15)),
          [DateTime(2026, 7, 15)]);
    });

    test('past start date: no backfill (Q6=B), day anchors only', () {
      // Subscribed months ago, added to app July 10; charge day = 5th.
      final s = sub(
          start: DateTime(2026, 4, 5), created: DateTime(2026, 7, 10));
      expect(calc.dueDatesBetween(s, DateTime(2026, 7, 10)), isEmpty);
      // Next 5th falls due:
      expect(calc.dueDatesBetween(s, DateTime(2026, 8, 5)),
          [DateTime(2026, 8, 5)]);
    });

    test('catch-up: three missed months recorded at once', () {
      final s = sub(
        start: DateTime(2026, 3, 10),
        created: DateTime(2026, 3, 10),
        lastCharged: DateTime(2026, 4, 10),
      );
      // App unopened since April; opened July 10.
      expect(calc.dueDatesBetween(s, DateTime(2026, 7, 10)), [
        DateTime(2026, 5, 10),
        DateTime(2026, 6, 10),
        DateTime(2026, 7, 10),
      ]);
    });

    test('marker prevents recharging (idempotent lower bound)', () {
      final s = sub(
        start: DateTime(2026, 7, 10),
        created: DateTime(2026, 7, 10),
        lastCharged: DateTime(2026, 7, 10),
      );
      expect(calc.dueDatesBetween(s, DateTime(2026, 7, 10)), isEmpty);
      expect(calc.dueDatesBetween(s, DateTime(2026, 8, 9)), isEmpty);
      expect(calc.dueDatesBetween(s, DateTime(2026, 8, 10)),
          [DateTime(2026, 8, 10)]);
    });

    test('day-31 clamps in short months', () {
      final s = sub(
          start: DateTime(2026, 1, 31), created: DateTime(2026, 1, 31));
      expect(calc.dueDatesBetween(s, DateTime(2026, 4, 30)), [
        DateTime(2026, 1, 31),
        DateTime(2026, 2, 28),
        DateTime(2026, 3, 31),
        DateTime(2026, 4, 30),
      ]);
    });
  });

  group('nextChargeDate', () {
    test('returns first due date after today', () {
      final s = sub(
          start: DateTime(2026, 7, 5), created: DateTime(2026, 7, 10));
      expect(calc.nextChargeDate(s, DateTime(2026, 7, 10)),
          DateTime(2026, 8, 5));
    });

    test('null when cancelled', () {
      final s = sub(
          start: DateTime(2026, 7, 5),
          created: DateTime(2026, 7, 10),
          active: false);
      expect(calc.nextChargeDate(s, DateTime(2026, 7, 10)), isNull);
    });
  });
}