# Phase 2: Basic Notification Scheduling - Research

**Researched:** 2026-02-28
**Domain:** iOS Local Notification Scheduling with UserNotifications Framework
**Confidence:** MEDIUM

## Summary

Phase 2 extends the notification service foundation from Phase 1 to schedule daily recurring notifications at 1 PM and 8 PM with Portuguese-BR time-specific messages. The iOS UserNotifications framework provides `UNCalendarNotificationTrigger` for scheduling notifications at specific times with automatic time zone and DST handling. Notifications are scheduled using `UNNotificationRequest` objects with unique identifiers, notification content, and calendar-based triggers.

The implementation follows Clean Architecture by extending the existing `NotificationServiceProtocol` with scheduling methods, implementing them in `NotificationService` (Data layer), and coordinating through a new Use Case. The key technical challenge is ensuring notifications recur daily without manual rescheduling, which requires `repeats: true` in calendar triggers. Debug configuration needs a testable mechanism (conditional compilation or configuration-based timing) to avoid hardcoded production times during development.

**Primary recommendation:** Use `UNCalendarNotificationTrigger` with `DateComponents` (hour, minute) and `repeats: true` for daily recurring notifications. Extend protocol with `scheduleNotification` and `cancelAllNotifications` methods. Create `ScheduleNotificationsUseCase` to coordinate scheduling operations. Use `#if DEBUG` conditional compilation for testable notification times during development.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **1 PM notification:** "Registre o que você comeu hoje" (action-focused, covers meals that may not be logged yet)
- **8 PM notification:** "Registre suas refeições e atividades" (comprehensive reminder for end-of-day logging)
- Notifications should use app name "HealthTracker" as the title
- Content is action-oriented and acknowledges user may not have logged data yet
- Use default system behavior: sound + badge + banner
- Respect user's system notification preferences
- Follow iOS best practices for permission and presentation

### Claude's Discretion
- Scheduling implementation approach (recurring request vs multiple days, rescheduling strategy)
- Debug configuration design (how to enable testable times for development)
- Time zone and DST handling implementation (automatic adjustment mechanism)
- Notification identifiers and category structure
- Integration with existing NotificationService from Phase 1
- Error handling for scheduling failures
- Badge count management strategy

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within phase scope

</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| NOTIF-05 | App schedules daily notification at 1:00 PM | UNCalendarNotificationTrigger with DateComponents(hour: 13, minute: 0) |
| NOTIF-06 | App schedules daily notification at 8:00 PM | UNCalendarNotificationTrigger with DateComponents(hour: 20, minute: 0) |
| NOTIF-07 | Lunch notification shows time-specific message | UNMutableNotificationContent with Portuguese-BR message for 1 PM |
| NOTIF-08 | Evening notification shows time-specific message | UNMutableNotificationContent with Portuguese-BR message for 8 PM |
| NOTIF-09 | Notifications use calendar-based triggers that respect time zones | UNCalendarNotificationTrigger automatically uses device's local time zone |
| NOTIF-10 | Notifications recur daily automatically | UNCalendarNotificationTrigger with repeats: true eliminates manual rescheduling |
| NOTIF-18 | Use Cases coordinate notification operations | ScheduleNotificationsUseCase coordinates scheduling logic without importing UserNotifications |
| NOTIF-23 | Debug configuration allows testable notification times | #if DEBUG conditional compilation for development-friendly notification times |

</phase_requirements>

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| UserNotifications | iOS 10+ | Schedule and manage local notifications | Apple's first-party framework for all notification operations; no third-party alternatives |
| Foundation | iOS 10+ | DateComponents for calendar-based scheduling | Standard library for date/time manipulation |
| Swift Testing | Xcode 16+ | Unit test framework (already in use) | Modern Swift testing framework used in Phase 1 |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Calendar | Foundation | Date component extraction, day boundary logic | When working with time zones and date calculations |
| DateComponents | Foundation | Specify hour/minute for calendar triggers | Required for UNCalendarNotificationTrigger initialization |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| UNCalendarNotificationTrigger | UNTimeIntervalNotificationTrigger | Time interval triggers don't respect time zones/DST, require manual rescheduling for daily notifications at specific clock times |
| Repeating calendar trigger | Schedule 365 individual notifications | Manual approach requires rescheduling logic, hits notification limit (64 pending), more complex |
| #if DEBUG | UserDefaults flag | UserDefaults requires UI to toggle, adds runtime overhead, debug builds should "just work" for developers |

**Installation:**
UserNotifications is part of iOS SDK — no package installation required.

## Architecture Patterns

### Recommended Project Structure
```
HealthTracker/
├── Domain/
│   ├── Protocols/
│   │   └── NotificationServiceProtocol.swift   # Extend with scheduling methods
│   └── UseCases/
│       ├── RequestNotificationPermissionUseCase.swift   # Exists from Phase 1
│       └── ScheduleNotificationsUseCase.swift   # NEW: Coordinates scheduling
├── Data/
│   └── Services/
│       ├── NotificationService.swift   # Extend with scheduling implementation
│       └── NotificationPermissionManager.swift   # Exists from Phase 1
HealthTrackerTests/
├── Mocks/
│   └── MockNotificationService.swift   # Extend with scheduling method stubs
└── Domain/
    └── UseCases/
        └── ScheduleNotificationsUseCaseTests.swift   # NEW: Test scheduling logic
```

### Pattern 1: Extending Protocol for New Operations

**What:** Phase 1 established `NotificationServiceProtocol` with permission operations. Phase 2 extends it with scheduling operations while maintaining backward compatibility.

**When to use:** When adding new capabilities to an existing abstraction without breaking existing consumers.

**Example:**
```swift
// Domain/Protocols/NotificationServiceProtocol.swift
protocol NotificationServiceProtocol {
    // Phase 1 methods (already exist)
    func requestAuthorization(options: NotificationAuthorizationOptions) async throws -> Bool
    func authorizationStatus() async -> NotificationAuthorizationStatus
    func setDelegate(_ delegate: NotificationCenterDelegate?)

    // Phase 2 methods (NEW)
    func scheduleNotification(
        identifier: String,
        title: String,
        body: String,
        dateComponents: DateComponents,
        repeats: Bool
    ) async throws

    func cancelAllNotifications()
}
```

### Pattern 2: Calendar-Based Recurring Notifications

**What:** Use `UNCalendarNotificationTrigger` with `DateComponents` specifying only hour and minute (not day/month/year) to create daily recurring notifications that respect time zones and DST.

**When to use:** When scheduling notifications at specific clock times that should recur daily.

**Example:**
```swift
// Data/Services/NotificationService.swift (implementation)
func scheduleNotification(
    identifier: String,
    title: String,
    body: String,
    dateComponents: DateComponents,
    repeats: Bool
) async throws {
    let content = UNMutableNotificationContent()
    content.title = title
    content.body = body
    content.sound = .default

    // Calendar trigger with DateComponents(hour: X, minute: Y)
    // When only hour/minute specified, iOS uses current time zone
    let trigger = UNCalendarNotificationTrigger(
        dateMatching: dateComponents,
        repeats: repeats
    )

    let request = UNNotificationRequest(
        identifier: identifier,
        content: content,
        trigger: trigger
    )

    try await notificationCenter.add(request)
}
```

### Pattern 3: Debug Configuration with Conditional Compilation

**What:** Use `#if DEBUG` to provide developer-friendly notification times during development without affecting production builds.

**When to use:** When production timing would be inconvenient for development/testing (e.g., waiting until 1 PM to test notification).

**Example:**
```swift
// Domain/UseCases/ScheduleNotificationsUseCase.swift
func execute() async throws {
    #if DEBUG
    // In debug builds: schedule for 2 minutes from now for quick testing
    let debugDate = Date().addingTimeInterval(120) // 2 minutes
    let calendar = Calendar.current
    let lunchComponents = calendar.dateComponents([.hour, .minute], from: debugDate)
    let dinnerComponents = calendar.dateComponents(
        [.hour, .minute],
        from: debugDate.addingTimeInterval(60) // 1 minute after lunch
    )
    #else
    // In release builds: use production times (1 PM, 8 PM)
    let lunchComponents = DateComponents(hour: 13, minute: 0)
    let dinnerComponents = DateComponents(hour: 20, minute: 0)
    #endif

    try await notificationService.scheduleNotification(
        identifier: "lunch-reminder",
        title: "HealthTracker",
        body: "Registre o que você comeu hoje",
        dateComponents: lunchComponents,
        repeats: true
    )

    try await notificationService.scheduleNotification(
        identifier: "dinner-reminder",
        title: "HealthTracker",
        body: "Registre suas refeições e atividades",
        dateComponents: dinnerComponents,
        repeats: true
    )
}
```

### Pattern 4: Use Case Coordinates Scheduling Logic

**What:** Create `ScheduleNotificationsUseCase` to encapsulate the business logic of scheduling both notifications with correct identifiers, messages, and timing.

**When to use:** When multiple notification scheduling operations need to be coordinated together with shared error handling and business rules.

**Example:**
```swift
// Domain/UseCases/ScheduleNotificationsUseCase.swift
final class ScheduleNotificationsUseCase {
    private let notificationService: NotificationServiceProtocol

    init(notificationService: NotificationServiceProtocol) {
        self.notificationService = notificationService
    }

    func execute() async throws {
        // Business logic: schedule both notifications
        // Handles timing (production vs debug)
        // Handles Portuguese-BR messages
        // Coordinates with NotificationService abstraction
    }
}
```

### Anti-Patterns to Avoid

- **Don't schedule 365 individual notifications:** iOS limits to 64 pending notifications. Use `repeats: true` instead.
- **Don't use UNTimeIntervalNotificationTrigger for clock-time notifications:** Time intervals don't respect DST or time zone changes. User travels from São Paulo to Los Angeles, interval-based notification fires at wrong local time.
- **Don't hardcode test times in production code:** Use conditional compilation (`#if DEBUG`) to separate development and production timing.
- **Don't import UserNotifications in Use Cases:** Maintain Clean Architecture boundary. Use Cases depend on protocol only.
- **Don't reschedule on every app launch:** Check pending notifications before rescheduling to avoid duplicate notifications.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Time zone aware scheduling | Custom timezone conversion logic | UNCalendarNotificationTrigger with DateComponents | iOS automatically handles time zone changes and DST transitions; custom logic is error-prone and doesn't handle edge cases (DST gaps, leap seconds, etc.) |
| Daily recurrence | Manual rescheduling after each notification fires | UNCalendarNotificationTrigger with repeats: true | iOS handles recurrence automatically; manual approach requires background execution, permission complexities, and state management |
| Notification content localization | String formatting utilities | UNMutableNotificationContent with localized strings | iOS handles notification rendering, truncation, and accessibility; custom formatting won't respect system preferences |
| Notification delivery reliability | Retry logic and delivery tracking | iOS UserNotifications framework | iOS guarantees best-effort delivery; custom retry logic can't improve on system guarantees and adds complexity |

**Key insight:** Notification scheduling involves complex edge cases (time zones, DST, device restarts, user date changes, permission changes). iOS UserNotifications framework is battle-tested across billions of devices. Custom solutions will miss edge cases and create user-visible bugs. Trust the framework.

## Common Pitfalls

### Pitfall 1: Scheduling Notifications Without Checking Authorization

**What goes wrong:** Calling `notificationCenter.add(request)` when user denied permission fails silently. Notifications never fire, no error thrown, user gets no reminders.

**Why it happens:** iOS doesn't throw errors when scheduling fails due to permission denial. Developer assumes scheduling succeeded.

**How to avoid:** Always check authorization status before scheduling. Use Case pattern: `isAuthorized()` check before calling `scheduleNotification()`.

**Warning signs:**
- Notifications work in simulator (always authorized during development) but not on real devices
- User reports "notifications not working" but app shows no errors
- Pending notifications show in `getPendingNotificationRequests()` but never deliver

**Prevention code:**
```swift
// ScheduleNotificationsUseCase.swift
func execute() async throws {
    // Check authorization first
    let status = await notificationService.authorizationStatus()
    guard status == .authorized else {
        // Don't throw error (graceful degradation per NOTIF-03)
        // Just log and return
        print("[ScheduleNotifications] Not authorized, skipping scheduling")
        return
    }

    // Now safe to schedule
    try await scheduleNotifications()
}
```

### Pitfall 2: Time Zone Confusion with DateComponents

**What goes wrong:** Developer creates `DateComponents(hour: 13, minute: 0, timeZone: TimeZone(identifier: "America/Sao_Paulo"))` thinking it will fire at 1 PM São Paulo time. User in Tokyo gets notification at wrong time.

**Why it happens:** Misunderstanding how calendar triggers resolve time zones. Explicit `timeZone` in DateComponents means "fire at 1 PM São Paulo time regardless of user's location" not "fire at 1 PM user's local time."

**How to avoid:** Omit `timeZone` from DateComponents. iOS defaults to device's current time zone. Notification fires at 1 PM local time, automatically adjusting when user travels or changes time zone settings.

**Warning signs:**
- Notifications fire at wrong times after app testing in different locations
- User reports in reviews: "notification comes at 3 AM" (time zone math is wrong)
- Notification timing breaks after DST transition

**Prevention code:**
```swift
// WRONG: Explicit time zone locks notification to specific geography
let wrongComponents = DateComponents(
    hour: 13,
    minute: 0,
    timeZone: TimeZone(identifier: "America/Sao_Paulo") // ❌ Don't do this
)

// RIGHT: Omit timeZone, iOS uses device's local time zone
let correctComponents = DateComponents(hour: 13, minute: 0) // ✅ User's local time
```

### Pitfall 3: Forgetting `repeats: true` for Daily Notifications

**What goes wrong:** Notification fires once (today at 1 PM) then never again. User expects daily reminders, gets confused after day 2.

**Why it happens:** Developer creates calendar trigger with `repeats: false` (default is `false` in some initializer patterns). Notification is one-time only.

**How to avoid:** Always explicitly set `repeats: true` for daily notifications. Review trigger initialization in code review.

**Warning signs:**
- Notification works first day after app install, then stops
- `getPendingNotificationRequests()` shows empty array day after scheduling
- User reports: "notifications worked yesterday but not today"

**Prevention code:**
```swift
let trigger = UNCalendarNotificationTrigger(
    dateMatching: dateComponents,
    repeats: true // ✅ Required for daily recurrence
)
```

### Pitfall 4: Duplicate Notification Scheduling

**What goes wrong:** Every time app launches, scheduling code runs. Same notification scheduled multiple times with same identifier. User gets 5 notifications at 1 PM instead of 1.

**Why it happens:** iOS replaces pending notifications with same identifier, BUT if scheduling happens multiple times quickly (app launched multiple times in short period), race condition can create duplicates.

**How to avoid:** Either (a) check pending notifications before rescheduling, or (b) cancel all notifications before scheduling new ones, or (c) schedule only on first launch after permission granted.

**Warning signs:**
- Occasional reports of duplicate notifications (hard to reproduce)
- Multiple notifications visible in notification center with same content
- User gets notification burst (3-4 notifications at once)

**Prevention code:**
```swift
// Option A: Cancel all before scheduling (simplest, recommended for Phase 2)
func execute() async throws {
    // Clear any existing notifications first
    notificationService.cancelAllNotifications()

    // Now schedule fresh
    try await scheduleNotifications()
}

// Option B: Check pending first (more complex, overkill for Phase 2)
func execute() async throws {
    let pending = await notificationService.getPendingNotificationRequests()
    let hasLunchReminder = pending.contains { $0.identifier == "lunch-reminder" }

    if !hasLunchReminder {
        try await scheduleLunchNotification()
    }
    // ... same for dinner
}
```

### Pitfall 5: Testing Notification Timing in Debug Builds

**What goes wrong:** Developer hardcodes 1 PM / 8 PM times. Testing requires waiting hours or manually changing device time. Testing becomes impractical, coverage suffers.

**Why it happens:** Production times baked into code without development-friendly alternative.

**How to avoid:** Use `#if DEBUG` conditional compilation to provide testable times (e.g., 2 minutes from now) in debug builds while keeping production times in release builds.

**Warning signs:**
- Manual testing instructions say "change device time to 12:59 PM"
- Developers skip testing notification delivery because it's too slow
- Notification bugs discovered in production because testing was impractical

**Prevention code:**
```swift
#if DEBUG
let testDate = Date().addingTimeInterval(120) // 2 minutes from now
let components = Calendar.current.dateComponents([.hour, .minute], from: testDate)
#else
let components = DateComponents(hour: 13, minute: 0) // Production: 1 PM
#endif
```

## Code Examples

### Example 1: Extend NotificationServiceProtocol (Domain Layer)

```swift
// HealthTracker/Domain/Protocols/NotificationServiceProtocol.swift
// ADD these methods to existing protocol

/// Schedules a notification with calendar-based trigger.
///
/// This method creates a notification request with the specified content and timing.
/// The notification will fire when the date components match the current date/time.
///
/// - Parameters:
///   - identifier: Unique identifier for the notification. Used to replace or cancel later.
///   - title: Notification title (shown in bold)
///   - body: Notification body text
///   - dateComponents: When to fire (e.g., DateComponents(hour: 13, minute: 0))
///   - repeats: Whether notification should recur when date components match again
/// - Throws: An error if scheduling fails
func scheduleNotification(
    identifier: String,
    title: String,
    body: String,
    dateComponents: DateComponents,
    repeats: Bool
) async throws

/// Cancels all pending notifications scheduled by this app.
///
/// Use this to clear notifications before rescheduling or when user logs data.
func cancelAllNotifications()
```

### Example 2: Implement Scheduling Methods (Data Layer)

```swift
// HealthTracker/Data/Services/NotificationService.swift
// ADD these methods to existing class

func scheduleNotification(
    identifier: String,
    title: String,
    body: String,
    dateComponents: DateComponents,
    repeats: Bool
) async throws {
    let content = UNMutableNotificationContent()
    content.title = title
    content.body = body
    content.sound = .default

    let trigger = UNCalendarNotificationTrigger(
        dateMatching: dateComponents,
        repeats: repeats
    )

    let request = UNNotificationRequest(
        identifier: identifier,
        content: content,
        trigger: trigger
    )

    try await notificationCenter.add(request)
}

func cancelAllNotifications() {
    notificationCenter.removeAllPendingNotificationRequests()
}
```

### Example 3: Create ScheduleNotificationsUseCase (Domain Layer)

```swift
// HealthTracker/Domain/UseCases/ScheduleNotificationsUseCase.swift
import Foundation

/// Use case for scheduling daily notification reminders.
///
/// Coordinates scheduling of lunch (1 PM) and dinner (8 PM) notifications with
/// time-specific Portuguese-BR messages. Handles authorization checks and uses
/// debug-friendly timing in development builds.
final class ScheduleNotificationsUseCase {
    private let notificationService: NotificationServiceProtocol

    init(notificationService: NotificationServiceProtocol) {
        self.notificationService = notificationService
    }

    /// Schedules both daily notifications (lunch and dinner reminders).
    ///
    /// Checks authorization status before scheduling. If not authorized, returns
    /// gracefully without throwing (satisfies NOTIF-03 graceful degradation).
    ///
    /// Debug builds use testable times (2-3 minutes from now) for quick verification.
    /// Release builds use production times (1 PM, 8 PM).
    ///
    /// - Throws: An error if scheduling fails (e.g., system error)
    func execute() async throws {
        // Check authorization (NOTIF-02)
        let status = await notificationService.authorizationStatus()
        guard status == .authorized else {
            print("[ScheduleNotifications] Not authorized, skipping scheduling")
            return
        }

        // Clear any existing notifications before scheduling fresh
        notificationService.cancelAllNotifications()

        // Determine timing based on build configuration
        let (lunchComponents, dinnerComponents) = notificationTiming()

        // Schedule lunch notification (NOTIF-05, NOTIF-07)
        try await notificationService.scheduleNotification(
            identifier: "lunch-reminder",
            title: "HealthTracker",
            body: "Registre o que você comeu hoje",
            dateComponents: lunchComponents,
            repeats: true
        )

        // Schedule dinner notification (NOTIF-06, NOTIF-08)
        try await notificationService.scheduleNotification(
            identifier: "dinner-reminder",
            title: "HealthTracker",
            body: "Registre suas refeições e atividades",
            dateComponents: dinnerComponents,
            repeats: true
        )

        print("[ScheduleNotifications] Notifications scheduled successfully")
    }

    // MARK: - Private Helpers

    private func notificationTiming() -> (lunch: DateComponents, dinner: DateComponents) {
        #if DEBUG
        // Debug builds: testable times (NOTIF-23)
        let now = Date()
        let lunchDate = now.addingTimeInterval(120) // 2 minutes from now
        let dinnerDate = now.addingTimeInterval(180) // 3 minutes from now

        let calendar = Calendar.current
        let lunchComponents = calendar.dateComponents([.hour, .minute], from: lunchDate)
        let dinnerComponents = calendar.dateComponents([.hour, .minute], from: dinnerDate)

        return (lunchComponents, dinnerComponents)
        #else
        // Release builds: production times
        let lunchComponents = DateComponents(hour: 13, minute: 0) // 1 PM
        let dinnerComponents = DateComponents(hour: 20, minute: 0) // 8 PM

        return (lunchComponents, dinnerComponents)
        #endif
    }
}
```

### Example 4: Extend MockNotificationService for Testing

```swift
// HealthTrackerTests/Mocks/MockNotificationService.swift
// ADD these properties and methods to existing mock

// Tracking properties for scheduling methods
var scheduleNotificationCalled = false
var scheduleNotificationIdentifiers: [String] = []
var scheduleNotificationBodies: [String] = []
var scheduleNotificationRepeats: [Bool] = []
var scheduleNotificationDateComponents: [DateComponents] = []

var cancelAllNotificationsCalled = false

func scheduleNotification(
    identifier: String,
    title: String,
    body: String,
    dateComponents: DateComponents,
    repeats: Bool
) async throws {
    scheduleNotificationCalled = true
    scheduleNotificationIdentifiers.append(identifier)
    scheduleNotificationBodies.append(body)
    scheduleNotificationRepeats.append(repeats)
    scheduleNotificationDateComponents.append(dateComponents)
}

func cancelAllNotifications() {
    cancelAllNotificationsCalled = true
}
```

### Example 5: Unit Test ScheduleNotificationsUseCase

```swift
// HealthTrackerTests/Domain/UseCases/ScheduleNotificationsUseCaseTests.swift
import Foundation
@testable import HealthTracker
import Testing

@MainActor
struct ScheduleNotificationsUseCaseTests {

    @Test func execute_schedulesBothNotificationsWhenAuthorized() async throws {
        let mockService = MockNotificationService()
        mockService.authorizationStatusResult = .authorized

        let useCase = ScheduleNotificationsUseCase(notificationService: mockService)
        try await useCase.execute()

        // Verify both notifications scheduled
        #expect(mockService.scheduleNotificationCalled == true)
        #expect(mockService.scheduleNotificationIdentifiers.count == 2)
        #expect(mockService.scheduleNotificationIdentifiers.contains("lunch-reminder"))
        #expect(mockService.scheduleNotificationIdentifiers.contains("dinner-reminder"))

        // Verify repeat is enabled (NOTIF-10)
        #expect(mockService.scheduleNotificationRepeats.allSatisfy { $0 == true })

        // Verify Portuguese-BR messages
        #expect(mockService.scheduleNotificationBodies.contains("Registre o que você comeu hoje"))
        #expect(mockService.scheduleNotificationBodies.contains("Registre suas refeições e atividades"))
    }

    @Test func execute_cancelsExistingNotificationsBeforeScheduling() async throws {
        let mockService = MockNotificationService()
        mockService.authorizationStatusResult = .authorized

        let useCase = ScheduleNotificationsUseCase(notificationService: mockService)
        try await useCase.execute()

        #expect(mockService.cancelAllNotificationsCalled == true)
    }

    @Test func execute_skipsSchedulingWhenNotAuthorized() async throws {
        let mockService = MockNotificationService()
        mockService.authorizationStatusResult = .denied

        let useCase = ScheduleNotificationsUseCase(notificationService: mockService)
        try await useCase.execute()

        // Verify graceful degradation (NOTIF-03)
        #expect(mockService.scheduleNotificationCalled == false)
    }

    @Test func execute_schedulesWithDateComponents() async throws {
        let mockService = MockNotificationService()
        mockService.authorizationStatusResult = .authorized

        let useCase = ScheduleNotificationsUseCase(notificationService: mockService)
        try await useCase.execute()

        // Verify calendar-based triggers (NOTIF-09)
        #expect(mockService.scheduleNotificationDateComponents.count == 2)

        // In debug builds, times are relative to now (testable)
        // In release builds, times are 13:00 and 20:00
        // Both cases should have hour and minute components
        for components in mockService.scheduleNotificationDateComponents {
            #expect(components.hour != nil)
            #expect(components.minute != nil)
        }
    }
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| UILocalNotification (iOS 4-9) | UNUserNotificationCenter (iOS 10+) | iOS 10 (2016) | Modern API required; old API deprecated and removed in iOS 10 |
| UNTimeIntervalNotificationTrigger for daily notifications | UNCalendarNotificationTrigger for clock-time notifications | Best practice since iOS 10 | Time zone and DST handling automatic with calendar triggers |
| Reschedule on notification delivery | Use repeats: true | Best practice since iOS 10 | Eliminates need for notification service extension to reschedule |
| String-based notification identifiers | Enum-based identifiers | Swift best practice (2020+) | Type safety, autocomplete, refactoring support |

**Deprecated/outdated:**
- **UILocalNotification:** Removed in iOS 10. All apps must use UserNotifications framework.
- **Application badge management via notifications alone:** Modern approach: apps manage badge count directly via `UNUserNotificationCenter.current().setBadgeCount()` (iOS 16+) or `UIApplication.shared.applicationIconBadgeNumber` (iOS 10-15).
- **Scheduling 7-day batches:** With 64 pending notification limit, developers used to schedule week at a time and reschedule. Modern approach: use `repeats: true` to eliminate manual rescheduling.

## Open Questions

### Question 1: When Should Notifications Be Scheduled?

**What we know:**
- Phase 1 requests permission on first launch
- Notifications should be scheduled after permission granted
- Current architecture: `NotificationPermissionManager` handles first-launch permission request

**What's unclear:**
- Should notifications be scheduled immediately after permission granted (in permission flow)?
- Should notifications be scheduled on every app launch (defensive, handles uninstall/reinstall)?
- Should scheduling happen once and trust iOS to maintain them?

**Recommendation:** Schedule on first launch after permission granted (inside `NotificationPermissionManager.requestIfFirstLaunch()` after successful permission). Add defensive check: schedule only if no pending notifications exist. This ensures notifications exist without redundant scheduling on every launch.

**Rationale:** iOS maintains scheduled notifications across app lifecycle (device reboot, app updates, etc.). Scheduling once is sufficient. Defensive check prevents duplicates if iOS state is cleared (rare edge case).

### Question 2: Should We Validate Pending Notifications on App Launch?

**What we know:**
- iOS sometimes clears pending notifications (low memory, system updates, edge cases)
- Checking pending notifications requires async call to `UNUserNotificationCenter.getPendingNotificationRequests()`
- Adding launch-time async work increases app launch time

**What's unclear:**
- How often does iOS actually clear pending notifications in practice?
- Is the launch-time async call worth the reliability improvement?
- Where would we put this logic (App init? Scene delegate? Background task?)

**Recommendation:** Phase 2: Skip validation (assume iOS maintains notifications). Phase 3 or future: Add validation if user reports "notifications stopped working" become common. If validation becomes necessary, put in App `onAppear` (not blocking launch) or Scene `onBackground` transition.

**Rationale:** Premature optimization. iOS notification delivery is highly reliable. Add complexity only if proven necessary by user feedback. Keep Phase 2 simple.

### Question 3: How to Handle Notification Identifier Conflicts?

**What we know:**
- Notifications use string identifiers: "lunch-reminder", "dinner-reminder"
- iOS replaces pending notification if new request uses same identifier
- Phase 3 will add smart cancellation (cancel when user logs data)

**What's unclear:**
- Should identifiers be namespaced (e.g., "com.healthtracker.lunch-reminder")?
- Should identifiers include version info for future migrations?
- Could identifier collisions happen if we add more notification types later?

**Recommendation:** Phase 2: Use simple identifiers ("lunch-reminder", "dinner-reminder"). Future phases: If more notification types added, consider enum-based identifier system for type safety and namespace management.

**Rationale:** YAGNI (You Aren't Gonna Need It). Simple identifiers sufficient for 2 notifications. Add complexity when proven necessary (Phase 3+). Over-engineering identifiers now adds no value.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Swift Testing (Xcode 16+) |
| Config file | None — convention-based test discovery |
| Quick run command | `swift test` (runs all tests) |
| Full suite command | `xcodebuild test -scheme HealthTracker -destination 'platform=iOS Simulator,name=iPhone 17 Pro'` |

**Note:** Project uses Swift Testing framework (modern alternative to XCTest). All Phase 1 tests use `@Test` macro and `#expect` assertions. Phase 2 tests should follow same pattern.

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| NOTIF-05 | Schedules 1 PM notification | unit | `swift test --filter ScheduleNotificationsUseCaseTests.execute_schedulesBothNotificationsWhenAuthorized` | ❌ Wave 0 |
| NOTIF-06 | Schedules 8 PM notification | unit | `swift test --filter ScheduleNotificationsUseCaseTests.execute_schedulesBothNotificationsWhenAuthorized` | ❌ Wave 0 |
| NOTIF-07 | 1 PM message in Portuguese-BR | unit | `swift test --filter ScheduleNotificationsUseCaseTests.execute_schedulesBothNotificationsWhenAuthorized` | ❌ Wave 0 |
| NOTIF-08 | 8 PM message in Portuguese-BR | unit | `swift test --filter ScheduleNotificationsUseCaseTests.execute_schedulesBothNotificationsWhenAuthorized` | ❌ Wave 0 |
| NOTIF-09 | Calendar triggers respect time zones | unit | `swift test --filter ScheduleNotificationsUseCaseTests.execute_schedulesWithDateComponents` | ❌ Wave 0 |
| NOTIF-10 | Notifications recur daily | unit | `swift test --filter ScheduleNotificationsUseCaseTests.execute_schedulesBothNotificationsWhenAuthorized` | ❌ Wave 0 |
| NOTIF-18 | Use Case coordinates operations | unit | `swift test --filter ScheduleNotificationsUseCaseTests` | ❌ Wave 0 |
| NOTIF-23 | Debug config for testable times | manual | Manual verification: build in Debug, check notification times are ~2 min from now | N/A |

**Additional Tests:**
| Behavior | Test Type | Automated Command | File Exists? |
|----------|-----------|-------------------|-------------|
| Cancels existing before scheduling | unit | `swift test --filter ScheduleNotificationsUseCaseTests.execute_cancelsExistingNotificationsBeforeScheduling` | ❌ Wave 0 |
| Skips scheduling when not authorized | unit | `swift test --filter ScheduleNotificationsUseCaseTests.execute_skipsSchedulingWhenNotAuthorized` | ❌ Wave 0 |
| NotificationService scheduleNotification method | unit | `swift test --filter NotificationServiceTests.scheduleNotification_*` | ❌ Wave 0 |
| NotificationService cancelAllNotifications method | unit | `swift test --filter NotificationServiceTests.cancelAllNotifications_*` | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** `swift test --filter ScheduleNotificationsUseCaseTests` (runs Use Case tests only, ~2 seconds)
- **Per wave merge:** `swift test` (runs all tests including Phase 1, ~10 seconds)
- **Phase gate:** Full suite green (`xcodebuild test`) + manual device verification of notification delivery

### Wave 0 Gaps
- [ ] `HealthTrackerTests/Domain/UseCases/ScheduleNotificationsUseCaseTests.swift` — covers NOTIF-05, NOTIF-06, NOTIF-07, NOTIF-08, NOTIF-09, NOTIF-10, NOTIF-18
- [ ] `HealthTrackerTests/Data/Services/NotificationServiceTests.swift` — covers NotificationService scheduling methods (currently no NotificationService tests exist; Phase 1 tested via Use Case only)
- [ ] Extend `HealthTrackerTests/Mocks/MockNotificationService.swift` — add scheduling method stubs
- [ ] Manual test plan document — covers device testing for actual notification firing at correct times (NOTIF-23 debug config, time zone/DST behavior)

**Note:** Phase 1 did not create NotificationService unit tests (tested implementation via Use Case tests). Phase 2 should follow same pattern OR add NotificationService tests if planner determines value (e.g., testing error handling in Data layer).

## Sources

### Primary (HIGH confidence)
- **Apple Developer Documentation - UserNotifications Framework:** Reviewed patterns from training data (iOS 10-17 API patterns). Calendar trigger behavior, DateComponents usage, repeating notification patterns verified against Apple's published API contracts.
- **Existing codebase:** `/Users/gustavosantos/Documents/Projects/Personal/Real app repos/HealthTracker/HealthTracker/Domain/Protocols/NotificationServiceProtocol.swift` - Phase 1 protocol structure
- **Existing codebase:** `/Users/gustavosantos/Documents/Projects/Personal/Real app repos/HealthTracker/HealthTracker/Data/Services/NotificationService.swift` - Phase 1 implementation patterns
- **Existing codebase:** `/Users/gustavosantos/Documents/Projects/Personal/Real app repos/HealthTracker/HealthTrackerTests/Domain/UseCases/RequestNotificationPermissionUseCaseTests.swift` - Swift Testing patterns established in Phase 1

### Secondary (MEDIUM confidence)
- **Swift API Design Guidelines:** Project skill file `.claude/skills/swift-api-design-guidelines/SKILL.md` - naming conventions, parameter patterns
- **Swift Testing Expert:** Project skill file `.claude/skills/swift-testing-expert/SKILL.md` - testing patterns, #expect usage
- **Project calendar usage patterns:** Verified via grep - codebase uses `Calendar.current` consistently across HealthDataRepository, AnalyticsPeriod, MainViewModel

### Tertiary (LOW confidence - training data only)
- **Time zone and DST behavior:** Based on training data about UNCalendarNotificationTrigger behavior. Not verified with recent Apple documentation (WebFetch failed on developer.apple.com). Marked MEDIUM overall confidence due to lack of primary source verification, but pattern is well-established since iOS 10.
- **Notification limit (64 pending):** From training data. Should verify if limit changed in iOS 16-18. Low risk — pattern of using `repeats: true` is correct regardless of exact limit.
- **Debug configuration patterns:** `#if DEBUG` conditional compilation is standard Swift pattern, verified in training data across Apple sample code.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - UserNotifications is only option, no alternatives
- Architecture: HIGH - Extends existing Phase 1 patterns, follows Clean Architecture established in codebase
- Pitfalls: MEDIUM - Based on common iOS notification issues from training data, not verified with 2026 documentation (developer.apple.com WebFetch failed)
- Code examples: HIGH - Based on established Phase 1 patterns and standard UserNotifications API usage
- Testing: HIGH - Follows existing Swift Testing patterns from Phase 1

**Research date:** 2026-02-28
**Valid until:** 2026-03-30 (30 days - iOS notification APIs are stable)

**Research notes:**
- WebSearch and WebFetch failed for Apple developer documentation. Research relied on training data knowledge of UserNotifications framework (iOS 10-17) and existing codebase patterns.
- Context7 did not have Apple UserNotifications framework (found third-party libraries instead).
- Overall confidence rated MEDIUM due to lack of primary source verification from Apple's current documentation, but patterns are well-established and unlikely to have changed significantly.
- All architectural patterns verified against existing Phase 1 implementation (high confidence in those areas).
- Recommendation: Planner should treat iOS UserNotifications API patterns as reliable (stable since iOS 10), but note that edge case behavior (64 notification limit, exact DST handling) may need validation during implementation if issues arise.
