# Application Design — Cycle 2: Web / PWA

Delta over Cycle 1 architecture. Layered structure unchanged
(presentation → application → domain; data implements domain).

## New / Changed Components

### 1. Conditional DB connection (data layer)
Replace `_openConnection()` inside `lib/data/database.dart` with a platform-split
connection module so web builds never import `dart:io`/`path_provider`:

```
lib/data/connection/
  connection.dart          # exports openConnection() via conditional import
  connection_native.dart   # NativeDatabase + path_provider (mobile/desktop)
  connection_web.dart      # WasmDatabase (sqlite3.wasm + drift worker, OPFS)
```

- `connection.dart` uses:
  `export 'connection_native.dart' if (dart.library.js_interop) 'connection_web.dart';`
- `AppDatabase()` constructor calls `openConnection()` from this module.
- `AppDatabase.forTesting` unchanged (tests keep NativeDatabase.memory()).
- Web assets required in `web/`: `sqlite3.wasm`, `drift_worker.dart.js`.

### 2. App-lock guard (application/presentation)
- `AppLockService.isAvailable()` / `authenticate()`: return unlocked early when
  `kIsWeb` (import `package:flutter/foundation.dart`).
- `AppLockGate`: if `kIsWeb`, render child directly (no lock screen).
- Settings: hide/disable the app-lock toggle on web.

### 3. BackupService (data layer) — new
`lib/data/backup_service.dart`, constructed with `AppDatabase`.
- `Future<String> exportJson()` — reads all 4 tables, returns JSON string
  (schema `version: 1`). Encodes DateTime as ISO-8601, enum ints as-is.
- `Future<void> importReplace(String json)` — validates version + shape; inside
  a single `db.transaction`, deletes all rows (respecting FK order:
  budgets, transactions, then categories, wallets) and re-inserts from file
  with explicit IDs preserved. Throws `DomainException` on malformed input.
- Pure serialization helpers unit-testable via `AppDatabase.forTesting`.

### 4. File I/O (platform-portable)
New deps: `file_saver` (export/download) + `file_picker` (import).
- Export: `BackupService.exportJson()` → `FileSaver` saves
  `money-manager-backup-YYYY-MM-DD.json` (browser download on web; save/share on mobile).
- Import: `FilePicker` picks a `.json` → read bytes → `importReplace`.
- Thin `BackupController` (application) orchestrates: pick/save + call service +
  surface errors; exposed via a provider.

### 5. Settings UI (presentation)
Add a "Data" section to `settings_screen.dart`:
- **Export data** button → save file, snackbar on success.
- **Import data** button → pick file → confirm dialog ("Replace all current
  data? This cannot be undone.") → restore → snackbar; refresh streams.
- App-lock toggle guarded off on web.

### 6. PWA scaffold (web/)
`flutter create --platforms=web .` then customize:
- `web/manifest.json`: name/short_name "Money Manager", `display: standalone`,
  theme_color/background_color from theme, icons 192/512 + maskable.
- `web/index.html`: title, apple-mobile-web-app-capable meta for iOS home-screen.
- `web/icons/`: generated placeholder mark (solid color + wallet glyph).
- Drift web runtime assets copied into `web/`.

## Component Dependencies (new)
```
SettingsScreen ──▶ BackupController ──▶ BackupService ──▶ AppDatabase
                        │                                   ▲
                        └── file_saver / file_picker        │
AppDatabase ──▶ connection.dart ──(conditional)──▶ native | web
AppLockGate / AppLockService ──▶ kIsWeb guard
```

## Unchanged
Domain entities, repository interfaces + impls, calculators, generated
`database.g.dart`, Riverpod provider graph (only adds backup providers), all
existing screens except Settings.
