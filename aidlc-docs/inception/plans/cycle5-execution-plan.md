# Cycle 5 Execution Plan — Subscriptions (recurring monthly expense)

## Detailed Analysis Summary

### Transformation Scope (Brownfield)
- **Transformation Type**: Single-unit feature addition, follows Cycle 4 installment patterns
- **Primary Changes**: `Subscriptions` table + `subscriptionId` column on `Transactions`; on-launch charge materializer; Subscriptions management screen; charge badges
- **Related Components**: domain (entity + due-date calculator + repo interface), data (schema v3 migration, repo impl with materializer, backup v3), application (providers, controller, launch hook), presentation (subscriptions screen, edit sheet, tile badge, Settings entry), l10n

### Change Impact Assessment
- **User-facing changes**: Yes — Subscriptions screen, auto-recorded charges, badges
- **Structural changes**: No — existing layering; one new concern: app-launch materialization hook in composition root
- **Data model changes**: Yes — new table, new FK column, schema v2→v3, backup v2→v3
- **API changes**: None (offline)
- **NFR impact**: Idempotency of materializer (NFR-2) — the one novel risk vs Cycle 4

### Risk Assessment
- **Risk Level**: Medium — auto-writing transactions on launch (must be idempotent, atomic, correct across missed months / clamped dates)
- **Rollback Complexity**: Easy (additive migration, git revert)
- **Testing Complexity**: Moderate — materializer time-based edge cases need injectable "today"

## Workflow Visualization

### Text
```
INCEPTION:    Workspace Detection (done) -> Requirements Analysis (done)
              -> Workflow Planning (this doc)
              User Stories, Application Design, Units Generation: SKIP
CONSTRUCTION: Functional Design (EXECUTE) -> Code Generation (EXECUTE)
              -> Build and Test (EXECUTE)
              NFR Requirements/Design, Infrastructure Design: SKIP
```

## Phases to Execute

### INCEPTION PHASE
- [x] Workspace Detection (COMPLETED)
- [x] Requirements Analysis (COMPLETED — subscription-requirements.md)
- [x] User Stories - SKIP (single persona; decisions table covers acceptance)
- [x] Workflow Planning (this document)
- [ ] Application Design - SKIP (new classes slot into existing layers, Cycle 4 precedent)
- [ ] Units Generation - SKIP (single unit `money-manager`)

### CONSTRUCTION PHASE (unit: money-manager)
- [ ] Functional Design - EXECUTE
  - **Rationale**: materializer algorithm (idempotency, catch-up, clamp, no-backfill anchor), lifecycle rules (edit-future-only, cancel, delete guard), schema + backup v3
- [ ] NFR Requirements - SKIP (stack fixed; idempotency handled in functional design)
- [ ] NFR Design - SKIP
- [ ] Infrastructure Design - SKIP (offline)
- [ ] Code Generation - EXECUTE (ALWAYS)
- [ ] Build and Test - EXECUTE (ALWAYS)

## Success Criteria
- **Primary Goal**: user subscribes once; app records the expense every month automatically on open
- **Key Deliverables**: schema v3 (+ migration), `Subscription` entity + due-date logic, idempotent materializer (launch + create/edit triggers), charge lock guard, Subscriptions screen + Settings entry + badges, backup v3 (imports v1/v2), EN+TH strings, tests (due-date math with injectable clock, idempotency double-run, catch-up, edit-future-only, backup round-trip)
- **Quality Gates**: analyze clean; all tests pass; web build OK (`--no-tree-shake-icons`)
