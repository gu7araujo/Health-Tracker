---
id: 260328-jdf
slug: fix-mood-button-tappability-in-main-view
phase: quick
plan: 260328-jdf
subsystem: UI / CardView
tags: [bugfix, swiftui, liquid-glass, hit-testing]
completed: "2026-03-28T17:02:21Z"
duration: "~3 min"

key-files:
  modified:
    - HealthTracker/Presentation/Views/Components/CardView.swift

decisions:
  - Apply glassEffect to the Button (outside label) rather than inside it — correct iOS 26 Liquid Glass pattern for tappable glass cards
  - Add activeGlassStyle computed property to avoid duplicating tint logic between body and card

metrics:
  tasks_completed: 1
  files_modified: 1
---

# Quick Task 260328-jdf: Fix Mood Button Tappability Summary

**One-liner:** Moved `glassEffect` from inside Button's label to outside it, following the correct iOS 26 Liquid Glass interactive button pattern so the full card area is tappable.

## What Was Done

`CardView.body` previously had a single branch for `action != nil` that called `Button(action:label:{ card })`, where `card` itself contained `.glassEffect(...interactive(), ...)`. This created a nested interactive glass layer that only hit-tested the visible content (icon + text), not the full card surface.

The fix adds a new branch in `body`:

```swift
if let action, applyGlassEffect {
    Button(action: action) {
        content.padding(internalPadding)
    }
    .buttonStyle(.plain)
    .glassEffect(activeGlassStyle, in: RoundedRectangle(cornerRadius: 16))
} else if let action {
    // existing non-glass button (unchanged)
} else {
    card  // existing display-only path (unchanged)
}
```

A new `activeGlassStyle` computed property centralizes the tint logic:

```swift
private var activeGlassStyle: GlassEffectStyle {
    if let glassTint {
        .regular.tint(glassTint).interactive()
    } else {
        .regular.interactive()
    }
}
```

The existing `card` computed property and the non-glass button branch are untouched.

## Tasks Completed

| # | Task | Commit |
|---|------|--------|
| 1 | Fix CardView glass button pattern | 7b03e89 |

## Deviations from Plan

None — plan executed exactly as written.

## Self-Check: PASSED

- [x] `HealthTracker/Presentation/Views/Components/CardView.swift` modified and verified
- [x] Commit `7b03e89` exists
