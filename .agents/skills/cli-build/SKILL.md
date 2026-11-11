---
name: cli-build
description: Build the HealthTracker app or compile the test target with xcodebuild, the fallback once an Xcode MCP build call has returned an error you can quote. Use before any xcodebuild build in a main session; workflow subagents and gates build through scripts/quality.
---

# Build HealthTracker from the CLI

The fallback the runner table in root `AGENTS.md` (Building and Validating) allows. Pipe every command through `xcbeautify` for readable output.

Build the app:
```bash
xcodebuild -project HealthTracker.xcodeproj -scheme HealthTracker -configuration Debug build | xcbeautify
```

Compile the tests without running them (faster; use to check test code compiles):
```bash
xcodebuild build-for-testing -project HealthTracker.xcodeproj -scheme HealthTracker | xcbeautify
```

**Done when:** the command ends in `Build Succeeded`. A failure prints the offending file and line — fix and rebuild until green.
