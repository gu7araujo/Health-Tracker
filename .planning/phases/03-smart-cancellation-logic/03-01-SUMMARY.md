---
phase: 3
plan: '03-01'
subsystem: notification-scheduling
tags: [foundation, architecture, phase-2-fix]
status: complete
completed: 2026-02-28T20:34:48Z
requirements: [NOTIF-11, NOTIF-12, NOTIF-13, NOTIF-14]
dependencies:
  requires: []
  provides:
    - date-specific-notification-identifiers
    - non-repeating-notifications
    - 30-day-scheduling-window
  affects:
    - ScheduleNotificationsUseCase
    - Phase 2 test suite (to be updated in 03-03)
tech_stack:
  added: []
  patterns:
    - date-specific-identifiers
    - non-repeating-calendar-notifications
    - 30-day-upfront-scheduling
key_files:
  created: []
  modified:
    - HealthTracker/Domain/UseCases/ScheduleNotificationsUseCase.swift
decisions:
  - "Schedule 60 individual notifications (30 days × 2) instead of 2 repeating notifications"
  - "Use date-specific identifiers (lunch-reminder-YYYY-MM-DD) for targeted cancellation"
  - "Set repeats: false to enable per-day cancellation without affecting future days"
  - "Include full DateComponents (year, month, day, hour, minute) for non-repeating triggers"
metrics:
  duration: 384
  tasks: 1
  files: 1
---

# Phase 3 Plan 03-01: Redesign Notification Scheduling with Date-Specific Identifiers Summary

**One-liner:** Replaced Phase 2's repeating notifications with 60 individual date-specific notifications (30 days × 2) using non-repeating triggers and formatted identifiers (e.g., "lunch-reminder-2026-02-28") to enable targeted daily cancellation.

## Tasks Completed

### Task 1: Modify ScheduleNotificationsUseCase to Schedule Date-Specific Notifications
**Status:** Complete
**Commit:** e3de90c
**Files Modified:**
- HealthTracker/Domain/UseCases/ScheduleNotificationsUseCase.swift

**Changes Made:**
1. Removed repeating notification logic (old static identifiers "lunch-reminder", "evening-reminder")
2. Added 30-day scheduling loop (0..<30) to schedule 60 individual notifications
3. Implemented date-specific identifier pattern using `formatDateForIdentifier()`
4. Updated `notificationTiming()` to accept date parameter and return full DateComponents
5. Set `repeats: false` for all notifications to enable targeted cancellation
6. Included year, month, day components in DateComponents for non-repeating triggers
7. Maintained debug testability with 2-3 minute delays for today's notifications
8. Added `formatDateForIdentifier()` helper method (yyyy-MM-dd format)
9. Updated print statement to confirm 60 notifications scheduled

**Verification:**
- Build successful (xcodebuild passed)
- Code review confirms all requirements met:
  - 60 notifications scheduled (30 days × 2 per day)
  - Date-specific identifiers follow "type-YYYY-MM-DD" pattern
  - Non-repeating notifications (repeats: false)
  - Full DateComponents with year/month/day/hour/minute
  - Debug builds maintain testability

**Expected Test Failures:**
Phase 2 tests now fail because they expect old behavior (2 repeating notifications with static identifiers). This is expected and documented in plan. Tests will be updated in plan 03-03 to verify new behavior:
- Expected 2 identifiers, now 60
- Expected static identifiers, now date-specific
- Expected repeats: true, now repeats: false
- Expected count 2, now count 60

## Verification Results

All plan verification criteria met:

1. **Notification identifiers are date-specific:** ✅
   - Pattern: "lunch-reminder-2026-02-28", "evening-reminder-2026-02-28"
   - Each day has unique identifiers
   - No collision between days

2. **30 days of notifications scheduled:** ✅
   - Loop: 0..<30 (day 0 through day 29)
   - Each day: 2 notifications (lunch + evening)
   - Total: 60 individual notification requests

3. **Non-repeating notifications:** ✅
   - All notifications: repeats: false
   - Each notification fires once on specific date
   - Future days remain when today's is canceled

4. **DateComponents include full date:** ✅
   - Components: [.year, .month, .day, .hour, .minute]
   - Ensures notification fires on correct date
   - Non-repeating calendar trigger behavior

5. **Debug builds maintain testability:** ✅
   - Today's notifications: 2-3 minutes from now
   - Future days: standard 13:00/20:00 times
   - Quick verification without waiting

## Deviations from Plan

None - plan executed exactly as written.

## Requirements Coverage

This plan enables the following requirements:

- **NOTIF-11:** Date-specific identifiers enable targeted cancellation for "today" only
- **NOTIF-12:** Non-repeating notifications support cancellation regardless of data type
- **NOTIF-13:** Identifiers use app's calendar logic (yyyy-MM-dd format)
- **NOTIF-14:** iOS notification system persists date-specific schedules across force-quit

## Technical Implementation

**Architecture Changes:**
- Changed from 2 repeating notifications to 60 individual notifications
- Identifier pattern: "{type}-{YYYY-MM-DD}" enables targeted cancellation
- Non-repeating triggers allow per-day cancellation without affecting future days

**Code Quality:**
- Clean separation: formatDateForIdentifier() helper method
- Maintained backward compatibility: same notification titles and bodies
- Debug support: testable timing preserved for today's notifications
- Documentation: comprehensive method comments explain new behavior

**iOS Integration:**
- UNCalendarNotificationTrigger with full DateComponents
- Non-repeating triggers (repeats: false) for targeted cancellation
- 30-day scheduling window ensures notifications continue without daily app opens
- All 60 notifications scheduled upfront on permission grant or app launch

## Dependencies Impact

**Provides for future plans:**
- 03-02 can now cancel by date-specific identifier
- 03-03 will update tests to verify 60 notifications
- Cancellation logic can target "today" without affecting "tomorrow"

**Affects:**
- Phase 2 test suite: 4 tests now fail (expected, will be fixed in 03-03)
- ScheduleNotificationsUseCase: complete redesign of scheduling approach
- No breaking changes to public API (execute() signature unchanged)

## Next Steps

1. **Plan 03-02:** Implement CancelNotificationsUseCase using date-specific identifiers
2. **Plan 03-03:** Update test suite to verify 60 notifications and date-specific behavior
3. **Future consideration:** Re-scheduling after cancellation (mentioned in plan context)

## Self-Check

Verifying implementation claims:

**Files created/modified:**
- ScheduleNotificationsUseCase.swift exists: FOUND
- File contains formatDateForIdentifier: FOUND
- File contains notificationTiming(for:): FOUND
- File contains date-specific identifiers: FOUND
- File contains repeats: false: FOUND

**Commits:**
- e3de90c exists: FOUND
- Commit message matches feat(03-01): FOUND
- 1 file changed in commit: FOUND

**Build verification:**
- xcodebuild build: SUCCESS
- Code compiles without errors: PASSED
- SwiftLint/SwiftFormat auto-formatting applied: PASSED

## Self-Check: PASSED

All claims verified. Implementation complete and correct.
