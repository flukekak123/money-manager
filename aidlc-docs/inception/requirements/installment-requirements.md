# Installment Expense Requirements (Cycle 4)

## Intent Analysis
- **User request**: "add expense that have installment like 3,6,10,12 month"
- **Request type**: New feature (brownfield enhancement)
- **Scope estimate**: Multiple components (domain, data, application, presentation)
- **Complexity estimate**: Moderate — new table + generation logic + UI, no architectural change

## Functional Requirements

### FR-1: Create installment expense
- User records an expense as an installment purchase: total amount, months (**3, 6, 10, or 12 only** — fixed presets), category, wallet, purchase date, optional note.
- App creates one **installment plan** record plus **N expense transactions** upfront, one per month, each linked to the plan.
- First installment is dated on the **purchase date**; each subsequent installment on the **same day of the following month** (clamp to last day of shorter months, e.g., Jan 31 → Feb 28).

### FR-2: Even split, remainder to last
- Total (integer minor units) is split evenly: `base = total ~/ months`.
- The **last installment absorbs the remainder**: `last = total - base × (months - 1)` (e.g., 1,000.00 over 3 → 333.33 / 333.33 / 333.34).
- No interest or fees — sum of installments always equals total exactly.

### FR-3: Monthly integration
- Each installment transaction counts in **its own month's** summaries, budgets, category spending, and trends — no special-casing in calculators.
- Wallet balance decreases **gradually**, one installment per month (future installments exist as future-dated transactions).

### FR-4: Plan-level edit/delete only
- Installment transactions are **not individually editable or deletable**; edits/deletes happen on the plan and regenerate/remove all its transactions.
- Attempting to edit/delete a single linked transaction directs the user to the plan (business rule violation → `DomainException`).
- Deleting a plan deletes all N linked transactions atomically.

### FR-5: Visibility
- Installment transactions are identifiable in lists (e.g., badge/label such as "3/6").
- User can view the plan (total, progress, remaining) and see linked installments.

## Non-Functional Requirements
- **NFR-1**: Money stays integer minor units end-to-end (`core/money.dart`), never `double`.
- **NFR-2**: Plan creation and deletion are atomic (single DB transaction; rollback on error).
- **NFR-3**: Works on all existing targets (Android/iOS/web PWA); no new platform-specific code.
- **NFR-4**: Backup/restore (`backup_service.dart`) includes installment plans and their links — schema version bump with migration.
- **NFR-5**: All new UI strings localized in English + Thai (both ARB files).
- **NFR-6**: Existing business rules preserved (wallet delete blocked when referenced, archived category handling, etc.).

## Out of Scope (this cycle)
- Interest/fee-bearing installments.
- Custom month counts beyond 3/6/10/12.
- Editing/deleting individual installment transactions.
- Notifications/reminders for upcoming installments.

## Decisions Record
| # | Question | Decision |
|---|---|---|
| 1 | Storage model | Plan + N upfront linked expense transactions |
| 2 | Rounding remainder | Last installment absorbs remainder |
| 3 | Month counts | Fixed presets: 3, 6, 10, 12 |
| 4 | First due date | Purchase date; monthly same-day after (clamped) |
| 5 | Edit/delete | Whole plan only |
| 6 | Interest | None — even split |
| 7 | Wallet balance | Gradual, per month |
