# Code Generation Plan — unit: money-manager

**Single source of truth for Code Generation.** Greenfield Flutter single-unit app. App code at workspace root `lib/`, tests `test/`. Docs summaries in `aidlc-docs/construction/money-manager/code/`.

## Unit Context
- **Unit**: money-manager (whole app)
- **Dependencies**: none (local-only)
- **DB entities owned**: Wallet, Category, TransactionEntry, Budget
- **Requirements covered**: FR1 transactions, FR2 categories, FR3 budgets, FR4 reports, FR5 wallets, FR6 app-lock, FR7 settings; NFR money-int, Riverpod, Drift, Material3.

## Tech / Packages
| Package | Use |
|---|---|
| flutter_riverpod | state management |
| drift, drift_flutter, sqlite3_flutter_libs | local DB |
| path_provider, path | DB file location |
| fl_chart | reports charts |
| local_auth | app lock |
| shared_preferences | settings |
| intl | currency/date format |
| build_runner, drift_dev | codegen (dev) |
| flutter_lints | lints (dev) |

## Project Structure (target)
```
lib/
  main.dart
  app.dart
  core/
    money.dart                 # Money value + MoneyFormatter
    date_utils.dart
  domain/
    entities.dart              # enums + entity classes
    repositories.dart          # abstract repo interfaces
    services/
      budget_calculator.dart
      summary_calculator.dart
  data/
    database.dart              # Drift AppDatabase + tables + DAOs
    database.g.dart            # generated
    seed.dart
    repositories/
      transaction_repository_impl.dart
      category_repository_impl.dart
      wallet_repository_impl.dart
      budget_repository_impl.dart
    settings_repository.dart
  application/
    providers.dart             # riverpod providers (composition root)
    controllers/
      transaction_controller.dart
      budget_controller.dart
      wallet_controller.dart
      category_controller.dart
    settings_notifier.dart
  presentation/
    app_lock_gate.dart
    main_shell.dart
    home/home_screen.dart
    transactions/transactions_screen.dart
    transactions/transaction_edit_screen.dart
    budgets/budgets_screen.dart
    reports/reports_screen.dart
    wallets/wallets_screen.dart
    categories/categories_screen.dart
    settings/settings_screen.dart
    widgets/money_text.dart
    widgets/category_avatar.dart
    widgets/empty_state.dart
    theme.dart
test/
  money_test.dart
  budget_calculator_test.dart
  summary_calculator_test.dart
  widget_smoke_test.dart
```

## Generation Steps

- [x] **Step 1 — Project scaffold**: `flutter create` app at workspace root (org, name money_manager), set pubspec dependencies, analysis_options.
- [x] **Step 2 — Core money**: `lib/core/money.dart` (MoneyFormatter parse/format, integer minor units), `date_utils.dart`. [BR-M1..M3]
- [x] **Step 3 — Domain entities + repo interfaces**: `lib/domain/entities.dart`, `lib/domain/repositories.dart`. [domain-entities.md]
- [x] **Step 4 — Domain services**: `budget_calculator.dart` (thresholds 80/100), `summary_calculator.dart`. [business-logic-model.md §4-7]
- [x] **Step 5 — Business logic unit tests**: `money_test.dart`, `budget_calculator_test.dart`, `summary_calculator_test.dart`.
- [x] **Step 6 — Data: Drift database**: `database.dart` (tables Wallets/Categories/Transactions/Budgets, DAOs, migration), `seed.dart` (Cash wallet + 9 categories). Run build_runner → `database.g.dart`.
- [x] **Step 7 — Repository impls**: transaction/category/wallet/budget repos + `settings_repository.dart` (shared_preferences). [BR delete-guards]
- [x] **Step 8 — Application layer**: `providers.dart` (composition root), controllers (transaction/budget/wallet/category), `settings_notifier.dart`. Validation per business-rules.
- [x] **Step 9 — Presentation: shell + theme + lock**: `app.dart`, `main_shell.dart` (5-tab bottom nav), `theme.dart` (M3 light+dark), `app_lock_gate.dart` (local_auth), `main.dart`.
- [x] **Step 10 — Presentation: screens**: home, transactions, transaction_edit, budgets, reports (fl_chart), wallets, categories, settings + shared widgets. `data-testid`-equivalent keys on interactive widgets.
- [x] **Step 11 — Widget smoke test**: `widget_smoke_test.dart` — app boots, home renders.
- [x] **Step 12 — Docs + README**: `README.md` (run instructions), `aidlc-docs/construction/money-manager/code/` summaries.

## Story / Requirement Traceability
| Requirement | Steps |
|---|---|
| FR1 transactions | 3,6,7,8,10 |
| FR2 categories | 3,6,7,8,10 |
| FR3 budgets | 4,6,7,8,10 |
| FR4 reports | 4,10 |
| FR5 wallets | 3,6,7,8,10 |
| FR6 app-lock | 9 |
| FR7 settings | 7,8,10 |
| NFR money-int | 2,5 |

## Scope
12 steps. Approx 35–40 files. After generation → Build & Test stage runs `flutter analyze` + `flutter test`.
