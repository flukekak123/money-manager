import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../application/providers.dart';
import '../../domain/entities.dart';
import '../../l10n/gen/app_localizations.dart';

class SubscriptionEditScreen extends ConsumerStatefulWidget {
  const SubscriptionEditScreen({super.key, this.existing});

  final Subscription? existing;

  @override
  ConsumerState<SubscriptionEditScreen> createState() =>
      _SubscriptionEditScreenState();
}

class _SubscriptionEditScreenState
    extends ConsumerState<SubscriptionEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _amountCtrl;
  late final TextEditingController _noteCtrl;
  int? _categoryId;
  int? _walletId;
  late DateTime _startDate;
  String? _error;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?.name ?? '');
    _amountCtrl = TextEditingController(
      text: e == null ? '' : (e.amountMinor / 100).toStringAsFixed(2),
    );
    _noteCtrl = TextEditingController(text: e?.note ?? '');
    _categoryId = e?.categoryId;
    _walletId = e?.walletId;
    _startDate = e?.startDate ?? DateTime.now();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;

    final category = ref.read(categoriesByIdProvider)[_categoryId];
    final wallet = ref.read(walletsByIdProvider)[_walletId];
    if (category == null || wallet == null) {
      setState(
          () => _error = AppLocalizations.of(context).selectCategoryAndWallet);
      return;
    }

    try {
      await ref.read(subscriptionControllerProvider).save(
            existing: widget.existing,
            name: _nameCtrl.text,
            amountText: _amountCtrl.text,
            category: category,
            wallet: wallet,
            startDate: _startDate,
            note: _noteCtrl.text,
          );
      if (mounted) Navigator.of(context).pop();
    } on DomainException catch (e) {
      setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final categories =
        ref.watch(categoriesProvider).asData?.value ?? const <Category>[];
    final wallets =
        ref.watch(walletsProvider).asData?.value ?? const <Wallet>[];
    final expenseCats =
        categories.where((c) => c.kind == TransactionKind.expense).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? l.editSubscription : l.newSubscription),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              key: const Key('subscription-name-field'),
              controller: _nameCtrl,
              maxLength: 40,
              decoration: InputDecoration(
                labelText: l.subscriptionName,
                border: const OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? l.subscriptionName : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('subscription-amount-field'),
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
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              key: const Key('subscription-category-dropdown'),
              initialValue: _categoryId,
              decoration: InputDecoration(
                labelText: l.category,
                border: const OutlineInputBorder(),
              ),
              items: expenseCats
                  .map((c) =>
                      DropdownMenuItem(value: c.id, child: Text(c.name)))
                  .toList(),
              onChanged: (v) => setState(() => _categoryId = v),
              validator: (v) => v == null ? l.selectCategory : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              key: const Key('subscription-wallet-dropdown'),
              initialValue: _walletId,
              decoration: InputDecoration(
                labelText: l.wallet,
                border: const OutlineInputBorder(),
              ),
              items: wallets
                  .map((w) =>
                      DropdownMenuItem(value: w.id, child: Text(w.name)))
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
              title: Text(l.startDate),
              subtitle: Text(DateFormat.yMMMd().format(_startDate)),
              trailing: const Icon(Icons.edit),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _startDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
                );
                if (picked != null) setState(() => _startDate = picked);
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('subscription-note-field'),
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
              key: const Key('save-subscription-button'),
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