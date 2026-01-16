# Task Completion Checklist

## After Finishing Code Edits

### 1. Run Formatting
```bash
swiftformat .
```

### 2. Run Linting
```bash
swiftlint .
```

### 3. Quality Gates Verification
Before considering a task complete, verify:

- [ ] NO force unwrapping (`!`, `try!`)
- [ ] ALL errors have recovery paths
- [ ] DEPENDENCIES injected via `init`
- [ ] PUBLIC APIs documented with `///` comments
- [ ] EDGE CASES handled (nil, empty, invalid)
- [ ] VALIDATION uses parsing (validation-carrying types) not boolean checks
- [ ] VALIDATED data flows through system as typed values, not raw strings
- [ ] DOMAIN BOUNDARIES respected: Domain uses domain types, boundaries parse strings ↔ domain types
- [ ] ACCESS CONTROL uses witnesses, not boolean checks (where applicable)

### 4. Architecture Compliance
- [ ] Domain layer has NO dependencies on Data or Presentation
- [ ] Data layer only depends on Domain
- [ ] Presentation layer uses dependency injection for use cases

### 5. File Header
Ensure new files have the standard header:
```swift
//
//  FileName.swift
//  HealthTracker
//
//  Created by Gustavo Araujo Santos on [Date].
//
```

### 6. Build Verification
Ensure the project builds without errors:
```bash
xcodebuild -project HealthTracker/HealthTracker.xcodeproj -scheme HealthTracker build
```
