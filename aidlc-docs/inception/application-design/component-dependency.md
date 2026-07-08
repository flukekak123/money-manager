# Component Dependencies — Money Manager App

## Dependency Rule
Presentation → Domain ← Data. Domain depends on nothing (pure). Data implements Domain interfaces. Presentation depends on Domain abstractions, wired to Data impls via Riverpod providers.

## Dependency Matrix
| Component | Depends On |
|---|---|
| Screens / Widgets | Riverpod providers, Domain entities, MoneyFormatter |
| Riverpod providers | Repository interfaces, Domain services, AppDatabase (composition root) |
| Controllers/Notifiers | Repository interfaces, Domain services |
| Domain services (Money/Budget/Summary) | Domain entities only |
| Repository impls | DAOs, Domain entities/interfaces |
| DAOs | AppDatabase (Drift) |
| AppDatabase | drift, sqlite3 |
| AppLockService | local_auth |
| SettingsRepositoryImpl | shared_preferences |

## Data Flow (add transaction)

```text
User taps Save on TransactionEditScreen
        |
        v
TransactionController.add()  --validate + MoneyFormatter.parse-->
        |
        v
TransactionRepository.add()  -->  TransactionDao.insert()  -->  Drift/SQLite
        |
        v
Drift watch stream re-emits
        |
        v
monthTransactionsProvider updates
        |
        +--> monthSummaryProvider (SummaryCalculator) --> HomeScreen refresh
        +--> budgetProgressProvider (BudgetCalculator) --> BudgetsScreen refresh
```

## Communication Patterns
- Reactive streams (Drift `watch`) for all lists → UI stays live.
- Pure calculators for derived values (no side effects, unit-tested).
- Composition root: providers construct `AppDatabase` once, inject into repos.

## Data Flow (app launch with lock)

```text
main() -> AppLockGate
   |-- lock disabled --> MainShell
   |-- lock enabled  --> AppLockService.authenticate()
                              |-- success --> MainShell
                              |-- fail    --> retry / stay locked
```
