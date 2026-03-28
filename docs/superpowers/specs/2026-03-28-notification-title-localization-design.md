# Notification Title Localization Fix

**Date:** 2026-03-28
**Status:** Approved

## Problem

Notification titles show the wrong language. The app name in push notifications is always returned from `Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName")`, which bypasses localization and ignores the device language setting. On an English device it should show "Essential Health"; on a Portuguese device, "Saúde Essencial".

The `InfoPlist.xcstrings` already has both translations:
- `en`: "Essential Health"
- `pt-BR`: "Saúde Essencial"

The notification bodies (`notification_lunch`, `notification_evening`) already work correctly via `String(localized:)` — only the title is broken.

## Solution

Replace the title lookup in `ScheduleNotificationsUseCase` with `Bundle.main.localizedInfoDictionary`, which reads from `InfoPlist.xcstrings` and respects the device language.

**File:** `HealthTracker/Domain/UseCases/ScheduleNotificationsUseCase.swift`
**Lines affected:** 70 and 79 (identical expressions, both lunch and evening notification scheduling)

### Before

```swift
title: Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ?? String(localized: "app_title")
```

### After

```swift
title: Bundle.main.localizedInfoDictionary?["CFBundleDisplayName"] as? String
    ?? Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
    ?? String(localized: "app_title")
```

### Fallback chain

1. `localizedInfoDictionary?["CFBundleDisplayName"]` — reads `InfoPlist.xcstrings`, returns device-language app name (primary fix)
2. `Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName")` — non-localized plist value (safety net if xcstrings is missing)
3. `String(localized: "app_title")` — last-resort fallback (kept from original)

## Scope

- **1 file changed:** `ScheduleNotificationsUseCase.swift`
- **2 lines changed:** identical expression replaced in both lunch and evening notification calls
- No new files, no new strings, no test changes (existing tests check bodies, not titles)
