# HealthTracker Notifications

## What This Is

An iOS health tracking app that helps users build daily logging habits through smart notifications. Users track meals, workouts, water intake, and mood, with reminders at key times during the day if they haven't logged yet.

## Core Value

Users remember to log their daily health data consistently, building a habit through timely, non-intrusive reminders.

## Requirements

### Validated

<!-- Existing capabilities from the current codebase -->

- ✓ User can log meals with quantity and satisfaction — existing
- ✓ User can log workouts with type and duration — existing
- ✓ User can log water intake via slider — existing
- ✓ User can log mood — existing
- ✓ User can view analytics across multiple time periods (7d/30d/90d/1y) — existing
- ✓ Data syncs across devices via iCloud Drive — existing
- ✓ App follows Clean Architecture with MVVM pattern — existing

### Active

<!-- New notification feature scope -->

- [ ] User receives notification at 1:00 PM if no data logged yet that day
- [ ] User receives notification at 8:00 PM if no data logged yet that day
- [ ] Evening notification is skipped if user logged data after lunch notification
- [ ] Lunch notification shows time-specific message (e.g., "Time to log your lunch!")
- [ ] Evening notification shows time-specific message (e.g., "How was your day? Log your health data")
- [ ] App requests notification permission on first launch
- [ ] Notification check uses same "day" logic as existing app
- [ ] Any data entry (meal, workout, water, or mood) counts as "logged" for the day

### Out of Scope

- User-configurable notification times — fixed at 1 PM and 8 PM
- Settings toggle to disable notifications — always on by design
- Separate toggles for lunch vs evening — both fire or neither
- Notification if user already logged data — only send when no data yet
- Multiple notifications per period — maximum 2 per day
- Notification history or tracking — just the reminders

## Context

**Existing Implementation:**
- iOS 26.0 native app using SwiftUI
- Clean Architecture with Domain/Data/Presentation layers
- Data persistence via iCloud Drive (JSON format)
- No external dependencies, pure Swift/iOS frameworks
- Swift 6.0 with modern concurrency patterns

**User Behavior:**
- Users may forget to log daily health data
- Lunchtime (1 PM) is first reminder opportunity
- Evening (8 PM) is last chance reminder
- Once they log anything, they're engaged for the day

**Technical Context:**
- Need to integrate iOS UserNotifications framework
- Must respect system notification permissions
- Should integrate with existing data layer to check if data logged
- Notification scheduling should survive app termination
- Need to cancel/reschedule notifications based on user activity

## Constraints

- **Platform**: iOS 26.0 minimum — must use native UserNotifications framework
- **Architecture**: Must maintain Clean Architecture pattern — notification logic should fit into existing layers
- **Dependencies**: No external notification libraries — use iOS native only
- **Timing**: Fixed notification times (1 PM, 8 PM) — not configurable by user
- **Permissions**: Always request on first launch — no deferred permission flow

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Fixed notification times (1 PM, 8 PM) | Simplicity - no settings UI needed, covers key day moments | — Pending |
| Any data entry cancels both notifications | Once user engages, they're active for the day | — Pending |
| Request permission on first launch | Get permission early while user is motivated | — Pending |
| No settings toggle | Always-on keeps implementation simple, matches habit-building goal | — Pending |
| Time-specific messages | "Log your lunch" vs "How was your day" feels more personal than generic reminder | — Pending |

---
*Last updated: 2026-02-28 after initialization*
