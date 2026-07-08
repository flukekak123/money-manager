/// Date helpers for month bucketing (`YYYY-MM`) and ranges.
class MonthKey {
  /// Returns `YYYY-MM` for the given date.
  static String of(DateTime date) {
    final m = date.month.toString().padLeft(2, '0');
    return '${date.year}-$m';
  }

  static String current() => of(DateTime.now());

  /// First instant of the month for a `YYYY-MM` key.
  static DateTime start(String yyyymm) {
    final parts = yyyymm.split('-');
    return DateTime(int.parse(parts[0]), int.parse(parts[1]), 1);
  }

  /// First instant of the following month (exclusive end).
  static DateTime endExclusive(String yyyymm) {
    final s = start(yyyymm);
    return DateTime(s.year, s.month + 1, 1);
  }
}

class DateRange {
  const DateRange(this.start, this.endExclusive);
  final DateTime start;
  final DateTime endExclusive;

  factory DateRange.month(String yyyymm) =>
      DateRange(MonthKey.start(yyyymm), MonthKey.endExclusive(yyyymm));

  int get days => endExclusive.difference(start).inDays;

  bool contains(DateTime d) =>
      !d.isBefore(start) && d.isBefore(endExclusive);
}
