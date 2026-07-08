# Code Generation Plan — Cycle 2: Web / PWA + Backup

Legend: [ ] pending, [x] done

## Steps
- [ ] 1. `pubspec.yaml`: add deps `file_saver`, `file_picker`; run `flutter pub get`
- [ ] 2. Create `lib/data/connection/connection.dart` (conditional export),
       `connection_native.dart` (NativeDatabase + path_provider),
       `connection_web.dart` (WasmDatabase). Refactor `database.dart`
       `_openConnection()` → `openConnection()` from module.
- [ ] 3. Guard app-lock on web: `kIsWeb` early-return in `AppLockService`,
       direct child render in `AppLockGate`, hide lock toggle in Settings on web.
- [ ] 4. Create `lib/data/backup_service.dart`: `exportJson()` + `importReplace()`
       per functional-design (BR-B1..B5).
- [ ] 5. Create `lib/application/controllers/backup_controller.dart` +
       providers in `providers.dart` (export via file_saver, import via
       file_picker, error surfacing).
- [ ] 6. Settings "Data" section: Export button, Import button + confirm dialog,
       success/error snackbars, stream refresh after import.
- [ ] 7. Scaffold web: `flutter create --platforms=web .`; customize
       `web/manifest.json` (standalone, theme colors, maskable icons),
       `web/index.html` (iOS home-screen meta), placeholder icons.
- [ ] 8. Add Drift web runtime assets to `web/`: `sqlite3.wasm` +
       `drift_worker.js` (download sqlite3.wasm from sqlite3.dart releases;
       generate worker via `dart run drift_dev make-worker`). Fallback documented
       if network blocked.
- [ ] 9. Tests: `test/backup_service_test.dart` — export→import round-trip
       preserves data + ids; malformed/version rejects with DomainException.
- [ ] 10. `flutter analyze` (expect clean) + `flutter test` (expect existing 25 +
       new pass).
- [ ] 11. Verify web build: `flutter build web` (or `flutter run -d chrome` smoke).
- [ ] 12. Write `code-summary.md`; update `aidlc-state.md`.

## Files touched
New: `lib/data/connection/{connection,connection_native,connection_web}.dart`,
`lib/data/backup_service.dart`,
`lib/application/controllers/backup_controller.dart`,
`test/backup_service_test.dart`, `web/*`.
Changed: `pubspec.yaml`, `lib/data/database.dart`,
`lib/application/app_lock_service.dart`, `lib/presentation/app_lock_gate.dart`,
`lib/presentation/settings/settings_screen.dart`,
`lib/application/providers.dart`.

## Traceability
FR-1→steps 2,8 · FR-2→step 3 · FR-3→steps 7,8 · FR-4→steps 4,5,6 ·
FR-5→steps 4,5,6,9
