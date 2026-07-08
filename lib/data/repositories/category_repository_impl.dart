import 'package:drift/drift.dart';

import '../../domain/entities.dart' as d;
import '../../domain/repositories.dart';
import '../database.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  CategoryRepositoryImpl(this._db);
  final AppDatabase _db;

  d.Category _map(Category r) => d.Category(
        id: r.id,
        name: r.name,
        kind: d.TransactionKind.values[r.kind],
        iconCodePoint: r.iconCodePoint,
        colorValue: r.colorValue,
        isDefault: r.isDefault,
        archived: r.archived,
      );

  @override
  Stream<List<d.Category>> watchAll({bool includeArchived = false}) {
    final q = _db.select(_db.categories);
    if (!includeArchived) {
      q.where((c) => c.archived.equals(false));
    }
    q.orderBy([(c) => OrderingTerm.asc(c.name)]);
    return q.watch().map((rows) => rows.map(_map).toList());
  }

  @override
  Future<int> add(d.Category c) {
    return _db.into(_db.categories).insert(
          CategoriesCompanion.insert(
            name: c.name,
            kind: c.kind.index,
            iconCodePoint: c.iconCodePoint,
            colorValue: c.colorValue,
            isDefault: Value(c.isDefault),
            archived: Value(c.archived),
          ),
        );
  }

  @override
  Future<void> update(d.Category c) {
    return (_db.update(_db.categories)..where((t) => t.id.equals(c.id))).write(
      CategoriesCompanion(
        name: Value(c.name),
        kind: Value(c.kind.index),
        iconCodePoint: Value(c.iconCodePoint),
        colorValue: Value(c.colorValue),
        archived: Value(c.archived),
      ),
    );
  }

  @override
  Future<void> archive(int id) async {
    await (_db.update(_db.categories)..where((t) => t.id.equals(id)))
        .write(const CategoriesCompanion(archived: Value(true)));
  }

  @override
  Future<void> delete(int id) async {
    // BR-C2: block delete if referenced by transactions.
    final refs = await (_db.select(_db.transactions)
          ..where((t) => t.categoryId.equals(id))
          ..limit(1))
        .get();
    if (refs.isNotEmpty) {
      throw const d.DomainException(
          'Cannot delete a category that has transactions. Archive it instead.');
    }
    await (_db.delete(_db.budgets)..where((b) => b.categoryId.equals(id))).go();
    await (_db.delete(_db.categories)..where((t) => t.id.equals(id))).go();
  }
}
