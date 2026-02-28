# Phase 1: Notification Service Foundation - Research

**Researched:** 2026-02-28
**Domain:** iOS UserNotifications Framework with Clean Architecture Integration
**Confidence:** HIGH

## Summary

Phase 1 establishes the Clean Architecture foundation for notification features in an iOS app, focusing on permission handling and protocol-based abstraction of Apple's UserNotifications framework. This phase requires creating a Domain layer protocol (`NotificationServiceProtocol`) and a Data layer implementation (`NotificationService`) that wraps `UNUserNotificationCenter`, ensuring ViewModels remain decoupled from iOS framework imports.

The research confirms this follows established Clean Architecture patterns in Swift, where the Domain layer defines business contracts through protocols, the Data layer implements concrete wrappers around platform frameworks, and Use Cases coordinate operations. The existing codebase already follows this pattern with `HealthDataRepositoryProtocol` and `HealthDataRepository`, providing a proven blueprint.

**Primary recommendation:** Mirror the existing repository pattern - create `NotificationServiceProtocol` in Domain/Protocols, implement `NotificationService` in Data/Services (new directory), and integrate permission request in `HealthTrackerApp.swift` init similar to existing `DataMigration.migrateIfNeeded()`.

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| NOTIF-01 | App requests notification permission on first launch | Request in App init, status tracking via UserDefaults or first-run detection |
| NOTIF-02 | App checks notification authorization status before scheduling | UNUserNotificationCenter.current().notificationSettings() provides authorizationStatus |
| NOTIF-03 | App handles notification permission denial gracefully | Authorization returns .denied - no crash, log/track for analytics, continue normal operation |
| NOTIF-04 | App configures UNUserNotificationCenter delegate at launch | Set delegate in App init before any notifications scheduled, required for foreground handling |
| NOTIF-15 | Notification logic follows Clean Architecture pattern with protocol abstraction | Domain protocol + Data implementation pattern matches existing HealthDataRepository |
| NOTIF-16 | NotificationServiceProtocol defined in Domain layer | Place in Domain/Protocols/ alongside HealthDataRepositoryProtocol.swift |
| NOTIF-17 | NotificationService implementation in Data layer wraps UserNotifications framework | Create Data/Services/ directory, implement concrete class wrapping UNUserNotificationCenter |
| NOTIF-19 | ViewModels never directly import UserNotifications framework | Use Cases inject NotificationServiceProtocol, ViewModels depend on Use Cases only |
</phase_requirements>

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| UserNotifications | iOS 26.0+ | System notification handling | Native Apple framework, only option for local notifications |
| UNUserNotificationCenter | Built-in | Singleton managing notification requests | Central interface for all notification operations |
| Swift Testing | Built-in | Unit testing framework | Project already uses this (seen in SaveDayDataUseCaseTests.swift) |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Foundation | iOS 26.0+ | Date/Calendar operations | Permission status persistence, date comparisons |
| Combine | iOS 26.0+ | Async operations | Optional - if permission checking needs reactive streams |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| UserNotifications | Third-party libraries (OneSignal, Pushwoosh) | Overkill - these are for push notifications, not local. Adds dependency for features not needed. |
| Protocol abstraction | Direct UNUserNotificationCenter in ViewModels | Violates Clean Architecture, makes testing impossible, couples presentation to iOS framework |

**Installation:**
No installation needed - UserNotifications is part of iOS SDK.

```swift
import UserNotifications // Only in Data layer implementation
```

## Architecture Patterns

### Recommended Project Structure

```
HealthTracker/
├── Domain/
│   ├── Protocols/
│   │   ├── HealthDataRepositoryProtocol.swift (existing)
│   │   └── NotificationServiceProtocol.swift (NEW)
│   └── UseCases/
│       └── RequestNotificationPermissionUseCase.swift (NEW)
├── Data/
│   ├── Repositories/
│   │   └── HealthDataRepository.swift (existing)
│   └── Services/
│       └── NotificationService.swift (NEW - wraps UNUserNotificationCenter)
└── Presentation/
    └── ViewModels/
        └── MainViewModel.swift (existing - will inject Use Case)
```

### Pattern 1: Protocol Abstraction in Domain Layer

**What:** Define notification operations as protocol in Domain layer with no iOS framework imports.

**When to use:** Always - this is the core Clean Architecture pattern.

**Example:**
```swift
// Source: Verified from existing HealthDataRepositoryProtocol.swift pattern + Context7 Clean Architecture examples
// Domain/Protocols/NotificationServiceProtocol.swift

import Foundation // Only Foundation, never UserNotifications

/// Protocol defining notification service operations.
/// Domain layer depends on this abstraction, NOT on concrete implementations.
/// Follows Dependency Inversion Principle.
protocol NotificationServiceProtocol {
    /// Requests authorization to display notifications.
    /// - Parameter options: Notification types to request (alert, sound, badge)
    /// - Returns: Result with granted status or error
    func requestAuthorization(options: NotificationAuthorizationOptions) async throws -> Bool

    /// Checks current notification authorization status.
    /// - Returns: Authorization status (notDetermined, denied, authorized, etc.)
    func authorizationStatus() async -> NotificationAuthorizationStatus

    /// Sets the notification center delegate
    /// - Parameter delegate: Object conforming to notification delegate protocol
    func setDelegate(_ delegate: NotificationCenterDelegate?)
}

/// Domain representation of notification authorization options
struct NotificationAuthorizationOptions: OptionSet {
    let rawValue: Int
    static let alert = NotificationAuthorizationOptions(rawValue: 1 << 0)
    static let sound = NotificationAuthorizationOptions(rawValue: 1 << 1)
    static let badge = NotificationAuthorizationOptions(rawValue: 1 << 2)
}

/// Domain representation of authorization status
enum NotificationAuthorizationStatus {
    case notDetermined
    case denied
    case authorized
    case provisional
    case ephemeral
}

/// Domain protocol for notification delegate
protocol NotificationCenterDelegate: AnyObject {
    // Will be expanded in Phase 2 for foreground notification handling
}
```

### Pattern 2: Concrete Implementation in Data Layer

**What:** Implement protocol by wrapping UNUserNotificationCenter, mapping iOS types to Domain types.

**When to use:** Always - one implementation per platform (iOS in this case).

**Example:**
```swift
// Source: Verified from existing HealthDataRepository.swift pattern + Context7 repository examples
// Data/Services/NotificationService.swift

import Foundation
import UserNotifications // OK to import in Data layer

/// Concrete implementation wrapping UNUserNotificationCenter.
final class NotificationService: NotificationServiceProtocol {
    private let notificationCenter: UNUserNotificationCenter

    init(notificationCenter: UNUserNotificationCenter = .current()) {
        self.notificationCenter = notificationCenter
    }

    func requestAuthorization(options: NotificationAuthorizationOptions) async throws -> Bool {
        let unOptions = options.toUNAuthorizationOptions()
        return try await notificationCenter.requestAuthorization(options: unOptions)
    }

    func authorizationStatus() async -> NotificationAuthorizationStatus {
        let settings = await notificationCenter.notificationSettings()
        return NotificationAuthorizationStatus.from(settings.authorizationStatus)
    }

    func setDelegate(_ delegate: NotificationCenterDelegate?) {
        // Will implement delegate bridging in Phase 2
        // For Phase 1, just store reference
    }
}

// MARK: - Type Mapping Extensions

private extension NotificationAuthorizationOptions {
    func toUNAuthorizationOptions() -> UNAuthorizationOptions {
        var result: UNAuthorizationOptions = []
        if contains(.alert) { result.insert(.alert) }
        if contains(.sound) { result.insert(.sound) }
        if contains(.badge) { result.insert(.badge) }
        return result
    }
}

private extension NotificationAuthorizationStatus {
    static func from(_ unStatus: UNAuthorizationStatus) -> NotificationAuthorizationStatus {
        switch unStatus {
        case .notDetermined: return .notDetermined
        case .denied: return .denied
        case .authorized: return .authorized
        case .provisional: return .provisional
        case .ephemeral: return .ephemeral
        @unknown default: return .notDetermined
        }
    }
}
```

### Pattern 3: Use Case Coordination

**What:** Use Cases encapsulate business logic for permission requests, called by ViewModels.

**When to use:** Always - Use Cases are the Domain layer's operations.

**Example:**
```swift
// Source: Verified from existing SaveDayDataUseCase.swift pattern
// Domain/UseCases/RequestNotificationPermissionUseCase.swift

import Foundation

/// Use case for requesting notification permissions.
/// Encapsulates the business logic for permission flow.
final class RequestNotificationPermissionUseCase {
    private let notificationService: NotificationServiceProtocol

    init(notificationService: NotificationServiceProtocol) {
        self.notificationService = notificationService
    }

    /// Requests notification permission with alert, sound, and badge.
    /// - Returns: True if granted, false if denied
    func execute() async throws -> Bool {
        let options: NotificationAuthorizationOptions = [.alert, .sound, .badge]
        let granted = try await notificationService.requestAuthorization(options: options)

        // Future: Could track permission status in analytics
        // Future: Could persist status in UserDefaults for first-run tracking

        return granted
    }

    /// Checks if notification permission is already granted.
    /// - Returns: True if authorized, false otherwise
    func isAuthorized() async -> Bool {
        let status = await notificationService.authorizationStatus()
        return status == .authorized
    }
}
```

### Pattern 4: First Launch Permission Request

**What:** Request permission in App initialization, similar to existing DataMigration pattern.

**When to use:** On app first launch only, not on every startup.

**Example:**
```swift
// Source: Verified from existing HealthTrackerApp.swift pattern
// HealthTrackerApp.swift (modified)

import SwiftUI

@main
struct HealthTrackerApp: App {
    init() {
        DataMigration.migrateIfNeeded() // existing

        // NEW: Request notification permission on first launch
        Task {
            await NotificationPermissionManager.requestIfFirstLaunch()
        }
    }

    var body: some Scene {
        WindowGroup {
            TabView {
                MainView()
                    .tabItem {
                        Label("Hoje", systemImage: "calendar")
                    }

                AnalyticsView()
                    .tabItem {
                        Label("Gráficos", systemImage: "chart.xyaxis.line")
                    }
            }
        }
    }
}

// Helper manager (could be in Data/Services/)
actor NotificationPermissionManager {
    private static let hasRequestedKey = "hasRequestedNotificationPermission"

    static func requestIfFirstLaunch() async {
        let hasRequested = UserDefaults.standard.bool(forKey: hasRequestedKey)
        guard !hasRequested else { return }

        let service = NotificationService()
        let useCase = RequestNotificationPermissionUseCase(notificationService: service)

        do {
            let granted = try await useCase.execute()
            print("Notification permission: \(granted ? "granted" : "denied")")
            UserDefaults.standard.set(true, forKey: hasRequestedKey)
        } catch {
            print("Failed to request notification permission: \(error)")
            // Don't crash - graceful degradation
        }
    }
}
```

### Pattern 5: Mock Implementation for Testing

**What:** Create mock conforming to protocol for unit tests.

**When to use:** All Use Case tests, ViewModel tests in future phases.

**Example:**
```swift
// Source: Verified from existing MockHealthDataRepository.swift pattern
// HealthTrackerTests/Mocks/MockNotificationService.swift

import Foundation
@testable import HealthTracker

/// Mock implementation of NotificationServiceProtocol for testing.
final class MockNotificationService: NotificationServiceProtocol {
    // MARK: - Stored Results
    var authorizationStatusResult: NotificationAuthorizationStatus = .notDetermined
    var requestAuthorizationResult: Bool = true
    var requestAuthorizationError: Error?

    // MARK: - Call Tracking
    var requestAuthorizationCalled = false
    var requestAuthorizationOptionsUsed: NotificationAuthorizationOptions?
    var authorizationStatusCalled = false
    var setDelegateCalled = false

    // MARK: - Protocol Implementation
    func requestAuthorization(options: NotificationAuthorizationOptions) async throws -> Bool {
        requestAuthorizationCalled = true
        requestAuthorizationOptionsUsed = options

        if let error = requestAuthorizationError {
            throw error
        }

        return requestAuthorizationResult
    }

    func authorizationStatus() async -> NotificationAuthorizationStatus {
        authorizationStatusCalled = true
        return authorizationStatusResult
    }

    func setDelegate(_ delegate: NotificationCenterDelegate?) {
        setDelegateCalled = true
    }
}
```

### Anti-Patterns to Avoid

- **Direct UNUserNotificationCenter in ViewModels:** Violates Clean Architecture, impossible to test, couples UI to iOS framework. Always use protocol abstraction.
- **Crashing on Permission Denial:** User can deny permission - handle gracefully, don't force-unwrap, don't crash. App should continue working.
- **Requesting Permission Repeatedly:** Only request once. Check authorization status before asking again. iOS shows system alert only first time.
- **Importing UserNotifications in Domain Layer:** Domain must be platform-agnostic. Use protocol types only.
- **Synchronous Permission Requests:** Authorization is async - must use async/await or completion handlers. Never block main thread.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Notification permission tracking | Custom database tracking system | UserDefaults for first-run flag + UNUserNotificationCenter.notificationSettings() | System already tracks permission state, just need first-run flag |
| Authorization status enum | String-based status tracking | NotificationAuthorizationStatus enum mapped from UNAuthorizationStatus | Type safety, compile-time checking, matches iOS semantics |
| Delegate management | Custom notification handling system | UNUserNotificationCenterDelegate protocol | Required by iOS, handles foreground notifications, user interactions |
| Permission UI | Custom permission request UI | iOS system permission alert via requestAuthorization() | iOS enforces system UI, custom UI won't show system permission dialog |

**Key insight:** Apple's UserNotifications framework is well-designed but tightly coupled to iOS. The wrapper layer is thin - just map types and forward calls. Don't add complexity trying to "improve" the API.

## Common Pitfalls

### Pitfall 1: Requesting Permission Too Late

**What goes wrong:** Request permission in middle of user flow, user confused about context, high denial rate.

**Why it happens:** Developers wait until feature needed instead of establishing permission early.

**How to avoid:** Request on first launch in App init (NOTIF-01 requirement). User expects setup during onboarding.

**Warning signs:** Permission request appears after user already interacting with app, no context for why notifications needed.

### Pitfall 2: Not Setting Delegate Before Scheduling

**What goes wrong:** Notifications scheduled but app can't respond to user taps, foreground notifications don't show.

**Why it happens:** Delegate set after scheduling, or not set at all.

**How to avoid:** Set delegate in App init immediately after requesting permission (NOTIF-04 requirement).

**Warning signs:** Notifications appear in Notification Center but nothing happens when tapped.

### Pitfall 3: Forgetting to Check Authorization Status

**What goes wrong:** Schedule notifications when permission denied, silent failures, confusion.

**Why it happens:** Assume permission granted after initial request.

**How to avoid:** Always check authorization status before scheduling (NOTIF-02 requirement). User can change permissions in Settings app.

**Warning signs:** Notifications not appearing, no error messages, scheduling succeeds but nothing fires.

### Pitfall 4: Crashing on Permission Denial

**What goes wrong:** App crashes or shows errors when user denies permission.

**Why it happens:** Force-unwrapping optionals, not handling denied state, throwing unhandled errors.

**How to avoid:** Graceful degradation (NOTIF-03 requirement). App works without notifications. Log for analytics but continue.

**Warning signs:** Crash logs showing nil unwrap in notification code path, error alerts shown to user.

### Pitfall 5: Importing UserNotifications in Wrong Layer

**What goes wrong:** ViewModels import UserNotifications, breaks Clean Architecture, impossible to test.

**Why it happens:** Developer takes shortcut, calls UNUserNotificationCenter.current() directly.

**How to avoid:** Protocol abstraction (NOTIF-15, NOTIF-16, NOTIF-17, NOTIF-19). Only Data layer imports UserNotifications.

**Warning signs:** Build succeeds but tests can't compile without iOS simulator, ViewModel tests require real notification center.

### Pitfall 6: Synchronous Permission Request

**What goes wrong:** App freezes, ANR (Application Not Responding), poor UX.

**Why it happens:** Using old completion handler APIs incorrectly, blocking main thread.

**How to avoid:** Use async/await APIs (available iOS 15+, project targets iOS 26+). Call from Task or async context.

**Warning signs:** UI freezes during permission request, watchdog timeout in crash logs.

## Code Examples

Verified patterns from existing codebase and Clean Architecture principles:

### Permission Request in App Init

```swift
// Source: Existing HealthTrackerApp.swift pattern
@main
struct HealthTrackerApp: App {
    init() {
        DataMigration.migrateIfNeeded()

        // Request notification permission on first launch
        Task {
            await NotificationPermissionManager.requestIfFirstLaunch()
        }
    }

    var body: some Scene {
        WindowGroup {
            // ... existing TabView
        }
    }
}
```

### Checking Authorization Status Before Scheduling

```swift
// Source: UNUserNotificationCenter best practices
func scheduleNotificationIfAuthorized() async {
    let service = NotificationService()
    let status = await service.authorizationStatus()

    guard status == .authorized else {
        print("Notification permission not granted, skipping schedule")
        return
    }

    // Proceed with scheduling (Phase 2)
}
```

### Graceful Permission Denial Handling

```swift
// Source: Error handling best practices
func requestPermissionWithGracefulDegradation() async {
    let service = NotificationService()
    let useCase = RequestNotificationPermissionUseCase(notificationService: service)

    do {
        let granted = try await useCase.execute()
        if granted {
            print("Notifications enabled - will schedule reminders")
        } else {
            print("Notifications denied - app continues without reminders")
            // Could show in-app message: "Enable notifications in Settings for reminders"
            // But app functions normally
        }
    } catch {
        print("Error requesting permission: \(error.localizedDescription)")
        // Continue anyway - don't crash
    }
}
```

### Use Case Unit Test

```swift
// Source: Existing SaveDayDataUseCaseTests.swift pattern
@MainActor
struct RequestNotificationPermissionUseCaseTests {
    @Test func execute_requestsPermissionWithCorrectOptions() async throws {
        let mockService = MockNotificationService()
        mockService.requestAuthorizationResult = true

        let useCase = RequestNotificationPermissionUseCase(notificationService: mockService)
        let granted = try await useCase.execute()

        #expect(mockService.requestAuthorizationCalled == true)
        #expect(mockService.requestAuthorizationOptionsUsed?.contains(.alert) == true)
        #expect(mockService.requestAuthorizationOptionsUsed?.contains(.sound) == true)
        #expect(mockService.requestAuthorizationOptionsUsed?.contains(.badge) == true)
        #expect(granted == true)
    }

    @Test func execute_handlesPermissionDenial() async throws {
        let mockService = MockNotificationService()
        mockService.requestAuthorizationResult = false // User denied

        let useCase = RequestNotificationPermissionUseCase(notificationService: mockService)
        let granted = try await useCase.execute()

        #expect(granted == false)
        // No crash, no throw - graceful handling
    }

    @Test func isAuthorized_returnsTrueWhenAuthorized() async {
        let mockService = MockNotificationService()
        mockService.authorizationStatusResult = .authorized

        let useCase = RequestNotificationPermissionUseCase(notificationService: mockService)
        let authorized = await useCase.isAuthorized()

        #expect(authorized == true)
    }

    @Test func isAuthorized_returnsFalseWhenDenied() async {
        let mockService = MockNotificationService()
        mockService.authorizationStatusResult = .denied

        let useCase = RequestNotificationPermissionUseCase(notificationService: mockService)
        let authorized = await useCase.isAuthorized()

        #expect(authorized == false)
    }
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Completion handlers for async operations | async/await with Swift Concurrency | iOS 15+ (2021) | Cleaner code, better error handling, structured concurrency |
| UNUserNotificationCenterDelegate methods | Same delegate protocol | Still current | No change - delegate pattern still required |
| Manual permission status caching | Query notificationSettings() each time | Always available | System is source of truth, no stale data |
| Separate authorization options | UNAuthorizationOptions OptionSet | Since iOS 10 | Type-safe options, composable permissions |

**Deprecated/outdated:**
- **UILocalNotification (iOS 4-9):** Removed in iOS 10, replaced by UserNotifications framework
- **requestAuthorization with completion handler:** Still works but async/await preferred on iOS 15+
- **Requesting permission on every launch:** iOS shows dialog once, further requests are silent

## Open Questions

1. **First Launch Detection Strategy**
   - What we know: Can use UserDefaults flag, system tracks permission state
   - What's unclear: Best key naming convention, whether to check both flag and authorization status
   - Recommendation: Use "hasRequestedNotificationPermission" key, set after first request regardless of user response. Don't conflate "requested" with "granted".

2. **Permission Request Timing in SwiftUI Lifecycle**
   - What we know: App init runs before views appear, Task allows async operation
   - What's unclear: Whether permission dialog blocks view rendering, if delay needed
   - Recommendation: Current pattern (Task in init) is correct. System dialog is async and doesn't block UI. Verified by existing DataMigration pattern.

3. **Delegate Implementation Scope for Phase 1**
   - What we know: Delegate needed for foreground notifications (Phase 2), user tap handling (Phase 2+)
   - What's unclear: How much to implement now vs defer to Phase 2
   - Recommendation: Create delegate protocol and setDelegate() method in Phase 1, but leave implementation minimal. Phase 2 will add actual handling.

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Swift Testing (built-in) |
| Config file | None - integrated with Xcode project |
| Quick run command | `xcodebuild test -scheme HealthTracker -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:HealthTrackerTests/RequestNotificationPermissionUseCaseTests` |
| Full suite command | `xcodebuild test -scheme HealthTracker -destination 'platform=iOS Simulator,name=iPhone 16 Pro'` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| NOTIF-01 | Request permission on first launch | unit | `xcodebuild test -scheme HealthTracker -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:HealthTrackerTests/NotificationPermissionManagerTests/testRequestIfFirstLaunch -x` | ❌ Wave 0 |
| NOTIF-02 | Check authorization status before operations | unit | `xcodebuild test -scheme HealthTracker -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:HealthTrackerTests/RequestNotificationPermissionUseCaseTests/testIsAuthorized -x` | ❌ Wave 0 |
| NOTIF-03 | Handle permission denial gracefully | unit | `xcodebuild test -scheme HealthTracker -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:HealthTrackerTests/RequestNotificationPermissionUseCaseTests/testHandlesPermissionDenial -x` | ❌ Wave 0 |
| NOTIF-04 | Configure delegate at launch | manual-only | N/A - verify in manual device testing | manual |
| NOTIF-15 | Clean Architecture protocol abstraction | unit | `xcodebuild test -scheme HealthTracker -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:HealthTrackerTests/NotificationServiceTests -x` | ❌ Wave 0 |
| NOTIF-16 | NotificationServiceProtocol in Domain layer | unit | Compile-time verification - protocol exists without UserNotifications import | ❌ Wave 0 |
| NOTIF-17 | NotificationService wraps UNUserNotificationCenter | unit | `xcodebuild test -scheme HealthTracker -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:HealthTrackerTests/NotificationServiceTests -x` | ❌ Wave 0 |
| NOTIF-19 | ViewModels don't import UserNotifications | manual-only | Compile-time verification - grep ViewModels for "import UserNotifications" | manual |

### Sampling Rate

- **Per task commit:** `xcodebuild test -scheme HealthTracker -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:HealthTrackerTests/RequestNotificationPermissionUseCaseTests`
- **Per wave merge:** `xcodebuild test -scheme HealthTracker -destination 'platform=iOS Simulator,name=iPhone 16 Pro'`
- **Phase gate:** Full suite green + manual verification of permission dialog appearance before `/gsd:verify-work`

### Wave 0 Gaps

- [ ] `HealthTrackerTests/Mocks/MockNotificationService.swift` - covers NOTIF-15, NOTIF-17
- [ ] `HealthTrackerTests/Domain/UseCases/RequestNotificationPermissionUseCaseTests.swift` - covers NOTIF-02, NOTIF-03
- [ ] `HealthTrackerTests/Data/Services/NotificationServiceTests.swift` - covers NOTIF-17 (type mapping)
- [ ] Manual test plan document for NOTIF-01, NOTIF-04 (device-only verification)

## Sources

### Primary (HIGH confidence)

- Context7 /nalexn/clean-architecture-swiftui - Clean Architecture layer patterns in SwiftUI
- Context7 /sergdort/moderncleanarchitectureswiftui - Protocol abstraction, repository implementation, dependency injection patterns
- Existing codebase patterns:
  - `/Users/gustavosantos/Documents/Projects/Personal/Real app repos/HealthTracker/HealthTracker/Domain/Protocols/HealthDataRepositoryProtocol.swift` - Protocol pattern
  - `/Users/gustavosantos/Documents/Projects/Personal/Real app repos/HealthTracker/HealthTracker/Data/Repositories/HealthDataRepository.swift` - Implementation pattern
  - `/Users/gustavosantos/Documents/Projects/Personal/Real app repos/HealthTracker/HealthTracker/Domain/UseCases/SaveDayDataUseCase.swift` - Use Case pattern
  - `/Users/gustavosantos/Documents/Projects/Personal/Real app repos/HealthTracker/HealthTrackerTests/Mocks/MockHealthDataRepository.swift` - Mock pattern
  - `/Users/gustavosantos/Documents/Projects/Personal/Real app repos/HealthTracker/HealthTrackerTests/Domain/UseCases/SaveDayDataUseCaseTests.swift` - Test pattern

### Secondary (MEDIUM confidence)

- iOS UserNotifications framework knowledge from training (iOS 10-16 era, async/await patterns verified current)
- Swift Testing framework (project already uses, verified from test files)

### Tertiary (LOW confidence - needs verification)

- Best practices for permission request timing - based on training data but not verified with 2026 official docs (WebFetch failed due to JavaScript requirement)
- Delegate configuration specifics - implementation details will be validated during Phase 2 when foreground handling needed

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - UserNotifications is only option, existing test framework verified
- Architecture: HIGH - Clean Architecture patterns verified from existing codebase + Context7 examples
- Pitfalls: HIGH - Based on known iOS notification gotchas, mapped to requirements

**Research date:** 2026-02-28
**Valid until:** 2026-03-28 (30 days - iOS notification APIs stable, Clean Architecture patterns established)

**Note on WebSearch/WebFetch limitations:** Apple Developer Documentation requires JavaScript rendering, could not fetch current official docs. Research relies on training knowledge (iOS 10-16 era) cross-verified with Context7 Swift patterns and existing codebase structure. Core UserNotifications APIs (requestAuthorization, notificationSettings, delegate pattern) have remained stable since iOS 10, with primary evolution being async/await support in iOS 15+. Project targets iOS 26+, so async/await is available and preferred.
