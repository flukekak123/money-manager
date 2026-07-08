import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_manager/data/database.dart';
import 'package:money_manager/data/repositories/transaction_repository_impl.dart';
import 'package:money_manager/data/repositories/wallet_repository_impl.dart';
import 'package:money_manager/domain/entities.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test('first run seeds default wallet and categories', () async {
    final categories = await db.select(db.categories).get();
    expect(categories.length, 9);
    expect(categories.where((c) => c.kind == TransactionKind.income.index).length,
        2);

    final wallets = await db.select(db.wallets).get();
    expect(wallets.length, 1);
    expect(wallets.first.name, 'Cash');
  });

  test('adding transactions updates wallet balance', () async {
    final txnRepo = TransactionRepositoryImpl(db);
    final walletRepo = WalletRepositoryImpl(db);

    await txnRepo.add(TransactionEntry(
      id: 0,
      amountMinor: 5000,
      kind: TransactionKind.income,
      categoryId: 8, // Salary (seeded income)
      walletId: 1,
      date: DateTime.now(),
    ));
    await txnRepo.add(TransactionEntry(
      id: 0,
      amountMinor: 2000,
      kind: TransactionKind.expense,
      categoryId: 1, // Food
      walletId: 1,
      date: DateTime.now(),
    ));

    final balance = await walletRepo.watchBalanceMinor(1).first;
    expect(balance, 3000);
  });

  test('cannot delete wallet with transactions', () async {
    final txnRepo = TransactionRepositoryImpl(db);
    final walletRepo = WalletRepositoryImpl(db);
    await txnRepo.add(TransactionEntry(
      id: 0,
      amountMinor: 1000,
      kind: TransactionKind.expense,
      categoryId: 1,
      walletId: 1,
      date: DateTime.now(),
    ));

    expect(
      () => walletRepo.delete(1),
      throwsA(isA<DomainException>()),
    );
  });
}
