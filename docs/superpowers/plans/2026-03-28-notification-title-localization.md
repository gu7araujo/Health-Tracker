# Notification Title Localization Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix notification titles so they display the localized app name ("Essential Health" or "Saúde Essencial") matching the device language.

**Architecture:** Replace `Bundle.main.object(forInfoDictionaryKey:)` with `Bundle.main.localizedInfoDictionary?[:]` in both notification scheduling calls. `localizedInfoDictionary` reads from `InfoPlist.xcstrings` and returns the device-language value. A two-level fallback is kept for safety.

**Tech Stack:** Swift, `Foundation.Bundle`, `UserNotifications`

---

## File Map

| Action | File |
|--------|------|
| Modify | `HealthTracker/HealthTracker/Domain/UseCases/ScheduleNotificationsUseCase.swift` (lines 70, 79) |

No new files. No test file changes (existing tests check bodies, not titles).

---

### Task 1: Replace the title lookup in ScheduleNotificationsUseCase

**Files:**
- Modify: `HealthTracker/HealthTracker/Domain/UseCases/ScheduleNotificationsUseCase.swift:70,79`

- [ ] **Step 1: Locate the two title expressions**

Open `HealthTracker/HealthTracker/Domain/UseCases/ScheduleNotificationsUseCase.swift`.

Lines 68–74 (lunch notification):
```swift
// Schedule lunch notification (NOTIF-05, NOTIF-07)
try await notificationService.scheduleNotification(
    identifier: "lunch-reminder-\(dateString)",
    title: Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ?? String(localized: "app_title"),
    body: String(localized: "notification_lunch"),
    dateComponents: lunchComponents,
    repeats: false
)
```

Lines 76–83 (evening notification):
```swift
// Schedule evening notification (NOTIF-06, NOTIF-08)
try await notificationService.scheduleNotification(
    identifier: "evening-reminder-\(dateString)",
    title: Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ?? String(localized: "app_title"),
    body: String(localized: "notification_evening"),
    dateComponents: eveningComponents,
    repeats: false
)
```

- [ ] **Step 2: Replace both title expressions**

Replace line 71 (lunch title) from:
```swift
                title: Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ?? String(localized: "app_title"),
```
To:
```swift
                title: Bundle.main.localizedInfoDictionary?["CFBundleDisplayName"] as? String
                    ?? Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
                    ?? String(localized: "app_title"),
```

Replace line 79 (evening title) from:
```swift
                title: Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ?? String(localized: "app_title"),
```
To:
```swift
                title: Bundle.main.localizedInfoDictionary?["CFBundleDisplayName"] as? String
                    ?? Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
                    ?? String(localized: "app_title"),
```

- [ ] **Step 3: Build the project to confirm no compilation errors**

In Xcode: **Product → Build** (⌘B).

Expected: Build succeeds with no errors or warnings related to the changed lines.

- [ ] **Step 4: Run the existing notification tests**

In Xcode: open `HealthTrackerTests/Domain/UseCases/ScheduleNotificationsUseCaseTests.swift` and run the test suite (**⌘U**).

Expected: All tests pass. The tests verify notification bodies and scheduling behavior — they do not assert on titles, so no test changes are needed.

- [ ] **Step 5: Manually verify on device/simulator**

1. Run the app on a simulator set to **English** (Settings → General → Language & Region → iPhone Language: English).
2. Grant notification permission if prompted.
3. Wait for the debug notifications to fire (2–3 minutes after launch, per the DEBUG timing in `notificationTiming(for:)`).
4. Confirm the notification banner shows **"Essential Health"** as the title.
5. Repeat with simulator set to **Portuguese (Brazil)**.
6. Confirm the notification banner shows **"Saúde Essencial"** as the title.

- [ ] **Step 6: Commit**

```bash
git add HealthTracker/HealthTracker/Domain/UseCases/ScheduleNotificationsUseCase.swift
git commit -m "fix: use localizedInfoDictionary for notification title to respect device language"
```
