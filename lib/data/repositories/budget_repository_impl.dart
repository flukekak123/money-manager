import 'package:drift/drift.dart';

import '../../domain/entities.dart' as d;
import '../../domain/repositories.dart';
import '../database.dart';

class BudgetRepositoryImpl implements BudgetRepository {
  BudgetRepositoryImpl(this._db);
  final AppDatabase _db;

  d.Budget _map(Budget r) => d.Budget(
        id: r.id,
        categoryId: r.categoryId,
        limitMinor: r.limitMinor,
        month: r.month,
      );

  @override
  Stream<List<d.Budget>> watchByMonth(String yyyymm) {
    final q = _db.select(_db.budgets)..where((b) => b.month.equals(yyyymm));
    return q.watch().map((rows) => rows.map(_map).toList());
  }

  @override
  Future<void> upsert(d.Budget b) async {
    // BR-B2: one budget per (category, month) — update if exists, else insert.
    final existing = await (_db.select(_db.budgets)
          ..where((t) =>
              t.categoryId.equals(b.categoryId) & t.month.equals(b.month))
          ..limit(1))
        .getSingleOrNull();
    if (existing != null) {
      await (_db.update(_db.budgets)..where((t) => t.id.equals(existing.id)))
          .write(BudgetsCompanion(limitMinor: Value(b.limitMinor)));
    } else {
      await _db.into(_db.budgets).insert(
            BudgetsCompanion.insert(
              categoryId: b.categoryId,
              limitMinor: b.limitMinor,
              month: b.month,
            ),
          );
    }
  }

  @override
  Future<void> delete(int id) {
    return (_db.delete(_db.budgets)..where((t) => t.id.equals(id))).go();
  }
}
