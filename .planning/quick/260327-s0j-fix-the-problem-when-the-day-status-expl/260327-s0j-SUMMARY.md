---
phase: quick
plan: 260327-s0j
subsystem: ui
tags: [swiftui, list, layout, animation]

requires: []
provides:
  - Day status explanation text merged into calendar strip row in MainView
  - No-layout-shift pattern for conditionally visible content within List rows
affects: [MainView]

tech-stack:
  added: []
  patterns: [VStack inside List row to embed conditional content without inserting/removing rows]

key-files:
  created: []
  modified:
    - HealthTracker/Presentation/Views/MainView.swift

key-decisions:
  - "Embed explanation text in datePickerSection VStack instead of separate List row — eliminates row insertion/removal and the resulting scroll jump"
  - "Use .animation(.easeInOut(duration: 0.2), value: viewModel.currentDayStatus) on the VStack for smooth fade without layout shift"
  - "Remove DayStatusExplanationView struct after inlining — no dead code left in file"

patterns-established:
  - "Conditional in-row content: wrap List row content in VStack and conditionally show additional views inside, never as sibling rows"

requirements-completed: []

duration: 2min
completed: 2026-03-27
---

# Quick Task 260327-s0j: Fix Day Status Explanation Layout Shift Summary

**Day status explanation text merged into the calendar strip List row using VStack, eliminating the scroll-jump caused by row insertion/removal.**

## Performance

- **Duration:** ~2 min
- **Started:** 2026-03-27T23:12:39Z
- **Completed:** 2026-03-27T23:13:47Z
- **Tasks:** 1
- **Files modified:** 1

## Accomplishments

- Removed `DayStatusExplanationView` as a standalone List row from `MainView.body`
- Wrapped `CalendarStrip` in a `VStack` inside `datePickerSection` and added the conditional explanation `Text` below it
- Added `.animation(.easeInOut(duration: 0.2), value: viewModel.currentDayStatus)` to smoothly fade the text in/out
- Removed the now-unused `DayStatusExplanationView` private struct to keep the file clean
- Build succeeds with no errors

## Task Commits

1. **Task 1: Merge explanation text into the calendar strip row** - `67e1744` (fix)

**Plan metadata:** (see below)

## Files Created/Modified

- `HealthTracker/Presentation/Views/MainView.swift` - Merged DayStatusExplanationView into datePickerSection VStack; removed DayStatusExplanationView struct

## Decisions Made

- Used VStack inside the existing `datePickerSection` row rather than a separate row so no row is ever inserted or removed from the List. The row is always present; only the text inside it conditionally appears. This prevents the list from recalculating row heights and scrolling abruptly.
- Kept `.listRowSeparator(.hidden)` and `.listRowInsets` on the outer VStack so list row styling remains unchanged.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Layout shift fix is complete and verified via successful Xcode build
- No blockers or concerns

---
*Phase: quick*
*Completed: 2026-03-27*

## Self-Check: PASSED

- `HealthTracker/Presentation/Views/MainView.swift` — FOUND (modified, `DayStatusExplanationView` standalone row removed, `datePickerSection` updated with VStack)
- Commit `67e1744` — FOUND
