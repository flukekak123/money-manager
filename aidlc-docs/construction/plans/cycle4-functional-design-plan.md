# Cycle 4 Functional Design Plan — Installment Expenses (unit: money-manager)

## Design Steps
- [x] Extend domain entities: `InstallmentPlan`, `TransactionEntry.installmentPlanId` + display info
- [x] Define split algorithm (`InstallmentCalculator`): even split, remainder to last, month-day clamp
- [x] Define business rules (BR-I*) incl. BR-T5 exemption for generated installments
- [x] Define repository interface changes (`InstallmentRepository`, transaction guards)
- [x] Define backup JSON v2 shape + v1 compatibility
- [x] Define frontend components (entry form, badges, plan management)

## Pre-resolved Design Decisions (from approved requirements)
- Plan + N transactions upfront; presets 3/6/10/12; remainder to last; first due purchase date, same day monthly (clamped); no interest; whole-plan edit/delete; gradual wallet balance.
- **BR-T5 conflict**: current rule blocks future transaction dates. Installments require future-dated generated transactions. Resolution: BR-T5 applies to manually entered transactions only; plan-generated installments are exempt (system-dated).

## Open Questions

## Question 1
Where does the user create an installment expense?

A) Inside the existing add-expense form — a "Pay in installments" toggle reveals a 3/6/10/12 preset picker (amount field = total)

B) Separate dedicated "Add installment" screen/menu entry

C) Other (please describe after [Answer]: tag below)

[Answer]: A

## Question 2
"Edit plan" semantics after some installments' months have passed?

A) No edit — plan is immutable; to change it, delete plan (removes all N transactions) and create a new one

B) Full edit — changing total/months/category/wallet/date regenerates all N transactions, including past months

C) Other (please describe after [Answer]: tag below)

