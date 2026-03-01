# Phase 4: Testing and Refinement - Research

**Researched:** 2026-03-01
**Domain:** iOS Notification Testing, Swift Testing Framework, and Manual Device Testing
**Confidence:** HIGH

## Summary

Phase 4 validates the notification system built in Phases 1-3 through comprehensive unit testing of Use Cases and manual device testing for iOS integration verification. The project uses Swift Testing framework (modern successor to XCTest introduced in Xcode 16) with `@Test` macros, `#expect` assertions, and native async/await support. MockNotificationService already exists with comprehensive tracking capabilities for all notification operations (scheduling, cancellation, authorization).

The key technical challenge is determining what to test at each level. Unit tests validate Use Case business logic (happy paths, error paths, edge cases) using mocks. Manual device tests validate iOS system integration (actual notification firing, permission flows, system edge cases like force quit, time zone changes, DST transitions). The NotificationService wrapper itself is intentionally NOT unit tested - it's a thin wrapper around UNUserNotificationCenter with no business logic, making unit tests low-value compared to manual device testing.

Swift Testing provides superior async support compared to XCTest: `@MainActor` tests for actor-isolated code, native `async throws` functions, and structured concurrency support. The existing test suite uses `#expect` for assertions (more composable than XCTAssert) and struct-based test organization (faster, less memory overhead than XCTestCase classes).

Debug logging already exists in Use Cases using simple `print()` statements with prefixed tags (`[ScheduleNotifications]`, `[CancelNotifications]`). This provides visibility into notification operations without requiring additional logging frameworks.

**Primary recommendation:** Create comprehensive Use Case tests covering happy paths and key error scenarios (permission denial, invalid inputs, authorization state variations). Document manual test plan in UAT.md format matching Phase 3 patterns (6 tests covering notification firing, edge cases, permission flows). Skip NotificationService unit tests - rely on manual device verification for iOS integration. Enhance debug logging if gaps are identified during manual testing.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **Use Case tests**: Happy path + key error paths (permission denial, already-scheduled scenarios, invalid inputs)
- **Service layer**: Skip unit tests for NotificationService - it's a thin wrapper around UNUserNotificationCenter. Rely on manual device tests for iOS integration.
- **Edge cases**: Manual testing only for force quit, time zone changes, DST transitions - these are iOS system integration behaviors that can't be meaningfully unit tested
- **Mock infrastructure**: Check for existing MockNotificationService from Phases 2-3 testing. Create only if missing - reuse over duplication.

### Claude's Discretion
- Test organization and file structure
- Test naming conventions
- Exact assertions and test data setup
- Manual test documentation format
- Debug logging implementation details
- Which specific error scenarios beyond permission denial and invalid inputs to test

### Deferred Ideas (OUT OF SCOPE)
None - discussion stayed within phase scope.

</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| NOTIF-20 | Notification service has unit tests with mock protocol implementation | MockNotificationService exists with comprehensive tracking; add Use Case tests using this mock |
| NOTIF-21 | Use Cases have unit tests covering scheduling and cancellation logic | Swift Testing with @Test macros, #expect assertions, async/await support for Use Case validation |
| NOTIF-22 | Manual test plan covers device testing for actual notification firing | UAT.md format from Phase 3 - structured test cases with expected/result fields, covers iOS integration scenarios |

</phase_requirements>

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Swift Testing | Xcode 16+ | Modern Swift testing framework with @Test macros | Project standard (used in all existing tests); replaces XCTest with better async/await support |
| Foundation | iOS 10+ | DateComponents, Calendar for test data setup | Standard library for date manipulation in tests |
| @testable import | Swift 5+ | Access internal types/methods for testing | Standard Swift testing pattern for white-box testing |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| MockNotificationService | Project | Protocol mock with call tracking | Every Use Case test - already exists with comprehensive tracking |
| @MainActor | Swift 5.5+ | Isolate tests to main actor context | Use Cases require MainActor - tests must match |
| Task | Swift 5.5+ | Test async fire-and-forget patterns | Verify cancellation doesn't block in MainViewModel integration |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Swift Testing | XCTest | XCTest is legacy framework; Swift Testing has better async support, no setup/tearDown overhead, faster compilation |
| #expect | #require or XCTAssert | #expect is standard for non-critical assertions; #require for critical unwrapping; XCTAssert is legacy |
| Manual UAT.md | Automated UI tests (XCUITest) | UI tests for notifications are brittle (timing, system permissions, simulator limitations); manual tests provide better coverage |

**Installation:**
Swift Testing is built into Xcode 16+ - no package installation required. Existing tests already use this framework.

## Architecture Patterns

### Recommended Project Structure
```
HealthTrackerTests/
├── Mocks/
│   └── MockNotificationService.swift                     # ✅ EXISTS - comprehensive tracking
├── Domain/
│   └── UseCases/
│       ├── RequestNotificationPermissionUseCaseTests.swift   # ✅ EXISTS
│       ├── ScheduleNotificationsUseCaseTests.swift          # ✅ EXISTS - needs enhancement
│       └── CancelNotificationsUseCaseTests.swift            # ✅ EXISTS - needs enhancement
.planning/phases/04-testing-and-refinement/
└── 04-UAT.md                                              # NEW - manual test plan
```

### Pattern 1: Swift Testing with Async/Await and MainActor

**What:** Modern Swift Testing framework uses `@Test` macro with native async/await support and `@MainActor` isolation for actor-isolated code.

**When to use:** All unit tests for Use Cases, especially when testing async operations or MainActor-isolated types.

**Example:**
```swift
// Source: https://developer.apple.com/documentation/testing/definingtests
import Testing
@testable import HealthTracker

@MainActor
struct ScheduleNotificationsUseCaseTests {
    @Test func execute_schedulesBothNotificationsWhenAuthorized() async throws {
        let mockService = MockNotificationService()
        mockService.authorizationStatusResult = .authorized

        let useCase = ScheduleNotificationsUseCase(notificationService: mockService)
        try await useCase.execute()

        #expect(mockService.scheduleNotificationCalled == true)
        #expect(mockService.scheduleNotificationIdentifiers.count == 60) // 30 days × 2
    }
}
```

**Key differences from XCTest:**
- Struct-based tests (no class overhead)
- `@Test` macro replaces `func test...()` naming convention
- `#expect` replaces `XCTAssert...()` functions
- Native async/await (no `waitForExpectations`)
- `@MainActor` annotation for actor isolation

### Pattern 2: Mock Service with Comprehensive Tracking

**What:** MockNotificationService tracks all method calls, parameters, and provides configurable results/errors for testing different scenarios.

**When to use:** Every Use Case test to verify protocol calls without iOS framework dependencies.

**Example:**
```swift
// MockNotificationService already exists - demonstrates usage pattern
@Test func execute_handlesPermissionDenial() async throws {
    let mockService = MockNotificationService()
    mockService.authorizationStatusResult = .denied  // Configure mock result

    let useCase = ScheduleNotificationsUseCase(notificationService: mockService)
    try await useCase.execute()

    // Verify graceful degradation - no scheduling attempted
    #expect(mockService.scheduleNotificationCalled == false)
}
```

**Mock capabilities (from MockNotificationService.swift):**
- Authorization status configuration: `authorizationStatusResult`
- Authorization result/error: `requestAuthorizationResult`, `requestAuthorizationError`
- Call tracking: `requestAuthorizationCalled`, `scheduleNotificationCalled`, etc.
- Parameter capture: `scheduleNotificationIdentifiers`, `scheduleNotificationBodies`, `scheduleNotificationDateComponents`
- Reset capabilities: `resetCancellationTracking()` for fresh test state

### Pattern 3: Test Organization by Behavior Group

**What:** Organize tests using comment blocks (MARK) and descriptive test names that document the behavior being verified.

**When to use:** Always - improves readability and makes test failures self-documenting.

**Example:**
```swift
struct ScheduleNotificationsUseCaseTests {
    // MARK: - Authorization Tests

    @Test func execute_schedulesBothNotificationsWhenAuthorized() async throws { }
    @Test func execute_skipsSchedulingWhenNotAuthorized() async throws { }
    @Test func execute_handlesNotDeterminedStatus() async throws { }

    // MARK: - Scheduling Logic Tests

    @Test func execute_cancelsExistingNotificationsBeforeScheduling() async throws { }
    @Test func execute_schedulesThirtyDaysOfNotifications() async throws { }
    @Test func execute_usesDateSpecificIdentifiers() async throws { }

    // MARK: - Edge Cases

    @Test func execute_handlesProvisionalStatus() async throws { }
}
```

### Pattern 4: Manual Device Testing for iOS Integration

**What:** Document manual test procedures in UAT.md format with structured test cases covering iOS system integration behaviors.

**When to use:** For testing actual notification firing, permission flows, system edge cases that can't be unit tested.

**Example:**
```markdown
## Tests

### 1. Unit Tests Pass for All Use Cases
expected: Run test suite (Cmd+U in Xcode). All tests in ScheduleNotificationsUseCaseTests, CancelNotificationsUseCaseTests, and RequestNotificationPermissionUseCaseTests should pass. No failures or crashes.
result: [pending/pass/fail]

### 2. Notifications Fire at 1 PM and 8 PM (Production Times)
expected: Install release build on device. Grant permissions. Check notification center at 1:00 PM and 8:00 PM. Two notifications should appear with correct Portuguese-BR messages.
result: [pending/pass/fail]

### 3. Time Zone Change Doesn't Break Notifications
expected: Schedule notifications, then change device time zone in Settings. Wait for next scheduled time in NEW time zone. Notifications should fire at 1 PM and 8 PM in the new time zone.
result: [pending/pass/fail]
```

### Anti-Patterns to Avoid

- **Testing NotificationService directly:** NotificationService is a thin wrapper with no business logic - unit tests would just verify iOS framework behavior, which is Apple's responsibility
- **Awaiting fire-and-forget cancellation in tests:** CancelNotificationsUseCase is called with fire-and-forget Task {} - tests should verify the pattern exists, not await completion
- **Hardcoding date expectations:** Use relative date calculations (e.g., "today + N days") rather than fixed dates that become stale
- **Over-mocking:** Don't mock Calendar or Date - use real Foundation types for more realistic tests
- **Ignoring MainActor requirements:** Use Cases require @MainActor - tests must match this isolation or will fail to compile

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Test framework | Custom test runner with XCTest | Swift Testing | Modern framework with better async support, faster compilation, built into Xcode 16+ |
| Mock notification service | Create new mock from scratch | Extend existing MockNotificationService | Already has comprehensive tracking for all operations from Phases 1-3 |
| Date manipulation in tests | Custom date helpers | Foundation's Calendar and DateComponents | Standard library handles edge cases (leap years, month boundaries, DST) |
| Async test waiting | Custom polling or delays | Native async/await in @Test functions | Swift Testing has native async support - no need for expectations or wait loops |

**Key insight:** Testing frameworks and mock infrastructure are deceptively complex. Swift Testing is battle-tested by Apple with excellent async/await support. Existing MockNotificationService tracks all operations needed - extending it is far cheaper than creating new test infrastructure.

## Common Pitfalls

### Pitfall 1: Testing iOS Framework Behavior Instead of Business Logic

**What goes wrong:** Writing unit tests for NotificationService that just verify UNUserNotificationCenter works correctly (e.g., testing that scheduleNotification actually adds to notification center).

**Why it happens:** Instinct to achieve 100% code coverage leads to testing framework wrappers.

**How to avoid:** Only test business logic. NotificationService is a thin wrapper - trust Apple's framework. Test Use Cases which contain actual business rules (authorization checks, date calculations, identifier generation).

**Warning signs:** Tests that require real UNUserNotificationCenter instance, tests that check notification center state directly, tests with no mock service.

### Pitfall 2: Race Conditions in Async Tests

**What goes wrong:** Tests that spawn async Tasks without proper awaiting can complete before async work finishes, leading to flaky test failures.

**Why it happens:** Fire-and-forget pattern in production code (Task { }) seems like it should be tested the same way.

**How to avoid:** For testing, convert fire-and-forget to awaitable pattern, or add small delays with expectations. Don't test the fire-and-forget pattern itself - test that the underlying Use Case method works correctly.

**Warning signs:** Tests that sometimes pass and sometimes fail, tests that fail when run in parallel but pass when isolated.

### Pitfall 3: Manual Tests That Can't Be Reproduced

**What goes wrong:** Manual test plan says "notifications fire at 1 PM" but provides no guidance on how to verify without waiting hours.

**Why it happens:** Forgetting that manual testers need practical instructions.

**How to avoid:** Document debug build testable times (notifications fire 2-3 minutes after launch in debug), provide time manipulation instructions (e.g., change device date/time in Settings), include clear pass/fail criteria.

**Warning signs:** Test instructions that require waiting hours, tests with subjective criteria ("notifications work well"), no mention of debug vs release differences.

### Pitfall 4: Missing Edge Case Coverage

**What goes wrong:** Tests cover happy path but miss important edge cases (authorization states, invalid inputs, boundary conditions).

**Why it happens:** Focus on making tests pass rather than thinking about failure modes.

**How to avoid:** For each Use Case, test: happy path, permission denial, invalid inputs, boundary values, error propagation. Use authorization status enum values as checklist (.notDetermined, .denied, .authorized, .provisional, .ephemeral).

**Warning signs:** Only one test per Use Case, no tests with "handles" or "edge" in name, mock never configured with error states.

### Pitfall 5: Brittle Date-Based Tests

**What goes wrong:** Tests that hardcode specific dates fail when run later (e.g., test expects "2026-03-01" but runs in April).

**Why it happens:** Using fixed dates for convenience during test writing.

**How to avoid:** Use relative dates (Date(), Calendar.current.date(byAdding:)), test date formatting functions separately from business logic, verify patterns (e.g., identifier contains "YYYY-MM-DD") rather than exact values.

**Warning signs:** Tests with hardcoded year/month/day values, tests that pass in March but fail in April, date assertions that compare full date strings.

## Code Examples

### Example 1: Testing Authorization State Variations

```swift
// Verified from existing RequestNotificationPermissionUseCaseTests.swift
@MainActor
struct ScheduleNotificationsUseCaseTests {
    @Test func execute_schedulesBothNotificationsWhenAuthorized() async throws {
        let mockService = MockNotificationService()
        mockService.authorizationStatusResult = .authorized

        let useCase = ScheduleNotificationsUseCase(notificationService: mockService)
        try await useCase.execute()

        #expect(mockService.scheduleNotificationCalled == true)
        #expect(mockService.scheduleNotificationIdentifiers.count == 60) // 30 days × 2
    }

    @Test func execute_skipsSchedulingWhenDenied() async throws {
        let mockService = MockNotificationService()
        mockService.authorizationStatusResult = .denied

        let useCase = ScheduleNotificationsUseCase(notificationService: mockService)
        try await useCase.execute()

        // Verify graceful degradation (NOTIF-03)
        #expect(mockService.scheduleNotificationCalled == false)
    }

    @Test func execute_skipsSchedulingWhenNotDetermined() async throws {
        let mockService = MockNotificationService()
        mockService.authorizationStatusResult = .notDetermined

        let useCase = ScheduleNotificationsUseCase(notificationService: mockService)
        try await useCase.execute()

        #expect(mockService.scheduleNotificationCalled == false)
    }
}
```

### Example 2: Testing Date-Specific Identifier Generation

```swift
// Pattern for testing identifier format without hardcoding dates
@Test func execute_usesDateSpecificIdentifiers() async throws {
    let mockService = MockNotificationService()
    mockService.authorizationStatusResult = .authorized

    let useCase = ScheduleNotificationsUseCase(notificationService: mockService)
    try await useCase.execute()

    // Verify identifier format matches "type-YYYY-MM-DD" pattern
    let identifiers = mockService.scheduleNotificationIdentifiers
    #expect(identifiers.count == 60) // 30 days × 2 types

    // Verify lunch identifiers follow pattern
    let lunchIdentifiers = identifiers.filter { $0.contains("lunch-reminder-") }
    #expect(lunchIdentifiers.count == 30)

    // Verify date portion is valid (YYYY-MM-DD format)
    for identifier in lunchIdentifiers {
        let components = identifier.split(separator: "-")
        #expect(components.count == 5) // ["lunch", "reminder", "YYYY", "MM", "DD"]
        #expect(components[2].count == 4) // Year has 4 digits
        #expect(components[3].count == 2) // Month has 2 digits
        #expect(components[4].count == 2) // Day has 2 digits
    }
}
```

### Example 3: Testing Cancellation Logic

```swift
// Pattern for testing cancellation with today's date
@Test func execute_cancelsTodayNotifications() async throws {
    let mockService = MockNotificationService()
    let useCase = CancelNotificationsUseCase(notificationService: mockService)

    try await useCase.execute()

    // Verify both pending and delivered notifications canceled
    #expect(mockService.cancelNotificationsCalled == true)
    #expect(mockService.removeDeliveredNotificationsCalled == true)

    // Verify correct identifiers used (today's date)
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    let todayString = formatter.string(from: Date())

    let expectedIdentifiers = [
        "lunch-reminder-\(todayString)",
        "evening-reminder-\(todayString)"
    ]

    #expect(mockService.cancelNotificationsIdentifiers.first == expectedIdentifiers)
    #expect(mockService.removeDeliveredNotificationsIdentifiers.first == expectedIdentifiers)
}
```

### Example 4: Testing Permission Request with Error Handling

```swift
// Pattern for testing error propagation
@Test func execute_propagatesAuthorizationError() async throws {
    let mockService = MockNotificationService()
    mockService.requestAuthorizationError = NSError(
        domain: "TestError",
        code: -1,
        userInfo: [NSLocalizedDescriptionKey: "Test error"]
    )

    let useCase = RequestNotificationPermissionUseCase(notificationService: mockService)

    // Verify error propagates to caller
    await #expect(throws: Error.self) {
        try await useCase.execute()
    }

    #expect(mockService.requestAuthorizationCalled == true)
}
```

### Example 5: Manual Test Plan Structure (UAT.md)

```markdown
---
status: pending
phase: 04-testing-and-refinement
source: 04-01-SUMMARY.md
started: 2026-03-01T00:00:00Z
updated: 2026-03-01T00:00:00Z
---

## Current Test

[test number or "testing complete"]

## Tests

### 1. All Unit Tests Pass
expected: Run Cmd+U in Xcode. All tests in HealthTrackerTests pass without failures. Tests cover ScheduleNotificationsUseCase, CancelNotificationsUseCase, and RequestNotificationPermissionUseCase with various scenarios (authorization states, error cases, edge cases).
result: [pending/pass/fail]

### 2. Notifications Fire at Correct Times (Debug Mode)
expected: Launch debug build. Grant notification permission. Notifications should fire 2-3 minutes after launch (testable times in debug). Check notification titles match "HealthTracker" and bodies match Portuguese-BR messages.
result: [pending/pass/fail]

### 3. Permission Denial Graceful Degradation
expected: Fresh install. When permission prompt appears, tap "Don't Allow". App should continue normally without crashes. No notifications scheduled (check device notification settings). App remains functional for logging data.
result: [pending/pass/fail]

### 4. Time Zone Change Handling
expected: Install app, grant permissions, schedule notifications. Change device time zone in Settings (e.g., from Pacific to Eastern). Notifications should fire at 1 PM and 8 PM in NEW time zone, not original time zone.
result: [pending/pass/fail]

### 5. DST Transition Handling
expected: Manually change device date to night before DST change (e.g., March 9, 2026 for Spring Forward). Grant permissions. Change date to DST day (March 10). Notifications should fire at 1 PM and 8 PM DST time (adjusted for hour change).
result: [pending/pass/fail]

### 6. Force Quit After Data Save
expected: Log any health data (meal, workout, water, or mood). Immediately force quit app (swipe up in app switcher). Relaunch app. Wait for notification time in debug build. No notification should fire today (cancellation persisted through force quit per NOTIF-14).
result: [pending/pass/fail]

### 7. Rapid Data Entry Cancellation
expected: Open app, log meal, log workout, log water, log mood in rapid succession (within 30 seconds). Wait for notification times. Only one cancellation should occur (no duplicate cancellation calls causing issues). No notifications fire today.
result: [pending/pass/fail]

## Summary

total: 7
passed: 0
issues: 0
pending: 7
skipped: 0

## Gaps

[none yet]
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| XCTest with XCTestCase classes | Swift Testing with @Test structs | Xcode 16 (2024) | Faster compilation, less memory overhead, better async support |
| XCTAssert functions | #expect and #require macros | Swift Testing (2024) | More composable, better error messages, no manual message strings |
| Expectation-based async testing | Native async/await in @Test | Swift Testing (2024) | Simpler async tests, no manual expectations or timeout management |
| setUp/tearDown lifecycle | Per-test initialization | Swift Testing (2024) | More explicit, less hidden state, easier to debug |
| Test discovery via naming (test...) | @Test macro | Swift Testing (2024) | More flexible naming, metadata support, better organization |

**Deprecated/outdated:**
- XCTest for new code (still works, but Swift Testing is preferred for new tests)
- waitForExpectations for async code (replaced by native async/await)
- XCTUnwrap (replaced by #require macro)

## Open Questions

1. **Should we test the fire-and-forget Task pattern in MainViewModel?**
   - What we know: CancelNotificationsUseCase is called via `Task { try? await cancelNotificationsUseCase.execute() }` in MainViewModel.persistChanges()
   - What's unclear: Whether to test the fire-and-forget pattern specifically or just test the Use Case independently
   - Recommendation: Test Use Case independently with awaited execution. Testing fire-and-forget adds complexity (timing, race conditions) with minimal value. Trust Swift's Task implementation.

2. **How comprehensive should error path testing be?**
   - What we know: MockNotificationService supports error injection via `requestAuthorizationError`
   - What's unclear: Whether to test every possible iOS error scenario or focus on high-level error propagation
   - Recommendation: Test that errors propagate (one test with generic error), don't enumerate every UNError code. iOS framework errors are Apple's responsibility - we verify our code doesn't swallow them.

3. **Should we add performance tests for notification scheduling?**
   - What we know: ScheduleNotificationsUseCase schedules 60 notifications (30 days × 2)
   - What's unclear: Whether scheduling 60 notifications could cause performance issues
   - Recommendation: Skip performance tests initially. 60 notifications is small - iOS handles thousands. Monitor during manual testing; add performance tests if issues observed.

## Validation Architecture

> Note: Phase 4 itself validates the notification system, so this section documents the validation approach rather than requiring new test infrastructure.

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Swift Testing (Xcode 16+) |
| Config file | None - built into Xcode project |
| Quick run command | `Cmd+U` in Xcode (runs all tests) |
| Specific test command | `xcodebuild test -scheme HealthTracker -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest'` |
| Manual test plan | `.planning/phases/04-testing-and-refinement/04-UAT.md` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| NOTIF-20 | Use Cases work with mock service | unit | See below | ✅ MockNotificationService.swift exists |
| NOTIF-21 | ScheduleNotificationsUseCase schedules notifications correctly | unit | `Cmd+U` → ScheduleNotificationsUseCaseTests | ✅ Needs enhancement |
| NOTIF-21 | CancelNotificationsUseCase cancels notifications correctly | unit | `Cmd+U` → CancelNotificationsUseCaseTests | ✅ Needs enhancement |
| NOTIF-21 | RequestNotificationPermissionUseCase handles permissions | unit | `Cmd+U` → RequestNotificationPermissionUseCaseTests | ✅ Complete |
| NOTIF-22 | Notifications fire at 1 PM and 8 PM on device | manual | Device test per UAT.md | ❌ UAT.md needed |
| NOTIF-22 | Time zone changes don't break notifications | manual | Device test per UAT.md | ❌ UAT.md needed |
| NOTIF-22 | DST transitions handled correctly | manual | Device test per UAT.md | ❌ UAT.md needed |
| NOTIF-22 | Force quit doesn't break cancellation | manual | Device test per UAT.md | ❌ UAT.md needed |

### Test Execution Strategy
- **Per task commit:** Run related test file (e.g., `Cmd+T` on current test file)
- **Per plan completion:** Run full test suite (`Cmd+U` - all unit tests)
- **Phase gate:** All unit tests pass + manual UAT.md tests completed before phase verification

### Wave 0 Gaps

**Unit Tests:**
- ✅ MockNotificationService - exists, comprehensive tracking
- ✅ ScheduleNotificationsUseCaseTests - exists, needs enhancement for 30-day scheduling, date-specific identifiers
- ✅ CancelNotificationsUseCaseTests - exists, has Wave 0 scaffolds with placeholder assertions, needs full implementation
- ✅ RequestNotificationPermissionUseCaseTests - exists, complete coverage

**Manual Tests:**
- ❌ `04-UAT.md` - needs creation with 7 manual test cases covering notification firing, edge cases (time zone, DST, force quit)

**Test Coverage Enhancements Needed:**
1. ScheduleNotificationsUseCaseTests:
   - Enhance Wave 0 scaffolds (lines 138-173) with full assertions
   - Verify 60 notifications scheduled (30 days × 2)
   - Verify date-specific identifiers match "type-YYYY-MM-DD" pattern
   - Verify non-repeating notifications (repeats: false)
   - Verify full DateComponents (year, month, day, hour, minute)

2. CancelNotificationsUseCaseTests:
   - Uncomment placeholder tests (lines 14-63)
   - Implement real Use Case calls with proper assertions
   - Test both pending and delivered notification removal
   - Test identifier generation with today's date
   - Test that only 2 notifications canceled (lunch + evening for today)

## Sources

### Primary (HIGH confidence)
- Swift Testing Official Documentation (developer.apple.com/documentation/testing) - Test framework patterns, async testing, MainActor isolation
- Context7 /websites/developer_apple_testing - Code examples for @Test macros, #expect assertions, async/await patterns
- Existing HealthTracker test suite - MockNotificationService.swift, existing Use Case test patterns, project-specific conventions
- iOS UserNotifications Documentation (developer.apple.com) - Notification persistence guarantees, calendar trigger behavior

### Secondary (MEDIUM confidence)
- Phase 1-3 RESEARCH.md files - Established patterns for Clean Architecture testing, mock usage, integration approaches
- Phase 3 UAT.md - Manual test plan format and structure for device testing
- Existing Use Case implementations - Debug logging patterns, async patterns, error handling

### Tertiary (LOW confidence)
- None - all findings verified with official documentation or existing codebase

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Swift Testing officially documented, project already uses it
- Architecture: HIGH - Existing tests demonstrate patterns, MockNotificationService comprehensive
- Pitfalls: HIGH - Based on common iOS testing issues (async race conditions, date handling, over-mocking)
- Edge cases: MEDIUM - iOS notification edge cases (time zone, DST, force quit) documented in Apple docs but behavior verification requires device testing

**Research date:** 2026-03-01
**Valid until:** 2026-06-01 (3 months - Swift Testing stable, iOS notification APIs stable since iOS 10)

**Key findings:**
1. MockNotificationService exists with comprehensive tracking - no new mock infrastructure needed
2. Swift Testing provides excellent async/await support - no custom test helpers needed
3. NotificationService should NOT be unit tested - thin wrapper with no business logic
4. Wave 0 scaffolds exist in CancelNotificationsUseCaseTests - need uncommenting and implementation
5. Manual testing crucial for iOS integration - time zone, DST, force quit can't be unit tested
6. Debug logging already adequate - simple print() statements with prefixed tags provide visibility
