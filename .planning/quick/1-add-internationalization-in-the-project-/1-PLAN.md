---
phase: quick-1
plan: 1
type: execute
wave: 1
depends_on: []
files_modified:
  - HealthTracker/Resources/en.lproj/Localizable.strings
  - HealthTracker/Resources/pt-BR.lproj/Localizable.strings
  - HealthTracker/Presentation/Views/MainView.swift
  - HealthTracker/Presentation/Views/AnalyticsView.swift
  - HealthTracker/Presentation/Views/Components/Charts/WaterLineChart.swift
  - HealthTracker/Presentation/Views/Components/Charts/MealsBarChart.swift
  - HealthTracker/Presentation/Views/Components/Charts/MoodBarChart.swift
  - HealthTracker/Presentation/Views/Components/Charts/WorkoutsBarChart.swift
  - HealthTracker/Domain/UseCases/ScheduleNotificationsUseCase.swift
autonomous: true
requirements: [I18N-01]

must_haves:
  truths:
    - User can switch between PT-BR and English language options
    - All UI text displays in the selected language
    - Notification messages respect the device language setting
  artifacts:
    - path: "HealthTracker/Resources/en.lproj/Localizable.strings"
      provides: "English localization strings"
      min_lines: 30
    - path: "HealthTracker/Resources/pt-BR.lproj/Localizable.strings"
      provides: "Portuguese-BR localization strings"
      min_lines: 30
  key_links:
    - from: "HealthTracker/Presentation/Views/MainView.swift"
      to: "Localizable.strings"
      via: "String(localized:)"
      pattern: "String\\(localized:"
    - from: "HealthTracker/Domain/UseCases/ScheduleNotificationsUseCase.swift"
      to: "Localizable.strings"
      via: "String(localized:)"
      pattern: "String\\(localized:"
---

<objective>
Add comprehensive internationalization (i18n) support to HealthTracker app for PT-BR and English languages.

Purpose: Enable the app to reach English-speaking users while maintaining the current Portuguese-BR experience. Allow users to use the app in their preferred language based on device settings.

Output: Fully localized app with string catalogs for PT-BR and English, all hardcoded strings replaced with localized references.
</objective>

<execution_context>
@./.claude/get-shit-done/workflows/execute-plan.md
@./.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/PROJECT.md
@.planning/STATE.md

# Current Implementation Context
The app currently has all strings hardcoded in Portuguese-BR:
- Navigation titles: "Monitore sua saúde"
- Section labels: "Água", "Exercícios"
- UI prompts: "Como está o seu humor hoje?"
- Notification messages: "Registre o que você comeu hoje", "Registre suas refeições e atividades"

# Architecture Context
- iOS 26.0+ native SwiftUI app
- Clean Architecture with Domain/Data/Presentation layers
- Current notification strings in ScheduleNotificationsUseCase (lines 71, 80)
- View strings scattered across MainView, AnalyticsView, and chart components
</context>

<tasks>

<task type="auto">
  <name>Task 1: Create Localizable.strings files for PT-BR and English</name>
  <files>
    HealthTracker/Resources/en.lproj/Localizable.strings
    HealthTracker/Resources/pt-BR.lproj/Localizable.strings
  </files>
  <action>
    Create the localization directory structure and string catalogs:

    1. Create `HealthTracker/Resources/en.lproj/Localizable.strings` with English translations:
       - All navigation titles, section labels, button text
       - Chart axis labels, threshold labels
       - Notification messages
       - Alert and modal text
       - Use clear, natural English without literal translation artifacts

    2. Create `HealthTracker/Resources/pt-BR.lproj/Localizable.strings` with current Portuguese-BR strings:
       - Extract all existing hardcoded PT-BR strings from views
       - Maintain the same keys as English file
       - Preserve current Portuguese text exactly as it appears in the app

    Key strings to localize (minimum):
    - "app_title" = "Monitore sua saúde" / "Track your health"
    - "add_button" = "Adicionar" / "Add"
    - "water_section" = "Água" / "Water"
    - "workouts_section" = "Exercícios" / "Workouts"
    - "mood_prompt" = "Como está o seu humor hoje?" / "How are you feeling today?"
    - "notification_lunch" = "Registre o que você comeu hoje" / "Log what you ate today"
    - "notification_evening" = "Registre suas refeições e atividades" / "Log your meals and activities"
    - Chart labels for all analytics views

    Use standard .strings file format:
    ```
    /* Comment describing usage */
    "key" = "value";
    ```
  </action>
  <verify>
    <automated>
      # Verify files exist and have correct structure
      test -f HealthTracker/Resources/en.lproj/Localizable.strings && \
      test -f HealthTracker/Resources/pt-BR.lproj/Localizable.strings && \
      grep -q "app_title" HealthTracker/Resources/en.lproj/Localizable.strings && \
      grep -q "app_title" HealthTracker/Resources/pt-BR.lproj/Localizable.strings && \
      echo "✓ Localization files created with matching keys"
    </automated>
  </verify>
  <done>Both localization files exist with complete string catalogs, matching keys, and proper .strings format</done>
</task>

<task type="auto">
  <name>Task 2: Replace hardcoded strings with String(localized:) in Views</name>
  <files>
    HealthTracker/Presentation/Views/MainView.swift
    HealthTracker/Presentation/Views/AnalyticsView.swift
    HealthTracker/Presentation/Views/Components/Charts/WaterLineChart.swift
    HealthTracker/Presentation/Views/Components/Charts/MealsBarChart.swift
    HealthTracker/Presentation/Views/Components/Charts/MoodBarChart.swift
    HealthTracker/Presentation/Views/Components/Charts/WorkoutsBarChart.swift
  </files>
  <action>
    Replace all hardcoded Portuguese strings with localized string lookups using Swift's modern String(localized:) API.

    Pattern to follow:
    ```swift
    // Before:
    .navigationTitle("Monitore sua saúde")

    // After:
    .navigationTitle(String(localized: "app_title"))
    ```

    Files to update:
    1. **MainView.swift**: navigationTitle, button text, section labels
    2. **AnalyticsView.swift**: titles, period labels, section headers
    3. **WaterLineChart.swift**: axis labels ("Data", "Litros"), threshold labels ("Ótimo")
    4. **MealsBarChart.swift**: axis labels, data series labels
    5. **MoodBarChart.swift**: axis labels, mood level labels
    6. **WorkoutsBarChart.swift**: axis labels, workout type labels

    Important:
    - Use `String(localized:)` (Swift 5.9+ API), not NSLocalizedString
    - Do NOT add table or bundle parameters - use default bundle
    - Preserve all existing functionality, only replace string literals
    - Keep all view modifiers, styling, and logic unchanged
  </action>
  <verify>
    <automated>
      # Verify localization calls present, no hardcoded Portuguese strings remain
      grep -c "String(localized:" HealthTracker/Presentation/Views/MainView.swift && \
      ! grep -q "\"Monitore sua saúde\"" HealthTracker/Presentation/Views/MainView.swift && \
      ! grep -q "\"Água\"" HealthTracker/Presentation/Views/MainView.swift && \
      echo "✓ Views updated with localized strings"
    </automated>
  </verify>
  <done>All view files use String(localized:) for user-facing text, no hardcoded Portuguese strings remain in presentation layer</done>
</task>

<task type="auto">
  <name>Task 3: Localize notification messages in ScheduleNotificationsUseCase</name>
  <files>
    HealthTracker/Domain/UseCases/ScheduleNotificationsUseCase.swift
  </files>
  <action>
    Replace hardcoded Portuguese notification messages with localized strings.

    Update lines 71 and 80 in ScheduleNotificationsUseCase.swift:

    ```swift
    // Before (line 71):
    body: "Registre o que você comeu hoje",

    // After:
    body: String(localized: "notification_lunch"),

    // Before (line 80):
    body: "Registre suas refeições e atividades",

    // After:
    body: String(localized: "notification_evening"),
    ```

    Important:
    - Keep the Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") logic for title unchanged
    - Maintain all other notification scheduling logic (dateComponents, repeats, identifiers)
    - Preserve error handling and logging
    - Do NOT change any of the scheduling logic or timing

    Why: Notification messages are user-facing content that must respect device language settings. This ensures users receive reminders in their preferred language.
  </action>
  <verify>
    <automated>
      # Verify notification messages use localized strings
      grep -q 'String(localized: "notification_lunch")' HealthTracker/Domain/UseCases/ScheduleNotificationsUseCase.swift && \
      grep -q 'String(localized: "notification_evening")' HealthTracker/Domain/UseCases/ScheduleNotificationsUseCase.swift && \
      ! grep -q '"Registre o que você comeu hoje"' HealthTracker/Domain/UseCases/ScheduleNotificationsUseCase.swift && \
      echo "✓ Notification messages localized"
    </automated>
  </verify>
  <done>Notification messages use String(localized:) and will display in device language (PT-BR or English)</done>
</task>

</tasks>

<verification>
## Manual Testing Steps

1. **English Language Test:**
   - Change iOS device language to English (Settings → General → Language & Region)
   - Launch HealthTracker app
   - Verify all UI text appears in English:
     - Navigation title: "Track your health"
     - Buttons: "Add" instead of "Adicionar"
     - Section labels in English
   - Wait for notification (or use debug build timing)
   - Verify notification message appears in English

2. **Portuguese-BR Test:**
   - Change iOS device language to Portuguese (Brazil)
   - Relaunch HealthTracker app
   - Verify all UI text appears in Portuguese:
     - Navigation title: "Monitore sua saúde"
     - Original Portuguese strings preserved
   - Verify notification messages in Portuguese

3. **Dynamic Switching Test:**
   - While app is running, switch device language
   - Verify new language takes effect when app returns to foreground
   - Check no crashes or missing strings

## Automated Validation

```bash
# Verify no hardcoded Portuguese strings in code (except comments)
! grep -r "Registre\|Água\|Exercícios" HealthTracker/Presentation --include="*.swift" | grep -v "//"

# Verify String(localized:) usage
grep -r "String(localized:" HealthTracker --include="*.swift" | wc -l
# Should show multiple matches (at least 15+)

# Verify both .strings files have matching key count
diff <(grep -o '"[^"]*" =' HealthTracker/Resources/en.lproj/Localizable.strings | sort) \
     <(grep -o '"[^"]*" =' HealthTracker/Resources/pt-BR.lproj/Localizable.strings | sort)
# Should show no differences in keys
```
</verification>

<success_criteria>
- [ ] Localizable.strings files exist for both en.lproj and pt-BR.lproj
- [ ] Both string catalogs contain matching keys with appropriate translations
- [ ] All user-facing strings in views use String(localized:)
- [ ] Notification messages use String(localized:)
- [ ] No hardcoded Portuguese strings remain in code (except comments/documentation)
- [ ] App displays correctly in English when device language is English
- [ ] App displays correctly in Portuguese when device language is PT-BR
- [ ] Notifications respect device language setting
- [ ] No crashes or missing strings when switching languages
</success_criteria>

<output>
After completion, create `.planning/quick/1-add-internationalization-in-the-project-/1-SUMMARY.md`
</output>
