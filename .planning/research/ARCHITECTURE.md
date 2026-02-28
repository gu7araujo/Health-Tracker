# Architecture Research: iOS UserNotifications in Clean Architecture

**Domain:** iOS local notifications for health tracking app
**Researched:** 2026-02-28
**Confidence:** HIGH

## Standard Architecture

### System Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    Presentation Layer                        │
├─────────────────────────────────────────────────────────────┤
│  ┌──────────┐          ┌──────────────────┐                 │
│  │ViewModel │ ────────▶│ Use Cases        │                 │
│  │          │          │ - Schedule       │                 │
│  │          │          │ - Cancel         │                 │
│  │          │          │ - CheckPermission│                 │
│  └──────────┘          └─────────┬────────┘                 │
│                                   │                          │
├───────────────────────────────────┼──────────────────────────┤
│                    Domain Layer   │                          │
├───────────────────────────────────┼──────────────────────────┤
│  ┌───────────────────────────────▼────────────────────┐     │
│  │       NotificationServiceProtocol                   │     │
│  │  (Abstract notification scheduling & permissions)   │     │
│  └───────────────────────────────┬────────────────────┘     │
│                                   │                          │
├───────────────────────────────────┼──────────────────────────┤
│                    Data Layer     │                          │
├───────────────────────────────────┼──────────────────────────┤
│  ┌───────────────────────────────▼────────────────────┐     │
│  │       NotificationService                           │     │
│  │  (Wraps UNUserNotificationCenter)                   │     │
│  └────────────────────────────────────────────────────┘     │
│                                                              │
│  Communicates with:                                          │
│  ┌───────────────────────────────────────────────────┐      │
│  │     HealthDataRepositoryProtocol                   │      │
│  │  (To check if user logged data today)              │      │
│  └────────────────────────────────────────────────────┘     │
└──────────────────────────────────────────────────────────────┘
```

### Component Responsibilities

| Component | Responsibility | Typical Implementation |
|-----------|----------------|------------------------|
| **NotificationServiceProtocol** | Abstract notification operations (Domain layer) | Protocol defining schedule, cancel, request permission methods |
| **NotificationService** | Concrete iOS implementation wrapping UserNotifications framework | Class implementing protocol, direct UNUserNotificationCenter calls |
| **ScheduleNotificationUseCase** | Business logic for when/how to schedule notifications | Use case with injected NotificationService and Repository dependencies |
| **CancelNotificationUseCase** | Business logic for canceling scheduled notifications | Use case determining which notifications to cancel based on data state |
| **RequestNotificationPermissionUseCase** | Permission flow and handling | Use case orchestrating permission request at app launch |
| **CheckNotificationStatusUseCase** | Query whether notifications should fire | Use case reading from HealthDataRepository to determine if user logged data |
| **MainViewModel** | Trigger notification updates when user logs data | Existing ViewModel calls notification use cases after data changes |

## Recommended Project Structure

```
HealthTracker/
├── Domain/
│   ├── Protocols/
│   │   ├── HealthDataRepositoryProtocol.swift       # Existing
│   │   └── NotificationServiceProtocol.swift        # NEW: Domain abstraction
│   │
│   ├── UseCases/
│   │   ├── LoadDayDataUseCase.swift                 # Existing
│   │   ├── SaveDayDataUseCase.swift                 # Existing
│   │   ├── ScheduleNotificationsUseCase.swift       # NEW: Schedule lunch + evening
│   │   ├── CancelNotificationsUseCase.swift         # NEW: Cancel when data logged
│   │   └── RequestNotificationPermissionUseCase.swift # NEW: First launch permission
│   │
│   └── Entities/
│       ├── DayData.swift                            # Existing
│       ├── RecordedDayData.swift                    # Existing
│       └── NotificationTime.swift                   # NEW: Enum for 1PM/8PM
│
├── Data/
│   ├── Repositories/
│   │   └── HealthDataRepository.swift               # Existing
│   │
│   └── Services/                                    # NEW: Services subfolder
│       └── NotificationService.swift                # NEW: UserNotifications wrapper
│
├── Presentation/
│   ├── ViewModels/
│   │   └── MainViewModel.swift                      # MODIFIED: Inject + call notification use cases
│   │
│   └── Views/
│       └── MainView.swift                           # Existing (no changes needed)
│
└── HealthTrackerApp.swift                           # MODIFIED: Request permission at init
```

### Structure Rationale

- **NotificationServiceProtocol in Domain/Protocols/:** Follows existing pattern. Domain defines what it needs, Data layer implements it. Maintains Dependency Inversion Principle.
- **NotificationService in Data/Services/:** New subfolder for service implementations (distinct from Repositories which are data-centric). Services wrap external frameworks.
- **Notification Use Cases in Domain/UseCases/:** Follows existing pattern. Each use case has single responsibility: schedule, cancel, or request permission.
- **NotificationTime entity in Domain/Entities/:** Business concept (lunch vs evening) lives in Domain, not hardcoded in implementation.

## Architectural Patterns

### Pattern 1: Protocol-Based Dependency Inversion

**What:** Domain layer defines NotificationServiceProtocol, Data layer implements it with concrete UserNotifications wrapper.

**When to use:** Always, for framework dependencies. Maintains testability and keeps Domain pure.

**Trade-offs:**
- **Pro:** Domain doesn't depend on UIKit/UserNotifications. Easy to mock for tests.
- **Pro:** Consistent with existing HealthDataRepositoryProtocol pattern.
- **Con:** Extra abstraction layer (minimal cost for architectural benefits).

**Example:**
```swift
// Domain/Protocols/NotificationServiceProtocol.swift
protocol NotificationServiceProtocol {
    func requestPermission() async -> Bool
    func scheduleNotification(id: String, title: String, body: String, hour: Int, minute: Int)
    func cancelNotification(id: String)
    func cancelAllNotifications()
}

// Data/Services/NotificationService.swift
import UserNotifications

final class NotificationService: NotificationServiceProtocol {
    private let center = UNUserNotificationCenter.current()

    func requestPermission() async -> Bool {
        do {
            return try await center.requestAuthorization(options: [.alert, .sound])
        } catch {
            #if DEBUG
            print("Permission request failed: \(error)")
            #endif
            return false
        }
    }

    func scheduleNotification(id: String, title: String, body: String, hour: Int, minute: Int) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)

        center.add(request) { error in
            #if DEBUG
            if let error = error {
                print("Failed to schedule notification: \(error)")
            }
            #endif
        }
    }

    func cancelNotification(id: String) {
        center.removePendingNotificationRequests(withIdentifiers: [id])
    }

    func cancelAllNotifications() {
        center.removeAllPendingNotificationRequests()
    }
}
```

### Pattern 2: Use Case Composition

**What:** Coordinate multiple domain operations (check repository + schedule notifications) through dedicated use cases.

**When to use:** When notification logic depends on data state (e.g., "only schedule if no data logged today").

**Trade-offs:**
- **Pro:** Business logic centralized, not scattered across ViewModels.
- **Pro:** Testable without UI dependencies.
- **Con:** More classes to maintain.

**Example:**
```swift
// Domain/UseCases/ScheduleNotificationsUseCase.swift
final class ScheduleNotificationsUseCase {
    private let notificationService: NotificationServiceProtocol
    private let repository: HealthDataRepositoryProtocol

    init(
        notificationService: NotificationServiceProtocol,
        repository: HealthDataRepositoryProtocol
    ) {
        self.notificationService = notificationService
        self.repository = repository
    }

    func execute() {
        // Business logic: Always schedule both times, they check data status when firing
        notificationService.scheduleNotification(
            id: "lunch-reminder",
            title: "Time to log your lunch!",
            body: "Log your meal and health data",
            hour: 13,
            minute: 0
        )

        notificationService.scheduleNotification(
            id: "evening-reminder",
            title: "How was your day?",
            body: "Log your health data before bed",
            hour: 20,
            minute: 0
        )
    }
}

// Domain/UseCases/CancelNotificationsUseCase.swift
final class CancelNotificationsUseCase {
    private let notificationService: NotificationServiceProtocol

    init(notificationService: NotificationServiceProtocol) {
        self.notificationService = notificationService
    }

    func execute() {
        // Business logic: Cancel both when any data is logged
        notificationService.cancelAllNotifications()
    }
}
```

### Pattern 3: ViewModel Integration Points

**What:** ViewModel calls notification use cases at strategic points (after data save, on app init).

**When to use:** When user actions should trigger notification behavior changes.

**Trade-offs:**
- **Pro:** ViewModel orchestrates cross-cutting concerns naturally.
- **Pro:** No changes to View layer (SwiftUI remains pure).
- **Con:** ViewModel becomes coordinator for multiple concerns.

**Example:**
```swift
// Presentation/ViewModels/MainViewModel.swift
@Observable
final class MainViewModel {
    private let loadUseCase: LoadDayDataUseCase
    private let saveUseCase: SaveDayDataUseCase
    private let scheduleNotificationsUseCase: ScheduleNotificationsUseCase
    private let cancelNotificationsUseCase: CancelNotificationsUseCase

    // ... existing properties ...

    convenience init(
        repository: HealthDataRepositoryProtocol = HealthDataRepository(),
        notificationService: NotificationServiceProtocol = NotificationService()
    ) {
        self.init(
            loadUseCase: LoadDayDataUseCase(repository: repository),
            saveUseCase: SaveDayDataUseCase(repository: repository),
            scheduleNotificationsUseCase: ScheduleNotificationsUseCase(
                notificationService: notificationService,
                repository: repository
            ),
            cancelNotificationsUseCase: CancelNotificationsUseCase(
                notificationService: notificationService
            )
        )
    }

    func loadData() {
        days = loadUseCase.execute().map(\.dayData)
        ensureDayDataExists(for: selectedDate)

        // Re-schedule notifications for today
        scheduleNotificationsUseCase.execute()
    }

    private func persistChanges() {
        let recordedDays = days.compactMap(RecordedDayData.init)
        saveUseCase.execute(days: recordedDays)

        // Check if user logged data today, cancel notifications if so
        let hasDataToday = recordedDays.contains {
            Calendar.current.isDate($0.dayData.date, inSameDayAs: Date())
        }

        if hasDataToday {
            cancelNotificationsUseCase.execute()
        }
    }
}
```

## Data Flow

### Notification Scheduling Flow

```
[App Launch]
    ↓
[HealthTrackerApp.init] → RequestNotificationPermissionUseCase.execute()
    ↓
[MainViewModel.loadData()] → ScheduleNotificationsUseCase.execute()
    ↓                              ↓
[Check today's data] ←────────────┘ (via HealthDataRepository)
    ↓
[NotificationService.scheduleNotification()] → UNUserNotificationCenter
```

### Notification Cancellation Flow

```
[User logs meal/workout/water/mood]
    ↓
[MainViewModel.persistChanges()]
    ↓
[Check if data exists for today]
    ↓ (yes)
[CancelNotificationsUseCase.execute()]
    ↓
[NotificationService.cancelAllNotifications()] → UNUserNotificationCenter
```

### Permission Request Flow

```
[App Launch (first time)]
    ↓
[HealthTrackerApp.init]
    ↓
[RequestNotificationPermissionUseCase.execute()]
    ↓
[NotificationService.requestPermission()]
    ↓
[UNUserNotificationCenter.requestAuthorization()]
    ↓
[User grants/denies] → [Result stored by iOS, not in app]
```

### Key Data Flows

1. **Schedule on load:** App launch → MainViewModel.loadData() → Check repository for today's data → Schedule both notifications (they'll check data when firing).
2. **Cancel on data entry:** User logs data → MainViewModel.persistChanges() → Detect data for today → Cancel all pending notifications for today.
3. **Permission on first launch:** App init → Request permission use case → NotificationService wraps native permission dialog.

## Scaling Considerations

| Scale | Architecture Adjustments |
|-------|--------------------------|
| 1-100 notifications/day | Current architecture sufficient. Two fixed notifications per day. |
| 100+ notifications/day | Not applicable. Fixed schedule (2/day max). |
| Custom schedules | Add SchedulePreferences entity, persist to Repository, read in ScheduleNotificationsUseCase. |

### Scaling Priorities

1. **First requirement change:** User wants to disable notifications → Add UserPreferences entity in Domain, persist via Repository, check in ScheduleNotificationsUseCase.
2. **Second requirement change:** User wants custom times → Extend NotificationTime entity with hour/minute properties, store in Repository, pass to NotificationService.

## Anti-Patterns

### Anti-Pattern 1: Direct UNUserNotificationCenter Calls in ViewModel

**What people do:** Import UserNotifications in MainViewModel, call UNUserNotificationCenter.current() directly.

**Why it's wrong:**
- Violates Dependency Inversion Principle (Presentation depends on framework).
- Makes ViewModel untestable without actual iOS notification system.
- Breaks Clean Architecture boundaries (Presentation shouldn't know about iOS frameworks beyond SwiftUI).

**Do this instead:**
- Create NotificationServiceProtocol in Domain.
- Inject protocol into ViewModel via Use Cases.
- Data layer implements protocol with UserNotifications wrapper.

### Anti-Pattern 2: Notification Logic in Views

**What people do:** Add `.task {}` or `.onAppear {}` to SwiftUI views that directly schedule notifications.

**Why it's wrong:**
- Business logic leaks into presentation.
- Harder to test notification behavior.
- Views re-render frequently, causing duplicate scheduling.

**Do this instead:**
- Keep Views dumb (just render state, call ViewModel methods).
- Put notification scheduling logic in Use Cases.
- ViewModel calls Use Cases at appropriate times (after data load/save).

### Anti-Pattern 3: Hardcoded Notification Content in Service Layer

**What people do:** Put "Time to log your lunch!" strings in NotificationService implementation.

**Why it's wrong:**
- Business language lives in Data layer (should be Domain concern).
- Hard to localize or change messaging.
- Service should be generic, Use Case provides context-specific details.

**Do this instead:**
- Use Cases determine notification content based on time/context.
- Pass title/body as parameters to NotificationService methods.
- NotificationService is a dumb wrapper, no business logic.

### Anti-Pattern 4: Checking Data State at Notification Fire Time

**What people do:** Use UNNotificationServiceExtension to query repository when notification fires, decide whether to show.

**Why it's wrong:**
- Extensions have limited runtime and memory.
- Querying iCloud Drive in extension is unreliable.
- Overcomplicated for simple use case.

**Do this instead:**
- Cancel notifications immediately when user logs data (CancelNotificationsUseCase).
- Simpler: no data logged = notifications active, data logged = notifications canceled.
- iOS handles the rest automatically.

## Integration Points

### External Services

| Service | Integration Pattern | Notes |
|---------|---------------------|-------|
| UNUserNotificationCenter | Wrapped in NotificationService | Singleton provided by iOS, no initialization needed |
| iCloud Drive (existing) | Via HealthDataRepositoryProtocol | Read to check if data logged today |
| System Permissions | Async/await in requestPermission() | One-time dialog, result cached by iOS |

### Internal Boundaries

| Boundary | Communication | Notes |
|----------|---------------|-------|
| MainViewModel ↔ NotificationUseCases | Method calls (sync) | ViewModel orchestrates after data changes |
| ScheduleNotificationsUseCase ↔ NotificationService | Protocol method calls | Use case provides content, service handles iOS calls |
| ScheduleNotificationsUseCase ↔ HealthDataRepository | Protocol method calls | Use case reads today's data to determine schedule |
| NotificationService ↔ UNUserNotificationCenter | Direct iOS framework calls | Service wraps singleton, handles async/completion patterns |

## Build Order Implications

### Dependency Graph

```
1. NotificationServiceProtocol (Domain - no dependencies)
    ↓
2. NotificationService (Data - implements protocol)
    ↓
3. Notification Use Cases (Domain - depend on protocol + repository)
    ↓
4. MainViewModel (Presentation - inject use cases)
    ↓
5. HealthTrackerApp (App - request permission, inject into views)
```

### Recommended Build Sequence

1. **Phase 1:** Create NotificationServiceProtocol + NotificationService (build vertical slice).
2. **Phase 2:** Add RequestNotificationPermissionUseCase + integrate in App init.
3. **Phase 3:** Add ScheduleNotificationsUseCase, integrate in MainViewModel.loadData().
4. **Phase 4:** Add CancelNotificationsUseCase, integrate in MainViewModel.persistChanges().
5. **Phase 5:** Add NotificationTime entity if time configuration needed (deferred to future).

### Testing Strategy

- **Unit tests:** Mock NotificationServiceProtocol in Use Case tests.
- **Integration tests:** Use TestNotificationService (in-memory) to verify ViewModel behavior.
- **Manual tests:** Run on device, check notification center at 1 PM / 8 PM.

## Sources

**PRIMARY (HIGH confidence):**
- Apple Developer Documentation: UserNotifications framework (official iOS documentation)
- Existing codebase analysis: HealthTracker/Domain/Protocols/HealthDataRepositoryProtocol.swift, HealthTracker/Data/Repositories/HealthDataRepository.swift, HealthTracker/Presentation/ViewModels/MainViewModel.swift
- Clean Architecture principles: Dependency Inversion, protocol-based abstractions observed in current codebase

**SECONDARY (MEDIUM confidence):**
- iOS development patterns: Service layer wrapping framework APIs (common pattern in Swift/iOS projects)
- Use Case pattern: Single responsibility classes with execute() methods (observed in LoadDayDataUseCase, SaveDayDataUseCase)

**CONFIDENCE ASSESSMENT:**
- Architecture patterns: HIGH (directly derived from existing codebase structure)
- UserNotifications integration: HIGH (standard iOS framework with well-defined API)
- Build order: HIGH (based on dependency analysis of existing Clean Architecture layers)

---
*Architecture research for: iOS UserNotifications in Clean Architecture*
*Researched: 2026-02-28*
