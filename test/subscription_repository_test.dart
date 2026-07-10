import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_manager/data/database.dart' hide Subscription;
import 'package:money_manager/data/repositories/subscription_repository_impl.dart';
import 'package:money_manager/data/repositories/transaction_repository_impl.dart';
import 'package:money_manager/domain/entities.dart';

void main() {
  late AppDatabase db;
  late SubscriptionRepositoryImpl repo;
  late TransactionRepositoryImpl txnRepo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = SubscriptionRepositoryImpl(db);
    txnRepo = TransactionRepositoryImpl(db);
  });

  tearDown(() async {
    await db.close();
  });

  Future<int> createSub({DateTime? start}) async {
    // create() materializes with real "now" — use a start date of today so
    // behavior is deterministic: exactly one charge (today) gets recorded.
    return repo.create(Subscription(
      id: 0,
      name: 'Netflix',
      amountMinor: 41900,
      categoryId: 1, // Food (seeded expense) — fine for tests
      walletId: 1,
      startDate: start ?? DateTime.now(),
      createdAt: DateTime.now(),
    ));
  }

  test('create materializes the charge due today', () async {
    final id = await createSub();
    final charges = await repo.watchCharges(id).first;
    expect(charges.length, 1);
    expect(charges.first.amountMinor, 41900);
    expect(charges.first.subscriptionId, id);
    expect(charges.first.kind, TransactionKind.expense);

    final sub = await repo.getById(id);
    expect(sub!.lastChargedDate, isNotNull);
  });

  test('materialize is idempotent — double run creates nothing (BR-SB5)',
      () async {
    final id = await createSub();
    final before = (await repo.watchCharges(id).first).length;
    expect(await repo.materializeDueCharges(), 0);
    expect(await repo.materializeDueCharges(), 0);
    expect((await repo.watchCharges(id).first).length, before);
  });

  test('catch-up: missed months recorded on next run', () async {
    final id = await createSub();
    // Pretend 3 months pass without opening the app.
    final future = DateTime.now();
    final in3Months = DateTime(future.year, future.month + 3, future.day);
    final created = await repo.materializeDueCharges(today: in3Months);
    expect(created, 3);
    expect((await repo.watchCharges(id).first).length, 4);
  });

  test('cancel stops future charges, keeps history (BR-SB7)', () async {
    final id = await createSub();
    await repo.cancel(id);
    final now = DateTime.now();
    final nextMonth = DateTime(now.year, now.month + 1, now.day);
    expect(await repo.materializeDueCharges(today: nextMonth), 0);
    expect((await repo.watchCharges(id).first).length, 1); // history kept
  });

  test('edit affects future charges only (BR-SB6)', () async {
    final id = await createSub();
    final sub = (await repo.getById(id))!;
    await repo.update(sub.copyWith(amountMinor: 49900));

    final now = DateTime.now();
    final nextMonth = DateTime(now.year, now.month + 1, now.day);
    await repo.materializeDueCharges(today: nextMonth);

    final charges = await repo.watchCharges(id).first; // newest first
    expect(charges.length, 2);
    expect(charges.first.amountMinor, 49900); // new price
    expect(charges.last.amountMinor, 41900); // history untouched
  });

  test('charge transactions are locked (BR-SB4)', () async {
    final id = await createSub();
    final charge = (await repo.watchCharges(id).first).first;

    expect(() => txnRepo.delete(charge.id), throwsA(isA<DomainException>()));
    expect(
      () => txnRepo.update(TransactionEntry(
        id: charge.id,
        amountMinor: 1,
        kind: charge.kind,
        categoryId: charge.categoryId,
        walletId: charge.walletId,
        date: charge.date,
      )),
      throwsA(isA<DomainException>()),
    );
  });

  test('delete only when no charges (BR-SB8)', () async {
    final id = await createSub();
    expect(() => repo.delete(id), throwsA(isA<DomainException>()));

    // Future-dated start: no charge materialized yet -> deletable.
    final now = DateTime.now();
    final id2 = await repo.create(Subscription(
      id: 0,
      name: 'Spotify',
      amountMinor: 14900,
      categoryId: 1,
      walletId: 1,
      startDate: DateTime(now.year, now.month + 1, now.day),
      createdAt: now,
    ));
    expect((await repo.watchCharges(id2).first), isEmpty);
    await repo.delete(id2);
    expect(await repo.getById(id2), isNull);
  });
}