# Phase 2: Basic Notification Scheduling - Planning Summary

**Phase Goal:** Users receive daily notifications at 1 PM and 8 PM with time-specific messages

**Created:** 2026-02-28
**Updated:** 2026-02-28 (gap closure)
**Plans:** 4 (3 initial + 1 gap closure)
**Total Requirements:** 8 (NOTIF-05, NOTIF-06, NOTIF-07, NOTIF-08, NOTIF-09, NOTIF-10, NOTIF-18, NOTIF-23)

## Plan Breakdown

### Wave 1: Protocol and Service Extension
**Plan:** 02-01-PLAN.md
**Focus:** Extend notification service with scheduling capabilities
**Files:** 3 modified
- HealthTracker/Domain/Protocols/NotificationServiceProtocol.swift
- HealthTracker/Data/Services/NotificationService.swift
- HealthTrackerTests/Mocks/MockNotificationService.swift

**Key outputs:**
- `scheduleNotification(identifier:title:body:dateComponents:repeats:)` protocol method
- `cancelAllNotifications()` protocol method
- Implementation using UNCalendarNotificationTrigger with DateComponents
- Mock service extended with tracking properties for testing

**Requirements covered:** NOTIF-05, NOTIF-06, NOTIF-09, NOTIF-10 (foundation)

**Depends on:** Nothing (Wave 1)

### Wave 2: Use Case and Integration
**Plan:** 02-02-PLAN.md
**Focus:** Create scheduling Use Case and integrate with first-launch flow
**Files:** 2 modified
- HealthTracker/Domain/UseCases/ScheduleNotificationsUseCase.swift (new)
- HealthTracker/Data/Services/NotificationPermissionManager.swift

**Key outputs:**
- ScheduleNotificationsUseCase coordinates scheduling of both notifications
- Authorization check before scheduling (graceful degradation)
- Portuguese-BR messages: "Registre o que você comeu hoje" (1 PM), "Registre suas refeições e atividades" (8 PM)
- Debug configuration: 2-3 minutes from now via #if DEBUG
- Release configuration: 1 PM (hour: 13) and 8 PM (hour: 20)
- Integration: Schedule after permission granted on first launch

**Requirements covered:** NOTIF-05, NOTIF-06, NOTIF-07, NOTIF-08, NOTIF-18, NOTIF-23

**Depends on:** 02-01 (needs scheduling methods)

### Wave 3: Testing and Verification
**Plan:** 02-03-PLAN.md
**Focus:** Comprehensive unit test coverage for scheduling Use Case
**Files:** 1 created
- HealthTrackerTests/Domain/UseCases/ScheduleNotificationsUseCaseTests.swift

**Key outputs:**
- 6 test cases covering all scheduling behaviors
- Tests verify authorization check and graceful degradation
- Tests verify both notifications scheduled with correct identifiers
- Tests verify Portuguese-BR messages
- Tests verify daily recurrence (repeats: true)
- Tests verify cancellation before scheduling
- Tests verify calendar-based DateComponents

**Requirements covered:** All Phase 2 requirements verified (NOTIF-05 through NOTIF-23)

**Depends on:** 02-01, 02-02 (needs Use Case to test)

### Wave 4: Gap Closure - Fix Notification Title Localization
**Plan:** 02-04-PLAN.md
**Focus:** Replace English notification title with Portuguese-BR app name
**Files:** 2 modified
- HealthTracker/Domain/UseCases/ScheduleNotificationsUseCase.swift
- HealthTrackerTests/Domain/UseCases/ScheduleNotificationsUseCaseTests.swift

**Key outputs:**
- Notification title changed from "HealthTracker" to "Monitor de Hábitos Saudáveis"
- Consistent Portuguese-BR localization across all notification content
- Test updated to verify Portuguese-BR title

**Gap addressed:** gap-1 (Inconsistent Localization - English Title)
**Requirements covered:** NOTIF-07, NOTIF-08 (fully localized notifications)

**Depends on:** None (standalone gap closure)

## Dependency Graph

```
Wave 1: 02-01 (Protocol & Service Extension)
          ↓
Wave 2: 02-02 (Use Case & Integration)
          ↓
Wave 3: 02-03 (Testing)

Wave 4: 02-04 (Gap Closure - Localization Fix) — Independent
```

**Critical path:** Waves 1-3 sequential, Wave 4 independent
**Parallelization:** Wave 4 can execute independently after verification
**Estimated duration:** 18-22 minutes total (5-7 min per plan × 3 + 3 min for gap closure)

## User Decision Integration

From 02-CONTEXT.md:

**Locked decisions honored:**
- Portuguese-BR notification messages (exact strings from context)
- 1 PM and 8 PM notification times (hardcoded in release builds)
- Portuguese-BR app name as notification title (updated in Wave 4 gap closure)
- Default system behavior (sound + badge + banner)

**Claude's discretion applied:**
- Scheduling approach: UNCalendarNotificationTrigger with repeats: true
- Debug configuration: #if DEBUG conditional compilation for testable times
- Integration point: Schedule after permission granted in NotificationPermissionManager
- Identifier naming: "lunch-reminder" and "evening-reminder"
- Error handling: Graceful degradation (log errors, continue execution)
- Duplicate prevention: Cancel all before scheduling

## Architecture Decisions

**Clean Architecture maintained:**
- Use Case in Domain layer depends on protocol only
- NotificationService in Data layer implements iOS-specific logic
- No UserNotifications imports in Domain layer

**Testing strategy:**
- Unit tests use MockNotificationService for fast, reliable verification
- Manual device testing deferred to Phase 4 (actual notification delivery)
- Debug configuration enables quick manual verification during development

**iOS integration:**
- UNCalendarNotificationTrigger for time zone and DST handling
- DateComponents without explicit timeZone (uses device local time)
- repeats: true for daily recurrence (no manual rescheduling)

## Requirements Traceability

| Requirement | Wave 1 | Wave 2 | Wave 3 | Wave 4 | Notes |
|-------------|--------|--------|--------|--------|-------|
| NOTIF-05 | Foundation | Implementation | Verified | - | 1 PM notification scheduling |
| NOTIF-06 | Foundation | Implementation | Verified | - | 8 PM notification scheduling |
| NOTIF-07 | - | Implementation | Verified | Localization fix | Lunch message in Portuguese-BR (title fixed in Wave 4) |
| NOTIF-08 | - | Implementation | Verified | Localization fix | Evening message in Portuguese-BR (title fixed in Wave 4) |
| NOTIF-09 | Foundation | Implementation | Verified | - | Calendar triggers respect time zones |
| NOTIF-10 | Foundation | Implementation | Verified | - | Daily recurrence with repeats: true |
| NOTIF-18 | - | Implementation | Verified | - | Use Case coordinates operations |
| NOTIF-23 | - | Implementation | Verified | - | Debug config for testable times |

**Coverage:** 8/8 requirements (100%)
**Foundation laid:** Wave 1 provides technical capability
**Implementation:** Wave 2 delivers user-facing behavior
**Verification:** Wave 3 confirms correctness
**Gap closure:** Wave 4 completes Portuguese-BR localization

## Success Metrics

**Must-haves for phase completion:**
1. Users receive notification at 1 PM with "Registre o que você comeu hoje"
2. Users receive notification at 8 PM with "Registre suas refeições e atividades"
3. Notifications recur daily automatically
4. Notifications respect time zone changes and DST transitions
5. Debug builds allow quick testing (2-3 minute delays)

**Automated verification:**
- All unit tests pass (ScheduleNotificationsUseCaseTests)
- Project compiles without errors
- Domain layer has zero UserNotifications imports

**Manual verification:**
- Debug build: Notifications fire 2-3 minutes after first launch
- Release build: Would need to wait until 1 PM or 8 PM (deferred to Phase 4 UAT)

## Handoff to Phase 3

**What Phase 3 can assume:**
- Notifications scheduled and recurring daily
- Authorization handled gracefully
- Fully localized Portuguese-BR notifications (title and messages)
- Clean Architecture maintained

**What Phase 3 needs to add:**
- Smart cancellation when user logs data
- Integration with data entry flows (meal, workout, water, mood)
- Day boundary logic for "both notifications today"

**Interface for Phase 3:**
- `NotificationService.cancelAllNotifications()` already available
- Can be called from data logging operations
- Use Case pattern established for coordination

---

**Planning completed:** 2026-02-28
**Gap closure plan added:** 2026-02-28
**Ready for execution:** Yes (Wave 4 gap closure)
**Blocker status:** None

## Gap Closure Context

**Gap addressed:** gap-1 (Inconsistent Localization - English Title)
**Severity:** Medium
**Found by:** User testing during Phase 2 verification
**Resolution:** Wave 4 (02-04-PLAN.md) replaces English "HealthTracker" with Portuguese-BR "Monitor de Hábitos Saudáveis"

**Impact of gap:**
- Inconsistent user experience (messages in Portuguese, title in English)
- Breaks localization expectations for Portuguese-BR users
- Does not match app's CFBundleDisplayName

**Resolution approach:**
- Simple string replacement in 2 locations
- Test update to verify Portuguese-BR title
- Low risk, no architectural changes
- Estimated time: 3 minutes
