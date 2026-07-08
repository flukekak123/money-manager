# Requirements — Money Manager App

## Intent Analysis
- **User Request**: "create app money manager using flutter"
- **Request Type**: New Project (greenfield)
- **Scope Estimate**: Multiple Components (single Flutter app, several feature modules)
- **Complexity Estimate**: Moderate
- **Requirements Depth**: Standard

## Product Summary
Offline-first personal finance app built in Flutter. Users log income/expenses, organize with categories, set per-category budgets, and view spending reports. All data stored locally on device. App protected by a device lock (PIN/biometric). MVP scope — lean, correct, polished core.

## Functional Requirements

### FR1 — Transaction Logging
- FR1.1 Add income and expense transactions.
- FR1.2 Each transaction: amount, type (income/expense), category, account/wallet, date, optional note.
- FR1.3 Edit and delete existing transactions.
- FR1.4 List transactions, most recent first, with running/date grouping.

### FR2 — Categories
- FR2.1 Predefined default categories (e.g., Food, Transport, Salary, Bills) seeded on first run.
- FR2.2 User can create, rename, delete custom categories.
- FR2.3 Category has name, icon, type (income/expense), color.

### FR3 — Budgets
- FR3.1 Set a monthly budget limit per category.
- FR3.2 Track spending against budget for the current period.
- FR3.3 Visual indicator when nearing or exceeding limit (in-app, no push).

### FR4 — Reports & Charts
- FR4.1 Spending by category (pie/bar) for a selected period.
- FR4.2 Income vs. expense trend over time.
- FR4.3 Period summary: total income, total expense, net balance.
- FR4.4 Period selector (this month / custom range).

### FR5 — Accounts / Wallets
- FR5.1 Support multiple wallets (cash, bank, card) — transactions assigned to a wallet.
- FR5.2 Per-wallet balance and combined total.
  *(Lightweight in MVP: at least one default wallet; multi-wallet if low cost.)*

### FR6 — App Lock
- FR6.1 Optional app lock via device PIN/passcode or biometric on launch.
- FR6.2 Toggle in settings; if enabled, require unlock to open app.

### FR7 — Settings
- FR7.1 Choose single app currency (display/formatting only).
- FR7.2 Toggle theme (system / light / dark).
- FR7.3 Toggle app lock.

## Non-Functional Requirements

### NFR1 — Platform
- Android + iOS via single Flutter codebase. Material 3 design.

### NFR2 — Data / Storage
- On-device only. Local relational DB (Drift over SQLite). No network/backend in MVP.
- Local-first design; no cloud sync in scope (not architected to preclude a future sync layer, but no work spent on it).

### NFR3 — Money Correctness
- Monetary amounts stored as integer minor units (e.g., cents) to avoid floating-point error. Format for display only.

### NFR4 — State Management
- Riverpod for app state.

### NFR5 — UI/UX
- Material 3, light + dark, follows system theme by default. Responsive to phone sizes.

### NFR6 — Usability
- Add-transaction flow reachable in ≤2 taps from home. Fast, minimal input.

### NFR7 — Maintainability / Testability
- Layered architecture (data / domain / presentation). Unit tests for money math, budget calc, category/transaction repositories.

### NFR8 — Privacy
- No data leaves the device. No analytics/telemetry in MVP.

## Out of Scope (v1)
- Cloud sync / multi-device.
- Multi-currency and currency conversion.
- Account login / social auth.
- Recurring/scheduled transactions.
- CSV/PDF export.
- Push notifications.

## Tech Decisions (confirmed)
| Concern | Choice |
|---|---|
| Framework | Flutter (Dart) |
| Targets | Android + iOS |
| Local DB | Drift (SQLite) |
| State mgmt | Riverpod |
| Design | Material 3, light + dark |
| Charts | fl_chart (proposed) |
| App lock | local_auth (proposed) |

## Extensions
- Security Baseline: OFF
- Resiliency Baseline: OFF
- Property-Based Testing: OFF

## Key Requirements Summary
Lean offline-first Flutter finance app: log transactions → categorize → budget → report, all local, device-lock protected, integer-based money math, Riverpod + Drift + Material 3.
