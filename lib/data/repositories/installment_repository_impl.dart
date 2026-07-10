import 'package:drift/drift.dart';

import '../../domain/entities.dart' as d;
import '../../domain/repositories.dart';
import '../../domain/services/installment_calculator.dart';
import '../database.dart';

class InstallmentRepositoryImpl implements InstallmentRepository {
  InstallmentRepositoryImpl(this._db);
  final AppDatabase _db;

  static const _calc = InstallmentCalculator();

  d.InstallmentPlan _map(InstallmentPlan r) => d.InstallmentPlan(
        id: r.id,
        totalMinor: r.totalMinor,
        months: r.months,
        categoryId: r.categoryId,
        walletId: r.walletId,
        startDate: r.startDate,
        note: r.note,
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
      );

  @override
  Stream<List<d.InstallmentPlan>> watchAll() {
    final q = _db.select(_db.installmentPlans)
      ..orderBy([(p) => OrderingTerm.desc(p.startDate)]);
    return q.watch().map((rows) => rows.map(_map).toList());
  }

  @override
  Future<d.InstallmentPlan?> getById(int id) async {
    final row = await (_db.select(_db.installmentPlans)
          ..where((p) => p.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : _map(row);
  }

  @override
  Stream<List<d.TransactionEntry>> watchInstallments(int planId) {
    final q = _db.select(_db.transactions)
      ..where((t) => t.installmentPlanId.equals(planId))
      ..orderBy([(t) => OrderingTerm.asc(t.installmentNo)]);
    return q.watch().map((rows) => rows.map(_mapTxn).toList());
  }

  @override
  Future<int> createPlan(d.InstallmentPlan plan) {
    // Validates BR-I1/I2 before touching the DB.
    final amounts = _calc.splitAmounts(plan.totalMinor, plan.months);
    final dates = _calc.dueDates(plan.startDate, plan.months);

    // BR-I5: plan + all N installments in one transaction.
    return _db.transaction(() async {
      final planId =
          await _db.into(_db.installmentPlans).insert(InstallmentPlansCompanion.insert(
                totalMinor: plan.totalMinor,
                months: plan.months,
                categoryId: plan.categoryId,
                walletId: plan.walletId,
                startDate: plan.startDate,
                note: Value(plan.note),
              ));
      for (var i = 0; i < plan.months; i++) {
        await _db.into(_db.transactions).insert(TransactionsCompanion.insert(
              amountMinor: amounts[i],
              kind: d.TransactionKind.expense.index,
              categoryId: plan.categoryId,
              walletId: plan.walletId,
              date: dates[i],
              note: Value(plan.note),
              installmentPlanId: Value(planId),
              installmentNo: Value(i + 1),
            ));
      }
      return planId;
    });
  }

  @override
  Future<void> deletePlan(int id) {
    // BR-I5: children first, atomically.
    return _db.transaction(() async {
      await (_db.delete(_db.transactions)
            ..where((t) => t.installmentPlanId.equals(id)))
          .go();
      await (_db.delete(_db.installmentPlans)..where((p) => p.id.equals(id)))
          .go();
    });
  }
}