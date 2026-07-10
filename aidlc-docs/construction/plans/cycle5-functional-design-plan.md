# Cycle 5 Functional Design Plan — Subscriptions (unit: money-manager)

## Design Steps
- [x] Domain entity `Subscription` + `TransactionEntry.subscriptionId`
- [x] Due-date/materialization algorithm (reuse `addMonthsClamped`; injectable "today")
- [x] Business rules BR-SB1..BR-SB9
- [x] Repository interface (`SubscriptionRepository` incl. `materializeDueCharges`)
- [x] Schema v3 + backup JSON v3 (imports v1/v2)
- [x] Frontend components (Subscriptions screen, edit form, badges, charge tap routing)

## Open Questions
None — user-facing decisions all resolved in requirements Q&A (Q1..Q6). Implementation-level decisions taken and documented below; challengeable at review.

## Design Decisions (implementation-level)
1. **Idempotency**: `lastChargedDate` marker column on subscription, advanced inside the same DB transaction as each charge insert. Monotonic; single-writer app → no double charges even if materializer runs twice.
2. **No-backfill anchor (Q6=B)**: charges generated only for due dates ≥ `date(createdAt)`; `startDate` supplies the day-of-month anchor.
3. **Archived category/wallet while active**: charges CONTINUE (archive only hides pickers; blocking silently would corrupt expectations). User edits subscription to repoint.
4. **Materializer triggers**: app launch (composition root, after DB ready) + after subscription create/edit. No timer/background work.
5. **Charge tap routing**: opens subscription detail sheet (mirror installment plan sheet).
