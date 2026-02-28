# Stack Research

**Domain:** iOS Local Notifications for Health Tracking App
**Researched:** 2026-02-28
**Confidence:** HIGH

## Recommended Stack

### Core Technologies

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| UserNotifications | iOS 26.0+ | Local notification scheduling, permission management, notification delivery | Native iOS framework, zero dependencies, full Swift 6 concurrency support, standard solution for all iOS apps since iOS 10 |
| UNUserNotificationCenter | iOS 26.0+ | Central manager for all notification operations | Singleton pattern, thread-safe, modern async/await APIs added in iOS 15+, fully compatible with Swift 6 strict concurrency |
| UNMutableNotificationContent | iOS 26.0+ | Notification content (title, body, sound, badge) | Standard iOS API for defining notification appearance and behavior |
| UNCalendarNotificationTrigger | iOS 26.0+ | Time-based notification scheduling | Repeating daily notifications at specific times (1 PM, 8 PM), more reliable than UNTimeIntervalNotificationTrigger for fixed times |

### Supporting Components

| Component | Version | Purpose | When to Use |
|-----------|---------|---------|-------------|
| UNNotificationRequest | iOS 26.0+ | Wraps content + trigger + unique identifier | Every notification schedule operation, identifier enables cancellation/rescheduling |
| UNUserNotificationCenterDelegate | iOS 26.0+ | Handle notification presentation and user responses | When app needs to respond to notification taps or customize in-app presentation |
| DateComponents | Foundation | Specify exact notification times (hour/minute) | Required by UNCalendarNotificationTrigger for daily repeating notifications |
| UNAuthorizationOptions | iOS 26.0+ | Define requested permissions (.alert, .sound, .badge) | First launch permission request, use .alert + .sound (badge not needed for this use case) |

### Architecture Integration

| Pattern | Purpose | Implementation Layer |
|---------|---------|---------------------|
| NotificationManager / NotificationService | Encapsulate UserNotifications APIs | Domain layer (new service protocol) or Data layer (concrete implementation) |
| Use Case pattern | Schedule/cancel notifications as business operations | Domain/UseCases (e.g., ScheduleNotificationsUseCase, CancelNotificationsUseCase) |
| Repository pattern | Abstract notification persistence/state if needed | Not required - UserNotifications manages its own state |
| Dependency Injection | Inject notification service into ViewModels | Existing pattern - inject into MainViewModel or App initialization |

## Installation

```swift
// No installation required - UserNotifications is a native iOS framework
// Simply import in relevant files:

import UserNotifications
```

## Alternatives Considered

| Recommended | Alternative | When to Use Alternative |
|-------------|-------------|-------------------------|
| UserNotifications (local) | Push Notifications (remote via APNs) | Only if notifications need to be triggered by external server events. Not needed for fixed daily reminders based on local app state. |
| UNCalendarNotificationTrigger | UNTimeIntervalNotificationTrigger | Never for this use case. TimeInterval cannot guarantee notifications at 1 PM / 8 PM daily - only delays from scheduling time. |
| Native UserNotifications | Third-party notification libraries (OneSignal, Pushwoosh) | Never for local-only notifications. These are for remote push, analytics, and A/B testing - massive overkill and violates no-dependencies constraint. |
| Swift 6 async/await APIs | Completion handler APIs | Never in new code. Completion handlers are legacy (pre-iOS 15), harder to reason about, and incompatible with Swift 6 strict concurrency. |

## What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| UILocalNotification | Deprecated since iOS 10 (2016), removed in iOS 10+ | UserNotifications framework (UNUserNotificationCenter) |
| UNTimeIntervalNotificationTrigger for daily reminders | Cannot schedule at specific clock times, only relative delays | UNCalendarNotificationTrigger with DateComponents |
| UNLocationNotificationTrigger | Not relevant for time-based reminders, requires location permissions | UNCalendarNotificationTrigger |
| Completion handler APIs (requestAuthorization with closure) | Legacy pre-Swift concurrency, harder to test, not compatible with Swift 6 strict concurrency | Async/await variants: `requestAuthorization(options:) async throws -> Bool` |
| Storing notification state in UserDefaults/iCloud | UserNotifications framework already manages pending notification state | Use `getPendingNotificationRequests() async -> [UNNotificationRequest]` to query |
| Badge numbers for this use case | App doesn't use badge to show unread counts, unnecessary permission request | Omit .badge from UNAuthorizationOptions |

## Stack Patterns by Use Case

**Permission Request (First Launch):**
```swift
let center = UNUserNotificationCenter.current()
let authorized = try await center.requestAuthorization(options: [.alert, .sound])
// Returns Bool indicating granted/denied
```

**Daily Notification Scheduling (1 PM):**
```swift
let content = UNMutableNotificationContent()
content.title = "Time to log your lunch!"
content.body = "Don't forget to track your meals and health data"
content.sound = .default

var dateComponents = DateComponents()
dateComponents.hour = 13  // 1 PM
dateComponents.minute = 0

let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
let request = UNNotificationRequest(identifier: "lunch-reminder", content: content, trigger: trigger)

try await center.add(request)
```

**Cancel Notifications (User Logged Data):**
```swift
// Cancel specific notifications
center.removePendingNotificationRequests(withIdentifiers: ["lunch-reminder", "evening-reminder"])

// Or check what's pending first
let pending = await center.pendingNotificationRequests()
// Filter and cancel selectively
```

**Query Pending Notifications:**
```swift
let pending = await center.pendingNotificationRequests()
// Returns [UNNotificationRequest] - all scheduled but not yet delivered
```

## Clean Architecture Integration Pattern

**Domain Layer:**
- Protocol: `NotificationServiceProtocol` (defines schedule/cancel/checkAuthorization operations)
- Use Cases: `ScheduleNotificationsUseCase`, `CancelNotificationsUseCase`, `RequestNotificationPermissionUseCase`

**Data Layer:**
- Implementation: `NotificationService: NotificationServiceProtocol` (wraps UNUserNotificationCenter)
- No repository needed - UserNotifications is stateless from app perspective

**Presentation Layer:**
- ViewModel calls Use Cases when data is logged (triggers cancellation)
- App initialization calls Use Case to schedule on first launch / ensure scheduled

**Why This Pattern:**
- Maintains existing Clean Architecture
- Testable - mock NotificationServiceProtocol in tests
- No external dependencies
- Domain layer stays framework-agnostic (protocol abstraction)

## Swift 6 Concurrency Considerations

**Thread Safety:**
- UNUserNotificationCenter is thread-safe, safe to call from any context
- All modern async APIs are nonisolated, work in any async context

**Sendable Conformance:**
- UNNotificationRequest, UNNotificationContent are Sendable
- Safe to pass across concurrency domains

**MainActor:**
- UserNotifications APIs do NOT require @MainActor
- Can be called from background tasks, use cases
- Only UI updates (ViewModel state) need @MainActor

**Observation Framework:**
- Existing @Observable ViewModels compatible
- Notification operations can be called from ViewModel methods
- No special handling needed beyond existing patterns

## Version Compatibility

| iOS Version | UserNotifications API | Notes |
|-------------|----------------------|-------|
| iOS 26.0 | Full support | Project minimum target, all modern APIs available |
| iOS 15.0+ | Async/await APIs added | requestAuthorization, add, getPendingNotificationRequests all have async variants |
| iOS 10.0+ | UserNotifications introduced | Calendar triggers, local notifications, permission model |
| iOS 9.x and earlier | UILocalNotification (deprecated) | Not compatible, not relevant for iOS 26 target |

**Key Insight:** Since project targets iOS 26.0 minimum, ALL modern UserNotifications APIs with async/await are available. No compatibility shims needed.

## Testing Strategy

**Mock Protocol:**
```swift
protocol NotificationServiceProtocol {
    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool
    func scheduleNotification(identifier: String, content: UNNotificationContent, trigger: UNNotificationTrigger?) async throws
    func cancelNotifications(withIdentifiers: [String])
    func getPendingNotificationRequests() async -> [UNNotificationRequest]
}
```

**Mock Implementation:**
```swift
final class MockNotificationService: NotificationServiceProtocol {
    var authorizationResult: Bool = true
    var scheduledNotifications: [String: (UNNotificationContent, UNNotificationTrigger?)] = [:]

    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool {
        return authorizationResult
    }

    func scheduleNotification(identifier: String, content: UNNotificationContent, trigger: UNNotificationTrigger?) async throws {
        scheduledNotifications[identifier] = (content, trigger)
    }

    func cancelNotifications(withIdentifiers identifiers: [String]) {
        identifiers.forEach { scheduledNotifications.removeValue(forKey: $0) }
    }

    func getPendingNotificationRequests() async -> [UNNotificationRequest] {
        return scheduledNotifications.map { UNNotificationRequest(identifier: $0.key, content: $0.value.0, trigger: $0.value.1) }
    }
}
```

**Use Case Testing:**
```swift
// Test notification scheduling
let mockService = MockNotificationService()
let useCase = ScheduleNotificationsUseCase(notificationService: mockService)
await useCase.execute()
XCTAssertEqual(mockService.scheduledNotifications.count, 2) // lunch + evening
XCTAssertNotNil(mockService.scheduledNotifications["lunch-reminder"])
XCTAssertNotNil(mockService.scheduledNotifications["evening-reminder"])
```

## Notification Identifiers Convention

**Recommended Pattern:**
- `"lunch-reminder"` - 1 PM notification
- `"evening-reminder"` - 8 PM notification

**Why:**
- Human-readable for debugging
- Static identifiers enable easy cancellation
- No need for dynamic IDs - same notification repeats daily

## Performance Considerations

**Scheduling Cost:**
- Negligible - scheduling is instant, stored by system
- Safe to call repeatedly (replaces existing notification with same ID)

**Query Cost:**
- `getPendingNotificationRequests()` is async but fast (< 10ms typically)
- System-level cache, no file I/O from app perspective

**Memory:**
- Zero ongoing memory cost - notifications managed by system
- No background tasks, timers, or observers needed

**Battery:**
- Zero battery impact - system handles all timing
- No need for app to remain active or run background tasks

## Privacy & Permissions

**Required Permission:**
- UNAuthorizationOptions: [.alert, .sound]
- User must grant explicitly on first request

**Permission Best Practices:**
- Request on first app launch (in App init or MainView.onAppear)
- Explain value before requesting ("We'll remind you to log your health data")
- Handle denial gracefully (continue without notifications, don't nag)

**No Settings UI Needed:**
- User can disable in iOS Settings > HealthTracker > Notifications
- App doesn't need custom settings toggle (matches project requirements)

## Sources

- Apple Developer Documentation: UserNotifications framework (https://developer.apple.com/documentation/usernotifications)
  - Confidence: HIGH (official documentation, iOS 26 compatible)
- Apple Developer Documentation: UNUserNotificationCenter (https://developer.apple.com/documentation/usernotifications/unusernotificationcenter)
  - Confidence: HIGH (official API reference)
- Swift Evolution: Async/await in Swift 5.5+ (https://github.com/apple/swift-evolution/blob/main/proposals/0296-async-await.md)
  - Confidence: HIGH (official language feature, stable since iOS 15)
- Project codebase analysis: Clean Architecture pattern, Swift 6.0, iOS 26.0 target
  - Confidence: HIGH (verified from project files)

---
*Stack research for: iOS Local Notifications*
*Researched: 2026-02-28*
*Confidence: HIGH - Based on official Apple APIs (UserNotifications), verified iOS 26 compatibility, and existing project architecture patterns*
