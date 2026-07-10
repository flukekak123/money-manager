import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_manager/data/backup_service.dart';
import 'package:money_manager/data/database.dart'
    hide Budget, InstallmentPlan, Subscription;
import 'package:money_manager/data/repositories/budget_repository_impl.dart';
import 'package:money_manager/data/repositories/installment_repository_impl.dart';
import 'package:money_manager/data/repositories/subscription_repository_impl.dart';
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
    // v2: an installment plan with its 3 generated transactions.
    final planId = await InstallmentRepositoryImpl(source).createPlan(
      InstallmentPlan(
        id: 0,
        totalMinor: 100000,
        months: 3,
        categoryId: 1,
        walletId: 1,
        startDate: DateTime(2026, 6, 15),
      ),
    );
    // v3: a subscription with its first charge (start = today).
    final subId = await SubscriptionRepositoryImpl(source).create(Subscription(
      id: 0,
      name: 'Netflix',
      amountMinor: 41900,
      categoryId: 1,
      walletId: 1,
      startDate: DateTime.now(),
      createdAt: DateTime.now(),
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
    expect(tgtTxns.length, 5); // 1 manual + 3 installments + 1 sub charge
    final manual = tgtTxns
        .where((t) => t.installmentPlanId == null && t.subscriptionId == null)
        .toList();
    expect(manual.length, 1);
    expect(manual.first.amountMinor, 1250);
    expect(manual.first.note, 'lunch');

    final tgtSubs = await target.select(target.subscriptions).get();
    expect(tgtSubs.length, 1);
    expect(tgtSubs.first.id, subId);
    expect(tgtSubs.first.name, 'Netflix');
    expect(tgtSubs.first.lastChargedDate, isNotNull);
    expect(tgtTxns.where((t) => t.subscriptionId == subId).length, 1);

    final tgtPlans = await target.select(target.installmentPlans).get();
    expect(tgtPlans.length, 1);
    expect(tgtPlans.first.id, planId);
    expect(tgtPlans.first.totalMinor, 100000);
    final installments =
        tgtTxns.where((t) => t.installmentPlanId == planId).toList();
    expect(installments.length, 3);
    expect(installments.map((t) => t.amountMinor).reduce((a, b) => a + b),
        100000);

    final tgtBudgets = await target.select(target.budgets).get();
    expect(tgtBudgets.length, 1);
    expect(tgtBudgets.first.limitMinor, 50000);
    expect(tgtBudgets.first.month, '2026-07');
  });

  test('v1 backup (no installment fields) still imports', () async {
    await BackupService(source).importReplace(
        '{"version": 1, "wallets": [{"id": 1, "name": "Cash", "type": 0, '
        '"iconCodePoint": 1, "colorValue": 1, "archived": false}], '
        '"categories": [{"id": 1, "name": "Food", "kind": 1, '
        '"iconCodePoint": 1, "colorValue": 1, "isDefault": true, '
        '"archived": false}], '
        '"transactions": [{"id": 1, "amountMinor": 900, "kind": 1, '
        '"categoryId": 1, "walletId": 1, "date": "2026-07-01T00:00:00.000", '
        '"note": null, "createdAt": "2026-07-01T00:00:00.000"}], '
        '"budgets": []}');

    final txns = await source.select(source.transactions).get();
    expect(txns.length, 1);
    expect(txns.first.installmentPlanId, isNull);
    expect(txns.first.subscriptionId, isNull);
    expect(await source.select(source.installmentPlans).get(), isEmpty);
    expect(await source.select(source.subscriptions).get(), isEmpty);
  });

  test('v2 backup (no subscriptions) still imports', () async {
    await BackupService(source).importReplace(
        '{"version": 2, "wallets": [{"id": 1, "name": "Cash", "type": 0, '
        '"iconCodePoint": 1, "colorValue": 1, "archived": false}], '
        '"categories": [{"id": 1, "name": "Food", "kind": 1, '
        '"iconCodePoint": 1, "colorValue": 1, "isDefault": true, '
        '"archived": false}], '
        '"installmentPlans": [], '
        '"transactions": [{"id": 1, "amountMinor": 900, "kind": 1, '
        '"categoryId": 1, "walletId": 1, "date": "2026-07-01T00:00:00.000", '
        '"note": null, "createdAt": "2026-07-01T00:00:00.000", '
        '"installmentPlanId": null, "installmentNo": null}], '
        '"budgets": []}');

    final txns = await source.select(source.transactions).get();
    expect(txns.length, 1);
    expect(await source.select(source.subscriptions).get(), isEmpty);
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
