# Code Generation Summary — money-manager

Greenfield Flutter app generated at workspace root. `flutter analyze` clean; `flutter test` = 25 passing.

## Files Created (application code)

### core
- `lib/core/money.dart` — MoneyFormatter (integer minor-unit parse/format)
- `lib/core/date_utils.dart` — MonthKey, DateRange

### domain
- `lib/domain/entities.dart` — enums, Wallet, Category, TransactionEntry, Budget, BudgetProgress, PeriodSummary, CategorySpend, TrendPoint, AppSettings, DomainException
- `lib/domain/repositories.dart` — repository interfaces
- `lib/domain/services/budget_calculator.dart` — thresholds warn ≥80%, over ≥100%
- `lib/domain/services/summary_calculator.dart` — totals, per-category, trend

### data
- `lib/data/database.dart` — Drift AppDatabase (Wallets/Categories/Transactions/Budgets), migration, FK pragma
- `lib/data/database.g.dart` — generated (build_runner)
- `lib/data/seed.dart` — default wallet + 9 categories
- `lib/data/repositories/{transaction,wallet,category,budget}_repository_impl.dart`
- `lib/data/settings_repository.dart` — shared_preferences

### application
- `lib/application/providers.dart` — Riverpod composition root + derived read models
- `lib/application/settings_notifier.dart`
- `lib/application/app_lock_service.dart` — local_auth wrapper
- `lib/application/controllers/{transaction,budget,wallet,category}_controller.dart`

### presentation
- `lib/app.dart`, `lib/main.dart`
- `lib/presentation/theme.dart`, `app_lock_gate.dart`, `main_shell.dart`
- screens: `home/`, `transactions/` (list, edit, tile), `budgets/`, `reports/`, `wallets/`, `categories/`, `settings/`
- widgets: `money_text.dart`, `category_avatar.dart`, `empty_state.dart`

### tests
- `test/money_test.dart`, `budget_calculator_test.dart`, `summary_calculator_test.dart` (pure logic)
- `test/database_test.dart` (Drift memory DB: seed, balance, delete-guard)
- `test/widget_smoke_test.dart` (boot, add-form, reports — fake repos)

## Key Decisions / Deviations
- **No separate DAO classes** — repository impls query Drift tables directly (simpler, same layering intent).
- **`dependency_overrides: path_provider_foundation 2.4.1`** — newer versions pull `objective_c` native-asset build hooks that break `build_runner` on Dart 3.10. Documented in README + pubspec.
- **drift pinned to `^2.28.0`** — latest drift_dev requires Dart SDK 3.11; host is 3.10.4.
- Widget tests use fake repositories (deterministic, no native DB / fakeAsync timer stalls); DB behavior covered separately in `database_test.dart`.

## Verification
- `flutter analyze` → No issues found.
- `flutter test` → All 25 tests passed.
