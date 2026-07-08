# Functional Design — Cycle 2 Backup + Web

## JSON Backup Schema (version 1)
```json
{
  "version": 1,
  "exportedAt": "2026-07-08T12:00:00.000Z",
  "wallets": [
    {"id": 1, "name": "Cash", "type": 0, "iconCodePoint": 0xe263,
     "colorValue": 4283215696, "archived": false}
  ],
  "categories": [
    {"id": 1, "name": "Food", "kind": 1, "iconCodePoint": 0xe57a,
     "colorValue": 4293467747, "isDefault": true, "archived": false}
  ],
  "transactions": [
    {"id": 1, "amountMinor": 1250, "kind": 1, "categoryId": 1, "walletId": 1,
     "date": "2026-07-01T00:00:00.000", "note": "lunch",
     "createdAt": "2026-07-01T09:30:00.000"}
  ],
  "budgets": [
    {"id": 1, "categoryId": 1, "limitMinor": 50000, "month": "2026-07"}
  ]
}
```
- Enums serialized as their stored `int` index (matches DB columns).
- Money stays integer minor units (no float).
- Dates ISO-8601 strings (`DateTime.toIso8601String()` / `DateTime.parse`).
- `note` nullable; omitted-or-null tolerated on import.

## Business Rules — Backup
- **BR-B1 (version)**: `version` must equal `1`; else
  `DomainException('Unsupported backup version')`.
- **BR-B2 (shape)**: top-level `wallets`, `categories`, `transactions`,
  `budgets` must be present and be lists; else
  `DomainException('Invalid or corrupt backup file')`.
- **BR-B3 (atomic replace)**: import runs inside one `db.transaction`. Delete
  order (children → parents): budgets, transactions, categories, wallets.
  Insert order (parents → children): wallets, categories, transactions, budgets.
- **BR-B4 (id preservation)**: rows inserted with explicit `id` (Companion
  `Value(id)`) so `categoryId`/`walletId` references stay valid.
- **BR-B5 (rollback)**: any parse/insert error throws inside the transaction →
  Drift rolls back → original data intact.
- **BR-B6 (confirm)**: UI must confirm before import (destructive replace).

## Web Business Rules
- **BR-W-WEB1**: on web (`kIsWeb`), app-lock is inactive — gate renders child
  directly; `authenticate()` returns `true`; lock toggle hidden in Settings.
- **BR-W-WEB2**: web DB persists in OPFS via `WasmDatabase`; same schema/queries
  as native. No `dart:io` in web build (enforced by conditional import).
