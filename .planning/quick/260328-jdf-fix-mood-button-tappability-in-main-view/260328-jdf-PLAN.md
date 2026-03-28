---
id: 260328-jdf
slug: fix-mood-button-tappability-in-main-view
description: Fix mood button tappability in main view List section
date: 2026-03-28
---

# Quick Task 260328-jdf: Fix Mood Button Tappability

## Root Cause

`CardView` applies `.glassEffect(.interactive(), ...)` **inside** the Button label, creating a nested interactive glass layer. This causes only the content area (icon + text) to be tappable, not the full glass card area.

The iOS 26 Liquid Glass reference pattern for custom glass buttons is:
```swift
Button(action: action) {
    content.padding(...)
}
.glassEffect(.regular.interactive(), in: shape)
```

The glass should wrap the Button — not be nested inside the Button's label.

## Files

- `HealthTracker/HealthTracker/Presentation/Views/Components/CardView.swift`

## Tasks

### Task 1: Fix CardView glass button pattern

**Action:** Restructure `CardView.body` so that when both `action != nil` and `applyGlassEffect == true`, the `glassEffect` is applied to the Button (outside its label), not inside it.

**Before (broken):**
```swift
var body: some View {
    if let action {
        Button(action: action, label: { card })  // card contains glassEffect inside
            .contentShape(.rect(cornerRadius: 16))
            .buttonStyle(.plain)
    } else {
        card
    }
}
```

**After (fixed):**
```swift
var body: some View {
    if let action, applyGlassEffect {
        // Glass applied to Button (outside label) — correct Liquid Glass pattern
        Button(action: action) {
            content.padding(internalPadding)
        }
        .buttonStyle(.plain)
        .glassEffect(activeGlassStyle, in: RoundedRectangle(cornerRadius: 16))
    } else if let action {
        Button(action: action, label: { card })
            .contentShape(.rect(cornerRadius: 16))
            .buttonStyle(.plain)
    } else {
        card
    }
}

private var activeGlassStyle: GlassEffectStyle {
    if let glassTint {
        .regular.tint(glassTint).interactive()
    } else {
        .regular.interactive()
    }
}
```

**Verify:** Mood buttons in the main view are tappable across their full glass card area, not just the icon/text content.

**Done:** All five mood buttons respond to taps anywhere on the glass card.

## Commit Message

```
fix(quick-260328-jdf): fix mood button hit area by applying glassEffect to Button, not inside label
```
