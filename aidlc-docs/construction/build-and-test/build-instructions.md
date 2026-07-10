# Build Instructions — money-manager (Cycle 4)

## Prerequisites
- **Build Tool**: Flutter 3.38+ / Dart 3.10+
- **Dependencies**: declared in `pubspec.yaml` (drift ^2.28.0 held, `intl` pinned 0.20.2, `path_provider_foundation` override 2.4.1 — do NOT bump, see CLAUDE.md toolchain gotcha)
- **Environment**: no env vars; offline-first app, no backend

## Build Steps

### 1. Install dependencies
```bash
flutter pub get
```

### 2. Regenerate code (only after schema/ARB changes)
```bash
dart run build_runner build --delete-conflicting-outputs   # Drift (database.g.dart)
flutter gen-l10n                                           # AppLocalizations
```

### 3. Build
```bash
flutter build web --no-tree-shake-icons    # web/PWA → build/web
flutter build apk                          # Android (requires Android SDK)
flutter build ios                          # iOS (requires Xcode, macOS)
```
⚠️ `--no-tree-shake-icons` is mandatory for release builds: category/wallet
icons are dynamic `IconData` from DB codePoints (`theme.dart`), which the icon
tree-shaker rejects. Pre-existing since Flutter toolchain update; not Cycle 4.

### 4. Verify build success
- Web: `✓ Built build/web`; artifacts in `build/web/` (static host + `sqlite3.wasm`, `drift_worker.js` already in `web/`)

## Troubleshooting
- **`'dart compile' does not support build hooks`** during build_runner: drift/drift_dev were bumped past ^2.28.0 or the path_provider_foundation override was removed. Revert (see CLAUDE.md).
- **`pub get` fails on intl**: `intl` must stay exactly 0.20.2 (flutter_localizations pin).
- **Icon tree-shaker error at theme.dart:33**: add `--no-tree-shake-icons`.
