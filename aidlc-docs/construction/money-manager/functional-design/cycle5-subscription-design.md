# Cycle 5 Functional Design — Subscriptions (recurring monthly expense)

## 1. Domain Entities (`lib/domain/entities.dart`)

### Subscription (new)
| Field | Type | Notes |
|---|---|---|
| id | int | PK |
| name | String | 1..40 ("Netflix") |
| amountMinor | int | monthly charge |
| categoryId | int | expense category |
| walletId | int | wallet |
| startDate | DateTime | day-of-month anchor (clamped) |
| note | String? | ≤200, copied to charges |
| active | bool | false = cancelled |
| lastChargedDate | DateTime? | latest recorded due date; idempotency marker |
| createdAt | DateTime | no-backfill anchor (Q6=B) |

### TransactionEntry (extended)
- `subscriptionId: int?` — set on generated charges; null otherwise.
- `isSubscriptionCharge => subscriptionId != null`.

## 2. Materialization Algorithm (`lib/domain/services/subscription_calculator.dart`)

Pure, stateless, injectable `today` for tests. Reuses
`InstallmentCalculator.addMonthsClamped`.

```
dueDatesBetween(sub, today):
  // charge dates: startDate + i months (day clamped), i = 0,1,2,...
  // eligible window: due >= floorDate(max coverage anchor) and due <= today
  if sub.lastChargedDate == null:
      // Q6=B' (amended): current billing period only — latest due <= today.
      // One charge, so a new subscription hits this month's expenses.
      return [max due_i <= today] (or [] if startDate is future)
  else:
      lowerBound = dayAfter(sub.lastChargedDate)   // catch-up from marker
      collect due_i = addMonthsClamped(sub.startDate, i)
          while due_i <= today, keep those >= lowerBound
```

Materializer (repository, per subscription, one DB transaction — BR-SB5):
```
for due in dueDatesBetween(sub, today):
  insert expense txn(amountMinor, categoryId, walletId, date=due,
                     note=sub.note, subscriptionId=sub.id)
  update sub.lastChargedDate = due       // same transaction
```
- Idempotent: marker advances atomically with each batch; rerun yields zero new rows.
- Catch-up: app closed 3 months → 3 charges, correctly dated.
- Cancelled (`active == false`) subscriptions are skipped.

**Triggers**: app launch (composition root after DB ready) + after subscription create/edit. No background scheduler exists.

## 3. Business Rules (BR-SB*)

- **BR-SB1**: name required, 1..40 chars.
- **BR-SB2**: `amountMinor > 0`.
- **BR-SB3**: at create/edit — category expense-kind + non-archived, wallet non-archived (reuse BR-T3/T4).
- **BR-SB4**: charge transactions locked (same as BR-I4): repo update/delete throws `DomainException`; UI opens subscription sheet instead. No swipe-delete.
- **BR-SB5**: materialization atomic per subscription; `lastChargedDate` advances in same transaction; running twice creates nothing new.
- **BR-SB6**: edits (amount/name/category/wallet) affect FUTURE charges only; recorded transactions untouched.
- **BR-SB7**: cancel sets `active=false`, stops materialization, keeps history. No pause/resume this cycle.
- **BR-SB8**: hard delete allowed only when subscription has zero recorded charges; otherwise cancel is the only removal path.
- **BR-SB9**: archiving the linked category/wallet does NOT stop charging (archives hide pickers only); user edits the subscription to repoint.
- Charges are exempt from BR-T5 future-date rule trivially (due dates are always ≤ today by construction).

## 4. Repository (`lib/domain/repositories.dart`)

```dart
abstract class SubscriptionRepository {
  Stream<List<Subscription>> watchAll();          // active first, then cancelled
  Future<Subscription?> getById(int id);
  Stream<List<TransactionEntry>> watchCharges(int subscriptionId);
  Future<int> create(Subscription sub);           // then materialize
  Future<void> update(Subscription sub);          // BR-SB6; then materialize
  Future<void> cancel(int id);                    // BR-SB7
  Future<void> delete(int id);                    // BR-SB8 guard
  /// Records all due-but-unrecorded charges for active subscriptions.
  /// Returns number of transactions created. [today] injectable for tests.
  Future<int> materializeDueCharges({DateTime? today});
}
```
- `TransactionRepository.update/delete` guard extended: blocks rows with `subscriptionId != null` too (shared lock guard with installments).

## 5. Data Layer
- **Schema v3**: `Subscriptions` table (fields per entity); `Transactions` + nullable `subscriptionId` FK. Migration `from < 3`: createTable + addColumn (additive).
- **Backup v3**: top-level `subscriptions` array; txn objects gain `subscriptionId`. Import accepts v1/v2/v3 (older → empty subscriptions, null fields). Wipe: transactions → subscriptions/installmentPlans → categories → wallets. Restore reverse.

## 6. Application Layer
- `subscriptionRepositoryProvider`, `subscriptionsProvider` (stream), `subscriptionChargesProvider(id)`, `subscriptionsByIdProvider` (badges).
- `SubscriptionController`: validate (BR-SB1..SB3) + create/update/cancel/delete; calls materialize after create/update.
- **Launch hook**: `MoneyManagerApp` startup runs `materializeDueCharges()` once (fire-and-forget with error swallow to snackbar-less log; UI streams update reactively).

## 7. Frontend Components
- **Settings → Manage → "Subscriptions"** `ListTile` → `SubscriptionsScreen`:
  list (name, amount/month, next charge date or "cancelled"), FAB add.
- **Edit form** (`SubscriptionEditScreen`): name, amount, category (expense only), wallet, start date, note; Cancel-subscription button when editing active one; Delete only when zero charges (BR-SB8).
- **Charge badge**: transaction tiles show autorenew icon + subscription name context; tap opens **subscription detail sheet** (mirror installment sheet): amount/month, next charge, charge history, Cancel button.
- **Localization**: all new strings EN + TH.

## 8. Test Plan
- Calculator: dueDatesBetween — first charge on startDate (today/future), past startDate anchors day only (no backfill), catch-up 3 missed months, clamp Jan 31 → Feb 28/29, marker lower bound.
- Repo: create+materialize records due charge; double materialize = 0 new; cancel stops; edit changes future amount only; BR-SB4 lock; BR-SB8 delete guard.
- Backup: v3 round-trip; v2 import still works.
