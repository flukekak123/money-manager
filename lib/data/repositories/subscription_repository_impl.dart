import 'package:drift/drift.dart';

import '../../domain/entities.dart' as d;
import '../../domain/repositories.dart';
import '../../domain/services/subscription_calculator.dart';
import '../database.dart';

class SubscriptionRepositoryImpl implements SubscriptionRepository {
  SubscriptionRepositoryImpl(this._db);
  final AppDatabase _db;

  static const _calc = SubscriptionCalculator();

  d.Subscription _map(Subscription r) => d.Subscription(
        id: r.id,
        name: r.name,
        amountMinor: r.amountMinor,
        categoryId: r.categoryId,
        walletId: r.walletId,
        startDate: r.startDate,
        createdAt: r.createdAt,
        note: r.note,
        active: r.active,
        lastChargedDate: r.lastChargedDate,
      );

  d.TransactionEntry _mapTxn(Transaction r) => d.TransactionEntry(
        id: r.id,
        amountMinor: r.amountMinor,
        kind: d.TransactionKind.values[r.kind],
        categoryId: r.categoryId,
        walletId: r.walletId,
        date: r.date,
        note: r.note,
        installmentPlanId: r.installmentPlanId,
        installmentNo: r.installmentNo,
        subscriptionId: r.subscriptionId,
      );

  @override
  Stream<List<d.Subscription>> watchAll() {
    final q = _db.select(_db.subscriptions)
      ..orderBy([
        (s) => OrderingTerm.desc(s.active),
        (s) => OrderingTerm.desc(s.createdAt),
      ]);
    return q.watch().map((rows) => rows.map(_map).toList());
  }

  @override
  Future<d.Subscription?> getById(int id) async {
    final row = await (_db.select(_db.subscriptions)
          ..where((s) => s.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : _map(row);
  }

  @override
  Stream<List<d.TransactionEntry>> watchCharges(int subscriptionId) {
    final q = _db.select(_db.transactions)
      ..where((t) => t.subscriptionId.equals(subscriptionId))
      ..orderBy([(t) => OrderingTerm.desc(t.date)]);
    return q.watch().map((rows) => rows.map(_mapTxn).toList());
  }

  @override
  Future<int> create(d.Subscription sub) async {
    final id = await _db.into(_db.subscriptions).insert(
          SubscriptionsCompanion.insert(
            name: sub.name,
            amountMinor: sub.amountMinor,
            categoryId: sub.categoryId,
            walletId: sub.walletId,
            startDate: sub.startDate,
            note: Value(sub.note),
          ),
        );
    await materializeDueCharges();
    return id;
  }

  @override
  Future<void> update(d.Subscription sub) async {
    // BR-SB6: only the subscription row changes — recorded charge
    // transactions keep their historical amount/category/wallet.
    await (_db.update(_db.subscriptions)..where((s) => s.id.equals(sub.id)))
        .write(SubscriptionsCompanion(
      name: Value(sub.name),
      amountMinor: Value(sub.amountMinor),
      categoryId: Value(sub.categoryId),
      walletId: Value(sub.walletId),
      startDate: Value(sub.startDate),
      note: Value(sub.note),
    ));
    await materializeDueCharges();
  }

  @override
  Future<void> cancel(int id) {
    // BR-SB7: no future charges; recorded transactions stay.
    return (_db.update(_db.subscriptions)..where((s) => s.id.equals(id)))
        .write(const SubscriptionsCompanion(active: Value(false)));
  }

  @override
  Future<void> delete(int id) async {
    final charges = await (_db.select(_db.transactions)
          ..where((t) => t.subscriptionId.equals(id))
          ..limit(1))
        .get();
    if (charges.isNotEmpty) {
      // BR-SB8: history exists — cancel instead of delete.
      throw const d.DomainException(
          'This subscription has recorded charges. Cancel it instead.');
    }
    await (_db.delete(_db.subscriptions)..where((s) => s.id.equals(id))).go();
  }

  @override
  Future<int> materializeDueCharges({DateTime? today}) async {
    final now = today ?? DateTime.now();
    final actives = await (_db.select(_db.subscriptions)
          ..where((s) => s.active.equals(true)))
        .get();

    var created = 0;
    for (final row in actives) {
      final sub = _map(row);
      final due = _calc.dueDatesBetween(sub, now);
      if (due.isEmpty) continue;
      // BR-SB5: charges + marker advance in ONE transaction per subscription.
      await _db.transaction(() async {
        for (final date in due) {
          await _db.into(_db.transactions).insert(TransactionsCompanion.insert(
                amountMinor: sub.amountMinor,
                kind: d.TransactionKind.expense.index,
                categoryId: sub.categoryId,
                walletId: sub.walletId,
                date: date,
                note: Value(sub.note),
                subscriptionId: Value(sub.id),
              ));
        }
        await (_db.update(_db.subscriptions)
              ..where((s) => s.id.equals(sub.id)))
            .write(SubscriptionsCompanion(
                lastChargedDate: Value(due.last)));
      });
      created += due.length;
    }
    return created;
  }
}