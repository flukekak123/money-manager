# Services — Money Manager App

MVP is local-only; "services" here = in-app orchestration layer (Riverpod notifiers + domain services), not network services.

## Orchestration Components

### SettingsNotifier (AsyncNotifier)
- Loads `AppSettings` from `SettingsRepository`.
- Exposes mutations: setCurrency, setThemeMode, setAppLockEnabled.
- Theme + currency changes ripple to UI via provider watch.

### TransactionController
- Coordinates add/edit/delete via `TransactionRepository`.
- Validates input (non-zero amount, category+wallet required) before persisting.
- Uses `MoneyFormatter.parse` to convert entered text into minor units.

### BudgetController
- Upsert/delete budgets via `BudgetRepository`.
- Reads month transactions + budgets, runs `BudgetCalculator` to produce `BudgetProgress` list for UI.

### ReportService (derived, read-only)
- Combines `monthTransactionsProvider` + `SummaryCalculator` to produce dashboard summary, spending-by-category, and trend series.

### AppLockService
- Wraps `local_auth`. Called by `AppLockGate` on cold start / resume when lock enabled.

## Orchestration Patterns
- **Read**: UI watches StreamProvider (repo → Drift stream) → auto-updates on DB change.
- **Compute**: derived Providers run pure domain calculators over streamed data (no extra persistence).
- **Write**: UI calls controller method → controller validates → repository → Drift → stream re-emits → UI refresh.
- **Single source of truth**: Drift DB. Settings in shared_preferences. No duplicated caches.
