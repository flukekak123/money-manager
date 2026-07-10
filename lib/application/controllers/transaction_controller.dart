import '../../core/money.dart';
import '../../domain/entities.dart';
import '../../domain/repositories.dart';
import '../../domain/services/installment_calculator.dart';

/// Validates and persists transactions. Throws [DomainException] on rule
/// violations so the UI can show inline errors.
class TransactionController {
  TransactionController({
    required TransactionRepository repository,
    required InstallmentRepository installments,
    required MoneyFormatter money,
  })  : _repo = repository,
        _installments = installments,
        _money = money;

  final TransactionRepository _repo;
  final InstallmentRepository _installments;
  final MoneyFormatter _money;

  /// Parses [amountText] and validates against business rules, returning the
  /// resolved amount in minor units. Throws [DomainException] on failure.
  int parseAmount(String amountText) {
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
    required int amountMinor,
    required TransactionKind kind,
    required Category category,
    required Wallet wallet,
    required DateTime date,
    String? note,
  }) {
    if (amountMinor <= 0) {
      throw const DomainException('Amount must be greater than zero.');
    }
    if (category.archived) {
      throw const DomainException('Selected category is archived.');
    }
    if (category.kind != kind) {
      throw const DomainException('Category type must match transaction type.');
    }
    if (wallet.archived) {
      throw const DomainException('Selected wallet is archived.');
    }
    if (date.isAfter(DateTime.now())) {
      throw const DomainException('Date cannot be in the future.');
    }
    if ((note?.length ?? 0) > 200) {
      throw const DomainException('Note is too long (max 200 characters).');
    }
  }

  Future<void> save({
    int? id,
    required String amountText,
    required TransactionKind kind,
    required Category category,
    required Wallet wallet,
    required DateTime date,
    String? note,
  }) async {
    final amountMinor = parseAmount(amountText);
    _validate(
      amountMinor: amountMinor,
      kind: kind,
      category: category,
      wallet: wallet,
      date: date,
      note: note,
    );
    final entry = TransactionEntry(
      id: id ?? 0,
      amountMinor: amountMinor,
      kind: kind,
      categoryId: category.id,
      walletId: wallet.id,
      date: date,
      note: (note != null && note.trim().isEmpty) ? null : note?.trim(),
    );
    if (id == null) {
      await _repo.add(entry);
    } else {
      await _repo.update(entry);
    }
  }

  Future<void> delete(int id) => _repo.delete(id);

  /// Creates an installment purchase: validates, then persists a plan plus its
  /// N monthly expense transactions atomically (FR-1, BR-I1..I5).
  /// [amountText] is the TOTAL purchase amount.
  Future<void> saveInstallment({
    required String amountText,
    required int months,
    required Category category,
    required Wallet wallet,
    required DateTime date,
    String? note,
  }) async {
    final totalMinor = parseAmount(amountText);
    _validate(
      amountMinor: totalMinor,
      kind: TransactionKind.expense,
      category: category,
      wallet: wallet,
      date: date, // BR-I7: purchase date itself must not be in the future
      note: note,
    );
    // Throws for invalid months/amount too small (BR-I1/I2).
    const InstallmentCalculator().splitAmounts(totalMinor, months);

    await _installments.createPlan(InstallmentPlan(
      id: 0,
      totalMinor: totalMinor,
      months: months,
      categoryId: category.id,
      walletId: wallet.id,
      startDate: date,
      note: (note != null && note.trim().isEmpty) ? null : note?.trim(),
    ));
  }

  Future<void> deleteInstallmentPlan(int planId) =>
      _installments.deletePlan(planId);
}
