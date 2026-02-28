---
phase: 02-basic-notification-scheduling
plan: 02
subsystem: notification-scheduling
tags: [use-case, notification-scheduling, first-launch-integration, clean-architecture]
dependency_graph:
  requires: [02-01-notification-service-protocol-extensions]
  provides: [schedule-notifications-use-case, first-launch-scheduling-integration]
  affects: [notification-permission-manager, first-launch-flow]
tech_stack:
  added:
    - ScheduleNotificationsUseCase (Domain/UseCases)
  patterns:
    - Conditional compilation (#if DEBUG) for testable notification times
    - Graceful degradation for authorization checks
    - Cancel-then-schedule pattern to prevent duplicate notifications
    - First-launch integration point for automatic scheduling
key_files:
  created:
    - HealthTracker/Domain/UseCases/ScheduleNotificationsUseCase.swift (98 lines)
  modified:
    - HealthTracker/Data/Services/NotificationPermissionManager.swift (+11 lines)
decisions:
  - Use #if DEBUG conditional compilation for testable times (2-3 minutes) vs production times (1 PM, 8 PM)
  - Schedule notifications immediately after permission granted on first launch
  - Cancel all notifications before scheduling to prevent duplicates
  - Graceful degradation: return without throwing if not authorized
  - Portuguese-BR messages match user requirements from 02-CONTEXT.md
metrics:
  duration_minutes: 3
  tasks_completed: 2
  files_created: 1
  files_modified: 1
  commits: 2
  test_coverage: manual-verification-required
completed: 2026-02-28T17:33:13Z
---

# Phase 2 Plan 2: Schedule Notifications Use Case Summary

**One-liner:** Daily notification scheduling (1 PM lunch, 8 PM evening) with Portuguese-BR messages, debug/release timing via conditional compilation, integrated into first-launch permission flow.

## What Was Built

### ScheduleNotificationsUseCase (Domain Layer)

Created Use Case to coordinate scheduling of both daily notifications:
- **Lunch notification (1 PM):** "Registre o que você comeu hoje"
- **Evening notification (8 PM):** "Registre suas refeições e atividades"
- **Authorization check:** Queries authorization status before scheduling, returns gracefully if denied
- **Debug timing:** 2-3 minutes from now in debug builds (testable via #if DEBUG)
- **Release timing:** 1 PM and 8 PM in release builds (production times)
- **Duplicate prevention:** Calls cancelAllNotifications() before scheduling
- **Daily recurrence:** Uses repeats: true for both notifications

### First-Launch Integration

Updated NotificationPermissionManager to schedule notifications after permission granted:
- **Integration point:** After `useCase.execute()` returns granted == true
- **Automatic setup:** Notifications scheduled immediately when user grants permission
- **Error handling:** Wrapped in existing do-catch, scheduling failures logged but don't crash
- **Graceful degradation:** If scheduling fails, app continues normally

## Implementation Approach

### Authorization Check Strategy
Use Case checks authorization status before attempting to schedule:
```swift
let status = await notificationService.authorizationStatus()
guard status == .authorized else {
    print("[ScheduleNotifications] Not authorized, skipping scheduling")
    return
}
```

If not authorized, Use Case returns gracefully without throwing (satisfies NOTIF-03 graceful degradation requirement).

### Debug vs Release Timing Strategy
Implemented conditional compilation to separate testable times from production times:
- **Debug builds:** Calculate 2 and 3 minutes from Date() using addingTimeInterval, extract hour/minute components
- **Release builds:** DateComponents(hour: 13, minute: 0) and DateComponents(hour: 20, minute: 0)
- **Pattern:** #if DEBUG wraps entire timing logic, returns tuple of DateComponents

This allows developers to quickly test notification delivery without waiting hours or manually changing device time.

### Duplicate Prevention Strategy
Use Case calls cancelAllNotifications() before scheduling to prevent race conditions:
- **Problem:** Multiple app launches in short period could create duplicate notifications
- **Solution:** Clear all pending notifications first, then schedule fresh
- **Trade-off:** Loses any manual notification changes (acceptable for v1.0, no manual control exposed)

### Integration Point Design
Notifications scheduled in NotificationPermissionManager.requestIfFirstLaunch() after permission granted:
- **Why here:** Ensures notifications set up as soon as user grants permission
- **Conditional:** Only schedules if granted == true (no wasted work if denied)
- **Timing:** First launch only (UserDefaults flag prevents repeated requests)
- **Error handling:** Extends existing do-catch, scheduling failures logged

## Design Decisions

### Decision 1: Use #if DEBUG for Testable Times
**Context:** Production times (1 PM, 8 PM) make development testing impractical (wait hours or manually change device time).

**Options considered:**
1. UserDefaults flag to toggle debug times (runtime configuration)
2. Build configuration preprocessor (#if DEBUG)
3. Hardcode production times, accept slow testing

**Selected:** Build configuration (#if DEBUG)

**Rationale:**
- Compile-time decision, zero runtime overhead
- Debug builds automatically get testable times (2-3 minutes from now)
- Release builds automatically get production times
- No UI needed to toggle behavior
- Developers can't accidentally ship debug times (build configuration enforces)

### Decision 2: Schedule After Permission Granted (First Launch)
**Context:** Notifications need to be scheduled at some point in app lifecycle.

**Options considered:**
1. Schedule on every app launch (defensive, handles edge cases)
2. Schedule after permission granted on first launch
3. Schedule on demand when user navigates to specific screen

**Selected:** Schedule after permission granted on first launch

**Rationale:**
- iOS maintains scheduled notifications across app lifecycle (reboots, updates)
- Scheduling once is sufficient for normal operation
- Scheduling on first launch ensures notifications exist immediately
- Avoids redundant scheduling on every launch (performance)
- Defensive check (cancelAllNotifications) handles edge cases where iOS clears notifications

### Decision 3: Cancel Then Schedule Pattern
**Context:** Need to prevent duplicate notifications if scheduling runs multiple times.

**Options considered:**
1. Check pending notifications first, only schedule if missing (complex)
2. Cancel all before scheduling (simple)
3. Rely on identifier replacement (iOS replaces pending notification with same identifier)

**Selected:** Cancel all before scheduling

**Rationale:**
- Simplest implementation (one method call)
- Guarantees no duplicates regardless of race conditions
- iOS identifier replacement has edge cases with rapid scheduling
- Acceptable trade-off: loses any manual notification state (not exposed in v1.0)
- Future phases can add smarter logic if needed

## Requirements Coverage

### Implemented Requirements

| Requirement | Implementation | Verification |
|-------------|----------------|--------------|
| NOTIF-05: Schedule 1 PM notification | DateComponents(hour: 13, minute: 0) in release builds | Manual: Check pending notifications |
| NOTIF-06: Schedule 8 PM notification | DateComponents(hour: 20, minute: 0) in release builds | Manual: Check pending notifications |
| NOTIF-07: Lunch message Portuguese-BR | body: "Registre o que você comeu hoje" | Code inspection: Line 52 |
| NOTIF-08: Evening message Portuguese-BR | body: "Registre suas refeições e atividades" | Code inspection: Line 59 |
| NOTIF-18: Use Case coordinates operations | ScheduleNotificationsUseCase schedules both notifications | Code inspection: Lines 44-66 |
| NOTIF-23: Debug configuration testable | #if DEBUG provides 2-3 minute times | Manual: Build in debug, verify times |

## Deviations from Plan

None - plan executed exactly as written.

## Known Limitations

1. **No duplicate detection on concurrent launches:** If app launched multiple times within 1 second (edge case), cancelAllNotifications might not complete before next scheduling attempt. Acceptable risk - iOS identifier replacement will handle it.

2. **No validation of pending notifications:** App doesn't check if notifications still exist after initial scheduling. iOS typically maintains them, but rare edge cases (low memory, system updates) could clear them. Future phase can add validation if user reports indicate it's necessary.

3. **Debug times are static offset:** Debug timing uses fixed 2-3 minute offset from Date(). If developer takes >2 minutes to install app after build, first notification will fire immediately. Acceptable for testing - just rebuild if needed.

## Testing Notes

### Manual Verification Required

**Debug Build Testing (NOTIF-23):**
1. Build in debug configuration
2. Reset simulator (erase all content and settings)
3. Launch app, grant notification permission
4. Check pending notifications: should show times ~2-3 minutes from now
5. Wait 2-3 minutes, verify notifications fire

**Release Build Testing (NOTIF-05, NOTIF-06):**
1. Build in release configuration
2. Reset simulator
3. Launch app, grant permission
4. Check pending notifications: should show 13:00 and 20:00

**Portuguese Messages (NOTIF-07, NOTIF-08):**
1. After scheduling, check notification content
2. Lunch: "Registre o que você comeu hoje"
3. Evening: "Registre suas refeições e atividades"

**Authorization Handling:**
1. Deny permission on first launch
2. Verify app doesn't crash
3. Verify no notifications scheduled
4. Check console logs for "Not authorized, skipping scheduling" message

## Self-Check: PASSED

Verified all files and commits exist:
- ✓ HealthTracker/Domain/UseCases/ScheduleNotificationsUseCase.swift
- ✓ Commit c5bc5ff (Task 1: Create ScheduleNotificationsUseCase)
- ✓ Commit 203cbc7 (Task 2: Integrate scheduling into first-launch flow)
