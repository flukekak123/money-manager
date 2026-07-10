# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

Offline-first personal finance app (Flutter, Material 3). Everything is stored
locally in SQLite via Drift — there is no backend. Flutter 3.38+ / Dart 3.10+,
Android/iOS targets.

## Commands

```bash
flutter pub get                 # install deps
dart run build_runner build     # regenerate Drift code (database.g.dart) after schema change
dart run build_runner build --delete-conflicting-outputs   # if codegen complains about stale outputs
flutter run                     # launch on device/emulator
flutter run -d chrome           # launch on web (PWA)
flutter analyze                 # static analysis (lints from flutter_lints)
flutter test                    # all unit + widget tests
flutter test test/money_test.dart          # single test file
flutter test --plain-name "budget warns"   # single test by name substring
flutter build web --no-tree-shake-icons    # production web build → build/web (static host)
```

`--no-tree-shake-icons` is required: category/wallet icons are stored as
codePoints in the DB and rebuilt via `iconFromCodePoint` (`theme.dart`), a
non-constant `IconData` the icon tree-shaker rejects.

`database.g.dart` is committed; rerun `build_runner` whenever a `Table` in
`lib/data/database.dart` changes and bump `schemaVersion` + add a migration.

### Toolchain gotcha (do not "fix" without reading)
`pubspec.yaml` pins `dependency_overrides: path_provider_foundation: 2.4.1` and
holds `drift`/`drift_dev` at `^2.28.0`. Newer versions use native-asset build
hooks (objective_c) that break `build_runner` codegen on Dart 3.10
(`'dart compile' does not support build hooks`). Removing the override breaks
code generation. Only bump once `build_runner` supports `dart build`.

## Architecture

Layered, dependency flows inward (presentation → application → domain; data
implements domain interfaces). `lib/core` is shared leaf utilities.

- **`lib/domain`** — pure Dart, no Flutter or DB imports. Entities/value objects
  (`entities.dart`), repository *interfaces* (`repositories.dart`), and stateless
  calculators (`services/`). This is the unit-tested core; keep it pure.
- **`lib/data`** — Drift database + `.g.dart`, repository *implementations*
  (`repositories/`), `seed.dart` (first-run defaults), `settings_repository.dart`
  (shared_preferences). Impls map Drift rows ↔ domain entities and alias the
  domain import `as d` to avoid clashing with generated Drift row classes.
- **`lib/application`** — Riverpod. `providers.dart` is the **composition root**:
  it wires DB → repositories → stream providers → derived read-model providers →
  controllers. `controllers/` validate input and persist. `settings_notifier.dart`,
  `app_lock_service.dart` here too.
- **`lib/presentation`** — Material 3 `ConsumerWidget` screens/widgets, one
  folder per feature (home, transactions, budgets, reports, wallets, categories,
  settings) plus shared `widgets/` and `theme.dart`.

### Provider layering (in `providers.dart`)
1. Infra `Provider`s: `databaseProvider`, `*RepositoryProvider`.
2. Reactive `StreamProvider`s watch repo streams (`walletsProvider`,
   `monthTransactionsProvider`, etc.) — UI rebuilds automatically on DB change.
3. **Derived pure providers** (`monthSummaryProvider`, `budgetProgressProvider`,
   `spendingByCategoryProvider`, `trendProvider`) feed watched transactions into
   `domain/services` calculators. Put new aggregation logic in a calculator, not
   in a widget.
4. `*ControllerProvider`s expose write/validate operations.

`selectedMonthProvider` (a `YYYY-MM` string via `MonthKey`) is the app-wide
month selector; month-scoped providers are `.family` keyed on it.

## Web / PWA (multi-platform)

Runs on mobile **and** web (installable PWA). Platform split is isolated:

- **DB connection** — `lib/data/database.dart` calls `openConnection()` from
  `lib/data/connection/`, a conditional export:
  `connection_native.dart` (NativeDatabase + `path_provider`, uses `dart:io`) vs
  `connection_web.dart` (`WasmDatabase`, OPFS/IndexedDB). The
  `if (dart.library.js_interop)` guard keeps `dart:io` out of web builds — don't
  import `dart:io`/`path_provider` anywhere else in `lib/`.
- **Web runtime assets** live in `web/`: `sqlite3.wasm` (from sqlite3.dart
  releases, match the resolved `sqlite3` package version) and `drift_worker.js`.
  Regenerate the worker after a drift upgrade:
  `dart compile js -O2 tool/drift_worker.dart -o web/drift_worker.js`.
- **App-lock** (`local_auth`) has no web support: `AppLockService`, `AppLockGate`,
  and the Settings toggle all guard on `kIsWeb` (web = unlocked). Guard any future
  native-only plugin the same way.

## Backup / restore

`lib/data/backup_service.dart` — schema-versioned JSON (`version: 1`) export +
**atomic replace** import. Import validates shape/version, then inside one
`db.transaction` wipes (children→parents FK order) and re-inserts preserving ids;
any error rolls back (`DomainException` surfaced). Bump `schemaVersion` + handle
older versions if the JSON shape changes. UI is the Settings "Data" section
(`BackupController` uses `file_saver`/`file_picker`, works web + mobile). This is
the mitigation for browser storage eviction — keep it working on web.

## Localization (i18n)

English + Thai via Flutter `gen-l10n`. Strings live in `lib/l10n/app_en.arb`
(template) and `app_th.arb`; generated code lands in `lib/l10n/gen/` (config in
`l10n.yaml`, `generate: true` in pubspec). Access with
`AppLocalizations.of(context).<key>` — it is non-null (`nullable-getter: false`).

- **Add a string**: add the key to *both* ARB files (with `@key` placeholder
  metadata if it interpolates), run `flutter gen-l10n`, then use it. `flutter
  build`/`run` also regenerates.
- **Add a language**: create `app_<code>.arb`, and it auto-joins
  `AppLocalizations.supportedLocales`; add it to the Settings `_languages` map.
- Language is a setting (`AppSettings.languageCode`, persisted) driving
  `MaterialApp.locale`; picker is in Settings. Enum-ish UI labels (theme mode,
  wallet type) map through local `switch` helpers, not `.name`.
- **Seed DB data is NOT localized** — category/wallet names are user data.
- ⚠️ `intl` is pinned to exactly `0.20.2` because `flutter_localizations` pins
  it; don't bump to `^0.20.3` or `pub get` breaks.

## Conventions & invariants

- **Money is always integer minor units** (cents), never `double`. Format/parse
  only through `core/money.dart` `MoneyFormatter` (currency-aware via `intl`).
  `TransactionEntry.signedMinor` gives +income / −expense.
- **Business-rule violations throw `DomainException`** (`domain/entities.dart`);
  the UI catches it to show inline errors. Validation lives in controllers
  (`TransactionController._validate`) and some repo methods
  (e.g. wallet archive keeps ≥1 active wallet; wallet delete blocked when
  transactions reference it). Referenced as `BR-*` codes in comments.
- Enums (`TransactionKind`, `WalletType`) are persisted by **`.index`** as an int
  column; map back with `Enum.values[i]`. Order of enum values is a schema
  contract — don't reorder.
- Budget thresholds are fixed: warn ≥80%, over ≥100% (`BudgetProgress.status`).
- **Subscriptions** (schema v3): recurring monthly expenses (`Subscriptions`
  table + `subscriptionId` on `Transactions`). No background scheduler —
  charges are **materialized on app launch** (`subscriptionMaterializeOnLaunchProvider`
  watched in `app.dart`) and after create/edit: `dueDatesBetween`
  (`domain/services/subscription_calculator.dart`) yields due dates from the
  `lastChargedDate` marker (or `createdAt` — no backfill) through today; the
  repo inserts charges and advances the marker in one DB transaction, so a
  double run is a no-op. Charges are locked like installments (BR-SB4); edits
  affect future charges only; cancel keeps history; hard delete only with zero
  charges. Backup JSON `version: 3` (imports v1/v2).
- **Installments** (schema v2): an expense can be split over 3/6/10/12 months —
  one `InstallmentPlans` row + N future-dated expense transactions generated
  upfront (`installmentPlanId`/`installmentNo` on `Transactions`). Split math
  lives in `domain/services/installment_calculator.dart` (even split, remainder
  to LAST installment, month-day clamped). Linked transactions are never edited
  or deleted individually (BR-I4 — repo update/delete throws); manage via the
  plan (`InstallmentRepository.createPlan/deletePlan`, both atomic). Plans are
  immutable: change = delete + recreate. Backup JSON is `version: 2` (imports
  v1 too).
- Categories/wallets are **archived, not hard-deleted**, when in use; watch
  queries exclude archived unless `includeArchived: true`.
- Tests construct the DB with `AppDatabase.forTesting(NativeDatabase.memory())`;
  the `onCreate` migration runs `SeedData.populate` (1 wallet, 9 categories).

## AI-DLC

This repo was built via the AI-DLC workflow; audit trail and design docs live in
`aidlc-docs/` (documentation only — never put application code there). Per global
instructions, invoke the `aidlc` skill before non-trivial feature work.
