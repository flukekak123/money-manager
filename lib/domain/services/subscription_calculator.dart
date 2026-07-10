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
  /// - never charged yet (Q6=B'): the CURRENT billing period only — the
  ///   latest due date on/before today. One charge, no deeper backfill, so
  ///   a new subscription shows up in this month's expenses immediately;
  /// - already charged: everything after the [Subscription.lastChargedDate]
  ///   marker (catch-up for missed months).
  List<DateTime> dueDatesBetween(Subscription sub, DateTime today) {
    final day = DateTime(today.year, today.month, today.day);

    if (sub.lastChargedDate == null) {
      DateTime? latest;
      for (var i = 0;; i++) {
        final d = InstallmentCalculator.addMonthsClamped(sub.startDate, i);
        if (d.isAfter(day)) break;
        latest = d;
      }
      return latest == null ? const [] : [latest];
    }

    final lower = sub.lastChargedDate!.add(const Duration(days: 1));
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