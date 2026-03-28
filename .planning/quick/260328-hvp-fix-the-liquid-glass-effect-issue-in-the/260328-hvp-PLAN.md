---
phase: quick-260328-hvp
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - HealthTracker/Presentation/Views/Components/CardView.swift
autonomous: true
requirements: []

must_haves:
  truths:
    - "Mood buttons with Liquid Glass effect have no visible shadow or artifact at the border/radius area"
    - "Non-glass cards (solid background) still render with correct rounded corners"
    - "Glass-effect cards used for tappable elements include .interactive() for proper interaction feedback"
  artifacts:
    - path: "HealthTracker/Presentation/Views/Components/CardView.swift"
      provides: "Fixed glass effect rendering without clipShape conflict"
  key_links:
    - from: "CardView"
      to: "glassEffect modifier"
      via: ".glassEffect(in: .rect(cornerRadius: 16))"
      pattern: "glassEffect.*cornerRadius"
---

<objective>
Fix the Liquid Glass shadow/border artifact on mood buttons in the main view.

Purpose: The current CardView applies `.clipShape(.rect(cornerRadius: 0))` when `applyGlassEffect` is true. This sharp rectangular clip conflicts with the glass effect's own rounded shape rendering — the glass effect draws rounded corners internally but the clip then cuts across them, creating visible shadow artifacts at the border edges.

Output: Updated CardView.swift where the clipShape is only applied on the non-glass path, and glass buttons use `.interactive()` for correct interaction feedback.
</objective>

<execution_context>
@/Users/gustavosantos/Documents/Projects/Personal/Real-app-repos/HealthTracker/.claude/get-shit-done/workflows/execute-plan.md
@/Users/gustavosantos/Documents/Projects/Personal/Real-app-repos/HealthTracker/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@HealthTracker/Presentation/Views/Components/CardView.swift

<interfaces>
<!-- Current CardView body — root cause is on the clipShape line -->

```swift
var body: some View {
    Button(action: action ?? {}, label: {
        content
            .padding(internalPadding)
            .if(applyGlassEffect) { view in
                view.glassEffect(in: .rect(cornerRadius: 16))
            }
            .background(backgroundColor)
            .clipShape(.rect(cornerRadius: applyGlassEffect ? 0 : 16))  // BUG: cornerRadius 0 clips glass shape
    })
    .buttonStyle(.plain)
}
```

Root cause: `.glassEffect(in: .rect(cornerRadius: 16))` renders its own rounded shape.
Then `.clipShape(.rect(cornerRadius: 0))` clips the view with a SHARP rectangle, cutting
through the glass effect's rounded border rendering and producing visible shadow artifacts.

Fix: Only apply clipShape on the non-glass path (cornerRadius: 16 for solid cards).
When glass effect is active, skip clipShape — the glass modifier owns the shape.

Also: glass-effect buttons are tappable, so `.interactive()` should be added per
the Liquid Glass guidelines (interactive() only on user-interactable elements).
</interfaces>
</context>

<tasks>

<task type="auto">
  <name>Task 1: Fix CardView glass effect clipping and add interactive modifier</name>
  <files>HealthTracker/Presentation/Views/Components/CardView.swift</files>
  <action>
    Two targeted changes to the `body` computed property:

    1. Remove the conflicting clipShape when glass is active. Change:
       ```swift
       .clipShape(.rect(cornerRadius: applyGlassEffect ? 0 : 16))
       ```
       To only apply clipShape on the non-glass path using the `.if` extension:
       ```swift
       .if(!applyGlassEffect) { view in
           view.clipShape(.rect(cornerRadius: 16))
       }
       ```
       This ensures clipShape is only applied to solid-background cards (non-glass), while glass cards let the glassEffect modifier own the shape entirely.

    2. Add `.interactive()` to the glass effect call since CardView with glass is always used for tappable elements (it wraps a Button):
       ```swift
       .if(applyGlassEffect) { view in
           view.glassEffect(.regular.interactive(), in: .rect(cornerRadius: 16))
       }
       ```

    Final body should look like:
    ```swift
    var body: some View {
        Button(action: action ?? {}, label: {
            content
                .padding(internalPadding)
                .if(applyGlassEffect) { view in
                    view.glassEffect(.regular.interactive(), in: .rect(cornerRadius: 16))
                }
                .background(backgroundColor)
                .if(!applyGlassEffect) { view in
                    view.clipShape(.rect(cornerRadius: 16))
                }
        })
        .buttonStyle(.plain)
    }
    ```

    Do NOT change the initializer, properties, or any other file.
  </action>
  <verify>Build succeeds: open the project in Xcode or run `xcodebuild -scheme HealthTracker -destination "platform=iOS Simulator,name=iPhone 16" build 2>&1 | tail -5`</verify>
  <done>No shadow/border artifact visible on mood buttons. Glass buttons show clean rounded glass without clipping artifacts. Solid-background cards (meals, water, workouts) still render with correct rounded corners.</done>
</task>

</tasks>

<verification>
Build compiles without errors. In the simulator, the mood section buttons (unselected state, which uses `applyGlassEffect: true`) show clean Liquid Glass with no visible shadow or artifact at the border radius edges.
</verification>

<success_criteria>
- CardView.swift updated with glass path using `.glassEffect(.regular.interactive(), in: .rect(cornerRadius: 16))` and NO clipShape
- CardView.swift non-glass path uses `.clipShape(.rect(cornerRadius: 16))`
- Project builds successfully
</success_criteria>

<output>
After completion, create `.planning/quick/260328-hvp-fix-the-liquid-glass-effect-issue-in-the/260328-hvp-SUMMARY.md`
</output>
