# Cycle 4 Code Generation Plan — Installment Expenses (unit: money-manager)

Source of truth for Cycle 4 generation. Brownfield: modify in place, no duplicates.
Design: `aidlc-docs/construction/money-manager/functional-design/cycle4-installment-design.md`
Requirements: FR-1..FR-5 (`installment-requirements.md`)

## Step 1 — Domain layer (FR-1, FR-2)
- [ ] 1.1 Modify `lib/domain/entities.dart`: add `InstallmentPlan`; extend `TransactionEntry` with `installmentPlanId`, `installmentNo` (nullable)
- [ ] 1.2 Create `lib/domain/services/installment_calculator.dart`: `splitAmounts` (BR-I2/I3), `dueDates` (day clamp), `allowedMonths = {3,6,10,12}` (BR-I1)
- [ ] 1.3 Modify `lib/domain/repositories.dart`: add `InstallmentRepository` interface

## Step 2 — Data layer (FR-1, FR-4, NFR-2, NFR-4)
- [ ] 2.1 Modify `lib/data/database.dart`: `InstallmentPlans` table; `Transactions` + `installmentPlanId`, `installmentNo`; `schemaVersion` 1→2; v1→v2 migration (additive)
- [ ] 2.2 Run `dart run build_runner build` → regenerate `database.g.dart`
- [ ] 2.3 Create `lib/data/repositories/installment_repository_impl.dart`: `createPlan` (plan + N transactions, one DB transaction), `deletePlan` (children first, atomic), watches
- [ ] 2.4 Modify `lib/data/repositories/transaction_repository_impl.dart`: map new columns; BR-I4 guard — `update`/`delete` throw `DomainException` for installment-linked rows
- [ ] 2.5 Modify `lib/data/backup_service.dart`: JSON v2 (`installmentPlans` array, transaction fields), import v1+v2, wipe/restore FK order

## Step 3 — Application layer (FR-1)
- [ ] 3.1 Modify `lib/application/providers.dart`: `installmentRepositoryProvider`, `installmentPlansProvider`, plan installments family provider
- [ ] 3.2 Modify `lib/application/controllers/transaction_controller.dart`: `addInstallmentExpense` (validate BR-I1/I2 + BR-T3/T4, delegate to repo)

## Step 4 — Presentation layer (FR-5)
- [ ] 4.1 Modify `lib/presentation/transactions/transaction_edit_screen.dart`: "Pay in installments" toggle (new expense only), 3/6/10/12 `SegmentedButton`, per-month preview via `MoneyFormatter`
- [ ] 4.2 Modify `lib/presentation/transactions/transaction_tile.dart`: "k/N" badge for installment rows
- [ ] 4.3 Create `lib/presentation/transactions/installment_plan_sheet.dart`: plan detail bottom sheet (progress BR-I9, installment list, delete-plan confirm); wire tap-routing in `transactions_screen.dart` / `home_screen.dart` (installment rows open sheet, not edit)
- [ ] 4.4 Modify `lib/l10n/app_en.arb` + `lib/l10n/app_th.arb`: new keys (toggle, presets, preview, badge, sheet, delete confirm); run `flutter gen-l10n`

## Step 5 — Tests (quality gates)
- [ ] 5.1 Create `test/installment_calculator_test.dart`: exact sum, remainder-to-last, BR-I1/I2 rejections, date clamp (Jan 31→Feb 28/29, year cross)
- [ ] 5.2 Modify `test/database_test.dart` (or new `test/installment_repository_test.dart`): createPlan atomicity, deletePlan cascade, BR-I4 guard throws
- [ ] 5.3 Modify `test/backup_service_test.dart`: v2 round-trip with plans; v1 import compatibility

## Step 6 — Verification + docs
- [ ] 6.1 `flutter analyze` clean; `flutter test` all pass; `flutter build web` succeeds
- [ ] 6.2 Create `aidlc-docs/construction/money-manager/code/cycle4-code-summary.md`
- [ ] 6.3 Update `CLAUDE.md` (schema v2, installment invariants) + `aidlc-state.md`

## Unit Context
- Single unit `money-manager`; no external dependencies; offline-first
- Contract: enum order + `.index` persistence untouched; money integer minor units; existing BR-C2/W2 delete guards apply automatically to installment transactions
