# Cycle 5 Code Summary — Subscriptions (recurring monthly expense)

## Results
- `flutter analyze`: clean
- `flutter test`: **63/63 pass** (was 47; +16 new)
- `flutter build web --no-tree-shake-icons`: success

## Created
- `lib/domain/services/subscription_calculator.dart` — `dueDatesBetween` (marker/no-backfill lower bound, today upper bound, day clamp via `InstallmentCalculator.addMonthsClamped`), `nextChargeDate`
- `lib/data/repositories/subscription_repository_impl.dart` — CRUD + `materializeDueCharges` (atomic per subscription, `lastChargedDate` marker advanced in same DB transaction), cancel, BR-SB8 delete guard
- `lib/application/controllers/subscription_controller.dart` — validation BR-SB1..SB3 + save/cancel/delete
- `lib/presentation/subscriptions/subscriptions_screen.dart` — list (next charge / cancelled) + FAB
- `lib/presentation/subscriptions/subscription_edit_screen.dart` — form (name/amount/category/wallet/start date/note)
- `lib/presentation/subscriptions/subscription_sheet.dart` — detail: amount/mo, next charge, history, edit, cancel-with-confirm
- `test/subscription_calculator_test.dart` (8 tests), `test/subscription_repository_test.dart` (7 tests)

## Modified
- `lib/domain/entities.dart` — `Subscription` entity; `TransactionEntry.subscriptionId` + `isSubscriptionCharge`
- `lib/domain/repositories.dart` — `SubscriptionRepository`
- `lib/data/database.dart` — `Subscriptions` table, `Transactions.subscriptionId`, schema v3, additive migration; `database.g.dart` regenerated
- `lib/data/repositories/transaction_repository_impl.dart` — guard renamed `_guardNotGenerated`, blocks subscription charges too (BR-SB4)
- `lib/data/backup_service.dart` — JSON v3; imports v1/v2/v3
- `lib/application/providers.dart` — subscription providers + `subscriptionMaterializeOnLaunchProvider`
- `lib/app.dart` — launch hook watches materialize-on-launch provider (cached FutureProvider, errors contained)
- `lib/presentation/transactions/transaction_tile.dart` — autorenew+name badge
- `transactions_screen.dart` / `home_screen.dart` — charge rows: no swipe-delete, tap opens subscription sheet
- `lib/presentation/settings/settings_screen.dart` — Manage → Subscriptions entry
- `lib/l10n/app_en.arb` / `app_th.arb` — 15 new keys each
- `test/backup_service_test.dart` — v3 round-trip incl. subscription; v2-compat import test
- `test/widget_smoke_test.dart` — `_FakeSubscriptionRepo` override

## Not verified
- Live UI walkthrough on device/browser
- Real v2→v3 SQLite migration on device (additive; fresh-create covered by tests)
