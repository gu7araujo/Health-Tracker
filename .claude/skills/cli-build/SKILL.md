---
name: cli-build
description: Build the HealthTracker app or compile the test target from the command line with xcodebuild. Use when the Xcode MCP build tools are unavailable or failing and you need to confirm the project compiles.
---

# Build HealthTracker from the CLI

Fallback for when the Xcode MCP build tools don't work. Pipe every command through `xcbeautify` for readable output.

Build the app:
```bash
xcodebuild -project HealthTracker.xcodeproj -scheme HealthTracker -configuration Debug build | xcbeautify
```

Compile the tests without running them (faster; use to check test code compiles):
```bash
xcodebuild build-for-testing -project HealthTracker.xcodeproj -scheme HealthTracker | xcbeautify
```

**Done when:** the command ends in `Build Succeeded`. A failure prints the offending file and line — fix and rebuild until green.
