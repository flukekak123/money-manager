import 'package:drift/drift.dart';

import '../../domain/entities.dart' as d;
import '../../domain/repositories.dart';
import '../database.dart';

class WalletRepositoryImpl implements WalletRepository {
  WalletRepositoryImpl(this._db);
  final AppDatabase _db;

  d.Wallet _map(Wallet r) => d.Wallet(
        id: r.id,
        name: r.name,
        type: d.WalletType.values[r.type],
        iconCodePoint: r.iconCodePoint,
        colorValue: r.colorValue,
        archived: r.archived,
      );

  @override
  Stream<List<d.Wallet>> watchAll({bool includeArchived = false}) {
    final q = _db.select(_db.wallets);
    if (!includeArchived) {
      q.where((w) => w.archived.equals(false));
    }
    q.orderBy([(w) => OrderingTerm.asc(w.name)]);
    return q.watch().map((rows) => rows.map(_map).toList());
  }

  @override
  Stream<int> watchBalanceMinor(int walletId) {
    final q = _db.select(_db.transactions)
      ..where((t) => t.walletId.equals(walletId));
    return q.watch().map((rows) {
      var balance = 0;
      for (final r in rows) {
        balance += d.TransactionKind.values[r.kind] == d.TransactionKind.income
            ? r.amountMinor
            : -r.amountMinor;
      }
      return balance;
    });
  }

  @override
  Future<int> add(d.Wallet w) {
    return _db.into(_db.wallets).insert(
          WalletsCompanion.insert(
            name: w.name,
            type: w.type.index,
            iconCodePoint: w.iconCodePoint,
            colorValue: w.colorValue,
            archived: Value(w.archived),
          ),
        );
  }

  @override
  Future<void> update(d.Wallet w) {
    return (_db.update(_db.wallets)..where((t) => t.id.equals(w.id))).write(
      WalletsCompanion(
        name: Value(w.name),
        type: Value(w.type.index),
        iconCodePoint: Value(w.iconCodePoint),
        colorValue: Value(w.colorValue),
        archived: Value(w.archived),
      ),
    );
  }

  @override
  Future<void> archive(int id) async {
    // BR-W3: at least one active wallet must remain.
    final active = await (_db.select(_db.wallets)
          ..where((w) => w.archived.equals(false)))
        .get();
    if (active.length <= 1 && active.any((w) => w.id == id)) {
      throw const d.DomainException('At least one active wallet is required.');
    }
    await (_db.update(_db.wallets)..where((t) => t.id.equals(id)))
        .write(const WalletsCompanion(archived: Value(true)));
  }

  @override
  Future<void> delete(int id) async {
    // BR-W2: block delete if referenced by transactions.
    final refs = await (_db.select(_db.transactions)
          ..where((t) => t.walletId.equals(id))
          ..limit(1))
        .get();
    if (refs.isNotEmpty) {
      throw const d.DomainException(
          'Cannot delete a wallet that has transactions. Archive it instead.');
    }
    await (_db.delete(_db.wallets)..where((t) => t.id.equals(id))).go();
  }
}
