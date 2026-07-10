# Subscription (Recurring Monthly Expense) — Requirements Questions (Cycle 5)

Answer with letter after each `[Answer]:` tag. Say "done" when finished.
Context: offline-first app — no server, no background scheduler. Recommended answers marked.

## Question 1
How are monthly charges recorded? (App can only act when opened.)

A) Materialize on app open — each launch, app creates real expense transactions for any due-but-unrecorded charges (catches up missed months automatically) (Recommended)

B) Pre-generate future charges upfront (e.g. next 12 months) like installments, extend over time

C) Virtual — no real transactions; monthly summaries just add active subscription costs on the fly

D) Other (please describe after [Answer]: tag below)

[A]:

## Question 2
Charge day each month?

A) Day of the subscription's start date, clamped for short months (start Jan 31 → charges Feb 28, Mar 31 — same rule as installments) (Recommended)

B) Separate "billing day" field independent of start date

C) Other (please describe after [Answer]: tag below)

[A]:

## Question 3
Subscription lifetime?

A) Active until cancelled; cancelling stops future charges, keeps past transactions (Recommended)

B) Active until cancelled, plus pause/resume support

C) Optional fixed end date as well

D) Other (please describe after [Answer]: tag below)

[A]:

## Question 4
Price changes (e.g. Netflix raises price)?

A) Subscription is editable — new amount/name/category/wallet applies to FUTURE charges only; past transactions unchanged (Recommended)

B) Immutable like installment plans — cancel + recreate to change

C) Other (please describe after [Answer]: tag below)

[A]:

## Question 5
Generated charge transactions individually editable/deletable?

A) Locked like installments — manage via the subscription; tap opens subscription detail (Recommended, consistent with Cycle 4)

B) Editable/deletable like normal transactions

C) Other (please describe after [Answer]: tag below)

[A]:

## Question 6
If start date is in the past (e.g. subscribed 3 months ago), backfill charges?

A) Yes — generate all charges from start date through today on creation (Recommended)

B) No — first charge is the next due date from today

C) Other (please describe after [Answer]: tag below)

[B]:
