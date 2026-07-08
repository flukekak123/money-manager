import 'entities.dart';

abstract class WalletRepository {
  Stream<List<Wallet>> watchAll({bool includeArchived = false});
  Stream<int> watchBalanceMinor(int walletId);
  Future<int> add(Wallet wallet);
  Future<void> update(Wallet wallet);
  Future<void> archive(int id);
  Future<void> delete(int id);
}

abstract class CategoryRepository {
  Stream<List<Category>> watchAll({bool includeArchived = false});
  Future<int> add(Category category);
  Future<void> update(Category category);
  Future<void> archive(int id);
  Future<void> delete(int id);
}

abstract class TransactionRepository {
  Stream<List<TransactionEntry>> watchAll();
  Stream<List<TransactionEntry>> watchByMonth(String yyyymm);
  Future<int> add(TransactionEntry entry);
  Future<void> update(TransactionEntry entry);
  Future<void> delete(int id);
}

abstract class BudgetRepository {
  Stream<List<Budget>> watchByMonth(String yyyymm);
  Future<void> upsert(Budget budget);
  Future<void> delete(int id);
}

abstract class SettingsRepository {
  Future<AppSettings> load();
  Future<void> save(AppSettings settings);
}
