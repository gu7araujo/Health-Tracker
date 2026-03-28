---
phase: quick
plan: 260328-ixs
type: execute
wave: 1
depends_on: []
files_modified:
  - HealthTracker/Presentation/Views/Components/CardView.swift
  - HealthTracker/Presentation/Views/MainView.swift
autonomous: true
requirements: []
must_haves:
  truths:
    - "Selected mood button shows a colored glass effect (tinted glass), not a solid color fill"
    - "Unselected mood buttons retain their plain glass appearance"
    - "The glass tint color matches the mood's semantic color (green=good, orange=neutral, red=sad)"
  artifacts:
    - path: "HealthTracker/Presentation/Views/Components/CardView.swift"
      provides: "CardView with optional glassTint parameter"
    - path: "HealthTracker/Presentation/Views/MainView.swift"
      provides: "moodButton passing mood.color as glassTint when selected"
  key_links:
    - from: "MainView.swift moodButton"
      to: "CardView glassTint"
      via: "glassTint parameter on CardView init"
      pattern: "glassTint.*mood\\.color"
---

<objective>
Update mood buttons so that when a mood is selected, it renders with a colored glass effect (using `.glassEffect(.regular.tint(color).interactive())`) instead of the current solid color background. Unselected buttons continue to use plain glass.

Purpose: Visual consistency — selected mood buttons should feel like interactive glass with a color tint, matching iOS 26 Liquid Glass design language, rather than breaking out to a solid opaque fill.
Output: CardView gains an optional glassTint parameter; MoodSectionView passes the mood color as tint when selected.
</objective>

<execution_context>
@/Users/gustavosantos/Documents/Projects/Personal/Real-app-repos/HealthTracker/.claude/get-shit-done/workflows/execute-plan.md
@/Users/gustavosantos/Documents/Projects/Personal/Real-app-repos/HealthTracker/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@HealthTracker/Presentation/Views/Components/CardView.swift
@HealthTracker/Presentation/Views/MainView.swift
@HealthTracker/Domain/Entities/Mood.swift

<interfaces>
<!-- CardView current signature -->
```swift
struct CardView<Content: View>: View {
    init(
        internalPadding: EdgeInsets? = nil,
        applyGlassEffect: Bool = true,
        backgroundColor: Binding<Color?> = .constant(nil),
        action: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    )
}
```

<!-- Mood color property -->
```swift
var color: Color {
    case .good:    .green
    case .neutral: .orange
    case .sad:     .red
}
```

<!-- Current moodButton call site (MainView.swift ~line 366) -->
```swift
CardView(
    applyGlassEffect: !isSelected,
    backgroundColor: .constant(isSelected ? mood.color : nil)
) {
    onUpdateMood(mood)
} content: { ... }
```

<!-- GlassEffectStyle tinting API (iOS 26+) -->
```swift
.glassEffect(.regular.tint(.green).interactive(), in: RoundedRectangle(cornerRadius: 16))
```
</interfaces>
</context>

<tasks>

<task type="auto">
  <name>Task 1: Add glassTint parameter to CardView</name>
  <files>HealthTracker/Presentation/Views/Components/CardView.swift</files>
  <action>
Add an optional `glassTint: Color?` parameter (default `nil`) to CardView's initializer. When `applyGlassEffect` is true and a tint is provided, apply `.glassEffect(.regular.tint(tint).interactive(), in: RoundedRectangle(cornerRadius: 16))`. When no tint is provided (existing behavior), apply `.glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 16))`.

Remove the `backgroundColor` binding from the glass branch entirely (the `.background(backgroundColor)` on the glass path was unused for coloring since glass is translucent — the old solid fill is being replaced by tinting). Keep `backgroundColor` on the non-glass branch (`applyGlassEffect: false`) unchanged since it is still used by other card instances (meals, water, workouts).

The updated `card` computed property should look like:

```swift
@ViewBuilder
private var card: some View {
    if applyGlassEffect {
        if let glassTint {
            content
                .padding(internalPadding)
                .glassEffect(.regular.tint(glassTint).interactive(), in: RoundedRectangle(cornerRadius: 16))
        } else {
            content
                .padding(internalPadding)
                .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 16))
        }
    } else {
        content
            .padding(internalPadding)
            .background(backgroundColor)
            .clipShape(.rect(cornerRadius: 16))
    }
}
```

Store `glassTint` as a `private let glassTint: Color?` property, initialized in `init`. The `backgroundColor` binding stays for the non-glass branch. No other callers pass `glassTint`, so all existing call sites remain unaffected (default `nil`).
  </action>
  <verify>Project builds without errors. Existing CardView callers (meals, water, workouts sections) compile unchanged.</verify>
  <done>CardView accepts optional glassTint; glass branch conditionally applies .tint(); non-glass branch is unchanged.</done>
</task>

<task type="auto">
  <name>Task 2: Update moodButton to use colored glass when selected</name>
  <files>HealthTracker/Presentation/Views/MainView.swift</files>
  <action>
In `MoodSectionView.moodButton(for:)`, change the CardView call to always use `applyGlassEffect: true` and pass `glassTint: isSelected ? mood.color : nil`. Remove `backgroundColor` (no longer needed for mood buttons).

Updated call site:

```swift
CardView(
    applyGlassEffect: true,
    glassTint: isSelected ? mood.color : nil
) {
    onUpdateMood(mood)
} content: {
    HStack {
        Spacer()
        VStack {
            Text(mood.emoji)
                .font(.title)
            Text(mood.localizedName)
                .font(.caption)
        }
        Spacer()
    }
}
.frame(maxWidth: .infinity)
```

This means:
- Unselected: plain `.glassEffect(.regular.interactive())` — no change from current unselected appearance
- Selected: `.glassEffect(.regular.tint(mood.color).interactive())` — colored glass instead of solid fill
  </action>
  <verify>Project builds and runs in simulator. Tapping a mood button shows a color-tinted glass card. Tapping another mood transfers the tint. Unselected buttons show plain glass.</verify>
  <done>Selected mood buttons display colored glass (tinted); unselected buttons display plain glass; no solid color background on any mood button.</done>
</task>

</tasks>

<verification>
Build project and run on iOS 26 simulator. Navigate to the mood section in MainView. Verify:
1. Tapping "Good" (😁) makes that card show green-tinted glass
2. Tapping "Neutral" (😐) moves the tint to orange
3. Tapping "Sad" (😔) moves the tint to red
4. The previously selected card returns to plain (untinted) glass
5. No visual regressions in meals, water, or workouts sections
</verification>

<success_criteria>
All mood buttons use glass effect at all times. Selected mood shows color-tinted glass matching mood.color. Unselected moods show plain glass. No solid-fill backgrounds on mood buttons. Project builds cleanly.
</success_criteria>

<output>
After completion, create `.planning/quick/260328-ixs-update-mood-buttons-to-use-colored-glass/260328-ixs-SUMMARY.md`
</output>
