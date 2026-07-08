# Application Design (Consolidated) — Money Manager App

## Overview
Offline-first Flutter MVP. Layered feature-first architecture: **Presentation (Flutter + Riverpod)** → **Domain (pure Dart)** ← **Data (Drift/SQLite)**. Money handled as integer minor units throughout.

## Confirmed Design Decisions
| Decision | Choice |
|---|---|
| Wallets | Lightweight multi-wallet (Wallets list, assign per transaction, per-wallet balance) |
| Navigation | Bottom nav: Home · Transactions · Budgets · Reports · Settings |
| Home/Dashboard | Current-month summary (income/expense/balance) + budget progress + recent transactions |
| Budget alerts | Fixed thresholds: warn ≥80%, over ≥100% |
| Seed data | Seed default categories + one default wallet on first run |

## Architecture Diagram

```text
+-------------------------------------------------------------+
|                     PRESENTATION                            |
|  MainShell (bottom nav)                                     |
|   Home | Transactions | Budgets | Reports | Settings        |
|  AppLockGate · TransactionEditScreen · Wallets · Categories |
|  Riverpod providers / controllers                           |
+-------------------------------+-----------------------------+
                                | (depends on abstractions)
                                v
+-------------------------------------------------------------+
|                        DOMAIN (pure)                        |
|  Entities: Wallet, Category, TransactionEntry, Budget, Money|
|  Services: MoneyFormatter, BudgetCalculator, SummaryCalc    |
|  Repo interfaces: Transaction/Category/Wallet/Budget/Settings|
+-------------------------------^-----------------------------+
                                | (implements)
                                |
+-------------------------------+-----------------------------+
|                          DATA                               |
|  AppDatabase (Drift) · DAOs · RepositoryImpls · SeedData    |
|  SettingsRepositoryImpl (shared_preferences)                |
+-------------------------------------------------------------+
```

## Screens
1. **AppLockGate** — biometric/device auth on launch when enabled.
2. **Home** — month summary, budget progress, recent transactions, quick-add FAB.
3. **Transactions** — grouped-by-date list, filter by wallet/category, tap to edit.
4. **Transaction Edit** — amount, kind (income/expense), category, wallet, date, note.
5. **Budgets** — per-category monthly budgets with progress bars.
6. **Reports** — spending-by-category pie + income/expense trend bar; period selector.
7. **Wallets** — CRUD + per-wallet balance.
8. **Categories** — CRUD.
9. **Settings** — currency, theme mode (system/light/dark), app-lock toggle.

## Data Model (logical)
- **Wallet**(id, name, type, icon, color, archived)
- **Category**(id, name, kind, icon, color, isDefault, archived)
- **TransactionEntry**(id, amountMinor, kind, categoryId→Category, walletId→Wallet, date, note)
- **Budget**(id, categoryId→Category, limitMinor, month `YYYY-MM`) — unique(categoryId, month)

## Key Rules (finalized in Functional Design)
- Money stored/computed as integer minor units; format only at display.
- Budget status: ok <80%, warn 80–99%, over ≥100% of limit for the month.
- Transaction requires non-zero amount + category + wallet.
- Deleting a category/wallet that has transactions is blocked or soft-archived.

## Cross-References
- Components: `components.md`
- Methods: `component-methods.md`
- Services/orchestration: `services.md`
- Dependencies/data flow: `component-dependency.md`

## Consistency Validation
- Every screen maps to at least one provider + repository. ✔
- Every repository interface has a Data-layer impl. ✔
- Domain has zero Flutter/DB imports (testable). ✔
- Money never represented as double. ✔
