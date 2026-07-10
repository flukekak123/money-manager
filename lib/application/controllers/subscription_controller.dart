import '../../core/money.dart';
import '../../domain/entities.dart';
import '../../domain/repositories.dart';

/// Validates and persists subscriptions (BR-SB1..SB3). Throws
/// [DomainException] on rule violations for inline UI errors.
class SubscriptionController {
  SubscriptionController({
    required SubscriptionRepository repository,
    required MoneyFormatter money,
  })  : _repo = repository,
        _money = money;

  final SubscriptionRepository _repo;
  final MoneyFormatter _money;

  int _parseAmount(String amountText) {
    int minor;
    try {
      minor = _money.parse(amountText);
    } on FormatException {
      throw const DomainException('Enter a valid amount.');
    }
    if (minor <= 0) {
      throw const DomainException('Amount must be greater than zero.');
    }
    return minor;
  }

  void _validate({
    required String name,
    required Category category,
    required Wallet wallet,
    String? note,
  }) {
    if (name.trim().isEmpty || name.trim().length > 40) {
      throw const DomainException('Enter a name (max 40 characters).');
    }
    if (category.kind != TransactionKind.expense) {
      throw const DomainException('Subscriptions need an expense category.');
    }
    if (category.archived) {
      throw const DomainException('Selected category is archived.');
    }
    if (wallet.archived) {
      throw const DomainException('Selected wallet is archived.');
    }
    if ((note?.length ?? 0) > 200) {
      throw const DomainException('Note is too long (max 200 characters).');
    }
  }

  Future<void> save({
    Subscription? existing,
    required String name,
    required String amountText,
    required Category category,
    required Wallet wallet,
    required DateTime startDate,
    String? note,
  }) async {
    final amountMinor = _parseAmount(amountText);
    _validate(name: name, category: category, wallet: wallet, note: note);
    final cleanNote =
        (note != null && note.trim().isEmpty) ? null : note?.trim();

    if (existing == null) {
      await _repo.create(Subscription(
        id: 0,
        name: name.trim(),
        amountMinor: amountMinor,
        categoryId: category.id,
        walletId: wallet.id,
        startDate: startDate,
        createdAt: DateTime.now(),
        note: cleanNote,
      ));
    } else {
      // BR-SB6: affects future charges only.
      await _repo.update(existing.copyWith(
        name: name.trim(),
        amountMinor: amountMinor,
        categoryId: category.id,
        walletId: wallet.id,
        startDate: startDate,
        note: cleanNote,
      ));
    }
  }

  Future<void> cancel(int id) => _repo.cancel(id);

  Future<void> delete(int id) => _repo.delete(id);
}