# Components — Money Manager App

Layered, feature-first architecture. Three layers: **Presentation**, **Domain**, **Data**.

## Domain Layer (pure Dart, no Flutter/DB deps)

### Entities
| Entity | Purpose | Key fields |
|---|---|---|
| `Wallet` | A place money lives (cash/bank/card) | id, name, type, iconCodePoint, colorValue, archived |
| `Category` | Classify a transaction | id, name, kind(income/expense), iconCodePoint, colorValue, isDefault, archived |
| `TransactionEntry` | One income/expense record | id, amountMinor(int), kind, categoryId, walletId, date, note |
| `Budget` | Monthly limit for a category | id, categoryId, limitMinor(int), month(YYYY-MM) |
| `Money` | Value object for currency-safe math | amountMinor(int), currencyCode |

**Rule**: money always stored/computed as integer minor units (`amountMinor`). Formatting only at display.

### Domain Services (pure logic)
| Component | Responsibility |
|---|---|
| `MoneyFormatter` | Format `amountMinor` + currency into display string; parse input string into minor units |
| `BudgetCalculator` | Given budget + transactions of month, compute spent, remaining, percent, status (ok/warn/over). Fixed thresholds: warn ≥80%, over ≥100% |
| `SummaryCalculator` | Compute period totals: income, expense, net; group spending by category |

### Repository Interfaces (abstractions; implemented in Data layer)
- `WalletRepository`
- `CategoryRepository`
- `TransactionRepository`
- `BudgetRepository`
- `SettingsRepository`

## Data Layer (Drift / SQLite)

| Component | Responsibility |
|---|---|
| `AppDatabase` | Drift database: tables Wallets, Categories, Transactions, Budgets; migrations; first-run seed |
| `WalletDao` / `CategoryDao` / `TransactionDao` / `BudgetDao` | Typed queries per table |
| `*RepositoryImpl` | Implement domain repository interfaces over DAOs; map rows ↔ entities |
| `SettingsRepositoryImpl` | Persist currency, theme mode, app-lock flag (shared_preferences) |
| `SeedData` | Default categories + one default wallet inserted on first run |

## Presentation Layer (Flutter + Riverpod)

| Component | Responsibility |
|---|---|
| `AppLockGate` | On launch, if lock enabled, require biometric/device auth before showing app (local_auth) |
| `HomeScreen` | Dashboard: current-month summary (income/expense/balance) + budget progress + recent transactions |
| `TransactionsScreen` | Full transaction list, grouped by date, filter by wallet/category |
| `TransactionEditScreen` | Add/edit transaction form (amount, kind, category, wallet, date, note) |
| `BudgetsScreen` | List budgets with progress bars; add/edit monthly budget per category |
| `ReportsScreen` | Charts: spending-by-category (pie), income-vs-expense trend (bar); period selector |
| `WalletsScreen` | Manage wallets; per-wallet balance |
| `CategoriesScreen` | Manage categories (CRUD) |
| `SettingsScreen` | Currency, theme mode, app-lock toggle |
| `MainShell` | Bottom navigation host: Home · Transactions · Budgets · Reports · Settings |
| Riverpod providers | Expose repositories + derived state (async lists, computed summaries) to widgets |

## Component Responsibility Summary
- Domain owns rules + money correctness, zero framework deps → unit-testable.
- Data owns persistence + mapping.
- Presentation owns UI + user interaction, reads/writes through providers → repositories.
