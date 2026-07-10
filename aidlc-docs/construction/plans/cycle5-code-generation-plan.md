# Cycle 5 Code Generation Plan — Subscriptions (unit: money-manager)

Source of truth for Cycle 5 generation. Brownfield: modify in place.
Design: `cycle5-subscription-design.md` · Requirements: FR-1..FR-5 (`subscription-requirements.md`)

## Step 1 — Domain (FR-1, FR-2)
- [ ] 1.1 `lib/domain/entities.dart`: `Subscription` entity; `TransactionEntry` + `subscriptionId` / `isSubscriptionCharge`
- [ ] 1.2 Create `lib/domain/services/subscription_calculator.dart`: `dueDatesBetween` (no-backfill anchor, marker lower bound, clamp via `InstallmentCalculator.addMonthsClamped`)
- [ ] 1.3 `lib/domain/repositories.dart`: `SubscriptionRepository` (incl. `materializeDueCharges({today})`)

## Step 2 — Data (FR-2, FR-3, NFR-2, NFR-4)
- [ ] 2.1 `lib/data/database.dart`: `Subscriptions` table; `Transactions` + `subscriptionId`; `schemaVersion` 2→3; additive migration
- [ ] 2.2 `dart run build_runner build` → regenerate `database.g.dart`
- [ ] 2.3 Create `lib/data/repositories/subscription_repository_impl.dart`: CRUD + atomic idempotent materializer (BR-SB5), cancel (BR-SB7), delete guard (BR-SB8)
- [ ] 2.4 `lib/data/repositories/transaction_repository_impl.dart`: map `subscriptionId`; extend lock guard to subscription charges (BR-SB4)
- [ ] 2.5 `lib/data/backup_service.dart`: JSON v3 (`subscriptions` + txn field), import v1/v2/v3

## Step 3 — Application (FR-2, FR-4)
- [ ] 3.1 Create `lib/application/controllers/subscription_controller.dart`: validate BR-SB1..SB3, create/update (+materialize), cancel, delete
- [ ] 3.2 `lib/application/providers.dart`: subscription repo/list/charges/byId providers + controller
- [ ] 3.3 Launch hook: materialize once on app start (composition root / app widget), errors non-fatal

## Step 4 — Presentation (FR-5)
- [ ] 4.1 Create `lib/presentation/subscriptions/subscriptions_screen.dart`: list (name, amount/mo, next charge or cancelled) + FAB
- [ ] 4.2 Create `lib/presentation/subscriptions/subscription_edit_screen.dart`: form (name, amount, expense category, wallet, start date, note), Cancel-subscription action, Delete when zero charges
- [ ] 4.3 Create `lib/presentation/subscriptions/subscription_sheet.dart`: detail (next charge, history, cancel)
- [ ] 4.4 `transaction_tile.dart`: autorenew badge; `transactions_screen.dart` + `home_screen.dart`: charge rows no swipe-delete, tap opens sheet
- [ ] 4.5 `settings_screen.dart`: Manage → Subscriptions entry
- [ ] 4.6 `app_en.arb` + `app_th.arb` new keys; `flutter gen-l10n`

## Step 5 — Tests
- [ ] 5.1 Create `test/subscription_calculator_test.dart`: first charge today/future start, past start no backfill, catch-up 3 months, clamp Jan 31, marker bound
- [ ] 5.2 Create `test/subscription_repository_test.dart`: materialize records due; double-run 0 new; cancel stops; edit future-only; BR-SB4 lock; BR-SB8 guard
- [ ] 5.3 `test/backup_service_test.dart`: v3 round-trip; v2 import compatibility
- [ ] 5.4 `test/widget_smoke_test.dart`: `_FakeSubscriptionRepo` override (Cycle 4 lesson)

## Step 6 — Verification + docs
- [ ] 6.1 `flutter analyze` clean; `flutter test` all pass; `flutter build web --no-tree-shake-icons` OK
- [ ] 6.2 Create `aidlc-docs/construction/money-manager/code/cycle5-code-summary.md`
- [ ] 6.3 Update CLAUDE.md (schema v3, subscriptions invariant) + aidlc-state.md

## Unit Context
- Single unit; reuses Cycle 4 lock-guard pattern and `addMonthsClamped`; enum order untouched; money integer minor units
