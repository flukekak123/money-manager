# Code Summary — Cycle 2: Web / PWA + Backup

## Result
- `flutter analyze`: **No issues found**
- `flutter test`: **29/29 passing** (25 original + 4 new backup tests)
- `flutter build web`: **success** (dart2js + wasm dry-run OK; `dart:io` excluded from web build)
- Local serve smoke: index + manifest + `sqlite3.wasm` + `drift_worker.js` + app JS all return HTTP 200

## Files
### New
- `lib/data/connection/connection.dart` — conditional export (native vs web)
- `lib/data/connection/connection_native.dart` — NativeDatabase + path_provider
- `lib/data/connection/connection_web.dart` — WasmDatabase (OPFS)
- `lib/data/backup_service.dart` — JSON v1 export + atomic import-replace
- `lib/application/controllers/backup_controller.dart` — file_saver/file_picker orchestration
- `test/backup_service_test.dart` — round-trip, version reject, malformed reject, rollback
- `tool/drift_worker.dart` — worker source (compiled to web/drift_worker.js)
- `web/` — scaffold; `manifest.json` + `index.html` branded; `sqlite3.wasm`, `drift_worker.js` assets

### Changed
- `lib/data/database.dart` — uses `openConnection()` from connection module
- `lib/application/app_lock_service.dart` — `kIsWeb` fails open
- `lib/presentation/app_lock_gate.dart` — `kIsWeb` renders child directly
- `lib/presentation/settings/settings_screen.dart` — "Data" section (export/import + confirm), lock toggle hidden on web
- `lib/application/providers.dart` — backupService + backupController providers
- `pubspec.yaml` — added file_saver, file_picker

## Requirement traceability
- FR-1 (web data layer) ✅ connection module + wasm assets, web build clean
- FR-2 (app-lock guard) ✅ kIsWeb in service + gate + settings
- FR-3 (PWA scaffold) ✅ manifest/icons/meta, installable
- FR-4 (export) ✅ BackupService.exportJson + controller + Settings
- FR-5 (import/restore) ✅ importReplace (BR-B1..B6), confirm dialog, tests

## Not verified here (requires a real browser)
- Live OPFS persistence across reloads on iOS Safari — needs manual device test.
  Unit tests exercise the same SQLite backup logic on native, and the web build +
  asset serving are confirmed.
