# Subscription Requirements (Cycle 5)

## Intent Analysis
- **User request**: "let create subscribe that pay every month"
- **Request type**: New feature (brownfield enhancement)
- **Scope estimate**: Multiple components (domain, data, application, presentation)
- **Complexity estimate**: Moderate — new table + on-launch materializer + management UI

## Functional Requirements

### FR-1: Create subscription
- User creates a subscription: name (e.g. "Netflix"), monthly amount, category (expense), wallet, start date, optional note.
- Charge day = day-of-month of start date, clamped to last day of shorter months (reuse installment date rule).

### FR-2: Automatic monthly charge recording (materialize on open)
- No background scheduler exists (offline app). On app launch (and on subscription create/edit), the app generates real expense transactions for every due-but-unrecorded charge date up to today.
- Missed months are caught up automatically (e.g. app unopened for 3 months → 3 charges created, correctly dated).
- **No backfill before creation** (Q6=B): charges are only generated for due dates on/after the subscription's creation; a past start date only sets the charge day anchor. First charge = next due date from creation (or the start date itself if today/future).
- Idempotent: a given (subscription, due date) charge is recorded at most once.

### FR-3: Charges are real, locked transactions
- Generated charges are normal expense transactions (count in month summaries, budgets, reports, wallet balance).
- Individually locked like installments: edit/delete of a charge transaction is blocked (`DomainException`); tap opens the subscription detail instead.

### FR-4: Subscription lifecycle
- Active until cancelled. Cancel stops all future charges; past charge transactions remain.
- Editable while active: amount/name/category/wallet changes apply to FUTURE charges only; already-recorded transactions unchanged.
- Deleting a cancelled/active subscription: cancel is the normal path; hard delete allowed only when it has no recorded charges (else cancel).

### FR-5: Management UI
- Subscriptions screen (list: name, amount, next charge date, active/cancelled) with add/edit/cancel; reachable from Settings "Manage" section.
- Charge transactions badged in lists (subscription icon/label); tap opens subscription detail.

## Non-Functional Requirements
- **NFR-1**: Money integer minor units end-to-end.
- **NFR-2**: Materialization atomic per subscription (one DB transaction); safe against double-run (idempotency via last-charged marker or unique constraint).
- **NFR-3**: Works Android/iOS/web; no platform-specific code; no notifications this cycle.
- **NFR-4**: Backup JSON v3 including subscriptions; imports v1/v2.
- **NFR-5**: EN + TH localization for all new strings.

## Out of Scope (this cycle)
- Non-monthly intervals (weekly/yearly), trials, reminders/notifications, pause/resume, price history log.

## Decisions Record
| # | Question | Decision |
|---|---|---|
| 1 | Recording | Materialize on app open, auto catch-up |
| 2 | Charge day | Start date's day, clamped |
| 3 | Lifetime | Active until cancelled; history kept |
| 4 | Price change | Editable; future charges only |
| 5 | Charge transactions | Locked; manage via subscription |
| 6 | Backfill | No — charges from creation forward |
