import '../../core/money.dart';
import '../../domain/entities.dart';
import '../../domain/repositories.dart';

class BudgetController {
  BudgetController({
    required BudgetRepository repository,
    required MoneyFormatter money,
  })  : _repo = repository,
        _money = money;

  final BudgetRepository _repo;
  final MoneyFormatter _money;

  Future<void> save({
    required Category category,
    required String limitText,
    required String month,
  }) async {
    if (category.kind != TransactionKind.expense) {
      throw const DomainException('Budgets apply to expense categories only.');
    }
    int limit;
    try {
      limit = _money.parse(limitText);
    } on FormatException {
      throw const DomainException('Enter a valid limit.');
    }
    if (limit <= 0) {
      throw const DomainException('Budget limit must be greater than zero.');
    }
    await _repo.upsert(
      Budget(id: 0, categoryId: category.id, limitMinor: limit, month: month),
    );
  }

  Future<void> delete(int id) => _repo.delete(id);
}
