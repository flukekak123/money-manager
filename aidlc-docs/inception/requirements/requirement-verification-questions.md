# Requirements Verification Questions — Money Manager App (Flutter)

Answer each by filling the letter after `[Answer]:`. If none fit, pick the Other option and describe.

## Question 1
Which platforms must the app target?

A) Android only

B) iOS only

C) Android + iOS (mobile)

D) Mobile + Web + Desktop (all Flutter targets)

X) Other (please describe after [Answer]: tag below)

[C]:

## Question 2
Where should financial data live?

A) On-device only, local storage (offline-first, no server)

B) Cloud backend with sync across devices (needs backend + accounts)

C) On-device now, cloud sync later (design local-first, leave hook)

X) Other (please describe after [Answer]: tag below)

[A]:

## Question 3
Which core features are in scope for v1? (pick all that apply — list letters)

A) Income/expense transaction logging

B) Categories & tags for transactions

C) Budgets per category with limit alerts

D) Multiple accounts/wallets (cash, bank, card)

E) Reports & charts (spending by category, trends over time)

F) Recurring transactions / scheduled bills

G) Data export (CSV / PDF)

X) Other (please describe after [Answer]: tag below)

[A,B,C,E]:

## Question 4
Multi-currency support?

A) Single currency only (user picks one)

B) Multiple currencies, no conversion

C) Multiple currencies with exchange-rate conversion

X) Other (please describe after [Answer]: tag below)

[A]:

## Question 5
Do you need user authentication / login?

A) No auth — single local user

B) App lock only (PIN / biometric) to open app

C) Full account login (email/password or social)

X) Other (please describe after [Answer]: tag below)

[B]:

## Question 6
Local database preference?

A) No preference — recommend best fit (I suggest Drift/SQLite)

B) SQLite (via drift or sqflite)

C) Hive / Isar (NoSQL key-value)

X) Other (please describe after [Answer]: tag below)

[A]:

## Question 7
State management approach?

A) No preference — recommend best fit (I suggest Riverpod)

B) Riverpod

C) Bloc / Cubit

D) Provider

X) Other (please describe after [Answer]: tag below)

[A]:

## Question 8
UI style / theme?

A) Material 3 default, light + dark mode

B) Material 3, light only

C) Custom branded design (provide colors later)

X) Other (please describe after [Answer]: tag below)

[A]:

## Question 9
Scope target for this build?

A) MVP — core logging + categories + simple summary, keep it lean

B) Full-featured — all selected features polished

X) Other (please describe after [Answer]: tag below)

[A]:

---

# Extension Opt-Ins

## Question: Security Extensions
Should security extension rules be enforced for this project?

A) Yes — enforce all SECURITY rules as blocking constraints (recommended for production-grade applications)

B) No — skip all SECURITY rules (suitable for PoCs, prototypes, and experimental projects)

X) Other (please describe after [Answer]: tag below)

[B]:

## Question: Resiliency Extensions
Should the resiliency baseline be applied to this project? (AWS Well-Architected Reliability directional best practices. Mostly aimed at cloud/server workloads.)

A) Yes — apply resiliency baseline as design-time guidance

B) No — skip (suitable for local-first mobile app / prototype)

X) Other (please describe after [Answer]: tag below)

[B]:

## Question: Property-Based Testing Extension
Should property-based testing (PBT) rules be enforced?

A) Yes — enforce all PBT rules (good for money math, serialization, budget logic)

B) Partial — PBT only for pure functions and serialization round-trips

C) No — skip all PBT rules

X) Other (please describe after [Answer]: tag below)

[C]:
