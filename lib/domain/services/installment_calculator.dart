import '../entities.dart';

/// Stateless installment math (BR-I1..BR-I3). Pure Dart, integer minor units
/// only — no floating point (BR-M3).
class InstallmentCalculator {
  const InstallmentCalculator();

  /// BR-I1: the only supported plan lengths.
  static const List<int> allowedMonths = [3, 6, 10, 12];

  /// Splits [totalMinor] into [months] amounts. Even split; the LAST
  /// installment absorbs the remainder so the sum is always exact (BR-I3).
  /// e.g. 100000 over 3 -> [33333, 33333, 33334].
  List<int> splitAmounts(int totalMinor, int months) {
    if (!allowedMonths.contains(months)) {
      throw const DomainException('Installments must be 3, 6, 10 or 12 months.');
    }
    if (totalMinor <= 0) {
      throw const DomainException('Amount must be greater than zero.');
    }
    if (totalMinor < months) {
      // BR-I2: every installment must be at least 1 minor unit.
      throw const DomainException('Amount is too small to split into installments.');
    }
    final base = totalMinor ~/ months;
    return [
      for (var i = 0; i < months - 1; i++) base,
      totalMinor - base * (months - 1),
    ];
  }

  /// Due dates: [startDate], then the same day of each following month,
  /// clamped to the last day of shorter months (Jan 31 -> Feb 28/29).
  List<DateTime> dueDates(DateTime startDate, int months) {
    return [for (var i = 0; i < months; i++) addMonthsClamped(startDate, i)];
  }

  static DateTime addMonthsClamped(DateTime date, int monthsToAdd) {
    final zeroBased = date.month - 1 + monthsToAdd;
    final year = date.year + zeroBased ~/ 12;
    final month = zeroBased % 12 + 1;
    final day = date.day <= _daysInMonth(year, month)
        ? date.day
        : _daysInMonth(year, month);
    return DateTime(year, month, day);
  }

  static int _daysInMonth(int year, int month) =>
      DateTime(year, month + 1, 0).day;
}