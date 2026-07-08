# Business Logic Model — money-manager

## 1. Money Math (MoneyFormatter)
- Store everything as `amountMinor: int`. Currency has `decimalDigits` (most = 2; some 0/3).
- **Parse** user text → minor:
  1. Strip grouping separators + currency symbol.
  2. Split on decimal separator; pad/truncate fractional part to `decimalDigits`.
  3. `minor = whole * 10^digits + frac`. Reject if non-numeric or negative.
- **Format** minor → text: `major = minor ~/ 10^digits`, `frac = minor % 10^digits`, apply locale grouping + symbol.
- Never use `double` for storage or accumulation.

## 2. Add / Edit Transaction (TransactionController)
Inputs: amountText, kind, categoryId, walletId, date, note.
1. `amountMinor = MoneyFormatter.parse(amountText)` → must be > 0.
2. Validate category exists, not archived, `category.kind == kind`.
3. Validate wallet exists, not archived.
4. Build `TransactionEntry`; insert (or update by id).
5. Drift stream re-emits → dependent providers recompute.
Edit = same validation, update by id. Delete = remove by id.

## 3. Wallet Balance
`balanceMinor(wallet) = Σ income.amountMinor − Σ expense.amountMinor` over that wallet's transactions. Computed via SQL aggregate (watch stream). Combined total = Σ over non-archived wallets.

## 4. Period Summary (SummaryCalculator)
Given transactions in period:
- `incomeMinor = Σ where kind=income`
- `expenseMinor = Σ where kind=expense`
- `netMinor = incomeMinor − expenseMinor`
Period default = current calendar month; custom range supported in Reports.

## 5. Spending by Category
Filter expenses in period → group by categoryId → Σ amountMinor per group → sort desc. Feeds pie chart + budget rows.

## 6. Income vs Expense Trend
Bucket transactions by day (range ≤ 31d) or by month (longer range). Per bucket: income total, expense total. Feeds bar chart.

## 7. Budget Progress (BudgetCalculator)
For each budget of the selected month:
1. `spentMinor` = Σ expenses where categoryId == budget.categoryId AND month(date) == budget.month.
2. `remainingMinor = limitMinor − spentMinor`.
3. `percent = spentMinor / limitMinor` (guard limit>0).
4. Status: `over` if percent ≥ 1.0; `warn` if percent ≥ 0.8; else `ok`.
UI: progress bar color green/amber/red by status.

## 8. First-Run Seed (SeedData)
On DB creation:
- Insert 1 default Wallet: "Cash" (type cash).
- Insert default Categories:
  - Expense: Food, Transport, Shopping, Bills, Health, Entertainment, Other.
  - Income: Salary, Other Income.
- Mark all `isDefault = true`.

## 9. App Lock Flow (AppLockService + AppLockGate)
- On cold start (and optionally resume): if `appLockEnabled`, call `authenticate()` (local_auth biometric/device credential).
- Success → show MainShell. Failure → remain on lock screen with Retry.
- If lock enabled but no auth available on device → treat as unlocked (fail-open) and surface a settings warning.

## 10. Settings Effects
- currencyCode → re-render all money via MoneyFormatter.
- themeMode → MaterialApp themeMode.
- appLockEnabled → gate behavior next launch (and immediate if toggled on).
