# Cycle 4 Code Summary — Installment Expenses

## Results
- `flutter analyze`: clean
- `flutter test`: **47/47 pass** (was 31; +16 new)
- `flutter build web --no-tree-shake-icons`: success
  - ⚠️ Plain `flutter build web` now fails on `theme.dart:33` (`iconFromCodePoint` — non-constant IconData). **Pre-existing**: verified HEAD (before Cycle 4) fails identically; Flutter toolchain became stricter. Dynamic icons are by design (codePoints stored in DB), so `--no-tree-shake-icons` is required from now on.

## Modified
- `lib/domain/entities.dart` — `InstallmentPlan` entity; `TransactionEntry` + `installmentPlanId`/`installmentNo` (+ `isInstallment`)
- `lib/domain/repositories.dart` — `InstallmentRepository` interface
- `lib/data/database.dart` — `InstallmentPlans` table, 2 new `Transactions` columns, `schemaVersion` 2, additive v1→v2 migration
- `lib/data/database.g.dart` — regenerated (build_runner)
- `lib/data/repositories/transaction_repository_impl.dart` — maps new columns; BR-I4 guard: update/delete of installment rows throws `DomainException`
- `lib/data/backup_service.dart` — JSON v2 (`installmentPlans` + txn fields); imports v1 AND v2; FK-ordered wipe/restore
- `lib/application/providers.dart` — installment repo/plans/planInstallments/plansById providers; controller wiring
- `lib/application/controllers/transaction_controller.dart` — `saveInstallment` (validates BR-I1/I2 + BR-T3/T4/T5-on-startDate), `deleteInstallmentPlan`
- `lib/presentation/transactions/transaction_edit_screen.dart` — installments toggle (new expense only), 3/6/10/12 picker, live per-month preview
- `lib/presentation/transactions/transaction_tile.dart` — "k/N" badge
- `lib/presentation/transactions/transactions_screen.dart` — installment rows: no swipe-delete, tap opens plan sheet
- `lib/presentation/home/home_screen.dart` — same routing on recent list
- `lib/l10n/app_en.arb`, `lib/l10n/app_th.arb` — 11 new keys each (regenerated gen/)
- `test/backup_service_test.dart` — v2 round-trip incl. plan; v1 compatibility test
- `test/widget_smoke_test.dart` — `_FakeInstallmentRepo` override (fixes pending-timer failure from real DB instantiation)

## Created
- `lib/domain/services/installment_calculator.dart` — split (remainder-to-last) + due dates (day clamp)
- `lib/data/repositories/installment_repository_impl.dart` — atomic createPlan/deletePlan (BR-I5)
- `lib/presentation/transactions/installment_plan_sheet.dart` — plan detail bottom sheet (progress BR-I9, delete with confirm)
- `test/installment_calculator_test.dart` — 10 tests (sum exactness, BR-I1/I2, date clamps incl. leap year)
- `test/installment_repository_test.dart` — 5 tests (atomicity, BR-I4 guards, plan delete isolation)

## Not verified
- Live UI walkthrough on device/browser (unit + widget tests only).
- Real v1→v2 SQLite migration on an existing device DB (migration is additive; covered by fresh-create tests only).
