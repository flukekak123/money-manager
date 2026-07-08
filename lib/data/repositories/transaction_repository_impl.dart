import 'package:drift/drift.dart';

import '../../core/date_utils.dart';
import '../../domain/entities.dart' as d;
import '../../domain/repositories.dart';
import '../database.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  TransactionRepositoryImpl(this._db);
  final AppDatabase _db;

  d.TransactionEntry _map(Transaction r) => d.TransactionEntry(
        id: r.id,
        amountMinor: r.amountMinor,
        kind: d.TransactionKind.values[r.kind],
        categoryId: r.categoryId,
        walletId: r.walletId,
        date: r.date,
        note: r.note,
      );

  @override
  Stream<List<d.TransactionEntry>> watchAll() {
    final q = _db.select(_db.transactions)
      ..orderBy([
        (t) => OrderingTerm.desc(t.date),
        (t) => OrderingTerm.desc(t.id),
      ]);
    return q.watch().map((rows) => rows.map(_map).toList());
  }

  @override
  Stream<List<d.TransactionEntry>> watchByMonth(String yyyymm) {
    final range = DateRange.month(yyyymm);
    final q = _db.select(_db.transactions)
      ..where((t) =>
          t.date.isBiggerOrEqualValue(range.start) &
          t.date.isSmallerThanValue(range.endExclusive))
      ..orderBy([
        (t) => OrderingTerm.desc(t.date),
        (t) => OrderingTerm.desc(t.id),
      ]);
    return q.watch().map((rows) => rows.map(_map).toList());
  }

  @override
  Future<int> add(d.TransactionEntry e) {
    return _db.into(_db.transactions).insert(
          TransactionsCompanion.insert(
            amountMinor: e.amountMinor,
            kind: e.kind.index,
            categoryId: e.categoryId,
            walletId: e.walletId,
            date: e.date,
            note: Value(e.note),
          ),
        );
  }

  @override
  Future<void> update(d.TransactionEntry e) {
    return (_db.update(_db.transactions)..where((t) => t.id.equals(e.id))).write(
      TransactionsCompanion(
        amountMinor: Value(e.amountMinor),
        kind: Value(e.kind.index),
        categoryId: Value(e.categoryId),
        walletId: Value(e.walletId),
        date: Value(e.date),
        note: Value(e.note),
      ),
    );
  }

  @override
  Future<void> delete(int id) {
    return (_db.delete(_db.transactions)..where((t) => t.id.equals(id))).go();
  }
}
