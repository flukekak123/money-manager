# Money Manager

Offline-first personal finance app built with Flutter. Log income and
expenses, organize with categories, set monthly budgets, and view reports —
all stored locally on device.

## Features
- Income / expense transaction logging (add, edit, delete)
- Categories (9 seeded defaults + custom) split by income/expense
- Multiple wallets with per-wallet balance
- Monthly budgets per category with progress + thresholds (warn ≥80%, over ≥100%)
- Reports: spending-by-category pie, income-vs-expense trend bars, period summary
- App lock (biometric / device credential) via `local_auth`
- Currency + theme (system/light/dark) settings
- Money stored as integer minor units — no floating-point errors

## Architecture
Layered, feature-first:
- `lib/domain` — pure Dart entities, business rules, calculators (unit-tested)
- `lib/data` — Drift (SQLite) database, DAOs, repository implementations, seed
- `lib/application` — Riverpod providers (composition root), controllers, settings
- `lib/presentation` — Flutter Material 3 screens and widgets

State: Riverpod. DB: Drift/SQLite. Charts: fl_chart.

## Requirements
- Flutter 3.38+ / Dart 3.10+
- Android or iOS target

## Setup
```bash
flutter pub get
# Drift code generation (already committed; rerun if schema changes):
dart run build_runner build
```

> Note: `path_provider_foundation` is pinned via `dependency_overrides` to a
> version without native-asset build hooks, because newer versions break
> `build_runner` code generation on Dart 3.10. Remove the override once
> `build_runner` supports `dart build`.

## Run
```bash
flutter run
```

## Test
```bash
flutter test          # unit + widget tests
flutter analyze       # static analysis
```

## Project Layout
```
lib/
  core/         money formatting, date helpers
  domain/       entities, repositories (interfaces), services
  data/         drift database, repository impls, seed, settings
  application/  riverpod providers, controllers, app lock
  presentation/ screens + widgets (home, transactions, budgets, reports,
                wallets, categories, settings)
```
