# Requirements — Cycle 2: Web / PWA Support

**Type**: Brownfield feature addition
**Unit**: money-manager (single unit, unchanged)
**Risk**: Low–Medium (touches data-layer connection + platform guards; core domain untouched)

## Intent
Let the user run Money Manager as an installable PWA on iPhone (Safari → Add to
Home Screen) for real daily use, avoiding Xcode / App Store / Apple Developer
cost. App stays offline-first; no backend introduced.

## Functional Requirements

### FR-1 — Web-capable data layer
- Drift database must run on web via `WasmDatabase` (sqlite3 WASM + drift worker,
  persisted in browser OPFS/IndexedDB).
- Mobile (Android/iOS native) must keep using `NativeDatabase` + `path_provider`
  unchanged.
- Connection selection is compile-time conditional (native vs web import), so
  `dart:io`/`path_provider` are never referenced in a web build.
- Domain, repositories, queries, and generated `database.g.dart` remain unchanged.

### FR-2 — App-lock platform guard
- On web, `local_auth` is unavailable. App-lock is disabled on web:
  `AppLockService` (and the gate) short-circuit to unlocked when `kIsWeb`.
- Mobile biometric/device-credential lock behavior unchanged.

### FR-3 — PWA scaffold
- Scaffold `web/` (index.html, manifest.json, icons, favicon).
- `manifest.json`: name "Money Manager", standalone display, theme/background
  colors matching app theme, maskable + standard 192/512 icons.
- Placeholder app icons generated (simple branded mark) — user can replace later.
- Installable + offline-capable (Flutter's default service worker).

### FR-4 — Backup: Export
- User can export all data (wallets, categories, transactions, budgets) to a
  JSON file, schema-versioned (`"version": 1`).
- Export downloads a file on web; on mobile, shares/saves a file.
- Accessible from Settings screen.

### FR-5 — Backup: Import / Restore
- User can import a previously exported JSON file to restore data.
- Import validates the schema version and structure; rejects malformed files
  with a clear error (no partial/corrupt writes).
- Import strategy: **replace** (clear existing rows, load from file) inside a
  single transaction. Confirm destructive action before replacing.
- IDs and references (categoryId/walletId) preserved so budgets/transactions
  stay linked.

## Non-Functional / Constraints
- No change to money-as-integer-minor-units invariant.
- No new heavyweight deps beyond what web + file I/O require (Drift wasm is part
  of `drift`; add `file_saver`/`file_picker` or use platform channels for
  file I/O — decided in Application Design).
- Must keep `flutter analyze` clean and existing 25 tests passing.
- iOS PWA storage caveat documented for the user (OPFS needs iOS 16.4+; installed
  home-screen PWA persists but backup mitigates eviction risk — this is FR-4/5's
  reason for existing).

## Out of Scope (this cycle)
- PIN-based lock on web (deferred; web lock simply disabled).
- Cloud sync / multi-device.
- Merge-on-import (only replace supported this cycle).
- Custom-branded final icon art (placeholder only).

## Decisions (from user, Cycle 2 requirements gate)
- Backup format: **JSON export/import** (portable, inspectable).
- Web scope: **Full web + PWA now** (manifest, icons, wasm, service worker).
- Web app-lock: **Disabled on web** via `kIsWeb` guard.
