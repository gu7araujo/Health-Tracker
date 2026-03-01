# Project Retrospective

*A living document updated after each milestone. Lessons feed forward into future planning.*

## Milestone: v1.0 — iOS Notifications MVP

**Shipped:** 2026-03-01
**Phases:** 4 | **Plans:** 12 | **Timeline:** 2 days execution (2026-02-28 → 2026-03-01)

### What Was Built
- Clean Architecture notification foundation with protocol-based abstraction in Domain layer
- Daily notifications at 1 PM and 8 PM with Portuguese-BR time-specific messages using calendar triggers
- Smart cancellation logic with date-specific identifiers (today-only suppression)
- Comprehensive test suite: 24 unit tests with mock service + 10 UAT device tests

### What Worked
- **Date-specific identifier breakthrough**: Discovered repeating notifications couldn't support per-day cancellation; pivoted to 30-day rolling schedule with unique identifiers
- **Protocol abstraction**: Zero UserNotifications imports in Domain/Presentation layers enabled clean testing
- **Milestone audit workflow**: Caught Portuguese-BR title gap before final UAT
- **Wave-based planning**: Each phase decomposed into right-sized plans (2-4 tasks) for autonomous execution
- **Verification-first approach**: Truth statements in PLAN.md drove implementation quality

### What Was Inefficient
- **Phase 3 architectural discovery**: Research phase uncovered that Phase 2's approach (repeating notifications) was incompatible with Phase 3's requirements, requiring Wave 1 to redesign Phase 2 before implementing cancellation
- **Minor documentation drift**: UAT expected 13 tests but actual count was 12 (not a blocker, but signal to verify counts)

### Patterns Established
- **Date-specific notification identifiers**: Pattern `"{type}-reminder-YYYY-MM-DD"` enables per-day operations while maintaining daily recurrence
- **Fire-and-forget cancellation**: MainViewModel's `persistChanges()` triggers cancellation in background Task without blocking UI
- **Mock tracking properties**: `scheduledNotifications`, `canceledIdentifiers`, `deliveredIdentifiers` arrays in MockNotificationService enable comprehensive test verification
- **Calendar-based triggers**: Using `UNCalendarNotificationTrigger` with `DateComponents` (no timeZone specified) ensures iOS handles time zone changes correctly

### Key Lessons
1. **Research phase value**: Investing time in research (Phase 3's discovery) prevented shipping broken architecture; redesign cost was minimal compared to fixing post-release
2. **Audit as requirement gate**: Milestone audit caught localization gap that UAT would have failed
3. **Clean Architecture pays off**: Protocol abstraction enabled 24 unit tests without device; caught bugs before UAT
4. **Portuguese-BR from start**: Localizing upfront simpler than retrofitting; dynamic `CFBundleDisplayName` lookup pattern works well

### Cost Observations
- Model mix: ~80% Opus 4.6 (planning/research), ~20% Sonnet (execution)
- Sessions: ~8 across 2 days
- Notable: Milestone audit workflow prevented UAT failures, saved rework

---

## Cross-Milestone Trends

### Process Evolution

| Milestone | Timeline | Phases | Key Change |
|-----------|----------|--------|------------|
| v1.0      | 2 days   | 4      | First milestone, established GSD workflow baseline |

### Cumulative Quality

| Milestone | Tests | Coverage | Verification Score |
|-----------|-------|----------|-------------------|
| v1.0      | 24 unit + 10 UAT | Use Cases: 100% | 23/23 requirements (100%) |

### Top Lessons (Verified Across Milestones)

1. Research phase prevents architectural dead ends (validated in Phase 3 pivot)
2. Milestone audit catches integration gaps before UAT (validated by Portuguese-BR title fix)
