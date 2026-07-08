import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_manager/l10n/gen/app_localizations.dart';

void main() {
  test('English and Thai localizations both load with distinct strings',
      () async {
    final en = await AppLocalizations.delegate.load(const Locale('en'));
    final th = await AppLocalizations.delegate.load(const Locale('th'));

    expect(en.navHome, 'Home');
    expect(th.navHome, 'หน้าแรก');
    expect(th.save, 'บันทึก');
    expect(th.expense, 'รายจ่าย');
    expect(th.walletTypeCash, 'เงินสด');
    // placeholder interpolation works in Thai
    expect(th.errorWithMessage('X'), 'ข้อผิดพลาด: X');
  });

  test('th is a supported locale', () {
    expect(
      AppLocalizations.supportedLocales.map((l) => l.languageCode),
      containsAll(<String>['en', 'th']),
    );
  });
}
