import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_manager/data/database.dart' hide InstallmentPlan;
import 'package:money_manager/data/repositories/installment_repository_impl.dart';
import 'package:money_manager/data/repositories/transaction_repository_impl.dart';
import 'package:money_manager/domain/entities.dart';

void main() {
  late AppDatabase db;
  late InstallmentRepositoryImpl repo;
  late TransactionRepositoryImpl txnRepo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = InstallmentRepositoryImpl(db);
    txnRepo = TransactionRepositoryImpl(db);
  });

  tearDown(() async {
    await db.close();
  });

  InstallmentPlan plan({int total = 100000, int months = 3}) => InstallmentPlan(
        id: 0,
        totalMinor: total,
        months: months,
        categoryId: 1, // Food (seeded expense)
        walletId: 1,
        startDate: DateTime(2026, 1, 31),
        note: 'TV',
      );

  test('createPlan inserts plan and N linked transactions (BR-I5)', () async {
    final planId = await repo.createPlan(plan(months: 6));

    final plans = await repo.watchAll().first;
    expect(plans.length, 1);
    expect(plans.first.totalMinor, 100000);

    final txns = await repo.watchInstallments(planId).first;
    expect(txns.length, 6);
    expect(txns.map((t) => t.amountMinor).reduce((a, b) => a + b), 100000);
    expect(txns.map((t) => t.installmentNo).toList(), [1, 2, 3, 4, 5, 6]);
    expect(txns.every((t) => t.installmentPlanId == planId), isTrue);
    expect(txns.every((t) => t.kind == TransactionKind.expense), isTrue);
    // Day-clamped dates from Jan 31.
    expect(txns[1].date, DateTime(2026, 2, 28));
  });

  test('createPlan rejects invalid input without writing (BR-I1/I2)', () async {
    expect(() => repo.createPlan(plan(months: 5)),
        throwsA(isA<DomainException>()));
    expect(() => repo.createPlan(plan(total: 0)),
        throwsA(isA<DomainException>()));

    expect(await repo.watchAll().first, isEmpty);
    expect(await txnRepo.watchAll().first, isEmpty);
  });

  test('installment transactions cannot be edited or deleted (BR-I4)',
      () async {
    final planId = await repo.createPlan(plan());
    final txns = await repo.watchInstallments(planId).first;
    final first = txns.first;

    expect(() => txnRepo.delete(first.id), throwsA(isA<DomainException>()));
    expect(
      () => txnRepo.update(TransactionEntry(
        id: first.id,
        amountMinor: 1,
        kind: first.kind,
        categoryId: first.categoryId,
        walletId: first.walletId,
        date: first.date,
      )),
      throwsA(isA<DomainException>()),
    );

    // Untouched.
    expect((await repo.watchInstallments(planId).first).length, 3);
  });

  test('deletePlan removes plan and all installments atomically (BR-I5)',
      () async {
    final planId = await repo.createPlan(plan(months: 12));
    // A normal transaction must survive the plan delete.
    await txnRepo.add(TransactionEntry(
      id: 0,
      amountMinor: 500,
      kind: TransactionKind.expense,
      categoryId: 1,
      walletId: 1,
      date: DateTime(2026, 1, 5),
    ));

    await repo.deletePlan(planId);

    expect(await repo.watchAll().first, isEmpty);
    final remaining = await txnRepo.watchAll().first;
    expect(remaining.length, 1);
    expect(remaining.first.amountMinor, 500);
  });

  test('normal transactions still editable and deletable', () async {
    final id = await txnRepo.add(TransactionEntry(
      id: 0,
      amountMinor: 500,
      kind: TransactionKind.expense,
      categoryId: 1,
      walletId: 1,
      date: DateTime(2026, 1, 5),
    ));
    await txnRepo.delete(id);
    expect(await txnRepo.watchAll().first, isEmpty);
  });
}