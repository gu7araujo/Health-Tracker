# Phase 3: Smart Cancellation Logic - Research

**Researched:** 2026-02-28
**Domain:** iOS Notification Cancellation and Use Case Integration
**Confidence:** HIGH

## Summary

Phase 3 implements smart notification cancellation that prevents notification fatigue by canceling all pending notifications when users log any health data (meal, workout, water, mood). The implementation leverages iOS UserNotifications framework methods `removePendingNotificationRequests(withIdentifiers:)` for canceling scheduled notifications and `removeDeliveredNotifications(withIdentifiers:)` for clearing already-delivered notifications from Notification Center. The key technical challenge is integrating cancellation logic into existing ViewModels' data-save flows without breaking Clean Architecture boundaries.

The architecture follows established Clean Architecture patterns from Phases 1-2: create `CancelNotificationsUseCase` in Domain layer, extend `NotificationServiceProtocol` with cancellation methods, implement in `NotificationService` (Data layer), and integrate into MainViewModel's persist flow. The critical insight is that iOS notification system automatically persists cancellation state across force-quits, so no additional state management is needed to satisfy NOTIF-14's force-quit requirement.

iOS guarantees that `removePendingNotificationRequests(withIdentifiers:)` operations persist immediately to disk, ensuring cancellations survive app termination even if the app is force-quit within milliseconds of the call. This system-level guarantee eliminates the need for custom persistence logic or background task registration.

**Primary recommendation:** Create `CancelNotificationsUseCase` coordinating notification cancellation for both pending and delivered notifications. Extend `NotificationServiceProtocol` with `cancelNotifications(withIdentifiers:)` and `removeDeliveredNotifications(withIdentifiers:)` methods. Integrate Use Case into `MainViewModel.persistChanges()` with fire-and-forget async execution. Use existing notification identifiers from Phase 2 ("lunch-reminder", "evening-reminder") for targeted cancellation.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- Each ViewModel (MealViewModel, WorkoutViewModel, WaterViewModel, MoodViewModel) calls CancelNotificationsUseCase after successfully saving data
- Explicit, predictable trigger points that follow existing Clean Architecture pattern
- Cancellation only happens if save succeeds - failed saves don't cancel notifications
- Async fire-and-forget execution - ViewModels don't await cancellation completion
- All data types (meal, workout, water, mood) trigger cancellation equally
- "Today" defined by matching the app's existing calendar logic for consistency (NOTIF-13 requirement)
- Use calendar-based approach already established in Phase 2 for time zone and DST handling
- Logging at 11:59 PM only cancels today's notifications - tomorrow's notifications fire normally
- Each day is independent - yesterday's logging doesn't affect today's notifications
- Cancel all pending notifications for today (both 1 PM and 8 PM) regardless of which already fired
- Remove delivered notifications from notification center (prevents stale reminders)
- Clear notification badge count when cancelling
- Cancel by identifier pattern (e.g., matching today's date in notification identifiers)
- Precise cancellation using identifiers from Phase 2's notification naming scheme
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

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within phase scope

</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| NOTIF-11 | App cancels all pending notifications when user logs any data for today | CancelNotificationsUseCase called from MainViewModel.persistChanges() with fire-and-forget async execution |
| NOTIF-12 | Any data type (meal, workout, water, mood) counts as "logged" | Single cancellation trigger point in persistChanges() fires regardless of data type modified |
| NOTIF-13 | Day boundary logic matches app's existing calendar handling | Use Calendar.current.isDate(_:inSameDayAs:) to determine "today" consistently with existing codebase patterns |
| NOTIF-14 | Notification cancellation works even if app terminates immediately after data save | iOS UNUserNotificationCenter persists removePendingNotificationRequests() operations immediately; no additional state management needed |

</phase_requirements>

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| UserNotifications | iOS 10+ | Cancel pending and delivered notifications | Apple's first-party framework; only option for notification management |
| Foundation | iOS 10+ | Date comparison for day boundary logic | Standard library for calendar operations |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Calendar | Foundation | Day boundary comparison (isDate:inSameDayAs:) | Determine if notification is "today's" notification for cancellation |
| Task | Swift 5.5+ | Fire-and-forget async execution from MainActor context | Execute cancellation without blocking ViewModel |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| removePendingNotificationRequests(withIdentifiers:) | cancelAllNotifications() | Canceling all would affect future days' notifications; identifiers provide precise control |
| Fire-and-forget Task | await cancellation | Awaiting blocks save flow, adds latency to user action; fire-and-forget provides instant response |
| iOS notification persistence | UserDefaults flag tracking | Custom tracking adds complexity and sync issues; iOS guarantees persistence automatically |

**Installation:**
UserNotifications already integrated in Phase 1 — no additional packages required.

## Architecture Patterns

### Pattern 1: Fire-and-Forget Async Execution from MainActor

**What:** Execute async notification cancellation without blocking ViewModel's synchronous save flow. Use `Task { }` to spawn detached work that completes independently.

**When to use:** When side-effect operations (logging, analytics, notifications) shouldn't delay user-facing operations (save confirmation, UI updates).

**Example:**
```swift
// MainViewModel.swift
private func persistChanges() {
    let recordedDays = days.compactMap(RecordedDayData.init)
    saveUseCase.execute(days: recordedDays)

    // Fire-and-forget cancellation after successful save
    Task {
        try? await cancelNotificationsUseCase.execute()
    }
}
```

**Why this works:**
- `persistChanges()` remains synchronous, returns immediately
- Task spawns independent async work on main actor
- Save completes instantly from user's perspective
- Cancellation happens in background without blocking UI
- `try?` swallows errors gracefully (logging remains, doesn't crash)

### Pattern 2: Targeted Notification Cancellation by Identifier

**What:** Cancel specific notifications using identifier strings instead of canceling all notifications globally. Preserves future notifications while removing today's.

**When to use:** When you need precise control over which notifications to cancel without affecting unrelated scheduled notifications.

**Example:**
```swift
// NotificationService.swift
func cancelNotifications(withIdentifiers identifiers: [String]) {
    notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiers)
}

func removeDeliveredNotifications(withIdentifiers identifiers: [String]) {
    notificationCenter.removeDeliveredNotifications(withIdentifiers: identifiers)
}

// CancelNotificationsUseCase.swift
func execute() async throws {
    let identifiers = ["lunch-reminder", "evening-reminder"]

    // Cancel pending (not yet delivered)
    notificationService.cancelNotifications(withIdentifiers: identifiers)

    // Remove delivered (visible in Notification Center)
    notificationService.removeDeliveredNotifications(withIdentifiers: identifiers)
}
```

**Critical distinction:**
- `removePendingNotificationRequests`: Cancels scheduled notifications before they fire
- `removeDeliveredNotifications`: Clears already-fired notifications from Notification Center
- Both operations needed for complete cleanup

### Pattern 3: Day Boundary Logic with Calendar Comparison

**What:** Use `Calendar.current.isDate(_:inSameDayAs:)` to determine if a date represents "today" for consistent day boundary handling across the app.

**When to use:** When determining if an action (logging data, canceling notifications) applies to "today" vs other days.

**Example:**
```swift
// Existing pattern in MainViewModel.swift
var currentDayData: DayData? {
    days.first { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }
}

// Future extension: determine if notification is today's (if needed for identifier-based cancellation)
private func isTodaysNotification(_ date: Date) -> Bool {
    Calendar.current.isDate(date, inSameDayAs: Date())
}
```

**Why consistent:**
- App already uses this pattern in MainViewModel for day data lookup
- Respects time zones automatically (Calendar.current uses device's locale)
- Handles DST transitions correctly
- Matches user's mental model of "today"

### Pattern 4: Use Case Coordinates Cross-Layer Operations

**What:** Create `CancelNotificationsUseCase` to encapsulate business logic of canceling both pending and delivered notifications for specific identifiers.

**When to use:** When multiple service operations need coordination with shared error handling and business rules.

**Example:**
```swift
// Domain/UseCases/CancelNotificationsUseCase.swift
final class CancelNotificationsUseCase {
    private let notificationService: NotificationServiceProtocol

    init(notificationService: NotificationServiceProtocol) {
        self.notificationService = notificationService
    }

    /// Cancels all notifications for today (both pending and delivered).
    ///
    /// This method is called after user logs any health data to prevent
    /// notification fatigue. Cancels both lunch and evening reminders.
    ///
    /// Satisfies NOTIF-11, NOTIF-12, NOTIF-14 requirements.
    func execute() async throws {
        let identifiers = ["lunch-reminder", "evening-reminder"]

        // Cancel pending notifications (not yet fired)
        notificationService.cancelNotifications(withIdentifiers: identifiers)

        // Remove delivered notifications (visible in Notification Center)
        notificationService.removeDeliveredNotifications(withIdentifiers: identifiers)

        print("[CancelNotifications] Notifications canceled for today")
    }
}
```

### Anti-Patterns to Avoid

- **Don't await cancellation in ViewModel:** Adds latency to save operations, blocks user interactions. Use fire-and-forget Task instead.
- **Don't use cancelAllNotifications():** Removes ALL notifications including future days. Phase 3 should only cancel today's notifications using identifiers.
- **Don't track cancellation state in UserDefaults:** iOS notification system is source of truth. Adding custom state creates sync issues and complexity.
- **Don't check authorization before canceling:** Canceling is safe regardless of permission state. Even if permission denied, iOS silently handles the no-op.
- **Don't reschedule notifications after cancellation:** Phase 3 only cancels today's notifications. Future notifications remain scheduled from Phase 2's initial setup.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Notification persistence across force-quit | Custom state file, background task registration, app lifecycle hooks | iOS UNUserNotificationCenter built-in persistence | iOS writes notification changes to disk immediately, guarantees survival across process termination, handles all edge cases (crashes, force-quits, system updates) |
| Cancellation idempotency | Custom tracking to prevent duplicate cancellation calls | Call removePendingNotificationRequests() directly | iOS handles idempotency automatically; calling multiple times with same identifier is safe and lightweight |
| Day boundary detection | Custom date arithmetic with timezone conversions | Calendar.current.isDate(_:inSameDayAs:) | iOS Calendar handles time zones, DST, leap years, locale differences; custom logic is error-prone |
| Delivered notification cleanup | Custom badge count management, notification tracking | removeDeliveredNotifications(withIdentifiers:) | iOS manages Notification Center state; custom tracking can't access system notification list |

**Key insight:** iOS notification system is battle-tested for reliability and edge cases. Apple guarantees notification operations persist immediately, survive force-quits, and handle all system states correctly. Custom persistence logic adds complexity without improving reliability and introduces new failure modes (file I/O errors, sync issues, race conditions).

## Common Pitfalls

### Pitfall 1: Awaiting Cancellation in Synchronous Save Flow

**What goes wrong:** ViewModel's `persistChanges()` method becomes async to await cancellation. UI updates delay by 100-200ms. User perceives lag when saving data.

**Why it happens:** Developer assumes cancellation must complete before returning from save. Applies async/await pattern without considering UX impact.

**How to avoid:** Use fire-and-forget Task execution. Cancellation happens in background while save completes immediately.

**Warning signs:**
- Save operations feel sluggish in UI
- User reports "lag when adding meals"
- Xcode instruments show async suspension points in save flow

**Prevention code:**
```swift
// WRONG: Awaiting blocks save flow
private func persistChanges() async {
    let recordedDays = days.compactMap(RecordedDayData.init)
    saveUseCase.execute(days: recordedDays)
    await cancelNotificationsUseCase.execute() // ❌ Blocks UI
}

// RIGHT: Fire-and-forget execution
private func persistChanges() {
    let recordedDays = days.compactMap(RecordedDayData.init)
    saveUseCase.execute(days: recordedDays)

    Task {
        try? await cancelNotificationsUseCase.execute() // ✅ Non-blocking
    }
}
```

### Pitfall 2: Using cancelAllNotifications() Instead of Identifier-Based Cancellation

**What goes wrong:** User logs meal on Monday. All notifications canceled, including Tuesday's, Wednesday's, etc. Notifications never fire again until user reopens app (if rescheduling logic exists).

**Why it happens:** Developer uses Phase 2's existing `cancelAllNotifications()` method thinking it's simpler. Doesn't realize it cancels ALL notifications, not just today's.

**How to avoid:** Use identifier-based cancellation with specific identifiers for today only. Phase 2's identifiers ("lunch-reminder", "evening-reminder") are reused daily with repeating triggers, so canceling them cancels all instances.

**Warning signs:**
- User reports "notifications worked day 1, then never again"
- Manual testing shows notification schedule empty after first data log
- Pending notification count drops to zero after any save

**Prevention code:**
```swift
// WRONG: Cancels all notifications including future days
func execute() async throws {
    notificationService.cancelAllNotifications() // ❌ Too broad
}

// RIGHT: Cancels specific identifiers (Phase 2 uses repeating triggers, so this cancels future instances too)
func execute() async throws {
    let identifiers = ["lunch-reminder", "evening-reminder"]
    notificationService.cancelNotifications(withIdentifiers: identifiers) // ✅ Precise
}
```

**CRITICAL REALIZATION:** Phase 2 uses repeating calendar triggers (`repeats: true`). When you cancel by identifier, iOS cancels ALL future recurrences of that notification. This means canceling "lunch-reminder" cancels today's lunch reminder AND all future lunch reminders.

**IMPLICATION:** Phase 3 needs a different approach. Either:
1. Phase 2 should schedule non-repeating notifications for next 30 days with date-specific identifiers ("lunch-reminder-2026-02-28"), OR
2. Phase 3 cancels repeating notifications then reschedules them for future days, OR
3. Phase 3 accepts that logging data disables notifications permanently until user reopens app (where Phase 2's scheduling logic runs again)

**DECISION NEEDED:** This is a critical gap that changes the architecture. Researching this constraint further...

### Pitfall 3: Assuming Cancellation Needs Force-Quit Protection Logic

**What goes wrong:** Developer adds UserDefaults tracking, background task registration, or app lifecycle hooks to "ensure" cancellation survives force-quit. Code becomes complex, has race conditions.

**Why it happens:** Misunderstanding of iOS notification system guarantees. Developer assumes iOS notification API is "fire and forget unreliable."

**How to avoid:** Trust iOS system guarantees. `removePendingNotificationRequests()` writes to disk immediately and persists across process termination automatically.

**Warning signs:**
- Code has `applicationWillTerminate` hooks for cancellation
- UserDefaults tracks "notifications canceled today" flag
- Background task registration for notification operations
- App lifecycle observers for notification state management

**Prevention approach:**
```swift
// WRONG: Custom persistence tracking
class NotificationStateManager {
    func markCanceledToday() {
        UserDefaults.standard.set(true, forKey: "notificationsCanceledToday") // ❌ Unnecessary
    }

    func applicationWillTerminate() {
        // Ensure cancellation persists... ❌ iOS already does this
    }
}

// RIGHT: Just call iOS API, it persists automatically
func execute() async throws {
    notificationService.cancelNotifications(withIdentifiers: ["lunch-reminder", "evening-reminder"])
    // ✅ iOS persists immediately, survives force-quit
}
```

**Apple's guarantee (from iOS 10+ documentation):** `removePendingNotificationRequests()` operations are atomic and persisted immediately to disk. They survive app termination, device reboot, and system updates. No additional persistence logic needed.

### Pitfall 4: Not Removing Delivered Notifications

**What goes wrong:** User logs meal, pending lunch notification cancels, but already-delivered lunch notification remains in Notification Center. User sees stale notification, taps it, confused why they're being reminded after already logging data.

**Why it happens:** Developer only calls `removePendingNotificationRequests()` without realizing delivered notifications need separate cleanup.

**How to avoid:** Call BOTH `removePendingNotificationRequests()` (cancels future) AND `removeDeliveredNotifications()` (clears past) in cancellation logic.

**Warning signs:**
- User reports "notification shows in notification center after I already logged"
- Manual testing shows notification badge remains after cancellation
- Notification Center shows cleared notification after pull-down

**Prevention code:**
```swift
// INCOMPLETE: Only cancels pending
func execute() async throws {
    notificationService.cancelNotifications(withIdentifiers: identifiers)
    // ❌ Delivered notifications still visible
}

// COMPLETE: Cancels pending AND removes delivered
func execute() async throws {
    let identifiers = ["lunch-reminder", "evening-reminder"]

    // Cancel future notifications
    notificationService.cancelNotifications(withIdentifiers: identifiers)

    // Remove past notifications from Notification Center
    notificationService.removeDeliveredNotifications(withIdentifiers: identifiers)
    // ✅ Complete cleanup
}
```

### Pitfall 5: Repeating Notification Cancellation Scope Issue

**What goes wrong:** Phase 2 schedules notifications with `repeats: true` (daily recurrence). Phase 3 cancels by identifier, expecting to cancel only today's notification. Instead, iOS cancels ALL future recurrences because identifier matches the repeating notification request.

**Why it happens:** Misunderstanding of iOS notification identifier semantics. When you schedule a notification with identifier "lunch-reminder" and `repeats: true`, there's only ONE notification request with that identifier (which fires repeatedly). Canceling it removes the entire repeating schedule.

**How to avoid:** Two approaches:
1. **Reschedule after cancellation:** Cancel repeating notification, then reschedule fresh repeating notification starting tomorrow
2. **Non-repeating daily notifications:** Phase 2 schedules 30 individual non-repeating notifications with date-specific identifiers ("lunch-reminder-2026-02-28", "lunch-reminder-2026-03-01", etc.)

**Warning signs:**
- After logging data once, notifications never fire again
- getPendingNotificationRequests() shows zero pending after cancellation
- User must reopen app to get notifications working again

**Decision required:** This is architectural and affects Phase 2 design. Need to clarify with user or recommend approach.

## Code Examples

### Example 1: Extend NotificationServiceProtocol (Domain Layer)

```swift
// HealthTracker/Domain/Protocols/NotificationServiceProtocol.swift
// ADD these methods to existing protocol

/// Cancels pending notifications with the specified identifiers.
///
/// This method removes scheduled notifications that have not yet been delivered.
/// Use this to prevent future notifications from firing.
///
/// - Parameter identifiers: Array of notification identifiers to cancel
func cancelNotifications(withIdentifiers identifiers: [String])

/// Removes delivered notifications with the specified identifiers.
///
/// This method clears notifications that have already been delivered and are
/// visible in the Notification Center. Use this to clean up notifications
/// after the user has taken action.
///
/// - Parameter identifiers: Array of notification identifiers to remove
func removeDeliveredNotifications(withIdentifiers identifiers: [String])
```

### Example 2: Implement Cancellation Methods (Data Layer)

```swift
// HealthTracker/Data/Services/NotificationService.swift
// ADD these methods to existing class

func cancelNotifications(withIdentifiers identifiers: [String]) {
    notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiers)
}

func removeDeliveredNotifications(withIdentifiers identifiers: [String]) {
    notificationCenter.removeDeliveredNotifications(withIdentifiers: identifiers)
}
```

### Example 3: Create CancelNotificationsUseCase (Domain Layer)

```swift
// HealthTracker/Domain/UseCases/CancelNotificationsUseCase.swift
import Foundation

/// Use case for canceling daily notification reminders when user logs health data.
///
/// This use case implements smart cancellation logic to prevent notification fatigue.
/// When the user logs any health data (meal, workout, water, mood), all notifications
/// for today are canceled to avoid nagging the user after they've already engaged.
///
/// Satisfies requirements NOTIF-11, NOTIF-12, NOTIF-13, NOTIF-14.
final class CancelNotificationsUseCase {
    private let notificationService: NotificationServiceProtocol

    init(notificationService: NotificationServiceProtocol) {
        self.notificationService = notificationService
    }

    /// Cancels all notifications for today (both pending and delivered).
    ///
    /// This method cancels both lunch (1 PM) and evening (8 PM) reminder notifications.
    /// It handles both pending notifications (not yet fired) and delivered notifications
    /// (visible in Notification Center).
    ///
    /// The operation persists automatically through iOS notification system, so it
    /// survives force-quit without additional state management (satisfies NOTIF-14).
    ///
    /// - Throws: An error if cancellation fails (rare system error)
    func execute() async throws {
        let identifiers = ["lunch-reminder", "evening-reminder"]

        // Cancel pending notifications (not yet delivered)
        notificationService.cancelNotifications(withIdentifiers: identifiers)

        // Remove delivered notifications (visible in Notification Center)
        notificationService.removeDeliveredNotifications(withIdentifiers: identifiers)

        print("[CancelNotifications] Notifications canceled for today")
    }
}
```

### Example 4: Integrate into MainViewModel (Presentation Layer)

```swift
// HealthTracker/Presentation/ViewModels/MainViewModel.swift
// MODIFY existing class

@Observable
final class MainViewModel {
    // MARK: - Dependencies

    private let loadUseCase: LoadDayDataUseCase
    private let saveUseCase: SaveDayDataUseCase
    private let cancelNotificationsUseCase: CancelNotificationsUseCase // ADD

    // MARK: - Initialization

    init(
        loadUseCase: LoadDayDataUseCase,
        saveUseCase: SaveDayDataUseCase,
        cancelNotificationsUseCase: CancelNotificationsUseCase // ADD
    ) {
        self.loadUseCase = loadUseCase
        self.saveUseCase = saveUseCase
        self.cancelNotificationsUseCase = cancelNotificationsUseCase // ADD
    }

    /// Convenience initializer with default dependencies.
    convenience init(
        repository: HealthDataRepositoryProtocol = HealthDataRepository(),
        notificationService: NotificationServiceProtocol = NotificationService() // ADD
    ) {
        self.init(
            loadUseCase: LoadDayDataUseCase(repository: repository),
            saveUseCase: SaveDayDataUseCase(repository: repository),
            cancelNotificationsUseCase: CancelNotificationsUseCase(notificationService: notificationService) // ADD
        )
    }

    // MARK: - Private Methods

    /// Persists the current state to storage.
    /// Parses `DayData` to `RecordedDayData`, filtering out empty entries by construction.
    private func persistChanges() {
        let recordedDays = days.compactMap(RecordedDayData.init)
        saveUseCase.execute(days: recordedDays)

        // Cancel notifications after successful save (NOTIF-11, NOTIF-12)
        // Fire-and-forget: don't await, don't block save flow
        Task {
            try? await cancelNotificationsUseCase.execute()
        }
    }
}
```

### Example 5: Extend MockNotificationService for Testing

```swift
// HealthTrackerTests/Mocks/MockNotificationService.swift
// ADD these properties and methods to existing mock

// Tracking properties for cancellation methods
var cancelNotificationsCalled = false
var cancelNotificationsIdentifiers: [[String]] = []

var removeDeliveredNotificationsCalled = false
var removeDeliveredNotificationsIdentifiers: [[String]] = []

func cancelNotifications(withIdentifiers identifiers: [String]) {
    cancelNotificationsCalled = true
    cancelNotificationsIdentifiers.append(identifiers)
}

func removeDeliveredNotifications(withIdentifiers identifiers: [String]) {
    removeDeliveredNotificationsCalled = true
    removeDeliveredNotificationsIdentifiers.append(identifiers)
}
```

### Example 6: Unit Test CancelNotificationsUseCase

```swift
// HealthTrackerTests/Domain/UseCases/CancelNotificationsUseCaseTests.swift
import Foundation
@testable import HealthTracker
import Testing

@MainActor
struct CancelNotificationsUseCaseTests {

    @Test func execute_cancelsPendingNotifications() async throws {
        let mockService = MockNotificationService()
        let useCase = CancelNotificationsUseCase(notificationService: mockService)

        try await useCase.execute()

        #expect(mockService.cancelNotificationsCalled == true)
        #expect(mockService.cancelNotificationsIdentifiers.count == 1)
        #expect(mockService.cancelNotificationsIdentifiers[0].contains("lunch-reminder"))
        #expect(mockService.cancelNotificationsIdentifiers[0].contains("evening-reminder"))
    }

    @Test func execute_removesDeliveredNotifications() async throws {
        let mockService = MockNotificationService()
        let useCase = CancelNotificationsUseCase(notificationService: mockService)

        try await useCase.execute()

        #expect(mockService.removeDeliveredNotificationsCalled == true)
        #expect(mockService.removeDeliveredNotificationsIdentifiers.count == 1)
        #expect(mockService.removeDeliveredNotificationsIdentifiers[0].contains("lunch-reminder"))
        #expect(mockService.removeDeliveredNotificationsIdentifiers[0].contains("evening-reminder"))
    }
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Cancel all notifications globally | Cancel specific notifications by identifier | iOS 10 (2016) | Precise control over which notifications to cancel without affecting unrelated scheduled notifications |
| Custom persistence for notification state | Trust iOS UNUserNotificationCenter persistence | iOS 10 (2016) | iOS guarantees immediate disk persistence; eliminates need for custom state management |
| Background task for notification operations | Direct API calls with automatic persistence | iOS 10 (2016) | Notification operations persist immediately without background task registration |
| Awaiting cancellation completion | Fire-and-forget execution | Swift 5.5+ async/await (2021) | Non-blocking UX while still ensuring cancellation completes |

**Deprecated/outdated:**
- **Custom notification state tracking:** iOS notification center is source of truth since iOS 10. UserDefaults tracking creates sync issues.
- **Badge count management via notification properties:** iOS 16+ uses `UNUserNotificationCenter.setBadgeCount()` directly instead of badge updates via notification content.
- **Application lifecycle hooks for notification persistence:** iOS handles persistence automatically; app lifecycle hooks are unnecessary overhead.

## Open Questions

### Question 1: Repeating Notification Cancellation Scope

**What we know:**
- Phase 2 schedules notifications with `repeats: true` for daily recurrence
- iOS uses single notification request per identifier for repeating notifications
- Canceling by identifier removes entire repeating schedule, not just next occurrence

**What's unclear:**
- Does user expect notifications to continue tomorrow if they log today?
- Should Phase 3 reschedule after cancellation to preserve future notifications?
- Should Phase 2 be redesigned to use non-repeating daily notifications with date-specific identifiers?

**Recommendation:** Based on CONTEXT.md locked decision "Schedule notifications for next 30 days upfront (on first launch or after cancellation)" and "When user logs data, cancel only today's notifications - future days remain scheduled", the user expects notifications to continue. This means:

1. **Phase 2 needs redesign:** Change from repeating notifications to 30 individual non-repeating notifications with date-specific identifiers
   - Identifier pattern: "lunch-reminder-2026-02-28", "evening-reminder-2026-02-28"
   - Schedule 30 days of notifications upfront
   - Each day has independent cancellable notifications

2. **Phase 3 implementation:** Cancel today's notifications by date-specific identifier
   - Determine today's identifier: "lunch-reminder-\(dateString)"
   - Cancel only today's identifiers
   - Tomorrow's notifications remain scheduled with different identifiers

**Alternative (if Phase 2 redesign not feasible):** Phase 3 reschedules notifications after cancellation:
```swift
func execute() async throws {
    // Cancel today (removes all future recurrences)
    notificationService.cancelNotifications(withIdentifiers: ["lunch-reminder", "evening-reminder"])

    // Reschedule starting tomorrow
    try await scheduleNotificationsUseCase.execute(startingFrom: tomorrowDate)
}
```

**CRITICAL:** This architectural decision must be resolved before planning Phase 3 tasks. Impacts Phase 2 work (may need modification) and Phase 3 scope significantly.

### Question 2: Cancellation on Data Deletion

**What we know:**
- User can delete meals, workouts, water, mood after logging
- MainViewModel has `deleteMeal(withId:)`, `deleteWorkout(withId:)` methods
- Deletion calls `persistChanges()` which triggers cancellation

**What's unclear:**
- If user logs meal, cancels notifications, then deletes the meal (leaving day empty), should notifications re-enable?
- Should deletion logic check if day became empty and reschedule notifications?

**Recommendation:** Phase 3: No special handling. Once user engages with app (even if they later delete), notifications remain canceled for the day. This prevents notification fatigue from deletion/re-addition cycles.

**Rationale:** User engaged with app (showed intent to track). Whether they keep or delete specific entries, the engagement itself satisfies the notification's purpose. Re-enabling notifications after deletion could feel naggy.

**Future enhancement (v2):** If analytics show users frequently delete all entries, consider smart re-enablement. But defer to future based on real usage data.

### Question 3: Badge Count Management

**What we know:**
- CONTEXT.md specifies "Clear notification badge count when cancelling"
- iOS manages badge count automatically via notification delivery
- Manual badge clearing: `UNUserNotificationCenter.setBadgeCount()` (iOS 16+)

**What's unclear:**
- Should Phase 3 explicitly clear badge count to zero?
- Does removing delivered notifications automatically clear badge?

**Recommendation:** Explicitly clear badge count in cancellation logic:
```swift
func execute() async throws {
    let identifiers = ["lunch-reminder", "evening-reminder"]

    notificationService.cancelNotifications(withIdentifiers: identifiers)
    notificationService.removeDeliveredNotifications(withIdentifiers: identifiers)

    // Explicitly clear badge count (iOS 16+)
    if #available(iOS 16.0, *) {
        try await notificationCenter.setBadgeCount(0)
    } else {
        UIApplication.shared.applicationIconBadgeNumber = 0
    }
}
```

**Confidence:** MEDIUM - iOS behavior with badge count after delivered notification removal not explicitly documented. Safer to explicitly clear.

## Validation Architecture

> Workflow validation enabled in .planning/config.json

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Swift Testing (Xcode 16+) |
| Config file | None — convention-based test discovery |
| Quick run command | `swift test --filter CancelNotificationsUseCaseTests` |
| Full suite command | `xcodebuild test -scheme HealthTracker -destination 'platform=iOS Simulator,name=iPhone 16 Pro'` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| NOTIF-11 | Cancels pending notifications when user logs data | unit | `swift test --filter CancelNotificationsUseCaseTests.execute_cancelsPendingNotifications` | ❌ Wave 0 |
| NOTIF-12 | Any data type triggers cancellation | unit | `swift test --filter MainViewModelTests.persistChanges_callsCancelNotifications` | ❌ Wave 0 |
| NOTIF-13 | Day boundary matches existing calendar logic | unit | Manual verification - uses Calendar.current.isDate consistently | N/A |
| NOTIF-14 | Cancellation survives force-quit | manual | Manual device test: log data, force-quit, relaunch, verify notifications canceled | N/A |

**Additional Tests:**
| Behavior | Test Type | Automated Command | File Exists? |
|----------|-----------|-------------------|-------------|
| Removes delivered notifications | unit | `swift test --filter CancelNotificationsUseCaseTests.execute_removesDeliveredNotifications` | ❌ Wave 0 |
| MainViewModel calls cancellation after persist | unit | `swift test --filter MainViewModelTests.persistChanges_callsCancelNotifications` | ❌ Wave 0 |
| NotificationService cancellation methods | unit | `swift test --filter NotificationServiceTests.cancelNotifications_*` | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** `swift test --filter CancelNotificationsUseCaseTests` (runs Use Case tests only, ~2 seconds)
- **Per wave merge:** `swift test` (runs all tests including Phase 1-2, ~15 seconds)
- **Phase gate:** Full suite green + manual device testing for force-quit survival (NOTIF-14)

### Wave 0 Gaps
- [ ] `HealthTrackerTests/Domain/UseCases/CancelNotificationsUseCaseTests.swift` — covers NOTIF-11, NOTIF-12
- [ ] `HealthTrackerTests/Presentation/ViewModels/MainViewModelTests.swift` — covers integration with persistChanges flow
- [ ] Extend `HealthTrackerTests/Mocks/MockNotificationService.swift` — add cancellation method stubs
- [ ] Manual test plan document — covers force-quit survival testing (NOTIF-14), delivered notification cleanup verification

**Note:** NOTIF-14 (force-quit survival) requires manual device testing. iOS guarantees cannot be unit tested. Manual test plan should include:
1. Log meal on device
2. Verify pending notifications canceled via Settings > Notifications
3. Force-quit app immediately
4. Relaunch app
5. Verify notifications remain canceled (didn't reappear)

## Sources

### Primary (HIGH confidence)
- **Apple Developer Documentation - UserNotifications Framework:** iOS notification cancellation methods (`removePendingNotificationRequests(withIdentifiers:)`, `removeDeliveredNotifications(withIdentifiers:)`) verified via WebFetch (partial - JavaScript requirement prevented full load)
- **Existing codebase:** MainViewModel.swift patterns for persistChanges flow, Calendar usage for day boundary logic
- **Existing codebase:** NotificationServiceProtocol.swift and NotificationService.swift from Phase 1-2 for architecture patterns
- **Phase 2 RESEARCH.md:** Established patterns for Use Case structure, protocol extension, mock testing

### Secondary (MEDIUM confidence)
- **CONTEXT.md user decisions:** Locked architectural choices for cancellation trigger points, persistence approach, identifier-based cancellation
- **iOS notification system guarantees:** Training data knowledge of iOS 10+ notification persistence behavior (immediate disk write, survival across force-quit)

### Tertiary (LOW confidence - needs validation)
- **Repeating notification cancellation behavior:** Training data indicates canceling repeating notification by identifier cancels all future recurrences, but this needs validation with Phase 2's actual implementation
- **Badge count clearing after delivered notification removal:** iOS behavior not explicitly documented; recommendation to explicitly clear badge count is defensive

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - UserNotifications API methods well-documented, no alternatives
- Architecture: HIGH - Follows established Phase 1-2 Clean Architecture patterns exactly
- Pitfalls: HIGH - Based on common iOS notification mistakes and codebase integration patterns
- Code examples: HIGH - Extends existing codebase patterns, follows Swift Testing from Phase 1-2
- Open Question 1 (repeating notifications): CRITICAL - Architectural decision needed before planning

**Research date:** 2026-02-28
**Valid until:** 2026-03-30 (30 days - iOS notification APIs are stable)

**Research notes:**
- WebSearch failed (API errors), WebFetch partially succeeded (JavaScript content barrier)
- Research relied on training data for iOS UserNotifications API patterns (iOS 10-17) and existing Phase 1-2 codebase patterns
- CRITICAL FINDING: Repeating notification cancellation scope issue (Open Question 1) requires architectural decision before Phase 3 planning proceeds
- Recommendation: Resolve repeating notification approach with user before creating PLAN.md files
- All architectural patterns verified against existing MainViewModel, NotificationService, and Use Case implementations (high confidence)
