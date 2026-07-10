import 'package:drift/drift.dart';

import 'connection/connection.dart';
import 'seed.dart';

part 'database.g.dart';

class Wallets extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 40)();
  IntColumn get type => integer()();
  IntColumn get iconCodePoint => integer()();
  IntColumn get colorValue => integer()();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();
}

class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 40)();
  IntColumn get kind => integer()(); // TransactionKind index
  IntColumn get iconCodePoint => integer()();
  IntColumn get colorValue => integer()();
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();
}

class InstallmentPlans extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get totalMinor => integer()();
  IntColumn get months => integer()(); // 3, 6, 10, or 12 (BR-I1)
  IntColumn get categoryId =>
      integer().references(Categories, #id)();
  IntColumn get walletId => integer().references(Wallets, #id)();
  DateTimeColumn get startDate => dateTime()();
  TextColumn get note => text().nullable().withLength(max: 200)();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
}

class Subscriptions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 40)();
  IntColumn get amountMinor => integer()();
  IntColumn get categoryId =>
      integer().references(Categories, #id)();
  IntColumn get walletId => integer().references(Wallets, #id)();
  DateTimeColumn get startDate => dateTime()(); // day-of-month anchor
  TextColumn get note => text().nullable().withLength(max: 200)();
  BoolColumn get active => boolean().withDefault(const Constant(true))();
  DateTimeColumn get lastChargedDate =>
      dateTime().nullable()(); // idempotency marker (BR-SB5)
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
}

class Transactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get amountMinor => integer()();
  IntColumn get kind => integer()(); // TransactionKind index
  IntColumn get categoryId =>
      integer().references(Categories, #id)();
  IntColumn get walletId => integer().references(Wallets, #id)();
  DateTimeColumn get date => dateTime()();
  TextColumn get note => text().nullable().withLength(max: 200)();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
  // Set when generated from an installment plan (BR-I4/I5); null otherwise.
  IntColumn get installmentPlanId =>
      integer().nullable().references(InstallmentPlans, #id)();
  IntColumn get installmentNo => integer().nullable()(); // 1-based
  // Set when auto-recorded from a subscription (BR-SB4); null otherwise.
  IntColumn get subscriptionId =>
      integer().nullable().references(Subscriptions, #id)();
}

class Budgets extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get categoryId =>
      integer().references(Categories, #id)();
  IntColumn get limitMinor => integer()();
  TextColumn get month => text().withLength(min: 7, max: 7)(); // YYYY-MM

  @override
  List<Set<Column>> get uniqueKeys => [
        {categoryId, month},
      ];
}

@DriftDatabase(tables: [
  Wallets,
  Categories,
  InstallmentPlans,
  Subscriptions,
  Transactions,
  Budgets
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(openConnection());

  /// For tests: pass an in-memory executor.
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await SeedData.populate(this);
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            // v2: installment plans (additive only).
            await m.createTable(installmentPlans);
            await m.addColumn(transactions, transactions.installmentPlanId);
            await m.addColumn(transactions, transactions.installmentNo);
          }
          if (from < 3) {
            // v3: subscriptions (additive only).
            await m.createTable(subscriptions);
            await m.addColumn(transactions, transactions.subscriptionId);
          }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}
