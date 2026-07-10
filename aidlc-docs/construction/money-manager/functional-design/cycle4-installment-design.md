# Cycle 4 Functional Design — Installment Expenses

Decisions: entry via toggle in expense form (Q1=A); plans immutable — delete + recreate (Q2=A); management via transaction detail sheet, no separate screen (Q3=A).

## 1. Domain Entities (`lib/domain/entities.dart`)

### InstallmentPlan (new)
| Field | Type | Notes |
|---|---|---|
| id | int | PK |
| totalMinor | int | total purchase amount, minor units |
| months | int | 3, 6, 10, or 12 |
| categoryId | int | expense category |
| walletId | int | wallet |
| startDate | DateTime | purchase date = first installment due date |
| note | String? | copied to installments, ≤200 chars |
| createdAt | DateTime | |

### TransactionEntry (extended)
- `installmentPlanId: int?` — null for normal transactions.
- `installmentNo: int?` — 1-based position, for "k/N" badge (N = plan.months).
- Both nullable; existing behavior unchanged when null.

## 2. Split Algorithm (`lib/domain/services/installment_calculator.dart`)

Stateless calculator, pure Dart, unit-tested.

```
splitAmounts(totalMinor, months):
  base = totalMinor ~/ months
  amounts = [base] * (months - 1) + [totalMinor - base * (months - 1)]
  // sum == totalMinor exactly; remainder absorbed by LAST installment
  // e.g. 100000 over 3 -> 33333, 33333, 33334

dueDates(startDate, months):
  for i in 0..months-1:
    y, m = addMonths(startDate.year, startDate.month, i)
    day = min(startDate.day, daysInMonth(y, m))   // clamp: Jan 31 -> Feb 28/29
    date_i = DateTime(y, m, day)
```

No floating point anywhere (BR-M1/M3).

## 3. Business Rules (BR-I*)

- **BR-I1**: `months` ∈ {3, 6, 10, 12}; anything else → `DomainException`.
- **BR-I2**: `totalMinor > 0` and `totalMinor >= months` (every installment ≥ 1 minor unit).
- **BR-I3**: sum of installment amounts == `totalMinor` exactly; remainder goes to last installment.
- **BR-I4**: transactions with `installmentPlanId != null` cannot be individually edited or deleted — `TransactionRepository.update/delete` throws `DomainException`; UI routes user to the plan sheet instead.
- **BR-I5**: plan creation inserts plan + N transactions in ONE DB transaction; plan deletion removes all N linked transactions + plan in ONE DB transaction (children first). Rollback on any error.
- **BR-I6**: plans are immutable — no update operation. Change = delete plan + create new.
- **BR-I7**: plan-generated installments are exempt from BR-T5 (future-date block). BR-T5 still applies to the plan's `startDate` (purchase already happened) and to manual transactions.
- **BR-I8**: category must be expense-kind + non-archived; wallet non-archived (reuse BR-T3/T4 at plan creation). Wallet/category delete guards (BR-C2/W2) work unchanged because installments are real referencing transactions.
- **BR-I9**: progress `k` = count of the plan's installments with `date <= today` (paid-so-far display).

## 4. Repository Interfaces (`lib/domain/repositories.dart`)

```dart
abstract class InstallmentRepository {
  Stream<List<InstallmentPlan>> watchAll();
  Future<InstallmentPlan?> getById(int id);
  Stream<List<TransactionEntry>> watchInstallments(int planId); // ordered by installmentNo
  Future<int> createPlan(InstallmentPlan plan);   // generates N transactions atomically
  Future<void> deletePlan(int id);                // deletes N transactions + plan atomically
}
```

- `TransactionRepository.update` / `delete`: guard per BR-I4.
- `TransactionEntry` mapping carries the two new columns.

## 5. Data Layer

- **Schema**: `schemaVersion` 1 → 2. New table `InstallmentPlans` (columns per entity; `categoryId`/`walletId` FK refs). `Transactions` gains nullable `installmentPlanId` (references `InstallmentPlans.id`) and `installmentNo`.
- **Migration v1→v2**: `m.createTable(installmentPlans)`, `m.addColumn(transactions, installmentPlanId)`, `m.addColumn(transactions, installmentNo)`. Additive only — existing rows untouched.
- **Controller**: `TransactionController.addInstallmentExpense(total, months, categoryId, walletId, date, note)` validates BR-I1/I2 + BR-T3/T4, then calls `InstallmentRepository.createPlan`.

## 6. Backup JSON v2 (`lib/data/backup_service.dart`)

- `version: 2`. New top-level array `installmentPlans: [...]`; transaction objects gain `installmentPlanId` + `installmentNo` (nullable).
- Export always writes v2.
- Import accepts v1 (no plans, nulls for new fields) AND v2. Restore order: plans before transactions (FK); wipe order: transactions before plans.

## 7. Frontend Components

### Expense entry form (existing edit screen)
- "Pay in installments" `SwitchListTile` — visible only when kind == expense AND creating new (not editing).
- ON reveals `SegmentedButton` presets 3 / 6 / 10 / 12 + live preview line: "12 × ฿83.33 (last ฿83.37)" using `MoneyFormatter`.
- Amount field = total. Save calls `addInstallmentExpense`; snackbar confirms N transactions created.

### Transaction list tile
- Installment rows show badge chip "k/N" (`installmentNo`/`months`) next to category.

### Plan detail bottom sheet
- Tapping an installment transaction opens plan sheet instead of edit form: total, category/wallet, progress (BR-I9, e.g. "2 of 6 paid"), full dated installment list, **Delete plan** button with confirm dialog ("removes all N transactions").

### Localization
- All new strings in `app_en.arb` + `app_th.arb` (toggle label, presets helper, preview, badge semantics, sheet labels, delete confirm).

## 8. Test Plan (domain-level)
- Split: exact sum, remainder-to-last, min-amount rejection (BR-I2), invalid months (BR-I1).
- Dates: Jan 31 start over 3 → Feb 28 (29 leap), Mar 31; Oct 31 over 6 crossing year.
- Repo: createPlan atomic (N rows + plan), deletePlan removes all, update/delete guard throws (BR-I4).
- Backup: v2 round-trip with plans; v1 import still works.
