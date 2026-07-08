# Frontend Components — money-manager

Flutter + Riverpod + Material 3. Navigation via `go_router` or nested Navigator; bottom nav shell.

## Navigation Shell
`MainShell` — Scaffold with `NavigationBar`, 5 destinations:
Home · Transactions · Budgets · Reports · Settings. Global FAB (quick add) on Home/Transactions.

## AppLockGate
- Root widget above MainShell.
- State: `locked: bool`.
- On start/resume with lock enabled → show lock UI + auto-trigger `authenticate()`.
- Actions: Unlock (retry). Success → render child.

## HomeScreen
- Watches: `monthSummaryProvider(currentMonth)`, `budgetProgressProvider(currentMonth)`, recent `monthTransactionsProvider`.
- Sections: SummaryCard (income/expense/net), BudgetProgressList (top budgets w/ colored bars), RecentTransactionsList (last ~10).
- FAB → TransactionEditScreen (new).

## TransactionsScreen
- Watches `transactionsProvider` (all) with filters.
- State: filterWalletId?, filterCategoryId?, dateRange?.
- List grouped by date (headers), each row: category icon, note, wallet, signed amount (green income / red expense).
- Tap row → TransactionEditScreen (edit). Swipe → delete (confirm).

## TransactionEditScreen
- Form fields: amount (numeric keypad), kind toggle (income/expense), category picker (filtered by kind), wallet picker, date picker, note.
- State: form values + validation errors (BR-T1..T5).
- Actions: Save (validate→controller.add/update), Delete (edit mode).

## BudgetsScreen
- Watches `budgetProgressProvider(month)` + month selector.
- Each row: category, spent/limit, progress bar (green/amber/red per status), remaining.
- Add/Edit budget dialog: expense category picker + limit amount. Upsert (BR-B2).

## ReportsScreen
- Controls: period selector (This Month / custom range).
- Charts (fl_chart):
  - Pie: spending by category (with legend + amounts).
  - Bar: income vs expense per bucket (day/month).
- Summary strip: total income, expense, net for period.

## WalletsScreen
- Watches `walletsProvider` + `walletBalanceProvider`.
- Row: name, type icon, balance. Add/Edit (name, type, icon, color). Archive/delete per BR-W2/W3.

## CategoriesScreen
- Two tabs: Expense / Income.
- Row: icon, name, default badge. Add/Edit (name, kind, icon, color). Archive/delete per BR-C2.

## SettingsScreen
- Currency picker (BR-S1), Theme mode selector (system/light/dark), App-lock switch (BR-S2).
- About section (version).

## Shared Widgets
- `MoneyText(amountMinor, currency, {signed})` — formats via MoneyFormatter, colors by sign.
- `CategoryAvatar(category)` — icon + color chip.
- `AmountInputField` — numeric input, parses on submit.
- `EmptyState` — friendly placeholder for empty lists.

## State Management Summary
- All lists via StreamProvider (Drift watch) → live updates.
- Derived summaries/budgets via Provider over streamed data (pure calculators).
- Form state local (StatefulWidget / local Notifier); commits through controllers.
- Settings via AsyncNotifierProvider.

## Interaction → Backend Map
| UI action | Provider/Controller | Repo |
|---|---|---|
| Save transaction | TransactionController | TransactionRepository |
| Delete transaction | TransactionController | TransactionRepository |
| Upsert budget | BudgetController | BudgetRepository |
| CRUD wallet | (wallet controller) | WalletRepository |
| CRUD category | (category controller) | CategoryRepository |
| Change setting | SettingsNotifier | SettingsRepository |
