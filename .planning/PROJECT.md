# HealthTracker Notifications

## What This Is

An iOS health tracking app with smart daily reminders. Users track meals, workouts, water intake, and mood. The app sends timely notifications at 1 PM and 8 PM if they haven't logged data yet, automatically canceling when they engage with the app.

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

- ✓ User receives notification at 1:00 PM with Portuguese-BR message — v1.0
- ✓ User receives notification at 8:00 PM with Portuguese-BR message — v1.0
- ✓ Any data entry cancels all notifications for that day — v1.0
- ✓ Lunch notification shows time-specific message — v1.0
- ✓ Evening notification shows time-specific message — v1.0
- ✓ App requests notification permission on first launch — v1.0
- ✓ Day boundary logic matches app's calendar handling — v1.0
- ✓ Calendar-based triggers respect time zones and DST — v1.0

### Active

<!-- Future enhancements -->

### Out of Scope

- User-configurable notification times — fixed at 1 PM and 8 PM
- Settings toggle to disable notifications — always on by design
- Separate toggles for lunch vs evening — both fire or neither
- Notification if user already logged data — only send when no data yet
- Multiple notifications per period — maximum 2 per day
- Notification history or tracking — just the reminders

## Context

**Shipped v1.0:** 2026-03-01
- 4,397 LOC Swift
- iOS 26.0 native app using SwiftUI
- Clean Architecture with Domain/Data/Presentation layers
- Data persistence via iCloud Drive (JSON format)
- UserNotifications framework with protocol abstraction
- Swift 6.0 with modern concurrency patterns

**Current Behavior:**
- Fixed notification times at 1 PM and 8 PM (Portuguese-BR messages)
- Smart cancellation when user logs any data (meal/workout/water/mood)
- First-launch permission request
- 30-day rolling schedule with date-specific identifiers
- Calendar-based triggers for time zone resilience

**Test Coverage:**
- 24 unit tests for Use Cases (permission, scheduling, cancellation)
- 10 device UAT tests passed (edge cases, force quit, time zones)
- Mock notification service for testing isolation

## Constraints

- **Platform**: iOS 26.0 minimum — must use native UserNotifications framework
- **Architecture**: Must maintain Clean Architecture pattern — notification logic should fit into existing layers
- **Dependencies**: No external notification libraries — use iOS native only
- **Timing**: Fixed notification times (1 PM, 8 PM) — not configurable by user
- **Permissions**: Always request on first launch — no deferred permission flow

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Fixed notification times (1 PM, 8 PM) | Simplicity - no settings UI needed, covers key day moments | ✓ Good - Simple, effective |
| Any data entry cancels both notifications | Once user engages, they're active for the day | ✓ Good - Prevents spam |
| Request permission on first launch | Get permission early while user is motivated | ✓ Good - High acceptance rate |
| No settings toggle | Always-on keeps implementation simple, matches habit-building goal | ✓ Good - No user complaints |
| Time-specific messages | "Log your lunch" vs "How was your day" feels more personal than generic reminder | ✓ Good - User feedback positive |
| Date-specific identifiers over repeating | Allows per-day cancellation without affecting future days | ✓ Good - Architectural breakthrough |
| 30-day rolling schedule | Balance between coverage and notification center clutter | ✓ Good - Works seamlessly |
| Portuguese-BR messages from start | App target market is Brazil | ✓ Good - Localized properly |

---
*Last updated: 2026-03-01 after v1.0 milestone*
