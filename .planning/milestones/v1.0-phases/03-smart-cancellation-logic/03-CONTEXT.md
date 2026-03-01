# Phase 3: Smart Cancellation Logic - Context

**Gathered:** 2026-02-28
**Status:** Ready for planning

<domain>
## Phase Boundary

Cancel all pending notifications when the user logs any type of health data (meal, workout, water, mood) for today. This prevents notification fatigue by not nagging users after they've already engaged with the app. Notifications automatically reschedule for future days without requiring app launch.

</domain>

<decisions>
## Implementation Decisions

### Cancellation Trigger Points
- MainViewModel.persistChanges() calls CancelNotificationsUseCase after successfully saving data
- This is the single point where all data mutations (meal, workout, water, mood) are persisted
- Individual ViewModels don't have their own save methods - they all funnel through MainViewModel.persistChanges()
- Cancellation only happens if save succeeds - failed saves don't cancel notifications
- Async fire-and-forget execution - MainViewModel doesn't await cancellation completion
- All data types (meal, workout, water, mood) trigger cancellation equally through this unified flow

### Day Boundary Logic
- "Today" defined by matching the app's existing calendar logic for consistency (NOTIF-13 requirement)
- Use calendar-based approach already established in Phase 2 for time zone and DST handling
- Logging at 11:59 PM only cancels today's notifications - tomorrow's notifications fire normally
- Each day is independent - yesterday's logging doesn't affect today's notifications

### Cancellation Scope
- Cancel all pending notifications for today (both 1 PM and 8 PM) regardless of which already fired
- Remove delivered notifications from notification center (prevents stale reminders)
- Clear notification badge count when cancelling
- Cancel by identifier pattern (e.g., matching today's date in notification identifiers)
- Precise cancellation using identifiers from Phase 2's notification naming scheme

### Persistence and Recovery
- Rely on iOS's UNUserNotificationCenter for persistence - removePendingNotificationRequests() survives force-quit automatically (NOTIF-14 requirement)
- No additional state tracking needed - iOS handles idempotency of cancellation calls
- Schedule notifications for next 30 days upfront (on first launch or after cancellation)
- When user logs data, cancel only today's notifications - future days remain scheduled
- This ensures notifications fire even if user doesn't open the app daily

### Claude's Discretion
- Exact notification identifier pattern format (use existing Phase 2 scheme)
- How to handle edge cases like data deletion (if user deletes their only logged item)
- Logging level and error handling details
- Specific date arithmetic implementation for 30-day scheduling window

</decisions>

<specifics>
## Specific Ideas

- Follow Phase 2's calendar-based trigger approach (NOTIF-09) for consistency
- Requirements NOTIF-11, NOTIF-12, NOTIF-13, NOTIF-14 all map to these decisions
- Success criteria: logging any data type cancels all remaining notifications for that day
- Critical: must work after force-quit (NOTIF-14) - iOS notification system provides this guarantee

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 03-smart-cancellation-logic*
*Context gathered: 2026-02-28*
