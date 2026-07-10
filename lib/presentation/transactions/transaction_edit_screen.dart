import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../application/providers.dart';
import '../../domain/entities.dart';
import '../../domain/services/installment_calculator.dart';
import '../../l10n/gen/app_localizations.dart';

class TransactionEditScreen extends ConsumerStatefulWidget {
  const TransactionEditScreen({super.key, this.existing});

  final TransactionEntry? existing;

  @override
  ConsumerState<TransactionEditScreen> createState() =>
      _TransactionEditScreenState();
}

class _TransactionEditScreenState extends ConsumerState<TransactionEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountCtrl;
  late final TextEditingController _noteCtrl;
  late TransactionKind _kind;
  int? _categoryId;
  int? _walletId;
  late DateTime _date;
  String? _error;
  bool _installments = false;
  int _months = InstallmentCalculator.allowedMonths.first;

  bool get _isEditing => widget.existing != null;

  // Installment option only when creating a new expense (FR-1, Q1=A).
  bool get _installmentsAvailable =>
      !_isEditing && _kind == TransactionKind.expense;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _amountCtrl = TextEditingController(
      text: e == null ? '' : (e.amountMinor / 100).toStringAsFixed(2),
    );
    _noteCtrl = TextEditingController(text: e?.note ?? '');
    _kind = e?.kind ?? TransactionKind.expense;
    _categoryId = e?.categoryId;
    _walletId = e?.walletId;
    _date = e?.date ?? DateTime.now();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;

    final cats = ref.read(categoriesByIdProvider);
    final wallets = ref.read(walletsByIdProvider);
    final category = cats[_categoryId];
    final wallet = wallets[_walletId];
    if (category == null || wallet == null) {
      setState(() =>
          _error = AppLocalizations.of(context).selectCategoryAndWallet);
      return;
    }

    try {
      final controller = ref.read(transactionControllerProvider);
      final asInstallments = _installmentsAvailable && _installments;
      if (asInstallments) {
        await controller.saveInstallment(
          amountText: _amountCtrl.text,
          months: _months,
          category: category,
          wallet: wallet,
          date: _date,
          note: _noteCtrl.text,
        );
      } else {
        await controller.save(
          id: widget.existing?.id,
          amountText: _amountCtrl.text,
          kind: _kind,
          category: category,
          wallet: wallet,
          date: _date,
          note: _noteCtrl.text,
        );
      }
      if (mounted) {
        if (asInstallments) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(AppLocalizations.of(context)
                  .installmentCreated('$_months'))));
        }
        Navigator.of(context).pop();
      }
    } on DomainException catch (e) {
      setState(() => _error = e.message);
    }
  }

  /// Live "{N} monthly payments of X (last Y)" preview; null while the amount
  /// is not yet a valid splittable total.
  String? _installmentPreview(AppLocalizations l) {
    final money = ref.read(moneyFormatterProvider);
    try {
      final total = money.parse(_amountCtrl.text);
      final amounts =
          const InstallmentCalculator().splitAmounts(total, _months);
      return l.installmentPreview(
          '$_months', money.format(amounts.first), money.format(amounts.last));
    } on FormatException {
      return null;
    } on DomainException {
      return null;
    }
  }

  Future<void> _delete() async {
    final id = widget.existing?.id;
    if (id == null) return;
    await ref.read(transactionControllerProvider).delete(id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider).asData?.value ??
        const <Category>[];
    final wallets = ref.watch(walletsProvider).asData?.value ?? const <Wallet>[];
    final kindCats =
        categories.where((c) => c.kind == _kind).toList();
    final l = AppLocalizations.of(context);

    // Reset category if it no longer matches the selected kind.
    if (_categoryId != null &&
        !kindCats.any((c) => c.id == _categoryId)) {
      _categoryId = null;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? l.editTransaction : l.addTransaction),
        actions: [
          if (_isEditing)
            IconButton(
              key: const Key('delete-transaction-button'),
              icon: const Icon(Icons.delete_outline),
              onPressed: _delete,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SegmentedButton<TransactionKind>(
              segments: [
                ButtonSegment(
                    value: TransactionKind.expense,
                    icon: const Icon(Icons.arrow_upward),
                    label: Text(l.expense)),
                ButtonSegment(
                    value: TransactionKind.income,
                    icon: const Icon(Icons.arrow_downward),
                    label: Text(l.income)),
              ],
              selected: {_kind},
              onSelectionChanged: (s) => setState(() => _kind = s.first),
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('amount-field'),
              controller: _amountCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: l.amount,
                prefixIcon: const Icon(Icons.attach_money),
                border: const OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? l.enterAmount : null,
              onChanged: (_) {
                if (_installments) setState(() {});
              },
            ),
            if (_installmentsAvailable) ...[
              const SizedBox(height: 8),
              SwitchListTile(
                key: const Key('installments-toggle'),
                title: Text(l.payInInstallments),
                contentPadding: EdgeInsets.zero,
                value: _installments,
                onChanged: (v) => setState(() => _installments = v),
              ),
              if (_installments) ...[
                SegmentedButton<int>(
                  key: const Key('installment-months-picker'),
                  segments: [
                    for (final m in InstallmentCalculator.allowedMonths)
                      ButtonSegment(value: m, label: Text('$m')),
                  ],
                  selected: {_months},
                  onSelectionChanged: (s) =>
                      setState(() => _months = s.first),
                ),
                const SizedBox(height: 8),
                if (_installmentPreview(l) case final preview?)
                  Text(preview,
                      style: Theme.of(context).textTheme.bodySmall),
              ],
            ],
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              key: const Key('category-dropdown'),
              initialValue: _categoryId,
              decoration: InputDecoration(
                labelText: l.category,
                border: const OutlineInputBorder(),
              ),
              items: kindCats
                  .map((c) => DropdownMenuItem(
                        value: c.id,
                        child: Text(c.name),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _categoryId = v),
              validator: (v) => v == null ? l.selectCategory : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              key: const Key('wallet-dropdown'),
              initialValue: _walletId,
              decoration: InputDecoration(
                labelText: l.wallet,
                border: const OutlineInputBorder(),
              ),
              items: wallets
                  .map((w) => DropdownMenuItem(
                        value: w.id,
                        child: Text(w.name),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _walletId = v),
              validator: (v) => v == null ? l.selectWallet : null,
            ),
            const SizedBox(height: 16),
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
                side: BorderSide(color: Theme.of(context).colorScheme.outline),
              ),
              leading: const Icon(Icons.calendar_today),
              title: Text(DateFormat.yMMMd().format(_date)),
              trailing: const Icon(Icons.edit),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
                );
                if (picked != null) setState(() => _date = picked);
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('note-field'),
              controller: _noteCtrl,
              maxLength: 200,
              decoration: InputDecoration(
                labelText: l.noteOptional,
                border: const OutlineInputBorder(),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            const SizedBox(height: 16),
            FilledButton.icon(
              key: const Key('save-transaction-button'),
              onPressed: _save,
              icon: const Icon(Icons.check),
              label: Text(l.save),
            ),
          ],
        ),
      ),
    );
  }
}
