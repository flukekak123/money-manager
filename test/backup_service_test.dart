import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_manager/data/backup_service.dart';
import 'package:money_manager/data/database.dart' hide Budget;
import 'package:money_manager/data/repositories/budget_repository_impl.dart';
import 'package:money_manager/data/repositories/transaction_repository_impl.dart';
import 'package:money_manager/domain/entities.dart';

void main() {
  late AppDatabase source;

  setUp(() {
    source = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await source.close();
  });

  test('export then import into a fresh db preserves rows and ids', () async {
    // Seeded db already has 1 wallet + 9 categories. Add a txn and a budget.
    await TransactionRepositoryImpl(source).add(TransactionEntry(
      id: 0,
      amountMinor: 1250,
      kind: TransactionKind.expense,
      categoryId: 1,
      walletId: 1,
      date: DateTime(2026, 7, 1),
      note: 'lunch',
    ));
    await BudgetRepositoryImpl(source).upsert(const Budget(
      id: 0,
      categoryId: 1,
      limitMinor: 50000,
      month: '2026-07',
    ));

    final json = await BackupService(source).exportJson();

    // Import into a second (also seeded) db — import must replace seed data.
    final target = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(target.close);
    await BackupService(target).importReplace(json);

    final srcWallets = await source.select(source.wallets).get();
    final tgtWallets = await target.select(target.wallets).get();
    expect(tgtWallets.length, srcWallets.length);
    expect(tgtWallets.map((w) => w.id), srcWallets.map((w) => w.id));

    final tgtCats = await target.select(target.categories).get();
    expect(tgtCats.length, 9);

    final tgtTxns = await target.select(target.transactions).get();
    expect(tgtTxns.length, 1);
    expect(tgtTxns.first.amountMinor, 1250);
    expect(tgtTxns.first.categoryId, 1);
    expect(tgtTxns.first.note, 'lunch');

    final tgtBudgets = await target.select(target.budgets).get();
    expect(tgtBudgets.length, 1);
    expect(tgtBudgets.first.limitMinor, 50000);
    expect(tgtBudgets.first.month, '2026-07');
  });

  test('import rejects unsupported version', () async {
    expect(
      () => BackupService(source).importReplace(
          '{"version": 99, "wallets": [], "categories": [], '
          '"transactions": [], "budgets": []}'),
      throwsA(isA<DomainException>()),
    );
  });

  test('import rejects malformed json', () async {
    expect(
      () => BackupService(source).importReplace('not json at all'),
      throwsA(isA<DomainException>()),
    );
  });

  test('failed import rolls back — original data intact', () async {
    final before = await source.select(source.categories).get();
    // Lists are well-formed (pass pre-validation) but a transaction element has
    // a bad type, so the failure occurs INSIDE the db transaction after the
    // wipe — the rollback must restore the seed data.
    try {
      await BackupService(source).importReplace(
          '{"version": 1, "wallets": [], "categories": [], '
          '"transactions": [{"id": "not-an-int"}], "budgets": []}');
      fail('expected DomainException');
    } on DomainException {
      // expected
    }
    final after = await source.select(source.categories).get();
    expect(after.length, before.length,
        reason: 'rollback must leave seed categories intact');
  });
}
