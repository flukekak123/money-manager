import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../theme.dart';

/// Displays an integer minor-unit amount formatted in the active currency.
class MoneyText extends ConsumerWidget {
  const MoneyText(
    this.amountMinor, {
    super.key,
    this.signed = false,
    this.colorBySign = false,
    this.style,
  });

  final int amountMinor;
  final bool signed;
  final bool colorBySign;
  final TextStyle? style;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final money = ref.watch(moneyFormatterProvider);
    final text = money.format(amountMinor, signed: signed);
    final baseStyle = style ?? const TextStyle();
    final resolved = colorBySign
        ? baseStyle.copyWith(color: AmountColors.of(context, amountMinor))
        : baseStyle;
    return Text(text, style: resolved);
  }
}
