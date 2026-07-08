import 'package:intl/intl.dart';

/// Currency-safe money helpers. All amounts are stored and computed as
/// integer minor units (e.g. cents). Never use `double` for money.
class MoneyFormatter {
  const MoneyFormatter(this.currencyCode, {this.locale});

  final String currencyCode;
  final String? locale;

  int get _decimalDigits {
    try {
      return NumberFormat.simpleCurrency(
        locale: locale,
        name: currencyCode,
      ).decimalDigits ??
          2;
    } catch (_) {
      return 2;
    }
  }

  NumberFormat get _fmt => NumberFormat.simpleCurrency(
        locale: locale,
        name: currencyCode,
      );

  /// Format integer minor units into a display string, e.g. 123456 -> "$1,234.56".
  String format(int amountMinor, {bool signed = false}) {
    final digits = _decimalDigits;
    final value = amountMinor / _pow10(digits);
    final text = _fmt.format(value.abs());
    if (signed) {
      final sign = amountMinor < 0 ? '-' : '+';
      return '$sign$text';
    }
    return amountMinor < 0 ? '-$text' : text;
  }

  /// Parse a user-entered amount string into integer minor units.
  /// Throws [FormatException] on invalid input. Result is always >= 0.
  int parse(String input) {
    final digits = _decimalDigits;
    var cleaned = input.trim();
    if (cleaned.isEmpty) {
      throw const FormatException('Amount is empty');
    }

    // Determine decimal separator from locale; default '.'.
    final symbols = NumberFormat.simpleCurrency(locale: locale).symbols;
    final decimalSep = symbols.DECIMAL_SEP;
    final groupSep = symbols.GROUP_SEP;

    // Remove currency symbols, spaces and grouping separators.
    cleaned = cleaned.replaceAll(RegExp(r'[^0-9\-.,]'), '');
    cleaned = cleaned.replaceAll(groupSep, '');
    if (decimalSep != '.') {
      cleaned = cleaned.replaceAll(decimalSep, '.');
    }

    final negative = cleaned.startsWith('-');
    if (negative) cleaned = cleaned.substring(1);
    cleaned = cleaned.replaceAll('-', '');

    if (cleaned.isEmpty || cleaned == '.') {
      throw FormatException('Invalid amount: $input');
    }

    final parts = cleaned.split('.');
    if (parts.length > 2) {
      throw FormatException('Invalid amount: $input');
    }

    final wholeStr = parts[0].isEmpty ? '0' : parts[0];
    var fracStr = parts.length == 2 ? parts[1] : '';
    if (fracStr.length > digits) {
      fracStr = fracStr.substring(0, digits); // truncate extra precision
    } else {
      fracStr = fracStr.padRight(digits, '0');
    }

    final whole = int.parse(wholeStr);
    final frac = digits == 0 ? 0 : int.parse(fracStr);
    final minor = whole * _pow10(digits) + frac;
    return negative ? -minor : minor;
  }

  static int _pow10(int n) {
    var r = 1;
    for (var i = 0; i < n; i++) {
      r *= 10;
    }
    return r;
  }
}
