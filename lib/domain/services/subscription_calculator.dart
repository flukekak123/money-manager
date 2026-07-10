import '../entities.dart';
import 'installment_calculator.dart';

/// Stateless subscription due-date math (BR-SB5, FR-2). Pure Dart;
/// [today] is injectable so time-based behavior is unit-testable.
class SubscriptionCalculator {
  const SubscriptionCalculator();

  /// Due dates that should be recorded now: charge dates are
  /// startDate + i months (day clamped), for i = 0, 1, 2, ...
  ///
  /// Window:
  /// - upper bound: [today] (inclusive) — never future-dated charges;
  /// - lower bound: day after [Subscription.lastChargedDate] when set
  ///   (continue from marker), else [Subscription.createdAt]'s date —
  ///   a past startDate only anchors the day-of-month, no backfill (Q6=B).
  List<DateTime> dueDatesBetween(Subscription sub, DateTime today) {
    final day = DateTime(today.year, today.month, today.day);
    final lower = sub.lastChargedDate != null
        ? sub.lastChargedDate!.add(const Duration(days: 1))
        : DateTime(
            sub.createdAt.year, sub.createdAt.month, sub.createdAt.day);

    final due = <DateTime>[];
    for (var i = 0;; i++) {
      final d = InstallmentCalculator.addMonthsClamped(sub.startDate, i);
      if (d.isAfter(day)) break;
      if (!d.isBefore(lower)) due.add(d);
    }
    return due;
  }

  /// Next charge date strictly after [today] (for display; due charges up to
  /// today are materialized on launch). Null when cancelled.
  DateTime? nextChargeDate(Subscription sub, DateTime today) {
    if (!sub.active) return null;
    final day = DateTime(today.year, today.month, today.day);
    for (var i = 0;; i++) {
      final d = InstallmentCalculator.addMonthsClamped(sub.startDate, i);
      if (d.isAfter(day)) return d;
    }
  }
}