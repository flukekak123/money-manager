# Build and Test Summary — Cycle 5 (Subscriptions) · Cycle 4 (Installments)

## Build Status (Cycle 5, current)
- **Build Tool**: Flutter 3.38 / Dart 3.10
- **Static Analysis**: `flutter analyze` — No issues found
- **Web Build**: `flutter build web --no-tree-shake-icons` — ✓ Built build/web
  (flag mandatory — pre-existing dynamic-IconData design, documented in CLAUDE.md)
- **Android/iOS builds**: not executed (Dart layer identical, platform split unchanged)

## Test Execution Summary

### Unit + integration tests (flutter test)
- **Total**: 63
- **Passed**: 63
- **Failed**: 0
- **New in Cycle 5**: 16 (subscription calculator 8, subscription repository 7, backup v2-compat 1) + v3 round-trip extension
- **New in Cycle 4**: 16 (calculator 10, repository 5, backup v1-compat 1)

### Integration scenarios
- Subscription create → charge materialized → month streams/balance: PASS
- Materializer idempotency (double-run = 0 new) + 3-month catch-up: PASS
- Cancel stops charges, keeps history; edit affects future only: PASS
- BR-SB4/BR-I4 locks + BR-SB8 delete guard: PASS
- Backup v3 round-trip + v1/v2 imports: PASS
- Plan → N transactions, cascade delete (Cycle 4): PASS
- Widget smoke (boot, nav, form): PASS

### Performance / contract / security tests
- N/A — offline single-user app, no API surface, no new NFRs (per cycle4-execution-plan.md)

## Overall Status
- **Build**: Success
- **All Tests**: Pass
- **Ready for Operations**: Yes

## Not verified (manual steps recommended)
- Live UI walkthrough (steps in integration-test-instructions.md)
- On-device v1→v2→v3 migration with real user data (additive migrations; low risk)
- Materializer with real device clock across a month boundary (covered by injectable-today tests)
