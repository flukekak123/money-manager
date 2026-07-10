# Unit Test Execution — money-manager (Cycle 4)

## Run
```bash
flutter test                                    # all suites
flutter test test/installment_calculator_test.dart   # Cycle 4 calculator
flutter test test/installment_repository_test.dart   # Cycle 4 repo/atomicity
flutter test --plain-name "remainder"                 # by name substring
```

## Expected
- **47 tests, 0 failures** (as of Cycle 4)
- Suites: money (10), summary calculator (4), budget calculator (4*), database (3), backup (6), localization (2), installment calculator (10), installment repository (5), widget smoke (3)

## Cycle 4 coverage
- Split math: exact sum for all totals × {3,6,10,12}; remainder to last; BR-I1/BR-I2 rejections
- Dates: same-day monthly, day-31 clamp (Feb 28/29 leap), year crossing
- Repo: atomic createPlan (N rows), deletePlan cascade, BR-I4 edit/delete guards, non-installment rows unaffected
- Backup: v2 round-trip with plan ids preserved; v1 import compatibility

## On failure
1. Read failing expectation in output
2. Fix source (domain/data first — UI depends on them)
3. Rerun single file, then full suite
