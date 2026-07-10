# Integration Test Instructions — money-manager (Cycle 4)

Single-unit offline app: "integration" = layers working together against a real
(in-memory) SQLite via drift. No services to start; no cleanup beyond test
teardown (`db.close()`).

## Automated (already in `flutter test`)
| Scenario | Layers | Test |
|---|---|---|
| Plan create → N transactions visible in month streams | application → data → DB | installment_repository_test |
| Installment edit/delete blocked, plan delete cascades | repo guard → DB | installment_repository_test |
| Backup export → import into fresh DB preserves plans + links | backup service → DB | backup_service_test |
| Seeded boot + wallet balance from transactions | seed → repo → DB | database_test |
| App boots, navigation, forms render | UI → providers (fakes) | widget_smoke_test |

## Automated — Cycle 5 additions (already in `flutter test`)
| Scenario | Test |
|---|---|
| Create subscription → charge due today materialized | subscription_repository_test |
| Double materialize = 0 new (idempotent marker) | subscription_repository_test |
| 3-month catch-up (injected today) | subscription_repository_test |
| Cancel stops charges, history kept; edit future-only | subscription_repository_test |
| Charge lock + delete guard (BR-SB4/SB8) | subscription_repository_test |
| Due-date math: no-backfill, clamp, marker bound | subscription_calculator_test |
| Backup v3 round-trip; v1+v2 imports | backup_service_test |

## Manual E2E walkthrough — Cycle 5 (subscriptions)
1. Settings → Subscriptions → + → name "Netflix", amount 419, category, wallet, start today → Save
2. Transactions: charge row today with autorenew badge "Netflix"; wallet balance decreased
3. Swipe charge row → no delete; tap → sheet: ฿419.00/เดือน, next charge next month, history 1 row
4. Edit amount to 499 → past charge unchanged; next month's charge (after device date passes) records 499
5. Sheet → Cancel subscription → confirm → listed as cancelled, history kept, no new charges
6. Export JSON → `"version": 3` + `subscriptions` array; import restores
7. Thai: toggle language → "บริการรายเดือน" in Settings

## Manual E2E walkthrough (Cycle 4 — installments)
```bash
flutter run -d chrome   # or device
```
1. Add expense, toggle "Pay in installments", pick 6, amount 1000 → preview shows 6 × 166.66 (last 166.70)
2. Save → snackbar; Transactions list shows badge "1/6" this month
3. Home/Reports: this month's expense includes only first installment
4. Tap installment row → plan sheet: total 1,000.00, "1 of 6 paid", 6 dated rows
5. Swipe installment row → no delete offered; swipe normal row → delete works
6. Plan sheet → Delete plan → confirm → all 6 rows gone
7. Settings → Export data → JSON contains `"version": 2` + `installmentPlans`
8. Import that JSON → plans + badges restored
9. Switch language to ไทย → toggle reads "ผ่อนชำระ", sheet "แผนผ่อนชำระ"

## Migration check (existing installs)
Upgrade path v1→v2 is additive (`createTable` + 2 `addColumn`). To verify on a
device with existing v1 data: install previous build, add data, install this
build → data intact, installment feature available.
