# Phase 3: Smart Cancellation Logic - Planning Summary

**Planned:** 2026-02-28
**Planner:** gsd-planner agent
**Phase Requirements:** NOTIF-11, NOTIF-12, NOTIF-13, NOTIF-14

## Planning Context

### Critical Architectural Decision

During research, discovered that Phase 2's repeating notifications (`repeats: true`) with static identifiers create an architectural conflict with Phase 3's per-day cancellation requirement. When iOS cancels a repeating notification by identifier, it cancels ALL future recurrences, not just today's instance.

**User Decision:** Selected Option A - Redesign Phase 2 to use date-specific notification identifiers instead of repeating notifications.

**Implication:** Phase 3 planning includes Wave 1 to modify Phase 2 code before implementing cancellation logic.

## Plans Overview

| Plan | Wave | Goal | Files Modified | Autonomous |
|------|------|------|----------------|------------|
| 03-01 | 1 | Redesign notification scheduling with date-specific identifiers | 1 | ✓ |
| 03-02 | 2 | Implement smart cancellation logic | 4 | ✓ |
| 03-03 | 3 | Add comprehensive tests | 3 | ✓ |

**Total files modified:** 8
**Autonomous execution:** Yes (all plans)
**Estimated duration:** ~15 minutes (based on Phase 1-2 velocity)

## Wave Dependency Graph

```
Wave 1: 03-01 (Foundation - Date-specific scheduling)
         ↓
Wave 2: 03-02 (Implementation - Cancellation logic)
         ↓
Wave 3: 03-03 (Verification - Tests)
```

**Parallelization:** None (strict sequential dependencies)
**Rationale:** 03-02 needs date-specific identifiers from 03-01, 03-03 tests both implementations

## Requirements Mapping

| Requirement | Description | Primary Plan | Verification |
|-------------|-------------|--------------|--------------|
| NOTIF-11 | Cancel pending notifications when logging data | 03-02 | Unit tests + manual device test |
| NOTIF-12 | Any data type triggers cancellation | 03-02 | Unit tests (persistChanges flow) |
| NOTIF-13 | Day boundary matches calendar logic | 03-02 | Unit tests (Calendar.current.startOfDay) |
| NOTIF-14 | Cancellation survives force-quit | 03-02 | Manual device test (Phase 4) |

**Coverage:** All 4 phase requirements mapped ✓

## Architectural Approach

### Date-Specific Identifiers (03-01)

**Problem:** Repeating notifications can't be canceled per-day (canceling one cancels all future)

**Solution:**
- Schedule 30 individual non-repeating notifications
- Use date-specific identifiers: "lunch-reminder-2026-02-28", "evening-reminder-2026-02-28"
- Each day's notifications independently cancellable
- 30-day window ensures notifications fire without daily app launches

**Impact:**
- Modifies Phase 2's `ScheduleNotificationsUseCase`
- Changes from 2 repeating notifications to 60 non-repeating notifications
- Maintains backward compatibility (existing tests updated in 03-03)

### Smart Cancellation Logic (03-02)

**Trigger Point:** MainViewModel's `persistChanges()` method
- Single integration point for all data types (meal, workout, water, mood)
- Called after successful save (failed saves don't cancel)
- Fire-and-forget async execution (doesn't block save flow)

**Cancellation Scope:**
- Targets only today's date-specific identifiers
- Cancels both pending and delivered notifications
- Tomorrow's notifications remain scheduled

**Persistence:**
- Relies on iOS UNUserNotificationCenter guarantees
- removePendingNotificationRequests() persists immediately to disk
- Survives force-quit automatically (no custom state tracking needed)

### Testing Strategy (03-03)

**Unit Tests:**
- Mock-based verification of business logic
- Verify date-specific identifier patterns match
- Verify today-only cancellation (2 identifiers, not 60)
- Fast execution, no iOS framework dependencies

**Manual Tests (deferred to Phase 4):**
- Force-quit survival (NOTIF-14)
- Actual notification firing and cancellation
- iOS Settings verification of pending notifications

## Key Technical Decisions

### Decision 1: Fire-and-Forget Cancellation
**Chosen:** Task { try? await useCase.execute() }
**Alternatives:** await useCase.execute(), background task registration
**Rationale:** Provides instant save completion UX while ensuring cancellation completes. iOS guarantees persistence without await. Errors swallowed gracefully (try?).

### Decision 2: Date Formatting Pattern
**Chosen:** "yyyy-MM-dd" (e.g., "2026-02-28")
**Alternatives:** Unix timestamps, "YYYYMMDD", ISO 8601
**Rationale:** Human-readable for debugging, sortable, unambiguous, matches common date patterns.

### Decision 3: 30-Day Scheduling Window
**Chosen:** Schedule 30 days upfront on first launch
**Alternatives:** Weekly scheduling, on-demand scheduling
**Rationale:** Balances iOS notification limits (~64 total) with ensuring notifications fire without daily app opens. Matches common user patterns (open app ~monthly).

### Decision 4: Day Boundary Logic
**Chosen:** Calendar.current.startOfDay(for: Date())
**Alternatives:** Date() truncated, user-configured day start
**Rationale:** Matches existing codebase pattern (MainViewModel.currentDayData), respects time zones and DST, consistent with iOS Calendar semantics.

### Decision 5: Complete Notification Cleanup
**Chosen:** Cancel pending AND remove delivered notifications
**Alternatives:** Cancel pending only
**Rationale:** Prevents stale notifications in Notification Center after user logs data. Cleaner UX.

## Risk Assessment

### Risk 1: Phase 2 Code Modification Introduces Regressions
**Likelihood:** LOW
**Impact:** MEDIUM
**Mitigation:** 03-03 updates existing tests to verify new behavior. Existing Phase 2 success criteria still apply (notifications fire at correct times, proper authorization handling).

### Risk 2: Date Formatting Inconsistency Between Scheduling and Cancellation
**Likelihood:** LOW
**Impact:** HIGH (cancellation wouldn't work)
**Mitigation:** Both Use Cases use identical formatDateForIdentifier() helper. Tests verify identifier patterns match.

### Risk 3: 30-Day Window Insufficient for Infrequent Users
**Likelihood:** LOW
**Impact:** LOW (notifications stop firing after 30 days)
**Mitigation:** Phase 4 can add rescheduling logic if analytics show users open app <monthly. Current 30-day window matches typical health tracking app usage.

### Risk 4: iOS 64-Notification Limit
**Likelihood:** NONE
**Impact:** NONE
**Mitigation:** App schedules 60 notifications (30 days × 2), well under iOS limit of 64 pending notifications.

## Open Questions (Resolved)

### Question: Should Phase 2 be redesigned or should Phase 3 reschedule after canceling?
**Resolution:** User selected Option A (redesign Phase 2). Cleaner architecture, no complex rescheduling logic, preserves future notifications automatically.

### Question: How to handle data deletion (if user deletes all logged items)?
**Resolution:** Deferred to Phase 4. Current approach: once user engages (even if they delete entries), notifications remain canceled for the day. Prevents notification fatigue from delete/re-add cycles.

### Question: Should badge count be explicitly cleared?
**Resolution:** Deferred to Phase 4. Research indicates removeDeliveredNotifications() may not clear badge automatically. If UAT shows badge remains, Phase 4 can add explicit setBadgeCount(0) call.

## Success Criteria Traceability

Phase goal: "Notifications cancel intelligently when user logs any data, preventing notification fatigue"

### Must-Have 1: Today-only cancellation
**Verification:** CancelNotificationsUseCase uses today's date-specific identifiers only
**Test:** CancelNotificationsUseCaseTests.execute_cancelsOnlyTwoNotifications

### Must-Have 2: Future notifications preserved
**Verification:** Date-specific identifiers ensure tomorrow's notifications unaffected
**Test:** Manual verification - log data, check pending notifications count drops by 2 (not 60)

### Must-Have 3: All data types trigger cancellation
**Verification:** Single persistChanges() integration point handles all data mutations
**Test:** Code inspection - all add/update/delete methods call persistChanges()

### Must-Have 4: Non-blocking execution
**Verification:** Fire-and-forget Task execution, no await in save flow
**Test:** Code inspection - persistChanges() remains synchronous

### Must-Have 5: Force-quit survival
**Verification:** iOS UNUserNotificationCenter persistence guarantees
**Test:** Manual device test (Phase 4) - log data, force-quit, verify cancellation persists

## Lessons from Previous Phases

### Applied from Phase 1-2:
1. **Protocol-first design:** NotificationServiceProtocol extended before implementation
2. **Clean Architecture boundaries:** Use Cases coordinate, Services wrap frameworks
3. **Mock-based testing:** MockNotificationService tracks all operations for assertions
4. **Graceful error handling:** try? for non-critical operations (logging, notifications)
5. **Debug-friendly timing:** Preserve testable notification times in debug builds

### Innovations in Phase 3:
1. **Retroactive architecture fix:** Wave 1 modifies Phase 2 before building Phase 3
2. **Date-specific identifiers:** Enables per-day cancellation without complex state tracking
3. **Fire-and-forget pattern:** Background Task without blocking user-facing operations
4. **30-day scheduling window:** Balance between iOS limits and user engagement patterns

## Downstream Dependencies

### Phase 4 (Testing and Refinement) Can Build On:
- Date-specific identifier pattern for enhanced logging/debugging
- CancelNotificationsUseCase as tested, reusable component
- 30-day scheduling window as tunable parameter for optimization
- Fire-and-forget pattern for other background operations (analytics, etc.)

### Potential v2 Enhancements:
- Smart rescheduling: if no data logged after N days, re-enable notifications
- Configurable scheduling window: allow users to extend beyond 30 days
- Notification grouping: iOS notification stacks for better Notification Center UX
- Badge count coordination: sync badge with logged data status

## Execution Notes

### For /gsd:execute-phase:
1. Execute plans in wave order (03-01 → 03-02 → 03-03)
2. Run tests after each plan: `swift test --filter <UseCaseTests>`
3. Verify Phase 2 still works after 03-01 (existing success criteria apply)
4. Manual verification: check Settings > Notifications for pending count (should be 60 after 03-01)

### For UAT (Phase 4):
1. Verify 60 notifications scheduled on first launch
2. Log any data type, verify pending count drops to 58
3. Force-quit app immediately, relaunch, verify count still 58 (NOTIF-14)
4. Next day, verify new notifications fire (tomorrow's identifiers)

### For Documentation:
1. Update ROADMAP.md Phase 3 plans list with 03-01, 03-02, 03-03
2. Update STATE.md with Phase 3 completion after execution
3. Document identifier pattern in NotificationService for future maintainers

---

*Planning completed: 2026-02-28*
*Agent: gsd-planner*
*Mode: standard*
*Architectural decision: Option A (date-specific identifiers)*
