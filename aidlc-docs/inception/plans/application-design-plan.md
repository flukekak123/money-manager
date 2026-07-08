# Application Design Plan — Money Manager App

## Design Artifacts to Produce (checklist)
- [ ] components.md — component definitions + responsibilities
- [ ] component-methods.md — method signatures + input/output
- [ ] services.md — service/orchestration definitions
- [ ] component-dependency.md — dependency matrix + data flow
- [ ] application-design.md — consolidated design doc
- [ ] Validate design completeness and consistency

## Proposed Architecture (for your awareness)
Layered, feature-first:
- **Presentation**: Flutter screens + widgets, Riverpod providers.
- **Domain**: entities (Transaction, Category, Budget, Wallet), use-cases / pure logic (money math, budget calc).
- **Data**: Drift database, DAOs, repositories implementing domain interfaces.

Proposed screens: Home/Dashboard, Transactions list, Add/Edit Transaction, Budgets, Reports, Settings, plus App-Lock gate.

---

## Design Questions

## Question 1
Multi-wallet scope for the MVP?

A) Single implicit wallet only — simplest, no wallet UI (defer multi-wallet)

B) Multi-wallet, lightweight — a Wallets list + assign wallet on each transaction, per-wallet balance

X) Other (please describe after [Answer]: tag below)

[Answer]: B

## Question 2
Primary navigation pattern?

A) Bottom navigation bar with tabs: Home, Transactions, Budgets, Reports, Settings

B) Bottom nav with fewer tabs (Home, Transactions, Reports) + Settings/Budgets in menu

X) Other (please describe after [Answer]: tag below)

[Answer]: A

## Question 3
What should the Home/Dashboard show first?

A) Current-month summary (income, expense, balance) + recent transactions + budget progress

B) Big current balance + quick-add button + recent transactions

C) Spending chart first + summary below

X) Other (please describe after [Answer]: tag below)

[Answer]: A

## Question 4
Budget alert behavior?

A) Configurable warn threshold per budget (e.g. warn at 80%, over at 100%)

B) Fixed: warn at 80%, over at 100% (no per-budget config)

C) Only flag when over 100%

X) Other (please describe after [Answer]: tag below)

[Answer]: B

## Question 5
Default seed data on first run?

A) Seed common default categories (Food, Transport, Bills, Salary, etc.) — user can edit/delete

B) Start empty — user creates all categories

X) Other (please describe after [Answer]: tag below)

[Answer]: A
