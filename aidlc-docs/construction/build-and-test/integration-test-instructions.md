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

## Manual E2E walkthrough (recommended before release)
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
