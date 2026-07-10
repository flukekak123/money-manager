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

abstract class InstallmentRepository {
  Stream<List<InstallmentPlan>> watchAll();
  Future<InstallmentPlan?> getById(int id);

  /// Installment transactions of a plan, ordered by installmentNo.
  Stream<List<TransactionEntry>> watchInstallments(int planId);

  /// Inserts the plan and generates its N linked expense transactions in one
  /// DB transaction (BR-I5). Returns the plan id.
  Future<int> createPlan(InstallmentPlan plan);

  /// Deletes the plan and ALL its linked transactions atomically (BR-I5).
  Future<void> deletePlan(int id);
}

abstract class SubscriptionRepository {
  /// Active first, then cancelled; newest first within each group.
  Stream<List<Subscription>> watchAll();
  Future<Subscription?> getById(int id);

  /// Recorded charges of one subscription, newest first.
  Stream<List<TransactionEntry>> watchCharges(int subscriptionId);

  /// Creates the subscription, then materializes any charge due today.
  Future<int> create(Subscription sub);

  /// BR-SB6: changes apply to future charges only. Re-materializes after.
  Future<void> update(Subscription sub);

  /// BR-SB7: stops future charges, keeps recorded transactions.
  Future<void> cancel(int id);

  /// BR-SB8: allowed only when the subscription has no recorded charges.
  Future<void> delete(int id);

  /// Records every due-but-unrecorded charge for all active subscriptions
  /// (BR-SB5: atomic + idempotent per subscription). Returns rows created.
  /// [today] injectable for tests.
  Future<int> materializeDueCharges({DateTime? today});
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
