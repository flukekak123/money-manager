import 'package:flutter_test/flutter_test.dart';
import 'package:money_manager/core/money.dart';

void main() {
  const usd = MoneyFormatter('USD', locale: 'en_US');

  group('MoneyFormatter.parse', () {
    test('parses whole and fractional amounts to minor units', () {
      expect(usd.parse('1234.56'), 123456);
      expect(usd.parse('0.05'), 5);
      expect(usd.parse('10'), 1000);
    });

    test('strips grouping separators and currency symbols', () {
      expect(usd.parse(r'$1,234.56'), 123456);
      expect(usd.parse('1,000'), 100000);
    });

    test('truncates extra decimal precision', () {
      expect(usd.parse('1.239'), 123);
    });

    test('pads missing decimals', () {
      expect(usd.parse('2.5'), 250);
    });

    test('throws on empty or invalid input', () {
      expect(() => usd.parse(''), throwsFormatException);
      expect(() => usd.parse('abc'), throwsFormatException);
      expect(() => usd.parse('.'), throwsFormatException);
    });
  });

  group('MoneyFormatter.format', () {
    test('formats minor units with symbol', () {
      expect(usd.format(123456), r'$1,234.56');
      expect(usd.format(5), r'$0.05');
    });

    test('negative amounts', () {
      expect(usd.format(-100), r'-$1.00');
    });

    test('signed formatting', () {
      expect(usd.format(100, signed: true), r'+$1.00');
      expect(usd.format(-100, signed: true), r'-$1.00');
    });
  });

  test('round trip parse/format is stable', () {
    for (final s in ['0.00', '1.00', '99.99', '1,000.00']) {
      final minor = usd.parse(s);
      final formatted = usd.format(minor);
      expect(usd.parse(formatted), minor);
    }
  });

  test('zero-decimal currency (JPY)', () {
    const jpy = MoneyFormatter('JPY', locale: 'ja_JP');
    expect(jpy.parse('1500'), 1500);
  });
}
