# Business Rules — money-manager

## Transaction Rules
- BR-T1: `amountMinor` must be > 0. Zero/negative rejected with inline error.
- BR-T2: `kind` ∈ {income, expense}.
- BR-T3: assigned category must exist, be non-archived, and `category.kind == transaction.kind`.
- BR-T4: assigned wallet must exist and be non-archived.
- BR-T5: `date` cannot be in the future beyond today (configurable; default disallow future dates). Note ≤ 200 chars.
- BR-T6: editing recalculates all dependent balances/summaries automatically (reactive).

## Category Rules
- BR-C1: name required, 1..40 chars, unique within same `kind` (case-insensitive).
- BR-C2: cannot delete a category referenced by any transaction → block, offer archive.
- BR-C3: default (seeded) categories may be archived/renamed but archiving hides from pickers.
- BR-C4: only expense categories can have budgets.

## Wallet Rules
- BR-W1: name required, 1..40 chars, unique (case-insensitive).
- BR-W2: cannot delete a wallet referenced by any transaction → block, offer archive.
- BR-W3: at least one non-archived wallet must exist at all times (block archiving the last active wallet).

## Budget Rules
- BR-B1: `limitMinor` must be > 0.
- BR-B2: one budget per (category, month) — enforced by unique constraint; re-adding upserts.
- BR-B3: budget applies only to its `month` (`YYYY-MM`); spending counted from transactions in that month.
- BR-B4: status thresholds fixed — warn ≥ 80%, over ≥ 100%.
- BR-B5: budget only for expense-kind categories.

## Money Rules
- BR-M1: all amounts stored/computed as integer minor units.
- BR-M2: display formatting applies currency `decimalDigits` + locale grouping.
- BR-M3: no floating-point arithmetic on monetary values.

## Settings / Lock Rules
- BR-S1: currency change is display-only; does not convert stored amounts.
- BR-S2: enabling app lock requires device biometric/credential availability; if unavailable, enabling shows a warning and lock fails open.
- BR-S3: theme mode ∈ {system, light, dark}; default system.

## Validation Error Handling
- All validation failures surface as inline field errors, non-destructive (form retains input).
- Repository/DB errors surface as a snackbar; operation rolled back (no partial writes).
